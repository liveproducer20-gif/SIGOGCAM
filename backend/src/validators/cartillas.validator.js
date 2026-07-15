function validarConductor(datos) {
    if (!datos) throw new Error('Los datos estructurados de Conductor son obligatorios');
    if (!/^\d{4}$/.test(String(datos.cedula_ultimos_4 || ''))) {
        throw new Error('Los últimos cuatro dígitos de la cédula deben contener exactamente cuatro números');
    }
    const opciones = ['ENTRADA_PERSONAL', 'SALIDA_PERSONAL', 'NOVEDADES_MOVIL'];
    if (!opciones.includes(datos.opcion)) throw new Error('Opción de Conductor no válida');
    const kilometraje = Number(datos.kilometraje);
    if (!Number.isInteger(kilometraje) || kilometraje < 0 || datos.kilometraje === '') {
        throw new Error('El kilometraje debe ser un número entero positivo');
    }
}

function validarAccesoEspecial(tipo, rol) {
    const value = String(rol || '').toUpperCase();
    if (tipo === 'FORMACION' &&
        !['ADMIN', 'ENCARGADO', 'RADIOPERADOR'].some((allowed) => value.includes(allowed))) {
        throw new Error('El rol autenticado no está autorizado para generar formaciones');
    }
    if (tipo === 'CONDUCTOR' && value.includes('AUDITOR')) {
        throw new Error('Auditoría dispone únicamente de acceso de lectura');
    }
}

module.exports = { validarConductor, validarAccesoEspecial };
