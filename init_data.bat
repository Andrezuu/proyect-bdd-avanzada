@echo off
echo ==== Iniciando carga de datos SQL + Python ====

setlocal enabledelayedexpansion
set FIRST_RUN=1

REM ---------- POSTGRES ----------
echo [PostgreSQL] Ejecutando archivos SQL...
for %%F in (init views functions procedures triggers indexes hashing) do (
    echo [PostgreSQL] %%F.sql
    docker cp postgres/%%F.sql apuestas_postgres_primary:/tmp/%%F.sql
    docker exec apuestas_postgres_primary sh -c "PGPASSWORD=$(printenv POSTGRESQL_PASSWORD) psql -U $(printenv POSTGRESQL_USERNAME) -d $(printenv POSTGRESQL_DATABASE) -f /tmp/%%F.sql" 1>nul
    if "!FIRST_RUN!"=="1" (
        echo [PostgreSQL] Ejecutando init_data.py...
        python init_data.py
        set FIRST_RUN=0
    )
)

@REM REM ---------- MYSQL ----------
@REM set FIRST_RUN=1
@REM echo [MySQL] Ejecutando archivos SQL...
@REM for %%F in (init views functions procedures triggers indexes hashing) do (
@REM     echo [MySQL] %%F.sql
@REM     docker cp mysql/%%F.sql apuestas_mysql:/tmp/%%F.sql
@REM     docker exec -i apuestas_mysql bash -c "mysql -u root apuestas_db < /tmp/%%F.sql 1>nul 2>&1"

@REM     if "!FIRST_RUN!"=="1" (
@REM         echo [MySQL] Ejecutando init_data.py...
@REM         python mysql/init_data.py
@REM         set FIRST_RUN=0
@REM     )
@REM )

@REM echo ==== ✅ Carga SQL + Datos finalizada ====
@REM pause
