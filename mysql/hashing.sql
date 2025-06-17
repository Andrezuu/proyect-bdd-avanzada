UPDATE usuarios
SET nombre = 'Usuario';

UPDATE usuarios
SET email = 'ofuscado_' || id_usuario || '@correos.com';

UPDATE metodos_pago 
SET tipo = 'tipo de pago ofuscado';

UPDATE metodos_pago 
SET detalles = JSON_OBJECT('clave', 'valor');

SELECT * FROM metodos_pago;
SELECT * FROM apuestas;
