import mysql.connector
from mysql.connector import Error
import time

#Tratamientos y revisiones de tipo calor y aspirador.
class MigVouchers:
    def __init__(self, src_conn_cfg: dict, tgt_conn_cfg: dict):
        self.src_cfg = src_conn_cfg
        self.tgt_cfg = tgt_conn_cfg

    def run_migration(self):
        max_retries = 1
        attempt = 1

        while attempt <= max_retries:
            src_conn = None
            tgt_conn = None
            try:
                src_cfg = {**self.src_cfg, 'charset': 'utf8mb4', 'use_unicode': True}
                tgt_cfg = {**self.tgt_cfg, 'charset': 'utf8mb4', 'use_unicode': True}
                
                src_conn = mysql.connector.connect(**src_cfg)
                tgt_conn = mysql.connector.connect(**tgt_cfg)

                src_cursor = src_conn.cursor(dictionary=True)
                tgt_cursor = tgt_conn.cursor()

                batch_size = 5000
                total_inserted = 0
                batch_count = 0

                # Procesar por lotes sin cargar todo en memoria
                src_cursor.execute(self._source_query())
                
                while True:
                    rows = src_cursor.fetchmany(size=batch_size)
                    if not rows:
                        break
                    
                    batch_values = []
                    for r in rows:
                        values = (
                            r["VoucherClientID"],
                            r["VoucherDate"],
                            r["VoucherExpiryDate"],
                            r["VoucherStatOriginalSessions"],
                            r["VoucherUsed"],
                            r["VoucherAvailable"],
                            r["VoucherProductID"],
                            r["VoucherImportID"],
                            r["VoucherDateCreated"],
                            r["VoucherNotes"],
                            r["__VoucherClinicID"],
                            r["__VoucherType"],
                        )
                        batch_values.append(values)

                    # Insertar lote con placeholders dinámicos
                    if batch_values:
                        values_placeholder = ",".join(
                            ["(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"] 
                            * len(batch_values)
                        )
                        flat_data = [item for row in batch_values for item in row]
                        
                        sql = f"""
                        INSERT INTO `vouchers` (`VoucherClientID`, VoucherDate, VoucherExpiryDate, VoucherStatOriginalSessions, VoucherUsed, VoucherAvailable, VoucherProductID, VoucherImportID, VoucherDateCreated, VoucherNotes, __VoucherClinicID, __VoucherType)
                        VALUES {values_placeholder}
                        """
                        
                        tgt_cursor.execute(sql, flat_data)
                        tgt_conn.commit()
                        
                        batch_count += 1
                        total_inserted += len(batch_values)
                        print(f"✅ Lote {batch_count}: {len(batch_values)} registros insertados ({total_inserted} total)")

                tgt_cursor.execute(self._update_sql())       

                print(f"✅ Migración bonos {total_inserted} registros insertados")

                return

            except Error as e:
                if tgt_conn:
                    try:
                        if getattr(tgt_conn, "is_connected", lambda: False)():
                            tgt_conn.rollback()
                    except Exception:
                        pass

                try:
                    if src_conn:
                        src_conn.close()
                except Exception:
                    pass
                try:
                    if tgt_conn:
                        tgt_conn.close()
                except Exception:
                    pass

                if attempt < max_retries:
                    wait = attempt * 2
                    print(f"⚠ Error en intento {attempt}: {e}. Reintentando en {wait}s...")
                    time.sleep(wait)
                    attempt += 1
                    continue
                raise RuntimeError(f"Error en migración de Providers: {e}")

            finally:
                try:
                    if src_conn:
                        src_conn.close()
                except Exception:
                    pass
                try:
                    if tgt_conn:
                        tgt_conn.close()
                except Exception:
                    pass

    @staticmethod
    def _source_query():
        return """
            
            SELECT 
                bm.CLIENTEASOCIADO_KEY_OID AS VoucherClientID,
                bm.CENTROASOCIADO_KEY_OID AS __VoucherClinicID,
                bm.FECHACONTRATACION AS VoucherDate,
                GREATEST(
                    GREATEST(bm.FECHAINICIO,bm.FECHACONTRATACION) + INTERVAL CONVERT(bm.TIPO,SIGNED) MONTH
                    ,MAX(m.FECHAMANTENIMIENTO
                )) AS VoucherExpiryDate,
                IF(
                        CONVERT(bm.TIPO,SIGNED)=0 OR CONVERT(bm.TIPO,SIGNED)*2<COUNT(m.`KEY`)
                        ,COUNT(m.`KEY`)
                        ,CONVERT(bm.TIPO,SIGNED)*2
                ) AS VoucherStatOriginalSessions,
                COUNT(m.`KEY`) AS VoucherUsed, 
                (
                    IF(
                        CONVERT(bm.TIPO,SIGNED)=0 OR CONVERT(bm.TIPO,SIGNED)*2<COUNT(m.`KEY`)
                        ,COUNT(m.`KEY`)
                        ,CONVERT(bm.TIPO,SIGNED)*2
                    )-	COUNT(m.`KEY`)
                ) AS VoucherAvailable, 
                CONVERT(bm.TIPO,SIGNED) AS VoucherProductID,
                DATE_FORMAT(CURDATE(),'%Y%m%d') AS VoucherImportID,
                CURRENT_TIMESTAMP() AS VoucherDateCreated,
                CONCAT(	bm.CODIGOBONO, ' - ', bm.NOMBREOPERADOR, ' - Último mantenimiento en sistema origen: ', DATE(MAX(m.FECHAMANTENIMIENTO)) ) AS VoucherNotes,
                bm.TIPO AS __VoucherType
            FROM BONOS_MANTENIMIENTO  bm
            INNER JOIN MANTENIMIENTO m ON m.BONOASOCIADO_KEY_OID =bm.`KEY`
            INNER JOIN CLIENTE c ON c.`KEY`=bm.CLIENTEASOCIADO_KEY_OID
            WHERE IF(@@server_uuid='02d35120-2210-11e9-80f9-42010a800117',bm.FECHACONTRATACION>'2024-12-31',bm.FECHACONTRATACION<'2024-12-31')
            GROUP BY bm.`KEY`
        """

    @staticmethod
    def _insert_sql():
        return """
        INSERT INTO `vouchers` (`VoucherClientID`, VoucherDate, VoucherExpiryDate, VoucherStatOriginalSessions, VoucherUsed, VoucherAvailable, VoucherProductID, VoucherImportID, VoucherDateCreated,VoucherNotes, __VoucherClinicID, __VoucherType)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """
    @staticmethod
    def _update_sql():
        return """
        UPDATE vouchers v 
            INNER JOIN __mig_mapp_vouchers mv ON mv.ProductIDFrom=v.VoucherProductID
            INNER JOIN __mig_mapp_clinics mc ON mc.ClinicIDFrom=v.__VoucherClinicID 
            INNER JOIN x_config_clinics xc ON xc.ClinicID=mc.ClinicIDTo
            INNER JOIN x_config_products_det xp ON xp.ProductGID=xc.ClinicProductGID AND xp.ProductSourceID=mv.ProductSourceID	
        SET v.VoucherProductID=xp.ProductID
        WHERE VoucherImportID = DATE_FORMAT(CURDATE(),'%Y%m%d')
        """

