

-- Citas a futuro
SELECT 
		`KEY` AS __MigDiaryGID,
		CENTROASOCIADO_KEY_OID AS DiaryGCompositionID,
		CLIENTEASOCIADO_KEY_OID AS DiaryGClientID,
		CONCAT(
			'Código de tratamiento: ', IFNULL(CODIGOTRATAMIENTO,' - '),'\n',	
			'Secuencial de tratamiento :', IFNULL(SECUENCIALTTO,' - '),'\n',			
			'Operador: ',IFNULL(OPERADOR,' - '),'\n',
			'Hora prevista: ',IFNULL(TIME(HORAPREVISTA),' - '),'\n',
			'Fecha tratamiento: ',IFNULL(DATE_FORMAT(FECHATRATAMIENTO,'%d/%m/%Y'),' - '),'\n',
			'Tipo: ',IFNULL(TIPO,' - '),'\n',
			'Observaciones: ',IFNULL(OBSERVACIONES,' - '),'\n',
			'Estado: ',IFNULL(NOMBREESTADO,' - '),'\n',
			'Revisión externa: ',if(REVISIONEXTERNA=0,'No','Si'),'\n',
			'Observaciones de revisión externa: ',IFNULL(OBSERVACIONESREVISIONEXTERNA,' - '),'\n'			
			) AS DiaryGComments,
		FECHAREVISION AS DiaryGDate,	
		SEC_TO_TIME(ROUND(TIME_TO_SEC(TIME(HORAINICIO)) / 60 / 15) * 15 * 60) AS DiaryGStart,
		SEC_TO_TIME(ROUND(TIME_TO_SEC(TIME(HORAFIN)) / 60 / 15) * 15 * 60) AS DiaryGEnd,
		1 AS DiaryGCabinetNum,
		0 AS DiaryGUserID, 
		CURDATE() AS  DiaryGCreated,
		-1 AS DiaryGMigrated,
			
 FROM TRATAMIENTO t 
 WHERE t.FECHAREVISION>CURDATE();

-- UPDATE diary_gen dg
INNER JOIN __mig_mapp_clinics xc ON xc.ClinicIDFrom=dg.DiaryGCompositionID
SET dg.DiaryGClinicID=xc.ClinicIDTo;

-- INSERT INTO diary_det (DiaryGID,DiaryZoneID)
SELECT DiaryGID, xp.ProductID
FROM diary_gen dg 
	INNER JOIN x_config_clinics xc ON xc.ClinicID=dg.DiaryGClinicID
	INNER JOIN x_config_products_det xp ON xp.ProductSourceID=420 AND xp.ProductGID=xc.ClinicProductGID
WHERE dg.DiaryGCreated=CURDATE() AND dg.DiaryGMigrated=-1;
