const { query } = require('../config/db');
const storage = require('./image-storage.service');

async function migrateInlineImages() {
    const rows = await query(`
        SELECT id, CONVERT(NVARCHAR(MAX), imagen_url) imagen_url
        FROM dbo.anuncios
        WHERE CONVERT(NVARCHAR(MAX), imagen_url) LIKE 'data:image/%;base64,%'`);
    let migrated = 0;
    const failures = [];

    for (const row of rows) {
        try {
            const route = await storage.saveDataUrl(row.imagen_url, 'anuncios');
            await query('UPDATE dbo.anuncios SET imagen_url=? WHERE id=?', [route, Number(row.id)]);
            migrated++;
        } catch (error) {
            failures.push({ id: Number(row.id), message: error.message });
        }
    }
    return { migrated, failures };
}

module.exports = { migrateInlineImages };
