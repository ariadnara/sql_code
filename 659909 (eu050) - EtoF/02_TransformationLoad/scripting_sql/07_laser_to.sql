
# tratamientos y revisiones de tipo calor y aspirador.
SET @ClientID=0;
SET @LaserSessionID=0;

SELECT 
	lg.LaserGID, 
	xp.ProductID AS LaserZoneID,
	if(@ClientID=lg.LaserGClientID,@LaserSessionID+1,1) AS LaserSessionID,
	@ClientID:=lg.LaserGClientID,
	DATE_FORMAT(CURDATE(),'%Y%m%d') AS LaserImportID
FROM laser_gen lg
INNER JOIN x_config_clinics xc ON xc.ClinicID=lg.LaserGClinicID
INNER JOIN x_config_products_det xp ON xp.ProductGID=xc.ClinicProductGID AND xp.ProductSourceID=5
GROUP BY lg.LaserGClientID,lg.LaserGID
ORDER BY lg.LaserGDate ASC;



# tratamientos y revisiones de tipo calor y aspirador.
SET @ClientID=0;
SET @LaserSessionID=0;

SELECT 
	lg.LaserGID, 
	xp.ProductID AS LaserZoneID,
	if(@ClientID=lg.LaserGClientID,@LaserSessionID+1,1) AS LaserSessionID,
	@ClientID:=lg.LaserGClientID,
	DATE_FORMAT(CURDATE(),'%Y%m%d') AS LaserImportID,
	3 as LaserEquipmentID,
	e.EquipmentID AS LaserClinicEquipmentID,
	sp.SpotClassID AS  LaserSpotID
FROM laser_gen lg
INNER JOIN x_config_clinics xc ON xc.ClinicID=lg.LaserGClinicID
INNER JOIN x_config_products_det xp ON xp.ProductGID=xc.ClinicProductGID AND xp.ProductSourceID=5
LEFT JOIN equipments e ON e.EquipmentClinicID=lg.LaserGClinicID AND e.EquipmentEquipmentID=3
LEFT JOIN x_config_spotclasses sp ON sp.SpotClassDesc=lg.__LasergStage AND sp.SpotClassEquipmentID=3
GROUP BY lg.LaserGClientID,lg.LaserGID
ORDER BY lg.LaserGDate ASC;

# tratamientos y revisiones de tipo calor y aspirador.
SET @ClientID=0;
SET @LaserSessionID=0;

SELECT 
	lg.LaserGID, 
	xp.ProductID AS LaserZoneID,
	if(@ClientID=lg.LaserGClientID,@LaserSessionID+1,1) AS LaserSessionID,
	@ClientID:=lg.LaserGClientID,
	DATE_FORMAT(CURDATE(),'%Y%m%d') AS LaserImportID,
	3 as LaserEquipmentID,
	e.EquipmentID AS LaserClinicEquipmentID,
	sp.SpotClassID AS  LaserSpotID
FROM laser_gen lg
INNER JOIN x_config_clinics xc ON xc.ClinicID=lg.LaserGClinicID
INNER JOIN x_config_products_det xp ON xp.ProductGID=xc.ClinicProductGID AND xp.ProductSourceID=6
LEFT JOIN equipments e ON e.EquipmentClinicID=lg.LaserGClinicID AND e.EquipmentEquipmentID=3
LEFT JOIN x_config_spotclasses sp ON sp.SpotClassDesc=lg.__LasergStage AND sp.SpotClassEquipmentID=3
GROUP BY lg.LaserGClientID,lg.LaserGID
ORDER BY lg.LaserGDate ASC;

# mantenimientos
SET @ClientID=0;
SET @LaserSessionID=0;

SELECT 
	lg.LaserGID, 
	xp.ProductID AS LaserZoneID,
	if(@ClientID=lg.LaserGClientID,@LaserSessionID+1,1) AS LaserSessionID,
	@ClientID:=lg.LaserGClientID,
	DATE_FORMAT(CURDATE(),'%Y%m%d') AS LaserImportID,
	3 as LaserEquipmentID,
	e.EquipmentID AS LaserClinicEquipmentID,
	sp.SpotClassID AS  LaserSpotID
FROM laser_gen lg
INNER JOIN x_config_clinics xc ON xc.ClinicID=lg.LaserGClinicID
INNER JOIN x_config_products_det xp ON xp.ProductGID=xc.ClinicProductGID AND xp.ProductSourceID=59
LEFT JOIN equipments e ON e.EquipmentClinicID=lg.LaserGClinicID AND e.EquipmentEquipmentID=3
LEFT JOIN x_config_spotclasses sp ON sp.SpotClassDesc=lg.__LasergStage AND sp.SpotClassEquipmentID=3
GROUP BY lg.LaserGClientID,lg.LaserGID
ORDER BY lg.LaserGDate ASC;