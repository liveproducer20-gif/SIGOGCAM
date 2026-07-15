const repo = require('../repositories/configuracion.repository');
const { asyncHandler } = require('../middleware/async-handler');

// ---- Módulos ----
const listarModulos = asyncHandler(async (req, res) => {
    const modulos = await repo.listarModulos();
    res.json({ ok: true, data: modulos });
});

const obtenerModulo = asyncHandler(async (req, res) => {
    const modulo = await repo.obtenerModulo(req.params.id);
    if (!modulo) return res.status(404).json({ ok: false, mensaje: 'Módulo no encontrado' });
    res.json({ ok: true, data: modulo });
});

const crearModulo = asyncHandler(async (req, res) => {
    const modulo = await repo.crearModulo(req.body);
    await repo.registrarAuditoria({
        modulo: 'configuracion', accion: 'crear_modulo',
        detalle: `Módulo creado: ${modulo.nombre} (${modulo.codigo})`,
        usuarioId: req.user.id, datosNuevos: modulo
    });
    res.status(201).json({ ok: true, data: modulo });
});

const actualizarModulo = asyncHandler(async (req, res) => {
    const anterior = await repo.obtenerModulo(req.params.id);
    if (!anterior) return res.status(404).json({ ok: false, mensaje: 'Módulo no encontrado' });
    const modulo = await repo.actualizarModulo(req.params.id, req.body);
    await repo.registrarAuditoria({
        modulo: 'configuracion', accion: 'actualizar_modulo',
        detalle: `Módulo actualizado: ${modulo.nombre}`,
        usuarioId: req.user.id, datosAntiguos: anterior, datosNuevos: modulo
    });
    res.json({ ok: true, data: modulo });
});

const eliminarModulo = asyncHandler(async (req, res) => {
    const anterior = await repo.obtenerModulo(req.params.id);
    if (!anterior) return res.status(404).json({ ok: false, mensaje: 'Módulo no encontrado' });
    await repo.eliminarModulo(req.params.id);
    await repo.registrarAuditoria({
        modulo: 'configuracion', accion: 'eliminar_modulo',
        detalle: `Módulo eliminado: ${anterior.nombre}`,
        usuarioId: req.user.id, datosAntiguos: anterior
    });
    res.json({ ok: true, mensaje: 'Módulo eliminado' });
});

// ---- Permisos de Módulo ----
const listarPermisosModulo = asyncHandler(async (req, res) => {
    const modulo = await repo.obtenerModulo(req.params.id);
    if (!modulo) return res.status(404).json({ ok: false, mensaje: 'Módulo no encontrado' });
    const permisos = await repo.listarPermisosPorModulo(modulo.id);
    res.json({ ok: true, data: permisos });
});

// ---- Menú por Rol ----
const obtenerMenuRol = asyncHandler(async (req, res) => {
    const items = await repo.obtenerMenuRol(req.params.rolId);
    res.json({ ok: true, data: items });
});

const guardarMenuRol = asyncHandler(async (req, res) => {
    const anterior = await repo.obtenerMenuRol(req.params.rolId);
    await repo.guardarMenuRol(req.params.rolId, req.body.items || []);
    await repo.registrarAuditoria({
        rolId: req.params.rolId, modulo: 'configuracion', accion: 'guardar_menu_rol',
        detalle: `Menú actualizado para rol ${req.params.rolId}`,
        usuarioId: req.user.id, datosAntiguos: anterior, datosNuevos: req.body.items
    });
    res.json({ ok: true, mensaje: 'Menú del rol actualizado' });
});

// ---- Mi Estructura (menú dinámico) ----
const miEstructura = asyncHandler(async (req, res) => {
    // Resolver desde el usuario evita depender de alias de rol almacenados en
    // tokens antiguos (por ejemplo AGENTE/USUARIO o AUDITORIA/AUDITOR).
    const items = await repo.miEstructura(req.user.id);
    const arbol = construirArbol(items);
    res.json({ ok: true, data: arbol });
});

function construirArbol(items) {
    const mapa = {};
    const raices = [];
    for (const item of items) {
        mapa[item.id] = { ...item, hijos: [] };
    }
    for (const item of items) {
        if (item.modulo_padre_id && mapa[item.modulo_padre_id]) {
            mapa[item.modulo_padre_id].hijos.push(mapa[item.id]);
        } else {
            raices.push(mapa[item.id]);
        }
    }
    return raices;
}

// ---- Alcance de Datos ----
const obtenerAlcanceRol = asyncHandler(async (req, res) => {
    const items = await repo.obtenerAlcanceRol(req.params.rolId);
    res.json({ ok: true, data: items });
});

const guardarAlcanceRol = asyncHandler(async (req, res) => {
    const anterior = await repo.obtenerAlcanceRol(req.params.rolId);
    await repo.guardarAlcanceRol(req.params.rolId, req.body.items || []);
    await repo.registrarAuditoria({
        rolId: req.params.rolId, modulo: 'configuracion', accion: 'guardar_alcance_rol',
        detalle: `Alcance de datos actualizado para rol ${req.params.rolId}`,
        usuarioId: req.user.id, datosAntiguos: anterior, datosNuevos: req.body.items
    });
    res.json({ ok: true, mensaje: 'Alcance de datos actualizado' });
});

// ---- Campos por Rol ----
const obtenerCamposRol = asyncHandler(async (req, res) => {
    const items = await repo.obtenerCamposRol(req.params.rolId);
    res.json({ ok: true, data: items });
});

const guardarCamposRol = asyncHandler(async (req, res) => {
    const anterior = await repo.obtenerCamposRol(req.params.rolId);
    await repo.guardarCamposRol(req.params.rolId, req.body.items || []);
    await repo.registrarAuditoria({
        rolId: req.params.rolId, modulo: 'configuracion', accion: 'guardar_campos_rol',
        detalle: `Permisos de campos actualizados para rol ${req.params.rolId}`,
        usuarioId: req.user.id, datosAntiguos: anterior, datosNuevos: req.body.items
    });
    res.json({ ok: true, mensaje: 'Permisos de campos actualizados' });
});

// ---- Versiones ----
const listarVersiones = asyncHandler(async (req, res) => {
    const versiones = await repo.listarVersiones(req.params.rolId);
    res.json({ ok: true, data: versiones });
});

const crearVersion = asyncHandler(async (req, res) => {
    const datosJson = req.body.datos_json || '{}';
    const version = await repo.crearVersion(req.params.rolId, datosJson, req.body.descripcion, req.user.id);
    await repo.registrarAuditoria({
        rolId: req.params.rolId, modulo: 'configuracion', accion: 'crear_version',
        detalle: `Versión ${version.version} creada para rol ${req.params.rolId}`,
        usuarioId: req.user.id, datosNuevos: version
    });
    res.status(201).json({ ok: true, data: version });
});

const restaurarVersion = asyncHandler(async (req, res) => {
    const version = await repo.obtenerVersion(req.params.versionId);
    if (!version) return res.status(404).json({ ok: false, mensaje: 'Versión no encontrada' });
    const datos = JSON.parse(version.datos_json);
    if (datos.menu) await repo.guardarMenuRol(req.params.rolId, datos.menu);
    if (datos.alcance) await repo.guardarAlcanceRol(req.params.rolId, datos.alcance);
    if (datos.campos) await repo.guardarCamposRol(req.params.rolId, datos.campos);
    await repo.registrarAuditoria({
        rolId: req.params.rolId, modulo: 'configuracion', accion: 'restaurar_version',
        detalle: `Versión ${version.version} restaurada para rol ${req.params.rolId}`,
        usuarioId: req.user.id, datosNuevos: datos
    });
    res.json({ ok: true, mensaje: `Versión ${version.version} restaurada` });
});

// ---- Auditoría ----
const listarAuditoria = asyncHandler(async (req, res) => {
    const items = await repo.listarAuditoria(req.query);
    res.json({ ok: true, data: items });
});

// ---- Campos del Sistema ----
const listarCamposSistema = asyncHandler(async (req, res) => {
    const campos = await repo.listarCamposSistema(req.query.entidad);
    res.json({ ok: true, data: campos });
});

module.exports = {
    listarModulos, obtenerModulo, crearModulo, actualizarModulo, eliminarModulo,
    listarPermisosModulo,
    obtenerMenuRol, guardarMenuRol,
    miEstructura,
    obtenerAlcanceRol, guardarAlcanceRol,
    obtenerCamposRol, guardarCamposRol,
    listarVersiones, crearVersion, restaurarVersion,
    listarAuditoria,
    listarCamposSistema
};
