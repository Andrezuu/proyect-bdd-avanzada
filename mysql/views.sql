CREATE OR REPLACE VIEW vista_detalle_eventos_simple AS
SELECT
    e.id_evento,
    e.nombre_evento,
    e.deporte,
    e.fecha,
    eq.nombre AS equipo,
    CASE ee.es_local WHEN 1 THEN 'Local' ELSE 'Visitante' END AS rol_equipo,
    c.nombre AS categoria,
    p.nombre AS patrocinador,
    m.tipo_mercado,
    m.cuota
FROM eventos e
LEFT JOIN evento_equipos ee ON ee.id_evento = e.id_evento
LEFT JOIN equipos eq ON eq.id_equipo = ee.id_equipo
LEFT JOIN eventos_categorias ec ON ec.id_evento = e.id_evento
LEFT JOIN categorias c ON c.id_categoria = ec.id_categoria
LEFT JOIN evento_patrocinadores ep ON ep.id_evento = e.id_evento
LEFT JOIN patrocinadores p ON p.id_patrocinador = ep.id_patrocinador
LEFT JOIN mercados m ON m.id_evento = e.id_evento;

-- select * from vista_detalle_eventos_simple