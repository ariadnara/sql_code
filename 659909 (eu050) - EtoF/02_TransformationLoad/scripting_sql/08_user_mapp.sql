

-- Ususarios de baja
SELECT * 
FROM __mig_users mu 
INNER JOIN __mig_users_dev dv ON dv.UserIDFrom=mu.UserIDFrom 
WHERE dv.UserLogin!=mu.UserLogin;

-- Usuarios que se sobreescriben
SELECT * 
FROM __mig_users mu 
INNER JOIN __mig_users_dev dv ON dv.UserIDFrom=mu.UserIDFrom 
WHERE dv.UsernameFrom!=mu.UsernameFrom;

-- Usuarios que están en la BD de PRO y no en DEV (16)
SELECT * 
FROM __mig_users mu 
LEFT  JOIN __mig_users_dev dv ON dv.UserIDFrom=mu.UserIDFrom 
WHERE ISNULL(dv.UserIDFrom);

-- Usuarios que están en la BD de DEV y no en PRO
SELECT * 
FROM __mig_users_dev dv 
LEFT  JOIN __mig_users mu ON mu.UserIDFrom=dv.UserIDFrom
WHERE ISNULL(mu.UserIDFrom)

-- Usuarios con el mismo login a gestionar por el cliente
CREATE TABLE __mig_repeat_userslogin
SELECT 
	COUNT( mu.UserIDFrom) AS Items ,
	GROUP_CONCAT(UserIDFrom) AS 'ID Usuarios repetidos',
	GROUP_CONCAT(UsernameFrom)  AS UsernameFrom,
	UserLogin  
FROM __mig_users mu GROUP BY mu.UserLogin HAVING  Items>1;

-- Usuarios SIN correo de login
SELECT xu.UserID, UserLogin, xu.UserName, xu.__UserIdMig FROM x_config_users xu WHERE UserEMail NOT LIKE '%@%' AND xu.UserSuper=0;


#INSERT INTO x_config_users ( UserName, UserNotes, UserLogin, UserEmail,UserDateNew, UserPassword, __UserIdMig, UserCountryID)
SELECT
	mu.UserNameFrom,
	UserClassFrom,
	LOWER(IF(
		(mu.UserLogin NOT  REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR NOT ISNULL(ml.id)>0),
		 CONCAT(UserIDFrom,'.flowww@kidsandnits.es'),
		mu.UserLogin
	)) AS UserLogin,
	LOWER(mu.UserLogin) AS UserEmail,
	mu.UserDate,
	'' AS UserPassword,
	mu.UserIDFrom,
	201 AS UserCountryID
FROM
	__mig_users mu
	LEFT JOIN __mig_repeat_userslogin ml ON ml.UserLogin=mu.UserLogin;
  
#INSERT INTO `x_config_workplaces` ( `WorkPlaceUserID`, `WorkPlaceClinicID`, `WorkPlaceUserClassID`, `WorkPlaceDefault`) 
SELECT 
	xu.UserID AS WorkPlaceUserID,
	IFNULL(mc.ClinicIDTo,0) AS WorkPlaceClinicID,
	16 AS  WorkPlaceUserClassID,
	0 AS WorkPlaceDefault 
FROM x_config_users xu 
	INNER JOIN __mig_operator mo ON mo.userid=xu.__UserIdMig AND __UserIdMig>0
	INNER JOIN __mig_mapp_clinics mc ON mc.ClinicIDFrom=mo.centroasociado_key_oid
WHERE xu.UserEmail NOT LIKE '%baja%';
 

#Listado de usuarios creados
SELECT IFNULL(WorkPlaceClinicID,0) AS UserClinicID, UserName, UserNotes, UserLogin, UserEmail, __UserIdMig 
FROM  x_config_users u 
LEFT JOIN x_config_workplaces w ON w.WorkPlaceUserID=u.UserID  
WHERE u.__UserIdMig>0; 

# Se actualiza el historico nativo
#UPDATE laser_gen lg 
	INNER JOIN __mig_mapp_operator mo ON mo.operadorasociado_key_oid=lg.LaserGUserID
	INNER JOIN x_config_users xu ON xu.__UserIdMig=mo.userid
SET LaserGUserID = xu.UserID
WHERE lg.__LaserMigrated=-1 AND lg.LaserGUserID>0