const jwt = require('jsonwebtoken');

function requireAuth(req, res, next) {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.substring(7) : null;

    if (!token) {
        return res.status(401).json({
            ok: false,
            mensaje: 'Token de autenticacion requerido'
        });
    }

    try {
        req.user = jwt.verify(
            token,
            process.env.JWT_SECRET || 'sigo_gcam_secret'
        );

        next();
    } catch (error) {
        return res.status(401).json({
            ok: false,
            mensaje: 'Token invalido o expirado'
        });
    }
}

function requirePermission(codigo) {
    return (req, res, next) => {
        const permisos = Array.isArray(req.user?.permisos)
            ? req.user.permisos
            : [];

        if (!permisos.includes(codigo)) {
            return res.status(403).json({
                ok: false,
                mensaje: `Permiso requerido: ${codigo}`
            });
        }

        next();
    };
}

function requireAnyPermission(codigos) {
    return (req, res, next) => {
        const permisos = Array.isArray(req.user?.permisos)
            ? req.user.permisos
            : [];

        const autorizado = codigos.some((codigo) => permisos.includes(codigo));

        if (!autorizado) {
            return res.status(403).json({
                ok: false,
                mensaje: `Permiso requerido: ${codigos.join(' o ')}`
            });
        }

        next();
    };
}

module.exports = {
    requireAuth,
    requirePermission,
    requireAnyPermission
};
