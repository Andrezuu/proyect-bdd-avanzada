const { exec } = require("child_process");
const path = require("path");

const execCommand = (command) => {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(stderr || error.message);
        return;
      }
      resolve(stdout.trim());
    });
  });
};

const POSTGRES_CONTAINER =
  process.env.POSTGRES_CONTAINER || "apuestas_postgres_primary";
const POSTGRES_USER = process.env.POSTGRES_USER || "postgres";
const POSTGRES_DB = process.env.POSTGRES_DB || "apuestas_db";
const POSTGRES_PASSWORD = process.env.POSTGRES_PASSWORD || "postgres_password";

const MYSQL_CONTAINER = process.env.MYSQL_CONTAINER || "apuestas_mysql";
const MYSQL_ROOT_PASSWORD = process.env.MYSQL_ROOT_PASSWORD || "mysql_password";

const MONGO_ROUTER_CONTAINER =
  process.env.MONGO_ROUTER_CONTAINER || "mongo_router";

const REDIS_CONTAINER = process.env.REDIS_CONTAINER || "apuestas_redis";

const BACKUP_BASE_DIR = path.join(__dirname, "backups");

const getLatestBackupFolder = async () => {
  const ls = await execCommand(`ls -td ${BACKUP_BASE_DIR}/* | head -n 1`);
  return ls;
};

const restorePostgres = async () => {
  console.log("Restaurando PostgreSQL...");
  try {
    const latestBackupDir = await getLatestBackupFolder();
    const backupFile = path.join(latestBackupDir, "postgres_backup.dump");

    await execCommand(
      `docker exec -u postgres -e PGPASSWORD=${POSTGRES_PASSWORD} ${POSTGRES_CONTAINER} sh -c "createdb -U ${POSTGRES_USER} ${POSTGRES_DB} 2>/dev/null || true"`
    );

    await execCommand(
      `docker cp ${backupFile} ${POSTGRES_CONTAINER}:/tmp/backup.dump`
    );

    await execCommand(
      `docker exec -u postgres -e PGPASSWORD=${POSTGRES_PASSWORD} ${POSTGRES_CONTAINER} pg_restore --clean --if-exists -U ${POSTGRES_USER} -d ${POSTGRES_DB} /tmp/backup.dump`
    );

    await execCommand(
      `docker exec -u postgres ${POSTGRES_CONTAINER} rm /tmp/backup.dump`
    );

    console.log("✅ PostgreSQL restaurado correctamente.");
  } catch (err) {
    console.error("Error restaurando PostgreSQL:", err);
  }
};

const restoreMySQL = async () => {
  console.log("Restaurando MySQL...");
  try {
    const latestBackupDir = await getLatestBackupFolder();
    const backupFile = path.join(latestBackupDir, "mysql_backup.sql");

    const restoreCmd = `cat ${backupFile} | docker exec -i ${MYSQL_CONTAINER} sh -c "mysql -u root -p'${MYSQL_ROOT_PASSWORD}'"`;

    await execCommand(restoreCmd);

    console.log("✅ MySQL restaurado correctamente.");
  } catch (err) {
    console.error("Error restaurando MySQL:", err);
  }
};

async function restoreMongo() {
  console.log("Restaurando MongoDB...");
  try {
    const latestBackupDir = await getLatestBackupFolder();
    const backupFile = path.join(latestBackupDir, "mongo_backup.archive");

    await execCommand(
      `docker cp ${backupFile} ${MONGO_ROUTER_CONTAINER}:/data/backup.archive`
    );

    await execCommand(
      `docker exec ${MONGO_ROUTER_CONTAINER} mongorestore --drop --gzip --archive=/data/backup.archive`
    );

    await execCommand(
      `docker exec ${MONGO_ROUTER_CONTAINER} rm /data/backup.archive`
    );

    console.log("✅ MongoDB restaurado correctamente.");
  } catch (err) {
    console.error("Error restaurando MongoDB:", err);
  }
}

const restoreRedis = async () => {
  console.log("Restaurando Redis...");
  try {
    const latestBackupDir = await getLatestBackupFolder();
    const backupFile = path.join(latestBackupDir, "redis_dump.rdb");

    await execCommand(
      `docker cp ${backupFile} ${REDIS_CONTAINER}:/data/dump.rdb`
    );

    await execCommand(`docker restart ${REDIS_CONTAINER}`);

    console.log("✅ Redis restaurado correctamente.");
  } catch (err) {
    console.error("Error restaurando Redis:", err);
  }
};

const main = async () => {
  await restorePostgres();
  await restoreMySQL();
  await restoreMongo();
  await restoreRedis();
  console.log("🎉 Restauración completa.");
};

main().catch(console.error);
