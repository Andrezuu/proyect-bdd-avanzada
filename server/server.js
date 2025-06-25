const express = require("express");
const cors = require("cors");
const {
  db,
  TTL,
  KEYS,
  saveHash,
  getHash,
  addToSet,
  getSetMembers,
  addToList,
  getList,
} = require("./config");

const app = express();
const PORT = process.env.PORT || 3000;
app.use(cors());
app.use(express.json());

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

app.get("/apuestas", async (req, res) => {
  try {
    if (await getRedis("get_apuestas")) {
      const data = await getRedis("get_apuestas");
      return res.json(data);
    } else {
      console.log("Cache miss for apuestas, fetching from database");
      const data = await db`SELECT * FROM apuestas`;
      await saveRedis("get_apuestas", data);
      return res.json(data);
    }
  } catch (error) {
    console.error("Error fetching apuestas:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// 1. Endpoint usando HASH para mercados

// 2. Endpoint usando SET para mercados activos
app.get("/mercados/activos", async (req, res) => {
  try {
    const cachedIds = await getSetMembers(KEYS.MERCADOS_ACTIVOS);

    if (cachedIds.length > 0) {
      const mercados = await db`
        SELECT * FROM mercados WHERE id_mercado = ANY(${cachedIds})
      `;
      return res.json(mercados);
    }

    const mercadosActivos = await db`
      select * from mercados where estado = true
    `;

    if (mercadosActivos.length > 0) {
      const ids = mercadosActivos.map((m) => m.id_mercado.toString());
      await addToSet(KEYS.MERCADOS_ACTIVOS, ids, "MERCADOS");
      return res.json(mercadosActivos);
    }

    res.json([]);
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

app.get("/mercados/:id", async (req, res) => {
  try {
    const mercadoKey = KEYS.MERCADO(req.params.id);
    const cachedMercado = await getHash(mercadoKey, "data");

    if (cachedMercado) {
      return res.json(cachedMercado);
    }

    const mercado = await db`
      SELECT * FROM mercados WHERE id_mercado = ${req.params.id}
    `;

    if (mercado[0]) {
      await saveHash(
        mercadoKey,
        { data: JSON.stringify(mercado[0]) },
        "MERCADOS"
      );
      return res.json(mercado[0]);
    }

    res.status(404).json({ error: "Mercado no encontrado" });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// 3. Endpoint usando LIST para historial de apuestas
app.get("/usuarios/:id/historial", async (req, res) => {
  try {
    const historialKey = KEYS.HISTORIAL_APUESTAS(req.params.id);
    const cachedHistorial = await getList(historialKey, 0, 9); // últimas 10

    if (cachedHistorial.length > 0) {
      return res.json(cachedHistorial);
    }

    const historial = await db`
      SELECT a.*, m.nombre as mercado_nombre, e.nombre_evento 
      FROM apuestas a
      JOIN mercados m ON a.id_mercado = m.id_mercado
      JOIN eventos e ON m.id_evento = e.id_evento
      WHERE a.id_usuario = ${req.params.id}
      ORDER BY a.created_at DESC
      LIMIT 10
    `;

    if (historial.length > 0) {
      await addToList(historialKey, historial, "HISTORIAL");
      return res.json(historial);
    }

    res.json([]);
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// 4. Endpoint combinando estructuras (usuario + notificaciones)
app.get("/usuarios/:id/dashboard", async (req, res) => {
  try {
    const userId = req.params.id;
    const [userHash, notifications] = await Promise.all([
      getHash(KEYS.USUARIO(userId), "data"),
      getList(KEYS.NOTIFICACIONES(userId), 0, 4),
    ]);

    let user;
    if (userHash) {
      user = JSON.parse(userHash);
    } else {
      user = (
        await db`
        SELECT u.*, r.nombre_rol 
        FROM usuarios u 
        JOIN usuario_rol ur ON u.id_usuario = ur.id_usuario
        JOIN roles r ON ur.id_rol = r.id_rol
        WHERE u.id_usuario = ${userId}
      `
      )[0];

      if (user) {
        await saveHash(
          KEYS.USUARIO(userId),
          { data: JSON.stringify(user) },
          "USUARIOS"
        );
      }
    }

    if (!user) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    // Agregar nueva notificación al inicio de la lista
    if (user.saldo < 100) {
      await addToList(KEYS.NOTIFICACIONES(userId), {
        mensaje: "Tu saldo está bajo",
        tipo: "alerta",
        fecha: new Date(),
      });
    }

    res.json({
      user,
      notifications: notifications || [],
    });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});
