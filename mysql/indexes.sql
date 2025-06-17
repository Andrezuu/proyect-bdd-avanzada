CREATE INDEX idx_apuestas_estado ON apuestas (estado_apuesta);
CREATE INDEX idx_apuestas_usuario ON apuestas (id_usuario);
CREATE INDEX idx_apuestas_mercado ON apuestas (id_mercado);

CREATE INDEX idx_mercados_evento ON mercados (id_evento);
CREATE INDEX idx_eventos_id ON eventos (id_evento);
CREATE INDEX idx_usuarios_id ON usuarios (id_usuario);

CREATE INDEX idx_apuestas_usuario_monto ON apuestas (id_usuario, monto);
CREATE INDEX idx_apuestas_id_usuario ON apuestas (id_usuario);

-- Reutilizado para procedimiento sp_cancelar_evento
CREATE INDEX idx_apuestas_mercado_estado ON apuestas (id_mercado, estado_apuesta);
