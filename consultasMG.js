//🔍 1. Usuarios con más notificaciones
db.notificaciones.aggregate([
  { $group: { _id: "$usuario_id", total: { $sum: 1 } } },
  { $sort: { total: -1 } },
  { $limit: 10 }
])


//📩 2. Últimas notificaciones por tipo
db.notificaciones.aggregate([
  { $sort: { fecha: -1 } },
  { $group: { _id: "$tipo", ultima: { $first: "$mensaje" } } }
])


//📊 3. Conteo de reportes por estado

db.reportes.aggregate([
  { $group: { _id: "$estado", cantidad: { $sum: 1 } } }
])


//📆 4. Actividades por día
db.actividades_usuario.aggregate([
  { $group: { _id: { $dateToString: { format: "%Y-%m-%d", date: "$fecha" } }, total: { $sum: 1 } } },
  { $sort: { "_id": 1 } }
])


//🎮 5. Usuarios más activos
db.actividades_usuario.aggregate([
  { $group: { _id: "$usuario_id", actividades: { $sum: 1 } } },
  { $sort: { actividades: -1 } },
  { $limit: 10 }
])


//🎁 6. Recompensas más comunes
db.recompensas_diarias.aggregate([
  { $group: { _id: "$recompensa", total: { $sum: 1 } } },
  { $sort: { total: -1 } }
])


//✉️ 7. Soportes pendientes
db.mensajes_soporte.aggregate([
  { $match: { estado: "pendiente" } },
  { $count: "total_pendientes" }
])


//🔔 8. Tipos de notificación más comunes
db.notificaciones.aggregate([
  { $group: { _id: "$tipo", cantidad: { $sum: 1 } } },
  { $sort: { cantidad: -1 } }
])


//📌 9. Preferencias más seleccionadas
db.preferencias.aggregate([
  { $project: { preferencias: { $objectToArray: "$preferencias" } } },
  { $unwind: "$preferencias" },
  { $group: { _id: "$preferencias.k", cantidad: { $sum: 1 } } },
  { $sort: { cantidad: -1 } }
])


//🕒 10. Tiempo promedio de respuesta en soporte
db.mensajes_soporte.aggregate([
  { $match: { tiempo_respuesta: { $exists: true } } },
  { $group: { _id: null, promedio: { $avg: "$tiempo_respuesta" } } }
])


//🎯 11. Actividades por tipo
db.actividades_usuario.aggregate([
  { $group: { _id: "$tipo", total: { $sum: 1 } } },
  { $sort: { total: -1 } }
])


//💬 12. Conversaciones de soporte por usuario
db.mensajes_soporte.aggregate([
  { $group: { _id: "$usuario_id", total_mensajes: { $sum: 1 } } },
  { $sort: { total_mensajes: -1 } }
])


//📌 13. Obtener notificaciones junto con datos del usuario
db.notificaciones.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" },
  {
    $project: {
      mensaje: 1,
      tipo: 1,
      fecha: 1,
      "usuario.nombre": 1,
      "usuario.email": 1
    }
  }
])


//🧾 14. Obtener reportes junto con información del usuario que lo reportó
db.reportes.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" },
  {
    $project: {
      descripcion: 1,
      estado: 1,
      fecha: 1,
      "usuario.nombre": 1
    }
  }
])


//🎁 15. Listar recompensas diarias con datos del usuario
db.recompensas_diarias.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" },
  {
    $project: {
      recompensa: 1,
      fecha: 1,
      "usuario.nombre": 1
    }
  }
])
//🧑‍💻 16. Unir actividades del usuario con su información básica
db.actividades_usuario.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" },
  {
    $project: {
      tipo: 1,
      fecha: 1,
      "usuario.nombre": 1,
      "usuario.email": 1
    }
  }
])
//🧠 17. Obtener mensajes de soporte junto con el usuario que los envió
db.mensajes_soporte.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" },
  {
    $project: {
      mensaje: 1,
      estado: 1,
      fecha: 1,
      "usuario.nombre": 1
    }
  }
])
//📌 18. Ver historial de apuestas junto con datos del evento
db.historial_apuestas.aggregate([
  {
    $lookup: {
      from: "eventos",
      localField: "evento_id",
      foreignField: "_id",
      as: "evento"
    }
  },
  { $unwind: "$evento" },
  {
    $project: {
      monto: 1,
      estado: 1,
      "evento.nombre_evento": 1,
      "evento.deporte": 1
    }
  }
])
//💳 19. Ver métodos de pago con detalles del usuario
db.metodos_pago_detalles.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" },
  {
    $project: {
      tipo_pago: 1,
      numero: 1,
      "usuario.nombre": 1
    }
  }
])

//🛠️ 20. Mostrar actividades del usuario junto a sus mensajes de soporte
db.actividades_usuario.aggregate([
  {
    $lookup: {
      from: "mensajes_soporte",
      localField: "usuario_id",
      foreignField: "usuario_id",
      as: "mensajes"
    }
  },
  {
    $project: {
      tipo: 1,
      fecha: 1,
      mensajes: 1
    }
  }
])



