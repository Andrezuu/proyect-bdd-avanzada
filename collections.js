
    db.createCollection("eventos")
    db.createCollection("metodos_pago_detalles")
    db.createCollection("historial_apuestas")
    db.createCollection("log_json_datos")
    db.createCollection("usuarios") // id
    //
    db.createCollection("preferencias")// embebida
    db.createCollection("notificaciones")//referencial
    db.createCollection("reportes")//referencial
    db.createCollection("mensajes_soporte")//referencial
    db.createCollection("actividades_usuario")//referecial
    db.createCollection("recompensas_diarias")//referencial