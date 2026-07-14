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

module.exports = { normalizarRol, nombreRol };
