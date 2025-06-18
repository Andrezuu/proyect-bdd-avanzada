-- MySQL version of functions.sql
-- Note: MySQL doesn't have pgcrypto, we'll use SHA2 for password hashing

DELIMITER //

-- 1. Function to authenticate user
CREATE FUNCTION autenticar_usuario(
  p_email TEXT,
  p_contrasena TEXT
)
RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
  DECLARE v_password_hash TEXT;
  DECLARE v_count INT DEFAULT 0;
  
  SELECT password INTO v_password_hash
  FROM usuarios
  WHERE email = p_email;
  
  -- Check if user exists
  SELECT COUNT(*) INTO v_count
  FROM usuarios 
  WHERE email = p_email;
  
  IF v_count = 0 THEN
    RETURN FALSE;
  END IF;

  -- Simple password comparison (in production, use proper hashing)
  IF SHA2(p_contrasena, 256) = v_password_hash THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END//

-- 2. Function to get user balance
CREATE FUNCTION get_saldo_usuario(p_id_usuario INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
DETERMINISTIC
BEGIN
  DECLARE v_saldo DECIMAL(12,2);
  
  SELECT saldo INTO v_saldo
  FROM usuarios
  WHERE id_usuario = p_id_usuario;

  RETURN IFNULL(v_saldo, 0);
END//

DELIMITER ;

-- 3. Procedure to get active events (MySQL doesn't support table-returning functions easily)
DELIMITER //
CREATE PROCEDURE get_eventos_activos()
READS SQL DATA
BEGIN
  SELECT id_evento, nombre_evento, deporte, fecha
  FROM eventos
  WHERE fecha > NOW() AND estado != 'cancelado';
END//
DELIMITER ;

-- 4. Procedure to get markets by event
DELIMITER //
CREATE PROCEDURE get_mercados_por_evento(IN p_id_evento INT)
READS SQL DATA
BEGIN
  SELECT id_mercado, tipo_mercado, cuota
  FROM mercados
  WHERE id_evento = p_id_evento AND estado = 1;
END//
DELIMITER ;

-- 5. Procedure to get bets by user
DELIMITER //
CREATE PROCEDURE get_apuestas_por_usuario(IN p_usuario INT)
READS SQL DATA
BEGIN
  SELECT a.id_apuesta, e.nombre_evento as evento, a.monto, a.ganancia_esperada
  FROM apuestas a
  JOIN mercados m ON a.id_mercado = m.id_mercado
  JOIN eventos e ON m.id_evento = e.id_evento
  WHERE a.id_usuario = p_usuario;
END//
DELIMITER ;

-- 6. Procedure to get event comments
DELIMITER //
CREATE PROCEDURE get_comentarios_evento(IN p_id_evento INT)
READS SQL DATA
BEGIN
  SELECT id_usuario, comentario, created_at as fecha
  FROM comentarios_eventos
  WHERE id_evento = p_id_evento;
END//
DELIMITER ;

-- Additional helper functions

-- Function to update user balance
DELIMITER //
CREATE PROCEDURE actualizar_saldo_usuario(
  IN p_id_usuario INT, 
  IN p_nuevo_saldo DECIMAL(12,2)
)
MODIFIES SQL DATA
BEGIN
  UPDATE usuarios 
  SET saldo = p_nuevo_saldo, updated_at = CURRENT_TIMESTAMP
  WHERE id_usuario = p_id_usuario;
END//
DELIMITER ;

-- Function to update event result
DELIMITER //
CREATE PROCEDURE actualizar_resultado_evento(
  IN p_id_evento INT, 
  IN p_resultado JSON
)
MODIFIES SQL DATA
BEGIN
  UPDATE eventos 
  SET resultado = p_resultado, updated_at = CURRENT_TIMESTAMP
  WHERE id_evento = p_id_evento;
END//
DELIMITER ;