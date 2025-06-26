CREATE INDEX idx_eventos_fecha ON eventos(fecha);  

-- Índices para JOINs directos
CREATE INDEX idx_evento_equipos_id_evento ON evento_equipos(id_evento);
CREATE INDEX idx_evento_equipos_id_equipo ON evento_equipos(id_equipo);

CREATE INDEX idx_eventos_categorias_id_evento ON eventos_categorias(id_evento);
CREATE INDEX idx_eventos_categorias_id_categoria ON eventos_categorias(id_categoria);

CREATE INDEX idx_evento_patrocinadores_id_evento ON evento_patrocinadores(id_evento);
CREATE INDEX idx_evento_patrocinadores_id_patrocinador ON evento_patrocinadores(id_patrocinador);

CREATE INDEX idx_mercados_id_evento ON mercados(id_evento);
