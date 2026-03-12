-- --------------------------------------------------------
-- Host:                         test911.flowww.net
-- Versi�n del servidor:         5.7.44-log - MySQL Community Server (GPL)
-- SO del servidor:              Win64
-- HeidiSQL Versi�n:             12.6.0.6765
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Volcando estructura para procedimiento __fRptCheckData_SIRES_CheckFormatNames
DROP PROCEDURE IF EXISTS __fRptCheckData_SIRES_CheckFormatNames;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptCheckData_SIRES_CheckFormatNames`(
	IN `IN_RoleID` TINYINT,
	IN `IN_PersonID` INT,
	OUT `OUT_PersonValidated` INT,
	OUT `OUT_MsgReturned` VARCHAR(500)
)
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:28/11/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	 
	 DECLARE PersonName VARCHAR(60);
    DECLARE PersonSurname1 VARCHAR(60);
    DECLARE PersonSurname2 VARCHAR(60);
    DECLARE PersonNameLength INT;
    DECLARE PersonSurname1Length INT;
    DECLARE PersonSurname2Length INT;
    DECLARE PersonValidated TINYINT DEFAULT 0;
	 DECLARE MsgReturned VARCHAR(500) DEFAULT '';
	 DECLARE PartOfName VARCHAR(50) DEFAULT '';
	 DECLARE LengthOfName VARCHAR(50) DEFAULT '';
	 DECLARE CharRegularExp VARCHAR(100) DEFAULT "^[']?[A-Za-z����]{1,50}((([ ]?[.,/'-]?)|([.,/'-]?[ ]?))[A-Za-z����]{1,50})*$";
    
   
	 IF IN_RoleID!=0 THEN  
		
		#IN_RoleID = 1: Se consulta el id en la tabla de clientes.
		SELECT 
			c.ClientName REGEXP CharRegularExp,
			c.ClientSurname1 REGEXP CharRegularExp,
			c.ClientSurname2 REGEXP CharRegularExp OR c.ClientSurname2='',
			LENGTH(c.ClientName),
			LENGTH(c.ClientSurname1),
			LENGTH(c.ClientSurname2)				
		INTO  
			PersonName,
			PersonSurname1,
			PersonSurname2,
			PersonNameLength,
			PersonSurname1Length,
			PersonSurname2Length
		FROM clients c 	
		WHERE c.ClientID=IN_PersonID; 
	
 	ELSE   			
		
		#IN_RoleID = 0: Se consulta el id en la tabla de usuarios.
		SELECT 
			xu.UserName REGEXP CharRegularExp, 
			xu.UserSurname1 REGEXP CharRegularExp,
			xu.UserSurname2 REGEXP CharRegularExp OR xu.UserSurname2='',
			LENGTH(xu.UserName),
			LENGTH(xu.UserSurname1),
			LENGTH(xu.UserSurname2)		
		INTO  
			PersonName,
			PersonSurname1,
			PersonSurname2,
			PersonNameLength,
			PersonSurname1Length,
			PersonSurname2Length
		FROM x_config_users xu 		
		WHERE xu.UserID=IN_PersonID;
	
	END IF;	 
	
	#Se definen los valores de salida 
	SET OUT_PersonValidated = 1;
	SET OUT_MsgReturned = '';
	
	#Mensajes de salida	
	SET @__MsgForRepExp = 'El XXX debe contener solo letras incluida a �, sin caracteres con acentos y solo se permite como caracteres intermedios de una sola aparici�n .,/- y el espacio.';
	SET @__MsgForLenght = 'El XXX debe tener de 2 a 50 caracteres.';
	
	#Se verifica si hay error de sistasis
	SET PartOfName = (CASE 
		 						 WHEN PersonName IS FALSE THEN 'nombre'
		 						 WHEN PersonSurname1 IS FALSE THEN 'primer apellido'
		 						 WHEN PersonSurname2 IS FALSE THEN 'segundo apellido'
		 					ELSE '' END);	
	
			
	IF PartOfName !='' THEN
		SET OUT_MsgReturned = REPLACE(@__MsgForRepExp,'XXX',PartOfName);
		SET OUT_PersonValidated = 0;	
	END IF;  
	
	#Se verifica si hay error en el tama�o de la cadena	
	SET LengthOfName = (CASE 
	 						 WHEN PersonNameLength NOT BETWEEN 2 AND 50 THEN 'nombre'
	 						 WHEN PersonSurname1Length NOT BETWEEN 2 AND 50  THEN 'primer apellido'
	 						 WHEN PersonSurname2Length NOT BETWEEN 0 AND 50  THEN 'segundo apellido'
	 					ELSE '' END);
	IF LengthOfName !='' THEN
		SET OUT_MsgReturned = REPLACE(@__MsgForLenght,'XXX',LengthOfName);
		SET OUT_PersonValidated = 0;	
	END IF;  
 
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptCheckData_SIRES_CheckPersonalData
DROP PROCEDURE IF EXISTS __fRptCheckData_SIRES_CheckPersonalData;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptCheckData_SIRES_CheckPersonalData`(
	IN `IN_UserID` INT,
	IN `IN_ClientID` INT,
	IN `IN_DiaryDate` DATE
)
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:16/12/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	 
	SET @__IN_DiaryDate = IFNULL(IN_DiaryDate,CURDATE());
	 
	 # 1.  Se verifica que los datos m�nimos personales se encuentren completos tanto por el profesional como del cliente
	SET @OUT_UserValidated=0;
    SET @OUT_UserMsgReturned='';
    SET @OUT_ClientValidated=0;
    SET @OUT_ClientMsgReturned='';
    
    CALL `__fRptCheckData_SIRES_CurpClientOrUser`('0', IN_UserID, @OUT_UserValidated, @OUT_UserMsgReturned);   
    CALL `__fRptCheckData_SIRES_CurpClientOrUser`('1', IN_ClientID, @OUT_ClientValidated, @OUT_ClientMsgReturned);
    
    # 2. Se verifica la edad del paciente en funci�n del tipo de personal antes de generar una cita (SQL).  
    SET @__ClientBirthDate = (SELECT ClientBirthDate FROM clients c WHERE c.ClientID=IN_ClientID);
    SET @__ClientLockData = (SELECT c.ClientLockData FROM clients c WHERE c.ClientID=IN_ClientID);
    SET @__UserCollegeTypeID = (SELECT xu.UserCollegeTypeID FROM x_config_users xu WHERE xu.UserID=IN_UserID);
    SET @__UserBirthDate = (SELECT xu.UserBirthDate FROM x_config_users xu WHERE xu.UserID=IN_UserID);
    
    IF NOT ISNULL(@__ClientBirthDate) THEN
    
    	 SET @__YearsFromBirthClient = TIMESTAMPDIFF(YEAR, @__ClientBirthDate, IN_DiaryDate);
    	 
    	 -- Si el valor registrado es �15 � PASANTE PSICOLOG�A� o �16 � PSIC�LOGA(O)�, se debe validar que la edad del paciente sea menor a �6 a�os�.   
    	 IF @__UserCollegeTypeID IN(15,16) AND @__YearsFromBirthClient>=6 THEN 
    	 	 SET @OUT_UserValidated=0;
		 	 SET @OUT_UserMsgReturned = CONCAT(@OUT_UserMsgReturned,'\n','No puede registrar una consulta a un paciente mayor a 6 a�os.');
    	 END IF;
    	 
    	 -- Si el valor registrado es �25 � LICENCIADA(O) EN GERONTOLOG�A� o �27 � PASANTE DE GERONTOLOG�A� se debe validar que la edad del paciente sea mayor o igual a �60 a�os�.
    	 IF @__UserCollegeTypeID IN(25,27) AND @__YearsFromBirthClient<60 THEN 
	    	 SET @OUT_UserValidated=0;
		 	 SET @OUT_UserMsgReturned = CONCAT(@OUT_UserMsgReturned,'\n','No puede registrar una consulta a un paciente menor a 60 a�os.');
    	 END IF;
    	 
    	 -- En el registro de personas, se debe limitar la edad m�xima a 120 a�os (incluyendo meses y d�as hasta antes de cumplir 121 a�os) para pacientes,
    	 IF @__YearsFromBirthClient>121 THEN 
	    	 SET @OUT_UserValidated=0;
		 	 SET @OUT_UserMsgReturned = CONCAT(@OUT_UserMsgReturned,'\n','No puede registrar una consulta a un paciente mayor a 121 a�os.');
    	 END IF;
    	 
    END IF;
    
    # 3. Se verifica la edad del prestados de servicios (usuario)
    IF NOT ISNULL(@__UserBirthDate) THEN
    
	 	  SET @__YearsFromBirthUser = TIMESTAMPDIFF(YEAR, @__UserBirthDate, IN_DiaryDate);
	 	  
	 	  -- En el registro de prestadores de servicios de salud y responsables se deber� limitar la edad m�nima a 18 a�os y la edad m�xima a 90 a�os (incluyendo meses y d�as hasta antes de cumplir 91 a�os).
    	  IF  NOT(@__YearsFromBirthUser BETWEEN 18 AND 90) THEN 
	    	 SET @OUT_UserValidated=0;
		 	 SET @OUT_UserMsgReturned = CONCAT(@OUT_UserMsgReturned,'\n','No puede registrar una consulta. Como prestador de servicios de salud o responsable debe tener entre 18 y 90 a�os.');
    	 END IF;
    END IF; 
    
    # 4. Se verifica la estructura del nombre tanto del cliente como del prestador de servicios(usuario).
    SET @OUT_UserFullNameValidated=0;
    SET @OUT_UserFullNameMsgReturned='';
    SET @OUT_ClientFullNameValidated=0;
    SET @OUT_ClientFullnameMsgReturned='';
    
    CALL `__fRptCheckData_SIRES_CheckFormatNames`('0', IN_UserID, @OUT_UserFullNameValidated, @OUT_UserFullNameMsgReturned);   
    CALL `__fRptCheckData_SIRES_CheckFormatNames`('1', IN_ClientID, @OUT_ClientFullNameValidated, @OUT_ClientFullnameMsgReturned);
    
    IF  @OUT_UserFullNameValidated=0 THEN 
    		 SET @MsgAdmin = 'Contacte con el administrador para ajustar el perfil de usuario.';
    		 SET @OUT_UserMsgReturned = IF(@OUT_UserValidated=0,CONCAT(@OUT_UserMsgReturned,'\n',@OUT_UserFullNameMsgReturned,'\n',@MsgAdmin),CONCAT(@OUT_UserFullNameMsgReturned,'\n',@MsgAdmin));
	    	 SET @OUT_UserValidated=0;
    END IF;
    
    IF @OUT_ClientFullNameValidated=0 THEN 
    		 SET @OUT_ClientMsgReturned = IF(@OUT_ClientValidated=0,CONCAT(@OUT_ClientMsgReturned,'\n',@OUT_ClientFullnameMsgReturned),@OUT_ClientFullnameMsgReturned);
	    	 SET @OUT_ClientValidated=0;		 	 
    END IF;
   
    # 5. Se verifica que ambos CURP sean diferentes
    SET @__ClientCURP = (SELECT c.ClientCURP FROM clients c WHERE c.ClientID=IN_ClientID);
    SET @__UserCURP = (SELECT xu.UserCURP FROM x_config_users xu WHERE xu.UserID=IN_UserID);
    
    IF @__ClientCURP = @__UserCURP AND @__UserCURP!='XXXX999999XXXXXX99' THEN 
 	 	 SET @OUT_UserValidated=0;
	 	 SET @OUT_UserMsgReturned = CONCAT(@OUT_UserMsgReturned,'\n','El CURP del usuario prestador del servicio debe ser diferente al CURP del paciente.');
 	END IF;
   
   # 6. Record de salida
	 SELECT 
	 	@OUT_UserValidated AS UserValidated,
	 	REPLACE(REPLACE(REPLACE(@OUT_UserMsgReturned,'"','\\"'),'\n','\\n'),'\r','')   AS UserMsgReturned,
	 	@OUT_ClientValidated AS ClientValidated,	 
	 	REPLACE(REPLACE(REPLACE(@OUT_ClientMsgReturned,'"','\\"'),'\n','\\n'),'\r','') AS ClientMsgReturned,
		@__ClientLockData AS ClientLockData;
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptCheckData_SIRES_Curp
DROP PROCEDURE IF EXISTS __fRptCheckData_SIRES_Curp;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptCheckData_SIRES_Curp`(
	IN `IN_curp` CHAR(18),
	IN `IN_name` VARCHAR(60),
	IN `IN_surname1` VARCHAR(60),
	IN `IN_surname2` VARCHAR(60),
	IN `IN_date` DATE,
	IN `IN_sex` CHAR(1),
	IN `IN_entity` CHAR(2),
	OUT `OUT_validated` TINYINT,
	OUT `OUT_error_msg` VARCHAR(2000)
)
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:26/11/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	 
    DECLARE first4char CHAR(4);
    DECLARE first4char_curp CHAR(4);
    DECLARE derogatory_term CHAR(4);
    DECLARE last3char CHAR(3);
    DECLARE date_curp CHAR(6);
    DECLARE sex_curp CHAR(1);
    DECLARE ent_curp CHAR(2);
    DECLARE ch17_curp CHAR(1);
    DECLARE ch18_curp CHAR(1);
    DECLARE regex_curp VARCHAR(1000);
    DECLARE name_clean VARCHAR(60);
    DECLARE surname1_clean VARCHAR(60);
    DECLARE surname2_clean VARCHAR(60);
    DECLARE char1 CHAR(1);
    DECLARE char2 CHAR(1);
    DECLARE char3 CHAR(1);
    DECLARE char4 CHAR(1);
    DECLARE char14 CHAR(1);
    DECLARE char15 CHAR(1);
    DECLARE char16 CHAR(1);
    DECLARE error_msg VARCHAR(2000);
    DECLARE provincecodes VARCHAR(2000);
	
	 END_PROC: BEGIN

	    SET OUT_validated = 1;
	    SET OUT_error_msg = ''; -- CURP v�lida
	    SET IN_curp = UPPER(IN_curp);
	    SET @__IN_name := UPPER(IN_name);
	    SET @__IN_surname1 := UPPER(IN_surname1);
	    SET @__IN_surname2 := UPPER(IN_surname2);   	    
	  
	    -- 1) Longitud  
	    IF LENGTH(IN_curp) <> 18 THEN
	        SET OUT_validated = 0;
	        SET error_msg = 'La longitud debe ser de 18 caracteres.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	
			  -- LEAVE END_PROC;        
	    END IF;
	  
	    -- 2) Regex de estructura CURP
		 SET provincecodes = IFNULL((SELECT GROUP_CONCAT(xp.ProvinceCode SEPARATOR '|') AS ProvinceCode FROM x_config_provinces xp WHERE xp.ProvinceCountryID=142),'');
	    
	    SET regex_curp = CONCAT(
	      '^[A-Z][AEIOUX][A-Z]{2}',
	      '[0-9]{2}[0-1][0-9][0-3][0-9]',
	      '[HM]',
	      '(',provincecodes,')',
	      '[B-DF-HJ-NP-TV-Z]{3}',
	      '[0-9A-Z]{2}$');
	
	    IF IN_curp NOT REGEXP regex_curp THEN
	        SET OUT_validated = 0;
	        SET error_msg = 'Formato CURP inv�lido.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));
			  -- LEAVE END_PROC;	        
	    END IF;
	  
	    -- 3) Extract from CURP  
	    SET first4char_curp = SUBSTRING(IN_curp, 1, 4);
	    SET last3char = SUBSTRING(IN_curp, 14, 3);
	    SET date_curp = SUBSTRING(IN_curp, 5, 6);
	    SET sex_curp  = SUBSTRING(IN_curp, 11, 1);
	    SET ent_curp   = SUBSTRING(IN_curp, 12, 2);	  
	  
	    -- 4) Normalizar nombres (casos especiales RENAPO) 
	    SET name_clean = __fRptCheckData_SIRES_CurpIgnoreFromName(UPPER(@__IN_name),1);      
	    SET surname1_clean = __fRptCheckData_SIRES_CurpIgnoreFromName(UPPER(@__IN_surname1),0);  
	    SET surname2_clean = __fRptCheckData_SIRES_CurpIgnoreFromName(UPPER(@__IN_surname2),0); 
	  
	    -- 5) Validaci�n apellidos/nombre contra primeros 4 caracteres  (1-4)
	    SET char1 = SUBSTRING(surname1_clean, 1, 1);
	    SET char2 = __fRptGetData_SIRES_CurpCharAfterPos(surname1_clean,LOCATE(char1,surname1_clean),'vocal');
	    SET char3 = SUBSTRING(surname2_clean, 1, 1);
	    SET char4 = SUBSTRING(name_clean, 1, 1);
	    SET char14 =  __fRptGetData_SIRES_CurpCharAfterPos(surname1_clean,LOCATE(char1,surname1_clean),'consonante');
	    SET char15 =  __fRptGetData_SIRES_CurpCharAfterPos(surname2_clean,LOCATE(char3,surname2_clean),'consonante');
	    SET char16 =  __fRptGetData_SIRES_CurpCharAfterPos(name_clean,LOCATE(char4,name_clean),'consonante');
		
		SET first4char=REPLACE(CONCAT(char1, char2, char3, char4),'�','X');		 
	    SET derogatory_term=__fRptReplacetData_SIRES_CurpDerogatoryTerm(first4char);
	   
	    IF first4char_curp <> first4char AND first4char_curp <> derogatory_term THEN
	        SET OUT_validated = 0;
	        SET error_msg = 'Las letras iniciales del CURP no coinciden con los nombres y apellidos.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	  
	        -- LEAVE END_PROC;
	    END IF;	    
	    
	    SET derogatory_term=__fRptReplacetData_SIRES_CurpDerogatoryTerm(first4char);
	    IF first4char <> derogatory_term AND first4char_curp=first4char   THEN
	        SET OUT_validated = 0;
	        SET error_msg =  'Las letras iniciales del CURP constituyen una palabra altizonante. Debe sustituir la primera vocal por X.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	  
	        -- LEAVE END_PROC;
	    END IF;
	    
	    IF CONCAT(char1, char2, char3)='XXX' AND char4!='X'  THEN
	        SET OUT_validated = 0;
	        SET error_msg = 'La persona registrada no cuenta con apellidos por lo es DESCONOCIDA.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	  
	        -- LEAVE END_PROC;
	    END IF;
	  
	    -- 6) Validar fecha exacta  (5-10)
	    IF  DATE_FORMAT(IFNULL(IN_date,CURDATE()),'%y%m%d') <> date_curp THEN
	        SET OUT_validated = 0;
	        SET error_msg = 'La fecha no coincide.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	 
	        -- LEAVE END_PROC;
	    END IF;
	  
	    -- 7) Validar sexo  (11)
	    IF UPPER(IFNULL(IN_sex,'')) <> sex_curp THEN
	        SET OUT_validated = 0;
	        SET error_msg = 'Sexo incorrecto.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	 
	        -- LEAVE END_PROC;
	    END IF;
	  
	    -- 8) Validar entidad  (12-13)
	    IF UPPER(IFNULL(IN_entity,'')) <> ent_curp AND  UPPER(IFNULL(IN_entity,'')) <> 'NA' THEN
	        SET OUT_validated = 0;
	        SET error_msg = 'Entidad incorrecta.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	 
	        -- LEAVE END_PROC;
	    END IF;
	    
	      -- 9) Validaci�n apellidos/nombre contra pen�ltimos 3 caracteres (14-16)
	     IF last3char <> REPLACE(CONCAT(char14, char15, char16),'�','X') THEN
	        SET OUT_validated = 0;
	        SET error_msg = 'Las consonantes siguientes a las letras iniciales del CURP no coinciden con los nombres y apellidos.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	 
	        -- LEAVE END_PROC;
	    END IF;  
	    
	       -- 10) Validaci�n contra el pen�ltimo caracter (17)	        
	     IF  ch17_curp NOT REGEXP IF(STR_TO_DATE(date_curp,'%y%m%d')<'2000-01-01','[0-9]','[ABCDEFGHIJ]') THEN
	     	  SET OUT_validated = 0;
	        SET error_msg = 'El caracter 17 no se corresponde con la fecha de nacimiento. ';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	 		  
		     -- LEAVE END_PROC;
	    END IF; 
	    
	      -- 11) Validaci�n �ltimo caracter (18)	        
	     IF  ch18_curp NOT REGEXP '[0-9]' THEN
	     	  SET OUT_validated = 0;
	        SET error_msg = 'El caracter 18 no se corresponde con el que se debe asignar por el algoritmo de asignaci�n.';
	        SET OUT_error_msg = IF(OUT_error_msg='',error_msg, CONCAT(OUT_error_msg,'\n',error_msg));	 		  
		     -- LEAVE END_PROC;
	    END IF; 
    
     END END_PROC;  
	  
	  SET  OUT_error_msg =if(OUT_validated=1,'CURP v�lida.',OUT_error_msg); 

	

END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptCheckData_SIRES_CurpClientOrUser
DROP PROCEDURE IF EXISTS __fRptCheckData_SIRES_CurpClientOrUser;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptCheckData_SIRES_CurpClientOrUser`(
	IN `IN_RoleID` TINYINT,
	IN `IN_PersonID` INT,
	OUT `OUT_PersonValidated` INT,
	OUT `OUT_MsgReturned` VARCHAR(2000)
)
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:28/11/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	 
	 DECLARE PersonName VARCHAR(60);
    DECLARE PersonSurname1 VARCHAR(60);
    DECLARE PersonSurname2 VARCHAR(60);
    DECLARE PersonBirthDate VARCHAR(10);
    DECLARE PersonSex CHAR(1);
    DECLARE PersonProvinceCode CHAR(2);
    DECLARE PersonCurp VARCHAR(18);
    DECLARE PersonValidated TINYINT DEFAULT 0;
	 DECLARE MsgReturned VARCHAR(2000) DEFAULT 'Debe rellenar los datos m�nimos de la persona para comprobar el CURP: Nombre, Apellidos, Sexo, Fecha de nacimiento, Entidad de nacimiento.';
    
   
	IF IN_RoleID!=0 THEN  
		
		#IN_RoleID = 1: Se consulta el id en la tabla de clientes.
		SELECT 
			c.ClientName,
			c.ClientSurname1,
			c.ClientSurname2,
			c.ClientBirthDate,
			CASE c.ClientSex
				WHEN 'F' THEN 'M'
				WHEN 'M' THEN 'H'
				ELSE 'X'
			END AS ClientSex,
			IF(c.ClientBirthProvinceID!=142,'NA',xp.ProvinceCode) AS ProvinceCode,	
			c.ClientCURP 
		INTO  
			PersonName,
			PersonSurname1,
			PersonSurname2,
			PersonBirthDate, 
			PersonSex, 
			PersonProvinceCode, 
			PersonCurp 
		FROM clients c 
		LEFT JOIN X_config_provinces xp ON xp.ProvinceID=c.ClientBirthProvinceID
		WHERE c.ClientID=IN_PersonID; 
	
	ELSE   			
		
		#IN_RoleID = 0: Se consulta el id en la tabla de usuarios.
		SELECT 
			xu.UserName, 
			xu.UserSurname1,
			xu.UserSurname2,
			xu.UserBirthDate,
			CASE xu.UserSex
				WHEN 'F' THEN 'M'
				WHEN 'M' THEN 'H'
				ELSE 'X'
			END AS UserSex,
			IF(xu.UserBirthCountryID!=142,'NA',xp.ProvinceCode) AS ProvinceCode,				
			xu.UserCURP  
		INTO  
			PersonName,
			PersonSurname1,
			PersonSurname2,			
			PersonBirthDate,
			PersonSex, 		  			
			PersonProvinceCode, 
			PersonCurp 
		FROM x_config_users xu 
		LEFT JOIN X_config_provinces xp ON xp.ProvinceID=xu.UserBirthProvinceID
		WHERE xu.UserID=IN_PersonID;
	
	END IF;	  	
 
	IF NOT ISNULL(PersonCurp) AND PersonCurp!='XXXX999999XXXXXX99' THEN 	
		CALL __fRptCheckData_SIRES_Curp(PersonCurp,PersonName,PersonSurname1,PersonSurname2,PersonBirthDate,PersonSex,PersonProvinceCode,PersonValidated,MsgReturned);		
		SET OUT_PersonValidated=PersonValidated;
		SET OUT_MsgReturned=CONCAT('Verificaci�n de CURP: ', IFNULL(PersonCurp,'No definido.') ,'\n','Datos: ',CONCAT_WS('|',PersonName,PersonSurname1,PersonSurname2,PersonBirthDate,PersonSex,PersonProvinceCode), '\n',MsgReturned);
	ELSE 
		IF  PersonCurp='XXXX999999XXXXXX99' THEN 
			SET OUT_PersonValidated=1;
			SET OUT_MsgReturned=MsgReturned;	
		ELSE 
			SET OUT_PersonValidated=0;
			SET OUT_MsgReturned=MsgReturned;		
		END IF;
	END IF;
	
-- CASO DE TEST________________________________________
-- SET @OUT_PersonValidated=0;
-- SET @OUT_MsgReturned='';
-- CALL `__fRptCheckData_SIRES_CurpClientOrUser`('1', '66', @OUT_PersonValidated, @OUT_MsgReturned);
-- SELECT @OUT_PersonValidated, @OUT_MsgReturned;
-- SELECT * FROM clients c WHERE c.ClientID=66;  
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptDeleteData_SIRES_Diary
DROP PROCEDURE IF EXISTS __fRptDeleteData_SIRES_Diary;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptDeleteData_SIRES_Diary`(
	IN `IN_ClientID` INT,
	IN `IN_DiaryID` INT,
	IN `IN_DiaryGDate` VARCHAR(10),
	IN `IN_Service` INT,
	IN `IN_TypeDiary` INT,
	IN `IN_ClinicID` INT,
	IN `IN_UserID` INT
)
    COMMENT 'Permite eliminar una consulta.'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:29/04/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	
	#.Determinar si existe una cita en la fecha fijada para el tratamiento y cliente seleccionado que no haya sido exportada el SIRES.
	SET @__SDiaryGID = IFNULL((SELECT SDiaryGID FROM __sires_diary_gen sdg WHERE ((sdg.SDiaryGClientID=IN_ClientID AND sdg.SClinicID=IN_ClinicID AND sdg.SDiaryGDate=IN_DiaryGDate AND FIND_IN_SET(IN_Service,sdg.SDiaryGServiceID)>0) OR SDiaryGID=IN_DiaryID)  AND sdg.SDiaryGIdExport=0 LIMIT 1),0);
	
	#. Se determina el usuario de dicha consulta para poder guardar registro de losdatos de la misma
	SET @__SDiaryGUserID = IFNULL((SELECT SDiaryGUserID FROM __sires_diary_gen sdg WHERE ((sdg.SDiaryGClientID=IN_ClientID AND sdg.SClinicID=IN_ClinicID AND sdg.SDiaryGDate=IN_DiaryGDate AND FIND_IN_SET(IN_Service,sdg.SDiaryGServiceID)>0) OR SDiaryGID=IN_DiaryID)  AND sdg.SDiaryGIdExport=0 LIMIT 1),0);

	#. Se obtiene la cabecera de la consulta.
	#SET @__SRegistryHeadData = IFNULL((SELECT GROUP_CONCAT(FieldName SEPARATOR '|') FROM __sires_x_config_field WHERE FieldDisabled = 0 AND FieldTypeDiary IN (0,IN_TypeDiary)),'');		
	SET @__SRegistryHeadData = IFNULL((SELECT GROUP_CONCAT(FieldName SEPARATOR '|') FROM __sires_x_config_field xcf INNER JOIN __sires_x_config_field_section xcs  ON  xcs.FieldSectionID=xcf.FieldSectionID WHERE FieldDisabled = 0 AND FieldTypeDiary IN (0,IN_TypeDiary) ORDER BY FieldSectionOrder,FieldOrderInSection ASC),'');		
	
	#. Se obtienen los datos de la consulta
	SET @__strValues = '';
	SET @__SRegistryData = '';
								
	SET @__sql_data_user_entity = (
		  SELECT GROUP_CONCAT(
		    CONCAT(
		      ' SELECT ',
		        'FieldID, FieldName, FieldDefaultValue, ',
		        '(SELECT ', 
		          SUBSTRING_INDEX(xcf.FieldNameFrom, '.', -1) ,
		        ' FROM ', 
		          SUBSTRING_INDEX(xcf.FieldNameFrom, '.', 1), 
		        ' WHERE ',
		          IF(SUBSTRING_INDEX(xcf.FieldNameFrom, '.', 1) = 'x_config_clinics', CONCAT('ClinicID = ',IN_ClinicID), CONCAT('UserID = ',@__SDiaryGUserID)),
		        ') AS FieldValue, ',xcs.FieldSectionOrder,' AS FieldSectionOrder,',xcf.FieldOrderInSection, ' AS FieldOrderInSection ',
		      ' FROM __sires_x_config_field xcf ',
		      ' WHERE FieldID = ', xcf.FieldID
		    )
		    SEPARATOR ' UNION ALL '
		  )
		  FROM __sires_x_config_field xcf
		  JOIN __sires_x_config_field_section xcs 
		    ON xcs.FieldSectionID = xcf.FieldSectionID 
		   AND xcs.FieldSectionTypeData > 1 
		  WHERE FieldDisabled = 0
		);							
		
		SET @__sql_data_client = (SELECT CONCAT(' ( SELECT FieldID,FieldName,FieldDefaultValue,if(FieldName like \'fecha%\', DATE_FORMAT(c.SClientFieldValue,\'%d/%m/%Y\'),CONVERT(c.SClientFieldValue USING utf8mb4)) AS FieldValue,FieldSectionOrder,FieldOrderInSection FROM  __sires_x_config_field xcf INNER JOIN __sires_x_config_field_section xcs ON xcs.FieldSectionID=xcf.FieldSectionID AND xcs.FieldSectionTypeData=1  LEFT JOIN __sires_clients c ON c.SClientFieldID=xcf.FieldID AND (ISNULL(c.SClientID) OR c.SClientID=',IN_ClientID,') LEFT JOIN clients cl ON cl.ClientID=',IN_ClientID,' WHERE  FieldDisabled = 0  AND xcf.FieldTypeDiary IN (0,',IN_TypeDiary,'))'));
		SET @__sql_data_diary = (SELECT CONCAT('( SELECT  FieldID,FieldName,FieldDefaultValue,if(FieldName like \'fecha%\', DATE_FORMAT(SDiaryFieldValue,\'%d/%m/%Y\'),CONVERT(SDiaryFieldValue USING utf8mb4) )  AS FieldValue,FieldSectionOrder,FieldOrderInSection FROM  __sires_x_config_field xcf INNER JOIN __sires_x_config_field_section xcs ON xcs.FieldSectionID=xcf.FieldSectionID AND xcs.FieldSectionTypeData=0  LEFT JOIN  __sires_diary_det d ON d.SDiaryFieldID=xcf.FieldID AND (ISNULL(d.SDiaryGID) OR d.SDiaryGID=',@__SDiaryGID,')  WHERE  FieldDisabled = 0 AND xcf.FieldTypeDiary IN (0,',IN_TypeDiary,'))'));
		
		SET @__sql_data_union = (SELECT CONCAT_WS(' UNION ALL ', @__sql_data_user_entity, @__sql_data_client, @__sql_data_diary));
		SET @__sql_data = (SELECT CONCAT('SELECT GROUP_CONCAT( CASE FieldName WHEN \'nombrePrestador\' THEN __fRptGetData_SIRES_StrPartOfFullName(FieldValue,1) WHEN \'primerApellidoPrestador\' THEN __fRptGetData_SIRES_StrPartOfFullName(FieldValue,2) WHEN \'segundoApellidoPrestador\' THEN __fRptGetData_SIRES_StrPartOfFullName(FieldValue,3) ELSE FieldValue END ORDER BY FieldSectionOrder,FieldOrderInSection ASC) INTO @__strValues FROM (',@__sql_data_union,')tmp;'));
	
		PREPARE stmt FROM @__sql_data;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
																
	#Se actualiza el string de exportaci�n de la consulta.
	IF @__strValues!='' THEN	
		SET @__SRegistryData = UPPER(REPLACE(@__strValues,',','|'));		
	END IF;	
	
	#Se elimina la consulta y se gaurda registro de la acci�n
	IF @__SDiaryGID>0 THEN
	/*
			DECLARE EXIT HANDLER FOR SQLEXCEPTION
			BEGIN
			    ROLLBACK;
			    SET @__msgReturn = 'lbl_undelete_diary_admin';
			    SELECT @__msgReturn;
			END;	*/	
	
			#. Se inicia bloque de operaciones
			START TRANSACTION;		
		
			#. Se inserta registro de la acci�n
			INSERT INTO `__sires_delete_registry` (`SRegistryDiarySGID`, `SRegistryTypeDiary`, `SRegistryUserID`, `SRegistryHeadData`, `SRegistryData`, `SRegistryClinicID`, `SRegistryDateTime`) VALUES (@__SDiaryGID, IN_TypeDiary, IN_UserID, @__SRegistryHeadData, @__SRegistryData, IN_ClinicID, NOW());
			
			#. Si existe la cita se eliminan los registros creados
			DELETE FROM __sires_diary_det WHERE SDiaryGID=@__SDiaryGID;
			DELETE FROM __sires_diary_gen WHERE SDiaryGID=@__SDiaryGID;
			
			#. Se eliminan los datos del clientes en caso se existir alg�n cambio en la ficha del cliente sino se ha registrado en el SIRES ninguna cita previa.
			SET @__ExistDiaryGIDInSIRES = IFNULL((SELECT COUNT(SDiaryGID) FROM __sires_diary_gen sdg WHERE sdg.SDiaryGClientID=IN_ClientID /*AND sdg.SDiaryGIdExport>0*/),0);
			
			IF @__ExistDiaryGIDInSIRES=0 THEN
				DELETE FROM __sires_clients WHERE SClientID=IN_ClientID;	
				UPDATE clients c SET c.ClientLockData = 0 WHERE c.ClientID=IN_ClientID; 	
			END IF;
			
			COMMIT;
			
			SET  @__msgReturn = 'lbl_delete_diary';	 			
			
	ELSE 
			SET  @__msgReturn = 'lbl_undelete_diary';	 
	END IF;
	
	SELECT @__msgReturn AS msg;	
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptGetData_SIRES_ClientData
DROP PROCEDURE IF EXISTS __fRptGetData_SIRES_ClientData;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptGetData_SIRES_ClientData`(
	IN `IN_Clientid` INT,
	IN `IN_Diaryid` INT,
	IN `IN_DiaryGDate` VARCHAR(50),
	IN `IN_Service` INT,
	IN `IN_TypeDiary` INT,
	IN `IN_ClinicID` INT,
	IN `IN_UserID` INT
)
    COMMENT 'Obtiene las variables registradas por consulta (integraci�n SIRES M�xico)'
BEGIN

/*
 * @Autor: Ariadna RA
 * @Created:14/04/2025
 * @Ticket HS: 22055276319
 * @Rpt:sires_form
 */

#. Se determina si existe una cita previa en el a�o.
SET @firthDiaryInYear = IFNULL((SELECT MIN(sdg.SDiaryGID) FROM __sires_diary_det sdt INNER  JOIN  __sires_diary_gen sdg ON sdg.SDiaryGID=sdt.SDiaryGID INNER JOIN __sires_x_config_field f ON f.FieldID=sdt.SDiaryFieldID WHERE sdg.SDiaryGClientID=IN_Clientid AND sdg.SClinicID=IN_ClinicID AND f.FieldName='primeraVezAnio' AND sdt.SDiaryFieldValue=1 AND IF(ISNULL(@IN_DiaryGDate),(YEAR(sdg.SDiaryGDate)=YEAR(CURDATE())),(YEAR(sdg.SDiaryGDate)=YEAR(IN_DiaryGDate)))),0);


#. Se identifica el id de la consulta que se procesa.
IF IN_Diaryid!=0 THEN
	SET @__DiaryGID = IN_Diaryid;
ELSE 
	#.Determinar si existe una cita en la fecha fijada para el tratamiento y cliente seleccionado que no haya sido exportada el SIRES.
	SET @__DiaryGID = IFNULL((SELECT SDiaryGID FROM __sires_diary_gen sdg WHERE sdg.SDiaryGClientID=IN_Clientid AND sdg.SClinicID=IN_ClinicID AND sdg.SDiaryGDate=IN_DiaryGDate AND  sdg.SDiaryGUserID=IN_UserID AND FIND_IN_SET(IN_Service,sdg.SDiaryGServiceID)>0  /*AND sdg.SDiaryGIdExport=0 */LIMIT 1),0);
END IF;
	
#. Se obtienen las variables y sus valores
SELECT * FROM (	
		SELECT 
			FieldID,FieldName,FieldDesc,FieldTypeView,REPLACE(REPLACE(REPLACE(FieldJSONValues,'"','\\"'),'\n','\\n'),'\r','') AS  FieldJSONValues, REPLACE(REPLACE(REPLACE(REPLACE(FieldCheckFn,'\\','\\\\'),'"','\\"'),'\n','\\n'),'\r','') AS  FieldCheckFn, /*REPLACE(REPLACE(REPLACE(FieldCheckFnDesc,'"','\\"'),'\n','\\n'),'\r','')*/ '' AS FieldCheckFnDesc, xcs.FieldSectionID,FieldDefaultValue,FieldMandatory,
			(CASE FieldName
				WHEN 'nombre' THEN IF(ISNULL(c.SClientFieldID),REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(TRIM(UPPER(ClientName)),1,50),'�','A'),'�','E'),'�','I'),'�','O'),'�','U'),c.SClientFieldValue)
				WHEN 'primerApellido' THEN IF(ISNULL(c.SClientFieldID),REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(TRIM(UPPER(ClientSurname1)),1,50),'�','A'),'�','E'),'�','I'),'�','O'),'�','U') ,c.SClientFieldValue)
				WHEN 'segundoApellido' THEN IF(ISNULL(c.SClientFieldID),REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(TRIM(UPPER(ClientSurname2)),1,50),'�','A'),'�','E'),'�','I'),'�','O'),'�','U'),c.SClientFieldValue)
				WHEN 'fechaNacimiento' THEN IF(ISNULL(c.SClientFieldID),ClientBirthDate,c.SClientFieldValue)
				WHEN 'curpPaciente' THEN IF(ISNULL(c.SClientFieldID),cl.ClientCURP,c.SClientFieldValue)
				WHEN 'paisNacPaciente' THEN IF(ISNULL(c.SClientFieldID),xcc.CountrySIRESKey,c.SClientFieldValue)
				WHEN 'entidadNacimiento' THEN IF(ISNULL(c.SClientFieldID),xcp.ProvinceSiresCatalogKey,c.SClientFieldValue)
				WHEN 'sexoCURP' THEN IF(ISNULL(c.SClientFieldID),(CASE cl.ClientSex WHEN 'F' THEN 2 WHEN 'M' THEN 1 ELSE 3 END),c.SClientFieldValue)
				WHEN 'sexoBiologico' THEN IF(ISNULL(c.SClientFieldID),(CASE cl.ClientSexByGender WHEN 'F' THEN 2 WHEN 'M' THEN 1 ELSE 3 END),c.SClientFieldValue)
			ELSE 	
				SClientFieldValue 
			END) AS FieldValue,
			FieldOrderInSection,
			FieldSectionOrder
		FROM 
			__sires_x_config_field xcf
			INNER JOIN __sires_x_config_field_section xcs ON xcs.FieldSectionID=xcf.FieldSectionID AND xcs.FieldSectionTypeData=1 
			LEFT JOIN __sires_clients c ON c.SClientFieldID=xcf.FieldID AND (ISNULL(c.SClientID) OR c.SClientID=IN_Clientid)
			LEFT JOIN clients cl ON cl.ClientID=IN_Clientid	
			LEFT JOIN x_config_countries xcc ON xcc.CountryID=cl.ClientBirthCountryID
			LEFT JOIN x_config_provinces xcp ON xcp.ProvinceID=cl.ClientBirthProvinceID
		WHERE 
			FieldDisabled = 0 
			AND (xcf.FieldTypeDiary=IN_TypeDiary OR xcf.FieldTypeDiary=0)
			
		UNION 
		
		SELECT 
			FieldID,FieldName,FieldDesc,FieldTypeView,REPLACE(REPLACE(REPLACE(FieldJSONValues,'"','\\"'),'\n','\\n'),'\r','') AS  FieldJSONValues,REPLACE(REPLACE(REPLACE(REPLACE(FieldCheckFn,'\\','\\\\'),'"','\\"'),'\n','\\n'),'\r','') AS  FieldCheckFn,/*REPLACE(REPLACE(REPLACE(FieldCheckFnDesc,'"','\\"'),'\n','\\n'),'\r','')*/ '' AS FieldCheckFnDesc, xcs.FieldSectionID,FieldDefaultValue,FieldMandatory,
			(CASE FieldName 				
				WHEN 'primeraVezAnio' THEN IF(@__DiaryGID=0,IF(@__DiaryGID=@firthDiaryInYear,1,0),SDiaryFieldValue)
				WHEN 'codigoCIEDiagnostico1'  THEN (SELECT CONCAT_WS(',',DiagnosisCatalogKey, DiagnosisName,DiagnosisCachildday,DiagnosisChronicday) FROM __sires_x_config_diagnosis WHERE DiagnosisCatalogKey = SDiaryFieldValue)
				WHEN 'codigoCIEDiagnostico2'  THEN (SELECT CONCAT_WS(',',DiagnosisCatalogKey, DiagnosisName,DiagnosisCachildday,DiagnosisChronicday) FROM __sires_x_config_diagnosis WHERE DiagnosisCatalogKey = SDiaryFieldValue)
				WHEN 'codigoCIEDiagnostico3'  THEN (SELECT CONCAT_WS(',',DiagnosisCatalogKey, DiagnosisName,DiagnosisCachildday,DiagnosisChronicday) FROM __sires_x_config_diagnosis WHERE DiagnosisCatalogKey = SDiaryFieldValue)
			ELSE
				SDiaryFieldValue 
			END) AS FieldValue,
			FieldOrderInSection,
			FieldSectionOrder
		FROM 
			__sires_x_config_field xcf
			INNER JOIN __sires_x_config_field_section xcs ON xcs.FieldSectionID=xcf.FieldSectionID AND xcs.FieldSectionTypeData=0 
			LEFT JOIN  __sires_diary_det d ON d.SDiaryFieldID=xcf.FieldID AND (ISNULL(d.SDiaryGID) OR d.SDiaryGID=@__DiaryGID) 
		WHERE 
			FieldDisabled = 0
			AND (xcf.FieldTypeDiary=IN_TypeDiary OR xcf.FieldTypeDiary IN (0,IN_TypeDiary))
			AND xcf.FieldHiddenInForm NOT IN (-1,IN_TypeDiary)
			
	)tmp
	ORDER BY FieldSectionOrder, FieldOrderInSection ASC;
		
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptGetData_SIRES_Diagnosis
DROP PROCEDURE IF EXISTS __fRptGetData_SIRES_Diagnosis;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptGetData_SIRES_Diagnosis`(
	IN `IN_DiagnosisName` VARCHAR(250),
	IN `IN_Sex` INT,
	IN `IN_BirthDate` VARCHAR(50),
	IN `IN_UserID` INT,
	IN `IN_DiaryType` INT,
	IN `IN_DiaryDate` VARCHAR(50),
	IN `IN_RelationsTmp` INT
)
    COMMENT 'Permite obtener el listado de diasn�sticos posibles seg�n la edad del paciente, el sexo y el profesional que lo atiende.'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:14/04/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	
	-- Se determina la edad del cliente
	SET @__BirthDate = if(IN_BirthDate='',CURDATE(),IN_BirthDate);
	SET @__DiaryDate = if(IN_DiaryDate='',CURDATE(),IN_DiaryDate);
	SET @__Age = TIMESTAMPDIFF(YEAR,@__BirthDate,@__DiaryDate);
	SET @__IN_DiagnosisName = UPPER(IN_DiagnosisName);
	SET @__IN_Sex = CASE IN_Sex
						    WHEN 2 THEN 'MUJER'
						    WHEN 1 THEN 'HOMBRE'
						    ELSE 'NO'
						END;
	
	IF LENGTH(@__IN_DiagnosisName)>=4 THEN
	
		-- Para consultas de Salud Bucal
		IF IN_DiaryType = 1 THEN
			
			SELECT 
				DiagnosisID AS id, 
				DiagnosisCatalogKey AS code,
				REPLACE(REPLACE(REPLACE(CONCAT(DiagnosisCatalogKey,' - ',DiagnosisName),'"','\\"'),'\n','\\n'),'\r','') AS 'name',
				(CASE DiagnosisLsex  WHEN 'MUJER' THEN 2 WHEN 'HOMBRE' THEN 1 ELSE 0 END) AS lsex, 
				DiagnosisLinf AS linf, 
				DiagnosisLsup AS lsup, 
				DiagnosisChronicday AS chronicday, 
				DiagnosisCachildday AS cachildday, 
				DiagnosisStaffTypeFirthCE AS stafftypefirthce,
				DiagnosisStaffTypeCE AS stafftypece,
				DiagnosisValidSB AS validsb 
			FROM
				__sires_x_config_diagnosis sd
				INNER JOIN x_config_users xu ON FIND_IN_SET(xu.UserCollegeTypeID,DiagnosisValidSB)>0
			WHERE 		
	  			(MATCH(DiagnosisCatalogKey, DiagnosisName) AGAINST(@__IN_DiagnosisName IN BOOLEAN MODE) OR @__IN_DiagnosisName = '')			
				AND (sd.DiagnosisLsex=@__IN_Sex OR sd.DiagnosisLsex='NO')
				AND (@__Age BETWEEN CONVERT(sd.DiagnosisLinf,SIGNED) AND CONVERT(sd.DiagnosisLsup,SIGNED)  OR sd.DiagnosisLinf='NO')
				AND xu.UserID=IN_UserID
			GROUP BY id;
				
		-- Para consultas de Consulta Externa	
		ELSE	
		
			SELECT 
				DiagnosisID AS id, 
				DiagnosisCatalogKey AS code,
				REPLACE(REPLACE(REPLACE(CONCAT(DiagnosisCatalogKey,' - ',DiagnosisName),'"','\\"'),'\n','\\n'),'\r','') AS 'name',
				(CASE DiagnosisLsex  WHEN 'MUJER' THEN 2 WHEN 'HOMBRE' THEN 1 ELSE 0 END) AS lsex, 
				DiagnosisLinf AS linf, 
				DiagnosisLsup AS lsup, 
				DiagnosisChronicday AS chronicday, 
				DiagnosisCachildday AS cachildday, 
				DiagnosisStaffTypeFirthCE AS stafftypefirthce,
				DiagnosisStaffTypeCE AS stafftypece,
				DiagnosisValidSB AS validsb 				
			FROM
				__sires_x_config_diagnosis sd
				INNER JOIN x_config_users xu ON FIND_IN_SET(xu.UserCollegeTypeID,if(IN_RelationsTmp=0,sd.DiagnosisStaffTypeFirthCE,sd.DiagnosisStaffTypeCE))>0
			WHERE 
				(MATCH(DiagnosisCatalogKey, DiagnosisName) AGAINST(@__IN_DiagnosisName IN BOOLEAN MODE) OR @__IN_DiagnosisName = '')			
				AND (sd.DiagnosisLsex=@__IN_Sex OR sd.DiagnosisLsex='NO' OR IN_Sex=3 )
				AND (@__Age BETWEEN CONVERT(sd.DiagnosisLinf,SIGNED) AND CONVERT(sd.DiagnosisLsup,SIGNED)  OR sd.DiagnosisLinf='NO')	
				AND xu.UserID=IN_UserID
			GROUP BY id;
				
		END IF;
	
	ELSE 
		SELECT 0,'','Escribir m�s de 4 caracteres','','','','','','','','';	
	END IF;
	
END//
DELIMITER ;


-- Volcando estructura para procedimiento __fRptGetData_SIRES_Export
DROP PROCEDURE IF EXISTS `__fRptGetData_SIRES_Export`;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptGetData_SIRES_Export`(
	IN `IN_DateStart` VARCHAR(10),
	IN `IN_DateEnd` VARCHAR(10),
	IN `IN_ClinicID` INT,
	IN `IN_TypeDiary` INT,
	IN `IN_UserID` INT
)
    COMMENT 'Permite exportar el SIRES los datos de las consultas de las gu�as de consulta externa y bucal.'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:14/04/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */

	#Se declaran las variables del recordset de  __sires_diary_gen.
	DECLARE bDone TINYINT(1) DEFAULT 0;
	DECLARE lSDiaryGID INT(1) DEFAULT 0;
	DECLARE lSDiaryGClientID INT(1) DEFAULT 0;
	DECLARE lSDiaryGUserID INT(1) DEFAULT 0;
	DECLARE SDateStart DATE DEFAULT if(IN_DateStart='',CONCAT(YEAR(CURDATE()),'-',MONTH(CURDATE()),'-01'),IN_DateStart);
	DECLARE SDateEnd DATE DEFAULT if(IN_DateEnd='',CURDATE(),IN_DateEnd);
	
	#Se determinan las variables a exportar seg�n el tipo de consulta y se declara el cursor.
	DECLARE rs CURSOR FOR  
		SELECT SDiaryGID,SDiaryGClientID,SDiaryGUserID 
		FROM __sires_diary_gen sdg
		LEFT JOIN __sires_diary_gen_export sdge ON sdge.SExportID=sdg.SDiaryGIdExport
		WHERE  sdg.SClinicID=IN_ClinicID AND sdg.SDiaryGType=IN_TypeDiary  AND ISNULL(sdge.SExportDateConfirmed) AND sdg.SDiaryGDate BETWEEN if(IN_DateStart='',CONCAT(YEAR(CURDATE()),'-',MONTH(CURDATE()),'-01'),IN_DateStart) AND if(IN_DateEnd='',CURDATE(),IN_DateEnd); 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET bDone=TRUE;
		
	#Variables auxiliares
	SET @__msgReturn = '';
	SET @__success = 1;
	SET @__filename = '';
	SET @__rowCount = 0;	
	SET @__env=IFNULL((SELECT GeneralValue FROM x_config_general WHERE GeneralDesc='GEN_SIRES_TEST'),-1);

	#Se comprueba que el CLUES existe en el listado de CLUES permitidos.
	SET @__ClinicCluesIsValidated= IFNULL((SELECT xc.ClinicID FROM x_config_clinics xc INNER JOIN x_config_sires_clues su ON su.CluesID=xc.ClinicCLUES WHERE xc.ClinicID=IN_ClinicID AND su.CluesOperatingStatus=1),0);

	
	IF @__ClinicCluesIsValidated=0 THEN	
	   	SET @__msgReturn = 'lbl_clues_invalid';
			SET @__success = 0;
	ELSE 
	
		#Se establece mensaje por defecto en caso de error y se ejecuta el Rollback del bloque de operaciones ejecutadas.
		/*DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
		    ROLLBACK;
		    SET @__msgReturn = 'lbl_not_exported_data_rollback';
		    SET @__success = 0;
		    SELECT @__msgReturn AS msg, @__success AS success;
		END;*/			
	
		#Se obtiene la cabecera de la exportaci�n.
		SET @__headExport = IFNULL((SELECT GROUP_CONCAT(FieldName ORDER BY FieldSectionOrder ASC,FieldOrderInSection ASC SEPARATOR '|') FROM __sires_x_config_field xcf INNER JOIN __sires_x_config_field_section xcs  ON  xcs.FieldSectionID=xcf.FieldSectionID WHERE FieldDisabled = 0 AND FieldTypeDiary IN (0,IN_TypeDiary)),'');		
		
		#Se determina si existe una exportaci�n previa de la cl�nica para el periodo seleccionado.
		SET @__siresListExportID = '';
		SET @__siresExportDateConfirmed = '';		
			
		SELECT
		    GROUP_CONCAT(SExportID),
		    IFNULL(MAX(SExportDateConfirmed),'')
		INTO
		    @__siresListExportID,
		    @__siresExportDateConfirmed
		FROM __sires_diary_gen_export
		WHERE SExportDateStart BETWEEN SDateStart AND SDateEnd
		  AND SExportDateEnd   BETWEEN SDateStart AND SDateEnd
		  AND SExportClinicID  = IN_ClinicID
		  AND SExportTypeDiary = IN_TypeDiary;
					
		#Si no existe una exportaci�n marcada como importada al SIRES, se permite volver a exportar el archivo.
		IF @__siresExportDateConfirmed='' THEN 
		
			#. Se inicia bloque de operaciones
			START TRANSACTION;
			
			#Se inserta el registro de exportaci�n
			INSERT INTO __sires_diary_gen_export (SExportUserID, SExportHead, SExportDateTime, SExportDateConfirmed, SExportDateStart, SExportDateEnd,SExportTypeDiary,SExportClinicID) VALUES (IN_UserID, @__headExport, NOW(), NULL, SDateStart, SDateEnd,IN_TypeDiary,IN_ClinicID);
		   SET @__siresExportID = LAST_INSERT_ID();
		   
		   IF @__siresExportID>0 THEN				
				
				UPDATE __sires_diary_gen_export 
				SET SExportIDLastID=@__siresExportID
				WHERE FIND_IN_SET(SExportID, CONCAT_WS(',',@__siresExportID,@__siresListExportID))>0;
				
			END IF;
		
			#. Se obtienen en un string los valores de cada consulta	
			IF @__siresExportID>0 THEN					
					
				OPEN rs;
					REPEAT
						FETCH rs INTO lSDiaryGID,lSDiaryGClientID,lSDiaryGUserID;
						IF NOT bDone THEN	
								
										SET @__strValues = '';
										
										SET @__sql_data_user_entity = (
										  SELECT GROUP_CONCAT(
										    CONCAT(
										      ' SELECT ',
										        'FieldID, FieldName, FieldDefaultValue, ',
										        '(SELECT ', 
										          SUBSTRING_INDEX(xcf.FieldNameFrom, '.', -1) ,
										        ' FROM ', 
										          SUBSTRING_INDEX(xcf.FieldNameFrom, '.', 1), 
										        ' WHERE ',
										          IF(SUBSTRING_INDEX(xcf.FieldNameFrom, '.', 1) = 'x_config_clinics', CONCAT('ClinicID = ',IN_ClinicID), CONCAT('UserID = ',lSDiaryGUserID)),
										        ') AS FieldValue, ',xcs.FieldSectionOrder,' AS FieldSectionOrder,',xcf.FieldOrderInSection, ' AS FieldOrderInSection ',
										      ' FROM __sires_x_config_field xcf ',
										      ' WHERE FieldID = ', xcf.FieldID
										    )
										    SEPARATOR ' UNION ALL '
										  )
										  FROM __sires_x_config_field xcf
										  JOIN __sires_x_config_field_section xcs 
										    ON xcs.FieldSectionID = xcf.FieldSectionID 
										   AND xcs.FieldSectionTypeData > 1 
										  WHERE FieldDisabled = 0
										);							
										
										SET @__sql_data_client = (SELECT CONCAT(' ( SELECT FieldID,FieldName,FieldDefaultValue,if(FieldName like \'fecha%\', DATE_FORMAT(c.SClientFieldValue,\'%d/%m/%Y\'),CONVERT(c.SClientFieldValue USING utf8mb4)) AS FieldValue,FieldSectionOrder,FieldOrderInSection FROM  __sires_x_config_field xcf INNER JOIN __sires_x_config_field_section xcs ON xcs.FieldSectionID=xcf.FieldSectionID AND xcs.FieldSectionTypeData=1  LEFT JOIN __sires_clients c ON c.SClientFieldID=xcf.FieldID AND (ISNULL(c.SClientID) OR c.SClientID=',lSDiaryGClientID,') LEFT JOIN clients cl ON cl.ClientID=',lSDiaryGClientID,' WHERE  FieldDisabled = 0  AND xcf.FieldTypeDiary IN (0,',IN_TypeDiary,'))'));
										SET @__sql_data_diary = (SELECT CONCAT('( SELECT  FieldID,FieldName,FieldDefaultValue,if(FieldName like \'fecha%\', DATE_FORMAT(SDiaryFieldValue,\'%d/%m/%Y\'),CONVERT(SDiaryFieldValue USING utf8mb4) )  AS FieldValue,FieldSectionOrder,FieldOrderInSection FROM  __sires_x_config_field xcf INNER JOIN __sires_x_config_field_section xcs ON xcs.FieldSectionID=xcf.FieldSectionID AND xcs.FieldSectionTypeData=0  LEFT JOIN  __sires_diary_det d ON d.SDiaryFieldID=xcf.FieldID AND (ISNULL(d.SDiaryGID) OR d.SDiaryGID=',lSDiaryGID,')  WHERE  FieldDisabled = 0 AND xcf.FieldTypeDiary IN (0,',IN_TypeDiary,'))'));
										
										SET @__sql_data_union = (SELECT CONCAT_WS(' UNION ALL ', @__sql_data_user_entity, @__sql_data_client, @__sql_data_diary));
										SET @__sql_data = (SELECT CONCAT('SELECT GROUP_CONCAT(IF(IFNULL(FieldValue,\'\')=\'\',FieldDefaultValue,FieldValue) ORDER BY FieldSectionOrder,FieldOrderInSection ASC) INTO @__strValues FROM (',@__sql_data_union,')tmp;'));
	 									
										PREPARE stmt FROM @__sql_data;
										EXECUTE stmt;
										DEALLOCATE PREPARE stmt;
																		
										#Se actualiza el string de exportaci�n de la consulta, el id de exportaci�n correspondiente y se actualiza el cliente.
										IF @__strValues!='' THEN
										
											UPDATE __sires_diary_gen sdg 
											SET 
												sdg.SDiaryGBodyExport=UPPER(REPLACE(@__strValues,',','|')),
												sdg.SDiaryGIdExport=@__siresExportID
											WHERE sdg.SDiaryGID=lSDiaryGID AND ISNULL(sdg.SDiaryGBodyExport);	
											
											#Se incrementa el contador de consultas exportadas
											SET @__rowCount = @__rowCount +1;
											
										END IF;	
												
								END IF;	
											
						UNTIL bDone END REPEAT;
						CLOSE rs;
						
						# Se determina el porciento de c�digos gen�ricos respecto al total de registros que se exportan				
						SET @__DefaultCurp = 'XXXX999999XXXXXX99';
						SET @__DefaultCodeDiagnosis = 'R69X';
						SET @__PercentDefaultCurp = IFNULL((SELECT SUM(sdg.SDiaryGBodyExport LIKE CONCAT('%',@__DefaultCurp,'%'))/COUNT(*) AS PercentDefaultCurp FROM __sires_diary_gen sdg WHERE sdg.SDiaryGIdExport=@__siresExportID),0);
						SET @__PercentDefaultCodeDiagnosis = IFNULL((SELECT SUM(sdg.SDiaryGBodyExport LIKE CONCAT('%',@__DefaultCodeDiagnosis,'%'))/COUNT(*) AS DefaultCodeDiagnosis FROM __sires_diary_gen sdg WHERE sdg.SDiaryGIdExport=@__siresExportID),0);
		
						IF @__env=0 AND (@__PercentDefaultCurp > 0.15  OR  @__PercentDefaultCodeDiagnosis>0.05) THEN	
						
							#Se prepara archivo con los registros a modificar 	PENDIENTE
										
							SET @__msgReturn = 'lbl_invalid_percent_default_code';
							SET @__success = 0;				 
						END IF;
						
						IF @__rowCount > 0 AND  @__success=1 THEN				
						 	
						 	#Se determina el nombre del fichero				
							SET @__filename = (SELECT __fRptGetData_SIRES_Filename(IN_ClinicID,IN_TypeDiary,SDateStart));
							
							#Se actualiza el nombre del fichero en el registro de exportaciones.
							UPDATE __sires_diary_gen_export SET SExportNameFile=@__filename WHERE SExportID=@__siresExportID;			
						
							#Se suben los cambios y se termina el bloque de transacci�n
							COMMIT;				
							
						   #Se genera el fichero de la exportaci�n
							SET @__filepath = CONCAT('C:\/ProgramData\/MySQL\/MySQL Server 5.7\/Uploads\/cifrado\/',@__filename);						
							SET @__sql_data_export = CONCAT(
															" SELECT * FROM (",
															" SELECT '",UPPER(@__headExport),"'",
															" UNION ",
															" SELECT sdg.SDiaryGBodyExport FROM __sires_diary_gen sdg INNER JOIN __sires_diary_gen_export sde ON sde.SExportID=sdg.SDiaryGIdExport AND sde.SExportIDLastID=",@__siresExportID,
														")tmp",
														" INTO OUTFILE'",	@__filepath,"'",
														" FIELDS TERMINATED BY ',' ",
													   " ENCLOSED BY '' ",
													   " LINES TERMINATED BY '\\n'"
												);
							PREPARE stmt FROM @__sql_data_export;
							EXECUTE stmt;
							DEALLOCATE PREPARE stmt;
							
							SET @__msgReturn = 'lbl_exported_data';
							SET @__success = 1;
									
						ELSE	
							ROLLBACK;	
							SET  @__msgReturn = IF(@__msgReturn!='',@__msgReturn,'lbl_not_exported_data') ;
							SET @__success = 0;
						END IF;
						
				ELSE 
						ROLLBACK;	
						SET @__msgReturn = 'lbl_not_exported_data_rollback';
						SET @__success = 0;
				END IF;
		ELSE 
		# Si la exportaci�n ha sido marcada como exportada al SIRES no se permite la exportaci�n del archivo.
			SET @__msgReturn = 'lbl_not_export_by_import_sires';
			SET @__success = 0;
		END IF;
	END IF;
	
	SELECT @__msgReturn AS msg, @__success AS success, @__filename AS filename;	

END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptGetData_SIRES_ListExports
DROP PROCEDURE IF EXISTS __fRptGetData_SIRES_ListExports;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptGetData_SIRES_ListExports`(
	IN `IN_DateStart` VARCHAR(50),
	IN `IN_DateEnd` VARCHAR(50),
	IN `IN_ClinicID` INT,
	IN `IN_TypeDiary` INT,
	IN `IN_UserID` INT,
	IN `IN_Limit` INT,
	IN `IN_Start` INT
)
    COMMENT 'Permite listar las exportaciones previas.'
BEGIN
	
	-- @Autor: Ariadna RA
	-- @Created:14/04/2025
	-- @Ticket HS: 22055276319
	-- @Rpt:sires_form
	
	DECLARE SDateStart DATE DEFAULT if(IN_DateStart='',CONCAT(YEAR(CURDATE()),'-',MONTH(CURDATE()),'-01'),IN_DateStart);
	DECLARE SDateEnd DATE DEFAULT if(IN_DateEnd='',CURDATE(),IN_DateEnd);
	DECLARE IN_Limit INT DEFAULT IF(ISNULL(IN_Limit) OR IN_Limit = '', 0, IN_Limit);
	DECLARE IN_Start INT DEFAULT IF(ISNULL(IN_Start) OR IN_Start = '', 0, IN_Start); 
   DECLARE IN_ClinicID INT DEFAULT IF(ISNULL(IN_ClinicID) OR IN_ClinicID = '', 0, IN_ClinicID);
	DECLARE IN_TypeDiary INT DEFAULT IF(ISNULL(IN_TypeDiary) OR IN_TypeDiary = '', 0, IN_TypeDiary);
	
	SELECT dge.*,xu.UserName, xc.ClinicCommercialName AS ClinicName,td.STypeDiaryDesc AS SExportTypeDiary
	FROM __sires_diary_gen_export dge 
	INNER JOIN x_config_users xu ON xu.UserID=dge.SExportUserID 
	INNER JOIN x_config_clinics xc ON xc.ClinicID=dge.SExportClinicID
	INNER JOIN __sires_type_diary td ON td.STypeDiaryID=dge.SExportTypeDiary
	WHERE SExportDateStart BETWEEN SDateStart AND SDateEnd AND SExportDateEnd BETWEEN SDateStart AND SDateEnd 
	  -- DATE(SExportDateTime) BETWEEN SDateStart AND SDateEnd 
		AND SExportClinicID=IN_ClinicID 
		AND SExportTypeDiary=IN_TypeDiary
		AND SExportIDLastID=SExportID
	ORDER BY dge.SExportDateTime DESC 
	LIMIT IN_Start,IN_Limit;
   
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptGetData_SIRES_ListExportsTotal
DROP PROCEDURE IF EXISTS __fRptGetData_SIRES_ListExportsTotal;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptGetData_SIRES_ListExportsTotal`(
	IN `IN_DateStart` VARCHAR(50),
	IN `IN_DateEnd` VARCHAR(50),
	IN `IN_ClinicID` INT,
	IN `IN_TypeDiary` INT,
	IN `IN_Limit` INT,
	IN `IN_Start` INT
)
    COMMENT 'Permite obtener el total de las exportaciones previas.'
BEGIN
	/*
	 * @Autor: Ariadna RA
	 * @Created:14/04/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	
	DECLARE SDateStart DATE DEFAULT if(IN_DateStart='',CONCAT(YEAR(CURDATE()),'-',MONTH(CURDATE()),'-01'),IN_DateStart);
	DECLARE SDateEnd DATE DEFAULT if(IN_DateEnd='',CURDATE(),IN_DateEnd);
	DECLARE IN_Limit INT DEFAULT IF(ISNULL(IN_Limit) OR IN_Limit = '', 0, IN_Limit);
	DECLARE IN_Start INT DEFAULT IF(ISNULL(IN_Start) OR IN_Start = '', 0, IN_Start); 
	DECLARE IN_ClinicID INT DEFAULT IF(ISNULL(IN_ClinicID) OR IN_ClinicID = '', 0, IN_ClinicID);
	DECLARE IN_TypeDiary INT DEFAULT IF(ISNULL(IN_TypeDiary) OR IN_TypeDiary = '', 0, IN_TypeDiary);
   
	SELECT CEIL(COUNT(dge.SExportID)/IN_Limit) AS CountPage, COUNT(dge.SExportID) AS CountTotal FROM __sires_diary_gen_export dge INNER JOIN x_config_users xu ON xu.UserID=dge.SExportUserID WHERE DATE(SExportDateTime) BETWEEN SDateStart AND SDateEnd AND SExportClinicID=IN_ClinicID AND SExportTypeDiary=IN_TypeDiary;
   
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptGetData_SIRES_RegistryData
DROP PROCEDURE IF EXISTS __fRptGetData_SIRES_RegistryData;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptGetData_SIRES_RegistryData`(
	IN `IN_ClientID` INT,
	IN `IN_DateStart` VARCHAR(10),
	IN `IN_DateEnd` VARCHAR(10),
	IN `IN_TypeForm` INT,
	IN `IN_ServiceIDs` VARCHAR(250),
	IN `IN_Limit` INT,
	IN `IN_Start` INT
)
    COMMENT 'Permite obtener el registro de todas las consultas del cliente.'
BEGIN
	
	SET @ServiceCatalog = (SELECT FieldJSONValues FROM __sires_x_config_field WHERE FieldID=25);
	SET @IN_DateStart = IF(IN_DateStart='','2000-01-01',IN_DateStart);
	SET @IN_DateEnd = IF(IN_DateEnd='',CURDATE(),IN_DateEnd);
	SET @IN_TypeForm = IFNULL(IN_TypeForm,1);
	SET @IN_ServiceIDs = IFNULL(IN_ServiceIDs,'');
	SET @IN_ClientID = IFNULL(IN_ClientID,0);
	
	IF(@IN_ClientID>0) THEN
				
		SELECT 
			dg.SDiaryGID, dg.SDiaryGDate, CONCAT_WS(' ',xc.ClinicPrefix, xc.ClinicCommercialName) AS ClinicName,xu.UserName,dg.SDiaryGDateTime,dge.SExportDateTime,		
			TRIM(REPLACE(REPLACE(REPLACE(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(@ServiceCatalog,LOCATE(CONCAT('"id": ',dg.SDiaryGServiceID,','),@ServiceCatalog)),'"staff"',1),'"name":',-1),'"',''),',',''),'\r\n','')) AS ServiceName
		FROM 
			__sires_diary_gen dg 
			INNER JOIN x_config_clinics xc ON xc.ClinicID=dg.SClinicID
			INNER JOIN x_config_users xu ON xu.UserID=dg.SDiaryGUserID
			LEFT JOIN __sires_diary_gen_export dge ON dge.SExportID=dg.SDiaryGIdExport
		WHERE 
			dg.SDiaryGClientID=@IN_ClientID
			AND dg.SDiaryGDate BETWEEN @IN_DateStart AND @IN_DateEnd
			AND dg.SDiaryGType=@IN_TypeForm
			AND (FIND_IN_SET(dg.SDiaryGServiceID,@IN_ServiceIDs)>0 OR @IN_ServiceIDs='')
		ORDER BY dg.SDiaryGDateTime DESC
		LIMIT IN_Start,IN_Limit;
		
	END IF;
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptGetData_SIRES_RegistryDataTotal
DROP PROCEDURE IF EXISTS __fRptGetData_SIRES_RegistryDataTotal;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptGetData_SIRES_RegistryDataTotal`(
	IN `IN_ClientID` INT,
	IN `IN_DateStart` VARCHAR(10),
	IN `IN_DateEnd` VARCHAR(10),
	IN `IN_TypeForm` INT,
	IN `IN_ServiceIDs` VARCHAR(250),
	IN `IN_Limit` INT,
	IN `IN_Start` INT
)
    COMMENT 'Permite obtener el registro de todas las consultas del cliente.'
BEGIN
	
	SET @ServiceCatalog = (SELECT FieldJSONValues FROM __sires_x_config_field WHERE FieldID=25);
	SET @IN_DateStart = IF(IN_DateStart='','2000-01-01',IN_DateStart);
	SET @IN_DateEnd = IF(IN_DateEnd='',CURDATE(),IN_DateEnd);
	SET @IN_TypeForm = IFNULL(IN_TypeForm,1);
	SET @IN_ServiceIDs = IFNULL(IN_ServiceIDs,'');
	SET @IN_ClientID = IFNULL(IN_ClientID,0);

			
	SELECT
		CEIL(COUNT(dg.SDiaryGID)/IN_Limit) AS CountPage, COUNT(dg.SDiaryGID) AS CountTotal 
	FROM 
		__sires_diary_gen dg 
		INNER JOIN x_config_clinics xc ON xc.ClinicID=dg.SClinicID
		INNER JOIN x_config_users xu ON xu.UserID=dg.SDiaryGUserID
		LEFT JOIN __sires_diary_gen_export dge ON dge.SExportID=dg.SDiaryGIdExport
	WHERE 
		dg.SDiaryGClientID=@IN_ClientID
		AND dg.SDiaryGDate BETWEEN @IN_DateStart AND @IN_DateEnd
		AND dg.SDiaryGType=@IN_TypeForm
		AND (FIND_IN_SET(dg.SDiaryGServiceID,@IN_ServiceIDs)>0 OR @IN_ServiceIDs='');
			
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptResetData_SIRES_AllCatalogJson
DROP PROCEDURE IF EXISTS __fRptResetData_SIRES_AllCatalogJson;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptResetData_SIRES_AllCatalogJson`()
    COMMENT 'A partir de las tablas que se referencian en __sires_x_config_catalogs actualiza en __sires_x_config_field los catalogos en JSON de las variables correspodientes'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:19/12/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	 
	 
	 DECLARE bDone TINYINT(1) DEFAULT 0;
    DECLARE lFnJsonETL VARCHAR(255);  

    -- Cursor para obtener los nombres de los procedimientos
    DECLARE items CURSOR FOR
        SELECT DISTINCT CatalogFnJsonETL FROM __sires_x_config_catalogs WHERE CatalogJsonETLEnabled=-1 AND  CatalogFnJsonETL!='';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET bDone=TRUE;

    OPEN items;
    REPEAT
        FETCH items INTO lFnJsonETL;
        IF NOT bDone THEN
        	
	        SET @__sqlCall = CONCAT('CALL ', lFnJsonETL, '()');	
	        PREPARE stmt FROM @__sqlCall;
	        EXECUTE stmt;
	        DEALLOCATE PREPARE stmt;
          
        END IF;
        UNTIL bDone END REPEAT;
    CLOSE items;

	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptResetData_SIRES_CatalogJsonCountries
DROP PROCEDURE IF EXISTS __fRptResetData_SIRES_CatalogJsonCountries;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptResetData_SIRES_CatalogJsonCountries`()
    COMMENT 'Permite construit JSON de la tabla x_config_countries, actualizando __sires_x_config_field.FieldJSONValues de las variables  FieldID=14|21 (paisNacPaciente|paisProcedencia|paisNacimiento).'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:18/12/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */

	CREATE TABLE __tmp_x_config_countries 	SELECT CountrySIRESKey,CountrySIRESDesc,CountrySIRESOrder FROM x_config_countries WHERE CountrySIRESKey!='' ORDER BY CountrySIRESOrder ASC;
	SET @ServiceCatalogJSON = (SELECT JSON_OBJECT('values', JSON_ARRAYAGG(JSON_OBJECT('id', CountrySIRESKey, 'name',CountrySIRESDesc,'order',CountrySIRESOrder))) FROM __tmp_x_config_countries);
	DROP TABLE __tmp_x_config_countries;

		
	IF @ServiceCatalogJSON!='' THEN 	
		UPDATE  __sires_x_config_field SET FieldJSONValues=@ServiceCatalogJSON WHERE FieldName IN('paisNacPaciente','paisProcedencia','paisNacimiento');
		UPDATE  __sires_x_config_catalogs SET CatalogJSONValue=@ServiceCatalogJSON,CatalogLastUpdate=CURRENT_TIMESTAMP()  WHERE CatalogFnJsonETL='__fRptResetData_SIRES_CatalogJsonCountries';
	END IF;
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptResetData_SIRES_CatalogJsonMemberShip
DROP PROCEDURE IF EXISTS `__fRptResetData_SIRES_CatalogJsonMemberShip`;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptResetData_SIRES_CatalogJsonMemberShip`()
    COMMENT 'Permite construir JSON de la tabla __sires_x_config_membership, actualizando __sires_x_config_field.x_config_provinces de las variables  FieldID=23 (derechohabiencia).'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:19/12/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */

	CREATE TABLE __tmp_sires_x_config_membership SELECT MemberShipCatalogKey, if(MemberShipDesc=MemberShipAbr,MemberShipAbr,CONCAT(MemberShipAbr,' - ',MemberShipDesc)) AS MemberShipAbr FROM __sires_x_config_membership WHERE MemberShipDisabled=0 ORDER BY MemberShipCatalogKey ASC;
	SET @ServiceCatalogJSON = (SELECT JSON_OBJECT('values', JSON_ARRAYAGG(JSON_OBJECT('id', MemberShipCatalogKey, 'name',MemberShipAbr))) FROM __tmp_sires_x_config_membership);
	DROP TABLE __tmp_sires_x_config_membership;
		
	IF @ServiceCatalogJSON!='' THEN 	
		UPDATE  __sires_x_config_field SET FieldJSONValues=@ServiceCatalogJSON WHERE FieldName IN('derechohabiencia');
		UPDATE  __sires_x_config_catalogs SET CatalogJSONValue=@ServiceCatalogJSON,CatalogLastUpdate=CURRENT_TIMESTAMP()  WHERE CatalogFnJsonETL='__fRptResetData_SIRES_CatalogJsonMemberShip';
	END IF;
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptResetData_SIRES_CatalogJsonProvinces
DROP PROCEDURE IF EXISTS `__fRptResetData_SIRES_CatalogJsonProvinces`;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptResetData_SIRES_CatalogJsonProvinces`()
    COMMENT 'Permite construir JSON de la tabla x_config_countries, actualizando __sires_x_config_field.x_config_provinces de las variables  FieldID=15 (entidadNacimiento).'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:18/12/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */

	CREATE TABLE __tmp_x_config_provinces 	SELECT ProvinceSiresCatalogKey,CONCAT(ProvinceCode,' - ',ProvinceName) AS ProvinceName,ProvinceCode FROM x_config_provinces xc WHERE ProvinceCountryID=142 ORDER BY ProvinceSiresCatalogKey ASC;
	SET @ServiceCatalogJSON = (SELECT JSON_OBJECT('values', JSON_ARRAYAGG(JSON_OBJECT('id', ProvinceSiresCatalogKey, 'name',ProvinceName,'abr',ProvinceCode))) FROM __tmp_x_config_provinces);
	DROP TABLE __tmp_x_config_provinces;
	
	IF @ServiceCatalogJSON!='' THEN 	
		UPDATE  __sires_x_config_field SET FieldJSONValues=@ServiceCatalogJSON WHERE FieldName IN('entidadNacimiento');
		UPDATE  __sires_x_config_catalogs SET CatalogJSONValue=@ServiceCatalogJSON,CatalogLastUpdate=CURRENT_TIMESTAMP()  WHERE CatalogFnJsonETL='__fRptResetData_SIRES_CatalogJsonProvinces';
	END IF;
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptResetData_SIRES_CatalogJsonServices
DROP PROCEDURE IF EXISTS __fRptResetData_SIRES_CatalogJsonServices;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptResetData_SIRES_CatalogJsonServices`()
    COMMENT 'Permite constriur JSON de las tablas __sires_services_ce_sis y  __sires_services_sb_sis actualizando __sires_x_config_field.FieldJSONValues de la variable FieldID=25.'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:17/12/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */

	SELECT 
	    GROUP_CONCAT(
	        CONCAT(
	            'SELECT ',
	            'catalog_key AS id, ',
	            'service AS name, ',
	            'disabled, ',
	            '''', COLUMN_NAME, ''' AS staff_id ',
	            'FROM __sires_services_ce_sis ',
	            'WHERE `', COLUMN_NAME, '` = ''X'''
	        )
	        SEPARATOR ' UNION ALL '
	    )
	INTO @sqlCE
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_SCHEMA = DATABASE()
	  AND TABLE_NAME = '__sires_services_ce_sis'
	  AND COLUMN_NAME REGEXP '^[0-9]+$';
	
	SELECT 
	    GROUP_CONCAT(
	        CONCAT(
	            'SELECT ',
	            'catalog_key AS id, ',
	            'service AS name, ',
	            'disabled, ',
	            '''', COLUMN_NAME, ''' AS staff_id ',
	            'FROM __sires_services_sb_sis ',
	            'WHERE `', COLUMN_NAME, '` = ''X'''
	        )
	        SEPARATOR ' UNION ALL '
	    )
	INTO @sqlSB
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_SCHEMA = DATABASE()
	  AND TABLE_NAME = '__sires_services_sb_sis'
	  AND COLUMN_NAME REGEXP '^[0-9]+$';
	
	SET @ServiceCatalogJSON='';
	SET @sqlJSON = CONCAT(
	    'SELECT JSON_OBJECT(',
	    '''values'', JSON_ARRAYAGG(',
	        'JSON_OBJECT(',
	            '''id'', id, ',
	            '''name'', name, ',
	            '''disabled'', disabled, ',
	            '''staff'', staff',
	        ')',
	    ')',
	    ') INTO  @ServiceCatalogJSON ',
	    'FROM (',
	        'SELECT id, name, disabled, GROUP_CONCAT(staff_id ORDER BY CONVERT(staff_id,SIGNED)) staff ',
	        'FROM (', @sqlCE,' UNION ALL ',@sqlSB ,') t ',
	        'GROUP BY id, name',
	    ') x'
	);
	
	PREPARE stmt_serv FROM @sqlJSON;
	EXECUTE stmt_serv;
	DEALLOCATE PREPARE stmt_serv;
		
	IF @ServiceCatalogJSON!='' THEN 	
		UPDATE  __sires_x_config_field SET FieldJSONValues=@ServiceCatalogJSON WHERE FieldName='servicioAtencion';
		UPDATE  __sires_x_config_catalogs SET CatalogJSONValue=@ServiceCatalogJSON,CatalogLastUpdate=CURRENT_TIMESTAMP()  WHERE CatalogFnJsonETL='__fRptResetData_SIRES_CatalogJsonServices';
	END IF;
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptResetTableSIRES_PostTest
DROP PROCEDURE IF EXISTS `__fRptResetTableSIRES_PostTest`;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptResetTableSIRES_PostTest`()
    DETERMINISTIC
BEGIN
    
   -- Se crea una copia de la tablA clientes asociados al SIRES.
  SET @__sqltxt = CONCAT('CREATE TABLE clients_sires_bkp_', DATE_FORMAT(current_timestamp(),'%Y%m%d_%H%i'),' SELECT * FROM clients  c WHERE c.ClientID in (SELECT DISTINCT SClientID FROM __sires_clients) ;');

  PREPARE stmt FROM @__sqltxt;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;  
  
	-- Se define el listado de tablas del SIRES a resetear
	SET @__tables_sires:='__sires_delete_registry,__sires_clients,__sires_diary_det,__sires_diary_gen,__sires_diary_gen_export'; 
	
	-- Iterador
	SET @__idx:=1;

   -- Se cuenta la cantidad de comas ? elementos = comas + 1
   SET @__tables_sires_count:=LENGTH(@__tables_sires)-LENGTH(REPLACE(@__tables_sires,',','')) + 1;

   -- Se hacer table de repaldo y se limpia cada una de las tables identificadas.
	WHILE @__idx <= @__tables_sires_count DO
        
        -- Se obtienen el elemento N usando SUBSTRING_INDEX
        SET @__table = SUBSTRING_INDEX(SUBSTRING_INDEX(@__tables_sires, ',', @__idx), ',', -1);

        -- 1. Construir consulta para generar respaldo
        SET @__sqltxt = CONCAT('CREATE TABLE ',@__table,'_bkp_', DATE_FORMAT(current_timestamp(),'%Y%m%d_%H%i'),' SELECT * FROM ',@__table,';');

        PREPARE stmt FROM @__sqltxt;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;        
        
        -- 2. Truncar tabla original
        SET @__sqltxt = CONCAT('TRUNCATE TABLE ', @__table);

        PREPARE stmt FROM @__sqltxt;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;        

			-- Se incrementa el iterador
        SET @__idx = @__idx + 1;
        
    END WHILE;

END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptSaveData_SIRES_ConfirmExport
DROP PROCEDURE IF EXISTS __fRptSaveData_SIRES_ConfirmExport;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptSaveData_SIRES_ConfirmExport`(
	IN `IN_ExportID` INT,
	IN `IN_UserID` INT
)
    COMMENT 'Permite confirmar el registro de exportaci�n ha sido importado al SIRES.'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:22/05/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	
	UPDATE __sires_diary_gen_export SET SExportDateConfirmed=CURDATE(),SExportUserIDConfirm=IN_UserID WHERE SExportID=IN_ExportID;
	
	SET @rows_afected = ROW_COUNT();
	
	if(@rows_afected>0) THEN
		SET  @__msgReturn = 'lbl_saved_data';		
	ELSE		
		SET  @__msgReturn = 'lbl_not_saved_data';
	END IF;
	
	SELECT @__msgReturn AS msg;	
	
END//
DELIMITER ;

-- Volcando estructura para procedimiento __fRptSaveData_SIRES_Diary
DROP PROCEDURE IF EXISTS __fRptSaveData_SIRES_Diary;
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `__fRptSaveData_SIRES_Diary`(
	IN `IN_ClientID` INT,
	IN `IN_Data` TEXT,
	IN `IN_TypeForm` INT,
	IN `IN_ClinicID` INT,
	IN `IN_UserID` INT
)
    COMMENT 'Permite guardar los datos de la consulta.'
BEGIN

	/*
	 * @Autor: Ariadna RA
	 * @Created:14/04/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */
	
		#.Se identifican todas las variables a guardar seg�n el tipo de formulario seleccionado.		
		DECLARE bDone TINYINT(1) DEFAULT 0;
		DECLARE lFieldName TEXT DEFAULT '';
		DECLARE lFieldID TEXT DEFAULT '';
		DECLARE lFieldDesc TEXT DEFAULT '';
		DECLARE lDelimiter TEXT DEFAULT '';
		DECLARE lFieldDefaultValue TEXT DEFAULT '';
		DECLARE lFieldNameFrom TEXT DEFAULT '';
		DECLARE lFieldSectionID INT DEFAULT 0;
		DECLARE lFieldTypeView TEXT DEFAULT 'TEXT';
		
		#Se determinan todas las variable de la consulta y se declara el cursor
		DECLARE rs CURSOR FOR  
			
			SELECT FieldID,FieldName, FieldDesc,FieldDelimiter,FieldDefaultValue,FieldNameFrom,sf.FieldSectionID,sf.FieldTypeView 
			FROM __sires_x_config_field sf 
			INNER JOIN __sires_x_config_field_section ss ON ss.FieldSectionID=sf.FieldSectionID
			WHERE sf.FieldDisabled=0 AND sf.FieldTypeDiary IN (0,IN_TypeForm);
		
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET bDone=TRUE;
		
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
		    ROLLBACK;
		    SET @__msgReturn = 'lbl_not_saved_data';
		    SELECT @__msgReturn;
		END;	
		
		#. Variables auxiliares.
		SET @__msgReturn = '';
		SET @__rowCount = 0;		
		
		#. Se determina la fecha de la cita y el tratamiento a insertar para identificar la consulta que se est� gestionando
		SET @__strDiaryGDate = __fRptGetData_SIRES_StrFieldValue(IN_Data,'fechaConsulta', CURDATE());
		SET @__strServiceID = __fRptGetData_SIRES_StrFieldValue(IN_Data,'servicioAtencion','');	
		
		#. Se determina si el establecimiento de salud (cl�nica para flowww) es especializado.
		SET @__clinicIsUneme = IFNULL((SELECT COUNT(CluesID) FROM x_config_sires_clues WHERE CluesTypeAbbreviation IN ('T','UNE') AND CluesSubAbbreviation IN ('T02','UNE02','UNE04','UNE11') AND CluesID IN (SELECT xc.ClinicCLUES FROM x_config_clinics xc WHERE xc.ClinicID=IN_ClinicID)),0);
		
		#. Se determina la edad del paciente respecto a la fecha de la consulta
		SET @__clientBirthDate = IFNULL((SELECT c.ClientBirthDate FROM clients c WHERE c.ClientID=IN_ClientID),CURDATE());
		SET @__clientAge = TIMESTAMPDIFF(YEAR,@__clientBirthDate,@__strDiaryGDate);
		
		#. Se determina el tipo de personal del profesional que  atiende la consulta
		SET @__userCollegeID = IFNULL((SELECT xu.UserCollegeTypeID FROM x_config_users xu WHERE xu.UserID=IN_UserID),0);
	
		IF CONVERT(@__strServiceID,SIGNED)>0 THEN
			
			#.Determinar si existe una cita en la fecha fijada para el tratamiento y cliente seleccionado que no haya sido exportada el SIRES.
			SET @__DiaryGID = IFNULL((SELECT SDiaryGID FROM __sires_diary_gen sdg WHERE sdg.SDiaryGClientID=IN_ClientID AND sdg.SClinicID=IN_ClinicID AND sdg.SDiaryGDate=@__strDiaryGDate AND FIND_IN_SET(@__strServiceID,sdg.SDiaryGServiceID)>0  AND sdg.SDiaryGIdExport=0 LIMIT 1),0);
	
			#. Se inicia bloque de operaciones
			START TRANSACTION;
			
			#. Si existe la cita se eliminan los registros creados para sobreescribirla.
			DELETE FROM __sires_diary_det WHERE SDiaryGID=@__DiaryGID;
			DELETE FROM __sires_diary_gen WHERE SDiaryGID=@__DiaryGID;
			
			#. Se eliminan los datos del clientes para insertarlos nuevamente en caso se existir alg�n cambio en la ficha del cliente sino se ha registrado en el SIRES ninguna cita previa.
			SET @__ExistDiaryGIDInSIRES = IFNULL((SELECT COUNT(SDiaryGID) FROM __sires_diary_gen sdg WHERE sdg.SDiaryGClientID=IN_ClientID AND sdg.SDiaryGIdExport>0),0);
			
			IF @__ExistDiaryGIDInSIRES=0 THEN
				DELETE FROM __sires_clients WHERE SClientID=IN_ClientID;	
			END IF;
				
			#. Se crea una nueva consulta con los nuevos valores	
			INSERT INTO __sires_diary_gen (DiaryGID, SClinicID, SDiaryGClientID, SDiaryGUserID, SDiaryGType, SDiaryGDate, SDiaryGServiceID, SDiaryGDateTime, SDiaryGIdExport) VALUES (0, IN_ClinicID, IN_ClientID, IN_UserID, IN_TypeForm, @__strDiaryGDate, @__strServiceID, NULL, 0);
			SET @__DiaryGID = LAST_INSERT_ID();		
			
			IF @__DiaryGID>0 THEN		
			
				#. Se insertan los valores de las variables seg�n su secci�n		
				OPEN rs;
					REPEAT
						FETCH rs INTO lFieldID,lFieldName,lFieldDesc,lDelimiter,lFieldDefaultValue,lFieldNameFrom,lFieldSectionID,lFieldTypeView;
						IF NOT bDone THEN										
						
							IF lFieldSectionID >= 3 THEN
							
									-- Se evalu�n los valores antes de guardar
									SET @__strFieldValue = __fRptGetData_SIRES_StrFieldValue(IN_Data,lFieldName,lFieldDefaultValue);
											
									IF lFieldTypeView='MULTISELECT' THEN
										SET @__strFieldValueRw = REPLACE(@__strFieldValue,'|',lDelimiter);
									ELSE 
										SET @__strFieldValueRw = (CASE 
																			  WHEN lFieldName IN ('peso', 'talla')  THEN IF(@__strFieldValue IN ('0'),999,@__strFieldValue)	
																			  WHEN lFieldName IN ('primeraVezUneme')  THEN IF(@__clinicIsUneme>0,0,@__strFieldValue)
																			  WHEN lFieldName IN ('informaPrevencionAccidentes') THEN IF(@__clientAge<10 AND @__userCollegeID NOT IN(15,16),0,@__strFieldValue)																		 
																			  ELSE @__strFieldValue
																			END);										
									END IF;
									
									IF lFieldSectionID = 3 AND @__ExistDiaryGIDInSIRES=0 THEN -- Se gestionan los datos del cliente
										INSERT INTO __sires_clients (SClientID, SClientFieldID, SClientFieldValue, SClientDateTime) VALUES (IN_ClientID, lFieldID, @__strFieldValueRw, CURRENT_TIMESTAMP());
										SET @__rowCount = @__rowCount+1;
									END IF;
									
									IF lFieldSectionID > 3 THEN -- Se gestionan los datos de la consulta									
									
										INSERT INTO __sires_diary_det (SDiaryGID, SDiaryFieldID, SDiaryFieldValue, `SDiaryDateTime`) VALUES (@__DiaryGID, lFieldID, @__strFieldValueRw, CURRENT_TIMESTAMP());
										SET @__rowCount = @__rowCount+1;
									END IF;
									
							END IF;
											
						END IF;	
									
				UNTIL bDone END REPEAT;
				CLOSE rs;
				
		ELSE 
				SET  @__msgReturn = 'lbl_unsaved_diary';
		END IF;
		
	ELSE 
		SET  @__msgReturn = 'lbl_blank_service';		
	END IF;
		
	COMMIT;

	IF @__rowCount > 0 THEN
		SET  @__msgReturn = 'lbl_saved_data';
		UPDATE clients c INNER JOIN __sires_diary_gen sdg ON sdg.SDiaryGClientID=c.ClientID SET ClientLockData = -1	WHERE sdg.SDiaryGID=@__DiaryGID;
			
	ELSE		
		SET  @__msgReturn = IF(@__msgReturn!='',@__msgReturn,'lbl_not_saved_data') ;
	END IF;
	
	SELECT @__msgReturn AS msg;	
	
END//
DELIMITER ;

-- Volcando estructura para funci�n __fRptCheckData_SIRES_CurpIgnoreFromName
DROP FUNCTION IF EXISTS __fRptCheckData_SIRES_CurpIgnoreFromName;
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `__fRptCheckData_SIRES_CurpIgnoreFromName`(
	`IN_Name` VARCHAR(50),
	`IN_Typeparams` TINYINT
) RETURNS varchar(50) CHARSET latin1 COLLATE latin1_spanish_ci
    DETERMINISTIC
    COMMENT 'Devuelve la primera palabra sin considerar primer preposiciones, art�culos, conjunciones,contracciones o nombre com�n recurrente. (IN_Typeparams: 1-Incluye nombres recurrentes, 0-Incluye solo preposiciones,conjunciones, art�culos y contracciones)'
BEGIN
    DECLARE WordName VARCHAR(100);
    DECLARE i INT DEFAULT 1;
    DECLARE WordReturned VARCHAR(100);
    
    IF IN_Typeparams=1 THEN
	    SET @__WordIgnore = 'JOSE,JOS�,MARIA,MAR�A,J.,M.,J,M,MA.,MA,DA,DAS,DE,DEL,DER,DI,DIE,DD,Y,EL,LA,LOS,LAS,LE,LES,MAC,MC,VAN,VON';
	 ELSE 
    	 SET @__WordIgnore = 'DA,DAS,DE,DEL,DER,DI,DIE,DD,Y,EL,LA,LOS,LAS,LE,LES,MAC,MC,VAN,VON';
    END IF;

    -- Lista de palabras a ignorar   
    SET @__CountNames = (LENGTH(IN_Name)-LENGTH(REPLACE(IN_Name,' ','')))+1;

    -- Bucle por cada palabra (m�x. 20 para seguridad)
    WHILE i <= @__CountNames AND @__CountNames<10 DO

        -- Obtener la i-�sima palabra usando SUBSTRING_INDEX
        SET WordName = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(IN_Name, ' ', i),' ',-1));

        -- Romper si ya no hay palabras
        IF WordName = '' OR WordName IS NULL THEN
            RETURN 'X';
        END IF;

        -- Si NO est� en la lista, devolverla
        IF FIND_IN_SET(UPPER(WordName), @__WordIgnore) = 0 THEN
            RETURN WordName;
        END IF;

        SET i = i + 1;
        
    END WHILE;

    RETURN 'X';
END//
DELIMITER ;

-- Volcando estructura para funci�n __fRptGetData_SIRES_CurpCharAfterPos
DROP FUNCTION IF EXISTS __fRptGetData_SIRES_CurpCharAfterPos;
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `__fRptGetData_SIRES_CurpCharAfterPos`(
	`IN_Text` VARCHAR(255),
	`IN_Start` INT,
	`IN_Type` ENUM('vocal','consonante')
) RETURNS char(1) CHARSET latin1 COLLATE latin1_spanish_ci
    DETERMINISTIC
BEGIN
    DECLARE i INT;
    DECLARE l INT;
    DECLARE ch CHAR(1);
    DECLARE p_text CHAR(50);
    
    SET p_text = UPPER(IN_Text);
    SET l = CHAR_LENGTH(p_text);
    SET i = IN_Start + 1;

    WHILE i <= l DO
        SET ch = SUBSTRING(p_text, i, 1);

        IF IN_Type = 'vocal' AND (ch IN ('A','E','I','O','U','�') OR ch IN ('/','-','.','\'','�')) THEN
            RETURN IF(ch='�','U',ch);
        END IF;
      
      	IF IN_Type = 'consonante' AND (ch REGEXP '^[B-DF-HJ-NP-TV-Z�]$' OR  ch IN ('/','-','.','\'','�')) THEN
            RETURN if(ch IN ('/','-','.','\'','�'),'X',ch);
        END IF;

        SET i = i + 1;
        
    END WHILE;

    RETURN 'X';
END//
DELIMITER ;

-- Volcando estructura para funci�n __fRptGetData_SIRES_Filename
DROP FUNCTION IF EXISTS __fRptGetData_SIRES_Filename;
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `__fRptGetData_SIRES_Filename`(
	`IN_ClinicID` INT,
	`IN_TypeDiary` INT,
	`IN_Date` VARCHAR(20)
) RETURNS varchar(250) CHARSET latin1 COLLATE latin1_spanish_ci
    DETERMINISTIC
    COMMENT 'Permite obtener el nombre del archivo a exportar al SIRES.'
BEGIN

	SET @__filename='';
	SET @__IN_ClinicID = IF(ISNULL(IN_ClinicID) OR IN_ClinicID='',0,IN_ClinicID);
	SET @__IN_TypeDiary = IF(ISNULL(IN_TypeDiary) OR IN_TypeDiary='',0,IN_TypeDiary);
	SET @__IN_Date = IF(ISNULL(IN_Date) OR IN_Date='',CURDATE(),IN_Date);		
	SET @__cluesPrefix = IFNULL((SELECT SUBSTRING(ClinicCLUES,1,5) FROM x_config_clinics WHERE ClinicID=@__IN_ClinicID),'');
	SET @__fileTypeDiary = IF(@__IN_TypeDiary=1,'CSB','CEX');
	SET @__filename = CONCAT(@__fileTypeDiary,'-',@__cluesPrefix,'-',SUBSTRING(YEAR(@__IN_Date),3,2),LPAD(MONTH(@__IN_Date),2,'0'),'.txt');		
	
	RETURN @__filename;	
		
END//
DELIMITER ;

-- Volcando estructura para funci�n __fRptGetData_SIRES_SerializedCatalog
DROP FUNCTION IF EXISTS __fRptGetData_SIRES_SerializedCatalog;
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `__fRptGetData_SIRES_SerializedCatalog`(
	`IN_FieldID` INT
) RETURNS text CHARSET latin1 COLLATE latin1_spanish_ci
    DETERMINISTIC
BEGIN	
	SET @__SerializedJson = IFNULL((SELECT REPLACE(REPLACE(REPLACE(FieldJSONValues,'"','\\"'),'\n','\\n'),'\r','') AS  FieldJSONValues FROM __sires_x_config_field WHERE FieldID=IN_FieldID),'');
	RETURN @__SerializedJson;
END//
DELIMITER ;

-- Volcando estructura para funci�n __fRptGetData_SIRES_StrFieldValue
DROP FUNCTION IF EXISTS __fRptGetData_SIRES_StrFieldValue;
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `__fRptGetData_SIRES_StrFieldValue`(
	`IN_Data` TEXT,
	`IN_FieldName` VARCHAR(50),
	`IN_FieldDefaultValue` VARCHAR(250)
) RETURNS varchar(250) CHARSET latin1 COLLATE latin1_spanish_ci
    DETERMINISTIC
    COMMENT 'Permite obtener el valor dada la clave del atributo en un par de tipo clave valor.'
BEGIN

	/*
		 @Autor: Ariadna RA
		 @Created:03/04/2025
		 @Ticket HS: 22055276319
		 @Rpt:sires_form
	*/
	
	#. Se determina el total de campos incluidos en el par�metro data.
	SET @__TotalFieldInData = IFNULL((SELECT LENGTH(IN_Data)-LENGTH(REPLACE(IN_Data,',',''))),0)+1;
	SET @__Counter = 1;	
	SET @__StrValue = '';
	
	#. Se determina el valor del campo que se busca
	WHILE @__Counter <= @__TotalFieldInData DO
	
		SET @__StrFieldValue=REPLACE(REPLACE(SUBSTRING_INDEX(IN_Data,',',@__Counter),SUBSTRING_INDEX(IN_Data,',',@__Counter-1),''),',','');
		
		IF REPLACE(SUBSTRING_INDEX(@__StrFieldValue,':',1),'"','')=IN_FieldName THEN
		
			SET @__StrValue=REPLACE(SUBSTRING_INDEX(@__StrFieldValue,':',-1),'"','');
			
			SET @__Counter = @__TotalFieldInData + 1;
			
		ELSE 				
				#. Se incrementa el contador
				SET @__Counter = @__Counter + 1;
				
		END IF;	
		
	END WHILE;
		
	IF @__StrValue='-2' OR @__StrValue=''  THEN
		SET  @__StrValue = IN_FieldDefaultValue;
	END IF;
		
	RETURN @__StrValue;
	
END//
DELIMITER ;

-- Volcando estructura para funci�n __fRptGetData_SIRES_StrPartOfFullName
DROP FUNCTION IF EXISTS __fRptGetData_SIRES_StrPartOfFullName;
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `__fRptGetData_SIRES_StrPartOfFullName`(
	`FieldValue` VARCHAR(250),
	`PositionFullName` INT
) RETURNS varchar(100) CHARSET latin1 COLLATE latin1_spanish_ci
    DETERMINISTIC
BEGIN
		
	/*
	 @Autor: Ariadna RA
	 @Created:05/05/2025
	 @Ticket HS: 22055276319
	 @Rpt:sires_export
	*/
	
	SET @CountWord:=(LENGTH(FieldValue)-LENGTH(REPLACE(FieldValue,' ','')));		
	SET @Surname2:=TRIM(if(@CountWord<=1,'',SUBSTRING_INDEX(FieldValue,' ', (@CountWord-(@CountWord-1))*-1)));
   SET @Surname1:=TRIM(CASE @CountWord 
										WHEN 0 THEN ''
										WHEN 1 THEN SUBSTRING_INDEX(REPLACE(FieldValue,@Surname2,''),' ', ((@CountWord-(@CountWord-1)))*-1)
										ELSE SUBSTRING_INDEX(REPLACE(FieldValue,@Surname2,''),' ', ((@CountWord-(@CountWord-2)))*-1)
										END);
	SET @Nombre:=TRIM(REPLACE(REPLACE(FieldValue,@Surname1,''),@Surname2,''));
		
	SET @Result:= (CASE PositionFullName
							WHEN 1 THEN @Nombre
							WHEN 2 THEN @Surname1
							WHEN 3 THEN @Surname2
							ELSE '' END);
		
	RETURN @Result;
	
END//
DELIMITER ;

-- Volcando estructura para funci�n __fRptReplacetData_SIRES_CurpDerogatoryTerm
DROP FUNCTION IF EXISTS __fRptReplacetData_SIRES_CurpDerogatoryTerm;
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `__fRptReplacetData_SIRES_CurpDerogatoryTerm`(
	`IN_Name` VARCHAR(4)
) RETURNS varchar(4) CHARSET latin1 COLLATE latin1_spanish_ci
    DETERMINISTIC
    COMMENT 'Modifica a X la primera vocal de una palabra altisonante de 4 caracteres (iniciales CURP)'
BEGIN
	
	/*
	 * @Autor: Ariadna RA
	 * @Created:26/11/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form
	 */	 

	 DECLARE i INT;
    DECLARE l INT;
    DECLARE ch CHAR(1);
    DECLARE Vowel TINYINT DEFAULT 0;
    DECLARE WordReturned CHAR(4) DEFAULT IN_Name;
    DECLARE DerogatoryTerm VARCHAR(2000) DEFAULT 'BACA,BAKA,BUEI,BUEY,CACA,CACO,CAGA,CAGO,CAKA,CAKO,COGE,COGI,COJA,COJE,COJI,COJO,COLA,CULO,FALO,FETO,GETA,GUEI,GUEY,JETA,JOTO,KACA,KACO,KAGA,KAGO,KAKA,KAKO,KOGE,KOGI,KOJA,KOJE,KOJI,KOJO,KOLA,KULO,LILO,LOCA,LOCO,LOKA,LOKO,MAME,MAMO,MEAR,MEAS,MEON,MIAR,MION,MOCO,MOKO,MULA,MULO,NACA,NACO,ORIN,PEDA,PEDO,PENE,PIPI,PITO,POPO,PUTA,PUTO,QULO,RATA,ROBA,ROBE,ROBO,RUIN,SENO,TETA,VACA,VAGA,VAGO,VAKA,VUEI,VUEY,WUEI,WUEY';
    
    SET l = CHAR_LENGTH(IN_Name);
    SET i = 1;
   
	 IF FIND_IN_SET(UPPER(IN_Name),DerogatoryTerm)>0 THEN    
	 	
		 SET WordReturned = ''; 

	    WHILE i <= l DO
	        SET ch = SUBSTRING(UPPER(IN_Name), i, 1);
	
	        IF Vowel=0 AND ch IN ('A','E','I','O','U') THEN
	           SET  ch='X';
	           SET Vowel = Vowel + 1;
	        END IF;
	        
	        SET WordReturned = CONCAT(WordReturned,ch);
	        
	        SET i = i + 1;
	       
	    END WHILE;	
	  
	END IF; 
	
	RETURN WordReturned;
	
END//
DELIMITER ;

-- Volcando estructura para disparador y_trigger_clients_merge_sires
DROP TRIGGER IF EXISTS `y_trigger_clients_merge_sires`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE DEFINER=`root`@`localhost` TRIGGER `y_trigger_clients_merge_sires` AFTER INSERT ON `clients_merge_history` FOR EACH ROW BEGIN
	/*
	 * @Autor: Ariadna RA
	 * @Created:14/04/2025
	 * @Ticket HS: 22055276319
	 * @Rpt:sires_form. Actualiza los datos del sires en el caso en el que el cliente se consolida en flowww
	 */	
	
	#Se verifica si existen los clientes consolidados creados como clientes del flowww-SIRES.
	SET @__ExistClientFrom = (SELECT COUNT(sc.SID) FROM  __sires_clients sc WHERE sc.SClientID=NEW.MergerFromID);
	SET @__ExistClientTo = (SELECT COUNT(sc.SID) FROM  __sires_clients sc WHERE sc.SClientID=NEW.MergerToID);
		
	#Se determina si se realiza la consolidaci�n de clientes a nivel de SIRES.
	IF @__ExistClientFrom>0 OR @__ExistClientTo>0 THEN 
		
		#Se pasan todas las consultas del cliente duplicado al cliente al cliente original que se mantendr� en el sistema
		UPDATE __sires_diary_gen sdg 
		SET sdg.SDiaryGClientID=NEW.MergerToID
		WHERE sdg.SDiaryGClientID=NEW.MergerFromID;		
		
		#Si el cliente original no tiene consultas SIRES se remplaza por los datos del duplicado.
		IF @__ExistClientTo=0 THEN	
				
				INSERT INTO __sires_clients (SClientID,SClientFieldID,SClientFieldValue)
				SELECT 
					NEW.MergerToID,
					FieldID,
					(CASE FieldName
						WHEN 'nombre' THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(TRIM(UPPER(ClientName)),1,50),'�','A'),'�','E'),'�','I'),'�','O'),'�','U')
						WHEN 'primerApellido' THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(TRIM(UPPER(ClientSurname1)),1,50),'�','A'),'�','E'),'�','I'),'�','O'),'�','U')
						WHEN 'segundoApellido' THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(TRIM(UPPER(ClientSurname2)),1,50),'�','A'),'�','E'),'�','I'),'�','O'),'�','U')
						WHEN 'fechaNacimiento' THEN ClientBirthDate
						WHEN 'curpPaciente' THEN cl.ClientNIF
						WHEN 'paisNacPaciente' THEN xcc.CountrySIRESKey
						WHEN 'entidadNacimiento' THEN xcp.ProvinceSiresCatalogKey
						WHEN 'sexoCURP' THEN (CASE cl.ClientSex WHEN 'F' THEN 2 WHEN 'M' THEN 1 ELSE 3 END)
						WHEN 'sexoBiologico' THEN (CASE cl.ClientSexByGender WHEN 'F' THEN 2 WHEN 'M' THEN 1 ELSE 3 END)
					ELSE 	
						SClientFieldValue 
					END) AS FieldValue
				FROM 
					__sires_x_config_field xcf
					INNER JOIN __sires_x_config_field_section xcs ON xcs.FieldSectionID=xcf.FieldSectionID AND xcs.FieldSectionTypeData=1 
					LEFT JOIN __sires_clients c ON c.SClientFieldID=xcf.FieldID AND (ISNULL(c.SClientID) OR c.SClientID=NEW.MergerFromID)
					LEFT JOIN clients cl ON cl.ClientID=NEW.MergerToID	
					LEFT JOIN x_config_countries xcc ON xcc.CountryID=cl.ClientBirthCountryID
					LEFT JOIN x_config_provinces xcp ON xcp.ProvinceID=cl.ClientBirthProvinceID
				WHERE 
					FieldDisabled = 0;
					
		END IF;
		
		#Si el cliente dulicado ten�a consultas consultas se eliminar el registro 		
		IF @__ExistClientFrom>0 THEN	
			DELETE FROM __sires_clients WHERE SClientID=NEW.MergerFromID;
		END IF;	
			
	END IF;
		
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
