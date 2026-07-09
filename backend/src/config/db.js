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

const errores = [];
if (!DB_SERVER) errores.push('DB_SERVER');
if (!DB_DATABASE) errores.push('DB_DATABASE');
if (!DB_DRIVER) errores.push('DB_DRIVER');
const timeout = parseInt(DB_CONNECTION_TIMEOUT, 10);
if (isNaN(timeout) || timeout < 1 || timeout > 120) {
  errores.push('DB_CONNECTION_TIMEOUT (debe ser 1-120)');
}
if (errores.length > 0) {
  throw new Error('Variables de entorno inválidas: ' + errores.join(', '));
}

const connectionString =
  `Driver={${DB_DRIVER}};` +
  `Server=${DB_SERVER};` +
  `Database=${DB_DATABASE};` +
  `Encrypt=${normalizarEncrypt(DB_ENCRYPT)};` +
  `TrustServerCertificate=${DB_TRUST_SERVER_CERTIFICATE};` +
  `Connection Timeout=${timeout};` +
  (
    DB_USER
      ? `UID=${DB_USER};PWD=${DB_PASSWORD || ''};`
      : `Trusted_Connection=${DB_TRUSTED_CONNECTION};`
  );

let poolInstance = null;

async function getPool() {
  if (!poolInstance) {
    poolInstance = await odbc.pool(connectionString, {
      initialSize: 15,
      maxSize: 30,
      connectionTimeout: timeout * 1000,
    });

    process.on('exit', async () => {
      if (poolInstance) {
        try { await poolInstance.close(); } catch (_) {}
      }
    });
  }
  return poolInstance;
}

async function query(sql, params) {
  const pool = await getPool();
  const conexion = await pool.connect();
  try {
    return await conexion.query(sql, params);
  } finally {
    await conexion.close();
  }
}

async function transaction(callback) {
  const pool = await getPool();
  const conexion = await pool.connect();
  try {
    await conexion.beginTransaction();
    const result = await callback(conexion);
    await conexion.commit();
    return result;
  } catch (error) {
    try { await conexion.rollback(); } catch (_) {}
    throw error;
  } finally {
    await conexion.close();
  }
}

module.exports = {
  odbc,
  connectionString,
  getPool,
  query,
  transaction,
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
