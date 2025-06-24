
    db.createCollection("eventos_resultados")
    db.createCollection("metodos_pago_detalles") //a
    db.createCollection("historial_apuestas")
    db.createCollection("log_json_datos")
    db.createCollection("usuarios") // id a
    //
    db.createCollection("preferencias")// embebida en user a
    db.createCollection("notificaciones")//referencial user a
    db.createCollection("reportes")//referencial user a
    db.createCollection("mensajes_soporte")//referencial user a
    db.createCollection("actividades_usuario")//referecial user a
    db.createCollection("recompensas_diarias")//referencialr user a


    // comentarios