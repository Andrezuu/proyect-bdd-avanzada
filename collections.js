
    db.createCollection("eventos")
    db.createCollection("metodos_pago_detalles")
    db.createCollection("historial_apuestas")
    db.createCollection("log_json_datos")
    db.createCollection("usuarios") // id
    //
    db.createCollection("preferencias")// embebida en user
    db.createCollection("notificaciones")//referencial user
    db.createCollection("reportes")//referencial user
    db.createCollection("mensajes_soporte")//referencial user
    db.createCollection("actividades_usuario")//referecial user
    db.createCollection("recompensas_diarias")//referencialr user