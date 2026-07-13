const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { asyncHandler } = require('../middleware/async-handler');
const service = require('../services/soporte.service');
const realtime = require('../support-realtime');

const listar = asyncHandler(async (req, res) => res.json({ ok: true, ...(await service.listar(req.query, req.user)) }));
const estadisticas = asyncHandler(async (req, res) => res.json({ ok: true, datos: await service.estadisticas(req.user) }));
const detalle = asyncHandler(async (req, res) => res.json({ ok: true, datos: await service.detalle(req.params.id, req.user) }));

const crear = asyncHandler(async (req, res) => {
    const ticket = await service.crear(req.body, req.user);
    realtime.publish('ticket.created', ticket);
    res.status(201).json({ ok: true, mensaje: 'Reporte enviado correctamente', datos: ticket });
});

const actualizar = asyncHandler(async (req, res) => {
    const ticket = await service.actualizar(req.params.id, req.body, req.user);
    realtime.publish('ticket.updated', ticket);
    res.json({ ok: true, mensaje: 'Alerta actualizada correctamente', datos: ticket });
});

const comentar = asyncHandler(async (req, res) => {
    const ticket = await service.comentar(req.params.id, req.body, req.user);
    realtime.publish('ticket.commented', ticket);
    res.status(201).json({ ok: true, mensaje: 'Respuesta enviada correctamente' });
});

const subirImagen = asyncHandler(async (req, res) => {
    if (!Buffer.isBuffer(req.body) || req.body.length === 0) throw Object.assign(new Error('Seleccione una imagen'), { statusCode: 400 });
    if (req.body.length > 5 * 1024 * 1024) throw Object.assign(new Error('La imagen supera el máximo de 5 MB'), { statusCode: 413 });
    const types = { 'image/png': '.png', 'image/jpeg': '.jpg', 'image/webp': '.webp' };
    const extension = types[req.headers['content-type']];
    if (!extension) throw Object.assign(new Error('Formato no permitido. Use PNG, JPG, JPEG o WEBP'), { statusCode: 415 });
    const folder = path.resolve(__dirname, '../../uploads/support');
    await fs.promises.mkdir(folder, { recursive: true });
    const fileName = `${Date.now()}-${crypto.randomBytes(8).toString('hex')}${extension}`;
    await fs.promises.writeFile(path.join(folder, fileName), req.body, { flag: 'wx' });
    res.status(201).json({ ok: true, datos: { ruta: `/uploads/support/${fileName}` } });
});

module.exports = { listar, estadisticas, detalle, crear, actualizar, comentar, subirImagen };

