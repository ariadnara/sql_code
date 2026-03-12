
SELECT 
	bm.CLIENTEASOCIADO_KEY_OID AS VoucherClientID,
	bm.CENTROASOCIADO_KEY_OID AS __VoucherClinicID,
	bm.FECHACONTRATACION AS VoucherDate,
	bm.FECHAINICIO,
	GREATEST(
		GREATEST(bm.FECHAINICIO,bm.FECHACONTRATACION) + INTERVAL CONVERT(bm.TIPO,SIGNED) MONTH
		,MAX(m.FECHAMANTENIMIENTO
	)) AS VoucherExpiryDate,
   IF(
			CONVERT(bm.TIPO,SIGNED)=0 OR CONVERT(bm.TIPO,SIGNED)*2<COUNT(m.`KEY`)
			,COUNT(m.`KEY`)
			,CONVERT(bm.TIPO,SIGNED)*2
		) AS VoucherStatOriginalSessions,
	COUNT(m.`KEY`) AS VoucherUsed, 
   (
		IF(
			CONVERT(bm.TIPO,SIGNED)=0 OR CONVERT(bm.TIPO,SIGNED)*2<COUNT(m.`KEY`)
			,COUNT(m.`KEY`)
			,CONVERT(bm.TIPO,SIGNED)*2
		)-	COUNT(m.`KEY`)
	) AS VoucherAvailable, 
	IF(
		CONVERT(bm.TIPO,SIGNED)=0
		,CEIL(COUNT(m.`KEY`)/2)
		,CONVERT(bm.TIPO,SIGNED)
	) AS VoucherProductID,
	DATE_FORMAT(CURDATE(),'%Y%m%d') AS VoucherImportID,
	CURRENT_TIMESTAMP() AS VoucherDateCreated,
	CONCAT(	bm.CODIGOBONO, ' - ', bm.NOMBREOPERADOR, ' - Último mantenimiento en sistema origen: ', DATE(MAX(m.FECHAMANTENIMIENTO)) ) AS VoucherNotes,
	bm.TIPO AS __VoucherType
 FROM BONOS_MANTENIMIENTO  bm
INNER JOIN MANTENIMIENTO m ON m.BONOASOCIADO_KEY_OID =bm.`KEY`
INNER JOIN CLIENTE c ON c.`KEY`=bm.CLIENTEASOCIADO_KEY_OID
INNER JOIN LINEAFACTURA LF ON LF.
WHERE IF(@@server_uuid='02d35120-2210-11e9-80f9-42010a800117',bm.FECHACONTRATACION>'2024-12-31',bm.FECHACONTRATACION<'2024-12-31')
GROUP BY bm.`KEY`;


-- Bonos en el destino
UPDATE vouchers v 
	INNER JOIN __mig_mapp_vouchers mv ON mv.ProductIDFrom=v.VoucherProductID
	INNER JOIN __mig_mapp_clinics mc ON mc.ClinicIDFrom=v.__VoucherClinicID 
	INNER JOIN x_config_clinics xc ON xc.ClinicID=mc.ClinicIDTo
	INNER JOIN x_config_products_det xp ON xp.ProductGID=xc.ClinicProductGID AND xp.ProductSourceID=mv.ProductSourceID	
SET v.VoucherProductID=xp.ProductID
WHERE VoucherImportID = DATE_FORMAT(CURDATE(),'%Y%m%d');

-- Mapping de bonos
CREATE TABLE __mig_mapp_vouchers 
SELECT 0 AS ProductIDFrom, xp.ProductSourceID,xp.ProductDesc FROM x_config_products_det xp
WHERE xp.ProductDesc LIKE '%Bono%' AND xp.ProductGID=1;
