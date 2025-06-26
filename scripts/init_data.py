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

# Reemplaza la sección de MongoDB en tu script con esto:

print("\n==== Iniciando generación de datos en MongoDB ====")

# Conexión a MongoDB (conectar al mongos router)
from pymongo import MongoClient
try:
    # Conectar al mongos router (puerto 27017)
    mongo_client = MongoClient("mongodb://localhost:27017/", serverSelectionTimeoutMS=5000)
    
    # Verificar conexión
    mongo_client.admin.command('ping')
    print("✓ Conexión exitosa a MongoDB cluster")
    
    config_db = mongo_client["config"]
    config_db["settings"].update_one(
        {"_id": "chunksize"},
        {"$set": {"value": 1}},  # 1MB
        upsert=True
    )
    admin_db = mongo_client.admin
    mongo_db = mongo_client["proyecto"]
    
    # Habilitar sharding en la base de datos
    try:
        admin_db.command("enableSharding", "proyecto")
        print("✓ Sharding habilitado en base de datos 'proyecto'")
    except Exception as e:
        print(f"⚠ Sharding ya habilitado o error: {e}")
    
except Exception as e:
    print(f"❌ Error conectando a MongoDB: {e}")
    print("Verifica que mongos esté corriendo en puerto 27017")
    exit(1)

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

# 1. Usuarios con preferencias (desde PostgreSQL) - SIN SHARDING
print("Generando usuarios con preferencias...")
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

if usuarios_mongo:
    mongo_db.usuarios.insert_many(usuarios_mongo)
    print("✓ Colección 'usuarios' creada sin sharding")

# 2. Métodos de pago detalles (desde PostgreSQL) - CON SHARDING
print("Generando métodos de pago detalles...")
metodos_pago = []
cur.execute("SELECT id_metodo, id_usuario, tipo FROM metodos_pago")
for metodo in cur.fetchall():
    tipo = metodo[2]
    detalles = {}
    
    if tipo == 'tarjeta_credito':
        detalles = {
            "numero": fake.credit_card_number(),
            "titular": fake.name(),
            "expiracion": fake.credit_card_expire()
        }
    elif tipo == 'paypal':
        detalles = {
            "email": fake.email()
        }
    elif tipo == 'transferencia':
        detalles = {
            "cuenta": fake.bban()
        }
    
    metodos_pago.append({
        "pg_id": metodo[0],
        "usuario_id": metodo[1],
        "tipo": tipo,
        "detalles": detalles
    })

if metodos_pago:
    mongo_db.metodos_pago_detalles.insert_many(metodos_pago)
    try:
        mongo_db.metodos_pago_detalles.create_index({"usuario_id": "hashed"})
        admin_db.command("shardCollection", "proyecto.metodos_pago_detalles", key={"usuario_id": "hashed"})
        print("✓ Sharding configurado para colección 'metodos_pago_detalles'")
    except Exception as e:
        print(f"⚠ Error configurando sharding metodos_pago_detalles: {e}")

# 3. Eventos Resultados (desde MySQL) - CON SHARDING
print("Generando eventos resultados...")
eventos_resultado = []
mysql_cur.execute("SELECT id_evento FROM eventos WHERE estado = 'finalizado'")
for evento in mysql_cur.fetchall():
    evento_id = evento[0]
    
    resultado = {
        "pg_id": evento_id,
        "resultado": {
            "marcador_local": random.randint(0, 5),
            "marcador_visitante": random.randint(0, 5),
            "estadisticas": {
                "posesion_local": random.randint(30, 70),
                "posesion_visitante": random.randint(30, 70),
                "tiros_local": random.randint(3, 15),
                "tiros_visitante": random.randint(3, 15)
            }
        }
    }
    eventos_resultado.append(resultado)

if eventos_resultado:
    mongo_db.eventos_resultados.insert_many(eventos_resultado)
    try:
        mongo_db.eventos_resultados.create_index({ "pg_id": "hashed" })
        admin_db.command("shardCollection", "proyecto.eventos_resultados", key={"pg_id": "hashed"})
        print("✓ Sharding configurado para colección 'eventos_resultados'")
    except Exception as e:
        print(f"⚠ Error configurando sharding eventos_resultados: {e}")

# 4. Historial Apuestas (desde PostgreSQL) - CON SHARDING
print("Generando historial apuestas...")
historial_apuestas = []
cur.execute("""
    SELECT a.id_apuesta, a.id_usuario, a.id_mercado, a.monto, a.estado_apuesta, 
           a.fecha, a.ganancia_esperada
    FROM apuestas a
""")

# Obtener evento_id para cada mercado
mercado_evento_map = {}
mysql_cur.execute("SELECT id_mercado, id_evento FROM mercados")
for mercado in mysql_cur.fetchall():
    mercado_evento_map[mercado[0]] = mercado[1]

for apuesta in cur.fetchall():
    evento_id = mercado_evento_map.get(apuesta[2], random.choice(list(eventos_mysql.keys())))
    
    historial = {
        "usuario_id": apuesta[1],
        "evento_id": evento_id,
        "monto": float(apuesta[3]),
        "estado": apuesta[4],
        "fecha_apuesta": apuesta[5],
        "resultado_final": {
            "ganancia_real": float(apuesta[6]) if apuesta[4] == 'ganada' else 0,
            "estado_pago": "pagado" if apuesta[4] == 'ganada' else "pendiente" if apuesta[4] == 'pendiente' else "cancelado"
        }
    }
    historial_apuestas.append(historial)

if historial_apuestas:
    mongo_db.historial_apuestas.insert_many(historial_apuestas)
    try:
        mongo_db.historial_apuestas.create_index({ "usuario_id": "hashed" })
        admin_db.command("shardCollection", "proyecto.historial_apuestas", key={"usuario_id": "hashed"})
        print("✓ Sharding configurado para colección 'historial_apuestas'")
    except Exception as e:
        print(f"⚠ Error configurando sharding historial_apuestas: {e}")

# 5. Log JSON Datos (desde PostgreSQL) - CON SHARDING
print("Generando log JSON datos...")
logs_json = []
cur.execute("SELECT id, tipo_log, created_at FROM logs_json")
acciones = ['login', 'logout', 'apuesta_creada', 'deposito', 'retiro', 'error_sistema']
resultados = ['exitoso', 'fallido', 'pendiente']

for log in cur.fetchall():
    log_data = {
        "pg_id": log[0],
        "fecha": log[2],
        "datos": {
            "usuario_id": random.choice([random.choice(usuarios_ids), None]),
            "ip": fake.ipv4(),
            "user_agent": fake.user_agent(),
            "accion": random.choice(acciones),
            "resultado": random.choice(resultados)
        }
    }
    logs_json.append(log_data)

if logs_json:
    mongo_db.log_json_datos.insert_many(logs_json)
    try:
        mongo_db.log_json_datos.create_index({ "pg_id": "hashed" })
        admin_db.command("shardCollection", "proyecto.log_json_datos", key={"pg_id": "hashed"})
        print("✓ Sharding configurado para colección 'log_json_datos'")
    except Exception as e:
        print(f"⚠ Error configurando sharding log_json_datos: {e}")

# 6. Notificaciones - CON SHARDING
print("Generando notificaciones...")
notificaciones = []
tipos_notificacion = ["sistema", "promocion", "seguridad", "apuesta"]

for usuario in usuarios_mongo:
    num_notificaciones = random.randint(3, 12)
    for _ in range(num_notificaciones):
        notificacion = {
            "usuario_id": usuario["pg_id"],
            "mensaje": fake.text(max_nb_chars=200),
            "tipo": random.choice(tipos_notificacion),
            "fecha": fake.date_time_between(start_date="-30d"),
            "leida": random.choice([True, False])
        }
        notificaciones.append(notificacion)

if notificaciones:
    mongo_db.notificaciones.insert_many(notificaciones)
    try:
        mongo_db.notificaciones.create_index({ "usuario_id": "hashed" })
        admin_db.command("shardCollection", "proyecto.notificaciones", key={"usuario_id": "hashed"})
        print("✓ Sharding configurado para colección 'notificaciones'")
    except Exception as e:
        print(f"⚠ Error configurando sharding notificaciones: {e}")

# 7. Reportes - SIN SHARDING
print("Generando reportes...")
reportes = []
tipos_reporte = ["bug", "fraude", "contenido", "tecnico"]
estados_reporte = ["pendiente", "en_revision", "resuelto", "cerrado"]
tipos_evidencia = ["imagen", "texto", "video"]

for _ in range(5000):  # Generar 500 reportes
    usuario_id = random.choice([u["pg_id"] for u in usuarios_mongo])
    num_evidencias = random.randint(0, 3)
    evidencias = []
    
    for _ in range(num_evidencias):
        evidencias.append({
            "tipo": random.choice(tipos_evidencia),
            "url": fake.url()
        })
    
    reporte = {
        "usuario_id": usuario_id,
        "tipo": random.choice(tipos_reporte),
        "descripcion": fake.text(max_nb_chars=300),
        "evidencias": evidencias,
        "estado": random.choice(estados_reporte),
        "fecha_creacion": fake.date_time_between(start_date="-60d")
    }
    reportes.append(reporte)

if reportes:
    mongo_db.reportes.insert_many(reportes)
    mongo_db.reportes.create_index({ "usuario_id": "hashed" })
    print("✓ Colección 'reportes' creada sin sharding")

# 8. Mensajes Soporte - CON SHARDING
print("Generando mensajes soporte...")
mensajes_soporte = []
categorias_soporte = ["tecnico", "financiero", "cuenta", "apuestas"]
estados_soporte = ["abierto", "en_proceso", "resuelto", "cerrado"]

for _ in range(8000):  # Generar 800 tickets de soporte
    usuario_id = random.choice([u["pg_id"] for u in usuarios_mongo])
    num_mensajes = random.randint(1, 8)
    mensajes = []
    
    fecha_inicio = fake.date_time_between(start_date="-90d")
    for i in range(num_mensajes):
        mensaje = {
            "texto": fake.paragraph(),
            "fecha": fecha_inicio + timedelta(hours=random.randint(1, 48)),
            "tipo": "usuario" if i % 2 == 0 else "soporte"
        }
        mensajes.append(mensaje)
        fecha_inicio = mensaje["fecha"]
    
    soporte = {
        "usuario_id": usuario_id,
        "categoria": random.choice(categorias_soporte),
        "estado": random.choice(estados_soporte),
        "mensajes": mensajes
    }
    mensajes_soporte.append(soporte)

if mensajes_soporte:
    mongo_db.mensajes_soporte.insert_many(mensajes_soporte)
    try:
        mongo_db.mensajes_soporte.create_index({ "usuario_id": "hashed" })
        admin_db.command("shardCollection", "proyecto.mensajes_soporte", key={"usuario_id": "hashed"})
        print("✓ Sharding configurado para colección 'mensajes_soporte'")
    except Exception as e:
        print(f"⚠ Error configurando sharding mensajes_soporte: {e}")

# 10. Recompensas Diarias - CON SHARDING
print("Generando recompensas diarias...")
recompensas = []
tipos_recompensa = ["bono_deposito", "apuesta_gratis", "cashback"]

for usuario in usuarios_mongo:
    num_recompensas = random.randint(2, 8)
    for _ in range(num_recompensas):
        fecha_otorgado = fake.date_time_between(start_date="-60d")
        recompensa = {
            "usuario_id": usuario["pg_id"],
            "tipo": random.choice(tipos_recompensa),
            "valor": round(random.uniform(5, 100), 2),
            "fecha_otorgado": fecha_otorgado,
            "fecha_expiracion": fecha_otorgado + timedelta(days=random.randint(7, 30)),
            "reclamado": random.choice([True, False]),
            "condiciones": {
                "apuesta_minima": round(random.uniform(10, 50), 2),
                "rollover": random.randint(1, 5)
            }
        }
        recompensas.append(recompensa)

if recompensas:
    mongo_db.recompensas_diarias.insert_many(recompensas)
    try:
        mongo_db.recompensas_diarias.create_index({ "usuario_id": "hashed" })
        admin_db.command("shardCollection", "proyecto.recompensas_diarias", key={"usuario_id": "hashed"})
        print("✓ Sharding configurado para colección 'recompensas_diarias'")
    except Exception as e:
        print(f"⚠ Error configurando sharding recompensas_diarias: {e}")

# 11. Comentarios Eventos - CON SHARDING
print("Generando comentarios eventos...")
comentarios = []
estados_comentario = ["activo", "oculto", "eliminado"]

for evento_id in list(eventos_mysql.keys())[:400]:  # Comentarios para 400 eventos
    num_comentarios = random.randint(1, 15)
    for _ in range(num_comentarios):
        usuario = random.choice(usuarios_mongo)
        comentario = {
            "evento_id": evento_id,
            "usuario_id": usuario["pg_id"],
            "texto": fake.paragraph(),
            "fecha": fake.date_time_between(start_date="-30d"),
            "likes": random.randint(0, 50),
            "reportado": random.choice([True, False, False, False, False]),
            "estado": random.choices(estados_comentario, weights=[85, 10, 5])[0]
        }
        comentarios.append(comentario)

if comentarios:
    mongo_db.comentarios_eventos.insert_many(comentarios)
    try:
        mongo_db.comentarios_eventos.create_index({ "evento_id": "hashed" })
        admin_db.command("shardCollection", "proyecto.comentarios_eventos", key={"evento_id": "hashed"})
        print("✓ Sharding configurado para colección 'comentarios_eventos'")
    except Exception as e:
        print(f"⚠ Error configurando sharding comentarios_eventos: {e}")

# Verificar el estado del sharding
print("\n==== Estado del Sharding ====")
try:
    
    # Mostrar colecciones con y sin sharding
    print("\n==== Resumen de Sharding ====")
    stats = mongo_db.command("dbStats")
    shards_stats = stats['raw']

    for shard, info in shards_stats.items():
        print(f"Shard: {shard}")
        print(f"  Colecciones: {info['collections']}")
        print(f"  Documentos: {info['objects']}")
        print(f"  Tamaño de datos: {info['dataSize']/1e6:.2f} MB")
        print(f"  Tamaño almacenamiento: {info['storageSize']/1e6:.2f} MB")
        print(f"  Índices: {info['indexes']}")
        print(f"  Tamaño índices: {info['indexSize']/1e6:.2f} MB")
        print(f"  Espacio usado FS: {info['fsUsedSize']/1e9:.2f} GB")
        print(f"  Espacio total FS: {info['fsTotalSize']/1e9:.2f} GB")
        print()

    
except Exception as e:
    print(f"Error obteniendo estado: {e}")

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