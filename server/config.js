const postgres = require("postgres");
const { createClient } = require("redis");

// TTL Constants (in seconds)
const TTL = {
  MERCADOS: {
    MIN: 30,
    MAX: 60,
  },
  EVENTOS: {
    MIN: 300, // 5 minutes
    MAX: 600, // 10 minutes
  },
  USUARIOS: {
    MIN: 600, // 10 minutes
    MAX: 1200, // 20 minutes
  },
  HISTORIAL: {
    MIN: 1800, // 30 minutes
    MAX: 3600, // 1 hour
  },
};

const db = postgres("postgres://user:password@localhost:5432/postgres", {
  host: "localhost",
  port: 5432,
  database: process.env.DB_NAME || "apuestas_db",
  username: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres_password",
});

// Redis client configuration
const redis = createClient({
  url: "redis://localhost:6379",
});

redis.connect().catch(console.error);

const saveRedis = async (key, value) => {
  try {
    await redis.set(key, JSON.stringify(value));
    console.log(`Cache saved for key: ${key}`);
  } catch (error) {
    console.error(`Error saving cache for key ${key}:`, error);
  }
};

const getRedis = async (key) => {
  try {
    const data = await redis.get(key);
    if (data) {
      console.log(`Cache hit for key: ${key}`);
      return JSON.parse(data);
    } else {
      console.log(`Cache miss for key: ${key}`);
      return null;
    }
  } catch (error) {
    console.error(`Error getting cache for key ${key}:`, error);
    return null;
  }
};

// Hash operations for mercados y usuarios
const saveHash = async (key, data, category = "USUARIOS") => {
  try {
    await redis.hSet(key, data);
    await redis.expire(key, TTL[category].MAX);
    console.log(`Hash saved for key: ${key} with TTL: ${TTL[category].MAX}s`);
  } catch (error) {
    console.error(`Error saving hash for key ${key}:`, error);
  }
};

const getHash = async (key, field) => {
  try {
    const data = await redis.hGet(key, field);
    return data ? JSON.parse(data) : null;
  } catch (error) {
    console.error(`Error getting hash for key ${key}:`, error);
    return null;
  }
};

// Set operations for mercados activos y eventos
const addToSet = async (key, members, category = "EVENTOS") => {
  try {
    await redis.sAdd(key, members);
    await redis.expire(key, TTL[category].MIN);
    console.log(`Added to set ${key} with TTL: ${TTL[category].MIN}s`);
  } catch (error) {
    console.error(`Error adding to set ${key}:`, error);
  }
};

const getSetMembers = async (key) => {
  try {
    return await redis.sMembers(key);
  } catch (error) {
    console.error(`Error getting set ${key} members:`, error);
    return [];
  }
};

// List operations for historial y notificaciones
const addToList = async (key, value, category = "HISTORIAL") => {
  try {
    await redis.lPush(key, JSON.stringify(value));
    await redis.expire(key, TTL[category].MAX);
    // Trim list to keep only last 100 items
    await redis.lTrim(key, 0, 99);
    console.log(`Added to list ${key} with TTL: ${TTL[category].MAX}s`);
  } catch (error) {
    console.error(`Error adding to list ${key}:`, error);
  }
};

const getList = async (key, start = 0, end = -1) => {
  try {
    const items = await redis.lRange(key, start, end);
    return items.map((item) => JSON.parse(item));
  } catch (error) {
    console.error(`Error getting list ${key}:`, error);
    return [];
  }
};

// Example key patterns
const KEYS = {
  MERCADO: (id) => `mercado:${id}`,
  USUARIO: (id) => `usuario:${id}`,
  MERCADOS_ACTIVOS: "mercados:activos",
  EVENTOS_PROXIMOS: "eventos:proximos",
  HISTORIAL_APUESTAS: (userId) => `historial:${userId}`,
  NOTIFICACIONES: (userId) => `notificaciones:${userId}`,
};

module.exports = {
  db,
  redis,
  TTL,
  KEYS,
  // Hash operations
  saveHash,
  getHash,
  // Set operations
  addToSet,
  getSetMembers,
  // List operations
  addToList,
  getList,
  // Cache operations
  saveRedis,
  getRedis,
};
