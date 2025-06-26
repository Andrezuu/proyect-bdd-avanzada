const mysql = require("mysql2/promise");
const { createClient } = require("redis");

const dbConfig = {
  host: "localhost",
  port: 3306,
  user: "root",
  password: "mysql_password",
  database: "apuestas_db",
};

const getConnection = async () => {
  return await mysql.createConnection(dbConfig);
};

const redis = createClient({ url: "redis://localhost:6379" });
redis.connect().catch(console.error);

const TTL = {
  MERCADOS: { MAX: 60 }, // 60 segundos
};

const KEYS = {
  MERCADO: (id) => `mercado:${id}`,
};

const saveHash = async (key, data, ttl = 60) => {
  try {
    await redis.hSet(key, data);
    await redis.expire(key, ttl);
  } catch (err) {
    console.error("Redis saveHash error:", err);
  }
};

const getHash = async (key, field) => {
  try {
    const value = await redis.hGet(key, field);
    return value ? JSON.parse(value) : null;
  } catch (err) {
    console.error("Redis getHash error:", err);
    return null;
  }
};

module.exports = { getConnection, redis, TTL, KEYS, saveHash, getHash };
