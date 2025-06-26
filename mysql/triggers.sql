DELIMITER //
CREATE TRIGGER tr_desactivar_mercados_evento_cancelado
AFTER UPDATE ON eventos
FOR EACH ROW
BEGIN
    IF NEW.estado = 'cancelado' AND OLD.estado != 'cancelado' THEN
        UPDATE mercados 
        SET estado = 0, updated_at = NOW()
        WHERE id_evento = NEW.id_evento;
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER tr_validar_cuota_mercado_update
BEFORE UPDATE ON mercados
FOR EACH ROW
BEGIN
    IF NEW.cuota <= 0.00 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cuota debe ser mayor a 1.00';
    END IF;
    SET NEW.updated_at = NOW();
END//
DELIMITER ;