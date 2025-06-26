# 🏆 Sistema de Casa de Apuestas

Sistema de base de datos avanzado para gestión de apuestas deportivas(OLIMPIADAS), implementado con PostgreSQL y MongoDB. ![image](https://github.com/user-attachments/assets/d4c25f18-33b0-4d1b-bb92-1a9b5593ef3a)

## 📚 Documentación

### 🏗️ Arquitectura
- [Arquitectura Docker](docs/architecture/diagrama_docker.md)
- [Arquitectura Redis](docs/architecture/diagrama_redis.md)

## 🧰 Tecnologías Utilizadas

| Componente | Tecnología | Rol |
| --- | --- | --- |
| Base relacional | PostgreSQL 15 | MySQL 8 | Gestión estructurada y ACID |
| Base NoSQL | MongoDB | Comentarios, vistas embebidas, consultas agregadas |
| Caché | Redis | Aceleración de consultas críticas |
| Contenedores | Docker & Compose | Arquitectura distribuida y replicada |
| Scripts | Python (`Faker`, `pymongo`, `mysql-connector-python`, `psycopg2-binary` ) | Generación y carga de datos |
| Automatización | Node.js | Scripts de backup/restore relacional |
| Cliente DB | DBeaver | Visualización y prueba de conexiones |

## 🚀 Guía de Inicio Rápido

1. **Clona el repositorio**

```bash
git clone <https://github.com/Andrezuu/proyect-bdd-avanzada.git>
cd proyect-bdd-avanzada

```

---

2. **Copia el archivo de configuración**

```bash
cp .env.example .env
# Edita las variables necesarias (puerto, usuario, contraseña, etc.)

```

3. **Levanta todos los servicios**
Este paso levantará:

- PostgreSQL
- MySQL
- MongoDB
- Redis

Ejecuta en la raíz del proyecto:

```bash
docker-compose up -d
```

✅ Espera a que los contenedores estén 100% iniciados (puedes verificar con `docker ps`).
4. **Instalar dependencias para MongoDB (solo si usarás los scripts Python)**

```bash
pip install pymongo faker psycopg2-binary mysql-connector-python
```

5. **Inicializa la base de datos**

```bash
./init.bat
# Ejecuta todos los scripts relacionales automáticamente
```

6. **Cargar datos falsos (opcional)**

Puedes poblar la base de datos con datos de prueba ejecutando:

```bash
python scripts/init_data.py
```

---

 7. **Backup y Restore**

- Para hacer un backup de todo el sistema:

```bash
node scripts/backup.js
```

- Para restaurar un backup:

```bash
node scripts/restore.js
```

---

## 📁 Estructura del Proyecto

```
proyect-bdd-avanzada/
├── postgres/               # Scripts PostgreSQL
│   ├── init.sql            # Tablas y relaciones
│   ├── functions.sql       # Funciones PL/pgSQL
│   ├── procedures.sql      # Procedimientos almacenados
│   ├── triggers.sql        # Automatización de lógica
│   ├── views.sql           # Consultas lógicas encapsuladas
│   └── indexes.sql         # Índices para optimización
│
├── mongodb/                # Consultas MongoDB
│   └── queries.js          # $lookup, $group, $unwind, etc.
│
├── scripts/
│   ├── init_data.py        # Generación de datos con Faker
│   ├── backup.js           # Backup PostgreSQL
│   └── restore.js          # Restauración de backups
│
├── docs/
│   ├── architecture/
│   │   ├── diagrama_docker.md
│   │   └── diagrama_redis.md
│   │   └── diagrama_mongo.md
│
└── init.bat                # Automatiza ejecución de scripts SQL

```

---

## 🧠 Funcionalidades y Técnicas Aplicadas

- 🔐 **Seguridad**: Hash de contraseñas con `crypt` en PostgreSQL.
- ⚙️ **Triggers**: Automatización de auditoría y validación.
- 🔁 **Procedimientos almacenados**: Registro de apuestas con manejo de excepciones.
- 📜 **Funciones**: Retorno de conjuntos y validaciones dinámicas.
- 📦 **Redis**: TTL y caching de eventos activos.
- ⚡ **MongoDB**: Consultas con operadores como `$unwind`, `$group`, `$match`.
- 📈 **Optimización**: Uso de `EXPLAIN ANALYZE` y creación de índices personalizados.
- 💾 **Backups**: Scripts automatizados para respaldo y recuperación.


## 📈 Características Principales

- Sistema de autenticación seguro
- Gestión de apuestas en tiempo real
- Backups automatizados
- Caché con Redis
- Documentación completa

## 👥 Equipo
Desarrollado por estudiantes de la Universidad Privada Boliviana - UPB
> 
> Materia: **Base de Datos Avanzada**
> 
- 🧑‍💻 **Andres Sanchez**
- 👩‍💻 **Alexia Marin**
- 🧑‍💻 **Adrian Sanchez**
