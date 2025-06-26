-- Eliminar usuarios si existen
DROP USER IF EXISTS 'juan'@'%';
DROP USER IF EXISTS 'maria'@'%';
DROP USER IF EXISTS 'admin1'@'%';

-- Eliminar roles si existen
DROP ROLE IF EXISTS admin;
DROP ROLE IF EXISTS apostador;
DROP ROLE IF EXISTS cajero;

-- Crear roles
CREATE ROLE admin;
CREATE ROLE apostador;
CREATE ROLE cajero;

-- Permisos para admin (acceso total a la base de datos)
GRANT ALL PRIVILEGES ON apuestas_db.* TO admin;

-- Permisos para apostador
GRANT SELECT ON apuestas_db.eventos TO apostador;
GRANT SELECT ON apuestas_db.mercados TO apostador;
GRANT SELECT ON apuestas_db.equipos TO apostador;
GRANT SELECT ON apuestas_db.categorias TO apostador;
GRANT SELECT ON apuestas_db.eventos_categorias TO apostador;
GRANT SELECT ON apuestas_db.evento_equipos TO apostador;

-- Crear usuarios y asignar roles
CREATE USER 'juan'@'%' IDENTIFIED BY 'apostador123';
GRANT apostador TO 'juan'@'%';
SET DEFAULT ROLE apostador TO 'juan'@'%';

CREATE USER 'maria'@'%' IDENTIFIED BY 'cajero123';
GRANT cajero TO 'maria'@'%';
SET DEFAULT ROLE cajero TO 'maria'@'%';

CREATE USER 'admin1'@'%' IDENTIFIED BY 'admin123';
GRANT admin TO 'admin1'@'%';
SET DEFAULT ROLE admin TO 'admin1'@'%';
