from bson import ObjectId
import psycopg2
from faker import Faker
import random
from datetime import datetime, timedelta
import json
import mysql.connector

fake = Faker('es_ES')  # Usar datos en español

# Configura tu conexión a PostgreSQL
conn = psycopg2.connect(
    host="localhost",
    database="apuestas_db",
    user="postgres",
    password="postgres_password"
)
cur = conn.cursor()

# Conexión a MySQL
mysql_conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="mysql_password",
    database="apuestas_db"
)
mysql_cur = mysql_conn.cursor()

# ---------------------
# PARÁMETROS
# ---------------------
NUM_USUARIOS = 5000
NUM_EVENTOS = 800
NUM_MERCADOS = 3200  # 4 mercados promedio por evento
NUM_APUESTAS = 30000
NUM_EQUIPOS = 200
NUM_PATROCINADORES = 50
NUM_ROLES = 3
NUM_CATEGORIAS = 10
NUM_TRANSACCIONES = 15000
NUM_COMENTARIOS = 5000

print("Iniciando generación de datos...")

# ---------------------
# LIMPIAR DATOS EXISTENTES (OPCIONAL)
# ---------------------
print("Limpiando datos existentes...")
# PostgreSQL tables
pg_tables_to_clear = [
    'logs_json', 'transacciones', 'metodos_pago', 
    'usuario_rol', 'roles', 'usuarios', 'apuestas'
]

for table in pg_tables_to_clear:
    cur.execute(f"TRUNCATE TABLE {table} RESTART IDENTITY CASCADE")

# MySQL tables
mysql_tables_to_clear = [
    'evento_patrocinadores', 'patrocinadores',
    'evento_equipos', 'equipos', 'mercados',
    'eventos_categorias', 'eventos', 'categorias'
]

for table in mysql_tables_to_clear:
    mysql_cur.execute(f"SET FOREIGN_KEY_CHECKS = 0")
    mysql_cur.execute(f"TRUNCATE TABLE {table}")
    mysql_cur.execute(f"SET FOREIGN_KEY_CHECKS = 1")

mysql_conn.commit()

# ---------------------
# INSERCIÓN DE ROLES
# ---------------------
print("Insertando roles...")
roles = ['admin', 'usuario', 'moderador']
for rol in roles:
    cur.execute("INSERT INTO roles (nombre_rol) VALUES (%s)", (rol,))

# ---------------------
# CATEGORÍAS
# ---------------------
print("Insertando categorías...")
categorias = ['Fútbol', 'Baloncesto', 'Tenis', 'Béisbol', 'Voleibol', 
              'Hockey', 'Rugby', 'Cricket', 'Golf', 'Boxeo']
categoria_ids = []
for categoria in categorias:
    mysql_cur.execute("INSERT INTO categorias (nombre) VALUES (%s)", (categoria,))
    categoria_ids.append(mysql_cur.lastrowid)

mysql_conn.commit()

# ---------------------
# USUARIOS
# ---------------------
print(f"Insertando {NUM_USUARIOS} usuarios...")
usuarios_ids = []

for i in range(NUM_USUARIOS):
    if i % 1000 == 0:
        print(f"  Usuarios: {i}/{NUM_USUARIOS}")
    
    cur.execute("""
        INSERT INTO usuarios (nombre, email, password, saldo, estado)
        VALUES (%s, %s, %s, %s, %s) RETURNING id_usuario
    """, (
        fake.name(), 
        fake.unique.email(), 
        fake.sha256(), 
        round(random.uniform(10, 2000), 2),
        random.choice([True, True, True, False])  # 75% activos
    ))
    usuarios_ids.append(cur.fetchone()[0])

print(f'Se registraron {len(usuarios_ids)} usuarios')

# Asignar roles aleatorios a usuarios
print("Asignando roles a usuarios...")
for user_id in usuarios_ids:
    # Algunos usuarios pueden tener múltiples roles
    num_roles = random.choices([1, 2], weights=[85, 15])[0]
    roles_asignados = random.sample(range(1, len(roles) + 1), num_roles)
    
    for rol_id in roles_asignados:
        cur.execute("""
            INSERT INTO usuario_rol (id_usuario, id_rol) 
            VALUES (%s, %s) ON CONFLICT DO NOTHING
        """, (user_id, rol_id))

# ---------------------
# MÉTODOS DE PAGO
# ---------------------
print("Insertando métodos de pago...")
tipos_pago = ['tarjeta_credito', 'tarjeta_debito', 'paypal', 'transferencia', 'criptomoneda']
for _ in range(NUM_USUARIOS // 2):  # 50% de usuarios tienen métodos de pago
    user_id = random.choice(usuarios_ids)
    tipo = random.choice(tipos_pago)
    
    cur.execute("""
        INSERT INTO metodos_pago (id_usuario, tipo, activo)
        VALUES (%s, %s, %s)
    """, (user_id, tipo, random.choice([True, True, False])))

# ---------------------
# EQUIPOS
# ---------------------
print(f"Insertando {NUM_EQUIPOS} equipos...")
equipo_ids = []
deportes = ['Fútbol', 'Baloncesto', 'Tenis', 'Béisbol', 'Voleibol']
paises = ['España', 'Argentina', 'Brasil', 'México', 'Colombia', 'Chile', 'Perú', 'Uruguay']

for i in range(NUM_EQUIPOS):
    if i % 50 == 0:
        print(f"  Equipos: {i}/{NUM_EQUIPOS}")
    
    mysql_cur.execute("""
        INSERT INTO equipos (nombre, pais, deporte, logo_url, fecha_fundacion, activo)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (
        f"{fake.city()} {fake.word().title()}", 
        random.choice(paises),
        random.choice(deportes),
        fake.image_url(width=200, height=200),
        fake.date_between(start_date='-50y', end_date='-1y'),
        random.choice([True, True, True, False])  # 75% activos
    ))
    equipo_ids.append(mysql_cur.lastrowid)

mysql_conn.commit()

# ---------------------
# PATROCINADORES
# ---------------------
print(f"Insertando {NUM_PATROCINADORES} patrocinadores...")
patrocinador_ids = []
for i in range(NUM_PATROCINADORES):
    mysql_cur.execute("""
        INSERT INTO patrocinadores (nombre, logo_url, sitio_web, contacto_email, activo)
        VALUES (%s, %s, %s, %s, %s)
    """, (
        fake.company(),
        fake.image_url(width=300, height=100),
        fake.url(),
        fake.company_email(),
        random.choice([True, True, False])  # 67% activos
    ))
    patrocinador_ids.append(mysql_cur.lastrowid)

mysql_conn.commit()

# ---------------------
# EVENTOS Y MERCADOS
# ---------------------
print(f"Insertando {NUM_EVENTOS} eventos...")
evento_ids = []
mercado_ids = []
estados_evento = ['pendiente', 'en_vivo', 'finalizado', 'cancelado']
tipos_mercado = ['1X2', 'Más/Menos 2.5', 'Ganador', 'Handicap', 'Ambos Marcan', 'Total Goles']

for i in range(NUM_EVENTOS):
    if i % 100 == 0:
        print(f"  Eventos: {i}/{NUM_EVENTOS}")
    
    # Crear evento
    deporte = random.choice(deportes)
    estado = random.choices(estados_evento, weights=[40, 10, 45, 5])[0]
    
    # Fecha del evento
    if (estado == 'pendiente'):
        fecha_evento = fake.future_datetime(end_date="+60d")
    elif (estado == 'en_vivo'):
        fecha_evento = fake.date_time_between(start_date='-1h', end_date='+2h')
    else:  # finalizado o cancelado
        fecha_evento = fake.past_datetime(start_date='-30d')
    
    
    mysql_cur.execute("""
        INSERT INTO eventos (nombre_evento, deporte, fecha,  estado)
        VALUES (%s, %s, %s, %s)
    """, (
        f"{fake.catch_phrase()} - {deporte}",
        deporte,
        fecha_evento,
        estado
    ))
    id_evento = mysql_cur.lastrowid
    evento_ids.append(id_evento)
    
    # Relacionar evento con categoría
    categoria_evento = random.choice(categoria_ids)
    mysql_cur.execute("""
        INSERT INTO eventos_categorias (id_categoria, id_evento)
        VALUES (%s, %s)
    """, (categoria_evento, id_evento))
    
    # Equipos relacionados con el evento
    equipos_deporte = [eq for eq in equipo_ids if random.random() < 0.3]  # Filtro aproximado
    if len(equipos_deporte) >= 2:
        equipos_evento = random.sample(equipos_deporte, 2)
        for idx, equipo_id in enumerate(equipos_evento):
            puntuacion = 0
            mysql_cur.execute("""
                INSERT INTO evento_equipos (id_evento, id_equipo, es_local, puntuacion)
                VALUES (%s, %s, %s, %s)
            """, (id_evento, equipo_id, idx == 0, puntuacion))
    
    # Patrocinadores del evento (algunos eventos)
    if random.random() < 0.3:  # 30% de eventos tienen patrocinadores
        num_patrocinadores = random.randint(1, 3)
        patrocinadores_evento = random.sample(patrocinador_ids, min(num_patrocinadores, len(patrocinador_ids)))
        
        for patrocinador_id in patrocinadores_evento:
            mysql_cur.execute("""
                INSERT INTO evento_patrocinadores (id_evento, id_patrocinador, tipo_patrocinio, 
                                                 monto, posicion_logo, fecha_inicio, fecha_fin)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                id_evento, patrocinador_id,
                random.choice(['titulo_evento', 'presentado_por', 'patrocinador_oficial']),
                round(random.uniform(1000, 50000), 2),
                random.choice(['banner_superior', 'lateral', 'camiseta', 'campo']),
                fecha_evento.date() - timedelta(days=random.randint(1, 30)),
                fecha_evento.date() + timedelta(days=random.randint(1, 10))
            ))
    
    # Mercados por evento
    num_mercados = random.randint(3, 6)
    mercados_evento = random.sample(tipos_mercado, min(num_mercados, len(tipos_mercado)))
    
    for tipo_mercado in mercados_evento:
        # Cuotas más realistas según el tipo de mercado
        if tipo_mercado == '1X2':
            cuota = round(random.uniform(1.5, 5.0), 2)
        elif 'Más/Menos' in tipo_mercado:
            cuota = round(random.uniform(1.7, 2.3), 2)
        else:
            cuota = round(random.uniform(1.2, 8.0), 2)
        
        # Estado del mercado
        estado_mercado = True if estado in ['pendiente', 'en_vivo'] else random.choice([True, False])
        
        mysql_cur.execute("""
            INSERT INTO mercados (id_evento, tipo_mercado, cuota, estado)
            VALUES (%s, %s, %s, %s)
        """, (id_evento, tipo_mercado, cuota, estado_mercado))
        mercado_ids.append(mysql_cur.lastrowid)

mysql_conn.commit()

# ---------------------
# APUESTAS (30,000 registros)
# ---------------------

print(f"Insertando {NUM_APUESTAS} apuestas...")
estados_apuesta = ['pendiente', 'ganada', 'perdida', 'anulada']

for i in range(NUM_APUESTAS):
    if i % 5000 == 0:
        print(f"  Apuestas: {i}/{NUM_APUESTAS}")
    
    mercado_id = random.choice(mercado_ids)
    user_id = random.choice(usuarios_ids)
    
    # Monto de la apuesta
    monto = round(random.uniform(5, 500), 2)
    
    # Obtener la cuota del mercado
    mysql_cur.execute("SELECT cuota FROM mercados WHERE id_mercado = %s", (mercado_id,))
    cuota = mysql_cur.fetchone()[0]
    
    # Ganancia esperada
    ganancia_esperada = round(monto * float(cuota), 2)
    
    # Estado de la apuesta (basado en si el evento ya finalizó)
    mysql_cur.execute("""
        SELECT e.estado FROM eventos e 
        JOIN mercados m ON e.id_evento = m.id_evento 
        WHERE m.id_mercado = %s
    """, (mercado_id,))
    estado_evento = mysql_cur.fetchone()[0]
    
    if estado_evento == 'finalizado':
        estado_apuesta = random.choices(['ganada', 'perdida'], weights=[30, 70])[0]
    elif estado_evento == 'cancelado':
        estado_apuesta = 'anulada'
    else:
        estado_apuesta = 'pendiente'
    
    # Fecha de la apuesta
    fecha_apuesta = fake.date_time_between(start_date='-60d', end_date='now')
    
    # Usar PostgreSQL para la inserción
    cur.execute("""
        INSERT INTO apuestas (id_usuario, id_mercado, monto, ganancia_esperada, fecha, estado_apuesta)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (user_id, mercado_id, monto, ganancia_esperada, fecha_apuesta, estado_apuesta))

mysql_conn.commit()

# ---------------------
# TRANSACCIONES
# ---------------------
print(f"Insertando {NUM_TRANSACCIONES} transacciones...")
tipos_transaccion = ['deposito', 'retiro', 'apuesta', 'ganancia']
estados_transaccion = ['completada', 'pendiente', 'fallida', 'cancelada']

# Obtener métodos de pago por usuario
cur.execute("SELECT id_metodo, id_usuario FROM metodos_pago WHERE activo = true")
metodos_pago_por_usuario = {}
for metodo in cur.fetchall():
    if metodo[1] not in metodos_pago_por_usuario:
        metodos_pago_por_usuario[metodo[1]] = []
    metodos_pago_por_usuario[metodo[1]].append(metodo[0])

for i in range(NUM_TRANSACCIONES):
    if i % 2000 == 0:
        print(f"  Transacciones: {i}/{NUM_TRANSACCIONES}")
    
    # Seleccionar usuario y su método de pago
    usuario_id = random.choice(usuarios_ids)
    metodo_pago_id = None
    
    # Si el usuario tiene métodos de pago, seleccionar uno
    if usuario_id in metodos_pago_por_usuario and metodos_pago_por_usuario[usuario_id]:
        metodo_pago_id = random.choice(metodos_pago_por_usuario[usuario_id])
    
    tipo = random.choice(tipos_transaccion)
    
    # Montos según el tipo de transacción
    if tipo == 'deposito':
        monto = round(random.uniform(20, 1000), 2)
    elif tipo == 'retiro':
        monto = round(random.uniform(50, 800), 2)
    elif tipo == 'apuesta':
        monto = round(random.uniform(5, 200), 2)
    else:  # ganancia
        monto = round(random.uniform(10, 1000), 2)
    
    estado = random.choices(estados_transaccion, weights=[80, 10, 7, 3])[0]
    
    cur.execute("""
        INSERT INTO transacciones (id_usuario, id_metodo_pago, tipo_transaccion, monto, estado)
        VALUES (%s, %s, %s, %s, %s)
    """, (
        usuario_id,
        metodo_pago_id,  # Puede ser None si el usuario no tiene métodos de pago
        tipo,
        monto,
        estado
    ))

# ---------------------
# LOGS JSON
# ---------------------
print("Insertando logs del sistema...")
tipos_log = ['login', 'apuesta_creada', 'deposito', 'retiro', 'error_sistema']

for _ in range(1000):
    tipo_log = random.choice(tipos_log)
    
    cur.execute("""
        INSERT INTO logs_json (tipo_log)
        VALUES (%s)
    """, (tipo_log,))

# ---------------------
# CONFIRMAR Y CERRAR
# ---------------------
print("Confirmando transacciones...")
conn.commit()

print("\n==== Iniciando generación de datos en MongoDB ====")

# Conexión a MongoDB
from pymongo import MongoClient
mongo_client = MongoClient("mongodb://mongo:mongo@localhost:27017/?authSource=admin")
mongo_db = mongo_client["proyecto"]

# Limpiar colecciones existentes
print("Limpiando colecciones de MongoDB...")
for collection in mongo_db.list_collection_names():
    mongo_db[collection].drop()

# Obtener datos de eventos de MySQL
mysql_cur.execute("""
    SELECT id_evento, nombre_evento, deporte, fecha, estado 
    FROM eventos
""")
eventos_mysql = {row[0]: {"nombre": row[1], "deporte": row[2], "fecha": row[3], "estado": row[4]} 
                for row in mysql_cur.fetchall()}

# Usuarios con preferencias (desde PostgreSQL)
print("Sincronizando usuarios con preferencias...")
usuarios_mongo = []
cur.execute("SELECT id_usuario, nombre, email, created_at FROM usuarios")
for user in cur.fetchall():
    usuario_mongo = {
        "pg_id": user[0],
        "nombre": user[1],
        "email": user[2],
        "fecha_registro": user[3],
        "preferencias": {
            "idioma": random.choice(["es", "en", "pt"]),
            "deporte_favorito": random.choice(deportes),
            "notificaciones": random.choice([True, False])
        }
    }
    usuarios_mongo.append(usuario_mongo)
mongo_db.usuarios.insert_many(usuarios_mongo)

# Métodos de pago detalles (desde PostgreSQL)
print("Generando detalles de métodos de pago...")
metodos_pago = []
cur.execute("SELECT id_metodo, id_usuario, tipo FROM metodos_pago")
for metodo in cur.fetchall():
    tipo = metodo[2]
    if tipo == 'tarjeta_credito':
        detalles = {
            "numero": fake.credit_card_number(),
            "titular": fake.name(),
            "expiracion": fake.credit_card_expire()
        }
    elif tipo == 'paypal':
        detalles = {"email": fake.email()}
    else:
        detalles = {"cuenta": fake.bban()}
    
    metodos_pago.append({
        "pg_id": metodo[0],
        "usuario_id": metodo[1],
        "tipo": tipo,
        "detalles": detalles
    })
mongo_db.metodos_pago_detalles.insert_many(metodos_pago)

# Resultados de eventos (desde MySQL)
print("Generando resultados de eventos...")
eventos_resultado = []
mysql_cur.execute("SELECT id_evento FROM eventos WHERE estado = 'finalizado'")
for evento in mysql_cur.fetchall():
    evento_id = evento[0]
    
    # Obtener equipos del evento
    mysql_cur.execute("""
        SELECT e.id_equipo, e.nombre, ee.es_local 
        FROM evento_equipos ee
        JOIN equipos e ON e.id_equipo = ee.id_equipo
        WHERE ee.id_evento = %s
    """, (evento_id,))
    equipos = mysql_cur.fetchall()
    
    resultado = {
        "marcador": {
            "local": random.randint(0, 5),
            "visitante": random.randint(0, 5)
        },
        "equipos": {
            "local": {"id": equipos[0][0], "nombre": equipos[0][1]} if equipos else None,
            "visitante": {"id": equipos[1][0], "nombre": equipos[1][1]} if len(equipos) > 1 else None
        },
        "estadisticas": {
            "posesion": random.randint(30, 70),
            "tiros": random.randint(5, 20),
            "faltas": random.randint(5, 25),
            "tarjetas": {
                "amarillas": random.randint(0, 8),
                "rojas": random.randint(0, 2)
            }
        }
    }
    eventos_resultado.append({
        "mysql_id": evento_id,
        "resultado": resultado,
        "fecha_actualizacion": eventos_mysql[evento_id]["fecha"]
    })
mongo_db.eventos_resultado.insert_many(eventos_resultado)

# Historial de apuestas (desde PostgreSQL)
print("Generando historial de apuestas...")
historial_apuestas = []
cur.execute("""
    SELECT a.id_apuesta, a.id_usuario, a.id_mercado, a.monto, a.estado_apuesta, 
           a.fecha, a.ganancia_esperada
    FROM apuestas a
""")
for apuesta in cur.fetchall():
    historial = {
        "pg_id": apuesta[0],
        "usuario_id": apuesta[1],
        "mercado_id": apuesta[2],
        "monto": float(apuesta[3]),
        "estado": apuesta[4],
        "fecha_apuesta": apuesta[5],
        "ganancia_esperada": float(apuesta[6]),
        "resultado_final": {
            "ganancia_real": float(apuesta[6]) if apuesta[4] == 'ganada' else 0,
            "estado_pago": "completado" if apuesta[4] in ['ganada', 'perdida'] else "pendiente"
        }
    }
    historial_apuestas.append(historial)
mongo_db.historial_apuestas.insert_many(historial_apuestas)

# Agregar después de eventos_resultado.insert_many()

# Comentarios de eventos
print("Generando comentarios de eventos...")
comentarios = []
for evento in eventos_resultado:
    num_comentarios = random.randint(1, 10)
    for _ in range(num_comentarios):
        usuario = random.choice(usuarios_mongo)
        comentario = {
            "evento_id": evento["mysql_id"],
            "usuario_id": usuario["pg_id"],
            "texto": fake.paragraph(),
            "fecha": fake.date_time_between(start_date="-30d"),
            "likes": random.randint(0, 100),
            "reportado": random.choice([True, False, False, False]),  # 25% probabilidad
            "estado": "activo"
        }
        comentarios.append(comentario)
mongo_db.comentarios_eventos.insert_many(comentarios)

# Notificaciones
print("Generando notificaciones...")
tipos_notificacion = ["sistema", "promocion", "seguridad", "apuesta", "deposito"]
notificaciones = []
for _ in range(NUM_USUARIOS * 3):  # 3 notificaciones promedio por usuario
    usuario = random.choice(usuarios_mongo)
    notificacion = {
        "usuario_id": usuario["pg_id"],  # Ahora usa el mismo ID que PostgreSQL
        "mensaje": fake.sentence(),
        "tipo": random.choice(tipos_notificacion),
        "fecha": fake.date_time_between(start_date=usuario["fecha_registro"]),
        "leida": random.choice([True, False])
    }
    notificaciones.append(notificacion)
mongo_db.notificaciones.insert_many(notificaciones)

# Reportes
print("Generando reportes...")
motivos_reporte = ["contenido_ofensivo", "bug", "fraude", "spam", "otro"]
estados_reporte = ["pendiente", "en_proceso", "resuelto", "cerrado"]
reportes = []
for _ in range(NUM_USUARIOS // 4):  # 25% de usuarios crean reportes
    usuario = random.choice(usuarios_mongo)
    reporte = {
        "usuario_id": usuario["pg_id"],
        "motivo": random.choice(motivos_reporte),
        "descripcion": fake.paragraph(),
        "estado": random.choice(estados_reporte),
        "fecha_creacion": fake.date_time_between(start_date="-30d"),
        "ultima_actualizacion": fake.date_time_between(start_date="-15d"),
        "prioridad": random.choice(["baja", "media", "alta"])
    }
    reportes.append(reporte)
mongo_db.reportes.insert_many(reportes)

# Actividades de usuario
print("Generando actividades de usuario...")
tipos_actividad = ["login", "logout", "apuesta_creada", "deposito", "retiro", "perfil_actualizado"]
actividades = []
for usuario in usuarios_mongo:
    num_actividades = random.randint(5, 20)
    for _ in range(num_actividades):
        actividad = {
            "usuario_id": usuario["pg_id"],
            "tipo": random.choice(tipos_actividad),
            "fecha": fake.date_time_between(start_date=usuario["fecha_registro"]),
            "detalles": {
                "ip": fake.ipv4(),
                "dispositivo": fake.user_agent(),
                "ubicacion": fake.city()
            }
        }
        actividades.append(actividad)
mongo_db.actividades_usuario.insert_many(actividades)

# Recompensas diarias
print("Generando recompensas diarias...")
tipos_recompensa = ["bono_deposito", "apuesta_gratis", "giros_gratis", "cashback", "puntos_vip"]
recompensas = []
for usuario in random.sample(usuarios_mongo, len(usuarios_mongo) // 2):  # 50% de usuarios
    for _ in range(random.randint(1, 5)):
        fecha_otorgado = fake.date_time_between(start_date="-30d")
        # Convertir fecha_expiracion a datetime en lugar de date
        fecha_expiracion = datetime.combine(
            fake.future_date(),
            datetime.min.time()
        )
        
        recompensa = {
            "usuario_id": usuario["pg_id"],
            "tipo": random.choice(tipos_recompensa),
            "valor": round(random.uniform(5, 100), 2),
            "fecha_otorgado": fecha_otorgado,
            "fecha_expiracion": fecha_expiracion,  # Ahora es datetime
            "reclamado": random.choice([True, False]),
            "condiciones": {
                "apuesta_minima": random.randint(10, 50),
                "rollover": random.randint(1, 5)
            }
        }
        recompensas.append(recompensa)
mongo_db.recompensas_diarias.insert_many(recompensas)

# Mensajes de soporte
print("Generando mensajes de soporte...")
categorias_soporte = ["tecnico", "financiero", "cuenta", "apuestas", "promociones"]
mensajes = []
for _ in range(NUM_USUARIOS // 3):  # 1/3 de usuarios con tickets de soporte
    usuario = random.choice(usuarios_mongo)
    fecha_inicial = fake.date_time_between(start_date="-60d")
    
    ticket = {
        "usuario_id": usuario["pg_id"],
        "categoria": random.choice(categorias_soporte),
        "estado": random.choice(["abierto", "en_proceso", "resuelto", "cerrado"]),
        "fecha_creacion": fecha_inicial,
        "mensajes": [
            {
                "texto": fake.paragraph(),
                "fecha": fecha_inicial,
                "tipo": "usuario"
            }
        ]
    }
    
    # Agregar respuestas al ticket
    num_respuestas = random.randint(1, 4)
    for i in range(num_respuestas):
        fecha_respuesta = fecha_inicial + timedelta(hours=random.randint(1, 48))
        mensaje = {
            "texto": fake.paragraph(),
            "fecha": fecha_respuesta,
            "tipo": "soporte" if i % 2 == 0 else "usuario"
        }
        ticket["mensajes"].append(mensaje)
    
    mensajes.append(ticket)
mongo_db.mensajes_soporte.insert_many(mensajes)

# Cerrar conexión MongoDB
print("Cerrando conexión con MongoDB...")
mongo_client.close()

# Cerrar conexiones MySQL
mysql_cur.close()
mysql_conn.close()

cur.close()
conn.close()

print("¡Datos generados exitosamente!")
print(f"""
Resumen de datos generados:
- Usuarios: {NUM_USUARIOS}
- Eventos: {NUM_EVENTOS}
- Mercados: {len(mercado_ids)}
- Apuestas: {NUM_APUESTAS}
- Equipos: {NUM_EQUIPOS}
- Patrocinadores: {NUM_PATROCINADORES}
- Comentarios: {NUM_COMENTARIOS}
- Transacciones: {NUM_TRANSACCIONES}
- Categorías: {len(categorias)}
- Roles: {len(roles)}
""")