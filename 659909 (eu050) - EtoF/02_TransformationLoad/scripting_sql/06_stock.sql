
-- @Autor: Ariadna RA
-- @date:260129
-- @SK: 659909
-- @Ticket: https://app.hubspot.com/contacts/387545/record/0-5/36393476676
-- @Description: Añadir productos en stock.


-- EXTRAER DEL ORIGEN
SELECT 
	C.`KEY`, C.NOMBRE, I.PRODUCTOASOCIADO_KEY_OID,P.CODIGO, P.NOMBRE, 
	P.PRECIOCOSTE, P.PRECIOVENTAPUBLICO, P.PRECIOVENTACENTRO, 
	P.CODIGOAGRUPACION, P.PRECIOVENTAFRANQUICIADO,P.PRECIOVENTAMASTER, 
	P.PROVEEDOR, I.UNIDADESDISPONIBLES, F.NOMBRE AS NOMBREFAMILIA
FROM INVENTARIO I
INNER JOIN ALMACEN A ON A.`KEY`=I.ALMACENASOCIADO_KEY_OID
INNER JOIN CENTRO C ON C.`KEY`=A.CENTROASOCIADO_KEY_OID
INNER JOIN PRODUCTO P ON P.`KEY`=I.PRODUCTOASOCIADO_KEY_OID
INNER JOIN FAMILIA F ON F.`KEY`=P.FAMILIAASOCIADA_KEY_OID;


-- CARGAR EN DESTINO


SELECT * FROM stock;


-- SET @DISABLE_TRIGGER=FALSE;

-- INSERT INTO `stock` (`StockClinicID`, `StockProductID`, `StockUnits`, `StockMinimum`, `StockStamp`, StockAveragePrice, StockPurchasePrice, StockProviderID)

SELECT 
	/*st.producto AS ProductName, st.centro AS ClinicName ,st.proveedor AS Provider,*/
	xc.ClinicID AS StockClinicID, xp.ProductID AS StockProductID, st.unidadesdisponibles AS StockUnits, 0 AS StockMinimum , 
	NOW() AS StockStamp, REPLACE(st.preciocoste,',','.') AS StockAvaragePrice, REPLACE(st.preciocoste,',','.') AS StockPurchasePrice, xv.ProviderID AS  StockProviderID
FROM 
	__mig_stock st
	INNER JOIN __mig_mapp_clinics mc ON mc.ClinicIDFrom=st.`key`
	INNER JOIN x_config_clinics xc ON xc.ClinicID=mc.ClinicIDTo
	INNER JOIN x_config_providers xv ON xv.ProviderName=st.proveedor
	INNER JOIN x_config_products_det xp  ON xp.ProductDesc=st.producto AND xp.ProductGID=xc.ClinicProductGID;


-- INSERT INTO `stock_registry` (
	`StockRClinicID`, `StockRProductID`, `StockRAmount`, `StockRUnits`,`StockRClass`, 
	`StockRDate`, `StockRTime`, `StockRUTCDate`,	`StockRUTCTime`, StockRProviderID,StockRAveragePrice,
	`StockRComments`
)	
SELECT 
	xc.ClinicID, xp.ProductID, st.unidadesdisponibles, st.unidadesdisponibles, 'U', 
	CURDATE(), CURTIME(), UTC_DATE(), UTC_TIME(),  xv.ProviderID, REPLACE(st.preciocoste,',','.'),
	CONCAT('Creado stock de ',st.unidadesdisponibles,' unidad(es) con fecha ',DATE_FORMAT(CURDATE(), '%d/%m/%Y'),' ',CURTIME(),' por intervención de Sistemas.Implantación.')
FROM 
	__mig_stock st
	INNER JOIN __mig_mapp_clinics mc ON mc.ClinicIDFrom=st.`key`
	INNER JOIN x_config_clinics xc ON xc.ClinicID=mc.ClinicIDTo
	INNER JOIN x_config_providers xv ON xv.ProviderName=st.proveedor
	INNER JOIN x_config_products_det xp  ON xp.ProductDesc=st.producto AND xp.ProductGID=xc.ClinicProductGID;

SET @DISABLE_TRIGGER=NULL;





