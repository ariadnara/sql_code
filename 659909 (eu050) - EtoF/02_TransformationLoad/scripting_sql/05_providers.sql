

-- Extraer Proveedores
SELECT DISTINCT SUBSTRING(p.PROVEEDOR,1,2)  AS  ProviderCode, p.PROVEEDOR FROM PRODUCTO p;


-- INSERT INTO `x_config_providers` (`ProviderCode`, `ProviderName`) VALUES
 ('AB', 'AB 7 COSMETICOS'),
  ('DE', 'DECEIN'),
  ('RA', 'RAJAPACK'),
  ('DI', 'DITEXTIL'),
  ('DR', 'DR FARNOS'),
  ('OR', 'ORIOL'),
  ('TO', 'TOYBE'),
  ('OF', 'OFAR'),
  ('IN', 'INNOVATEC'),
  ('KN', 'KN'),
  ('TR', 'TRYLAB BIOSCIENCE S.L.'),
  ('BI', 'BIOPLASTICOS GENIL, S.L.');
