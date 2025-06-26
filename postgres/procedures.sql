CREATE EXTENSION IF NOT EXISTS pgcrypto; 

---------------PROCEDIMIENTOS ACTUALIZADOS PARA POSTGRESQL (EXCEPTION + ROLLBACK)

-- 1SP - Insertar usuario (sin cambios)
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
    INSERT INTO usuarios (nombre, email, password, saldo, estado)
    VALUES (p_nombre, p_email, crypt(p_contrasena, gen_salt('bf')), p_saldo, true);
    
    RAISE NOTICE 'Usuario insertado exitosamente: %', p_email;
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE 'Error: El email % ya existe', p_email;
      ROLLBACK;
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al insertar usuario: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

-- 2SP - Eliminar apuesta (sin cambios)
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

    RAISE NOTICE 'Apuesta % eliminada exitosamente', p_id_apuesta;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al eliminar apuesta: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

-- 3SP - Retirar saldo (sin cambios)
CREATE OR REPLACE PROCEDURE sp_retirar_saldo(p_id_usuario INT, p_monto NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    IF p_monto <= 0 THEN
      RAISE EXCEPTION 'El monto debe ser positivo.';
    END IF;

    UPDATE usuarios
    SET saldo = saldo - p_monto,
        updated_at = NOW()
    WHERE id_usuario = p_id_usuario AND saldo >= p_monto;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Fondos insuficientes o usuario no encontrado.';
    END IF;

    -- Registrar transacción
    INSERT INTO transacciones (id_usuario, tipo_transaccion, monto, estado)
    VALUES (p_id_usuario, 'retiro', p_monto, 'completada');

    RAISE NOTICE 'Retiro exitoso de % para usuario %', p_monto, p_id_usuario;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al retirar saldo: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

-- 4SP - Depositar saldo
CREATE OR REPLACE PROCEDURE sp_depositar_saldo(p_id_usuario INT, p_monto NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    IF p_monto <= 0 THEN
      RAISE EXCEPTION 'El monto debe ser positivo.';
    END IF;

    UPDATE usuarios
    SET saldo = saldo + p_monto,
        updated_at = NOW()
    WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Usuario no encontrado con ID %', p_id_usuario;
    END IF;

    -- Registrar transacción
    INSERT INTO transacciones (id_usuario, tipo_transaccion, monto, estado)
    VALUES (p_id_usuario, 'deposito', p_monto, 'completada');

    RAISE NOTICE 'Depósito exitoso de % para usuario %', p_monto, p_id_usuario;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al depositar saldo: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

-- 5SP - Registrar apuesta (actualizada para PostgreSQL solamente)
CREATE OR REPLACE PROCEDURE sp_registrar_apuesta(
  IN p_id_usuario INT,
  IN p_id_mercado INT,
  IN p_monto NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
  v_saldo_actual NUMERIC;
BEGIN
  BEGIN
    -- Validar usuario activo
    IF NOT validar_usuario_activo(p_id_usuario) THEN
      RAISE EXCEPTION 'Usuario no activo o no encontrado.';
    END IF;

    -- Validar monto positivo
    IF p_monto <= 0 THEN
      RAISE EXCEPTION 'El monto debe ser positivo.';
    END IF;

    -- Verificar fondos suficientes
    IF NOT verificar_fondos_suficientes(p_id_usuario, p_monto) THEN
      RAISE EXCEPTION 'Saldo insuficiente.';
    END IF;

    -- Insertar apuesta
    INSERT INTO apuestas (id_usuario, id_mercado, monto, fecha, estado_apuesta)
    VALUES (p_id_usuario, p_id_mercado, p_monto, NOW(), 'activa');

    -- Descontar del saldo
    UPDATE usuarios
    SET saldo = saldo - p_monto,
        updated_at = NOW()
    WHERE id_usuario = p_id_usuario;

    -- Registrar transacción
    INSERT INTO transacciones (id_usuario, tipo_transaccion, monto, estado)
    VALUES (p_id_usuario, 'apuesta', p_monto, 'completada');

    RAISE NOTICE 'Apuesta registrada exitosamente para usuario %', p_id_usuario;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al registrar apuesta: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

-- 6SP - Actualizar estado apuesta
CREATE OR REPLACE PROCEDURE sp_actualizar_estado_apuesta(
  p_id_apuesta INT,
  p_nuevo_estado TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id_usuario INT;
  v_monto NUMERIC;
  v_ganancia_esperada NUMERIC;
BEGIN
  BEGIN
    -- Obtener datos de la apuesta
    SELECT id_usuario, monto, ganancia_esperada
    INTO v_id_usuario, v_monto, v_ganancia_esperada
    FROM apuestas
    WHERE id_apuesta = p_id_apuesta;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Apuesta no encontrada con ID %', p_id_apuesta;
    END IF;

    -- Actualizar estado
    UPDATE apuestas
    SET estado_apuesta = p_nuevo_estado,
        updated_at = NOW()
    WHERE id_apuesta = p_id_apuesta;

    -- Si la apuesta fue ganada, acreditar ganancia
    IF p_nuevo_estado = 'ganada' THEN
      UPDATE usuarios
      SET saldo = saldo + v_ganancia_esperada,
          updated_at = NOW()
      WHERE id_usuario = v_id_usuario;

      INSERT INTO transacciones (id_usuario, tipo_transaccion, monto, estado)
      VALUES (v_id_usuario, 'ganancia', v_ganancia_esperada, 'completada');
    END IF;

    -- Si la apuesta fue cancelada, devolver monto
    IF p_nuevo_estado = 'cancelada' THEN
      UPDATE usuarios
      SET saldo = saldo + v_monto,
          updated_at = NOW()
      WHERE id_usuario = v_id_usuario;

      INSERT INTO transacciones (id_usuario, tipo_transaccion, monto, estado)
      VALUES (v_id_usuario, 'reembolso', v_monto, 'completada');
    END IF;

    RAISE NOTICE 'Estado de apuesta % actualizado a %', p_id_apuesta, p_nuevo_estado;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al actualizar estado de apuesta: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

-- 7SP - Procesar transacción
CREATE OR REPLACE PROCEDURE sp_procesar_transaccion(
  p_id_usuario INT,
  p_id_metodo_pago INT,
  p_tipo_transaccion TEXT,
  p_monto NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    -- Validar parámetros
    IF p_monto <= 0 THEN
      RAISE EXCEPTION 'El monto debe ser positivo.';
    END IF;

    IF p_tipo_transaccion NOT IN ('deposito', 'retiro') THEN
      RAISE EXCEPTION 'Tipo de transacción inválido: %', p_tipo_transaccion;
    END IF;

    -- Validar usuario
    IF NOT validar_usuario_activo(p_id_usuario) THEN
      RAISE EXCEPTION 'Usuario no activo o no encontrado.';
    END IF;

    -- Para retiros, verificar fondos
    IF p_tipo_transaccion = 'retiro' AND NOT verificar_fondos_suficientes(p_id_usuario, p_monto) THEN
      RAISE EXCEPTION 'Fondos insuficientes para el retiro.';
    END IF;

    -- Insertar transacción
    INSERT INTO transacciones (id_usuario, id_metodo_pago, tipo_transaccion, monto, estado)
    VALUES (p_id_usuario, p_id_metodo_pago, p_tipo_transaccion, p_monto, 'pendiente');

    RAISE NOTICE 'Transacción de % por % procesada para usuario %', p_tipo_transaccion, p_monto, p_id_usuario;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error al procesar transacción: %', SQLERRM;
      ROLLBACK;
  END;
END;
$$;

-- Pruebas
-- CALL sp_insertar_usuario('Test User', 'test@example.com', 'password123', 1000.00);
-- CALL sp_depositar_saldo(1, 500.00);
-- CALL sp_registrar_apuesta(1, 1, 100.00);