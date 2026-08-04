<section class="page-header">
    <div>
        <p class="eyebrow">Sistema</p>
        <h1>Configuración</h1>
    </div>
    <a class="button secondary" href="/dashboard">Volver</a>
</section>

<section class="work-card full config-fields">
    <div class="admin-form-title"><div><p class="eyebrow">Seguridad de datos</p><h2>Campos por rol</h2></div><span><?= count($fields ?? []) ?> campos</span></div>
    <form method="post" action="/configuracion/campos"><input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>"><div class="table-wrap embedded"><table><thead><tr><th>Módulo</th><th>Campo</th><th>Clasificación</th><th>Nivel de acceso</th><th>Enmascarado</th></tr></thead><tbody><?php foreach(($fields ?? []) as $field): ?><tr><td><?= htmlspecialchars($field['modulo'] ?? '') ?></td><td><strong><?= htmlspecialchars($field['nombre'] ?? '') ?></strong><small><?= htmlspecialchars($field['codigo'] ?? '') ?></small></td><td><?= htmlspecialchars($field['clasificacion'] ?? '') ?></td><td><select name="fields[<?= (int)$field['campo_id'] ?>][nivel_acceso]"><?php foreach(['ninguno','lectura','edicion'] as $level): ?><option value="<?= $level ?>" <?= ($field['nivel_acceso']??'')===$level?'selected':'' ?>><?= ucfirst($level) ?></option><?php endforeach; ?></select></td><td><input type="checkbox" name="fields[<?= (int)$field['campo_id'] ?>][enmascarado]" <?= !empty($field['enmascarado'])?'checked':'' ?>></td></tr><?php endforeach; ?></tbody></table></div><button type="submit">Guardar campos</button></form>
</section>

<section class="content-grid config-history-grid">
    <div class="work-card"><div class="admin-form-title"><div><p class="eyebrow">Respaldo lógico</p><h2>Versiones</h2></div></div><form method="post" action="/configuracion/versiones"><input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>"><label>Comentario<input name="comentario" placeholder="Motivo o alcance de esta versión"></label><button>Crear versión</button></form><div class="config-timeline"><?php foreach(($versions ?? []) as $item): ?><article><strong>v<?= (int)$item['version'] ?></strong><span><?= htmlspecialchars($item['estado']) ?></span><p><?= htmlspecialchars($item['comentario'] ?: 'Sin comentario') ?></p><small><?= htmlspecialchars($item['creado_por_nombre'] ?? 'Sistema') ?> · <?= htmlspecialchars($item['fecha_creacion']) ?></small></article><?php endforeach; ?></div></div>
    <div class="work-card"><div class="admin-form-title"><div><p class="eyebrow">Trazabilidad</p><h2>Auditoría del rol</h2></div><span><?= count($audit ?? []) ?> eventos</span></div><div class="config-timeline audit"><?php foreach(($audit ?? []) as $item): ?><article><strong><?= htmlspecialchars($item['accion'] ?? '') ?></strong><span><?= htmlspecialchars($item['rol'] ?? '') ?></span><p><?= htmlspecialchars($item['usuario'] ?? 'Sistema') ?></p><small><?= htmlspecialchars($item['fecha'] ?? '') ?> · <?= htmlspecialchars($item['ip'] ?? '') ?></small></article><?php endforeach; ?></div></div>
</section>

<section class="work-card full changelog-section">
    <div class="admin-form-title">
        <div><p class="eyebrow">Historial de actualizaciones</p><h2>Registro de cambios</h2></div>
        <span><?= count($cambios ?? []) ?> registros</span>
    </div>

    <form method="post" action="/configuracion/cambios" class="changelog-form">
        <div class="form-grid">
            <label>Desarrollador<input type="text" name="desarrollador" required placeholder="Nombre del desarrollador"></label>
            <label>Título de actualización<input type="text" name="titulo" required placeholder="Ej: Módulo de cartillas mejorado"></label>
            <label class="span-2">Detalle de mejoras aplicadas<textarea name="detalle" rows="4" required placeholder="Describa las mejoras, correcciones o funcionalidades implementadas..."></textarea></label>
        </div>
        <button type="submit">Registrar cambio</button>
    </form>

    <div class="changelog-timeline">
        <?php if (empty($cambios)): ?>
            <div class="empty-state">No hay cambios registrados</div>
        <?php else: ?>
            <?php foreach ($cambios as $cambio): ?>
                <article class="changelog-entry">
                    <div class="changelog-entry-header">
                        <div class="changelog-meta">
                            <strong><?= htmlspecialchars($cambio['titulo'] ?? '') ?></strong>
                            <span class="changelog-author"><?= htmlspecialchars($cambio['desarrollador'] ?? '') ?></span>
                        </div>
                        <div class="changelog-datetime">
                            <span class="changelog-date"><?= htmlspecialchars($cambio['fecha'] ?? '') ?></span>
                            <span class="changelog-time"><?= htmlspecialchars($cambio['hora'] ?? '') ?></span>
                        </div>
                        <form method="post" action="/configuracion/cambios/eliminar" class="inline-form">
                            <input type="hidden" name="id" value="<?= (int)$cambio['id'] ?>">
                            <button type="submit" class="danger" title="Eliminar registro">✕</button>
                        </form>
                    </div>
                    <?php if (!empty($cambio['detalle'])): ?>
                        <p class="changelog-detail"><?= nl2br(htmlspecialchars($cambio['detalle'])) ?></p>
                    <?php endif; ?>
                </article>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>
</section>

<?php if ($error): ?>
    <div class="alert error"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if (!empty($message)): ?>
    <div class="success"><?= htmlspecialchars($message) ?></div>
<?php endif; ?>

<section class="work-card full">
    <h2>Versión actual</h2>
    <p><?= htmlspecialchars($version['resumen'] ?? 'Sin versiones registradas') ?></p>
    <form method="get" action="/configuracion" class="form-grid">
        <label>Rol activo
            <select name="rol_id" onchange="this.form.submit()">
                <?php foreach ($roles as $role): ?>
                    <option value="<?= (int)$role['id'] ?>" <?= (int)$selectedRoleId === (int)$role['id'] ? 'selected' : '' ?>>
                        <?= htmlspecialchars($role['nombre'] ?? '') ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </label>
    </form>
</section>

<section class="work-card full">
    <h2>Constructor visual de menú</h2>
    <form method="post" action="/configuracion/menu" id="menuBuilderForm">
        <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
        <div class="drag-list" id="menuDragList">
            <?php foreach (($menu ?? []) as $index => $item): ?>
                <article class="drag-row" draggable="true">
                    <span class="drag-handle">↕</span>
                    <input type="hidden" name="items[<?= $index ?>][id]" value="<?= (int)$item['id'] ?>">
                    <input type="hidden" name="items[<?= $index ?>][modulo_id]" value="<?= (int)$item['modulo_id'] ?>">
                    <label>Orden<input class="order-input" type="number" name="items[<?= $index ?>][orden]" value="<?= (int)$item['orden'] ?>"></label>
                    <label>Etiqueta<input name="items[<?= $index ?>][nombre_visual]" value="<?= htmlspecialchars($item['nombre_visual'] ?: $item['nombre']) ?>"></label>
                    <label>Icono<input name="items[<?= $index ?>][icono_visual]" value="<?= htmlspecialchars($item['icono_visual'] ?: $item['icono'] ?: '') ?>"></label>
                    <label>Grupo<input name="items[<?= $index ?>][grupo]" value="<?= htmlspecialchars($item['grupo'] ?? '') ?>"></label>
                    <label>Badge<input name="items[<?= $index ?>][color_badge]" value="<?= htmlspecialchars($item['color_badge'] ?? '') ?>"></label>
                    <label class="check-row"><input type="checkbox" name="items[<?= $index ?>][visible]" <?= !empty($item['visible']) ? 'checked' : '' ?>> Visible</label>
                    <label class="check-row"><input type="checkbox" name="items[<?= $index ?>][habilitado]" <?= !empty($item['habilitado']) ? 'checked' : '' ?>> Habilitado</label>
                    <label class="check-row"><input type="checkbox" name="items[<?= $index ?>][pagina_inicial]" <?= !empty($item['pagina_inicial']) ? 'checked' : '' ?>> Inicio</label>
                    <label class="check-row"><input type="checkbox" name="items[<?= $index ?>][mostrar_badge]" <?= !empty($item['mostrar_badge']) ? 'checked' : '' ?>> Badge</label>
                </article>
            <?php endforeach; ?>
        </div>
        <button type="submit">Guardar menú</button>
    </form>
</section>

<section class="content-grid">
    <div class="work-card full">
        <h2>Permisos por rol</h2>
        <form method="post" action="/configuracion/permisos">
            <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
            <?php $activePermissionIds = []; foreach ($roles as $role) { if ((int)$role['id'] === (int)$selectedRoleId) { foreach (($role['permisos'] ?? []) as $permission) { $activePermissionIds[] = (int)($permission['id'] ?? 0); } } } ?>
            <div class="permission-grid">
                <?php foreach (($permissions ?? []) as $permission): ?>
                    <label class="check-row">
                        <input type="checkbox" name="permiso_ids[]" value="<?= (int)$permission['id'] ?>" <?= in_array((int)$permission['id'], $activePermissionIds, true) ? 'checked' : '' ?>>
                        <?= htmlspecialchars($permission['codigo'] ?? '') ?>
                    </label>
                <?php endforeach; ?>
            </div>
            <button type="submit">Guardar permisos</button>
        </form>
    </div>

    <div class="work-card full">
        <h2>Alcance de datos</h2>
        <form method="post" action="/configuracion/alcance">
            <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
            <label>ID para editar<input type="number" name="id" placeholder="Vacío para crear"></label>
            <label>Módulo
                <select name="modulo_id" required>
                    <?php foreach (($modules ?? []) as $module): ?>
                        <option value="<?= (int)$module['id'] ?>"><?= htmlspecialchars($module['nombre'] ?? '') ?></option>
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
            <label>Configuración JSON<textarea name="configuracion_json" rows="4" placeholder='{"campo":"valor"}'></textarea></label>
            <button type="submit">Guardar alcance</button>
        </form>
        <div class="mini-list">
            <?php foreach (($scopes ?? []) as $scope): ?>
                <div><strong>#<?= (int)$scope['id'] ?></strong> <?= htmlspecialchars($scope['modulo'] ?? '') ?> · <?= htmlspecialchars($scope['tipo_alcance'] ?? '') ?></div>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<section class="work-card full">
    <h2>Condiciones del rol</h2>
    <form method="post" action="/configuracion/condiciones" class="form-grid">
        <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
        <label>ID para editar<input type="number" name="id" placeholder="Vacío para crear"></label>
        <label>Módulo
            <select name="modulo_id">
                <option value="">Global</option>
                <?php foreach (($modules ?? []) as $module): ?>
                    <option value="<?= (int)$module['id'] ?>"><?= htmlspecialchars($module['nombre'] ?? '') ?></option>
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
        <button type="submit">Guardar condición</button>
    </form>

    <div class="table-wrap embedded">
        <table>
            <thead><tr><th>ID</th><th>Módulo</th><th>Condición</th><th>Estado</th><th>Acción</th></tr></thead>
            <tbody>
            <?php foreach (($conditions ?? []) as $condition): ?>
                <tr>
                    <td><?= (int)$condition['id'] ?></td>
                    <td><?= htmlspecialchars($condition['modulo'] ?? 'Global') ?></td>
                    <td><?= htmlspecialchars(($condition['campo'] ?? '') . ' ' . ($condition['operador'] ?? '') . ' ' . ($condition['valor'] ?? '')) ?></td>
                    <td><span class="pill"><?= !empty($condition['estado']) ? 'Activa' : 'Inactiva' ?></span></td>
                    <td>
                        <form method="post" action="/configuracion/condiciones/eliminar" class="inline-form">
                            <input type="hidden" name="rol_id" value="<?= (int)$selectedRoleId ?>">
                            <input type="hidden" name="id" value="<?= (int)$condition['id'] ?>">
                            <button type="submit" class="danger">Desactivar</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</section>
