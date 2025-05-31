import psycopg2
from faker import Faker
import random
from datetime import datetime, timedelta
import json

fake = Faker('es_ES')  # Usar datos en español

# Configura tu conexión a PostgreSQL
conn = psycopg2.connect(
    host="localhost",
    database="apuestas_db",
    user="postgres",
    password=""
)
cur = conn.cursor()

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
tables_to_clear = [
    'logs_json', 'historial_apuestas', 'evento_patrocinadores', 'patrocinadores',
    'evento_equipos', 'equipos', 'transacciones', 'apuestas', 'mercados',
    'comentarios_eventos', 'eventos_categorias', 'eventos', 'categorias', 
    'metodos_pago', 'usuario_rol', 'roles', 'usuarios'
]

for table in tables_to_clear:
    cur.execute(f"TRUNCATE TABLE {table} RESTART IDENTITY CASCADE")

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
    cur.execute("INSERT INTO categorias (nombre) VALUES (%s) RETURNING id_categoria", (categoria,))
    categoria_ids.append(cur.fetchone()[0])

# ---------------------
# USUARIOS
# ---------------------
print(f"Insertando {NUM_USUARIOS} usuarios...")
usuarios_ids = []
for i in range(NUM_USUARIOS):
    if i % 1000 == 0:
        print(f"  Usuarios: {i}/{NUM_USUARIOS}")
    
    cur.execute("""
        INSERT INTO usuarios (nombre, email, password_hash, saldo, estado)
        VALUES (%s, %s, %s, %s, %s) RETURNING id_usuario
    """, (
        fake.name(), 
        fake.unique.email(), 
        fake.sha256(), 
        round(random.uniform(10, 2000), 2),
        random.choice([True, True, True, False])  # 75% activos
    ))
    usuarios_ids.append(cur.fetchone()[0])

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
    
    if tipo.startswith('tarjeta'):
        detalles = {
            "numero": fake.credit_card_number(),
            "titular": fake.name(),
            "expiracion": fake.credit_card_expire(),
            "cvv": fake.credit_card_security_code()
        }
    elif tipo == 'paypal':
        detalles = {
            "email": fake.email(),
            "verificado": random.choice([True, False])
        }
    else:
        detalles = {
            "cuenta": fake.bban(),
            "banco": fake.company()
        }
    
    cur.execute("""
        INSERT INTO metodos_pago (id_usuario, tipo, detalles, activo)
        VALUES (%s, %s, %s, %s)
    """, (user_id, tipo, json.dumps(detalles), random.choice([True, True, False])))

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
    
    cur.execute("""
        INSERT INTO equipos (nombre, pais, deporte, logo_url, fecha_fundacion, activo)
        VALUES (%s, %s, %s, %s, %s, %s) RETURNING id_equipo
    """, (
        f"{fake.city()} {fake.word().title()}", 
        random.choice(paises),
        random.choice(deportes),
        fake.image_url(width=200, height=200),
        fake.date_between(start_date='-50y', end_date='-1y'),
        random.choice([True, True, True, False])  # 75% activos
    ))
    equipo_ids.append(cur.fetchone()[0])

# ---------------------
# PATROCINADORES
# ---------------------
print(f"Insertando {NUM_PATROCINADORES} patrocinadores...")
patrocinador_ids = []
for i in range(NUM_PATROCINADORES):
    cur.execute("""
        INSERT INTO patrocinadores (nombre, logo_url, sitio_web, contacto_email, activo)
        VALUES (%s, %s, %s, %s, %s) RETURNING id_patrocinador
    """, (
        fake.company(),
        fake.image_url(width=300, height=100),
        fake.url(),
        fake.company_email(),
        random.choice([True, True, False])  # 67% activos
    ))
    patrocinador_ids.append(cur.fetchone()[0])

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
    if estado == 'pendiente':
        fecha_evento = fake.future_datetime(end_date="+60d")
    elif estado == 'en_vivo':
        fecha_evento = fake.date_time_between(start_date='-1h', end_date='+2h')
    else:  # finalizado o cancelado
        fecha_evento = fake.past_datetime(start_date='-30d')
    
    # Resultado del evento
    if estado == 'finalizado':
        resultado = {
            "marcador_local": random.randint(0, 5),
            "marcador_visitante": random.randint(0, 5),
            "estadisticas": {
                "posesion_local": random.randint(30, 70),
                "posesion_visitante": random.randint(30, 70)
            }
        }
    else:
        resultado = {}
    
    cur.execute("""
        INSERT INTO eventos (nombre_evento, deporte, fecha, resultado, estado)
        VALUES (%s, %s, %s, %s, %s) RETURNING id_evento
    """, (
        f"{fake.catch_phrase()} - {deporte}",
        deporte,
        fecha_evento,
        json.dumps(resultado),
        estado
    ))
    id_evento = cur.fetchone()[0]
    evento_ids.append(id_evento)
    
    # Relacionar evento con categoría
    categoria_evento = random.choice(categoria_ids)
    cur.execute("""
        INSERT INTO eventos_categorias (id_categoria, id_evento)
        VALUES (%s, %s)
    """, (categoria_evento, id_evento))
    
    # Equipos relacionados con el evento
    equipos_deporte = [eq for eq in equipo_ids if random.random() < 0.3]  # Filtro aproximado
    if len(equipos_deporte) >= 2:
        equipos_evento = random.sample(equipos_deporte, 2)
        for idx, equipo_id in enumerate(equipos_evento):
            puntuacion = 0
            if estado == 'finalizado' and resultado:
                puntuacion = resultado.get('marcador_local', 0) if idx == 0 else resultado.get('marcador_visitante', 0)
            
            cur.execute("""
                INSERT INTO evento_equipos (id_evento, id_equipo, es_local, puntuacion)
                VALUES (%s, %s, %s, %s)
            """, (id_evento, equipo_id, idx == 0, puntuacion))
    
    # Patrocinadores del evento (algunos eventos)
    if random.random() < 0.3:  # 30% de eventos tienen patrocinadores
        num_patrocinadores = random.randint(1, 3)
        patrocinadores_evento = random.sample(patrocinador_ids, min(num_patrocinadores, len(patrocinador_ids)))
        
        for patrocinador_id in patrocinadores_evento:
            cur.execute("""
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
        
        cur.execute("""
            INSERT INTO mercados (id_evento, tipo_mercado, cuota, estado)
            VALUES (%s, %s, %s, %s) RETURNING id_mercado
        """, (id_evento, tipo_mercado, cuota, estado_mercado))
        mercado_ids.append(cur.fetchone()[0])

# ---------------------
# COMENTARIOS DE EVENTOS
# ---------------------
print(f"Insertando {NUM_COMENTARIOS} comentarios...")
comentarios_ejemplo = [
    "¡Qué gran partido!", "Esperando un buen resultado", "El equipo local se ve fuerte",
    "Creo que será un empate", "¡Vamos mi equipo!", "Partido muy reñido",
    "Excelente cuota para apostar", "No me convence este mercado", "El árbitro está sesgado", "Esperando a que algo suceda... 🐱‍👤", 
     "Espero que no haya sorpresas", "Marcalo", "Necesitas algo?"
]

# Para evitar conflictos de PRIMARY KEY, solo insertamos un comentario por usuario-evento
comentarios_insertados = set()
for i in range(NUM_COMENTARIOS):
    if i % 1000 == 0:
        print(f"  Comentarios: {i}/{NUM_COMENTARIOS}")
    
    # Generar combinación única de usuario-evento
    max_intentos = 10
    for _ in range(max_intentos):
        user_id = random.choice(usuarios_ids)
        evento_id = random.choice(evento_ids)
        if (user_id, evento_id) not in comentarios_insertados:
            comentarios_insertados.add((user_id, evento_id))
            break
    else:
        continue  # Si no se pudo encontrar una combinación única, saltar
    
    cur.execute("""
        INSERT INTO comentarios_eventos (id_usuario, id_evento, comentario, fecha)
        VALUES (%s, %s, %s, %s)
    """, (
        user_id,
        evento_id,
        random.choice(comentarios_ejemplo) + " " + fake.sentence(),
        fake.date_time_between(start_date='-30d', end_date='now')
    ))

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
    cur.execute("SELECT cuota FROM mercados WHERE id_mercado = %s", (mercado_id,))
    cuota = cur.fetchone()[0]
    
    # Ganancia esperada
    ganancia_esperada = round(monto * float(cuota), 2)
    
    # Estado de la apuesta (basado en si el evento ya finalizó)
    cur.execute("""
        SELECT e.estado FROM eventos e 
        JOIN mercados m ON e.id_evento = m.id_evento 
        WHERE m.id_mercado = %s
    """, (mercado_id,))
    estado_evento = cur.fetchone()[0]
    
    if estado_evento == 'finalizado':
        estado_apuesta = random.choices(['ganada', 'perdida'], weights=[30, 70])[0]
    elif estado_evento == 'cancelado':
        estado_apuesta = 'anulada'
    else:
        estado_apuesta = 'pendiente'
    
    # Fecha de la apuesta
    fecha_apuesta = fake.date_time_between(start_date='-60d', end_date='now')
    
    cur.execute("""
        INSERT INTO apuestas (id_usuario, id_mercado, monto, ganancia_esperada, fecha, estado_apuesta)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (user_id, mercado_id, monto, ganancia_esperada, fecha_apuesta, estado_apuesta))

# ---------------------
# TRANSACCIONES
# ---------------------
print(f"Insertando {NUM_TRANSACCIONES} transacciones...")
tipos_transaccion = ['deposito', 'retiro', 'apuesta', 'ganancia']
estados_transaccion = ['completada', 'pendiente', 'fallida', 'cancelada']

for i in range(NUM_TRANSACCIONES):
    if i % 2000 == 0:
        print(f"  Transacciones: {i}/{NUM_TRANSACCIONES}")
    
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
        INSERT INTO transacciones (id_usuario, tipo_transaccion, monto, fecha, estado)
        VALUES (%s, %s, %s, %s, %s)
    """, (
        random.choice(usuarios_ids),
        tipo,
        monto,
        fake.date_time_between(start_date='-90d', end_date='now'),
        estado
    ))

# ---------------------
# HISTORIAL DE APUESTAS (JSON)
# ---------------------
print("Insertando historiales de apuestas...")
for user_id in random.sample(usuarios_ids, NUM_USUARIOS // 3):  # 1/3 de usuarios
    historial = {
        "total_apuestas": random.randint(1, 100),
        "total_ganado": round(random.uniform(0, 5000), 2),
        "total_perdido": round(random.uniform(0, 3000), 2),
        "deporte_favorito": random.choice(deportes),
        "racha_actual": random.randint(-5, 10),
        "mejor_racha": random.randint(1, 15)
    }
    
    cur.execute("""
        INSERT INTO historial_apuestas (id_usuario, historial)
        VALUES (%s, %s)
    """, (user_id, json.dumps(historial)))

# ---------------------
# LOGS JSON
# ---------------------
print("Insertando logs del sistema...")
tipos_log = ['login', 'apuesta_creada', 'deposito', 'retiro', 'error_sistema']

for _ in range(1000):
    tipo_log = random.choice(tipos_log)
    
    if tipo_log == 'login':
        datos = {
            "id_usuario": random.choice(usuarios_ids),
            "ip": fake.ipv4(),
            "user_agent": fake.user_agent(),
            "exitoso": random.choice([True, False])
        }
    elif tipo_log == 'apuesta_creada':
        datos = {
            "id_usuario": random.choice(usuarios_ids),
            "id_apuesta": random.randint(1, NUM_APUESTAS),
            "monto": round(random.uniform(5, 200), 2)
        }
    elif tipo_log in ['deposito', 'retiro']:
        datos = {
            "id_usuario": random.choice(usuarios_ids),
            "monto": round(random.uniform(20, 500), 2),
            "método": random.choice(['tarjeta', 'paypal', 'transferencia'])
        }
    else:  # error_sistema
        datos = {
            "error": fake.sentence(),
            "modulo": random.choice(['apuestas', 'pagos', 'usuarios', 'eventos']),
            "severidad": random.choice(['low', 'medium', 'high', 'critical'])
        }
    
    cur.execute("""
        INSERT INTO logs_json (tipo_log, datos)
        VALUES (%s, %s)
    """, (tipo_log, json.dumps(datos)))

# ---------------------
# CONFIRMAR Y CERRAR
# ---------------------
print("Confirmando transacciones...")
conn.commit()
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