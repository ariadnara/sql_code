
SELECT 
	(SELECT COUNT(ClientID) FROM clients) AS Clientes,
	(SELECT COUNT(ca.AccessClientID) FROM clients_access ca) AS Accesos_Clientes,
	(SELECT COUNT(lg.LaserGClientID) FROM laser_gen lg) AS Historiales,
	(SELECT COUNT(ld.LaserID) FROM laser_det ld) AS Detalles_Historiales,
	(SELECT COUNT(dg.DiaryGID) FROM diary_gen dg) AS Citas_invisibles_historico_tto,
	(SELECT COUNT(VoucherID) FROM vouchers v ) AS Bonos,
	-- A corregir
	(SELECT COUNT(ClientID) FROM clients WHERE ClientClinicID=0) AS Clientes_Sin_Clínicas, -- ¿¿¿Dónde colocar losclientes sin clínica de destino en floww???
	(SELECT COUNT(lg.LaserGClientID) FROM laser_gen lg WHERE lg.LaserGClinicID=0) AS Historiales,
	(SELECT COUNT(VoucherID) FROM vouchers v WHERE v.VoucherProductID=0 ) AS Bonos_Sin_Productos;
	
	
	-- ¿¿¿Donde colocar los bonos de tipo curso??
	SELECT c.ClientID,c.ClientClinicID,__VoucherType FROM vouchers v INNER JOIN clients c ON c.ClientID=v.VoucherClientID WHERE v.VoucherProductID=0;
	
