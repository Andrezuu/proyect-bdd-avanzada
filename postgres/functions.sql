CREATE EXTENSION IF NOT EXISTS pgcrypto; 

--FUNCIONES ACTUALIZADAS PARA POSTGRESQL

-- 1F - Autenticar usuario (sin cambios)
CREATE OR REPLACE FUNCTION autenticar_usuario(
  p_email TEXT,
  p_contrasena TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  v_password_hash TEXT;
BEGIN
  SELECT password INTO v_password_hash
  FROM usuarios
  WHERE email = p_email;

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  IF crypt(p_contrasena, v_password_hash) = v_password_hash THEN
    RETURN TRUE; 
  ELSE
    RETURN FALSE; 
  END IF;
END;
$$;

-- 2F - Get saldo usuario (sin cambios)
CREATE OR REPLACE FUNCTION get_saldo_usuario(p_id_usuario INT)
RETURNS NUMERIC AS $$
DECLARE
  v_saldo NUMERIC;
BEGIN
  SELECT saldo INTO v_saldo
  FROM usuarios
  WHERE id_usuario = p_id_usuario;

  RETURN COALESCE(v_saldo, 0);
END;
$$ LANGUAGE plpgsql;

-- 3F - Get apuestas por usuario (actualizada para PostgreSQL)
CREATE OR REPLACE FUNCTION get_apuestas_por_usuario(p_usuario INT)
RETURNS TABLE(
  id_apuesta INT,
  id_mercado INT,
  monto NUMERIC,
  ganancia_esperada NUMERIC,
  estado_apuesta TEXT,
  fecha TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT a.id_apuesta, a.id_mercado, a.monto, a.ganancia_esperada, a.estado_apuesta, a.fecha
  FROM apuestas a
  WHERE a.id_usuario = p_usuario
  ORDER BY a.fecha DESC;
END;
$$ LANGUAGE plpgsql;

-- 4F - Get historial transacciones usuario
CREATE OR REPLACE FUNCTION get_historial_transacciones(p_id_usuario INT)
RETURNS TABLE(
  id_transaccion INT,
  tipo_transaccion VARCHAR,
  monto NUMERIC,
  estado VARCHAR,
  fecha TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT t.id_transaccion, t.tipo_transaccion, t.monto, t.estado, t.created_at
  FROM transacciones t
  WHERE t.id_usuario = p_id_usuario
  ORDER BY t.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 5F - Actualizar saldo usuario
CREATE OR REPLACE FUNCTION actualizar_saldo_usuario(
  p_id_usuario INT,
  p_nuevo_saldo NUMERIC
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE usuarios
  SET saldo = p_nuevo_saldo,
      updated_at = NOW()
  WHERE id_usuario = p_id_usuario;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- 6F - Verificar fondos suficientes
CREATE OR REPLACE FUNCTION verificar_fondos_suficientes(
  p_id_usuario INT,
  p_monto NUMERIC
)
RETURNS BOOLEAN AS $$
DECLARE
  v_saldo_actual NUMERIC;
BEGIN
  SELECT saldo INTO v_saldo_actual
  FROM usuarios
  WHERE id_usuario = p_id_usuario;

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  RETURN v_saldo_actual >= p_monto;
END;
$$ LANGUAGE plpgsql;

-- 7F - Get estadísticas usuario
CREATE OR REPLACE FUNCTION get_estadisticas_usuario(p_id_usuario INT)
RETURNS TABLE(
  total_apuestas BIGINT,
  monto_total_apostado NUMERIC,
  ganancia_esperada_total NUMERIC,
  apuestas_activas BIGINT,
  apuestas_ganadas BIGINT,
  apuestas_perdidas BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_apuestas,
    COALESCE(SUM(a.monto), 0) as monto_total_apostado,
    COALESCE(SUM(a.ganancia_esperada), 0) as ganancia_esperada_total,
    COUNT(*) FILTER (WHERE a.estado_apuesta = 'activa') as apuestas_activas,
    COUNT(*) FILTER (WHERE a.estado_apuesta = 'ganada') as apuestas_ganadas,
    COUNT(*) FILTER (WHERE a.estado_apuesta = 'perdida') as apuestas_perdidas
  FROM apuestas a
  WHERE a.id_usuario = p_id_usuario;
END;
$$ LANGUAGE plpgsql;

-- 8F - Validar usuario activo
CREATE OR REPLACE FUNCTION validar_usuario_activo(p_id_usuario INT)
RETURNS BOOLEAN AS $$
DECLARE
  v_estado BOOLEAN;
BEGIN
  SELECT estado INTO v_estado
  FROM usuarios
  WHERE id_usuario = p_id_usuario;

  RETURN COALESCE(v_estado, FALSE);
END;
$$ LANGUAGE plpgsql;
