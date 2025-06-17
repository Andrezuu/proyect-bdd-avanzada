@echo off
echo ==== 🚀 Iniciando carga de datos para PostgreSQL y MySQL ====

REM ---------- POSTGRES ----------
echo [PostgreSQL] Copiando y ejecutando archivos SQL...
for %%F in (init views functions procedures triggers indexes hashing) do (
    echo [PostgreSQL] %%F.sql
    docker cp postgres/%%F.sql apuestas_postgres:/tmp/%%F.sql
    docker exec -i apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/%%F.sql
)

@REM REM ---------- MYSQL ----------
@REM echo [MySQL] Copiando y ejecutando archivos SQL...
@REM for %%F in (init views functions procedures triggers indexes hashing) do (
@REM     echo [MySQL] %%F.sql
@REM     docker cp mysql/%%F.sql apuestas_mysql:/tmp/%%F.sql
@REM     docker exec -i apuestas_mysql bash -c "mysql -u mysqluser apuestas_db < /tmp/%%F.sql"
@REM )

@REM echo ==== ✅ Carga finalizada ====
pause
