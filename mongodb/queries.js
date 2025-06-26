//🔍 1. Usuarios con más notificaciones
db.notificaciones.aggregate([
  { $group: { _id: "$usuario_id", total: { $sum: 1 } } },
  { $sort: { total: -1 } },
  { $limit: 10 },
]);

db.notificaciones.aggregate([
  { $sort: { fecha: -1 } },
  { $group: { _id: "$tipo", ultima: { $first: "$mensaje" } } },
]);

db.reportes.aggregate([{ $group: { _id: "$estado", cantidad: { $sum: 1 } } }]);

db.recompensas_diarias.aggregate([
  { $group: { _id: "$recompensa", total: { $sum: 1 } } },
  { $sort: { total: -1 } },
]);

db.mensajes_soporte.aggregate([
  { $match: { estado: "en_proceso" } },
  { $count: "total_pendientes" },
]);

db.notificaciones.aggregate([
  { $group: { _id: "$tipo", cantidad: { $sum: 1 } } },
  { $sort: { cantidad: -1 } },
]);

db.usuarios.aggregate([
  {
    $project: {
      preferencias: { $objectToArray: "$preferencias" },
    },
  },
  { $unwind: "$preferencias" },
  {
    $group: {
      _id: "$preferencias.k",
      cantidad: { $sum: 1 },
    },
  },
  { $sort: { cantidad: -1 } },
]);

db.recompensas_diarias.aggregate([
  { $match: { reclamado: true } },
  {
    $group: {
      _id: "$tipo",
      total_recompensas: { $sum: "$valor" },
      cantidad: { $sum: 1 },
    },
  },
  { $sort: { total_recompensas: -1 } },
]);

db.mensajes_soporte.aggregate([
  { $group: { _id: "$usuario_id", total_mensajes: { $sum: 1 } } },
  { $sort: { total_mensajes: -1 } },
]);

db.notificaciones.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "pg_id",
      as: "usuario",
    },
  },
  { $unwind: "$usuario" },
  {
    $project: {
      mensaje: 1,
      tipo: 1,
      fecha: 1,
      "usuario.nombre": 1,
      "usuario.email": 1,
    },
  },
]);

db.reportes.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "pg_id",
      as: "usuario",
    },
  },
  { $unwind: "$usuario" },
  {
    $project: {
      descripcion: 1,
      estado: 1,
      fecha: 1,
      "usuario.nombre": 1,
    },
  },
]);

db.recompensas_diarias.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "pg_id",
      as: "usuario",
    },
  },
  { $unwind: "$usuario" },
  {
    $project: {
      tipo: 1,
      valor: 1,
      fecha_otorgado: 1,
      fecha_expiracion: 1,
      reclamado: 1,
      "usuario.nombre": 1,
    },
  },
]);

db.mensajes_soporte.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "pg_id",
      as: "usuario",
    },
  },
  { $unwind: "$usuario" },
  {
    $project: {
      mensaje: 1,
      estado: 1,
      fecha: 1,
      "usuario.nombre": 1,
    },
  },
]);

db.historial_apuestas.aggregate([
  {
    $group: {
      _id: "$estado",
      total_monto: { $sum: "$monto" },
      cantidad_apuestas: { $sum: 1 },
    },
  },
  { $sort: { total_monto: -1 } },
]);

db.metodos_pago_detalles.aggregate([
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "pg_id",
      as: "usuario",
    },
  },
  { $unwind: "$usuario" },
  {
    $project: {
      _id: 0,
      tipo: 1,
      "detalles.numero": 1,
      "detalles.email": 1,
      "detalles.titular": 1,
      "usuario.nombre": 1,
    },
  },
]);

db.historial_apuestas.aggregate([
  {
    $match: { estado: "ganada" },
  },
  {
    $group: {
      _id: "$usuario_id",
      total_ganadas: { $sum: 1 },
    },
  },
  {
    $lookup: {
      from: "usuarios",
      localField: "_id",
      foreignField: "pg_id",
      as: "usuario_info",
    },
  },
  {
    $unwind: "$usuario_info",
  },
  {
    $project: {
      usuario_id: "$_id",
      nombre: "$usuario_info.nombre",
      total_ganadas: 1,
    },
  },
]);

db.metodos_pago_detalles.aggregate([
  {
    $group: {
      _id: "$usuario_id",
      total_metodos: { $sum: 1 },
    },
  },
  {
    $lookup: {
      from: "usuarios",
      localField: "_id",
      foreignField: "pg_id",
      as: "usuario_info",
    },
  },
  {
    $unwind: "$usuario_info",
  },
  {
    $project: {
      usuario_id: "$_id",
      nombre: "$usuario_info.nombre",
      total_metodos: 1,
    },
  },
]);

db.metodos_pago_detalles.aggregate([
  {
    $group: {
      _id: "$tipo",
      usuarios_unicos: { $addToSet: "$usuario_id" }
    }
  },
  {
    $project: {
      tipo: "$_id",
      cantidad_usuarios: { $size: "$usuarios_unicos" }
    }
  },
  { $sort: { cantidad_usuarios: -1 } }
])

db.metodos_pago_detalles.aggregate([
  {
    $match: {
      $or: [
        { "detalles": { $exists: false } },
        { $expr: { $eq: [{ $size: { $objectToArray: "$detalles" } }, 0] } }
      ]
    }
  },
  {
    $lookup: {
      from: "usuarios",
      localField: "usuario_id",
      foreignField: "pg_id",
      as: "usuario"
    }
  },
  { $unwind: "$usuario" },
  {
    $project: {
      tipo: 1,
      usuario_nombre: "$usuario.nombre",
      usuario_email: "$usuario.email"
    }
  }
])

db.comentarios_eventos.aggregate([
  {
    $group: {
      _id: "$evento_id",
      total_comentarios: { $sum: 1 }
    }
  },
  { $sort: { total_comentarios: -1 } },
  { $limit: 10 }
])