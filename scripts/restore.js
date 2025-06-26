const { exec } = require("child_process");
const path = require("path");
const fs = require("fs");

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

const POSTGRES_CONTAINER = "apuestas_postgres_primary";
const POSTGRES_USER = "postgres";
const POSTGRES_DB = "apuestas_db";
const POSTGRES_PASSWORD = "postgres_password";

const MYSQL_CONTAINER = "apuestas_mysql";
const MYSQL_ROOT_PASSWORD = "mysql_password";

const MONGO_ROUTER_CONTAINER = "mongo_router";
const REDIS_CONTAINER = "apuestas_redis";

const BACKUP_BASE_DIR = path.join(__dirname, "backups");

const getLatestBackupFolder = () => {
  if (!fs.existsSync(BACKUP_BASE_DIR)) {
    throw new Error(`Directorio de backups no existe: ${BACKUP_BASE_DIR}`);
  }
  
  const folders = fs.readdirSync(BACKUP_BASE_DIR)
    .map(name => ({
      name,
      fullPath: path.join(BACKUP_BASE_DIR, name),
      time: fs.statSync(path.join(BACKUP_BASE_DIR, name)).mtime.getTime()
    }))
    .filter(item => fs.statSync(item.fullPath).isDirectory())
    .sort((a, b) => b.time - a.time);
  
  if (folders.length === 0) {
    throw new Error("No se encontraron carpetas de backup");
  }
  
  return folders[0].fullPath;
};

async function restorePostgres() {
  console.log("Restaurando PostgreSQL...");
  const latestBackupDir = getLatestBackupFolder();
  const backupFile = path.join(latestBackupDir, "postgres_backup.dump");
  
  await execCommand(`docker cp "${backupFile}" ${POSTGRES_CONTAINER}:/tmp/backup.dump`);
  await execCommand(`docker exec -e PGPASSWORD=${POSTGRES_PASSWORD} ${POSTGRES_CONTAINER} pg_restore --clean --if-exists -U ${POSTGRES_USER} -d ${POSTGRES_DB} /tmp/backup.dump`);
  console.log("✅ PostgreSQL restaurado");
}

const restoreMySQL = async () => {
  console.log("Restaurando MySQL...");
  const latestBackupDir = getLatestBackupFolder();
  const backupFile = path.join(latestBackupDir, "mysql_backup.sql");
  
  const catCommand = process.platform === 'win32' ? 'type' : 'cat';
  await execCommand(`${catCommand} "${backupFile}" | docker exec -i ${MYSQL_CONTAINER} mysql -u root -p${MYSQL_ROOT_PASSWORD}`);
  console.log("✅ MySQL restaurado");
}

const restoreMongo = async () => {
  console.log("Restaurando MongoDB...");
  const latestBackupDir = getLatestBackupFolder();
  const backupFile = path.join(latestBackupDir, "mongo_backup.archive");
  
  await execCommand(`docker cp "${backupFile}" ${MONGO_ROUTER_CONTAINER}:/tmp/backup.archive`);
  await execCommand(`docker exec ${MONGO_ROUTER_CONTAINER} mongorestore --drop --gzip --archive=/tmp/backup.archive --nsExclude="config.*"`);
  await execCommand(`docker exec ${MONGO_ROUTER_CONTAINER} rm /tmp/backup.archive`);
  console.log("✅ MongoDB restaurado");
}

const restoreRedis = async () => {
  console.log("Restaurando Redis...");
  const latestBackupDir = getLatestBackupFolder();
  const backupFile = path.join(latestBackupDir, "redis_dump.rdb");
  
  await execCommand(`docker cp "${backupFile}" ${REDIS_CONTAINER}:/data/dump.rdb`);
  await execCommand(`docker restart ${REDIS_CONTAINER}`);
  console.log("✅ Redis restaurado");
}

const main = async () => {
  try {
    await restorePostgres();
    await restoreMySQL();
    await restoreMongo();
    await restoreRedis();
    console.log("🎉 Restauración completa");
  } catch (error) {
    console.error("Error:", error);
  }
}

main();