const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const root = path.resolve(__dirname, '../../uploads');
const supportedTypes = {
    'image/png': '.png',
    'image/jpeg': '.jpg',
    'image/webp': '.webp'
};

async function saveImage(buffer, contentType, folder = 'anuncios') {
    if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
        throw Object.assign(new Error('Seleccione una imagen'), { statusCode: 400 });
    }
    if (buffer.length > 5 * 1024 * 1024) {
        throw Object.assign(new Error('La imagen supera el máximo de 5 MB'), { statusCode: 413 });
    }
    const extension = supportedTypes[contentType];
    if (!extension || !hasValidSignature(buffer, contentType)) {
        throw Object.assign(new Error('Formato no permitido. Use PNG, JPG, JPEG o WEBP'), { statusCode: 415 });
    }

    const safeFolder = folder.replace(/[^a-z0-9_-]/gi, '');
    const destination = path.join(root, safeFolder);
    await fs.promises.mkdir(destination, { recursive: true });
    const fileName = `${Date.now()}-${crypto.randomUUID()}${extension}`;
    await fs.promises.writeFile(path.join(destination, fileName), buffer, { flag: 'wx' });
    return `/uploads/${safeFolder}/${fileName}`;
}

async function saveDataUrl(value, folder = 'anuncios') {
    const match = /^data:(image\/(?:png|jpeg|webp));base64,([a-z0-9+/=\s]+)$/i.exec(value || '');
    if (!match) throw new Error('La imagen Base64 no tiene un formato compatible');
    return saveImage(Buffer.from(match[2], 'base64'), match[1].toLowerCase(), folder);
}

function hasValidSignature(buffer, type) {
    if (type === 'image/png') {
        return buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
    }
    if (type === 'image/jpeg') {
        return buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
    }
    return buffer.length >= 12 && buffer.toString('ascii', 0, 4) === 'RIFF' && buffer.toString('ascii', 8, 12) === 'WEBP';
}

module.exports = { saveImage, saveDataUrl };
