<?php
$e = static fn(mixed $value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$tab = $tab ?? 'resumen';
$validTabs = ['resumen', 'permisos', 'menu', 'alcance', 'condiciones', 'campos', 'versiones', 'auditoria', 'cambios'];
if (!in_array($tab, $validTabs, true)) {
    $tab = 'resumen';
}
$tabUrl = static fn(string $t): string => '/configuracion?rol_id=' . (int)($selectedRoleId ?? 0) . '&tab=' . rawurlencode($t);
$tabActive = static fn(string $t): string => $tab === $t ? ' is-active' : '';
?>
<section class="dashboard admin-workspace">

<section class="page-header">
    <div>
        <p class="eyebrow">Sistema</p>
        <h1>Configuración</h1>
        <p>Permisos, menú, alcance y seguridad por rol</p>
    </div>
    <form method="get" action="/configuracion" class="config-role-switcher">
        <input type="hidden" name="tab" value="<?= $e($tab) ?>">
        <label>Rol activo
            <select name="rol_id" onchange="this.form.submit()">
                <?php foreach (($roles ?? []) as $role): ?>
                    <option value="<?= (int)$role['id'] ?>" <?= (int)$selectedRoleId === (int)$role['id'] ? 'selected' : '' ?>>
                        <?= $e($role['nombre'] ?? '') ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </label>
        <a class="button secondary" href="/dashboard">Volver</a>
    </form>
</section>

<?php if ($error): ?>
    <div class="alert error"><?= $e($error) ?></div>
<?php endif; ?>
<?php if (!empty($message)): ?>
    <div class="success"><?= $e($message) ?></div>
<?php endif; ?>

<nav class="admin-tabs" aria-label="Secciones de Configuración">
    <a class="<?= $tabActive('resumen') ?>" href="<?= $tabUrl('resumen') ?>">Resumen</a>
    <a class="<?= $tabActive('permisos') ?>" href="<?= $tabUrl('permisos') ?>">Permisos</a>
    <a class="<?= $tabActive('menu') ?>" href="<?= $tabUrl('menu') ?>">Menú</a>
    <a class="<?= $tabActive('alcance') ?>" href="<?= $tabUrl('alcance') ?>">Alcance</a>
    <a class="<?= $tabActive('condiciones') ?>" href="<?= $tabUrl('condiciones') ?>">Condiciones</a>
    <a class="<?= $tabActive('campos') ?>" href="<?= $tabUrl('campos') ?>">Campos por rol</a>
    <a class="<?= $tabActive('versiones') ?>" href="<?= $tabUrl('versiones') ?>">Versiones</a>
    <a class="<?= $tabActive('auditoria') ?>" href="<?= $tabUrl('auditoria') ?>">Auditoría</a>
    <a class="<?= $tabActive('cambios') ?>" href="<?= $tabUrl('cambios') ?>">Registro de cambios</a>
</nav>

<?php if ($tab === 'resumen'): ?>
<?php
$configSummary = [
    ['permisos', 'Permisos', count($permissions ?? []), 'Permisos disponibles para asignar a los roles.', '✓'],
    ['menu', 'Menú', count($menu ?? []), 'Elementos del menú del rol seleccionado.', '☰'],
    ['alcance', 'Alcance', count($scopes ?? []), 'Reglas de visibilidad de datos por rol.', '⇥'],
    ['condiciones', 'Condiciones', count($conditions ?? []), 'Filtros dinámicos aplicados al rol.', '⚙'],
    ['campos', 'Campos', count($fields ?? []), 'Niveles de acceso a campos sensibles.', '▦'],
    ['versiones', 'Versiones', count($versions ?? []), 'Puntos de restauración de la configuración.', '▤'],
    ['auditoria', 'Auditoría', count($audit ?? []), 'Eventos registrados sobre este rol.', '◉'],
    ['cambios', 'Cambios', count($cambios ?? []), 'Historial de actualizaciones de la plataforma.', '↻'],
];
?>
<header class="admin-section-heading">
    <div><span class="eyebrow">Centro de configuración</span><h2>Resumen</h2><p>Seleccione un rol y acceda a cada área de configuración.</p></div>
    <span><?= count($roles ?? []) ?> roles</span>
</header>

<div class="config-role-pills" role="list" aria-label="Roles disponibles">
    <?php foreach (($roles ?? []) as $role): ?>
        <?php $isCurrent = (int)$selectedRoleId === (int)$role['id']; ?>
        <a class="config-role-pill<?= $isCurrent ? ' is-active' : '' ?>" href="/configuracion?rol_id=<?= (int)$role['id'] ?>&tab=resumen" data-role-switch="<?= (int)$role['id'] ?>" role="listitem">
            <i><?= $isCurrent ? '●' : '○' ?></i>
            <span><strong><?= $e($role['nombre'] ?? '') ?></strong><small><?= count($role['permisos'] ?? []) ?> permisos</small></span>
        </a>
    <?php endforeach; ?>
</div>

<div class="admin-summary-grid config-summary-grid">
    <?php foreach ($configSummary as [$target, $title, $value, $description, $icon]): ?>
        <a href="<?= $tabUrl($target) ?>"><i><?= $icon ?></i><span><strong><?= (int)$value ?></strong><b><?= $e($title) ?></b><small><?= $e($description) ?></small></span></a>
    <?php endforeach; ?>
</div>
<?php endif; ?>

<?php if ($tab === 'permisos'): ?>
<?php
$activePermissionIds = [];
foreach (($roles ?? []) as $role) {
    if ((int)$role['id'] === (int)$selectedRoleId) {
        foreach (($role['permisos'] ?? []) as $permission) {
            $activePermissionIds[] = (int)($permission['id'] ?? 0);
        }
    }
}
$permissionGroups = [];
foreach (($permissions ?? []) as $permission) {
    $permissionGroups[$permission['modulo'] ?? 'otros'][] = $permission;
}
ksort($permissionGroups);
?>
<header class="admin-section-heading">
    <div><span class="eyebrow">Control de acceso</span><h2>Permisos por rol</h2><p>Marque los permisos que se otorgan al rol seleccionado. Se agrupan automáticamente por módulo.</p></div>
    <span><?= count($permissions ?? []) ?> permisos</span>
</header>
<div class="perm-toolbar">
    <input type="search" id="permSearch" class="perm-search" placeholder="Buscar permiso… ej. personal.ver" autocomplete="off">
    <span class="perm-counter" id="permCounter">0 de <?= count($permissions ?? []) ?> permisos seleccionados</span>
</div>
<form method="post" action="/configuracion/permisos" class="form-panel admin-form" id="permisosForm">
    <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
    <?php foreach ($permissionGroups as $modulo => $items): ?>
        <div class="config-perm-group" data-perm-group="<?= $e($modulo) ?>">
            <button type="button" class="config-perm-toggle" aria-expanded="true" title="Plegar/desplegar grupo">⌄</button>
            <span class="config-perm-name"><?= $e(ucfirst((string)$modulo)) ?></span>
            <span class="config-perm-count" data-group-count>0/<?= count($items) ?></span>
            <span class="config-perm-actions">
                <button type="button" data-perm-action="all" title="Marcar todos los permisos de este módulo">Seleccionar todo</button>
                <button type="button" data-perm-action="none" title="Quitar todos los permisos de este módulo">Quitar todos</button>
            </span>
        </div>
        <div class="permission-grid" data-perm-grid="<?= $e($modulo) ?>">
            <?php foreach ($items as $permission): ?>
                <label class="check-row" title="<?= $e($permission['descripcion'] ?? '') ?>">
                    <input type="checkbox" name="permiso_ids[]" value="<?= (int)$permission['id'] ?>" <?= in_array((int)$permission['id'], $activePermissionIds, true) ? 'checked' : '' ?>>
                    <span><?= $e($permission['codigo']) ?></span>
                </label>
            <?php endforeach; ?>
        </div>
    <?php endforeach; ?>
    <button type="submit">Guardar permisos</button>
</form>
<?php endif; ?>

<?php if ($tab === 'menu'): ?>
<?php
// Conjunto de iconos del selector: los reales del catálogo de módulos + los canónicos del sidebar.
$iconSet = [];
foreach (($modules ?? []) as $module) {
    $icon = (string)($module['icono'] ?? '');
    if ($icon !== '' && !isset($iconSet[$icon])) {
        $iconSet[$icon] = (string)($module['nombre'] ?? 'Icono');
    }
}
foreach ([
    '▣' => 'Panel principal', '♙' => 'Administración', '⌖' => 'Distribución',
    '☐' => 'Panel de Asistencia', '▧' => 'Eventos y anuncios', '▤' => 'Cartillas',
    '♜' => 'Insignias', '♧' => 'Alertas / Soporte', '⚙' => 'Configuración',
    '★' => 'Destacado', '◈' => 'Punto destacado', '◉' => 'Marca de evento', '⌂' => 'Inicio',
] as $glyph => $label) {
    if (!isset($iconSet[$glyph])) {
        $iconSet[$glyph] = $label;
    }
}
?>
<header class="admin-section-heading">
    <div><span class="eyebrow">Navegación</span><h2>Constructor visual de menú</h2><p>Arrastre las filas para cambiar el orden y ajuste etiqueta, icono, grupo, visibilidad y badge.</p></div>
    <span><?= count($menu ?? []) ?> elementos</span>
</header>
<div class="menu-builder-grid">
    <form method="post" action="/configuracion/menu" class="form-panel admin-form" id="menuBuilderForm">
        <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
        <div class="drag-list" id="menuDragList">
            <?php foreach (($menu ?? []) as $index => $item): ?>
                <article class="drag-row" draggable="true" data-menu-row>
                    <span class="drag-handle">↕</span>
                    <input type="hidden" name="items[<?= $index ?>][id]" value="<?= (int)$item['id'] ?>">
                    <input type="hidden" name="items[<?= $index ?>][modulo_id]" value="<?= (int)$item['modulo_id'] ?>">
                    <label>Orden<input class="order-input" type="number" name="items[<?= $index ?>][orden]" value="<?= (int)$item['orden'] ?>"></label>
                    <label>Etiqueta<input name="items[<?= $index ?>][nombre_visual]" value="<?= $e(($item['nombre_visual'] ?? '') ?: ($item['nombre'] ?? '')) ?>"></label>
                    <label class="menu-icon-field">Icono
                        <span class="menu-icon-combo">
                            <button type="button" class="menu-icon-preview" title="Elegir icono" aria-label="Elegir icono"><?= $e(($item['icono_visual'] ?? '') ?: ($item['icono'] ?? '')) ?: '▫' ?></button>
                            <input name="items[<?= $index ?>][icono_visual]" value="<?= $e(($item['icono_visual'] ?? '') ?: ($item['icono'] ?? '')) ?>" autocomplete="off">
                        </span>
                        <small>Haz clic en el cuadro para elegir un icono</small>
                    </label>
                    <label>Grupo<input name="items[<?= $index ?>][grupo]" value="<?= $e($item['grupo'] ?? '') ?>"></label>
                    <label>Badge<input name="items[<?= $index ?>][color_badge]" value="<?= $e($item['color_badge'] ?? '') ?>"></label>
                    <label class="check-row"><input type="checkbox" name="items[<?= $index ?>][visible]" <?= !empty($item['visible']) ? 'checked' : '' ?>> Visible</label>
                    <label class="check-row"><input type="checkbox" name="items[<?= $index ?>][habilitado]" <?= !empty($item['habilitado']) ? 'checked' : '' ?>> Habilitado</label>
                    <label class="check-row"><input type="checkbox" name="items[<?= $index ?>][pagina_inicial]" <?= !empty($item['pagina_inicial']) ? 'checked' : '' ?>> Inicio</label>
                    <label class="check-row"><input type="checkbox" name="items[<?= $index ?>][mostrar_badge]" <?= !empty($item['mostrar_badge']) ? 'checked' : '' ?>> Badge</label>
                </article>
            <?php endforeach; ?>
        </div>
        <button type="submit">Guardar menú</button>
    </form>
    <div class="menu-icon-picker" id="menuIconPicker" hidden role="dialog" aria-label="Selector de iconos">
        <div class="menu-icon-picker-head"><strong>Iconos del menú</strong><button type="button" class="menu-icon-picker-close" title="Cerrar" aria-label="Cerrar">✕</button></div>
        <div class="menu-icon-picker-grid">
            <?php foreach ($iconSet as $icon => $label): ?>
                <button type="button" class="menu-icon-option" title="<?= $e($label) ?>" aria-label="<?= $e($label) ?>"><?= $e($icon) ?></button>
            <?php endforeach; ?>
        </div>
    </div>
    <aside class="menu-preview-panel">
        <div class="admin-form-title"><div><p class="eyebrow">Vista previa</p><h2>Cómo se verá el menú</h2></div></div>
        <div class="menu-preview" id="menuPreview" aria-live="polite"></div>
        <p class="menu-preview-hint">Los elementos con grupo <strong>PRINCIPAL</strong> se muestran como entrada principal; el resto se agrupa bajo la última entrada principal.</p>
    </aside>
</div>
<?php endif; ?>

<?php if ($tab === 'alcance'): ?>
<header class="admin-section-heading">
    <div><span class="eyebrow">Seguridad de datos</span><h2>Alcance de datos por rol</h2><p>Limita los datos que el rol puede ver: propios, de área, de equipo, por distrito o globales.</p></div>
    <span><?= count($scopes ?? []) ?> reglas</span>
</header>
<div class="content-grid">
    <form method="post" action="/configuracion/alcance" class="form-panel admin-form">
        <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
        <div class="form-grid">
            <label>ID para editar<input type="number" name="id" placeholder="Vacío para crear"></label>
            <label>Módulo
                <select name="modulo_id" required>
                    <?php foreach (($modules ?? []) as $module): ?>
                        <option value="<?= (int)$module['id'] ?>"><?= $e($module['nombre'] ?? '') ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Tipo de alcance
                <select name="tipo_alcance">
                    <option value="propio">Propio</option>
                    <option value="area">Área</option>
                    <option value="equipo">Equipo</option>
                    <option value="distrito">Distrito</option>
                    <option value="global">Global</option>
                    <option value="personalizado">Personalizado</option>
                </select>
            </label>
            <label class="span-2">Configuración JSON<textarea name="configuracion_json" rows="4" placeholder='{"campo":"valor"}'></textarea></label>
        </div>
        <button type="submit">Guardar alcance</button>
    </form>
    <div class="work-card">
        <div class="admin-form-title"><div><p class="eyebrow">Reglas vigentes</p><h2>Alcances del rol</h2></div></div>
        <?php if (empty($scopes ?? [])): ?>
            <div class="empty-state">Este rol no tiene reglas de alcance configuradas</div>
        <?php else: ?>
            <div class="mini-list">
                <?php foreach (($scopes ?? []) as $scope): ?>
                    <div><strong>#<?= (int)$scope['id'] ?></strong> <?= $e($scope['modulo'] ?? '') ?> · <?= $e($scope['tipo_alcance'] ?? '') ?></div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</div>
<?php endif; ?>

<?php if ($tab === 'condiciones'): ?>
<header class="admin-section-heading">
    <div><span class="eyebrow">Filtros dinámicos</span><h2>Condiciones del rol</h2><p>Reglas de filtrado adicionales aplicadas a las consultas del rol.</p></div>
    <span><?= count($conditions ?? []) ?> condiciones</span>
</header>
<form method="post" action="/configuracion/condiciones" class="form-panel admin-form">
    <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
    <div class="form-grid">
        <label>ID para editar<input type="number" name="id" placeholder="Vacío para crear"></label>
        <label>Módulo
            <select name="modulo_id">
                <option value="">Global</option>
                <?php foreach (($modules ?? []) as $module): ?>
                    <option value="<?= (int)$module['id'] ?>"><?= $e($module['nombre'] ?? '') ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>Campo<input name="campo" required></label>
        <label>Operador
            <select name="operador">
                <option>=</option>
                <option>!=</option>
                <option>LIKE</option>
                <option>IN</option>
                <option>&gt;</option>
                <option>&lt;</option>
            </select>
        </label>
        <label>Valor<input name="valor"></label>
        <label>Agrupador
            <select name="agrupador"><option>AND</option><option>OR</option></select>
        </label>
        <label class="check-row"><input type="checkbox" name="estado" checked> Activa</label>
    </div>
    <button type="submit">Guardar condición</button>
</form>
<div class="table-wrap">
    <table>
        <thead><tr><th>ID</th><th>Módulo</th><th>Condición</th><th>Estado</th><th>Acción</th></tr></thead>
        <tbody>
        <?php if (empty($conditions ?? [])): ?>
            <tr><td colspan="5" class="empty-state">No hay condiciones configuradas para este rol</td></tr>
        <?php else: ?>
            <?php foreach (($conditions ?? []) as $condition): ?>
                <tr>
                    <td><?= (int)$condition['id'] ?></td>
                    <td><?= $e($condition['modulo'] ?? 'Global') ?></td>
                    <td><?= $e(($condition['campo'] ?? '') . ' ' . ($condition['operador'] ?? '') . ' ' . ($condition['valor'] ?? '')) ?></td>
                    <td><span class="pill"><?= !empty($condition['estado']) ? 'Activa' : 'Inactiva' ?></span></td>
                    <td class="actions">
                        <form method="post" action="/configuracion/condiciones/eliminar" class="inline-form">
                            <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
                            <input type="hidden" name="id" value="<?= (int)$condition['id'] ?>">
                            <button type="submit" class="danger">Eliminar</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
        <?php endif; ?>
        </tbody>
    </table>
</div>
<?php endif; ?>

<?php if ($tab === 'campos'): ?>
<header class="admin-section-heading">
    <div><span class="eyebrow">Seguridad de datos</span><h2>Campos por rol</h2><p>Define el nivel de acceso (ninguno / lectura / edición) y el enmascarado de cada campo sensible.</p></div>
    <span><?= count($fields ?? []) ?> campos</span>
</header>
<form method="post" action="/configuracion/campos" class="form-panel admin-form config-fields">
    <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
    <div class="table-wrap embedded">
        <table>
            <thead><tr><th>Módulo</th><th>Campo</th><th>Clasificación</th><th>Nivel de acceso</th><th>Enmascarado</th></tr></thead>
            <tbody>
            <?php foreach (($fields ?? []) as $field): ?>
                <tr>
                    <td><?= $e($field['modulo'] ?? '') ?></td>
                    <td><strong><?= $e($field['nombre'] ?? '') ?></strong><small><?= $e($field['codigo'] ?? '') ?></small></td>
                    <td><?= $e($field['clasificacion'] ?? '') ?></td>
                    <td><select name="fields[<?= (int)$field['campo_id'] ?>][nivel_acceso]"><?php foreach (['ninguno', 'lectura', 'edicion'] as $level): ?><option value="<?= $level ?>" <?= ($field['nivel_acceso'] ?? '') === $level ? 'selected' : '' ?>><?= ucfirst($level) ?></option><?php endforeach; ?></select></td>
                    <td><input type="checkbox" name="fields[<?= (int)$field['campo_id'] ?>][enmascarado]" <?= !empty($field['enmascarado']) ? 'checked' : '' ?>></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <button type="submit">Guardar campos</button>
</form>
<?php endif; ?>

<?php if ($tab === 'versiones'): ?>
<header class="admin-section-heading">
    <div><span class="eyebrow">Respaldo lógico</span><h2>Versiones de configuración</h2><p>Historial de cambios de la configuración del rol. Cada versión es un punto de restauración.</p></div>
    <span>v<?= (int)($version['version'] ?? 0) ?></span>
</header>
<div class="content-grid config-history-grid">
    <div class="work-card">
        <div class="admin-form-title"><div><p class="eyebrow">Nueva versión</p><h2>Crear versión</h2></div></div>
        <form method="post" action="/configuracion/versiones" class="form-panel admin-form">
            <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
            <label>Comentario<input name="comentario" placeholder="Motivo o alcance de esta versión"></label>
            <button>Crear versión</button>
        </form>
        <div class="version-actual">
            <p class="eyebrow">Versión actual</p>
            <p><?= $e($version['resumen'] ?? 'Sin versiones registradas') ?></p>
        </div>
    </div>
    <div class="work-card">
        <div class="admin-form-title"><div><p class="eyebrow">Historial</p><h2>Línea de tiempo</h2></div><span><?= count($versions ?? []) ?> versiones</span></div>
        <?php if (empty($versions ?? [])): ?>
            <div class="empty-state">Aún no hay versiones registradas para este rol</div>
        <?php else: ?>
            <div class="config-timeline">
                <?php foreach (($versions ?? []) as $item): ?>
                    <article><strong>v<?= (int)$item['version'] ?></strong><span><?= $e($item['estado'] ?? '') ?></span><p><?= $e($item['comentario'] ?? 'Sin comentario') ?></p><small><?= $e($item['creado_por_nombre'] ?? 'Sistema') ?> · <?= $e($item['fecha_creacion'] ?? '') ?></small></article>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</div>
<?php endif; ?>

<?php if ($tab === 'auditoria'): ?>
<header class="admin-section-heading">
    <div><span class="eyebrow">Trazabilidad</span><h2>Auditoría del rol</h2><p>Registro de acciones realizadas sobre la configuración de este rol.</p></div>
    <span><?= count($audit ?? []) ?> eventos</span>
</header>
<div class="work-card">
    <?php if (empty($audit ?? [])): ?>
        <div class="empty-state">Sin eventos de auditoría para este rol</div>
    <?php else: ?>
        <div class="config-timeline audit">
            <?php foreach (($audit ?? []) as $item): ?>
                <article><strong><?= $e($item['accion'] ?? '') ?></strong><span><?= $e($item['rol'] ?? '') ?></span><p><?= $e($item['usuario'] ?? 'Sistema') ?></p><small><?= $e($item['fecha'] ?? '') ?> · <?= $e($item['ip'] ?? '') ?></small></article>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</div>
<?php endif; ?>

<?php if ($tab === 'cambios'): ?>
<header class="admin-section-heading">
    <div><span class="eyebrow">Historial de actualizaciones</span><h2>Registro de cambios</h2><p>Mejoras, correcciones y funcionalidades implementadas en la plataforma.</p></div>
    <span><?= count($cambios ?? []) ?> registros</span>
</header>
<section class="work-card full changelog-section">
    <form method="post" action="/configuracion/cambios" class="changelog-form">
        <div class="form-grid">
            <label>Desarrollador<input type="text" name="desarrollador" required placeholder="Nombre del desarrollador"></label>
            <label>Título de actualización<input type="text" name="titulo" required placeholder="Ej: Módulo de cartillas mejorado"></label>
            <label class="span-2">Detalle de mejoras aplicadas<textarea name="detalle" rows="4" required placeholder="Describa las mejoras, correcciones o funcionalidades implementadas..."></textarea></label>
        </div>
        <button type="submit">Registrar cambio</button>
    </form>

    <div class="changelog-timeline">
        <?php if (empty($cambios ?? [])): ?>
            <div class="empty-state">No hay cambios registrados</div>
        <?php else: ?>
            <?php foreach ($cambios as $cambio): ?>
                <article class="changelog-entry">
                    <div class="changelog-entry-header">
                        <div class="changelog-meta">
                            <strong><?= $e($cambio['titulo'] ?? '') ?></strong>
                            <span class="changelog-author"><?= $e($cambio['desarrollador'] ?? '') ?></span>
                        </div>
                        <div class="changelog-datetime">
                            <span class="changelog-date"><?= $e($cambio['fecha'] ?? '') ?></span>
                            <span class="changelog-time"><?= $e($cambio['hora'] ?? '') ?></span>
                        </div>
                        <form method="post" action="/configuracion/cambios/eliminar" class="inline-form">
                            <input type="hidden" name="id" value="<?= (int)$cambio['id'] ?>">
                            <button type="submit" class="danger" title="Eliminar registro">✕</button>
                        </form>
                    </div>
                    <?php if (!empty($cambio['detalle'])): ?>
                        <p class="changelog-detail"><?= nl2br($e($cambio['detalle'])) ?></p>
                    <?php endif; ?>
                </article>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>
</section>
<?php endif; ?>

</section>
