function errorHandler(error, req, res, next) {
    console.error('========== ERROR DETECTADO ==========');
    console.error('URL:', req?.method, req?.originalUrl);
    console.error('Message:', error?.message);
    if (error?.odbcErrors) console.error('ODBC Errors:', JSON.stringify(error.odbcErrors, null, 2));
    if (error?.stack) console.error('Stack:', error.stack);
    console.error('======================================');

    if (error?.type === 'entity.too.large') {
        return res.status(413).json({
            ok: false,
            mensaje: 'El archivo o imagen supera el tamaño permitido por la API.'
        });
    }

    if (error instanceof SyntaxError && 'body' in error) {
        return res.status(400).json({
            ok: false,
            mensaje: 'El cuerpo enviado no es un JSON válido.'
        });
    }

    const statusCode = error.statusCode || 500;
    const body = {
        ok: false,
        mensaje: error.message || 'Error interno del servidor'
    };
    if (error.odbcErrors) body.detalle = error.odbcErrors;
    if (error.requiereReset) body.requiereReset = true;

    res.status(statusCode).json(body);
}

function notFoundHandler(req, res) {
    res.status(404).json({
        ok: false,
        mensaje: `Ruta no encontrada: ${req.method} ${req.originalUrl}`
    });
}

module.exports = { errorHandler, notFoundHandler };
