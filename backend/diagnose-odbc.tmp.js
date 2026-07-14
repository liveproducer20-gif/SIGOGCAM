const odbc = require('odbc');

const connectionString =
  `Driver={${process.env.DB_DRIVER}};` +
  `Server=${process.env.DB_SERVER};` +
  `Database=${process.env.DB_DATABASE};` +
  `Encrypt=${process.env.DB_ENCRYPT};` +
  `TrustServerCertificate=${process.env.DB_TRUST_SERVER_CERTIFICATE};` +
  'Connection Timeout=5;' +
  `UID=${process.env.DB_USER};PWD=${process.env.DB_PASSWORD};`;

odbc.connect(connectionString)
  .then(async (connection) => {
    console.log('connected');
    await connection.close();
    process.exit(0);
  })
  .catch((error) => {
    console.error(JSON.stringify(error.odbcErrors || error.message));
    process.exit(1);
  });
