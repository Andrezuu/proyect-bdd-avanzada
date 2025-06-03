---------------TRIGERSSSS-------------------
---
CREATE OR REPLACE FUNCTION log_creacion_apuesta()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO logs_json (tipo_log, datos)
  VALUES (
    'CREAR_APUESTA',
    jsonb_build_object(
      'id_apuesta', NEW.id_apuesta,
      'id_usuario', NEW.id_usuario,
      'id_mercado', NEW.id_mercado,
      'monto', NEW.monto,
      'fecha', NEW.fecha
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_creacion_apuesta
AFTER INSERT ON apuestas
FOR EACH ROW
EXECUTE FUNCTION log_creacion_apuesta();

INSERT INTO apuestas (id_usuario, id_mercado, monto, fecha, estado_apuesta)
VALUES (1, 1, 150.00, NOW(), 'activa');

SELECT * FROM logs_json
WHERE tipo_log = 'CREAR_APUESTA'
ORDER BY fecha DESC;

----2T
CREATE OR REPLACE FUNCTION log_cambio_saldo()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.saldo IS DISTINCT FROM OLD.saldo THEN
    INSERT INTO logs_json (tipo_log, datos)
    VALUES (
      'CAMBIO_SALDO',
      jsonb_build_object(
        'id_usuario', NEW.id_usuario,
        'saldo_anterior', OLD.saldo,
        'saldo_nuevo', NEW.saldo,
        'fecha_modificacion', NOW()
      )
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

SELECT saldo FROM usuarios WHERE id_usuario = 1;

UPDATE usuarios SET saldo = saldo + 50 WHERE id_usuario = 1;

SELECT * FROM logs_json
WHERE tipo_log = 'CAMBIO_SALDO'
ORDER BY fecha DESC;
-----
------3T
CREATE OR REPLACE FUNCTION log_apuesta_cancelada()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.estado_apuesta = 'cancelada' AND OLD.estado_apuesta IS DISTINCT FROM 'cancelada' THEN
    INSERT INTO logs_json (tipo_log, datos)
    VALUES (
      'APUESTA_CANCELADA',
      jsonb_build_object(
        'id_apuesta', NEW.id_apuesta,
        'usuario', NEW.id_usuario,
        'monto', NEW.monto,
        'fecha_cancelacion', NOW()
      )
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

SELECT estado_apuesta FROM apuestas WHERE id_apuesta = 1;

UPDATE apuestas SET estado_apuesta = 'anulada' WHERE id_apuesta = 1;

SELECT * FROM logs_json
WHERE tipo_log = 'APUESTA_CANCELADA'
ORDER BY fecha DESC; ----------------PARA REVISAR CON ANDRESSSS

-----
---4T
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

UPDATE usuarios SET saldo = saldo - 10 WHERE id_usuario = 1;

UPDATE usuarios SET saldo = -100 WHERE id_usuario = 1;

------
---5T
CREATE OR REPLACE FUNCTION log_resultado_evento()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.resultado IS DISTINCT FROM OLD.resultado THEN
    INSERT INTO logs_json (tipo_log, datos)
    VALUES (
      'RESULTADO_EVENTO_ACTUALIZADO',
      jsonb_build_object(
        'id_evento', NEW.id_evento,
        'resultado_anterior', OLD.resultado,
        'resultado_nuevo', NEW.resultado,
        'fecha', NOW()
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_resultado_evento
AFTER UPDATE ON eventos
FOR EACH ROW
WHEN (OLD.resultado IS DISTINCT FROM NEW.resultado)
EXECUTE FUNCTION log_resultado_evento();

SELECT resultado FROM eventos WHERE id_evento = 3;

UPDATE eventos
SET resultado = to_jsonb('ARGENTINA_CAMPEÓN'::text)
WHERE id_evento = 1;

SELECT * FROM logs_json
WHERE tipo_log = 'RESULTADO_EVENTO_ACTUALIZADO'
ORDER BY fecha DESC;

----
--6T
CREATE OR REPLACE FUNCTION calcular_ganancia_esperada()
RETURNS TRIGGER AS $$
DECLARE
  cuota_actual NUMERIC;
BEGIN
  SELECT cuota INTO cuota_actual
  FROM mercados
  WHERE id_mercado = NEW.id_mercado;

  NEW.ganancia_esperada := NEW.monto * cuota_actual;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_calcular_ganancia_esperada
BEFORE INSERT ON apuestas
FOR EACH ROW
EXECUTE FUNCTION calcular_ganancia_esperada();

INSERT INTO apuestas (id_usuario, id_mercado, monto, fecha, estado_apuesta)
VALUES (1, 1, 250, NOW(), 'activa');

SELECT id_apuesta, monto, ganancia_esperada
FROM apuestas
WHERE id_usuario = 1
ORDER BY id_apuesta DESC
LIMIT 1;

