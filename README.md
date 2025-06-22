# 🏆 Sistema de Casa de Apuestas

Sistema de base de datos avanzado para gestión de apuestas deportivas, implementado con PostgreSQL y MongoDB.

## 📚 Documentación

### 🏗️ Arquitectura
- [Arquitectura Docker](docs/architecture/diagrama_docker.md)
- [Arquitectura Redis](docs/architecture/diagrama_redis.md)
- [Esquema de Base de Datos](architecture/database-schema.md)

### 🚀 Guías Rápidas
- [Instalación y Configuración](guides/installation.md)
- [Backup y Restore](guides/backup-restore.md)

## ⚙️ Tecnologías

- PostgreSQL 15
- MongoDB
- Redis
- Docker & Docker Compose
- Python (Faker)
- Node.js

## 🛠️ Estructura del Proyecto

```
proyecto-bdd/
├── postgres/               # Scripts PostgreSQL
│   ├── init.sql           # Esquema inicial
│   ├── functions.sql      # Funciones PL/pgSQL
│   ├── procedures.sql     # Procedimientos almacenados
│   ├── triggers.sql       # Triggers automáticos
│   ├── views.sql         # Vistas
│   └── indexes.sql       # Índices optimizados
│
├── mongodb/              # Scripts MongoDB
│   └── queries.js       # Consultas principales
│
├── scripts/             # Scripts de utilidad
│   ├── backup.js       # Sistema de backups
│   └── restore.js      # Restauración
│
└── docs/               # Documentación
    ├── architecture/   # Diagramas y diseño
    ├── guides/        # Guías de uso
    └── development/   # Guías desarrollo
```

## 🚀 Inicio Rápido

1. **Clonar el repositorio**
```bash
git clone <repo-url>
cd proyecto-bdd-avanzada
```

2. **Configurar el entorno**
```bash
cp .env.example .env
# Editar .env según necesidades
```

3. **Levantar servicios**
```bash
docker-compose up -d
```

4. **Inicializar base de datos**
```bash
./init_data.bat
```

## 📈 Características Principales

- Sistema de autenticación seguro
- Gestión de apuestas en tiempo real
- Backups automatizados
- Caché con Redis
- Documentación completa

## 👥 Equipo

- Andres Sanchez 
- Alexia Marin 
- Adrian Sanchez 
