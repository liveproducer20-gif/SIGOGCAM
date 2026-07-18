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

module.exports = { normalizarRol };
