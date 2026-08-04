<section class="dashboard">
    <header class="topbar">
        <div>
            <h1>Cartillas</h1>
            <p>Registro institucional de cartillas operativas.</p>
        </div>
        <a class="button-link" href="/dashboard">Volver</a>
    </header>

    <?php if (!empty($error)): ?>
        <div class="alert"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <?php if (!empty($success)): ?>
        <div class="success"><?= htmlspecialchars($success) ?></div>
    <?php endif; ?>

    <form class="work-card full" method="post" action="/cartillas">
        <div class="form-grid">
            <label>Tipo de servicio
                <select name="tipo_servicio">
                    <option>EAS</option>
                    <option>Motorizado</option>
                    <option>K9</option>
                    <option>Ambiente</option>
                    <option>Radioperador</option>
                    <option>Administrativo</option>
                </select>
            </label>
            <label>EAS
                <select name="eas_nombre">
                    <option value="">Seleccione si aplica</option>
                    <?php foreach (($eas ?? []) as $station): ?>
                        <option value="<?= htmlspecialchars(($station['codigo'] ?? '') . ' - ' . ($station['nombre'] ?? '')) ?>">
                            <?= htmlspecialchars(($station['codigo'] ?? '') . ' - ' . ($station['nombre'] ?? '')) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Causa
                <select name="causa">
                    <option>Punto Martillo</option>
                    <option>Desalojo de vendedores</option>
                    <option>Retiro temporal</option>
                    <option>Requerimiento</option>
                    <option>Rondas disuasivas</option>
                    <option>Colaboración con otras entidades</option>
                    <option>Colaboración ciudadana</option>
                    <option>Accidente</option>
                    <option>Robo a mano armada</option>
                    <option>Extorsión</option>
                    <option>Amenazas</option>
                    <option>Desaparición de persona</option>
                    <option>Agresión</option>
                    <option>Visualización de cámaras</option>
                    <option>Permiso de ausentismo</option>
                </select>
            </label>
            <label>Dirección<input type="text" name="direccion"></label>
            <label>Horario<input type="text" name="horario" placeholder="Automático"></label>
            <label>Móvil<input type="text" name="movil"></label>
            <label>CP<input type="text" name="cp"></label>
            <label>JP<input type="text" name="jp"></label>
            <label>Policía<input type="text" name="policia"></label>
        </div>

        <label>
            Procedimiento narrativo
            <textarea name="procedimiento" rows="7" placeholder="Si lo deja vacío, se genera una redacción institucional base."></textarea>
        </label>

        <label>
            Detalle adicional
            <textarea name="detalle" rows="4" placeholder="Datos del accidente, motivo de ausentismo, entidad colaboradora u otra información relevante."></textarea>
        </label>

        <label>
            Contenido final de la cartilla
            <textarea name="contenido" rows="14" placeholder="Opcional: puede pegar una cartilla ya redactada. Si queda vacío, el sistema genera el formato institucional."><?= htmlspecialchars($preview ?? '') ?></textarea>
        </label>

        <button type="submit">Registrar cartilla</button>
    </form>
</section>
