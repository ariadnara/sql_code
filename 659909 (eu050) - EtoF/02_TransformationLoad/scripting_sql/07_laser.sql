/*
SELECT * FROM TRATAMIENTO;
SELECT * FROM REVISION;
SELECT @@server_uuid;*/


# tratamientos y revisiones de tipo calor y aspirador.
SELECT * FROM (	
					SELECT 
					  	CLIENTEASOCIADO_KEY_OID AS ClientID,
						t.CENTROASOCIADO_KEY_OID AS LaserGClinicIDFrom,
						0 AS LaserGCabinetNum,
						FECHATRATAMIENTO AS LaserGDate,
						TIME(HORAINICIO) AS LaserGStart,
						IFNULL(TIME(HORAFIN), TIME(HORAINICIO) + INTERVAL 15 MINUTE ) AS LaserGEnd,
						0 AS LaserGTicketGID,
						IFNULL(OPERADORASOCIADO_KEY_OID,0) AS LaserGUserIDFrom,
						NOMBREESTADO AS __LasergStage,
						CONCAT('TRATAMIENTO: \n',
								' - Tipo: ',IFNULL(TIPO,' - '),'\n',
								' - Observaciones: ',IFNULL(OBSERVACIONES,' - '),'\n',
								' - Estado: ',IFNULL(NOMBREESTADO,' - '),'\n',
								' - Revisión externa: ',if(REVISIONEXTERNA=0,'No','Si'),'\n',
								' - Observaciones de revisión externa: ',IFNULL(OBSERVACIONESREVISIONEXTERNA,' - '),'\n',
								IF (CENTROASOCIADO_KEY_OID!=CENTROEXTERNOASOCIADO_KEY_OID,CONCAT(' - Centro externo asociado: ',c.NOMBRE,'\n'),''),	
								' - Código de tratamiento: ', IFNULL(CODIGOTRATAMIENTO,' - '),'\n',	
								' - Operador: ',IFNULL(OPERADOR,' - ')
						) AS LaserGComments,
						CURDATE() AS LaserGStamp,
						t.`KEY` AS  __LaserGIDTto,
						0 AS __LaserGIDRev,
						0 AS   __LaserGIDMto,
						5 AS __LaserGProductSourceID
					FROM TRATAMIENTO t 
					LEFT JOIN CENTRO c ON c.`KEY`= CENTROEXTERNOASOCIADO_KEY_OID
					WHERE  t.TIPO IN ('Calor','Aspirado') AND  IF(@@server_uuid='02d35120-2210-11e9-80f9-42010a800117',t.FECHATRATAMIENTO>'2024-12-31',t.FECHATRATAMIENTO<'2024-12-31')
					
					UNION ALL 
					
					SELECT 
					  	r.CLIENTEASOCIADO_KEY_OID AS ClientID,
						t.CENTROASOCIADO_KEY_OID AS LaserGClinicIDFrom,
						0 AS LaserGCabinetNum,
						r.FECHAREVISION AS LaserGDate,
						TIME(r.HORAINICIO) AS LaserGStart,
						IFNULL(TIME(r.HORAFIN), TIME(r.HORAINICIO) + INTERVAL 15 MINUTE ) AS LaserGEnd,
						0 AS LaserGTicketGID,
						IFNULL(r.OPERADORASOCIADO_KEY_OID,0) AS LaserGUserIDFrom,
						r.NOMBREESTADO AS __LasergStage,
						CONCAT('REVISION: \n',
								' - Tipo: ',IFNULL(t.TIPO,' - '),'\n',
								' - Observaciones: ',IF(r.OBSERVACIONES='' OR ISNULL(r.OBSERVACIONES) ,' Sin observaciones',r.OBSERVACIONES),'\n',
								' - Estado: ',IFNULL(r.NOMBREESTADO,' - '),'\n',
								' - Revisión externa: ', IF(r.CENTROASOCIADO_KEY_OID!=r.CENTROEXTERNOASOCIADO_KEY_OID,'Si','No'),'\n',		
								IF (r.CENTROASOCIADO_KEY_OID!=r.CENTROEXTERNOASOCIADO_KEY_OID,CONCAT(' - Centro externo asociado: ',c.NOMBRE,'\n'),''),
								' - Código de revisión: ', IFNULL(r.CODIGO,' - '),'\n',	
								' - Operador: ',IFNULL(r.NOMBREOPERADOR,' - ')
						) AS LaserGComments,
						CURDATE() AS LaserGStamp,
						0 AS  __LaserGIDTto,
						r.`KEY` AS __LaserGIDRev,
						0 AS   __LaserGIDMto,
						5 AS __LaserGProductSourceID
					FROM REVISION r 
					INNER JOIN TRATAMIENTO t ON t.`KEY`=r.TRATAMIENTOASOCIADO_KEY_OID
					LEFT JOIN CENTRO c ON c.`KEY`= r.CENTROEXTERNOASOCIADO_KEY_OID
					WHERE  t.TIPO IN ('Calor','Aspirado') AND  IF(@@server_uuid='02d35120-2210-11e9-80f9-42010a800117',r.FECHAREVISION>'2024-12-31',t.FECHATRATAMIENTO<'2024-12-31')
)tmp
ORDER BY LaserGDate DESC;

# tratamientos y revisiones de tipo diagnóstico
SELECT * FROM (	
					SELECT 
					  	CLIENTEASOCIADO_KEY_OID AS ClientID,
						t.CENTROASOCIADO_KEY_OID AS LaserGClinicIDFrom,
						0 AS LaserGCabinetNum,
						FECHATRATAMIENTO AS LaserGDate,
						TIME(HORAINICIO) AS LaserGStart,
						IFNULL(TIME(HORAFIN), TIME(HORAINICIO) + INTERVAL 15 MINUTE ) AS LaserGEnd,
						0 AS LaserGTicketGID,
						IFNULL(OPERADORASOCIADO_KEY_OID,0) AS LaserGUserIDFrom,
						NOMBREESTADO AS __LasergStage,
						CONCAT('TRATAMIENTO: \n',
								' - Tipo: ',IFNULL(TIPO,' - '),'\n',
								' - Observaciones: ',IFNULL(OBSERVACIONES,' - '),'\n',							
								' - Revisión externa: ',if(REVISIONEXTERNA=0,'No','Si'),'\n',
								' - Observaciones de revisión externa: ',IFNULL(OBSERVACIONESREVISIONEXTERNA,' - '),'\n',
								IF (CENTROASOCIADO_KEY_OID!=CENTROEXTERNOASOCIADO_KEY_OID,CONCAT(' - Centro externo asociado: ',c.NOMBRE,'\n'),''),	
								' - Código de tratamiento: ', IFNULL(CODIGOTRATAMIENTO,' - '),'\n',	
								' - Operador: ',IFNULL(OPERADOR,' - ')
						) AS LaserGComments,
						CURDATE() AS LaserGStamp,
						t.`KEY` AS  __LaserGIDTto,
						0 AS __LaserGIDRev,
						0 AS  AS  __LaserGIDMto,
						6 AS __LaserGProductSourceID
					FROM TRATAMIENTO t 
					LEFT JOIN CENTRO c ON c.`KEY`= CENTROEXTERNOASOCIADO_KEY_OID
					WHERE  t.TIPO IN ('Diagnóstico') AND  IF(@@server_uuid='02d35120-2210-11e9-80f9-42010a800117',t.FECHATRATAMIENTO>'2024-12-31',t.FECHATRATAMIENTO<'2024-12-31')
					
					UNION ALL 
					
					SELECT 
					  	r.CLIENTEASOCIADO_KEY_OID AS ClientID,
						t.CENTROASOCIADO_KEY_OID AS LaserGClinicIDFrom,
						0 AS LaserGCabinetNum,
						r.FECHAREVISION AS LaserGDate,
						TIME(r.HORAINICIO) AS LaserGStart,
						IFNULL(TIME(r.HORAFIN), TIME(r.HORAINICIO) + INTERVAL 15 MINUTE ) AS LaserGEnd,
						0 AS LaserGTicketGID,
						IFNULL(r.OPERADORASOCIADO_KEY_OID,0) AS LaserGUserIDFrom,
						r.NOMBREESTADO AS __LasergStage,
						CONCAT('REVISION: \n',
								' - Tipo: ',IFNULL(t.TIPO,' - '),'\n',
								' - Observaciones: ',IF(r.OBSERVACIONES='' OR ISNULL(r.OBSERVACIONES) ,' Sin observaciones',r.OBSERVACIONES),'\n',
								' - Revisión externa: ', IF(r.CENTROASOCIADO_KEY_OID!=r.CENTROEXTERNOASOCIADO_KEY_OID,'Si','No'),'\n',		
								IF (r.CENTROASOCIADO_KEY_OID!=r.CENTROEXTERNOASOCIADO_KEY_OID,CONCAT(' - Centro externo asociado: ',c.NOMBRE,'\n'),''),
								' - Código de revisión: ', IFNULL(r.CODIGO,' - '),'\n',	
								' - Operador: ',IFNULL(r.NOMBREOPERADOR,' - ')
						) AS LaserGComments,
						CURDATE() AS LaserGStamp,
						0 AS  __LaserGIDTto,
						r.`KEY` AS __LaserGIDRev,
						0 AS  AS  __LaserGIDMto,
						5 AS __LaserGProductSourceID
					FROM REVISION r 
					INNER JOIN TRATAMIENTO t ON t.`KEY`=r.TRATAMIENTOASOCIADO_KEY_OID
					LEFT JOIN CENTRO c ON c.`KEY`= r.CENTROEXTERNOASOCIADO_KEY_OID
					WHERE  t.TIPO IN ('Diagnóstico') AND  IF(@@server_uuid='02d35120-2210-11e9-80f9-42010a800117',r.FECHAREVISION>'2024-12-31',t.FECHATRATAMIENTO<'2024-12-31')
)tmp
ORDER BY LaserGDate DESC;

#mantenimientos
SELECT 	
	 	m.CLIENTEASOCIADO_KEY_OID AS ClientID,
		m.CENTROASOCIADO_KEY_OID AS LaserGClinicIDFrom,
		0 AS LaserGCabinetNum,
		m.FECHAMANTENIMIENTO AS LaserGDate,
		TIME(m.HORAINICIO) AS LaserGStart,
		IFNULL(TIME(HORAFIN), TIME(HORAINICIO) + INTERVAL 15 MINUTE ) AS LaserGEnd,
		0 AS LaserGTicketGID,
		IFNULL(m.OPERADORASOCIADO_KEY_OID,0) AS LaserGUserIDFrom,
		m.NOMBREESTADO AS __LasergStage,		
		CONCAT('MANTENIMIENTO:\n'			  
			   ' - Observaciones: ',IFNULL(m.OBSERVACIONES,' - '),'\n',	
				' - Código de Bono asociado: ', IFNULL(bm.CODIGOBONO,' - '),'\n',
				' - Operador: ',IFNULL(m.NOMBREOPERADOR,' - '),'\n'	
		) AS ClientCComments ,
	CURDATE() AS LaserGStamp,
	0 AS  __LaserGIDTto,
	0 AS __LaserGIDRev,
	m.`KEY` AS  __LaserGIDMto,
	59 AS __LaserGProductSourceID
FROM MANTENIMIENTO m
INNER JOIN CENTRO C ON C.`KEY`=m.CENTROASOCIADO_KEY_OID
LEFT JOIN BONOS_MANTENIMIENTO bm ON bm.`KEY`=m.BONOASOCIADO_KEY_OID;

SELECT * FROM MANTENIMIENTO;
SELECT * FROM BONOS_MANTENIMIENTO;



SELECT * FROM laser_gen lg INNER JOIN __mig_mapp_clinics mc ON  mc.ClinicIDFrom=lg.LaserGClinicID;
UPDATE laser_gen lg INNER JOIN __mig_mapp_clinics mc ON  mc.ClinicIDFrom=lg.LaserGClinicID SET lg.LaserGCabinetNum=mc.ClinicIDTo;
UPDATE laser_gen lg SET LaserGClinicID=LaserGCabinetNum;

