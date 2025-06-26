-- PROCEDIMIENTOS ALMACENADOS PARA MYSQL

-- 1. Procedimiento para crear evento
DELIMITER //
CREATE PROCEDURE sp_crear_evento(
    IN p_nombre_evento VARCHAR(100),
    IN p_fecha TIMESTAMP,
    IN p_deporte VARCHAR(50)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Validar que la fecha sea futura
    IF p_fecha <= NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha del evento debe ser futura';
    END IF;
    
    INSERT INTO eventos (nombre_evento, fecha, deporte, estado)
    VALUES (p_nombre_evento, p_fecha, p_deporte, 'programado');
    
    COMMIT;
END//
DELIMITER ;

-- 2. Procedimiento para crear mercado
DELIMITER //
CREATE PROCEDURE sp_crear_mercado(
    IN p_id_evento INT,
    IN p_tipo_mercado VARCHAR(50),
    IN p_cuota DECIMAL(5,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Validar que el evento existe y está activo
    IF NOT EXISTS (SELECT 1 FROM eventos WHERE id_evento = p_id_evento AND estado IN ('programado', 'activo')) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El evento no existe o no está disponible para mercados';
    END IF;
    
    -- Validar cuota
    IF p_cuota <= 1.00 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cuota debe ser mayor a 1.00';
    END IF;
    
    INSERT INTO mercados (id_evento, tipo_mercado, cuota, estado)
    VALUES (p_id_evento, p_tipo_mercado, p_cuota, 1);
    
    COMMIT;
END//
DELIMITER ;

-- 3. Procedimiento para actualizar cuota
DELIMITER //
CREATE PROCEDURE sp_actualizar_cuota(
    IN p_id_mercado INT,
    IN p_nueva_cuota DECIMAL(5,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Validar que el mercado existe y está activo
    IF NOT EXISTS (SELECT 1 FROM mercados WHERE id_mercado = p_id_mercado AND estado = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El mercado no existe o no está activo';
    END IF;
    
    -- Validar nueva cuota
    IF p_nueva_cuota <= 1.00 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cuota debe ser mayor a 1.00';
    END IF;
    
    UPDATE mercados 
    SET cuota = p_nueva_cuota, updated_at = NOW()
    WHERE id_mercado = p_id_mercado;
    
    COMMIT;
END//
DELIMITER ;

-- 4. Procedimiento para cancelar evento
DELIMITER //
CREATE PROCEDURE sp_cancelar_evento(
    IN p_id_evento INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Verificar que el evento existe
    IF NOT EXISTS (SELECT 1 FROM eventos WHERE id_evento = p_id_evento) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El evento no existe';
    END IF;
    
    -- Actualizar estado del evento
    UPDATE eventos
    SET estado = 'cancelado', updated_at = NOW()
    WHERE id_evento = p_id_evento;
    
    -- Desactivar todos los mercados del evento
    UPDATE mercados
    SET estado = 0, updated_at = NOW()
    WHERE id_evento = p_id_evento;
    
    COMMIT;
END//
DELIMITER ;

-- 5. Procedimiento para finalizar evento con resultado
DELIMITER //
CREATE PROCEDURE sp_finalizar_evento(
    IN p_id_evento INT,
    IN p_resultado JSON
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Verificar que el evento existe y no está finalizado
    IF NOT EXISTS (SELECT 1 FROM eventos WHERE id_evento = p_id_evento AND estado != 'finalizado') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El evento no existe o ya está finalizado';
    END IF;
    
    -- Actualizar evento con resultado
    UPDATE eventos
    SET estado = 'finalizado', 
        resultado = p_resultado,
        updated_at = NOW()
    WHERE id_evento = p_id_evento;
    
    -- Desactivar mercados
    UPDATE mercados
    SET estado = 0, updated_at = NOW()
    WHERE id_evento = p_id_evento;
    
    COMMIT;
END//
DELIMITER ;

-- 6. Procedimiento para agregar equipo a evento
DELIMITER //
CREATE PROCEDURE sp_agregar_equipo_evento(
    IN p_id_evento INT,
    IN p_id_equipo INT,
    IN p_es_local TINYINT(1)
)
BEGIN
    DECLARE v_evento_deporte VARCHAR(50);
    DECLARE v_equipo_deporte VARCHAR(50);
    DECLARE v_equipo_count INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Verificar que el evento existe
    IF NOT EXISTS (SELECT 1 FROM eventos WHERE id_evento = p_id_evento) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El evento no existe';
    END IF;
    
    -- Verificar que el equipo existe
    IF NOT EXISTS (SELECT 1 FROM equipos WHERE id_equipo = p_id_equipo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El equipo no existe';
    END IF;
    
    -- Verificar que no hay más de 2 equipos en el evento
    SELECT COUNT(*) INTO v_equipo_count
    FROM evento_equipos
    WHERE id_evento = p_id_evento;
    
    IF v_equipo_count >= 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un evento no puede tener más de 2 equipos';
    END IF;
    
    -- Verificar que los deportes coinciden
    SELECT deporte INTO v_evento_deporte FROM eventos WHERE id_evento = p_id_evento;
    SELECT deporte INTO v_equipo_deporte FROM equipos WHERE id_equipo = p_id_equipo;
    
    IF v_evento_deporte != v_equipo_deporte THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El deporte del equipo debe coincidir con el del evento';
    END IF;
    
    -- Insertar relación
    INSERT INTO evento_equipos (id_evento, id_equipo, es_local)
    VALUES (p_id_evento, p_id_equipo, p_es_local);
    
    COMMIT;
END//
DELIMITER ;