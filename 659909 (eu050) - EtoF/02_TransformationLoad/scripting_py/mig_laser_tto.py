# @Autor: Ariadna RA
# @Created:24/02/2026
# @SK: 659909
# @Ticket HS:36393476676
# @Concepto: mig_laser_tto.py 

import mysql.connector
from mysql.connector import Error
import time

#Tratamientos y revisiones de tipo calor y aspirador.
class MigLaserTto:
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
                            r["ClientID"],
                            r["LaserGClinicIDFrom"],
                            r["LaserGCabinetNum"],
                            r["LaserGDate"],
                            r["LaserGStart"],
                            r["LaserGEnd"],
                            r["LaserGTicketGID"],
                            r["LaserGUserIDFrom"],
                            r["LaserGComments"],
                            r["LaserGStamp"],
                            r["__LasergStage"],
                            r["__LaserGIDTto"],
                            r["__LaserGIDRev"],
                            r["__LaserGIDMto"],
                            r["__LaserGProductSourceID"],
                            r["__LaserMigrated"],
                            r["__LaserExtRwClinicID"]
                        )
                        batch_values.append(values)

                    # Insertar lote con placeholders dinámicos
                    if batch_values:
                        values_placeholder = ",".join(
                            ["(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"] 
                            * len(batch_values)
                        )
                        flat_data = [item for row in batch_values for item in row]
                        
                        sql = f"""
                        INSERT INTO `laser_gen` (`LaserGClientID`, LaserGClinicID, LaserGCabinetNum, LaserGDate, LaserGStart, LaserGEnd, LaserGTicketGID, LaserGUserID, LaserGComments, LaserGStamp, __LasergStage, __LaserGIDTto, __LaserGIDRev, __LaserGIDMto, __LaserGProductSourceID,__LaserMigrated,__LaserExtRwClinicID)
                        VALUES {values_placeholder}
                        """
                        
                        tgt_cursor.execute(sql, flat_data)
                        tgt_conn.commit()
                        
                        batch_count += 1
                        total_inserted += len(batch_values)
                        print(f"✅ Lote {batch_count}: {len(batch_values)} registros insertados ({total_inserted} total)")

                print(f"✅ Migración completada de historiales de tipo calor y aspirador: {total_inserted} registros insertados")

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
                SELECT * FROM (						
					SELECT 
					  	CLIENTEASOCIADO_KEY_OID AS ClientID,
						t.CENTROASOCIADO_KEY_OID AS LaserGClinicIDFrom,
						0 AS LaserGCabinetNum,
						FECHATRATAMIENTO AS LaserGDate,
						TIME(HORAINICIO) AS LaserGStart,
						IFNULL(TIME(HORAFIN), TIME(HORAINICIO) + INTERVAL 15 MINUTE ) AS LaserGEnd,
						0 AS LaserGTicketGID,
						COALESCE(OPERADORASOCIADO_KEY_OID, (SELECT `KEY` FROM OPERADORDEFRANQUICIA WHERE REPLACE(CONCAT(TRIM(NOMBRE),' ',TRIM(APELLIDOS)),'  ',' ')=REPLACE(TRIM(OPERADOR),'  ',' ') LIMIT 1 ),0) AS LaserGUserIDFrom,
					    IFNULL(NOMBREESTADO,'') AS __LasergStage,
						CONCAT(														
								' - Código de tratamiento: ', IFNULL(CODIGOTRATAMIENTO,' - '),'\n',
							    ' - Estado: ',IFNULL(NOMBREESTADO,' - '),'\n',					
								' - Operador: ',IFNULL(OPERADOR,' - '),'\n',
								' - Observaciones: ',IF(OBSERVACIONES='' OR ISNULL(OBSERVACIONES) ,' Sin anotaciones',OBSERVACIONES)
						) AS LaserGComments,
						CURDATE() AS LaserGStamp,
						t.`KEY` AS  __LaserGIDTto,
						0 AS __LaserGIDRev,
						0 AS __LaserGIDMto,
                        6 AS __LaserGProductSourceID,
                        -1 AS __LaserMigrated,
                        0 AS __LaserExtRwClinicID
					FROM TRATAMIENTO t 
					LEFT JOIN CENTRO c ON c.`KEY`= CENTROEXTERNOASOCIADO_KEY_OID
					WHERE  t.TIPO IN ('Diagnóstico') AND  IF(@@server_uuid='02d35120-2210-11e9-80f9-42010a800117',t.FECHATRATAMIENTO>'2024-12-31',t.FECHATRATAMIENTO<='2024-12-31')
					
					UNION ALL 
					
					SELECT 
					  	r.CLIENTEASOCIADO_KEY_OID AS ClientID,
						t.CENTROASOCIADO_KEY_OID AS LaserGClinicIDFrom,
						0 AS LaserGCabinetNum,
						r.FECHAREVISION AS LaserGDate,
						TIME(r.HORAINICIO) AS LaserGStart,
						IFNULL(TIME(r.HORAFIN), TIME(r.HORAINICIO) + INTERVAL 15 MINUTE ) AS LaserGEnd,
						0 AS LaserGTicketGID,
						COALESCE(r.OPERADORASOCIADO_KEY_OID, (SELECT `KEY` FROM OPERADORDEFRANQUICIA WHERE REPLACE(CONCAT(TRIM(NOMBRE),' ',TRIM(APELLIDOS)),'  ',' ')=REPLACE(TRIM(r.NOMBREOPERADOR),'  ',' ') LIMIT 1 ),0) AS LaserGUserIDFrom,
					    IFNULL(r.NOMBREESTADO,'') AS __LasergStage,
						CONCAT(			
								' - Código de revisión: ', IFNULL(r.CODIGO,' - '),'\n',	
                                ' - Código de tratamiento: ', IFNULL(t.CODIGOTRATAMIENTO,' - '),'\n',                        
                                ' - Estado: ',IFNULL(r.NOMBREESTADO,' - '),'\n',
								' - Operador: ',IFNULL(r.NOMBREOPERADOR,' - '),'\n', 
								' - Observaciones: ',IF(r.OBSERVACIONES='' OR ISNULL(r.OBSERVACIONES) ,' Sin anotaciones',r.OBSERVACIONES)			
						) AS LaserGComments,
						CURDATE() AS LaserGStamp,
						0 AS  __LaserGIDTto,
						r.`KEY` AS __LaserGIDRev,
						0 AS __LaserGIDMto,
                        60 AS __LaserGProductSourceID,
                        -1 AS __LaserMigrated,
                        0 AS __LaserExtRwClinicID
					FROM REVISION r 
					INNER JOIN TRATAMIENTO t ON t.`KEY`=r.TRATAMIENTOASOCIADO_KEY_OID
					LEFT JOIN CENTRO c ON c.`KEY`= r.CENTROEXTERNOASOCIADO_KEY_OID
					WHERE  t.TIPO IN ('Diagnóstico') AND  IF(@@server_uuid='02d35120-2210-11e9-80f9-42010a800117',r.FECHAREVISION>'2024-12-31',r.FECHAREVISION<='2024-12-31')
            )tmp
            ORDER BY LaserGDate DESC;
        """



