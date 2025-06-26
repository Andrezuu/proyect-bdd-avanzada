---------------TRIGGERS ACTUALIZADOS PARA POSTGRESQL-------------------

-- 1T - Log creación apuesta
CREATE OR REPLACE FUNCTION log_creacion_apuesta()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO logs_json (tipo_log)
  VALUES (
    'CREAR_APUESTA'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_creacion_apuesta
AFTER INSERT ON apuestas
FOR EACH ROW
EXECUTE FUNCTION log_creacion_apuesta();

-- Prueba
--  INSERT INTO apuestas (id_usuario, id_mercado, monto, estado_apuesta)
--  VALUES (1, 1, 150.00, 'activa');
--  SELECT * FROM logs_json
--  WHERE tipo_log = 'CREAR_APUESTA'
--  ORDER BY created_at DESC;

-- 2T - Log cambio saldo
CREATE OR REPLACE FUNCTION log_cambio_saldo()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.saldo IS DISTINCT FROM OLD.saldo THEN
    INSERT INTO logs_json (tipo_log)
    VALUES (
      'CAMBIO_SALDO'
         );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_cambio_saldo
AFTER UPDATE ON usuarios
FOR EACH ROW
WHEN (OLD.saldo IS DISTINCT FROM NEW.saldo)
EXECUTE FUNCTION log_cambio_saldo();

-- Pruebas
--  SELECT saldo FROM usuarios WHERE id_usuario = 1;
--  UPDATE usuarios SET saldo = saldo + 50 WHERE id_usuario = 1;
--  SELECT * FROM logs_json WHERE tipo_log = 'CAMBIO_SALDO' ORDER BY created_at DESC;

-- 3T - Log apuesta cancelada
CREATE OR REPLACE FUNCTION log_apuesta_cancelada()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.estado_apuesta = 'cancelada' AND OLD.estado_apuesta IS DISTINCT FROM 'cancelada' THEN
    INSERT INTO logs_json (tipo_log)
    VALUES (
      'APUESTA_CANCELADA'
      
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_apuesta_cancelada
AFTER UPDATE ON apuestas
FOR EACH ROW
WHEN (OLD.estado_apuesta IS DISTINCT FROM NEW.estado_apuesta)
EXECUTE FUNCTION log_apuesta_cancelada();

-- Pruebas
--  SELECT estado_apuesta FROM apuestas WHERE id_apuesta = 1;
--  UPDATE apuestas SET estado_apuesta = 'cancelada' WHERE id_apuesta = 1;
--  SELECT * FROM logs_json WHERE tipo_log = 'APUESTA_CANCELADA' ORDER BY created_at DESC;

-- 4T - Validar saldo no negativo
CREATE OR REPLACE FUNCTION validar_saldo_no_negativo()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.saldo < 0 THEN
    RAISE EXCEPTION 'No se permite saldo negativo para el usuario %', NEW.id_usuario;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_validar_saldo_no_negativo
BEFORE UPDATE ON usuarios
FOR EACH ROW
EXECUTE FUNCTION validar_saldo_no_negativo();

-- Pruebas
--  UPDATE usuarios SET saldo = saldo + 1000 WHERE id_usuario = 1;
--  UPDATE usuarios SET saldo = saldo - 10 WHERE id_usuario = 1;