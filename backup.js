const cron = require("cron");
const { exec } = require("child_process");
const dotenv = require("dotenv");
const dayjs = require("dayjs");

dotenv.config();
const job = new cron.CronJob(
  "*/1 * * * *", // cronTime
  function () {
    console.log("Creating backup");
    const dockerUser = process.env.DOCKER_USER || "postgres"
    const dockerContainer = process.env.DOCKER_CONTAINER || "apuestas_postgres";
    const user = process.env.DB_USER || "postgres";
    const database = process.env.DB_NAME || "apuestas_db";
    const folder = process.env.BACKUP_FOLDER || "/tmp";
    const fileName = `backup_${dayjs().format("YYYYMMDD_HHmmss")}.dump`;
    const backupCommand = `docker exec -u ${dockerUser} ${dockerContainer} \
         pg_dump -U ${user} -F c -d ${database} -f ${folder}/${fileName}`;
    const copyCommand = `docker cp ${dockerContainer}:/tmp/${fileName} ./backups/${fileName}`;
    exec(backupCommand, (error, stdout, stderr) => {
      if (error) {
        console.error(`Error executing command: ${error.message}`);
        return;
      }
      if (stderr) {
        console.error(`Error output: ${stderr}`);
        return;
      }
      console.log(`Backup successful ${stdout}`);
      exec(copyCommand, (error, stdout, stderr) => {
        if (error) {
          console.error(`Error executing command: ${error.message}`);
          return;
        }
        if (stderr) {
          console.error(`Error output: ${stderr}`);
          return;
        }
        console.log(`Copied Backup successfully: ${stdout}`);
      });
    });
  }, // onTick
  true // start
);
job.start();
console.log("Cron job started.");
