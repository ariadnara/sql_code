# @Autor: Ariadna RA
# @Created:24/02/2026
# @SK: 659909
# @Ticket HS:36393476676
# @Concepto: fix_laser_gen.py 

import mysql.connector
from mysql.connector import Error
import time

#Tratamientos y revisiones de tipo calor y aspirador.
class MigLaserFix:
    def __init__(self,  tgt_conn_cfg: dict):        
        self.tgt_cfg = tgt_conn_cfg

    def run_migration(self):
        max_retries = 1
        attempt = 1
        rows_affected_user = 0
        rows_affected_user0 = 0
        rows_affected_clinic = 0
        rows_affected_diaries = 0
        rows_affected_clinic_ext = 0

        while attempt <= max_retries:
            src_conn = None
            tgt_conn = None
            try:                
                tgt_conn = mysql.connector.connect(**self.tgt_cfg)                
                tgt_cursor = tgt_conn.cursor() 

                tgt_cursor.execute(self._update_user_laser_gen_sql())
                rows_affected_user = tgt_cursor.rowcount

                tgt_cursor.execute(self._update_user_0_laser_gen_sql())
                rows_affected_user0 = tgt_cursor.rowcount
                
                tgt_cursor.execute(self._update_clinic_laser_gen_sql())
                rows_affected_clinic = tgt_cursor.rowcount

                tgt_cursor.execute(self._insert_invisible_diary_sql())
                rows_affected_clinic = tgt_cursor.rowcount

                tgt_cursor.execute(self._update_comments_laser_gen_sql())
                rows_affected_clinic_ext = tgt_cursor.rowcount

                tgt_conn.commit()     
                
                print(f"✅ Actualizados los profesionales en históriales nativos: {rows_affected_user} registros modificados")
                print(f"✅ Colocado el profesional 273 en historiales nativos sin referencia de profesional: {rows_affected_user} registros modificados")
                print(f"✅ Actualizadas clínicas en históriales nativos: {rows_affected_clinic} registros modificados")
                print(f"✅ Actualizadas citas invisibles en históriales nativos: {rows_affected_diaries} registros insertados")
                print(f"✅ Actualizados los comentarios en históriales nativos de revisioanes externas: {rows_affected_clinic_ext} registros insertados")
                
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
    def _update_user_laser_gen_sql():
        return """
        UPDATE laser_gen lg 
            INNER JOIN __mig_mapp_operator mo ON mo.operadorasociado_key_oid=lg.LaserGUserID
            INNER JOIN x_config_users xu ON xu.__UserIdMig=mo.userid
        SET LaserGUserID = xu.UserID
        WHERE lg.__LaserMigrated=-1 AND lg.LaserGUserID>0 AND LaserGStamp=CURDATE()
        """     

    @staticmethod
    def _update_user_0_laser_gen_sql():
        return """
        UPDATE laser_gen lg             
        SET LaserGUserID = 273
        WHERE lg.__LaserMigrated=-1 AND lg.LaserGUserID=0 AND LaserGStamp=CURDATE()
        """ 

    @staticmethod
    def _update_clinic_laser_gen_sql():
        return """
        UPDATE laser_gen lg LEFT JOIN __mig_mapp_clinics mc ON mc.ClinicIDFrom = lg.LaserGClinicID SET lg.LaserGClinicID = IFNULL(mc.ClinicIDTo,0) WHERE lg.__LaserMigrated=-1 AND lg.LaserGClinicID>0 AND LaserGStamp=CURDATE()
        """

    @staticmethod
    def _insert_invisible_diary_sql():
        return """
            INSERT INTO diary_gen (DiaryGClientID,DiaryGClinicID,DiaryGDate,DiaryGLaserGID,DiaryGCreated,DiaryGStamp,DiaryGInvisible)
            SELECT  lg.LaserGClientID AS DiaryGClientID,lg.LaserGClinicID AS DiaryGClinicID,lg.LaserGDate AS DiaryGDate,lg.LaserGID AS DiaryGLaserGID,CURDATE() AS DiaryGCreated,CURDATE() AS DiaryGStamp,-1 AS DiaryGInvisible
            FROM laser_gen lg WHERE lg.__LaserMigrated=-1 AND lg.LaserGClinicID>0 AND LaserGStamp=CURDATE()
        """
      
    @staticmethod
    def _update_comments_laser_gen_sql():
        return """
        UPDATE laser_gen lg INNER JOIN __mig_mapp_clinics mc ON mc.ClinicIDFrom = lg.__LaserExtRwClinicID AND lg.__LaserExtRwClinicID>0 INNER JOIN x_config_clinics xc ON xc.ClinicID = mc.ClinicIDTo SET lg.LaserGComments = CONCAT(' - Centro externo asociado: ',xc.ClinicCommercialName,'\n',LaserGComments) WHERE lg.__LaserExtRwClinicID>0
        """


