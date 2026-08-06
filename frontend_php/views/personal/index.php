<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$perms = $permissions ?? [];
$canCreate = $isAdministrator || in_array('personal.crear', $perms, true);
$canEdit = $isAdministrator || in_array('personal.editar', $perms, true);
$json = static fn($value): string => htmlspecialchars(json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES), ENT_QUOTES, 'UTF-8');
$roles = $catalogs['roles'] ?? [];
$grados = $catalogs['grados'] ?? [];
$estados = $catalogs['estados'] ?? [];
$grupos = $catalogs['grupos'] ?? [];
$jornadas = $catalogs['jornadas'] ?? [];
?>

<?php if (!empty($message)): ?><div class="admin-flash"><?= $esc($message) ?></div><?php endif; ?>
<?php if (!empty($error)): ?><div class="admin-alert" role="alert"><?= $esc($error) ?></div><?php endif; ?>

<?php if ($canCreate || $canEdit): ?>
<section class="admin-form-section">
    <div class="admin-form-title">
        <h3 id="formTitle">Nuevo Personal</h3>
        <button type="reset" class="secondary" id="resetForm">Limpiar</button>
    </div>
    <form method="post" action="/personal" id="personForm" class="admin-form">
        <input type="hidden" name="id" id="formId" value="">
        <div class="form-grid">
            <label>Cédula <input name="cedula" required maxlength="20" placeholder="0912345678"></label>
            <label>Nombres <input name="nombres" required maxlength="120" placeholder="Juan Carlos"></label>
            <label>Apellidos <input name="apellidos" required maxlength="120" placeholder="Pérez López"></label>
            <label>Correo institucional <input name="correo_institucional" type="email" required maxlength="180" placeholder="usuario@seguraep.com"></label>
            <label>Teléfono <input name="telefono" maxlength="30" placeholder="0991234567"></label>
            <label>Grado<select name="grado_id"><option value="">Seleccione</option><?php foreach ($grados as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
            <label>Rol<select name="rol_id"><option value="">Seleccione</option><?php foreach ($roles as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
            <label>Grupo<select name="grupo_id"><option value="">Seleccione</option><?php foreach ($grupos as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
            <label>Jornada<select name="jornada_id"><option value="">Seleccione</option><?php foreach ($jornadas as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
            <label>Estado<select name="estado_personal_id"><option value="">Seleccione</option><?php foreach ($estados as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
            <label>Contraseña <input name="password" type="password" minlength="4" maxlength="128" placeholder="Dejar vacío para mantener"><small style="color:#8592a5;font-size:10px" id="passwordHint">Requerido al crear</small></label>
            <label class="check-row"><input type="checkbox" name="activo" checked> Activo</label>
        </div>
        <button type="submit" class="button" id="submitBtn">Guardar Personal</button>
    </form>
</section>
<?php endif; ?>

<section class="table-wrap">
    <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 18px;border-bottom:1px solid var(--sigo-line)">
        <h2 style="margin:0;font-size:15px">Personal registrado</h2>
        <span style="color:var(--sigo-muted);font-size:12px"><?= count($items) ?> registro(s)</span>
    </div>
    <div style="overflow-x:auto">
        <table>
            <thead>
                <tr>
                    <th>Nombre</th>
                    <th>Cédula</th>
                    <th>Correo</th>
                    <th>Grado</th>
                    <th>Rol</th>
                    <th>Grupo</th>
                    <th>Estado</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($items as $item): ?>
                <tr>
                    <td><?= $esc($item['nombre_completo'] ?? '') ?></td>
                    <td><?= $esc($item['cedula'] ?? '') ?></td>
                    <td><?= $esc($item['correo_institucional'] ?? '') ?></td>
                    <td><?= $esc($item['grado'] ?? '') ?></td>
                    <td><?= $esc($item['rol'] ?? '') ?></td>
                    <td><?= $esc($item['grupo'] ?? '') ?></td>
                    <td><span class="status-pill <?= ($item['activo'] ?? 0) ? 'is-active' : '' ?>"><?= $esc($item['estado_personal'] ?? '') ?></span></td>
                    <td class="actions">
                        <?php if ($canEdit): ?>
                        <button type="button" class="secondary edit-btn"
                            data-payload="<?= $json([
                                'id' => $item['id'],
                                'cedula' => $item['cedula'] ?? '',
                                'nombres' => $item['nombres'] ?? '',
                                'apellidos' => $item['apellidos'] ?? '',
                                'correo_institucional' => $item['correo_institucional'] ?? '',
                                'telefono' => $item['telefono'] ?? '',
                                'grupo_id' => $item['grupo_id'] ?? '',
                                'jornada_id' => $item['jornada_id'] ?? '',
                                'rol_id' => $item['rol_id'] ?? '',
                                'grado_id' => $item['grado_id'] ?? '',
                                'estado_personal_id' => $item['estado_personal_id'] ?? '',
                                'activo' => $item['activo'] ?? 0,
                            ]) ?>">Editar</button>
                        <?php endif; ?>
                        <?php if ($canEdit): ?>
                        <form method="post" action="/personal/eliminar" class="inline-form" onsubmit="return confirm('¿Está seguro de eliminar este registro?')">
                            <input type="hidden" name="id" value="<?= (int)($item['id'] ?? 0) ?>">
                            <button class="danger">Eliminar</button>
                        </form>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                <?php if (empty($items)): ?>
                <tr><td colspan="8" style="padding:30px;text-align:center;color:#8592a5;font-size:13px">No hay personal registrado.</td></tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</section>

<script>
document.querySelectorAll('.edit-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const form = document.getElementById('personForm');
        const payload = JSON.parse(btn.dataset.payload || '{}');
        document.getElementById('formTitle').textContent = 'Editar Personal';
        document.getElementById('submitBtn').textContent = 'Actualizar Personal';
        document.getElementById('passwordHint').textContent = 'Dejar vacío para mantener';
        Object.keys(payload).forEach(key => {
            const field = form.querySelector('[name="' + key + '"]');
            if (!field) return;
            if (field.type === 'checkbox') field.checked = Boolean(payload[key]);
            else field.value = payload[key] ?? '';
        });
        form.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
});
document.getElementById('resetForm')?.addEventListener('click', () => {
    document.getElementById('formTitle').textContent = 'Nuevo Personal';
    document.getElementById('submitBtn').textContent = 'Guardar Personal';
    document.getElementById('passwordHint').textContent = 'Requerido al crear';
    document.getElementById('personForm').reset();
    document.getElementById('formId').value = '';
});
</script>
