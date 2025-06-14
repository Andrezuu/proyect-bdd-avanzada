CREATE EXTENSION IF NOT EXISTS pgcrypto; 

---------------EXCEPTION + ROLLBACKKKKK
--- 1SP EX + ROLL
CREATE OR REPLACE PROCEDURE sp_insertar_usuario(
  p_nombre TEXT,
  p_email TEXT,
  p_contrasena TEXT,
  p_saldo NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    INSERT INTO usuarios (nombre, email, password, saldo,  estado)
    VALUES (p_nombre, p_email, crypt(p_contrasena, gen_salt('bf')), p_saldo, true);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al insertar usuario: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

CALL sp_insertar_usuario('Carlos Pérez', 'carlos@example.com', 'segura123', 100.00);

-----2SP EX + ROLL
CREATE OR REPLACE PROCEDURE sp_eliminar_apuesta(p_id_apuesta INT)
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    DELETE FROM apuestas
    WHERE id_apuesta = p_id_apuesta AND estado_apuesta = 'activa';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'No se encontró apuesta activa con ID %', p_id_apuesta;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al eliminar apuesta: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

CALL sp_eliminar_apuesta(3);

----- 3SP EX + ROLL
CREATE OR REPLACE PROCEDURE sp_registrar_evento(
  p_nombre varchar(45),
  p_fecha TIMESTAMP,
  p_deporte varchar(45)
)
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    INSERT INTO eventos (nombre_evento, fecha, deporte, estado)
    VALUES (p_nombre, p_fecha, p_deporte, 'programado');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al registrar evento: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

CALL sp_registrar_evento('Final Copa Libertadores', '2025-11-15 20:00:00', 'Fútbol');

--ESTE NO PUEDO HACER QUE SALGA EL ERROR 
------4SP EX + ROLL

CREATE OR REPLACE PROCEDURE sp_cancelar_evento(p_id_evento INT)
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    -- Actualizar estado del evento
    UPDATE eventos
    SET resultado = '{"estado": "CANCELADO"}'
    WHERE id_evento = p_id_evento;

    -- Cancelar apuestas asociadas
    UPDATE apuestas
    SET estado_apuesta = 'cancelada'
    WHERE id_mercado IN (
      SELECT id_mercado FROM mercados WHERE id_evento = p_id_evento
    );

  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al cancelar evento: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;
CALL sp_cancelar_evento(400);
CALL sp_cancelar_evento(7);
CALL sp_cancelar_evento(99999);


-----5SP EX + ROLL

CREATE OR REPLACE PROCEDURE sp_retirar_saldo(p_id_usuario INT, p_monto NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    IF p_monto <= 0 THEN
      RAISE EXCEPTION 'El monto debe ser positivo.';
    END IF;

    UPDATE usuarios
    SET saldo = saldo - p_monto
    WHERE id_usuario = p_id_usuario AND saldo >= p_monto;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Fondos insuficientes o usuario no encontrado.';
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al retirar saldo: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;


CALL sp_retirar_saldo(1, 50.00);
CALL sp_retirar_saldo(1, -10.00);
CALL sp_retirar_saldo(99999, 100.00);
CALL sp_retirar_saldo(1, 1000000.00);

------- 6SP EX + ROLL
CREATE OR REPLACE PROCEDURE sp_registrar_apuesta(
  IN p_id_usuario INT,
  IN p_id_mercado INT,
  IN p_monto NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
  v_saldo_actual NUMERIC;
  v_evento_activo BOOLEAN;
  v_id_evento INT;
BEGIN
  SELECT id_evento INTO v_id_evento
  FROM mercados
  WHERE id_mercado = p_id_mercado;

  SELECT estado = 'activo' INTO v_evento_activo
  FROM eventos
  WHERE id_evento = v_id_evento;

  IF NOT v_evento_activo THEN
    RAISE EXCEPTION 'No se puede apostar: el evento no está activo.';
  END IF;

  SELECT saldo INTO v_saldo_actual
  FROM usuarios
  WHERE id_usuario = p_id_usuario;

  IF v_saldo_actual < p_monto THEN
    RAISE EXCEPTION 'Saldo insuficiente.';
  END IF;

  INSERT INTO apuestas (id_usuario, id_mercado, monto, fecha, estado_apuesta)
  VALUES (p_id_usuario, p_id_mercado, p_monto, NOW(), 'activa');

  UPDATE usuarios
  SET saldo = saldo - p_monto
  WHERE id_usuario = p_id_usuario;

  RAISE NOTICE 'Apuesta registrada con éxito.';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;
END;
$$;
