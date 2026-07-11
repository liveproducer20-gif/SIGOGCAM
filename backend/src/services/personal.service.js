const bcrypt = require('bcrypt');
const repository = require('../repositories/personal.repository');

async function obtenerTodo(query = {}) {
    return await repository.obtenerTodo(query);
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
    const limpio = (texto || '').toString().trim();
    if (!limpio) {
        throw new Error('El texto de búsqueda es obligatorio');
    }
    if (limpio.length < 2) {
        throw new Error('El texto de búsqueda debe tener al menos 2 caracteres');
    }
    if (limpio.length > 50) {
        throw new Error('El texto de búsqueda no puede exceder 50 caracteres');
    }

    return await repository.buscar(limpio);
}

async function obtenerPerfil(id) {
    const perfil = await repository.obtenerPerfil(Number(id));

    if (!perfil) {
        throw new Error('Perfil no encontrado');
    }

    return mapPerfil(perfil);
}

async function actualizarPerfil(id, data) {
    const { cedula, correoInstitucional } = validarCedulaYCorreo(data, ['cedula', 'correoInstitucional']);

    const perfil = await repository.actualizarPerfil(Number(id), {
        cedula,
        correoInstitucional,
        telefono: data.telefono ? data.telefono.toString().trim() : null,
        fechaNacimiento: data.fechaNacimiento || null,
        fotoPerfilUrl: data.fotoPerfilUrl || null
    });

    return mapPerfil(perfil);
}

function validarCamposRequeridos(data, campos) {
    for (const campo of campos) {
        if (data[campo] === undefined || data[campo] === null || data[campo] === '') {
            throw new Error(`El campo ${campo} es obligatorio`);
        }
    }
}

function validarCedulaYCorreo(data, camposRequeridos) {
    if (camposRequeridos) validarCamposRequeridos(data, camposRequeridos);

    const cedula = data.cedula.toString().trim();
    if (!/^\d{10}$/.test(cedula)) {
        throw new Error('La cédula debe tener 10 dígitos');
    }

    const correoInstitucional = data.correoInstitucional.toString().trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoInstitucional)) {
        throw new Error('El correo institucional no es válido');
    }

    return { cedula, correoInstitucional };
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
    validarCamposRequeridos(data, [
        'cedula', 'nombres', 'apellidos', 'correoInstitucional', 'gradoId'
    ]);

    const { cedula, correoInstitucional } = validarCedulaYCorreo(data);

    const payload = normalizarPayload(data, { cedula, correoInstitucional });
    payload.passwordHash = await bcrypt.hash(
        payload.fechaNacimiento ? passwordInicial(payload.fechaNacimiento) : 'segura2025',
        10
    );

    return await repository.crear(payload);
}

async function actualizar(id, data) {
    const personalId = Number(id);
    if (!Number.isInteger(personalId) || personalId <= 0) {
        throw new Error('El id de personal no es válido');
    }

    validarCamposRequeridos(data, [
        'cedula', 'nombres', 'apellidos', 'correoInstitucional', 'gradoId'
    ]);

    const { cedula, correoInstitucional } = validarCedulaYCorreo(data);

    return await repository.actualizar(personalId, normalizarPayload(data, { cedula, correoInstitucional }));
}

async function cambiarEstado(id, activo) {
    const personalId = Number(id);
    if (!Number.isInteger(personalId) || personalId <= 0) {
        throw new Error('El id de personal no es válido');
    }

    return repository.cambiarEstado(personalId, Boolean(activo));
}

async function eliminar(id) {
    const personalId = Number(id);
    if (!Number.isInteger(personalId) || personalId <= 0) {
        throw new Error('El id de personal no es válido');
    }
    return repository.eliminar(personalId);
}

async function restablecerPassword(id) {
    const personalId = Number(id);
    if (!Number.isInteger(personalId) || personalId <= 0) {
        throw new Error('El id de personal no es válido');
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
        areaId: data.areaId ? Number(data.areaId) : null,
        funcionOperativaId: data.funcionOperativaId ? Number(data.funcionOperativaId) : null,
        jornadaId: data.jornadaId ? Number(data.jornadaId) : null,
        grupoId: data.grupoId ? Number(data.grupoId) : null,
        tipoRotacionId: data.tipoRotacionId ? Number(data.tipoRotacionId) : null,
        rolId: data.rolId ? Number(data.rolId) : null,
        estadoPersonalId: data.estadoPersonalId ? Number(data.estadoPersonalId) : null
    };
}

function passwordInicial(fechaNacimiento) {
    const value = fechaNacimiento instanceof Date
        ? fechaNacimiento.toISOString().substring(0, 10)
        : fechaNacimiento.toString().substring(0, 10);
    const parts = value.includes('-') ? value.split('-') : value.split('/');

    if (parts.length !== 3) {
        throw new Error('La fecha de nacimiento no es válida');
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
    restablecerPassword,
    eliminar
};
