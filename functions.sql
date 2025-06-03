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
CREATE OR REPLACE FUNCTION actualizar_resultado_evento(p_evento INT, p_resultado JSONB)
RETURNS VOID AS $$
BEGIN
  UPDATE eventos
  SET resultado = p_resultado
  WHERE id_evento = p_evento;
END;
$$ LANGUAGE plpgsql;

--3
CREATE OR REPLACE FUNCTION actualizar_saldo_usuario(p_usuario INT, p_cantidad NUMERIC)
RETURNS VOID AS $$
BEGIN
  UPDATE usuarios
  SET saldo = saldo + p_cantidad
  WHERE id_usuario = p_usuario;
END;
$$ LANGUAGE plpgsql;

--4
CREATE OR REPLACE FUNCTION calcular_ganancia(p_mercado INT, p_monto NUMERIC)
RETURNS NUMERIC AS $$
DECLARE
  cuota NUMERIC;
BEGIN
  SELECT cuota INTO cuota
  FROM mercados
  WHERE id_mercado = p_mercado;

  RETURN p_monto * cuota;
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

--prueba

SELECT * FROM apuestas WHERE id_usuario = 1;


SELECT actualizar_resultado_evento(3, '{"Ganador": "Argentina"}');

SELECT resultado FROM eventos WHERE id_evento = 1;
---

SELECT saldo FROM usuarios WHERE id_usuario = 1;

SELECT actualizar_saldo_usuario(1, 500.00);

SELECT saldo FROM usuarios WHERE id_usuario = 1;
-----








