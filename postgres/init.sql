drop table if exists usuarios cascade;

create table
    usuarios (
        id_usuario SERIAL PRIMARY KEY,
        nombre VARCHAR(100),
        email VARCHAR(100) UNIQUE,
        password TEXT,
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

create table
    transacciones (
        id_transaccion SERIAL PRIMARY KEY,
        id_usuario INT REFERENCES usuarios (id_usuario),
        tipo_transaccion VARCHAR(10),
        monto NUMERIC(10, 2),
        estado VARCHAR(20),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

drop table if exists metodos_pago cascade;

create table
    metodos_pago (
        id_metodo SERIAL PRIMARY KEY,
        id_usuario INT REFERENCES usuarios (id_usuario),
        id_transaccion INT REFERENCES transacciones (id_transaccion),
        tipo TEXT,
        activo BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    );

-- PARTICIONES - Logs con partición por mes
drop table if exists logs_json cascade;

create table
    logs_json (
        id BIGSERIAL,
        tipo_log VARCHAR(50),
        created_at TIMESTAMP DEFAULT NOW (),
        updated_at TIMESTAMP DEFAULT NOW ()
    )
PARTITION BY
    RANGE (created_at);

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