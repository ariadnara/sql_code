SELECT * FROM  TRATAMIENTO_HST;
SELECT * FROM TRATAMIENTO;
SELECT * FROM REVISION;



#INSERT INTO `clients_crm` (`ClientCClientID`,  `ClientCClass`, `ClientCDate`, `ClientCTime`,ClientCComments) 
SELECT 
  	 CLIENTEASOCIADO_KEY_OID AS ClientID,	
	CONCAT('TRATAMIENTO: \n'
			' - Código de tratamiento: ', IFNULL(CODIGOTRATAMIENTO,' - '),'\n',	
			' - Centro: ', IFNULL(C.NOMBRE,' - '),'\n',	
			' - Secuencial de tratamiento :', IFNULL(SECUENCIALTTO,' - '),'\n',			
			' - Operador: ',IFNULL(OPERADOR,' - '),'\n',
			' - Hora prevista: ',IFNULL(TIME(HORAPREVISTA),' - '),'\n',
			' - Fecha tratamiento: ',IFNULL(DATE_FORMAT(FECHATRATAMIENTO,'%d/%m/%Y'),' - '),'\n',
			' - Tipo: ',IFNULL(TIPO,' - '),'\n',
			' - Observaciones: ',IFNULL(OBSERVACIONES,' - '),'\n',
			' - Estado: ',IFNULL(NOMBREESTADO,' - '),'\n',
			' - Revisión externa: ',if(REVISIONEXTERNA=0,'No','Si'),'\n',
			' - Observaciones de revisión externa: ',IFNULL(OBSERVACIONESREVISIONEXTERNA,' - '),'\n'			
			) AS ClientCComments ,
			'TXT' AS ClientCClass,
			FECHAREVISION AS ClientCDate,
			'00:00' AS ClientCTime
FROM TRATAMIENTO t 
INNER JOIN CENTRO C ON C.`KEY`=t.CENTROASOCIADO_KEY_OID
WHERE t.FECHAREVISION<'2026-01-21'

UNION

SELECT 
		/*m.CLIENTEASOCIADO_KEY_OID,
		m.`KEY` AS MANTENIMIENTO_ID,
		bm.CODIGOBONO,
		C.NOMBRE AS ClinicName,		
		m.FECHAMANTENIMIENTO,
		TIME(m.HORAINICIO) AS Ini,
		TIME(m.HORAFIN) AS fin,
		m.INFESTADO,
		m.NOMBREESTADO,
		m.OPERADORASOCIADO_KEY_OID,
		m.OBSERVACIONES,
		bm.SECUENCIALBONO,
		GROUP_CONCAT(vp.PRODUCTOVENDIDO) AS Productos	
		*/
		
		m.CLIENTEASOCIADO_KEY_OID AS ClientID,	
		CONCAT('MANTENIMIENTO:\n'
				' - Identificador de mantenimiento: ', IFNULL(m.`KEY`,' - '),'\n',	
				' - Centro: ', IFNULL(C.NOMBRE,' - '),'\n',	
				' - Código de Bono asociado: ', IFNULL(bm.CODIGOBONO,' - '),'\n',
				' - Secuencial de Bono :', IFNULL(bm.SECUENCIALBONO,' - '),'\n',			
				' - Operador: ',IFNULL(m.NOMBREOPERADOR,' - '),'\n',			
				' - Hora inicio: ',IFNULL(TIME(m.HORAINICIO),' - '),'\n',
				' - Hora fin: ',IFNULL(TIME(m.HORAFIN),' - '),'\n',			
				' - ¿Infestado?: ',IF(m.INFESTADO=0,'No','Si'),'\n',
				' - Estado: ',IFNULL(m.NOMBREESTADO,' - '),'\n',
				' - Observaciones: ',IFNULL(m.OBSERVACIONES,' - '),'\n',		
				' - Productos vendidos: ',IFNULL(GROUP_CONCAT(vp.PRODUCTOVENDIDO),' - '),'\n'					
				) AS ClientCComments ,
			'TXT' AS ClientCClass,
			FECHAMANTENIMIENTO AS ClientCDate,
			'00:00' AS ClientCTime
FROM MANTENIMIENTO m
INNER JOIN CENTRO C ON C.`KEY`=m.CENTROASOCIADO_KEY_OID
LEFT JOIN BONOS_MANTENIMIENTO bm ON bm.`KEY`=m.BONOASOCIADO_KEY_OID
LEFT JOIN VENTAPRODUCTO vp ON vp.MANTENIMIENTOASOCIADO_KEY_OID=m.`KEY` 
GROUP BY m.`KEY`; 