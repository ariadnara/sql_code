import mysql.connector
from mysql.connector import Error
from datetime import date
import time


class MigClients:
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

                    # Acumular todas las tuplas de valores y ejecutar en bloque
                    batch_values = []

                    for r in rows:                   

                        values = (
                            r["ClientID"],
                            r["ClientImportID"],
                            self._title(r["ClientName"]),
                            self._title(r["ClientSurname1"]),
                            self._title(r["ClientSurname2"]),
                            r["ClientBirthDate"],
                            r["ClientBillingPostCode"],
                            r["ClientBillingCity"],
                            r["ClientBillingProvince"],
                            r["ClientBillingAddress"],
                            r["ClientPhone1"],
                            r["ClientPhone2"],
                            r["ClientAddress"],
                            r["ClientCity"],
                            r["ClientPostCode"],
                            r["ClientEMail"],
                            r["ClientEnableGeneralConditions"],
                            r["ClientDisableSMS"],
                            r["ClientEnableRGPD"],
                            r["ClientDate"],
                            r["ClientD_LOPDDate"],
                            r["ClientMigrated"],
                            r["ClientFWAPassword"],
                            r["ClientFWALogin"],
                            r["ClientCustom1"],
                            self._sanitize_string(r["ClientCustom3"]),  
                            self._sanitize_string(r["ClientCustom4"]),  
                            self._sanitize_string(r["ClientCustom5"]),      
                            r["ClientCustom6"],
                            r["ClientCustom7"],
                            r["ClientCustom8"],
                            r["ClientStamp"],
                            r["ClientUserID"],
                            r["ClientNotes"],
                        )

                        batch_values.append(values)

                    # Insertar lote con placeholders dinámicos
                    if batch_values:
                        values_placeholder = ",".join(
                            ["(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"] 
                            * len(batch_values)
                        )
                        # Aplanar los datos
                        flat_data = [item for row in batch_values for item in row]
                        
                        # Construir SQL dinámicamente
                        sql = f"""
                        REPLACE INTO clients (
                            ClientID, ClientImportID,
                            ClientName, ClientSurname1, ClientSurname2, ClientBirthDate,
                            ClientBillingPostCode, ClientBillingCity, ClientBillingProvince, ClientBillingAddress,
                            ClientPhone1, ClientPhone2,
                            ClientAddress, ClientCity, ClientPostCode, ClientEMail,
                            ClientEnableGeneralConditions, ClientDisableSMS, ClientEnableRGPD,
                            ClientDate, ClientD_LOPDDate,
                            ClientMigrated, ClientFWAPassword, ClientFWALogin,
                            ClientCustom1, ClientCustom3, ClientCustom4,
                            ClientCustom5, ClientCustom6, ClientCustom7, ClientCustom8,
                            ClientStamp, ClientUserID, ClientNotes
                        )
                        VALUES {values_placeholder}
                        """
                        
                        tgt_cursor.execute(sql, flat_data)
                        tgt_conn.commit()
                        
                        batch_count += 1
                        total_inserted += len(batch_values)
                        print(f"✅ Lote {batch_count}: {len(batch_values)} registros insertados ({total_inserted} total)")

                self._result_summary_migrated(src_cursor)

                # Insertar accesos iniciales en clients_access después de todos los inserts  
                print(f"\n✅ Migración completada: {total_inserted} clientes migrados")

                return

            except Error as e:
                # Intentar rollback si la conexión aún está viva
                if tgt_conn:
                    try:
                        if getattr(tgt_conn, "is_connected", lambda: False)():
                            tgt_conn.rollback()
                    except Exception:
                        pass

                # Cerrar conexiones antes de reintentar
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
                raise RuntimeError(f"Error en migración de clientes: {e}")

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

    # -----------------------------------------------------

    @staticmethod
    def _title(value):
        return value.title() if value else value
    
    @staticmethod
    def _sanitize_string(value):
        if not value:
            return value
        try:
            return value.encode('utf-8', errors='ignore').decode('utf-8')
        except Exception:
            return ''
        
    @staticmethod
    def _source_query():
        #REGEXP_REPLACE(IFNULL(c.TUTOR,''), '[^[:print:]]', '') AS ClientCustom3,
        return """
        SELECT 
            c.`KEY` AS ClientID, 
			REPLACE(if(LENGTH(c.APELLIDOS)>64,c.APELLIDOS,''),'_','')  AS ClientNotes,
            REPLACE(SUBSTRING_INDEX(c.APELLIDOS,' ',1),'_','') AS ClientSurname1,
            SUBSTRING(REPLACE(REPLACE(c.APELLIDOS,SUBSTRING_INDEX(c.APELLIDOS,' ',1),''),'_',''),0,60) AS ClientSurname2,
            IFNULL(c.CODIGOPOSTAL,'') AS ClientPostCode,
            IFNULL(c.CORREOELECTRONICO,'') AS ClientEMail,
            c.FECHANACIMIENTO AS ClientBirthDate,
            c.NOMBRE AS ClientName,
            IFNULL(c.POBLACION,'') AS ClientCity,
            IFNULL(c.TELEFONOFIJO,'') AS ClientPhone2,
            IFNULL(c.TELEFONOMOVIL,'') AS ClientPhone1,        
            IF(c.LOPD=1,-1,0) AS ClientEnableGeneralConditions,
            IF(c.CONSIENTEEMAIL=1 OR c.CONSIENTETELEFONO=1,-1,0) AS ClientEnableRGPD,
            IF(c.CONSIENTETELEFONO=1,0,-1) AS ClientDisableSMS,
            IFNULL(c.FECHAALTA,CURDATE()) AS ClientDate,
            c.FECHAIMPRESIONLOPD AS ClientD_LOPDDate,
            IF(c.MENOR=1,'Si','No') AS ClientCustom1,
            CONVERT(IFNULL(c.TUTOR,'') USING utf8) AS ClientCustom3,            
            IFNULL(c.COLEGIO,'') AS ClientCustom4,
            IFNULL(c.COMONOSCONOCIO,'') AS ClientCustom5,
            IFNULL(c.FECHANACIMIENTOTUTOR,'') AS ClientCustom6,
            IFNULL(c.FECHAREACTIVACION,'') AS ClientCustom7,
            IFNULL(c.CENTROASOCIADO_KEY_OID,0) AS ClientCustom8,
            IFNULL(p.DOMICILIO,'') AS ClientAddress,
            DATE_FORMAT(CURDATE(),'%Y%m%d') AS ClientImportID, 
            -1 AS ClientMigrated,
            p.CODIGOPOSTAL AS ClientBillingPostCode,
            p.POBLACION AS ClientBillingCity,
            p.PROVINCIA AS ClientBillingProvince,
            p.DOMICILIO AS ClientBillingAddress,
            UPPER(SUBSTRING(MD5(c.`KEY`),1,6)) AS ClientFWAPassword,
            c.`KEY` AS ClientFWALogin,
            CURDATE() AS ClientStamp,
            0 AS ClientUserID
        FROM CLIENTE c
        LEFT JOIN PERSONAJURIDICA p 
            ON c.PERSONAJURIDICAASOCIADA_KEY_OID = p.`KEY`
        ORDER BY c.`KEY`
        """

    @staticmethod
    def _result_summary_migrated(cursor):   
        cursor.execute(
            """
            SELECT COUNT(c.`KEY`) AS TotalMigrado, c.CENTROASOCIADO_KEY_OID AS ClinicID
            FROM CLIENTE c            
            GROUP BY c.CENTROASOCIADO_KEY_OID
            """
        )
        rows = cursor.fetchall()
        print("\n📊 Clientes migrados por clínica ORIGEN:")
        for row in rows:
            print(f"ClinicID {row[1]} -> Total Migrado: {row[0]}")
