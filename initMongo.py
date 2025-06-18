from pymongo import MongoClient
from datetime import datetime, timedelta
import random
from bson import ObjectId

client = MongoClient("mongodb://mongo:mongo@localhost:27017/?authSource=admin")
db = client["proyecto"]

usuarios = []
for i in range(15):
    usuario = {
        "_id": ObjectId(),
        "nombre": f"Usuario{i}",
        "email": f"usuario{i}@mail.com",
        "fecha_registro": datetime.now() - timedelta(days=random.randint(1, 1000))
    }
    usuarios.append(usuario)
db.usuarios.insert_many(usuarios)

tipos_notificacion = ["sistema", "promocion", "seguridad"]
estados_reporte = ["pendiente", "resuelto", "en proceso"]
tipos_actividad = ["login", "apuesta", "retiro", "recarga"]
recompensas = ["bono 5", "bono 10", "giros gratis"]

db.notificaciones.insert_many([
    {
        "usuario_id": random.choice(usuarios)["_id"],
        "mensaje": "Mensaje de notificación",
        "tipo": random.choice(tipos_notificacion),
        "fecha": datetime.now() - timedelta(days=random.randint(0, 30))
    } for _ in range(100)
])

db.reportes.insert_many([
    {
        "usuario_id": random.choice(usuarios)["_id"],
        "descripcion": "Contenido ofensivo",
        "estado": random.choice(estados_reporte),
        "fecha": datetime.now() - timedelta(days=random.randint(0, 60))
    } for _ in range(40)
])

db.actividades_usuario.insert_many([
    {
        "usuario_id": random.choice(usuarios)["_id"],
        "tipo": random.choice(tipos_actividad),
        "fecha": datetime.now() - timedelta(days=random.randint(0, 90))
    } for _ in range(100)
])

db.recompensas_diarias.insert_many([
    {
        "usuario_id": random.choice(usuarios)["_id"],
        "recompensa": random.choice(recompensas),
        "fecha": datetime.now() - timedelta(days=random.randint(0, 15))
    } for _ in range(60)
])

db.mensajes_soporte.insert_many([
    {
        "usuario_id": random.choice(usuarios)["_id"],
        "mensaje": "Necesito ayuda",
        "estado": "pendiente" if random.random() < 0.4 else "resuelto",
        "fecha": datetime.now() - timedelta(days=random.randint(0, 20)),
        **({"tiempo_respuesta": random.randint(5, 120)} if random.random() > 0.3 else {})
    } for _ in range(30)
])
