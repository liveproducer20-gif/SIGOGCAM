const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const repository = require('../repositories/auth.repository');
const { normalizarRol, nombreRol, permisosPorDefecto } = require('../validators/auth.validator');

async function login(correo, password) {
    const login = (correo || '').toString().trim().toLowerCase();
    const clave = (password || '').toString().trim();

    if (!login || !clave) {
        throw Object.assign(new Error('Correo o cédula y contraseña son obligatorios'), { statusCode: 400 });
    }

    const persona = await repository.buscarPorCorreo(login);
    if (!persona) {
        throw Object.assign(new Error('Usuario no encontrado o inactivo'), { statusCode: 401 });
    }

    const rolCodigo = normalizarRol(persona.rol);

    let permisos = [];
    try {
        const dbPermisos = await repository.obtenerPermisos(nombreRol(rolCodigo));
        const defaults = permisosPorDefecto(rolCodigo);
        permisos = [...new Set([...dbPermisos, ...defaults])];
    } catch {
        permisos = permisosPorDefecto(rolCodigo);
    }

    if (!persona.password_hash) {
        if (clave !== persona.cedula) {
            throw Object.assign(
                new Error('Debe restablecer su contraseña antes de iniciar sesión. Contacte a su administrador.'),
                { statusCode: 401, requiereReset: true }
            );
        }
    } else if (!(await bcrypt.compare(clave, persona.password_hash))) {
        throw Object.assign(new Error('Contraseña incorrecta'), { statusCode: 401 });
    }

    const usuarioSesion = {
        id: persona.id,
        cedula: persona.cedula,
        correo: persona.correo_institucional,
        nombres: persona.nombres,
        apellidos: persona.apellidos,
        nombreCompleto: persona.nombre_completo,
        rol: rolCodigo,
        estadoPersonal: persona.estado_personal,
        fotoPerfilUrl: persona.foto_perfil_url || null,
        permisos
    };

    const token = jwt.sign(usuarioSesion, process.env.JWT_SECRET, { expiresIn: '8h' });

    return { usuario: usuarioSesion, token };
}

function refreshToken(user) {
    const token = jwt.sign(user, process.env.JWT_SECRET, { expiresIn: '8h' });
    return token;
}

async function changePassword(userId, oldPassword, newPassword, confirmPassword) {
    const oldValue = (oldPassword || '').toString().trim();
    const nextValue = (newPassword || '').toString().trim();
    const confirmValue = (confirmPassword || '').toString().trim();

    if (!oldValue || !nextValue || !confirmValue) {
        throw Object.assign(
            new Error('Ingrese contraseña anterior, nueva contraseña y verificación'),
            { statusCode: 400 }
        );
    }

    if (nextValue !== confirmValue) {
        throw Object.assign(
            new Error('La nueva contraseña y la verificación no coinciden'),
            { statusCode: 400 }
        );
    }

    if (nextValue.length < 6) {
        throw Object.assign(
            new Error('La nueva contraseña debe tener al menos 6 caracteres'),
            { statusCode: 400 }
        );
    }

    const tienePassword = await repository.tieneColumna('password_hash');
    if (!tienePassword) {
        throw Object.assign(
            new Error('Ejecute el script database/20260706_personal_password_hash.sql para habilitar contraseñas'),
            { statusCode: 400 }
        );
    }

    const persona = await repository.buscarPorId(userId);
    if (!persona) {
        throw Object.assign(new Error('Usuario no encontrado'), { statusCode: 404 });
    }

    if (persona.password_hash) {
        if (!(await bcrypt.compare(oldValue, persona.password_hash))) {
            throw Object.assign(
                new Error('La contraseña anterior no es correcta'),
                { statusCode: 401 }
            );
        }
    }

    const hash = await bcrypt.hash(nextValue, 10);
    await repository.actualizarPassword(userId, hash);
}

module.exports = { login, refreshToken, changePassword };
