
-- 1. Vista: vista_apuestas_activas
EXPLAIN ANALYZE
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

-- 2. Vista: vista_top_usuarios_apuestas
EXPLAIN ANALYZE
SELECT 
  u.id_usuario,
  u.nombre AS nombre_usuario,
  COUNT(a.id_apuesta) AS total_apuestas,
  SUM(a.monto) AS monto_total_apostado
FROM usuarios u
JOIN apuestas a ON u.id_usuario = a.id_usuario
GROUP BY u.id_usuario, u.nombre
ORDER BY total_apuestas DESC;

-- 3. Función: get_apuestas_por_usuario
EXPLAIN ANALYZE
SELECT a.id_apuesta, e.nombre_evento, a.monto, a.ganancia_esperada
FROM apuestas a
JOIN mercados m ON a.id_mercado = m.id_mercado
JOIN eventos e ON m.id_evento = e.id_evento
WHERE a.id_usuario = 1;

-- 4. Procedimiento: sp_cancelar_evento 
EXPLAIN ANALYZE
UPDATE apuestas
SET estado_apuesta = 'cancelada'
WHERE id_mercado IN (
  SELECT id_mercado FROM mercados WHERE id_evento = 400
);

 