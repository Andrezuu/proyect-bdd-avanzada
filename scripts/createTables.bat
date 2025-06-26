@echo off
echo Copiando y ejecutando PostgreSQL...
docker cp postgres/init.sql apuestas_postgres_primary:/tmp/init.sql
docker exec apuestas_postgres_primary sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/init.sql"

docker cp postgres/triggers.sql apuestas_postgres_primary:/tmp/triggers.sql
docker exec apuestas_postgres_primary sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/triggers.sql"

docker cp postgres/functions.sql apuestas_postgres_primary:/tmp/functions.sql
docker exec apuestas_postgres_primary sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/functions.sql"

docker cp postgres/procedures.sql apuestas_postgres_primary:/tmp/procedures.sql
docker exec apuestas_postgres_primary sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/procedures.sql"

timeout /t 10 
echo Copiando y ejecutando MySQL...
docker cp mysql/init.sql apuestas_mysql:/tmp/init.sql
docker exec apuestas_mysql sh -c "mysql -u root -p$(printenv MYSQL_ROOT_PASSWORD) $(printenv MYSQL_DATABASE) < /tmp/init.sql"

docker cp mysql/functions.sql apuestas_mysql:/tmp/functions.sql
docker exec apuestas_mysql sh -c "mysql -u root -p$(printenv MYSQL_ROOT_PASSWORD) $(printenv MYSQL_DATABASE) < /tmp/functions.sql"

docker cp mysql/procedures.sql apuestas_mysql:/tmp/procedures.sql
docker exec apuestas_mysql sh -c "mysql -u root -p$(printenv MYSQL_ROOT_PASSWORD) $(printenv MYSQL_DATABASE) < /tmp/procedures.sql"

echo Configurando MongoDB Sharding...

echo 1. Iniciando replicaset en Config Server...
docker exec mongo_configsvr mongosh --port 27019 --eval "rs.initiate({_id: 'mongors1conf', members: [{_id: 0, host: 'mongo_configsvr:27019'}]})" 

echo 2. Iniciando replicaset en Shard 2...
docker exec mongo_shard1 mongosh --port 27018 --eval "rs.initiate({_id: 'mongors1', members: [{_id: 0, host: 'mongo_shard1:27018'}]})"

echo 3. Iniciando replicaset en Shard 2...
docker exec mongo_shard2 mongosh --port 27018 --eval "rs.initiate({_id: 'mongors2', members: [{_id: 0, host: 'mongo_shard2:27018'}]})"

echo 4. Esperando a que los replica sets esten listos...
timeout /t 10

echo 5. Agregando shards al cluster...
docker exec mongo_router mongosh --eval "sh.addShard('mongors1/mongo_shard1:27018')"
docker exec mongo_router mongosh --eval "sh.addShard('mongors2/mongo_shard2:27018')"

docker cp etl/init.sql apuestas_postgres_etl:/tmp/init.sql
docker exec apuestas_postgres_etl sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/init.sql"

echo Listo!
pause