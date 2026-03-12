# @Autor: Ariadna RA
# @Created:24/02/2026
# @SK: 659909
# @Ticket HS:36393476676
# @Concepto: main.py 

import os
from dotenv import load_dotenv
from mig_clients import MigClients
from mig_clients_fix import MigClientsFix 
from mig_clients_rep import MigClientRep
from mig_laser_diagnostic import MigLaserDiagnostics
from mig_laser_fix import MigLaserFix
from mig_laser_tto import MigLaserTto 
from mig_laser_mtto import MigLaserMtto 
from mig_laser_det import MigLaserDet
from mig_users import MappUsers
from mig_vouchers import MigVouchers 
#from mapp_clinics import create_clinic_mapping

load_dotenv()  # carga las variables desde .env

#Origen BD Prod
HOSTSRC = os.getenv("HOSTSRC")
USRC = os.getenv("USRC")
KEYSRC = os.getenv("KEYSRC")
BDSRC = os.getenv("BDSRC")
PORTSRC = int(os.getenv("PORTSRC"))

#Origen BD Desarrollo
HOSTSRCDEV = os.getenv("HOSTSRCDEV")
USRCDEV = os.getenv("USRCDEV")
KEYSRCDEV = os.getenv("KEYSRCDEV")
BDSRCDEV = os.getenv("BDSRCDEV")
PORTSRCDEV = int(os.getenv("PORTSRCDEV"))

#Destino BD flowww
HOSTTGT = os.getenv("HOSTTGT")
UTGT = os.getenv("UTGT")
KEYTARGET = os.getenv("KEYTARGET")
BDTGT = os.getenv("BDTGT")
PORTTGT = int(os.getenv("PORTTGT"))

#Objetos de conexión
source_config = {
    "host": HOSTSRC,
    "user": USRC,
    "password": KEYSRC,
    "database": BDSRC,
    "port":PORTSRC,
    "charset":'utf8mb4',
    "collation":'utf8mb4_general_ci'
}

source_config_dev = {
    "host": HOSTSRCDEV,
    "user": USRCDEV,
    "password": KEYSRCDEV,
    "database": BDSRCDEV,
    "port":PORTSRCDEV,
    "charset":'utf8mb4',
    "collation":'utf8mb4_general_ci'
}

target_config = {
    "host": HOSTTGT,
    "user": UTGT,
    "password": KEYTARGET,
    "database": BDTGT,
    "port":PORTTGT,
}

#MappClinics(source_config, target_config)
#MappUsers(source_config, source_config_dev, target_config)


print("=" * 60)
print("INICIANDO MIGRACIONES DE DATOS")
print("=" * 60)

# print("\n📋 Migrando clientes desde BD Desarrollo...")
# MigClients(source_config_dev, target_config).run_migration()

# print("\n📋 Migrando clientes desde BD Producción...")
# MigClients(source_config, target_config).run_migration()

# print("\n📅 Ejecutando fix de clientes")
# MigClientsFix(target_config).run_migration()

# print("\n📅 Migrando tutores")
# MigClientRep(target_config).run_migration()

# print("\n📅 Migrando historiales desde BD Desarrollo...")
# MigLaserDiagnostics(source_config_dev, target_config).run_migration()
# MigLaserTto(source_config_dev, target_config).run_migration()
# MigLaserMtto(source_config_dev, target_config).run_migration()

# print("\n📅 Migrando historiales desde BD Producción...")
# MigLaserDiagnostics(source_config, target_config).run_migration()
# MigLaserTto(source_config, target_config).run_migration()
# MigLaserMtto(source_config, target_config).run_migration()

# print("\n📅 Migrando detalles historiales con datos de la BD destino...")
# MigLaserDet(target_config).run_migration()

# print("\n📅 Ejecutando fix en detalles historiales con datos de la BD destino...")
# MigLaserFix(target_config).run_migration()

# print("\n📅 Migrando bonos desde BD Desarrollo...")
# MigVouchers(source_config_dev,target_config).run_migration()

# print("\n📅 Migrando bonos desde BD Producción...")
# MigVouchers(source_config,target_config).run_migration()

print("\n" + "=" * 60)
print("✅ TODAS LAS MIGRACIONES COMPLETADAS")
print("=" * 60)


# CREATE TABLE laser_gen_bkp_20260310 SELECT * FROM laser_gen;
# CREATE TABLE laser_det_bkp_20260310 SELECT * FROM laser_det;
# CREATE TABLE diary_gen_bkp_20260310 SELECT * FROM diary_gen;
# DELETE FROM laser_gen WHERE laser_gen.__LaserMigrated=-1;
# DELETE FROM laser_det WHERE laser_det.LaserImportID>0;
# DELETE FROM diary_gen WHERE diary_gen.DiaryGInvisible=-1;