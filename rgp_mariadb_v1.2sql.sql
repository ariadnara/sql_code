
ALTER TABLE `wpda_ext_type_pkg_credit`  ADD `time_active` SMALLINT  UNSIGNED NULL DEFAULT NULL COMMENT 'Tiempo de validez de los bonos.';
ALTER TABLE `wpda_ext_type_pkg_credit`  ADD `type_time_active` ENUM('D','M','Y','H','I')  NULL DEFAULT 'M' COMMENT 'Clasificación den time_active. d-días, m-mes,y-año,n-minutos '  AFTER `time_active`;
ALTER TABLE `wpda_ext_credits`  ADD `date_expired` DATE NULL COMMENT 'Fecha en vence el bono.'  AFTER `limit_acq`;
ALTER TABLE `wpda_ext_credits` ADD `acq_consumed` INT NOT NULL DEFAULT '0' COMMENT 'Adquisiciones consumidas del crédito comprado.' AFTER `limit_acq`; 

-------- FUNCTION -----------------
DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_credits_date_expired`(`user_id` BIGINT) RETURNS varchar(100) CHARSET utf8mb4
BEGIN	
	SET @limit_acq = 0;
    SET  @date_expired = NULL;
    
	SELECT 
    	sum(c.limit_acq-c.acq_consumed),
        MAX(c.date_expired)
    INTO @limit_acq, @date_expired
    FROM wpda_ext_credits c
	WHERE c.id_user = user_id
    AND c.status_credits=0
    AND c.limit_acq>c.acq_consumed 
    AND c.date_expired>CURRENT_DATE;
    
    RETURN concat(@limit_acq,'|', @date_expired);
END$$

-------EVENT------------------
CREATE DEFINER=`root`@`localhost` 
EVENT `check_acq_confirmed` 
ON SCHEDULE EVERY 1 DAY STARTS '2022-04-12 00:00:00' 
ON COMPLETION NOT PRESERVE ENABLE DO 
UPDATE wp_posts s 
INNER JOIN wpda_ext_acq a ON a.post_id=s.ID
SET s.post_status='draft'      
WHERE 
    a.data_closed is null
    AND datediff(curdate(),a.date_insert) > 15
    AND s.post_status not like 'draft' 

----------QUERIES--------------
SELECT 
	a.date_insert,
	datediff(curdate(),a.date_insert),
	a.*
FROM 
	wp_posts s 
	INNER JOIN wpda_ext_acq a ON a.post_id=s.ID 
WHERE 
	a.data_closed is null
    AND datediff(curdate(),a.date_insert) > 15
    AND s.post_status not like 'draft';
-- 
UPDATE wpda_ext_credits w
SET w.acq_consumed = @new_value_consumed := w.acq_consumed + 1,
	w.data_consumed = IF(w.limit_acq = @new_value_consumed,CURRENT_TIME,NULL),
	w.status_credits = IF(w.limit_acq = @new_value_consumed,1,0)
WHERE w.id_user = 1
    AND w.limit_acq > w.acq_consumed
    AND (w.date_expired > CURRENT_DATE OR w.date_expired IS NULL) 
ORDER BY w.date_expired ASC
LIMIT 1;
