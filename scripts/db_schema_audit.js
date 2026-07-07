const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
loadEnv(path.join(root, 'backend', '.env'));
process.env.DB_ENCRYPT = 'No';
const { odbc, connectionString } = require('../backend/src/config/db');
const appRoots = [
  path.join(root, 'backend', 'src'),
  path.join(root, 'backend', 'index.js'),
  path.join(root, 'mobile', 'lib'),
];

function readFiles(target) {
  if (!fs.existsSync(target)) return [];
  const stat = fs.statSync(target);
  if (stat.isFile()) return [target];

  return fs.readdirSync(target, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(target, entry.name);
    if (entry.isDirectory()) {
      if (['node_modules', '.dart_tool', 'build'].includes(entry.name)) return [];
      return readFiles(full);
    }
    if (!/\.(js|dart)$/i.test(entry.name)) return [];
    return [full];
  });
}

function hasWord(source, word) {
  const escaped = word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`(^|[^A-Za-z0-9_])${escaped}([^A-Za-z0-9_]|$)`, 'i').test(source);
}

function loadEnv(envPath) {
  if (!fs.existsSync(envPath)) return;
  const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const index = trimmed.indexOf('=');
    if (index <= 0) continue;
    const key = trimmed.substring(0, index).trim();
    const value = trimmed.substring(index + 1).trim().replace(/^['"]|['"]$/g, '');
    if (!process.env[key]) process.env[key] = value;
  }
}

async function main() {
  const files = appRoots.flatMap(readFiles);
  const source = files.map((file) => fs.readFileSync(file, 'utf8')).join('\n');
  let connection;
  try {
    connection = await odbc.connect(connectionString);
    const objects = await connection.query(`
      SELECT TABLE_NAME AS name, TABLE_TYPE AS type
      FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_SCHEMA = 'dbo'
      ORDER BY TABLE_TYPE, TABLE_NAME
    `);
    const columns = await connection.query(`
      SELECT TABLE_NAME AS table_name, COLUMN_NAME AS column_name, DATA_TYPE AS data_type
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'dbo'
      ORDER BY TABLE_NAME, ORDINAL_POSITION
    `);

    printReport({ files, source, objects, columns, mode: 'SQL Server' });
  } catch (error) {
    console.log(`# No se pudo conectar a SQL Server: ${error.message}\n`);
    console.log('Usando fallback estatico desde database/*.sql.\n');
    const { objects, columns } = readStaticSqlSchema();
    printReport({ files, source, objects, columns, mode: 'database/*.sql' });
  } finally {
    if (connection) await connection.close();
  }
}

function printReport({ files, source, objects, columns, mode }) {
  const groupedColumns = columns.reduce((acc, row) => {
    acc[row.table_name] = acc[row.table_name] || [];
    acc[row.table_name].push(row);
    return acc;
  }, {});

  const objectReport = objects.map((obj) => ({
    name: obj.name,
    type: obj.type,
    referencedInApp: hasWord(source, obj.name),
  }));

  const columnReport = Object.entries(groupedColumns).map(([table, tableColumns]) => ({
    table,
    columnsNotReferencedInApp: tableColumns
      .filter((col) => !hasWord(source, col.column_name))
      .map((col) => `${col.column_name} (${col.data_type})`),
  }));

  const unusedObjects = objectReport.filter((item) => !item.referencedInApp);
  const maybeUnusedColumns = columnReport.filter((item) => item.columnsNotReferencedInApp.length > 0);

  console.log('# Auditoria de esquema SQL vs app\n');
  console.log(`Modo: ${mode}`);
  console.log(`Archivos analizados: ${files.length}`);
  console.log(`Objetos dbo encontrados: ${objectReport.length}\n`);

  console.log('## Objetos sin referencia directa en backend/src, backend/index.js ni mobile/lib');
  if (unusedObjects.length === 0) {
    console.log('- Ninguno');
  } else {
    unusedObjects.forEach((item) => console.log(`- ${item.name} (${item.type})`));
  }

  console.log('\n## Columnas sin referencia directa por nombre en la app');
  maybeUnusedColumns.forEach((item) => {
    console.log(`\n### ${item.table}`);
    item.columnsNotReferencedInApp.forEach((column) => console.log(`- ${column}`));
  });
}

function readStaticSqlSchema() {
  const dbDir = path.join(root, 'database');
  const objects = [];
  const columns = [];
  const files = fs.readdirSync(dbDir).filter((name) => name.toLowerCase().endsWith('.sql'));

  for (const file of files) {
    const sql = fs.readFileSync(path.join(dbDir, file), 'utf8');
    const regex = /CREATE\s+TABLE\s+dbo\.([A-Za-z0-9_]+)\s*\(([\s\S]*?)\n\s*\);/gi;
    let match;
    while ((match = regex.exec(sql)) !== null) {
      const table = match[1];
      if (!objects.some((item) => item.name === table)) {
        objects.push({ name: table, type: 'BASE TABLE' });
      }
      const body = match[2];
      for (const rawLine of body.split(/\r?\n/)) {
        const line = rawLine.trim().replace(/,$/, '');
        if (!line || /^(CONSTRAINT|PRIMARY|FOREIGN|UNIQUE|CHECK)\b/i.test(line)) continue;
        const columnMatch = line.match(/^\[?([A-Za-z0-9_]+)\]?\s+([A-Za-z0-9_()]+)/);
        if (!columnMatch) continue;
        columns.push({
          table_name: table,
          column_name: columnMatch[1],
          data_type: columnMatch[2],
        });
      }
    }
  }

  return { objects, columns };
}

main().catch((error) => {
  console.error(error.message);
  if (error.odbcErrors) console.error(JSON.stringify(error.odbcErrors));
  process.exit(1);
});
