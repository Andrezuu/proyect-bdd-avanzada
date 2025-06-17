// ✅ 1. usuarios 📦 (Embebido parcial)
db.createCollection("usuarios")
//🔹 Embebido: Dirección y método de pago se acceden con el usuario y no se reutilizan.

//✅ 2. roles 🔗 (Referencial)
db.createCollection("roles")
//🔹 Referencial: Muchos usuarios pueden compartir un mismo rol.

//✅ 3. eventos 📦 (Embebido parcial)
db.createCollection("eventos")
//🔹 Embebido: Ubicación es específica del evento.

//✅ 4. equipos 🔗 (Referencial)
db.createCollection("equipos")
//🔹 Referencial: Se relaciona con múltiples eventos.

//✅ 5. jugadores 🔗 (Referencial)
db.createCollection("jugadores")
//🔹 Referencial: Muchos jugadores participan en varios eventos.

//✅ 6. apuestas 📦 (Embebido parcial)
db.createCollection("apuestas")
//🔹 Embebido: Detalles no se usan fuera de la apuesta.

//✅ 7. transacciones 🔗 (Referencial)
db.createCollection("transacciones")
//🔹 Referencial: Historial grande, no se embebe en usuarios.

//✅ 8. comentarios_evento 🔗 (Referencial)
db.createCollection("comentarios_evento")
//🔹 Referencial: Muchos comentarios por evento, evita crecer el documento evento.

//✅ 9. categorias_evento 🔗
db.createCollection("categorias_evento")
//🔹 Referencial: Categorías compartidas por muchos eventos.

//✅ 10. mercados 📦
db.createCollection("mercados")
//🔹 Embebido: Opciones están muy ligadas a cada mercado.

//✅ 11. historial_apuestas 🔗
db.createCollection("historial_apuestas")
//🔹 Referencial: Aumenta frecuentemente, por lo tanto separado.

//✅ 12. notificaciones 📦
db.createCollection("notificaciones")
//🔹 Embebido: Específico para cada usuario y se elimina al leer.

//✅ 13. favoritos_usuario 🔗
db.createCollection("favoritos_usuario")
//🔹 Referencial: Puede crecer demasiado, especialmente si hay muchos favoritos.

//✅ 14. estadisticas_evento 📦
db.createCollection("estadisticas_evento")
//🔹 Embebido: Cambia poco, específico de un evento.

//✅ 15. logs_sistema 🔗
db.createCollection("logs_sistema")
//🔹 Referencial: Se registran en gran volumen, no deben ir dentro de otra colección.

