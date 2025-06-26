-- Crear roles
CREATE ROLE admin;
CREATE ROLE apostador;
CREATE ROLE cajero;

-- Permisos para admin (acceso total al esquema public)
GRANT ALL PRIVILEGES ON SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO admin;

-- Permisos para apostador
GRANT USAGE ON SCHEMA public TO apostador;
GRANT SELECT, INSERT ON apuestas TO apostador;
GRANT SELECT, INSERT ON transacciones TO apostador;
GRANT SELECT, INSERT ON metodos_pago TO apostador;

-- Permisos para cajero
GRANT USAGE ON SCHEMA public TO cajero;
GRANT SELECT, UPDATE ON usuarios TO cajero;
GRANT SELECT, INSERT, UPDATE ON metodos_pago TO cajero;
GRANT SELECT, INSERT, UPDATE ON transacciones TO cajero;

-- Crear usuarios y asignar roles
CREATE USER juan WITH PASSWORD 'apostador123';
GRANT apostador TO juan;

CREATE USER maria WITH PASSWORD 'cajero123';
GRANT cajero TO maria;

CREATE USER admin1 WITH PASSWORD 'admin123';
GRANT admin TO admin1;
