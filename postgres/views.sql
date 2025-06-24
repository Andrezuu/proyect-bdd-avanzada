----
------------------------VISTASSSSS--------
--1V
CREATE OR REPLACE VIEW vista_apuestas_activas AS
SELECT 
  a.id_apuesta,
  u.nombre AS nombre_usuario,
  e.nombre_evento,
  a.monto,
  a.ganancia_esperada,
  a.fecha
FROM apuestas a
JOIN usuarios u ON u.id_usuario = a.id_usuario
JOIN mercados m ON m.id_mercado = a.id_mercado
JOIN eventos e ON e.id_evento = m.id_evento
WHERE a.estado_apuesta = 'activa';

SELECT * FROM vista_apuestas_activas;

----2V
CREATE OR REPLACE VIEW vista_top_usuarios_apuestas AS
SELECT 
  u.id_usuario,
  u.nombre AS nombre_usuario,
  COUNT(a.id_apuesta) AS total_apuestas,
  SUM(a.monto) AS monto_total_apostado
FROM usuarios u
JOIN apuestas a ON u.id_usuario = a.id_usuario
GROUP BY u.id_usuario, u.nombre
ORDER BY total_apuestas DESC;

SELECT * FROM vista_top_usuarios_apuestas;

----3V
CREATE OR REPLACE VIEW vista_eventos_finalizados AS
SELECT 
  id_evento,
  nombre_evento,
  deporte,
  fecha,
FROM eventos

SELECT * FROM vista_eventos_finalizados;