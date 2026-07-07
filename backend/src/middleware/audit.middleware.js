const auditoriaRepository = require('../repositories/auditoria.repository');

function auditAction({ accion, modulo, tabla }) {
    return (req, res, next) => {
        const originalJson = res.json.bind(res);
        let responseBody = null;

        res.json = (body) => {
            responseBody = body;
            return originalJson(body);
        };

        res.on('finish', () => {
            if (res.statusCode >= 400) return;

            const registroId =
                responseBody?.eventoId ||
                responseBody?.personalId ||
                responseBody?.id ||
                req.params?.id ||
                null;

            auditoriaRepository.registrar({
                usuarioId: req.user?.id,
                accion,
                modulo,
                tablaAfectada: tabla,
                registroId,
                metodo: req.method,
                endpoint: req.originalUrl,
                ip: req.ip,
                userAgent: req.headers['user-agent'],
                datosAnteriores: null,
                datosNuevos: req.body
            }).catch((error) => {
                console.error('ERROR AUDITORIA:', error.message);
            });
        });

        next();
    };
}

module.exports = {
    auditAction
};
