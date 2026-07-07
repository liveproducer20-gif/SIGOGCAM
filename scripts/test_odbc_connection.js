const odbc = require('../backend/node_modules/odbc');

const variants = [
  {
    name: 'Driver 18 Encrypt=no localhost',
    value: 'Driver={ODBC Driver 18 for SQL Server};Server=localhost\\SQLEXPRESS;Database=BITSAC;Encrypt=no;TrustServerCertificate=yes;Trusted_Connection=yes;',
  },
  {
    name: 'Driver 18 Encrypt=no hostname',
    value: 'Driver={ODBC Driver 18 for SQL Server};Server=LAPTOP-JC\\SQLEXPRESS;Database=BITSAC;Encrypt=no;TrustServerCertificate=yes;Trusted_Connection=yes;',
  },
  {
    name: 'Driver 17 Encrypt=no localhost',
    value: 'Driver={ODBC Driver 17 for SQL Server};Server=localhost\\SQLEXPRESS;Database=BITSAC;Encrypt=no;TrustServerCertificate=yes;Trusted_Connection=yes;',
  },
  {
    name: 'Driver 17 Encrypt=no hostname',
    value: 'Driver={ODBC Driver 17 for SQL Server};Server=LAPTOP-JC\\SQLEXPRESS;Database=BITSAC;Encrypt=no;TrustServerCertificate=yes;Trusted_Connection=yes;',
  },
  {
    name: 'Legacy SQL Server local',
    value: 'Driver={SQL Server};Server=localhost\\SQLEXPRESS;Database=BITSAC;Trusted_Connection=yes;',
  },
  {
    name: 'Legacy SQL Server hostname',
    value: 'Driver={SQL Server};Server=LAPTOP-JC\\SQLEXPRESS;Database=BITSAC;Trusted_Connection=yes;',
  },
  {
    name: 'Driver 18 named pipe',
    value: 'Driver={ODBC Driver 18 for SQL Server};Server=np:\\\\.\\pipe\\MSSQL$SQLEXPRESS\\sql\\query;Database=BITSAC;Encrypt=no;TrustServerCertificate=yes;Trusted_Connection=yes;',
  },
  {
    name: 'Legacy named pipe',
    value: 'Driver={SQL Server};Server=np:\\\\.\\pipe\\MSSQL$SQLEXPRESS\\sql\\query;Database=BITSAC;Trusted_Connection=yes;',
  },
];

async function main() {
  for (const variant of variants) {
    process.stdout.write(`Probando ${variant.name}... `);
    let connection;
    try {
      connection = await odbc.connect(variant.value);
      const rows = await connection.query('SELECT DB_NAME() AS db');
      console.log(`OK (${rows[0].db})`);
      console.log(`CADENA=${variant.value}`);
      return;
    } catch (error) {
      console.log(`FALLO: ${error.message}`);
      if (error.odbcErrors) {
        console.log(JSON.stringify(error.odbcErrors));
      }
    } finally {
      if (connection) await connection.close();
    }
  }

  process.exitCode = 1;
}

main();
