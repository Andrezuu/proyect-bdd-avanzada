DROP PROCEDURE IF EXISTS sp_get_eventos_activos;
DELIMITER //

CREATE PROCEDURE sp_get_eventos_activos()
BEGIN
  SELECT 
    e.id_evento,
    e.nombre_evento,
    e.deporte,
    e.fecha
  FROM eventos e
  WHERE e.fecha > NOW() AND e.estado != 'cancelado';
END;
//

DELIMITER ;

-- call sp_get_eventos_activos();
DROP PROCEDURE IF EXISTS sp_get_mercados_por_evento;
DELIMITER //

CREATE PROCEDURE sp_get_mercados_por_evento(IN p_id_evento INT)
BEGIN
  SELECT 
    m.id_mercado,
    m.tipo_mercado,
    m.cuota
  FROM mercados m
  WHERE m.id_evento = p_id_evento AND m.estado = 1;
END
//

DELIMITER ;
