import mysql.connector


def MappClinics(
    source_cfg: dict,
    target_cfg: dict
):
    """
    Realiza el mapeo entre CENTRO (origen) y x_config_clinics (destino)
    y crea/inserta datos en __mig_mapp_clinics.
    """

    # ---------- CONEXIONES ----------
    src_conn = mysql.connector.connect(**source_cfg)
    tgt_conn = mysql.connector.connect(**target_cfg)

    src_cur = src_conn.cursor(dictionary=True)
    tgt_cur = tgt_conn.cursor(dictionary=True)

    try:
        # ---------- CONSULTAS ----------
        src_query = """
            SELECT 
                `KEY`,
                CODIGO,
                NOMBRE,
                FRANQUICIADOASOCIADO_KEY_OID
            FROM CENTRO
        """

        tgt_query = """
            SELECT
                ClinicID,
                ClinicCommercialName,
                ClinicPrefix
            FROM x_config_clinics
        """

        src_cur.execute(src_query)
        src_rows = src_cur.fetchall()

        tgt_cur.execute(tgt_query)
        tgt_rows = tgt_cur.fetchall()

        # ---------- INDEXACIÓN DESTINO ----------
        # key: CODIGO normalizado (sin ceros)
        tgt_index = {
            row["ClinicPrefix"].lstrip("0"): row
            for row in tgt_rows
            if row["ClinicPrefix"]
        }

        # ---------- CREAR TABLA ----------
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS __mig_mapp_clinics (
            ClinicIDFrom INT,
            ClinicFranqID INT,
            ClinicCommercialNameFrom VARCHAR(255),
            ClinicIDTo INT,
            ClinicCommercialNameTo VARCHAR(255),
            PRIMARY KEY (ClinicIDFrom, ClinicIDTo)
        )
        """

        tgt_cur.execute(create_table_sql)

        # ---------- INSERCIÓN ----------
        insert_sql = """
            INSERT INTO __mig_mapp_clinics (
                ClinicIDFrom,
                ClinicFranqID,
                ClinicCommercialNameFrom,
                ClinicIDTo,
                ClinicCommercialNameTo
            )
            VALUES (%s, %s, %s, %s, %s)
        """

        data_to_insert = []

        for src in src_rows:
            codigo = str(src["CODIGO"]).lstrip("0")

            if codigo in tgt_index:
                tgt = tgt_index[codigo]
                data_to_insert.append((
                    src["KEY"],
                    src["FRANQUICIADOASOCIADO_KEY_OID"],
                    src["NOMBRE"],
                    tgt["ClinicID"],
                    tgt["ClinicCommercialName"]
                ))

        if data_to_insert:
            tgt_cur.executemany(insert_sql, data_to_insert)
            tgt_conn.commit()

        print(f"✔ Migración completada: {len(data_to_insert)} registros insertados")

    finally:
        src_cur.close()
        tgt_cur.close()
        src_conn.close()
        tgt_conn.close()
