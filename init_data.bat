@echo off
echo ==== 🚀 Iniciando carga de datos SQL + Python ====

setlocal enabledelayedexpansion
set FIRST_RUN=1

REM ---------- POSTGRES ----------
echo [PostgreSQL] Ejecutando archivos SQL...
for %%F in (init views functions procedures triggers indexes hashing) do (
    echo [PostgreSQL] %%F.sql
    docker cp postgres/%%F.sql apuestas_postgres_primary:/tmp/%%F.sql
    docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/%%F.sql 1>nul

    if "!FIRST_RUN!"=="1" (
        echo [PostgreSQL] Ejecutando init_data.py...
        python postgres/init_data.py
        set FIRST_RUN=0
    )
)

REM ---------- MYSQL ----------
set FIRST_RUN=1
echo [MySQL] Ejecutando archivos SQL...
for %%F in (init views functions procedures triggers indexes hashing) do (
    echo [MySQL] %%F.sql
    docker cp mysql/%%F.sql apuestas_mysql:/tmp/%%F.sql
    docker exec -i apuestas_mysql bash -c "mysql -u root apuestas_db < /tmp/%%F.sql 1>nul 2>&1"

    if "!FIRST_RUN!"=="1" (
        echo [MySQL] Ejecutando init_data.py...
        python mysql/init_data.py
        set FIRST_RUN=0
    )
)

echo ==== ✅ Carga SQL + Datos finalizada ====
pause
