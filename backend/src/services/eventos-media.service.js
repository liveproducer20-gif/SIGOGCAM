const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const { query } = require('../config/db');
const { saveImage, saveDataUrl } = require('./image-storage.service');

const uploadsRoot = path.resolve(__dirname, '../../uploads');
const imageTypes = new Set(['image/png', 'image/jpeg', 'image/webp']);

async function saveUpload(buffer, contentType) {
    const type = (contentType || '').split(';')[0].trim().toLowerCase();
    if (imageTypes.has(type)) {
        return saveImage(buffer, type, 'eventos-imagenes');
    }
    if (type === 'application/pdf') {
        return savePdf(buffer);
    }
    throw Object.assign(
        new Error('Formato no permitido. Use PNG, JPG, JPEG, WEBP o PDF'),
        { statusCode: 415 }
    );
}

async function savePdf(buffer) {
    if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
        throw Object.assign(new Error('Seleccione un archivo PDF'), { statusCode: 400 });
    }
    if (buffer.length > 10 * 1024 * 1024) {
        throw Object.assign(new Error('El PDF supera el máximo de 10 MB'), { statusCode: 413 });
    }
    if (buffer.length < 5 || buffer.toString('ascii', 0, 5) !== '%PDF-') {
        throw Object.assign(new Error('El archivo no contiene un PDF válido'), { statusCode: 415 });
    }
    const folder = 'eventos-documentos';
    const destination = path.join(uploadsRoot, folder);
    await fs.promises.mkdir(destination, { recursive: true });
    const fileName = `${Date.now()}-${crypto.randomUUID()}.pdf`;
    await fs.promises.writeFile(path.join(destination, fileName), buffer, { flag: 'wx' });
    return `/uploads/${folder}/${fileName}`;
}

async function savePdfDataUrl(value) {
    const match = /^data:application\/pdf;base64,([a-z0-9+/=\s]+)$/i.exec(value || '');
    if (!match) throw new Error('El PDF Base64 no tiene un formato compatible');
    return savePdf(Buffer.from(match[1], 'base64'));
}

function normalizeStoredUrl(value, kind) {
    const text = value?.toString().trim();
    if (!text) return null;
    if (/^https:\/\//i.test(text)) return text;
    const expected = kind === 'pdf' ? '/uploads/eventos-documentos/' : '/uploads/eventos-imagenes/';
    if (text.startsWith(expected)) return text;
    throw Object.assign(new Error(`La ruta de ${kind === 'pdf' ? 'PDF' : 'imagen'} no es válida`), { statusCode: 400 });
}

async function migrateInlineMedia() {
    const columns = await query(`
        SELECT COL_LENGTH('eventos', 'imagen_url') imagen_url,
               COL_LENGTH('eventos', 'pdf_url') pdf_url
    `);
    if (!columns[0]?.imagen_url && !columns[0]?.pdf_url) {
        return { migrated: 0, failures: [] };
    }

    const rows = await query(`
        SELECT id,
               CONVERT(NVARCHAR(MAX), imagen_url) imagen_url,
               CONVERT(NVARCHAR(MAX), pdf_url) pdf_url
        FROM eventos
        WHERE imagen_url LIKE 'data:image/%;base64,%'
           OR pdf_url LIKE 'data:application/pdf;base64,%'
    `);
    let migrated = 0;
    const failures = [];
    for (const row of rows) {
        try {
            let image = row.imagen_url;
            let pdf = row.pdf_url;
            if (image?.startsWith('data:image/')) {
                image = await saveDataUrl(image, 'eventos-imagenes');
            }
            if (pdf?.startsWith('data:application/pdf')) {
                pdf = await savePdfDataUrl(pdf);
            }
            await query('UPDATE eventos SET imagen_url=?, pdf_url=? WHERE id=?', [image || null, pdf || null, Number(row.id)]);
            migrated++;
        } catch (error) {
            failures.push({ id: Number(row.id), error: error.message });
        }
    }
    return { migrated, failures };
}

module.exports = { saveUpload, normalizeStoredUrl, migrateInlineMedia };
