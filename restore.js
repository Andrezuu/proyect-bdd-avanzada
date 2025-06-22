const cron = require("cron");
const { exec } = require("child_process");
const dotenv = require("dotenv");

dotenv.config();
console.log("Restoring backup");
const dockerUser = process.env.DOCKER_USER || "postgres";
const dockerContainer = process.env.DOCKER_CONTAINER || "apuestas_postgres";
const user = process.env.DB_USER || "postgres";
const password = process.env.DB_PASSWORD;
const folder = process.env.BACKUP_FOLDER || "/tmp";
const restore_db = process.env.RESTORE_DB || "apuestas_db";
const createRestoreDbCommand = `docker exec -u ${dockerUser} -e PGPASSWORD=${password} ${dockerContainer} sh -c "createdb -U ${user} ${restore_db} 2>/dev/null || true"`;

exec(createRestoreDbCommand, (error, stderr) => {
  console.log("Trying to create the database if it does not exist");
  if (error) {
    console.error(`Error executing command: ${error.message}`);
    return;
  }
  if (stderr) {
    console.error(`Error output: ${stderr}`);
    return;
  }
  console.log("Database restored successfully or already exists.");
});

const restoreCommand = `docker exec -u ${dockerUser} -e PGPASSWORD=${password} ${dockerContainer} pg_restore --clean --if-exists -U ${user} -d ${restore_db} ${folder}/`;

const latestBackupCommand = `docker exec -u ${dockerUser} -e PGPASSWORD=${password} ${dockerContainer} sh -c "ls -t ${folder} | head -n 1"`;
exec(latestBackupCommand, (error, stdout, stderr) => {
  if (error) {
    console.error(`Error executing command: ${error.message}`);
    return;
  }
  if (stderr) {
    console.error(`Error output: ${stderr}`);
    return;
  }
  const latestBackup = stdout;
  console.log(`📁 Respaldo más reciente encontrado: ${latestBackup}`);
  exec(`${restoreCommand}${latestBackup}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error executing restore command: ${error.message}`);
      return;
    }
    if (stderr) {
      console.error(`Error output during restore: ${stderr}`);
      return;
    }
    console.log("✅ Base de datos restaurada correctamente.");
  });
});
