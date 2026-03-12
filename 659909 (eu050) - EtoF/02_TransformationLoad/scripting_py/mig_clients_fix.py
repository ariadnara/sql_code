import mysql.connector
from mysql.connector import Error
from datetime import date
import time


class MigClientsFix:
    def __init__(self,  tgt_conn_cfg: dict):        
        self.tgt_cfg = tgt_conn_cfg

    def run_migration(self):
        max_retries = 1
        attempt = 1
        rows_affected=0

        while attempt <= max_retries:
            src_conn = None
            tgt_conn = None
            try:                
                tgt_cfg = {**self.tgt_cfg, 'charset': 'utf8mb4', 'use_unicode': True}    
                tgt_conn = mysql.connector.connect(**tgt_cfg)
                tgt_cursor = tgt_conn.cursor()
                rows_affected = 0     

            
                # Insertar accesos iniciales en clients_access después de todos los inserts
                self._update_clinic_id(tgt_cursor)
                self._update_referer__id(tgt_cursor)
                self._fix_client_birthdate(tgt_cursor)                
                self._insert_clients_access(tgt_cursor)
                tgt_conn.commit()
                rows_affected = tgt_cursor.rowcount if tgt_cursor.rowcount is not None else 0  
                print(f"\n✅ Migración completada: {rows_affected} accesos de clientes.")
                print("✅ Actualizadas clínicas y orígenes de los clientes")


                # Mostrar resultado agregado por clínica
                self._result_summary_migrated(tgt_cursor)

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
    def _insert_clients_access(cursor):
        cursor.execute(
            """
            REPLACE INTO clients_access
                (AccessClientID, AccessClinicID, AccessUserID, AccessSource, AccessTimeStamp)
            SELECT
                c.ClientID        AS AccessClientID,
                c.ClientClinicID  AS AccessClinicID,
                0                 AS AccessUserID,
                'Import'          AS AccessSource,
                CURRENT_TIMESTAMP() AS AccessTimeStamp
            FROM clients c
            WHERE ClientImportID=DATE_FORMAT(CURDATE(),'%Y%m%d') AND ClientClinicID!=0 
            """
        )

    @staticmethod
    def _update_clinic_id(cursor):
        cursor.execute(
            """
            UPDATE clients c
            INNER JOIN __mig_mapp_clinics mc ON mc.ClinicIDFrom=c.ClientCustom8
            SET c.ClientClinicID=mc.ClinicIDTo            
            """
        )
    
    @staticmethod
    def _update_referer__id(cursor):
        cursor.execute(
            """
            UPDATE clients c
            INNER JOIN __mig_mapp_refererid mr ON mr.RefererIDFrom=c.ClientCustom5
            SET c.ClientRefererID=mr.RefererIDTo            
            """
        ) 

    @staticmethod
    def _fix_client_birthdate(cursor):
        cursor.execute(
            """
            UPDATE clients c 
            SET ClientBirthDate= STR_TO_DATE(
                                            CONCAT(
                                                CASE
                                                    WHEN RIGHT(LEFT(ClientBirthDate,4),2) > DATE_FORMAT(CURDATE(),'%y')
                                                        THEN '19'
                                                    ELSE '20'
                                                END,
                                                RIGHT(LEFT(ClientBirthDate,4),2),
                                                SUBSTRING(ClientBirthDate,5)
                                            ),'%Y-%m-%d') 
            WHERE c.ClientBirthDate<'1800-01-01';         
            """
        )   

    @staticmethod
    def _result_summary_migrated(cursor):   
        cursor.execute(
            """
            SELECT COUNT(c.ClientID) AS TotalMigrado, c.ClientClinicID
            FROM clients c
            WHERE ClientImportID=DATE_FORMAT(CURDATE(),'%Y%m%d')
            GROUP BY c.ClientClinicID
            """
        )
        rows = cursor.fetchall()
        print("\n📊 Clientes migrados por clínica DESTINO:")
        for row in rows:
            print(f"ClinicID {row[1]} -> Total Migrado: {row[0]}")
