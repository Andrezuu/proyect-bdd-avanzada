--METODOS DE PAGO PREFERIDO
CREATE SCHEMA apuestas_olimpiadas;

CREATE TABLE apuestas_olimpiadas.dim_metodos_tipo_pago (
    id_metodos_tipo SERIAL PRIMARY KEY,
    tipo VARCHAR(50),
    proveedor VARCHAR(100),
    moneda VARCHAR(10)
);

CREATE TABLE apuestas_olimpiadas.dim_usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    pais VARCHAR(100),
    correo_electronico VARCHAR(150) UNIQUE,
    edad INT,
    id_metodos_tipo INT,
    FOREIGN KEY (id_metodos_tipo) REFERENCES apuestas_olimpiadas.dim_metodos_tipo_pago(id_metodos_tipo)
);

CREATE TABLE apuestas_olimpiadas.dim_fecha (
    id_fecha SERIAL PRIMARY KEY,
    anio INT,
    mes INT,
    dia INT,
    semana INT
);


CREATE TABLE apuestas_olimpiadas.dim_estado (
    id_estado SERIAL PRIMARY KEY,
    estado_del_pago VARCHAR(50),
    motivo_fallo TEXT,
    descripcion TEXT
);

CREATE TABLE apuestas_olimpiadas.fact_metodos_pago (
    id_pago SERIAL PRIMARY KEY,
    monto_del_pago NUMERIC(10,2),
    estado_del_pago VARCHAR(50),
    fecha_del_pago DATE,
    metodo_de_pago_utilizado VARCHAR(100),
    usuario_realizo_pago VARCHAR(100),
    id_usuario INT,
    id_estado INT,
    id_fecha INT,
    FOREIGN KEY (id_usuario) REFERENCES apuestas_olimpiadas.dim_usuario(id_usuario),
    FOREIGN KEY (id_estado) REFERENCES apuestas_olimpiadas.dim_estado(id_estado),
    FOREIGN KEY (id_fecha) REFERENCES apuestas_olimpiadas.dim_fecha(id_fecha)
);


INSERT INTO apuestas_olimpiadas.dim_metodos_tipo_pago (tipo, proveedor, moneda) VALUES
('Tarjeta de Crédito', 'Visa', 'USD'),
('Tarjeta de Débito', 'Mastercard', 'USD'),
('PayPal', 'PayPal Inc.', 'USD'),
('Transferencia Bancaria', 'Banco Nación', 'BOB'),
('Criptomoneda', 'Binance', 'BTC');

INSERT INTO apuestas_olimpiadas.dim_fecha (anio, mes, dia, semana) VALUES
(2025, 1, 1, 1), (2025, 1, 2, 1), (2025, 1, 3, 1), (2025, 1, 4, 1), (2025, 1, 5, 1),
(2025, 2, 1, 1), (2025, 2, 2, 1), (2025, 2, 3, 1), (2025, 2, 4, 1), (2025, 2, 5, 1),
(2025, 3, 1, 1), (2025, 3, 2, 1), (2025, 3, 3, 1), (2025, 3, 4, 1), (2025, 3, 5, 1);

INSERT INTO apuestas_olimpiadas.dim_usuario (nombre, pais, correo_electronico, edad, id_metodos_tipo) VALUES
('Andrew Silva', 'Honduras', 'robertpennington@yahoo.com', 21, 3),
('John Bell', 'Zimbabwe', 'scottmckenzie@hotmail.com', 34, 3),
('Mark Cervantes', 'Niger', 'charlene85@kline-daugherty.com', 18, 4);

INSERT INTO apuestas_olimpiadas.dim_estado (estado_del_pago, motivo_fallo, descripcion) VALUES
('Exitoso', NULL, 'Pago realizado correctamente'),
('Fallido', 'Fondos insuficientes', 'El usuario no tenía saldo suficiente'),
('Fallido', 'Error de conexión', 'No se pudo comunicar con el proveedor');


INSERT INTO apuestas_olimpiadas.fact_metodos_pago (
    monto_del_pago, estado_del_pago, fecha_del_pago,
    metodo_de_pago_utilizado, usuario_realizo_pago,
    id_usuario, id_estado, id_fecha
) VALUES
(120.50, 'Exitoso', '2025-01-01', 'PayPal', 'Andrew Silva', 1, 1, 1),
(230.00, 'Fallido', '2025-01-02', 'Visa', 'John Bell', 2, 2, 2),
(85.75, 'Exitoso', '2025-02-01', 'Banco Nación', 'Mark Cervantes', 3, 1, 6),
(300.00, 'Fallido', '2025-03-01', 'Mastercard', 'Andrew Silva', 1, 3, 11),
(99.99, 'Exitoso', '2025-02-05', 'PayPal', 'John Bell', 2, 1, 10),
(157.25, 'Fallido', '2025-01-05', 'Binance', 'Mark Cervantes', 3, 2, 5),
(200.00, 'Exitoso', '2025-01-03', 'PayPal', 'Andrew Silva', 1, 1, 3),
(43.75, 'Fallido', '2025-03-02', 'Mastercard', 'John Bell', 2, 3, 12),
(88.88, 'Exitoso', '2025-01-04', 'Visa', 'Mark Cervantes', 3, 1, 4),
(150.00, 'Exitoso', '2025-02-03', 'Banco Nación', 'Andrew Silva', 1, 1, 8);

--metodos de pago que hay
SELECT * FROM apuestas_olimpiadas.dim_metodos_tipo_pago;

--metodo de pago preferido de usuarios
SELECT u.nombre, u.pais, m.tipo AS metodo_pago
FROM apuestas_olimpiadas.dim_usuario u
JOIN apuestas_olimpiadas.dim_metodos_tipo_pago m
  ON u.id_metodos_tipo = m.id_metodos_tipo;

--metodos mas usados
SELECT metodo_de_pago_utilizado, COUNT(*) AS cantidad_usos
FROM apuestas_olimpiadas.fact_metodos_pago
GROUP BY metodo_de_pago_utilizado
ORDER BY cantidad_usos DESC;

--metodos con mayor dinero
SELECT metodo_de_pago_utilizado, SUM(monto_del_pago) AS total_recaudado
FROM apuestas_olimpiadas.fact_metodos_pago
GROUP BY metodo_de_pago_utilizado
ORDER BY total_recaudado DESC;

--pagos por estado 
SELECT estado_del_pago, COUNT(*) AS total
FROM apuestas_olimpiadas.fact_metodos_pago
GROUP BY estado_del_pago;

--usuarios con mas pagos realizados
SELECT usuario_realizo_pago, COUNT(*) AS cantidad_pagos
FROM apuestas_olimpiadas.fact_metodos_pago
GROUP BY usuario_realizo_pago
ORDER BY cantidad_pagos DESC;

--pagos por dia
SELECT df.anio, df.mes, df.dia, COUNT(f.id_pago) AS pagos_del_dia
FROM apuestas_olimpiadas.fact_metodos_pago f
JOIN apuestas_olimpiadas.dim_fecha df ON f.id_fecha = df.id_fecha
GROUP BY df.anio, df.mes, df.dia
ORDER BY df.anio, df.mes, df.dia;