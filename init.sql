drop table if exists usuarios cascade;

create table
    usuarios (
        id_usuario SERIAL PRIMARY KEY,
        nombre VARCHAR(100),
        email VARCHAR(100) UNIQUE,
        password_hash TEXT,
        fecha_registro TIMESTAMP DEFAULT NOW (),
        saldo NUMERIC(12, 2),
        estado BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists roles cascade;

create table
    roles (
        id_rol SERIAL PRIMARY KEY,
        nombre_rol VARCHAR(50) UNIQUE,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists usuario_rol cascade;

create table
    usuario_rol (
        id_usuario INT REFERENCES usuarios (id_usuario),
        id_rol INT REFERENCES roles (id_rol),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW (),
        PRIMARY KEY (id_usuario, id_rol)
    );

drop table if exists eventos cascade;

create table
    eventos (
        id_evento SERIAL PRIMARY KEY,
        nombre_evento VARCHAR(100),
        deporte VARCHAR(50),
        fecha TIMESTAMP,
        resultado JSONB,
        estado VARCHAR(20),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists mercados cascade;

create table
    mercados (
        id_mercado SERIAL PRIMARY KEY,
        id_evento INT REFERENCES eventos (id_evento),
        tipo_mercado VARCHAR(50),
        cuota NUMERIC(5, 2),
        estado BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists metodos_pago cascade;

create table
    metodos_pago (
        id_metodo SERIAL PRIMARY KEY,
        id_usuario INT REFERENCES usuarios (id_usuario),
        tipo VARCHAR(50), -- tarjeta, paypal, etc.
        detalles JSONB,
        activo BOOLEAN DEFAULT TRUE,
        fecha_registro TIMESTAMP DEFAULT NOW (),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists comentarios_eventos cascade;

create table
    comentarios_eventos (
        id_usuario INT REFERENCES usuarios (id_usuario),
        id_evento INT REFERENCES eventos (id_evento),
        comentario TEXT,
        fecha TIMESTAMP DEFAULT NOW (),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW (),
        PRIMARY KEY (id_usuario, id_evento)
    );

drop table if exists categorias cascade;

create table
    categorias (
        id_categoria SERIAL PRIMARY KEY,
        nombre VARCHAR(50) UNIQUE,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists eventos_categorias cascade;

create table
    eventos_categorias (
        id_categoria INT REFERENCES categorias (id_categoria) ON DELETE CASCADE,
        id_evento INT REFERENCES eventos (id_evento) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW (),
        PRIMARY KEY (id_categoria, id_evento)
    );

drop table if exists apuestas cascade;

create table
    apuestas (
        id_apuesta SERIAL PRIMARY KEY,
        id_usuario INT REFERENCES usuarios (id_usuario),
        id_mercado INT REFERENCES mercados (id_mercado),
        monto NUMERIC(10, 2),
        ganancia_esperada NUMERIC(10, 2),
        fecha TIMESTAMP DEFAULT NOW (),
        estado_apuesta VARCHAR(20),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists transacciones cascade;

create table
    transacciones (
        id_transaccion SERIAL PRIMARY KEY,
        id_usuario INT REFERENCES usuarios (id_usuario),
        tipo_transaccion VARCHAR(10),
        monto NUMERIC(10, 2),
        fecha TIMESTAMP DEFAULT NOW (),
        estado VARCHAR(20),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists equipos cascade;

create table
    equipos (
        id_equipo SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        pais VARCHAR(50),
        deporte VARCHAR(50),
        logo_url VARCHAR(255),
        fecha_fundacion DATE,
        activo BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

-- 12. Tabla para relacionar equipos con eventos
drop table if exists evento_equipos cascade;

create table
    evento_equipos (
        id_evento INT REFERENCES eventos (id_evento),
        id_equipo INT REFERENCES equipos (id_equipo),
        es_local BOOLEAN DEFAULT FALSE,
        puntuacion INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW (),
        PRIMARY KEY (id_evento, id_equipo)
    );

drop table if exists patrocinadores cascade;

create table
    patrocinadores (
        id_patrocinador SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        logo_url VARCHAR(255),
        sitio_web VARCHAR(255),
        contacto_email VARCHAR(100),
        activo BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists evento_patrocinadores cascade;

create table
    evento_patrocinadores (
        id_evento INT REFERENCES eventos (id_evento),
        id_patrocinador INT REFERENCES patrocinadores (id_patrocinador),
        tipo_patrocinio VARCHAR(50), -- titulo_evento, presentado_por, patrocinador_oficial
        monto NUMERIC(12, 2),
        posicion_logo VARCHAR(30), -- banners, pantallas, camisetas
        fecha_inicio DATE,
        fecha_fin DATE,
        activo BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW (),
        PRIMARY KEY (id_evento, id_patrocinador)
    );

-- NOSQL
drop table if exists historial_apuestas cascade;

create table
    historial_apuestas (
        id SERIAL PRIMARY KEY,
        id_usuario INT REFERENCES usuarios (id_usuario),
        historial JSONB,
        fecha_actualizacion TIMESTAMP DEFAULT NOW (),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

-- PARTICIONES - Logs con partición por mes
drop table if exists logs_json cascade;

create table
    logs_json (
        id BIGSERIAL,
        tipo_log VARCHAR(50),
        datos JSONB,
        fecha TIMESTAMP DEFAULT NOW (),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    )
PARTITION BY
    RANGE (fecha);

-- Crear particiones para logs (último año + próximos 6 meses)
CREATE TABLE
    logs_json_2024_12 PARTITION OF logs_json FOR
VALUES
FROM
    ('2024-12-01') TO ('2025-01-01');

CREATE TABLE
    logs_json_2025_01 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-01-01') TO ('2025-02-01');

CREATE TABLE
    logs_json_2025_02 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-02-01') TO ('2025-03-01');

CREATE TABLE
    logs_json_2025_03 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-03-01') TO ('2025-04-01');

CREATE TABLE
    logs_json_2025_04 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-04-01') TO ('2025-05-01');

CREATE TABLE
    logs_json_2025_05 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-05-01') TO ('2025-06-01');

CREATE TABLE
    logs_json_2025_06 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-06-01') TO ('2025-07-01');

CREATE TABLE
    logs_json_2025_07 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-07-01') TO ('2025-08-01');

CREATE TABLE
    logs_json_2025_08 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-08-01') TO ('2025-09-01');

CREATE TABLE
    logs_json_2025_09 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-09-01') TO ('2025-10-01');

CREATE TABLE
    logs_json_2025_10 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-10-01') TO ('2025-11-01');

CREATE TABLE
    logs_json_2025_11 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-11-01') TO ('2025-12-01');

CREATE TABLE
    logs_json_2025_12 PARTITION OF logs_json FOR
VALUES
FROM
    ('2025-12-01') TO ('2026-01-01');