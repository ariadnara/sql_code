import mysql.connector
from datetime import date

#    Realiza el mapeo entre CENTRO (origen) y x_config_clinics (destino) y crea/inserta datos en __mig_mapp_clinics.
def MappUsers(
    source_cfg: dict,
    source_cfg_dev: dict,
    target_cfg: dict
):

    # ---------- CONEXIONES ----------
    src_conn = mysql.connector.connect(**source_cfg)
    src_conn_dev = mysql.connector.connect(**source_cfg_dev)
    tgt_conn = mysql.connector.connect(**target_cfg)

    src_cur = src_conn.cursor(dictionary=True)
    src_cur_dev = src_conn_dev.cursor(dictionary=True)
    tgt_cur = tgt_conn.cursor(dictionary=True)

    try:
        # ---------- CONSULTAS ----------
        src_query = """
                    SELECT 
                        `KEY`,
                        NOMBRE,
                        PERFIL,
                        USUARIOGOOGLE,
                        TOKENCREATIONDATE,
                        CENTROUSUARIO_KEY_OID,
                        `PASSWORD`,
                        'PROD' AS TYPEBD
                    FROM USUARIO
        """
        src_query_dev = """
                    SELECT 
                        `KEY`,
                        NOMBRE,
                        PERFIL,
                        USUARIOGOOGLE,
                        TOKENCREATIONDATE,
                        CENTROUSUARIO_KEY_OID,
                        `PASSWORD`,
                        'DEV' AS TYPEBD
                    FROM USUARIO
        """        

        src_cur.execute(src_query)
        src_rows = src_cur.fetchall()
        src_cur_dev.execute(src_query_dev)
        src_rows_dev = src_cur_dev.fetchall()


        # ---------- CREAR TABLA ----------
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS __mig_users (
            UserIDFrom INT,
            UsernameFrom VARCHAR(255),
            UserClassFrom VARCHAR(255),
            UserLogin VARCHAR(255),
            UserDate Date,
            UserClinicID INT,
            UserTypeBD VARCHAR(10),
            UserPass VARCHAR(255),
            PRIMARY KEY (UserIDFrom)
        )
        """
        create_table_sql_dev = """
        CREATE TABLE IF NOT EXISTS __mig_users_dev (
            UserIDFrom INT,
            UsernameFrom VARCHAR(255),
            UserClassFrom VARCHAR(255),
            UserLogin VARCHAR(255),
            UserDate Date,
            UserClinicID INT,
            UserTypeBD VARCHAR(10),
            UserPass VARCHAR(255),
            PRIMARY KEY (UserIDFrom)
        )
        """
        tgt_cur.execute(create_table_sql)
        tgt_cur.execute(create_table_sql_dev)

        # ---------- INSERCIÓN ----------
        insert_sql = """
            REPLACE INTO
            __mig_users (
                UserIDFrom,
                UsernameFrom,
                UserClassFrom,
                UserLogin,                
                UserDate,
                UserClinicID,
                UserTypeBD,
                UserPass
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """

        insert_sql_dev = """
            REPLACE INTO
            __mig_users_dev (
                UserIDFrom,
                UsernameFrom,
                UserClassFrom,
                UserLogin,
                UserDate,
                UserClinicID,
                UserTypeBD,
                UserPass
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """

        data_to_insert = []
        data_to_insert_dev = []

        for src in src_rows:
            data_to_insert.append((
                    src["KEY"],
                    src["NOMBRE"],
                    src["PERFIL"],
                    src["USUARIOGOOGLE"],                    
                    str(src["TOKENCREATIONDATE"] or date.today()),
                    src["CENTROUSUARIO_KEY_OID"] or 0,
                    src["TYPEBD"],    
                    src["PASSWORD"]   
            ))
        
        for src_dev in src_rows_dev:
            data_to_insert_dev.append((
                    src_dev["KEY"],
                    src_dev["NOMBRE"],
                    src_dev["PERFIL"],
                    src_dev["USUARIOGOOGLE"],                    
                    str(src_dev["TOKENCREATIONDATE"] or date.today()),
                    src_dev["CENTROUSUARIO_KEY_OID"] or 0,
                    src_dev["TYPEBD"],    
                    src_dev["PASSWORD"]   
            ))

        if data_to_insert:
            tgt_cur.executemany(insert_sql, data_to_insert)
            tgt_conn.commit()

        if data_to_insert_dev:
            tgt_cur.executemany(insert_sql_dev, data_to_insert_dev)
            tgt_conn.commit()

        print(f"✔ Migración de usuarios completada: {len(data_to_insert)} registros insertados")

    finally:
        src_cur.close()
        src_cur_dev.close()
        tgt_cur.close()
        src_conn.close()
        src_conn_dev.close()
        tgt_conn.close()
