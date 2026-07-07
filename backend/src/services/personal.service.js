const bcrypt = require('bcrypt');
const repository = require('../repositories/personal.repository');

async function obtenerTodo() {
    return await repository.obtenerTodo();
}

async function obtenerOperativos() {
    return await repository.obtenerOperativos();
}

async function obtenerDisponibles() {
    return await repository.obtenerDisponibles();
}

async function obtenerDisponiblesSinEvento() {
    return await repository.obtenerDisponiblesSinEvento();
}

async function buscar(texto) {
    if (!texto || texto.trim() === '') {
        throw new Error('El texto de búsqueda es obligatorio');
    }

    return await repository.buscar(texto.trim());
}

async function obtenerPerfil(id) {
    const perfil = await repository.obtenerPerfil(Number(id));

    if (!perfil) {
        throw new Error('Perfil no encontrado');
    }

    return mapPerfil(perfil);
}

async function actualizarPerfil(id, data) {
    const requeridos = ['cedula', 'correoInstitucional'];

    for (const campo of requeridos) {
        if (data[campo] === undefined || data[campo] === null || data[campo] === '') {
            throw new Error(`El campo ${campo} es obligatorio`);
        }
    }

    const cedula = data.cedula.toString().trim();
    if (!/^\d{10}$/.test(cedula)) {
        throw new Error('La cedula debe tener 10 digitos');
    }

    const correoInstitucional = data.correoInstitucional.toString().trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoInstitucional)) {
        throw new Error('El correo institucional no es valido');
    }

    const perfil = await repository.actualizarPerfil(Number(id), {
        cedula,
        correoInstitucional,
        telefono: data.telefono ? data.telefono.toString().trim() : null,
        fechaNacimiento: data.fechaNacimiento || null,
        fotoPerfilUrl: data.fotoPerfilUrl || null
    });

    return mapPerfil(perfil);
}

function mapPerfil(row) {
    return {
        id: row.id,
        cedula: row.cedula,
        nombres: row.nombres,
        apellidos: row.apellidos,
        nombreCompleto: row.nombre_completo || `${row.nombres} ${row.apellidos}`,
        correo: row.correo_institucional,
        telefono: row.telefono,
        fechaNacimiento: row.fecha_nacimiento,
        fechaIngreso: row.fecha_ingreso,
        rol: row.rol,
        estadoPersonal: row.estado_personal,
        fotoPerfilUrl: row.foto_perfil_url || null
    };
}

async function crear(data) {
    const requeridos = [
        'cedula',
        'nombres',
        'apellidos',
        'correoInstitucional',
        'fechaNacimiento',
        'areaId',
        'jornadaId',
        'grupoId',
        'rolId',
        'estadoPersonalId'
    ];

    for (const campo of requeridos) {
        if (data[campo] === undefined || data[campo] === null || data[campo] === '') {
            throw new Error(`El campo ${campo} es obligatorio`);
        }
    }

    const cedula = data.cedula.toString().trim();
    if (!/^\d{10}$/.test(cedula)) {
        throw new Error('La cedula debe tener 10 digitos');
    }

    const correoInstitucional = data.correoInstitucional.toString().trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoInstitucional)) {
        throw new Error('El correo institucional no es valido');
    }

    const payload = normalizarPayload(data, {
        cedula,
        correoInstitucional
    });
    payload.passwordHash = await bcrypt.hash(passwordInicial(payload.fechaNacimiento), 10);

    return await repository.crear(payload);
}

async function actualizar(id, data) {
    const personalId = Number(id);
    if (!Number.isInteger(personalId) || personalId <= 0) {
        throw new Error('El id de personal no es valido');
    }

    const requeridos = [
        'cedula',
        'nombres',
        'apellidos',
        'correoInstitucional',
        'fechaNacimiento',
        'areaId',
        'jornadaId',
        'grupoId',
        'rolId',
        'estadoPersonalId'
    ];

    for (const campo of requeridos) {
        if (data[campo] === undefined || data[campo] === null || data[campo] === '') {
            throw new Error(`El campo ${campo} es obligatorio`);
        }
    }

    const cedula = data.cedula.toString().trim();
    if (!/^\d{10}$/.test(cedula)) {
        throw new Error('La cedula debe tener 10 digitos');
    }

    const correoInstitucional = data.correoInstitucional.toString().trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoInstitucional)) {
        throw new Error('El correo institucional no es valido');
    }

    return await repository.actualizar(personalId, normalizarPayload(data, {
        cedula,
        correoInstitucional
    }));
}

async function cambiarEstado(id, activo) {
    const personalId = Number(id);
    if (!Number.isInteger(personalId) || personalId <= 0) {
        throw new Error('El id de personal no es valido');
    }

    return repository.cambiarEstado(personalId, Boolean(activo));
}

async function restablecerPassword(id) {
    const personalId = Number(id);
    if (!Number.isInteger(personalId) || personalId <= 0) {
        throw new Error('El id de personal no es valido');
    }

    const persona = await repository.obtenerBasico(personalId);
    if (!persona) {
        throw new Error('Personal no encontrado');
    }
    if (!persona.fecha_nacimiento) {
        throw new Error('El personal no tiene fecha de nacimiento registrada');
    }

    const hash = await bcrypt.hash(passwordInicial(persona.fecha_nacimiento), 10);
    await repository.actualizarPassword(personalId, hash);
}

function normalizarPayload(data, base) {
    const gradoId = data.gradoId || data.cargoId;
    if (!gradoId) {
        throw new Error('El campo gradoId es obligatorio');
    }

    return {
        cedula: base.cedula,
        nombres: data.nombres.toString().trim(),
        apellidos: data.apellidos.toString().trim(),
        correoInstitucional: base.correoInstitucional,
        telefono: data.telefono ? data.telefono.toString().trim() : null,
        fechaNacimiento: data.fechaNacimiento || null,
        fechaIngreso: data.fechaIngreso || null,
        cargoId: Number(data.cargoId || gradoId),
        gradoId: Number(gradoId),
        areaId: Number(data.areaId),
        funcionOperativaId: data.funcionOperativaId ? Number(data.funcionOperativaId) : null,
        jornadaId: Number(data.jornadaId),
        grupoId: Number(data.grupoId),
        tipoRotacionId: data.tipoRotacionId ? Number(data.tipoRotacionId) : null,
        rolId: Number(data.rolId),
        estadoPersonalId: Number(data.estadoPersonalId)
    };
}

function passwordInicial(fechaNacimiento) {
    const value = fechaNacimiento instanceof Date
        ? fechaNacimiento.toISOString().substring(0, 10)
        : fechaNacimiento.toString().substring(0, 10);
    const parts = value.includes('-') ? value.split('-') : value.split('/');

    if (parts.length !== 3) {
        throw new Error('La fecha de nacimiento no es valida');
    }

    if (value.includes('-')) {
        return `${parts[2]}${parts[1]}${parts[0]}`;
    }

    return `${parts[0].padStart(2, '0')}${parts[1].padStart(2, '0')}${parts[2]}`;
}

module.exports = {
    obtenerTodo,
    obtenerOperativos,
    obtenerDisponibles,
    obtenerDisponiblesSinEvento,
    buscar,
    obtenerPerfil,
    actualizarPerfil,
    crear,
    actualizar,
    cambiarEstado,
    restablecerPassword
};
