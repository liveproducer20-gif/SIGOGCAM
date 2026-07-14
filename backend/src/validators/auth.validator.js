function normalizarRol(rol) {
    const value = (rol || '').toString().trim().toUpperCase();
    if (value.includes('ADMIN')) return 'ADMINISTRADOR';
    if (value.includes('OPERACION')) return 'OPERACIONES';
    if (value.includes('RADIO')) return 'RADIOPERADOR_SEGURA_EP';
    if (value.includes('ENCARGADO')) return 'ENCARGADO';
    if (value.includes('SUPERVISOR')) return 'SUPERVISOR';
    if (value.includes('INSPECTOR')) return 'INSPECTOR';
    if (value.includes('COMUNICACION')) return 'COMUNICACIONES';
    if (value.includes('PERSONAL OPERATIVO')) return 'PERSONAL_OPERATIVO';
    if (value.includes('CONSULTA')) return 'USUARIO';
    if (value.includes('AUDITOR')) return 'AUDITOR';
    return 'USUARIO';
}

function nombreRol(rolCodigo) {
    const mapa = {
        ADMINISTRADOR: 'Administrador',
        OPERACIONES: 'Operaciones',
        SUPERVISOR: 'Supervisor',
        INSPECTOR: 'Inspector',
        USUARIO: 'Agente municipal',
        RADIOPERADOR_SEGURA_EP: 'Radioperador SEGURA EP',
        ENCARGADO: 'Encargado',
        COMUNICACIONES: 'Comunicaciones',
        PERSONAL_OPERATIVO: 'Personal Operativo',
        AUDITOR: 'Auditor'
    };
    return mapa[rolCodigo] || 'Agente';
}

function permisosPorDefecto(rolCodigo) {
    const mapa = {
        ADMINISTRADOR: [
            'personal.ver', 'personal.crear', 'personal.editar', 'personal.editar_estado',
            'personal.reset_password', 'roles.ver', 'roles.crear', 'roles.editar',
            'permisos.ver', 'administracion.ver', 'catalogos.ver', 'catalogos.crear',
            'catalogos.editar', 'catalogos.estado', 'lugares_servicio.ver',
            'lugares_servicio.crear', 'lugares_servicio.editar', 'lugares_servicio.estado',
            'eas.ver', 'eas.crear', 'eas.editar', 'eas.estado', 'moviles.ver',
            'moviles.crear', 'moviles.editar', 'moviles.estado', 'moviles.asignar',
            'dashboard.mantenimiento', 'eventos.ver', 'eventos.crear', 'eventos.editar',
            'eventos.eliminar', 'eventos.convocar', 'eventos.publicar',
            'anuncios.ver', 'anuncios.crear', 'anuncios.editar', 'anuncios.eliminar',
            'cartillas.ver', 'cartillas.generar', 'insignias.ver',
            'perfil.ver', 'perfil.editar'
        ],
        OPERACIONES: [
            'personal.ver', 'administracion.ver', 'catalogos.ver',
            'lugares_servicio.ver', 'lugares_servicio.crear', 'lugares_servicio.editar',
            'lugares_servicio.estado', 'eas.ver', 'eas.crear', 'eas.editar',
            'eas.estado', 'moviles.ver', 'moviles.crear', 'moviles.editar',
            'moviles.estado', 'moviles.asignar', 'dashboard.mantenimiento',
            'eventos.ver', 'eventos.crear', 'eventos.editar', 'eventos.convocar',
            'anuncios.ver', 'anuncios.crear', 'anuncios.editar',
            'cartillas.ver', 'cartillas.generar', 'insignias.ver',
            'perfil.ver', 'perfil.editar'
        ],
        COMUNICACIONES: [
            'eventos.ver', 'eventos.crear', 'eventos.editar', 'eventos.eliminar',
            'eventos.convocar', 'eventos.publicar',
            'anuncios.ver', 'anuncios.crear', 'anuncios.editar', 'anuncios.eliminar',
            'cartillas.ver', 'cartillas.generar', 'insignias.ver',
            'perfil.ver', 'perfil.editar'
        ],
        AUDITOR: [
            'administracion.ver', 'catalogos.ver', 'personal.ver',
            'lugares_servicio.ver', 'eas.ver', 'moviles.ver',
            'auditoria.ver', 'auditoria.detalle', 'auditoria.exportar',
            'reportes.exportar', 'eventos.ver', 'cartillas.ver', 'perfil.ver'
        ],
        RADIOPERADOR_SEGURA_EP: [
            'dashboard.mantenimiento', 'eventos.ver', 'servicios.ver',
            'novedades.crear', 'cartillas.generar', 'cartillas.ver',
            'perfil.ver', 'perfil.editar'
        ],
        ENCARGADO: [
            'eventos.ver_convocado', 'anuncios.ver', 'insignias.ver',
            'reportes.ver', 'personal.ver_asignado',
            'cartillas.generar', 'cartillas.ver',
            'perfil.ver', 'perfil.editar'
        ]
    };
    return mapa[rolCodigo] || [
        'eventos.ver_convocado', 'anuncios.ver',
        'cartillas.ver', 'cartillas.generar', 'insignias.ver', 'perfil.ver'
    ];
}

module.exports = { normalizarRol, nombreRol, permisosPorDefecto };
