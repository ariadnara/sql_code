-- INSERT INTO `clients_rep` ( `ClientRepParenthood`, `ClientRepName`, `ClientRepSurnames`, `ClientRepAddress`, `ClientRepPhone`, `ClientRepIDClass`, `ClientRepNIF`, `ClientRepEmail`)

SELECT
'' AS ClientRepParenthood,
	UPPER(REPLACE(c.ClientCustom3,'/','')) AS ClientRepName,
	c.ClientID AS ClientRepSurnames,
	IF(
		ClientCustom6 != '',
		CONCAT(
			'Fecha nacimiento del tutor: ',
			DATE_FORMAT(ClientCustom6, '%d/%m/%Y')
		),
		''
	) AS ClientRepAddress,
	'' AS ClientRepPhone,
	0 AS ClientRepIDClass,
	'' AS ClientRepNIF,
	'' AS ClientRepEmail
FROM
	clients c
WHERE
	c.ClientCustom1 != 'No'
	AND c.ClientCustom3 != ''
	AND c.ClientClinicID=3;
	
	
	SELECT c.ClientID,cr.ClientRepID FROM clients c INNER JOIN clients_rep cr ON cr.ClientRepSurnames=c.ClientID;
-- 	UPDATE  clients c INNER JOIN clients_rep cr ON cr.ClientRepSurnames=c.ClientID 	SET c.ClientClientRepID=cr.ClientRepID