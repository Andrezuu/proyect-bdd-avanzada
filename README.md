Ejecutar 
```
docker compose up -d
docker cp init.sql apuestas_postgres:/tmp/init.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/init.sql 
docker cp functions.sql apuestas_postgres:/tmp/functions.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/functions.sql 
docker cp procedures.sql apuestas_postgres:/tmp/procedures.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/procedures.sql 
docker cp triggers.sql apuestas_postgres:/tmp/triggers.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/triggers.sql 
docker cp indexes.sql apuestas_postgres:/tmp/indexes.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/indexes.sql 
docker cp hashing.sql apuestas_postgres:/tmp/hashing.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/hashing.sql 
docker cp optimization.sql apuestas_postgres:/tmp/optimization.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/optimization.sql 
pip install psycopg2-binary faker
python init_data.py
```