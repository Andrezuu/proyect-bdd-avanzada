const { exec } = require("child_process");
const path = require("path");
const fs = require("fs");
const cron = require("cron");

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
const ETL_CONTAINER = "apuestas_postgres_etl";
const ETL_USER = "etl_user";
const ETL_DB = "etl_db";
const ETL_PASSWORD = "etl_password";

const BACKUP_BASE_DIR = path.join(__dirname, "backups");

const generateBackupDir = () => {
  const now = new Date();
  const timestamp = now
    .toISOString()
    .replace(/[-:]/g, "")
    .replace(/\..+/, "")
    .replace("T", "_");
  const backupDir = path.join(BACKUP_BASE_DIR, timestamp);

  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  return backupDir;
};

const backupPostgres = async (backupDir) => {
  console.log("Backing up PostgreSQL...");
  const dumpFile = path.join(backupDir, "postgres_backup.dump");

  try {
    await execCommand(
      `docker exec -u postgres -e PGPASSWORD=${POSTGRES_PASSWORD} ${POSTGRES_CONTAINER} pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} -F c > "${dumpFile}"`
    );
    console.log("✅ PostgreSQL backup completed.");
  } catch (error) {
    console.error("PostgreSQL backup error:", error);
    throw error;
  }
};

const backupMySQL = async (backupDir) => {
  console.log("Backing up MySQL...");
  const dumpFile = path.join(backupDir, "mysql_backup.sql");

  try {
    await execCommand(
      `docker exec ${MYSQL_CONTAINER} mysqldump -u root -p${MYSQL_ROOT_PASSWORD} --all-databases > "${dumpFile}"`
    );
    console.log("✅ MySQL backup completed.");
  } catch (error) {
    console.error("MySQL backup error:", error);
    throw error;
  }
};

const backupMongo = async (backupDir) => {
  console.log("Backing up MongoDB (sharded cluster)...");
  const dumpFile = path.join(backupDir, "mongo_backup.archive");

  try {
    await execCommand(
      `docker exec ${MONGO_ROUTER_CONTAINER} mongodump --gzip --archive=/tmp/backup.archive`
    );
    await execCommand(
      `docker cp ${MONGO_ROUTER_CONTAINER}:/tmp/backup.archive "${dumpFile}"`
    );
    await execCommand(
      `docker exec ${MONGO_ROUTER_CONTAINER} rm /tmp/backup.archive`
    );
    console.log("✅ MongoDB backup completed.");
  } catch (error) {
    console.error("MongoDB backup error:", error);
    throw error;
  }
};

const backupRedis = async (backupDir) => {
  console.log("Backing up Redis...");
  const dumpFile = path.join(backupDir, "redis_dump.rdb");

  try {
    // Forzar un BGSAVE para asegurar que el dump.rdb esté actualizado
    await execCommand(`docker exec ${REDIS_CONTAINER} redis-cli BGSAVE`);

    // Esperar un poco para que termine el BGSAVE
    await new Promise((resolve) => setTimeout(resolve, 2000));

    await execCommand(
      `docker cp ${REDIS_CONTAINER}:/data/dump.rdb "${dumpFile}"`
    );
    console.log("✅ Redis backup completed.");
  } catch (error) {
    console.error("Redis backup error:", error);
    throw error;
  }
};

const backupETL = async (backupDir) => {
  console.log("Backing up ETL...");
  const dumpFile = path.join(backupDir, "etl_backup.dump");

  try {
    await execCommand(
      `docker exec -u postgres -e PGPASSWORD=${ETL_PASSWORD} ${ETL_CONTAINER} pg_dump -U ${ETL_USER} ${ETL_DB} -F c > "${dumpFile}"`
    );
    console.log("✅ ETL backup completed.");
  } catch (error) {
    console.error("ETL backup error:", error);
    throw error;
  }
};

const main = async () => {
  try {
    console.log("Backup job started.");
    const backupDir = generateBackupDir();
    console.log(
      `Starting backup at ${path.basename(backupDir)} in folder ${backupDir}`
    );

    await backupPostgres(backupDir);
    await backupMySQL(backupDir);
    await backupMongo(backupDir);
    await backupRedis(backupDir);
    await backupETL(backupDir);

    console.log("🎉 All backups completed.");
    console.log(`Backup saved in: ${backupDir}`);
  } catch (error) {
    console.error("Backup failed:", error);
    process.exit(1);
  }
};
const job = new cron.CronJob(
  "* * * * *",
  () => main().catch(console.error),
  null
);

job.start();
console.log("Backup job started.");
