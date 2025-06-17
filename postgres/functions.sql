CREATE EXTENSION IF NOT EXISTS pgcrypto; 

--FUNCIONES
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

--2
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

--3
CREATE OR REPLACE FUNCTION get_eventos_activos()
RETURNS TABLE(
  id_evento INT,
  nombre_evento TEXT,
  deporte TEXT,
  fecha TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT id_evento, nombre_evento, deporte, fecha
  FROM eventos
  WHERE fecha > NOW() AND estado != 'cancelado';
END;
$$ LANGUAGE plpgsql;

--4
CREATE OR REPLACE FUNCTION get_mercados_por_evento(p_id_evento INT)
RETURNS TABLE(
  id_mercado INT,
  tipo_mercado TEXT,
  cuota NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT id_mercado, tipo_mercado, cuota
  FROM mercados
  WHERE id_evento = p_id_evento AND estado = TRUE;
END;
$$ LANGUAGE plpgsql;


--5
CREATE OR REPLACE FUNCTION get_apuestas_por_usuario(p_usuario INT)
RETURNS TABLE(
  id_apuesta INT,
  evento TEXT,
  monto NUMERIC,
  ganancia_esperada NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT a.id_apuesta, e.nombre_evento, a.monto, a.ganancia_esperada
  FROM apuestas a
  JOIN mercados m ON a.id_mercado = m.id_mercado
  JOIN eventos e ON m.id_evento = e.id_evento
  WHERE a.id_usuario = p_usuario;
END;
$$ LANGUAGE plpgsql;

--6
CREATE OR REPLACE FUNCTION get_comentarios_evento(p_id_evento INT)
RETURNS TABLE(
  id_usuario INT,
  comentario TEXT,
  fecha TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT id_usuario, comentario, created_at
  FROM comentarios_eventos
  WHERE id_evento = p_id_evento;
END;
$$ LANGUAGE plpgsql;


--prueba

SELECT * FROM apuestas WHERE id_usuario = 1;


-- SELECT actualizar_resultado_evento(3, '{"Ganador": "Argentina"}');

SELECT resultado FROM eventos WHERE id_evento = 1;
---

SELECT saldo FROM usuarios WHERE id_usuario = 1;

-- SELECT actualizar_saldo_usuario(1, 500.00);

SELECT saldo FROM usuarios WHERE id_usuario = 1;
-----
