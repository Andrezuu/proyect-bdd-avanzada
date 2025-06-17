-- MySQL version of triggers.sql

-- 1. Trigger to log bet creation
DELIMITER //
CREATE TRIGGER tr_log_creacion_apuesta
AFTER INSERT ON apuestas
FOR EACH ROW
BEGIN
  INSERT INTO logs_json (tipo_log, datos)
  VALUES (
    'CREAR_APUESTA',
    JSON_OBJECT(
      'id_apuesta', NEW.id_apuesta,
      'id_usuario', NEW.id_usuario,
      'id_mercado', NEW.id_mercado,
      'monto', NEW.monto,
      'created_at', NEW.created_at
    )
  );
END//
DELIMITER ;

-- 2. Trigger to log balance changes
DELIMITER //
CREATE TRIGGER tr_log_cambio_saldo
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN
  IF NEW.saldo != OLD.saldo THEN
    INSERT INTO logs_json (tipo_log, datos)
    VALUES (
      'CAMBIO_SALDO',
      JSON_OBJECT(
        'id_usuario', NEW.id_usuario,
        'saldo_anterior', OLD.saldo,
        'saldo_nuevo', NEW.saldo,
        'fecha_modificacion', NOW()
      )
    );
  END IF;
END//
DELIMITER ;

-- 3. Trigger to log cancelled bets
DELIMITER //
CREATE TRIGGER tr_log_apuesta_cancelada
AFTER UPDATE ON apuestas
FOR EACH ROW
BEGIN
  IF NEW.estado_apuesta = 'cancelada' AND OLD.estado_apuesta != 'cancelada' THEN
    INSERT INTO logs_json (tipo_log, datos)
    VALUES (
      'APUESTA_CANCELADA',
      JSON_OBJECT(
        'id_apuesta', NEW.id_apuesta,
        'usuario', NEW.id_usuario,
        'monto', NEW.monto,
        'fecha_cancelacion', NOW()
      )
    );
  END IF;
END//
DELIMITER ;

-- 4. Trigger to validate non-negative balance
DELIMITER //
CREATE TRIGGER tr_validar_saldo_no_negativo
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
  IF NEW.saldo < 0 THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'No se permite saldo negativo';
  END IF;
END//
DELIMITER ;

-- 5. Trigger to log event result updates
DELIMITER //
CREATE TRIGGER tr_log_resultado_evento
AFTER UPDATE ON eventos
FOR EACH ROW
BEGIN
  IF JSON_EXTRACT(NEW.resultado, '$') != JSON_EXTRACT(OLD.resultado, '$') OR 
     (NEW.resultado IS NOT NULL AND OLD.resultado IS NULL) OR
     (NEW.resultado IS NULL AND OLD.resultado IS NOT NULL) THEN
    INSERT INTO logs_json (tipo_log, datos)
    VALUES (
      'RESULTADO_EVENTO_ACTUALIZADO',
      JSON_OBJECT(
        'id_evento', NEW.id_evento,
        'resultado_anterior', OLD.resultado,
        'resultado_nuevo', NEW.resultado,
        'fecha', NOW()
      )
    );
  END IF;
END//
DELIMITER ;

-- 6. Trigger to calculate expected winnings
DELIMITER //
CREATE TRIGGER tr_calcular_ganancia_esperada
BEFORE INSERT ON apuestas
FOR EACH ROW
BEGIN
  DECLARE cuota_actual DECIMAL(5,2);
  
  SELECT cuota INTO cuota_actual
  FROM mercados
  WHERE id_mercado = NEW.id_mercado;

  SET NEW.ganancia_esperada = NEW.monto * cuota_actual;
END//
DELIMITER ;