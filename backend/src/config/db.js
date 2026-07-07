const odbc = require('odbc');

const {
  DB_DRIVER = 'ODBC Driver 18 for SQL Server',
  DB_SERVER,
  DB_DATABASE,
  DB_USER,
  DB_PASSWORD,
  DB_TRUSTED_CONNECTION = 'Yes',
  DB_TRUST_SERVER_CERTIFICATE = 'Yes',
  DB_ENCRYPT = 'no',
  DB_CONNECTION_TIMEOUT = '15',
} = process.env;

if (!DB_SERVER || !DB_DATABASE) {
  throw new Error('Faltan variables de entorno DB_SERVER o DB_DATABASE');
}

const connectionString =
  `Driver={${DB_DRIVER}};` +
  `Server=${DB_SERVER};` +
  `Database=${DB_DATABASE};` +
  `Encrypt=${normalizarEncrypt(DB_ENCRYPT)};` +
  `TrustServerCertificate=${DB_TRUST_SERVER_CERTIFICATE};` +
  `Connection Timeout=${DB_CONNECTION_TIMEOUT};` +
  (
    DB_USER
      ? `UID=${DB_USER};PWD=${DB_PASSWORD || ''};`
      : `Trusted_Connection=${DB_TRUSTED_CONNECTION};`
  );

module.exports = {
  odbc,
  connectionString,
};

function normalizarEncrypt(value) {
  const text = (value || '').toString().trim().toLowerCase();

  if (['false', '0', 'no', 'none', 'disabled'].includes(text)) {
    return 'no';
  }

  if (['true', '1', 'yes', 'mandatory', 'required'].includes(text)) {
    return 'yes';
  }

  if (text === 'optional') {
    return 'no';
  }

  return text || 'no';
}
