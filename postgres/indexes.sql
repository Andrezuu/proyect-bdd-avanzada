CREATE INDEX idx_apuestas_estado ON apuestas(estado_apuesta);
CREATE INDEX idx_apuestas_usuario ON apuestas(id_usuario);
CREATE INDEX idx_apuestas_mercado ON apuestas(id_mercado);

CREATE INDEX idx_apuestas_usuario_monto ON apuestas(id_usuario, monto);
CREATE INDEX idx_apuestas_id_usuario ON apuestas(id_usuario);