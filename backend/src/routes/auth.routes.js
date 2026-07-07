const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const router = express.Router();
const { odbc, connectionString } = require('../config/db');
const { requireAuth } = require('../middleware/auth.middleware');

router.get('/registro', (req, res) => {
  res.json({
    ok: true,
    mensaje: 'Ruta de registro activa. Use POST para crear usuario.'
  });
});

router.post('/login', async (req, res) => {
  let connection;

  try {
    const { usuario, correo, password } = req.body;
    const login = (correo || usuario || '').toString().trim().toLowerCase();
    const clave = (password || '').toString().trim();

    if (!login || !clave) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Correo y contraseña son obligatorios'
      });
    }

    connection = await odbc.connect(connectionString);

    const tieneFoto = await tieneColumnaFoto(connection);
    const tienePassword = await tieneColumnaPassword(connection);
    const extraScalarSelect = [
      tienePassword ? 'p.password_hash' : null,
      'p.fecha_nacimiento'
    ].filter(Boolean).map((column) => `, ${column}`).join('');
    const extraLobSelect = tieneFoto
      ? ', CONVERT(NVARCHAR(MAX), p.foto_perfil_url) AS foto_perfil_url'
      : '';
    const sql = `
      SELECT TOP 1
        vd.id,
        vd.cedula,
        vd.correo_institucional,
        vd.nombres,
        vd.apellidos,
        vd.nombre_completo,
        vd.rol,
        vd.estado_personal,
        vd.activo
        ${extraScalarSelect}
        ${extraLobSelect}
      FROM vw_personal_detalle vd
      LEFT JOIN dbo.personal p ON p.id = vd.id
      WHERE LOWER(vd.correo_institucional) = ?
        AND (vd.activo = 1 OR vd.activo = '1')
      ORDER BY vd.id
    `;

    const result = await connection.query(sql, [login]);

    if (result.length === 0) {
      return res.status(401).json({
        ok: false,
        mensaje: 'Correo no encontrado o usuario inactivo'
      });
    }

    const persona = result[0];
    const rolCodigo = normalizarRol(persona.rol);
    const permisos = await obtenerPermisos(connection, rolCodigo);
    const claveValida = await validarClaveExtendida(persona, clave);

    if (!claveValida) {
      return res.status(401).json({
        ok: false,
        mensaje: 'Contraseña incorrecta'
      });
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
      fotoPerfilUrl: persona.foto_perfil_url ?? null,
      permisos
    };

    const token = jwt.sign(
      usuarioSesion,
      process.env.JWT_SECRET || 'sigo_gcam_secret',
      { expiresIn: '8h' }
    );

    res.json({
      ok: true,
      mensaje: 'Inicio de sesión correcto',
      usuario: usuarioSesion,
      token
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      mensaje: error.message,
      detalle: error.odbcErrors || error
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
});

router.post('/change-password', requireAuth, async (req, res) => {
  let connection;

  try {
    const { oldPassword, newPassword, confirmPassword } = req.body;
    const oldValue = (oldPassword || '').toString().trim();
    const nextValue = (newPassword || '').toString().trim();
    const confirmValue = (confirmPassword || '').toString().trim();

    if (!oldValue || !nextValue || !confirmValue) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Ingrese contraseña anterior, nueva contraseña y verificación'
      });
    }

    if (nextValue !== confirmValue) {
      return res.status(400).json({
        ok: false,
        mensaje: 'La nueva contraseña y la verificación no coinciden'
      });
    }

    if (nextValue.length < 6) {
      return res.status(400).json({
        ok: false,
        mensaje: 'La nueva contraseña debe tener al menos 6 caracteres'
      });
    }

    connection = await odbc.connect(connectionString);

    const tienePassword = await tieneColumnaPassword(connection);
    if (!tienePassword) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Ejecute el script database/20260706_personal_password_hash.sql para habilitar contraseñas'
      });
    }

    const result = await connection.query(`
      SELECT TOP 1
        vd.id,
        vd.cedula,
        p.password_hash
      FROM vw_personal_detalle vd
      INNER JOIN dbo.personal p ON p.id = vd.id
      WHERE vd.id = ?
    `, [req.user.id]);

    if (result.length === 0) {
      return res.status(404).json({
        ok: false,
        mensaje: 'Usuario no encontrado'
      });
    }

    const persona = result[0];
    const claveValida = await validarClaveExtendida(persona, oldValue);

    if (!claveValida) {
      return res.status(401).json({
        ok: false,
        mensaje: 'La contraseña anterior no es correcta'
      });
    }

    const hash = await bcrypt.hash(nextValue, 10);
    await connection.query(
      'UPDATE dbo.personal SET password_hash = ? WHERE id = ?',
      [hash, req.user.id]
    );

    res.json({
      ok: true,
      mensaje: 'Contraseña actualizada correctamente'
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      mensaje: error.message,
      detalle: error.odbcErrors || error
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
});

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
    CONSULTA: 'Agente municipal',
    AUDITORIA: 'Auditoria',
    AUDITOR: 'Auditor'
  };

  return mapa[rolCodigo] || 'Agente';
}

async function obtenerPermisos(connection, rolCodigo) {
  const sql = `
    SELECT p.codigo
    FROM roles r
    INNER JOIN rol_permiso rp ON rp.rol_id = r.id
    INNER JOIN permisos p ON p.id = rp.permiso_id
    WHERE r.nombre = ?
      AND r.activo = 1
      AND p.activo = 1
    ORDER BY p.codigo
  `;

  try {
    const result = await connection.query(sql, [nombreRol(rolCodigo)]);
    const permisos = result.map((item) => item.codigo);

    if (permisos.length > 0) {
      if (rolCodigo === 'COMUNICACIONES') {
        return [...new Set([...permisos, ...permisosPorDefecto(rolCodigo)])];
      }

      return permisos;
    }

    return permisosPorDefecto(rolCodigo);
  } catch (error) {
    return permisosPorDefecto(rolCodigo);
  }
}

async function validarClave(persona, clave) {
  if (clave === persona.cedula) {
    return true;
  }

  if (persona.fecha_nacimiento) {
    return clave === passwordDesdeFecha(persona.fecha_nacimiento);
  }

  return clave === persona.cedula;
}

async function validarClaveExtendida(persona, clave) {
  if (persona.password_hash) {
    return await bcrypt.compare(clave, persona.password_hash);
  }

  return validarClave(persona, clave);
}

function permisosPorDefecto(rolCodigo) {
  if (rolCodigo === 'ADMINISTRADOR') {
    return [
      'personal.ver',
      'personal.crear',
      'personal.editar',
      'personal.editar_estado',
      'personal.reset_password',
      'roles.ver',
      'roles.crear',
      'roles.editar',
      'permisos.ver',
      'administracion.ver',
      'catalogos.ver',
      'catalogos.crear',
      'catalogos.editar',
      'catalogos.estado',
      'lugares_servicio.ver',
      'lugares_servicio.crear',
      'lugares_servicio.editar',
      'lugares_servicio.estado',
      'eas.ver',
      'eas.crear',
      'eas.editar',
      'eas.estado',
      'moviles.ver',
      'moviles.crear',
      'moviles.editar',
      'moviles.estado',
      'moviles.asignar',
      'dashboard.mantenimiento',
      'eventos.ver',
      'eventos.crear',
      'eventos.editar',
      'eventos.eliminar',
      'eventos.convocar',
      'eventos.publicar',
      'anuncios.ver',
      'anuncios.crear',
      'anuncios.editar',
      'anuncios.eliminar',
      'cartillas.ver',
      'cartillas.generar',
      'insignias.ver',
      'perfil.ver',
      'perfil.editar'
    ];
  }

  if (rolCodigo === 'OPERACIONES') {
    return [
      'personal.ver',
      'administracion.ver',
      'catalogos.ver',
      'lugares_servicio.ver',
      'lugares_servicio.crear',
      'lugares_servicio.editar',
      'lugares_servicio.estado',
      'eas.ver',
      'eas.crear',
      'eas.editar',
      'eas.estado',
      'moviles.ver',
      'moviles.crear',
      'moviles.editar',
      'moviles.estado',
      'moviles.asignar',
      'dashboard.mantenimiento',
      'eventos.ver',
      'eventos.crear',
      'eventos.editar',
      'eventos.convocar',
      'anuncios.ver',
      'anuncios.crear',
      'anuncios.editar',
      'cartillas.ver',
      'cartillas.generar',
      'insignias.ver',
      'perfil.ver',
      'perfil.editar'
    ];
  }

  if (rolCodigo === 'COMUNICACIONES') {
    return [
      'eventos.ver',
      'eventos.crear',
      'eventos.editar',
      'eventos.eliminar',
      'eventos.convocar',
      'eventos.publicar',
      'anuncios.ver',
      'anuncios.crear',
      'anuncios.editar',
      'anuncios.eliminar',
      'cartillas.ver',
      'cartillas.generar',
      'insignias.ver',
      'perfil.ver',
      'perfil.editar'
    ];
  }

  if (rolCodigo === 'AUDITOR') {
    return [
      'administracion.ver',
      'catalogos.ver',
      'personal.ver',
      'lugares_servicio.ver',
      'eas.ver',
      'moviles.ver',
      'auditoria.ver',
      'auditoria.detalle',
      'auditoria.exportar',
      'reportes.exportar',
      'eventos.ver',
      'cartillas.ver',
      'perfil.ver'
    ];
  }

  if (rolCodigo === 'RADIOPERADOR_SEGURA_EP') {
    return [
      'dashboard.mantenimiento',
      'eventos.ver',
      'servicios.ver',
      'novedades.crear',
      'cartillas.generar',
      'cartillas.ver',
      'perfil.ver',
      'perfil.editar'
    ];
  }

  if (rolCodigo === 'ENCARGADO') {
    return [
      'reportes.ver',
      'personal.ver_asignado',
      'cartillas.generar',
      'cartillas.ver',
      'perfil.ver',
      'perfil.editar'
    ];
  }

  return [
    'eventos.ver_convocado',
    'anuncios.ver',
    'cartillas.ver',
    'cartillas.generar',
    'insignias.ver',
    'perfil.ver'
  ];
}

function passwordDesdeFecha(fechaNacimiento) {
  const value = fechaNacimiento instanceof Date
    ? fechaNacimiento.toISOString().substring(0, 10)
    : fechaNacimiento.toString().substring(0, 10);
  const parts = value.includes('-') ? value.split('-') : value.split('/');

  if (parts.length !== 3) return '';
  if (value.includes('-')) return `${parts[2]}${parts[1]}${parts[0]}`;
  return `${parts[0].padStart(2, '0')}${parts[1].padStart(2, '0')}${parts[2]}`;
}

async function tieneColumnaFoto(connection) {
  const result = await connection.query(`
    SELECT COL_LENGTH('dbo.personal', 'foto_perfil_url') AS existe
  `);

  return Boolean(result[0]?.existe);
}

async function tieneColumnaPassword(connection) {
  const result = await connection.query(`
    SELECT COL_LENGTH('dbo.personal', 'password_hash') AS existe
  `);

  return Boolean(result[0]?.existe);
}

module.exports = router;
