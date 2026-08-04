<section class="page-header">
    <div>
        <p class="eyebrow">Sistema</p>
        <h1>Configuración</h1>
    </div>
    <a class="button secondary" href="/dashboard">Volver</a>
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
