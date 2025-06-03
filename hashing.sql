
UPDATE usuarios
SET nombre = 'Usuario';

UPDATE usuarios
SET email = 'ofuscado_' || id_usuario || '@correos.com';

UPDATE metodos_pago mp SET tipo = 'tipo de pago ofuscado';
UPDATE metodos_pago mp set detalles = '{"clave": "valor"}';


select *
from metodos_pago mp 

select *
from apuestas a 

