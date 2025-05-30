Ejecutar 
```
docker compose up -d
docker cp init.sql apuestas_postgres:/tmp/init.sql
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/init.sql
pip install psycopg2-binary faker
python init_data.py
```