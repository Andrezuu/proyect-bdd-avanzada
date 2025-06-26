----
------------------------VISTASSSSS--------
--1V
CREATE OR REPLACE VIEW vista_resumen_usuario AS
SELECT 
    u.id_usuario,
    u.nombre AS nombre_usuario,
    u.email,
    u.saldo,
    COUNT(a.id_apuesta) AS total_apuestas,
    COALESCE(SUM(a.monto), 0) AS total_apostado,
    COALESCE(SUM(a.ganancia_esperada), 0) AS ganancia_total_esperada,
    MAX(a.fecha) AS ultima_apuesta
FROM usuarios u
LEFT JOIN apuestas a ON a.id_usuario = u.id_usuario
GROUP BY u.id_usuario, u.nombre, u.email, u.saldo;

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

-- SELECT * FROM vista_top_usuarios_apuestas;
