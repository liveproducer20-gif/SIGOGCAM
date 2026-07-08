const sql = require('msnodesqlv8');

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

// Adapter que expone la misma interfaz que usaba node-odbc (promesas,
// conexion.query(sql, params), conexion.close, transaction) pero sobre
// msnodesqlv8, el cual maneja NVARCHAR/UTF-16 de forma nativa y evita que
// los acentidos se conviertan en el caracter de reemplazo (U+FFFD / '�').
function openConnection() {
  return new Promise((resolve, reject) => {
    sql.open(connectionString, (err, conn) => {
      if (err) return reject(err);
      resolve(conn);
    });
  });
}

function queryOn(conn, sqlText, params) {
  return new Promise((resolve, reject) => {
    conn.query(sqlText, params || [], (err, rows) => {
      if (err) return reject(err);
      resolve(rows || []);
    });
  });
}

function beginTransaction(conn) {
  return new Promise((resolve, reject) => {
    conn.beginTransaction((err) => (err ? reject(err) : resolve()));
  });
}

function commit(conn) {
  return new Promise((resolve, reject) => {
    conn.commit((err) => (err ? reject(err) : resolve()));
  });
}

function rollback(conn) {
  return new Promise((resolve) => {
    conn.rollback(() => resolve());
  });
}

// Pool simple: mantiene una unica conexion abierta reutilizable.
// msnodesqlv8 gestiona internamente la conexion; para mayor concurrencia
// se abre una conexion por operacion (open es rapido y maneja Unicode bien).
let poolInstance = null;

async function getPool() {
  if (!poolInstance) {
    poolInstance = {
      async connect() {
        const conn = await openConnection();
        return {
          query: (sqlText, params) => queryOn(conn, sqlText, params),
          beginTransaction: () => beginTransaction(conn),
          commit: () => commit(conn),
          rollback: () => rollback(conn),
          close: () => new Promise((res) => conn.close(() => res())),
        };
      },
    };

    process.on('exit', () => {
      // msnodesqlv8 cierra las conexiones al salir del proceso.
    });
  }
  return poolInstance;
}

async function query(sqlText, params) {
  const conn = await openConnection();
  try {
    return await queryOn(conn, sqlText, params);
  } finally {
    await new Promise((res) => conn.close(() => res()));
  }
}

async function transaction(callback) {
  const conn = await openConnection();
  try {
    await beginTransaction(conn);
    const result = await callback({
      query: (sqlText, params) => queryOn(conn, sqlText, params),
    });
    await commit(conn);
    return result;
  } catch (error) {
    await rollback(conn);
    throw error;
  } finally {
    await new Promise((res) => conn.close(() => res()));
  }
}

module.exports = {
  sql,
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
