const express = require("express");
const cors = require("cors");
const { getConnection, KEYS, TTL, saveHash, getHash } = require("./config");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// Endpoint: GET /mercados/:id usando Redis HASH
app.get("/mercados", async (req, res) => {
  const mercadoId = req.params.id;
  const key = KEYS.MERCADO(mercadoId);

  try {
    const cached = await getHash(key, "data");
    if (cached) {
      return res.json({ source: "cache", data: cached });
    }

    const conn = await getConnection();
    const [rows] = await conn.execute("SELECT * FROM mercados");
    await conn.end();

    if (!rows.length) {
      return res.status(404).json({ error: "Mercado no encontrado" });
    }

    const mercado = rows;

    await saveHash(key, { data: JSON.stringify(mercado) }, TTL.MERCADOS.MAX);

    res.json({ source: "db", data: mercado });
  } catch (err) {
    console.error("Error en /mercados/:id:", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

app.listen(PORT, () => {
  console.log(`API escuchando en http://localhost:${PORT}`);
});
