@echo off
echo Copiando y ejecutando PostgreSQL...
docker cp postgres/init.sql apuestas_postgres_primary:/tmp/init.sql
docker exec apuestas_postgres_primary sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/init.sql"

echo Copiando y ejecutando MySQL...
docker cp mysql/init.sql apuestas_mysql:/tmp/init.sql
docker exec apuestas_mysql sh -c "mysql -u root -p$(printenv MYSQL_ROOT_PASSWORD) $(printenv MYSQL_DATABASE) < /tmp/init.sql"

echo Listo!
pause