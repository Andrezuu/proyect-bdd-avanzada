//🔍 1. Total de apuestas por estado
db.apuestas.aggregate([
  { $group: { _id: "$estado", total: { $sum: 1 } } }
])

//🔍 2. Usuarios con saldo mayor a 1000
db.usuarios.aggregate([
  { $match: { saldo: { $gt: 1000 } } }
])

//🔍 3. Detalles de apuestas con usuario
db.apuestas.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "id_usuario",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" }
])

//🔍 4. Eventos por deporte
db.eventos.aggregate([
  { $group: { _id: "$deporte", total: { $sum: 1 } } }
])

//🔍 5. Usuarios agrupados por ro
db.usuarios.aggregate([
  { $group: { _id: "$rol", cantidad: { $sum: 1 } } }
])


//🔍 6. Apuestas totales y promedio por usuario
db.apuestas.aggregate([
  { $group: {
    _id: "$id_usuario",
    total_apostado: { $sum: "$monto" },
    promedio: { $avg: "$monto" }
  }}
])

//🔍 7. Eventos programados con sus mercados
db.eventos.aggregate([
  { $match: { estado: "programado" } },
  {
    $lookup: {
      from: "mercados",
      localField: "_id",
      foreignField: "id_evento",
      as: "mercados"
    }
  }
])


//🔍 8. Comentarios por evento

db.comentarios_evento.aggregate([
  { $group: { _id: "$id_evento", cantidad: { $sum: 1 } } }
])

//🔍 9. Transacciones por tipo

db.transacciones.aggregate([
  { $group: { _id: "$tipo", total: { $sum: 1 } } }
])


//🔍 10. Total de notificaciones por usuario
db.notificaciones.aggregate([
  { $group: { _id: "$id_usuario", total: { $sum: 1 } } }
])

//🔍 11. Jugadores por equipo
db.jugadores.aggregate([
  { $group: { _id: "$id_equipo", cantidad: { $sum: 1 } } }
])

//🔍 12. Favoritos por usuario
db.favoritos_usuario.aggregate([
  { $group: { _id: "$id_usuario", total: { $sum: 1 } } }
])

//🔍 13. Eventos y su categoría
db.eventos.aggregate([
  {
    $lookup: {
      from: "categorias_evento",
      localField: "id_categoria",
      foreignField: "_id",
      as: "categoria"
    }
  }
])

//🔍 14. Apuestas canceladas con usuario
db.apuestas.aggregate([
  { $match: { estado_apuesta: "cancelada" } },
  {
    $lookup: {
      from: "usuarios",
      localField: "id_usuario",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" }
])

//🔍 15. Estadísticas promedio por evento
db.estadisticas_evento.aggregate([
  { $group: {
    _id: "$id_evento",
    promedio_local: { $avg: "$marcador_local" },
    promedio_visitante: { $avg: "$marcador_visitante" }
  }}
])
//🔍 16. Apuestas con mercados y eventos
db.apuestas.aggregate([
  {
    $lookup: {
      from: "mercados",
      localField: "id_mercado",
      foreignField: "_id",
      as: "mercado"
    }
  },
  { $unwind: "$mercado" },
  {
    $lookup: {
      from: "eventos",
      localField: "mercado.id_evento",
      foreignField: "_id",
      as: "evento"
    }
  }
])
//🔍 17. Últimos logs por módulo
db.logs_sistema.aggregate([
  { $sort: { fecha: -1 } },
  { $group: { _id: "$modulo", ultimo_log: { $first: "$mensaje" } } }
])
//🔍 18. Cantidad de mercados por evento
db.mercados.aggregate([
  { $group: { _id: "$id_evento", cantidad: { $sum: 1 } } }
])
//🔍 19. Promedio de apuestas por evento
db.apuestas.aggregate([
  {
    $lookup: {
      from: "mercados",
      localField: "id_mercado",
      foreignField: "_id",
      as: "mercado"
    }
  },
  { $unwind: "$mercado" },
  {
    $group: {
      _id: "$mercado.id_evento",
      promedio_apuesta: { $avg: "$monto" }
    }
  }
])
//🔍 20. Usuarios con más de 3 apuestas
db.apuestas.aggregate([
  { $group: { _id: "$id_usuario", total: { $sum: 1 } } },
  { $match: { total: { $gt: 3 } } }
])

//🔍 21. Eventos con más de 2 mercados
db.mercados.aggregate([
  { $group: { _id: "$id_evento", total: { $sum: 1 } } },
  { $match: { total: { $gt: 2 } } }
])

//🔍 22. Roles y cantidad de usuarios
db.usuarios.aggregate([
  {
    $lookup: {
      from: "roles",
      localField: "rol",
      foreignField: "_id",
      as: "rol_info"
    }
  },
  { $unwind: "$rol_info" },
  {
    $group: { _id: "$rol_info.nombre", total: { $sum: 1 } }
  }
])

//🔍 23. Apuestas ganadas por usuario
db.apuestas.aggregate([
  { $match: { resultado: "ganada" } },
  { $group: { _id: "$id_usuario", ganadas: { $sum: 1 } } }
])

//🔍 24. Eventos del mes actual
db.eventos.aggregate([
  {
    $match: {
      fecha: {
        $gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
        $lt: new Date(new Date().getFullYear(), new Date().getMonth() + 1, 1)
      }
    }
  }
])
//🔍 25. Transacciones recientes de tipo "retiro"
db.transacciones.aggregate([
  { $match: { tipo: "retiro" } },
  { $sort: { fecha: -1 } },
  { $limit: 10 }
])


/*
📊 Consulta 1: Detalles completos de apuestas activas por usuario con mercados y eventos
Esta consulta retorna todas las apuestas activas con:

Datos del usuario

Información del mercado

Detalles del evento
Ideal para un dashboard de usuario o un reporte administrativo.
*/
db.apuestas.aggregate([
  { $match: { estado_apuesta: "activa" } },
  {
    $lookup: {
      from: "usuarios",
      localField: "id_usuario",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" },
  {
    $lookup: {
      from: "mercados",
      localField: "id_mercado",
      foreignField: "_id",
      as: "mercado"
    }
  },
  { $unwind: "$mercado" },
  {
    $lookup: {
      from: "eventos",
      localField: "mercado.id_evento",
      foreignField: "_id",
      as: "evento"
    }
  },
  { $unwind: "$evento" },
  {
    $project: {
      _id: 0,
      nombre_usuario: "$usuario.nombre",
      correo: "$usuario.correo",
      monto_apostado: "$monto",
      cuota: "$cuota",
      mercado: "$mercado.nombre",
      evento: "$evento.nombre_evento",
      fecha_evento: "$evento.fecha",
      deporte: "$evento.deporte"
    }
  }
])

/* 
💸 Consulta 2: Ranking de usuarios que más han ganado (suma total de apuestas ganadas)
Reporte que muestra los top apostadores ganadores, útil para 
análisis financiero o gamificación.
*/

db.apuestas.aggregate([
  { $match: { resultado: "ganada" } },
  {
    $group: {
      _id: "$id_usuario",
      total_ganado: { $sum: { $multiply: ["$monto", "$cuota"] } },
      cantidad_apuestas_ganadas: { $sum: 1 }
    }
  },
  {
    $lookup: {
      from: "usuarios",
      localField: "_id",
      foreignField: "_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" },
  {
    $project: {
      _id: 0,
      nombre: "$usuario.nombre",
      total_ganado: 1,
      cantidad_apuestas_ganadas: 1
    }
  },
  { $sort: { total_ganado: -1 } },
  { $limit: 10 }
])

/*
📅 Consulta 3: Análisis mensual de eventos por deporte con promedio de apuestas por evento
Muestra cuántos eventos hubo este mes por deporte y cuánto se apostó en promedio por evento,
 para evaluar popularidad y monetización.
*/
db.eventos.aggregate([
  {
    $match: {
      fecha: {
        $gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
        $lt: new Date(new Date().getFullYear(), new Date().getMonth() + 1, 1)
      }
    }
  },
  {
    $lookup: {
      from: "mercados",
      localField: "_id",
      foreignField: "id_evento",
      as: "mercados"
    }
  },
  { $unwind: "$mercados" },
  {
    $lookup: {
      from: "apuestas",
      localField: "mercados._id",
      foreignField: "id_mercado",
      as: "apuestas"
    }
  },
  {
    $project: {
      deporte: 1,
      total_apuestas: { $size: "$apuestas" },
      monto_total: { $sum: "$apuestas.monto" }
    }
  },
  {
    $group: {
      _id: "$deporte",
      eventos_totales: { $sum: 1 },
      apuestas_totales: { $sum: "$total_apuestas" },
      monto_promedio_por_evento: { $avg: "$monto_total" }
    }
  }
])
