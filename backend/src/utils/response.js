function ok(res, datos = null, mensaje = null, status = 200) {
    const body = { ok: true };
    if (mensaje) body.mensaje = mensaje;
    if (datos !== null) body.datos = datos;
    return res.status(status).json(body);
}

function created(res, id, idKey = 'id', mensaje = 'Creado correctamente') {
    return res.status(201).json({
        ok: true,
        mensaje,
        [idKey]: id
    });
}

function paginated(res, datos, total, page) {
    return res.status(200).json({
        ok: true,
        datos,
        total,
        page
    });
}

module.exports = { ok, created, paginated };
