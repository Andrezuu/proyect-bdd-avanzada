const cron = require("cron");
const { exec } = require("child_process");
const dotenv = require("dotenv");

dotenv.config();
const job = new cron.CronJob(
  "*/1 * * * *", // cronTime
  function () {
    console.log("Creating backup");
    const dockerUser = "postgres";
    const dockerContainer = "apuestas_postgres";
    const user = "postgres";
    const database = "apuestas_db";
    const folder = "/tmp";
    const currentDate = new Date();
    const fileName = `backup_${currentDate.toISOString()}.dump`;
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
