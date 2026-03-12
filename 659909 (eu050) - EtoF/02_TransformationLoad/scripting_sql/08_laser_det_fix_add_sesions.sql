


SELECT * FROM laser_gen lg WHERE lg.LaserGID=183612;

-- Revisión
SET @ClientID=0;
SET @LaserSessionID=0;
-- INSERT INTO laser_det (LaserGID, LaserZoneID, LaserSessionID, LaserImportID, LaserEquipmentID, LaserClinicEquipmentID, LaserSpotID)
SELECT 
   LaserGID, LaserZoneID, LaserSessionID, LaserImportID, LaserEquipmentID, LaserClinicEquipmentID, LaserSpotID
FROM (
       SELECT
           t.LaserGID,
           t.LaserZoneID,
           @LaserSessionID :=
               IF(@ClientID = t.LaserGClientID,
               @LaserSessionID + 1,
               1) AS LaserSessionID,
           @ClientID := t.LaserGClientID AS ClientID,
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
               INNER JOIN x_config_products_det xp ON xp.ProductGID = xc.ClinicProductGID AND xp.ProductSourceID = 60
               LEFT JOIN equipments e ON e.EquipmentClinicID = lg.LaserGClinicID AND e.EquipmentEquipmentID = 3
               LEFT JOIN x_config_spotclasses sp ON SUBSTRING_INDEX(sp.SpotClassDesc,'-',1)= SUBSTRING_INDEX(lg.__LaserGStage,'-',1) AND sp.SpotClassEquipmentID = 3
            WHERE lg.__LaserGIDRev>0 AND lg.__LaserGProductSourceID=5
           GROUP BY lg.LaserGClientID,lg.LaserGID
           ORDER BY lg.LaserGClientID, lg.LaserGDate, lg.LaserGID
       ) t
)tmp;

-- Diagnistico
SET @ClientID=0;
SET @LaserSessionID=0;
-- INSERT INTO laser_det (LaserGID, LaserZoneID, LaserSessionID, LaserImportID, LaserEquipmentID, LaserClinicEquipmentID, LaserSpotID)
SELECT 
   LaserGID, LaserZoneID, LaserSessionID, LaserImportID, LaserEquipmentID, LaserClinicEquipmentID, LaserSpotID
FROM (
       SELECT
           t.LaserGID,
           t.LaserZoneID,
           @LaserSessionID :=
               IF(@ClientID = t.LaserGClientID,
               @LaserSessionID + 1,
               1) AS LaserSessionID,
           @ClientID := t.LaserGClientID AS ClientID,
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
               INNER JOIN x_config_products_det xp ON xp.ProductGID = xc.ClinicProductGID AND xp.ProductSourceID = 6
               LEFT JOIN equipments e ON e.EquipmentClinicID = lg.LaserGClinicID AND e.EquipmentEquipmentID = 3
               LEFT JOIN x_config_spotclasses sp ON SUBSTRING_INDEX(sp.SpotClassDesc,'-',1)= SUBSTRING_INDEX(lg.__LaserGStage,'-',1) AND sp.SpotClassEquipmentID = 3
            WHERE lg.__LaserGIDTto>0 AND lg.__LaserGProductSourceID=5
           GROUP BY lg.LaserGClientID,lg.LaserGID
           ORDER BY lg.LaserGClientID, lg.LaserGDate, lg.LaserGID
       ) t
)tmp;

-- Revisión externa
SET @ClientID=0;
SET @LaserSessionID=0;
-- INSERT INTO laser_det (LaserGID, LaserZoneID, LaserSessionID, LaserImportID, LaserEquipmentID, LaserClinicEquipmentID, LaserSpotID)
SELECT 
   LaserGID, LaserZoneID, LaserSessionID, LaserImportID, LaserEquipmentID, LaserClinicEquipmentID, LaserSpotID
FROM (
       SELECT
           t.LaserGID,
           t.LaserZoneID,
           @LaserSessionID :=
               IF(@ClientID = t.LaserGClientID,
               @LaserSessionID + 1,
               1) AS LaserSessionID,
           @ClientID := t.LaserGClientID AS ClientID,
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
               INNER JOIN x_config_products_det xp ON xp.ProductGID = xc.ClinicProductGID AND xp.ProductSourceID = 24
               LEFT JOIN equipments e ON e.EquipmentClinicID = lg.LaserGClinicID AND e.EquipmentEquipmentID = 3
               LEFT JOIN x_config_spotclasses sp ON SUBSTRING_INDEX(sp.SpotClassDesc,'-',1)= SUBSTRING_INDEX(lg.__LaserGStage,'-',1) AND sp.SpotClassEquipmentID = 3
            WHERE lg.__LaserGIDRev>0 AND lg.__LaserGProductSourceID=5 AND lg.LaserGComments LIKE '%Revisión externa: Si%'
           GROUP BY lg.LaserGClientID,lg.LaserGID
           ORDER BY lg.LaserGClientID, lg.LaserGDate, lg.LaserGID
       ) t
)tmp;


