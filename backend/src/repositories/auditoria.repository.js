const { odbc, connectionString } = require('../config/db');

async function registrar(data) {
    const conexion = await odbc.connect(connectionString);

    try {
        const sql = `
            INSERT INTO auditoria (
                usuario_id,
                accion,
                modulo,
                tabla_afectada,
                registro_id,
                metodo,
                endpoint,
                ip,
                user_agent,
                datos_anteriores,
                datos_nuevos,
                fecha_creacion
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
        `;

        await conexion.query(sql, [
            data.usuarioId || null,
            data.accion,
            data.modulo,
            data.tablaAfectada || null,
            data.registroId ? data.registroId.toString() : null,
            data.metodo,
            data.endpoint,
            data.ip || null,
            data.userAgent || null,
            data.datosAnteriores ? JSON.stringify(data.datosAnteriores) : null,
            data.datosNuevos ? JSON.stringify(data.datosNuevos) : null
        ]);
    } finally {
        await conexion.close();
    }
}

module.exports = {
    registrar
};
