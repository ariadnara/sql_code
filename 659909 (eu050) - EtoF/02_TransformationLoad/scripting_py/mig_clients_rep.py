import mysql.connector
from mysql.connector import Error
import time


class MigClientRep:
    def __init__(self, tgt_conn_cfg: dict):        
        self.tgt_cfg = tgt_conn_cfg

    def run_migration(self):
        max_retries = 1
        attempt = 1

        while attempt <= max_retries:
            src_conn = None
            tgt_conn = None
            try:                
                tgt_conn = mysql.connector.connect(**self.tgt_cfg)                
                tgt_cursor = tgt_conn.cursor()
                tgt_cursor.execute(self._source_query())
                tgt_conn.commit()
                tgt_cursor.execute(self._update_sql())
                print(f"✅ Migración tutores completada.")

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
        INSERT INTO clients_rep (
                        ClientRepParenthood, ClientRepName, ClientRepSurnames, 
                        ClientRepAddress, ClientRepPhone, ClientRepIDClass, 
                        ClientRepNIF, ClientRepEmail, __ClientID
                    )
        SELECT
            '' AS ClientRepParenthood,
            UPPER(REPLACE(c.ClientCustom3,'/','')) AS ClientRepName,
            '' AS ClientRepSurnames,                
            IF(
                ClientCustom6 != '',
                CONCAT(
                    'Fecha nacimiento ',
                    DATE_FORMAT(ClientCustom6, '%Y/%m/%d')
                ),
                ''
            ) AS ClientRepAddress,
            '' AS ClientRepPhone,
            0 AS ClientRepIDClass,
            '' AS ClientRepNIF,
            '' AS ClientRepEmail,
            c.ClientID AS __ClientID
        FROM
            clients c
        WHERE
            c.ClientCustom1 != 'No'
            AND c.ClientCustom3 != ''
            AND c.ClientImportID=DATE_FORMAT(CURDATE(),'%Y%m%d')
        """
    
    @staticmethod
    def _update_sql():
        return """
        UPDATE clients c INNER JOIN clients_rep cr ON cr.__ClientID=c.ClientID SET c.ClientClientRepID=cr.ClientRepID
        """
