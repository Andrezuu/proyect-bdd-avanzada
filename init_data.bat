@echo off
echo ==== Iniciando carga de datos SQL + Python ====

setlocal enabledelayedexpansion
set FIRST_RUN=1
docker cp postgres/init.sql apuestas_postgres_primary:/tmp/init.sql
docker exec apuestas_postgres_primary sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/init.sql"
docker cp mysql/init.sql apuestas_mysql:/tmp/init.sql
docker exec apuestas_mysql sh -c "mysql -u root -p$(printenv MYSQL_ROOT_PASSWORD) $(printenv MYSQL_DATABASE) < /tmp/init.sql"
echo [PostgreSQL] Ejecutando init_data.py...
python scripts/init_data.py

REM ---------- POSTGRES ----------
echo [PostgreSQL] Ejecutando archivos SQL...
for %%F in (views functions procedures triggers indexes roles) do (
    if exist postgres/%%F.sql (
        echo [PostgreSQL] %%F.sql
        docker cp postgres/%%F.sql apuestas_postgres_primary:/tmp/%%F.sql
        docker exec apuestas_postgres_primary sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/%%F.sql" 1>nul
    ) else (
        echo [PostgreSQL] Archivo postgres/%%F.sql no encontrado, saltando...
    )
)

REM ---------- MYSQL ----------
echo [MySQL] Ejecutando archivos SQL...
for %%F in (functions procedures triggers indexes roles) do (
    if exist mysql/%%F.sql (
        echo [MySQL] %%F.sql
        docker cp mysql/%%F.sql apuestas_mysql:/tmp/%%F.sql
        docker exec apuestas_mysql sh -c "mysql -u root -p$(printenv MYSQL_ROOT_PASSWORD) $(printenv MYSQL_DATABASE) < /tmp/%%F.sql"
    ) else (
        echo [MySQL] Archivo mysql/%%F.sql no encontrado, saltando...
    )
)

REM ---------- MONGODB SHARDING ----------
echo Configurando MongoDB Sharding...

echo 1. Iniciando replicaset en Config Server...
docker exec mongo_configsvr mongosh --port 27019 --eval "rs.initiate({_id: 'mongors1conf', members: [{_id: 0, host: 'mongo_configsvr:27019'}]})"

echo 2. Iniciando replicaset en Shard 1...
docker exec mongo_shard1 mongosh --port 27018 --eval "rs.initiate({_id: 'mongors1', members: [{_id: 0, host: 'mongo_shard1:27018'}]})"

echo 3. Iniciando replicaset en Shard 2...
docker exec mongo_shard2 mongosh --port 27018 --eval "rs.initiate({_id: 'mongors2', members: [{_id: 0, host: 'mongo_shard2:27018'}]})"

echo 4. Esperando a que los replica sets esten listos...
timeout /t 10

echo 5. Agregando shards al cluster...
docker exec mongo_router mongosh --eval "sh.addShard('mongors1/mongo_shard1:27018')"
docker exec mongo_router mongosh --eval "sh.addShard('mongors2/mongo_shard2:27018')"

REM ---------- POSTGRES ETL ----------
echo [PostgreSQL ETL] Ejecutando init.sql...
docker cp etl/init.sql apuestas_postgres_etl:/tmp/init.sql
docker exec apuestas_postgres_etl sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/init.sql"

echo ==== Proceso finalizado! ====
pause
