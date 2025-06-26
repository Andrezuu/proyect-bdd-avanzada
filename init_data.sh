#!/bin/bash
set -e

echo "==== Iniciando carga de datos SQL + Python ===="

# Copiar y ejecutar init.sql en PostgreSQL
docker cp postgres/init.sql apuestas_postgres_primary:/tmp/init.sql
docker exec apuestas_postgres_primary sh -c "PGPASSWORD=\$POSTGRESQL_PASSWORD psql -U \$POSTGRESQL_USERNAME -d \$POSTGRESQL_DATABASE -f /tmp/init.sql"

# Copiar y ejecutar init.sql en MySQL
docker cp mysql/init.sql apuestas_mysql:/tmp/init.sql
docker exec apuestas_mysql sh -c "mysql -u root -p\$MYSQL_ROOT_PASSWORD \$MYSQL_DATABASE < /tmp/init.sql"

echo "[PostgreSQL] Ejecutando init_data.py..."
python3 scripts/init_data.py

# ---------- POSTGRES ----------
echo "[PostgreSQL] Ejecutando archivos SQL..."
for file in views functions procedures triggers indexes roles; do
    if [ -f "postgres/${file}.sql" ]; then
        echo "[PostgreSQL] ${file}.sql"
        docker cp "postgres/${file}.sql" apuestas_postgres_primary:/tmp/${file}.sql
        docker exec apuestas_postgres_primary sh -c "PGPASSWORD=\$POSTGRESQL_PASSWORD psql -U \$POSTGRESQL_USERNAME -d \$POSTGRESQL_DATABASE -f /tmp/${file}.sql" > /dev/null
    else
        echo "[PostgreSQL] Archivo postgres/${file}.sql no encontrado, saltando..."
    fi
done

# ---------- MYSQL ----------
echo "[MySQL] Ejecutando archivos SQL..."
for file in functions procedures triggers indexes; do
    if [ -f "mysql/${file}.sql" ]; then
        echo "[MySQL] ${file}.sql"
        docker cp "mysql/${file}.sql" apuestas_mysql:/tmp/${file}.sql
        docker exec apuestas_mysql sh -c "mysql -u root -p\$MYSQL_ROOT_PASSWORD \$MYSQL_DATABASE < /tmp/${file}.sql"
    else
        echo "[MySQL] Archivo mysql/${file}.sql no encontrado, saltando..."
    fi
done

# ---------- MONGODB SHARDING ----------
echo "Configurando MongoDB Sharding..."

echo "1. Iniciando replicaset en Config Server..."
docker exec mongo_configsvr mongosh --port 27019 --eval "rs.initiate({_id: 'mongors1conf', members: [{_id: 0, host: 'mongo_configsvr:27019'}]})"

echo "2. Iniciando replicaset en Shard 1..."
docker exec mongo_shard1 mongosh --port 27018 --eval "rs.initiate({_id: 'mongors1', members: [{_id: 0, host: 'mongo_shard1:27018'}]})"

echo "3. Iniciando replicaset en Shard 2..."
docker exec mongo_shard2 mongosh --port 27018 --eval "rs.initiate({_id: 'mongors2', members: [{_id: 0, host: 'mongo_shard2:27018'}]})"

echo "4. Esperando a que los replica sets estén listos..."
sleep 10

echo "5. Agregando shards al cluster..."
docker exec mongo_router mongosh --eval "sh.addShard('mongors1/mongo_shard1:27018')"
docker exec mongo_router mongosh --eval "sh.addShard('mongors2/mongo_shard2:27018')"

# ---------- POSTGRES ETL ----------
echo "[PostgreSQL ETL] Ejecutando init.sql..."
docker cp etl/init.sql apuestas_postgres_etl:/tmp/init.sql
docker exec apuestas_postgres_etl sh -c "PGPASSWORD=\$POSTGRESQL_PASSWORD psql -U \$POSTGRESQL_USERNAME -d \$POSTGRESQL_DATABASE -f /tmp/init.sql"

echo "==== Proceso finalizado! ===="
read -p "Presiona Enter para continuar..."
