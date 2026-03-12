# @Autor: Ariadna RA
# @Created:24/02/2026
# @SK: 659909
# @Ticket HS:36393476676
# @Concepto: mig_laser_det.py 

import mysql.connector
from mysql.connector import Error
import time

#Tratamientos y revisiones de tipo calor y aspirador.
class MigLaserDet:
    def __init__(self,  tgt_conn_cfg: dict):        
        self.tgt_cfg = tgt_conn_cfg

    def run_migration(self):
        max_retries = 1
        attempt = 1
        rows_affected = 0

        while attempt <= max_retries:
            src_conn = None
            tgt_conn = None
            try:                
                tgt_conn = mysql.connector.connect(**self.tgt_cfg)                
                tgt_cursor = tgt_conn.cursor()       

                for result in tgt_cursor.execute(self._insert_det_sql(), multi=True):
                    pass  

                rows_affected = tgt_cursor.rowcount
            
                tgt_conn.commit()                

                print(f"✅ Generando detalles de historiales nativos: {rows_affected} registros insertados")

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
    def _insert_det_sql():
        return """
        SET @ClientID=0;
        SET @LaserSessionID=0;
        SET @LaserZoneID=0;
        INSERT INTO laser_det (LaserGID, LaserZoneID, LaserSessionID, LaserImportID, LaserEquipmentID, LaserClinicEquipmentID, LaserSpotID)
        SELECT 
            LaserGID, LaserZoneID, LaserSessionID, LaserImportID, LaserEquipmentID, LaserClinicEquipmentID, LaserSpotID
        FROM (
                SELECT
                    t.LaserGID,
                    @LaserSessionID :=
                        IF(@ClientID = t.LaserGClientID AND @LaserZoneID = t.LaserZoneID,
                        @LaserSessionID + 1,
                        1) AS LaserSessionID,
                    @ClientID := t.LaserGClientID AS ClientID,
                    @LaserZoneID:= t.LaserZoneID as LaserZoneID,
                    t.LaserImportID,
                    t.LaserEquipmentID,
                    t.LaserClinicEquipmentID,
                    t.LaserSpotID
                FROM (
                    SELECT
                        lg.LaserGID,
                        xp.ProductID AS LaserZoneID,
                        lg.LaserGClientID,
                        DATE_FORMAT(CURDATE(),'%Y%m%d') AS LaserImportID,
                        IF(ISNULL(e.EquipmentID),0,3)  AS LaserEquipmentID,
                        IFNULL(e.EquipmentID,0) AS LaserClinicEquipmentID,
                        IFNULL(sp.SpotClassID,0) AS LaserSpotID,
                        lg.LaserGDate
                    FROM laser_gen lg
                        INNER JOIN x_config_clinics xc ON xc.ClinicID = lg.LaserGClinicID
                        INNER JOIN x_config_products_det xp ON xp.ProductGID = xc.ClinicProductGID AND xp.ProductSourceID = lg.__LaserGProductSourceID
                        LEFT JOIN equipments e ON e.EquipmentClinicID = lg.LaserGClinicID AND e.EquipmentEquipmentID = 3
                        LEFT JOIN x_config_spotclasses sp ON SUBSTRING_INDEX(sp.SpotClassDesc,'-',1)= SUBSTRING_INDEX(lg.__LaserGStage,'-',1) AND sp.SpotClassEquipmentID = 3
                    GROUP BY lg.LaserGClientID,lg.LaserGID,xp.ProductID
                    ORDER BY lg.LaserGClientID, lg.LaserGDate, lg.LaserGID,xp.ProductID
                ) t
        )tmp
         
        """

