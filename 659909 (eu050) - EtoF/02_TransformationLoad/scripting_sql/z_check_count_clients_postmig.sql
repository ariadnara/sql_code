-- SE CHEQUEA EL NÚMERO TOTAL DE CLIENTES POR CLINICA

-- ORIGEN
SELECT COUNT(c.`KEY`) AS TotalMigrado, c.`CENTROASOCIADO_KEY_OID`
FROM CLIENTE c
GROUP BY c.CENTROASOCIADO_KEY_OID;
            
-- DESTINO 
SELECT COUNT(c.ClientID) AS TotalMigrado, c.ClientClinicID,mc.ClinicIDFrom
FROM clients c
INNER JOIN __mig_mapp_clinics mc ON mc.ClinicIDTo=c.ClientClinicID
WHERE ClientImportID=20260121
GROUP BY c.ClientClinicID;