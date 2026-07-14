const odbc = require('odbc');

const {
  DB_DRIVER = 'ODBC Driver 18 for SQL Server',
  DB_SERVER,
  DB_SQL_PORT = '1433',
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

const credentials = DB_USER
  ? `UID=${DB_USER};PWD=${DB_PASSWORD || ''};`
  : `Trusted_Connection=${DB_TRUSTED_CONNECTION};`;

const isFreeTds = DB_DRIVER.trim().toLowerCase() === 'freetds';
const connectionString = isFreeTds
  ? `Driver={${DB_DRIVER}};` +
    `Server=${DB_SERVER};Port=${DB_SQL_PORT};` +
    `Database=${DB_DATABASE};TDS_Version=7.4;ClientCharset=UTF-8;` +
    `LoginTimeout=${timeout};${credentials}`
  : `Driver={${DB_DRIVER}};` +
    `Server=${DB_SERVER};` +
    `Database=${DB_DATABASE};` +
    `Encrypt=${normalizarEncrypt(DB_ENCRYPT)};` +
    `TrustServerCertificate=${DB_TRUST_SERVER_CERTIFICATE};` +
    `Connection Timeout=${timeout};${credentials}`;

let poolInstance = null;
let poolClosing = false;

async function closePool() {
  if (poolClosing) return;
  poolClosing = true;
  if (poolInstance) {
    const p = poolInstance;
    poolInstance = null;
    try { await p.close(); } catch (_) {}
  }
}

async function getPool() {
  if (!poolInstance) {
    poolInstance = await odbc.pool(connectionString, {
      initialSize: 5,
      maxSize: 15,
      connectionTimeout: timeout * 1000,
    });

    if (isFreeTds) {
      habilitarParametrosFreeTds(poolInstance);
    }
  }
  return poolInstance;
}

process.on('SIGINT', async () => { await closePool(); process.exit(0); });
process.on('SIGTERM', async () => { await closePool(); process.exit(0); });

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

// FreeTDS no implementa SQLDescribeParam, función que node-odbc invoca antes
// de enlazar cualquier marcador "?". Para este driver únicamente se generan
// literales T-SQL escapados; el controlador Microsoft conserva parámetros ODBC.
function habilitarParametrosFreeTds(pool) {
  const conectar = pool.connect.bind(pool);

  pool.connect = async function conectarCompatible() {
    const conexion = await conectar();
    if (conexion.__parametrosFreeTds) return conexion;

    const consultar = conexion.query.bind(conexion);
    Object.defineProperty(conexion, '__parametrosFreeTds', { value: true });
    conexion.query = function queryCompatible(sql, params, ...rest) {
      if (!Array.isArray(params) || params.length === 0) {
        return consultar(sql, params, ...rest);
      }
      return consultar(interpolarParametros(sql, params), null, ...rest);
    };
    return conexion;
  };
}

function interpolarParametros(sql, params) {
  let resultado = '';
  let indice = 0;
  let estado = 'normal';

  for (let i = 0; i < sql.length; i += 1) {
    const actual = sql[i];
    const siguiente = sql[i + 1];

    if (estado === 'normal') {
      if (actual === "'") estado = 'cadena';
      else if (actual === '"') estado = 'identificador';
      else if (actual === '[') estado = 'corchete';
      else if (actual === '-' && siguiente === '-') estado = 'comentario-linea';
      else if (actual === '/' && siguiente === '*') estado = 'comentario-bloque';
      else if (actual === '?') {
        if (indice >= params.length) {
          throw new Error('Faltan valores para los parámetros SQL');
        }
        resultado += literalSql(params[indice]);
        indice += 1;
        continue;
      }
    } else if (estado === 'cadena' && actual === "'") {
      if (siguiente === "'") {
        resultado += actual + siguiente;
        i += 1;
        continue;
      }
      estado = 'normal';
    } else if (estado === 'identificador' && actual === '"') {
      if (siguiente === '"') {
        resultado += actual + siguiente;
        i += 1;
        continue;
      }
      estado = 'normal';
    } else if (estado === 'corchete' && actual === ']') {
      if (siguiente === ']') {
        resultado += actual + siguiente;
        i += 1;
        continue;
      }
      estado = 'normal';
    } else if (estado === 'comentario-linea' && (actual === '\n' || actual === '\r')) {
      estado = 'normal';
    } else if (estado === 'comentario-bloque' && actual === '*' && siguiente === '/') {
      resultado += actual + siguiente;
      i += 1;
      estado = 'normal';
      continue;
    }

    resultado += actual;
  }

  if (indice !== params.length) {
    throw new Error(`Sobran ${params.length - indice} valores para los parámetros SQL`);
  }
  return resultado;
}

function literalSql(value) {
  if (value === null || value === undefined) return 'NULL';
  if (typeof value === 'boolean') return value ? '1' : '0';
  if (typeof value === 'bigint') return value.toString();
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) throw new TypeError('Parámetro numérico SQL inválido');
    return value.toString();
  }
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) throw new TypeError('Parámetro de fecha SQL inválido');
    return `CONVERT(datetime2(7), '${value.toISOString()}', 127)`;
  }
  if (Buffer.isBuffer(value)) return `0x${value.toString('hex')}`;

  const text = typeof value === 'string' ? value : JSON.stringify(value);
  return `N'${String(text).replace(/'/g, "''")}'`;
}
