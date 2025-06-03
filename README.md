# 🏆 Proyecto Base de Datos Avanzada – Casa de Apuestas

Este proyecto forma parte de la materia de **Base de Datos Avanzada** y consiste en el desarrollo de una base de datos para una casa de apuestas deportivas. Se utilizó **PostgreSQL** dentro de un entorno **Docker**, sin ningún backend, cumpliendo con los requerimientos de la **Primera Fase**.

---

## 📌 Objetivo General

Diseñar e implementar una base de datos relacional avanzada que permita gestionar usuarios, apuestas, eventos deportivos, mercados de apuestas y resultados, utilizando SQL puro con soporte para funciones, procedimientos, triggers, índices, y operaciones de optimización.

---

## 🧱 Tecnologías Utilizadas

- PostgreSQL 15
- Docker y Docker Compose
- DBeaver (como cliente SQL)
- Python (para poblar datos ficticios)
- Librerías Python: `psycopg2-binary`, `faker`

---

## ⚙️ Configuración Inicial del Proyecto

### 🐳 Levantar el contenedor de PostgreSQL
```bash
docker compose up -d
````
---

## 🧩 Estructura de Archivos

| Archivo / Carpeta    | Descripción                                                                          |
| -------------------- | ------------------------------------------------------------------------------------ |
| `init.sql`           | Crea las tablas base y relaciones principales de la base de datos                    |
| `functions.sql`      | Contiene funciones definidas en PL/pgSQL para lógica específica                      |
| `procedures.sql`     | Procedimientos almacenados para operaciones complejas                                |
| `triggers.sql`       | Triggers que ejecutan acciones automáticas en respuesta a eventos                    |
| `indexes.sql`        | Definición de índices para optimizar consultas pesadas                               |
| `hashing.sql`        | Manejo de seguridad, como encriptación u ofuscamiento de contraseñas                 |
| `optimization.sql`   | Consultas optimizadas con `EXPLAIN ANALYZE`, y recomendaciones de mejora             |
| `views.sql`          | Creación de vistas para simplificar consultas complejas                              |
| `init_data.py`       | Script en Python que usa `faker` para poblar la base con datos ficticios             |
| `backups/`           | Carpeta que contiene scripts de respaldo (`backup.js`) y restauración (`restore.js`) |
| `docker-compose.yml` | Archivo de configuración de Docker para levantar el contenedor de PostgreSQL         |
| `package.json`       | Dependencias de Node.js requeridas para ejecutar los scripts de `backups/`           |
| `package-lock.json`  | Versión fija de las dependencias para asegurar consistencia                          |

---

## 🧪 Pasos de Carga y Ejecución

### 1. Cargar el script principal de creación de tablas

```bash
docker cp init.sql apuestas_postgres:/tmp/init.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/init.sql
```

--- 

## 2. 📊 Carga de Datos Ficticios

### Instalar dependencias en Python

```bash
pip install psycopg2-binary faker
```

### Ejecutar script de carga

```bash
python init_data.py
```

El script pobla las tablas principales con usuarios, eventos deportivos, mercados, y apuestas simuladas utilizando la librería `faker`.

--- 

### 3. Creacion de views

```bash
docker cp views.sql apuestas_postgres:/tmp/views.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/views.sql
```

### 4. Cargar funciones (`plpgsql`)

```bash
docker cp functions.sql apuestas_postgres:/tmp/functions.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/functions.sql
```

### 5. Cargar procedimientos almacenados

```bash
docker cp procedures.sql apuestas_postgres:/tmp/procedures.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/procedures.sql
```

### 6. Cargar triggers

```bash
docker cp triggers.sql apuestas_postgres:/tmp/triggers.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/triggers.sql
```

### 7. Crear índices

```bash
docker cp indexes.sql apuestas_postgres:/tmp/indexes.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/indexes.sql
```

### 8. Ejecutar lógica de ofuscamiento

```bash
docker cp hashing.sql apuestas_postgres:/tmp/hashing.sql 
docker exec -it apuestas_postgres psql -U postgres -d apuestas_db -f /tmp/hashing.sql
```
---

## ✅ Requerimientos Cumplidos - Fase 1

* [x] Creación de base de datos relacional avanzada.
* [x] Inserción de datos estructurados y relacionales.
* [x] Uso de funciones SQL (`plpgsql`).
* [x] Uso de procedimientos almacenados.
* [x] Implementación de triggers.
* [x] Generación de índices y consultas optimizadas (`EXPLAIN ANALYZE`).
* [x] Lógica de ofuscamiento de datos sensibles (como contraseñas).
* [x] Carga automatizada con scripts Python.

---

## 📸 Herramientas de Visualización

* Cliente: **DBeaver**
* Entorno: **Docker Desktop**
* Edición de SQL: **VS Code**

---

## ✍️ Autores

* Andres Sanchez
* Alexia Marin
* Adrian Sanchez

---

## 📂 Estructura del Proyecto

```
proyect-bdd-avanzada/
├── backups/
│   ├── backup.js
│   └── restore.js
├── docker-compose.yml
├── functions.sql
├── hashing.sql
├── indexes.sql
├── init.sql
├── init_data.py
├── optimization.sql
├── package-lock.json
├── package.json
├── procedures.sql
├── README.md
├── triggers.sql
└── views.sql

```
