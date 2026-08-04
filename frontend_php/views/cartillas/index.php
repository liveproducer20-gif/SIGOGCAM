<?php $esc=static fn(mixed $v):string=>htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8'); ?>
<section class="module-workspace cards-workspace">

<?php if($error): ?><div class="alert"><?= $esc($error) ?></div><?php endif; ?>
<?php if($success): ?><div class="success"><?= $esc($success) ?></div><?php endif; ?>

<header class="module-heading">
    <div>
        <span class="eyebrow">Generador operativo</span>
        <h2>Cartillas institucionales</h2>
        <p>Seleccione el servicio y genere el reporte con vista previa en tiempo real.</p>
    </div>
    <div class="module-metrics">
        <strong><?= count($eas) ?></strong>
        <span>EAS disponibles</span>
    </div>
</header>

<section class="card-generator">
    <form class="form-panel module-form" method="post" action="/cartillas" id="cartillaForm" novalidate>
        <div class="form-grid">

            <label>Tipo de servicio
                <select name="tipo_servicio" id="tipoServicio">
                    <?php foreach(['EAS','Motorizado','K9','Ambiente','Fila pedestre','Administrativo','Ciclista','Conductor','Palacio','Cuadrante','Apoyo Seguridad Ciudadana','Radioperador','Supervisión'] as $type): ?>
                        <option><?= $type ?></option>
                    <?php endforeach; ?>
                </select>
            </label>

            <label>Tipo de cartilla
                <select name="tipo_cartilla" id="tipoCartilla">
                    <?php foreach(['Formación entrante','Formación saliente','Otras cartillas','Desalojo de vendedores','Punto martillo','Rondas disuasivas','Retiro temporal','Requerimiento','Colaboración con otras entidades','Colaboración ciudadana','Permiso de ausentismo'] as $type): ?>
                        <option><?= $type ?></option>
                    <?php endforeach; ?>
                </select>
            </label>

            <label>EAS
                <select name="eas_nombre" id="easNombre">
                    <option value="">No aplica</option>
                    <?php foreach($eas as $station): ?>
                        <option value="<?= $esc(($station['codigo']??'').' - '.($station['nombre']??'')) ?>"><?= $esc(($station['codigo']??'').' - '.($station['nombre']??'')) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>

            <label>Causa
                <select name="causa" id="causaSelect">
                    <?php foreach(['Punto Martillo','Desalojo de vendedores','Retiro temporal','Requerimiento','Rondas disuasivas','Colaboración con otras entidades','Colaboración ciudadana','Accidente','Robo a mano armada','Extorsión','Amenazas','Desaparición de persona','Agresión','Visualización de cámaras','Permiso de ausentismo'] as $cause): ?>
                        <option><?= $cause ?></option>
                    <?php endforeach; ?>
                </select>
            </label>

            <label>Distrito
                <input name="distrito" id="distritoInput" value="MODELO">
            </label>

            <label>Circuito
                <input name="circuito" id="circuitoInput" placeholder="Nombre del circuito o EAS">
            </label>

            <label>Dirección
                <input name="direccion" id="direccionInput" placeholder="Av. 9 de Octubre y Boyacá">
            </label>

            <label>Horario
                <input name="horario" id="horarioInput" placeholder="06:00 - 14:30">
            </label>

            <label>Móvil
                <select name="movil" id="movilSelect">
                    <option value="">No aplica</option>
                    <?php foreach($assignments as $assignment): ?>
                        <option value="<?= $esc($assignment['numero_movil'] ?? '') ?>"><?= $esc(($assignment['numero_movil']??'').' · '.($assignment['eas_codigo']??'')) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>

            <label>Policía
                <input name="policia" id="policiaInput" placeholder="Nombre del policía">
            </label>

            <label>Circuito de preexistencia
                <input name="cp" id="cpInput" value="<?= $esc($tempCp) ?>">
            </label>

            <label>JP
                <input name="jp" id="jpInput" value="<?= $esc($chief) ?>">
            </label>

            <!-- Campos exclusivos de Conductor -->
            <div id="conductorFields" class="span-2" style="display:none;">
                <div class="form-grid" style="grid-template-columns: repeat(4, 1fr);">
                    <label>Últimos 4 dígitos cédula
                        <input name="cedula_ultimos_4" id="cedulaUltimos4" maxlength="4" pattern="\d{4}" placeholder="1234">
                    </label>
                    <label>Número de disco
                        <input name="numero_disco" id="numeroDisco" placeholder="D-001">
                    </label>
                    <label>Opción
                        <select name="opcion_conductor" id="opcionConductor">
                            <option value="ENTRADA_PERSONAL">Entrada personal</option>
                            <option value="SALIDA_PERSONAL">Salida personal</option>
                            <option value="NOVEDADES_MOVIL">Novedades móvil</option>
                        </select>
                    </label>
                    <label>Kilometraje actual
                        <input name="kilometraje" id="kilometraje" type="number" min="0" placeholder="0">
                    </label>
                </div>
            </div>

            <!-- Campos adicionales para Otras cartillas -->
            <div id="detalleFields" style="display:none;">
                <label class="span-2">Detalle adicional
                    <textarea name="detalle" id="detalleInput" rows="2" maxlength="500" placeholder="Información adicional sobre la novedad..."></textarea>
                </label>
            </div>

            <label class="span-2">Contenido de la cartilla
                <textarea name="contenido" id="contenidoInput" rows="8" placeholder="Escriba manualmente o deje vacío para generar automáticamente..."><?= $esc($preview) ?></textarea>
            </label>

        </div>

        <div class="form-actions" style="display:flex;gap:8px;margin-top:14px;flex-wrap:wrap;">
            <button type="button" class="button" id="btnPrevisualizar">Previsualizar</button>
            <button type="button" class="secondary" id="btnLimpiar">Limpiar campos</button>
            <button type="submit" class="button">Registrar cartilla</button>
        </div>

        <!-- Alertas para Conductor -->
        <div id="conductorAlert" class="alert" style="display:none;margin-top:10px;"></div>
    </form>

    <aside class="cartilla-preview">
        <header>
            <div>
                <span class="eyebrow">Vista previa</span>
                <h3>Texto institucional</h3>
            </div>
            <div>
                <button type="button" class="secondary" data-copy-cartilla>Copiar</button>
                <button type="button" data-share-cartilla>Compartir</button>
            </div>
        </header>
        <textarea name="contenido" form="cartillaForm" id="previewOutput" rows="28" placeholder="La vista previa aparecer Aquí…"><?= $esc($preview) ?></textarea>
        <small>El contenido puede editarse antes de registrarlo.</small>
    </aside>
</section>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('cartillaForm');
    const tipoServicio = document.getElementById('tipoServicio');
    const tipoCartilla = document.getElementById('tipoCartilla');
    const causaSelect = document.getElementById('causaSelect');
    const previewOutput = document.getElementById('previewOutput');
    const contenidoInput = document.getElementById('contenidoInput');
    const conductorFields = document.getElementById('conductorFields');
    const detalleFields = document.getElementById('detalleFields');
    const conductorAlert = document.getElementById('conductorAlert');
    const movilSelect = document.getElementById('movilSelect');

    function toggleConductorFields() {
        const isConductor = tipoServicio.value === 'Conductor';
        conductorFields.style.display = isConductor ? 'block' : 'none';
    }

    function toggleDetalleFields() {
        const causesWithDetalle = ['Accidente','Robo a mano armada','Extorsión','Amenazas','Desaparición de persona','Agresión','Visualización de cámaras'];
        detalleFields.style.display = causesWithDetalle.includes(causaSelect.value) ? 'block' : 'none';
    }

    function greet() {
        const h = new Date().getHours();
        if (h >= 6 && h < 12) return 'buenos días';
        if (h >= 12 && h < 19) return 'buenas tardes';
        return 'buenas noches';
    }

    function val(name) {
        return (form.elements[name]?.value || '').trim();
    }

    function procedureByCause(cause, address) {
        const base = 'Muy ' + greet() + ', Sr. Maldonado Cabrera Freddy, Jefe de Control Municipal, muy respetuosamente me permito informarle que';
        const c = cause.toLowerCase();
        const l = address ? ' en la dirección ' + address : '';

        if (c.includes('desalojo'))
            return base + ' durante el recorrido preventivo se evidenció la presencia de vendedores ocupando el espacio público' + l + ', por lo que se procedió a dialogar de manera respetuosa, indicando la normativa vigente y solicitando el retiro voluntario del lugar. La intervención se desarrolló sin novedades adicionales, manteniendo presencia preventiva en el sector.';
        if (c.includes('retiro'))
            return base + ' se realizó el retiro temporal correspondiente' + l + ', verificando previamente las condiciones del sitio y coordinando la actuación de forma ordenada para precautelar la seguridad ciudadana y el uso adecuado del espacio público.';
        if (c.includes('requerimiento'))
            return base + ' se atendió un requerimiento ciudadano/institucional' + l + ', tomando contacto con las partes involucradas y brindando la colaboración operativa necesaria conforme a las competencias del Cuerpo de Agentes de Control Municipal.';
        if (c.includes('ronda'))
            return base + ' se ejecutaron rondas disuasivas' + l + ', manteniendo presencia preventiva, verificando puntos sensibles y observando el normal desarrollo de las actividades en el sector asignado.';
        if (c.includes('entidades'))
            return base + ' se brindó colaboración operativa a otras entidades' + l + ', acompañando el procedimiento solicitado y manteniendo presencia institucional hasta la culminación de la novedad, sin registrarse incidentes adicionales.';
        if (c.includes('ciudadana'))
            return base + ' se brindó colaboración ciudadana' + l + ', orientando a la persona requirente y realizando las gestiones operativas necesarias dentro del ámbito de competencia institucional.';
        if (c.includes('accidente'))
            return base + ' se tomó conocimiento de un accidente' + l + ', verificando la situación en territorio y precautelando el área mientras se coordinaba la atención correspondiente con las entidades competentes. Se mantuvo presencia preventiva hasta normalizar la novedad.';
        if (c.includes('robo'))
            return base + ' se tomó conocimiento de una alerta relacionada con presunto robo' + l + ', por lo que se mantuvo presencia preventiva, se verificó la novedad y se orientó a la persona afectada para la coordinación con las entidades competentes.';
        if (c.includes('extorsi'))
            return base + ' se recibió información relacionada con una presunta extorsión' + l + ', manteniendo reserva y orientando a la persona involucrada sobre la canalización correspondiente con las autoridades competentes.';
        if (c.includes('amenaza'))
            return base + ' se atendió una novedad por amenazas' + l + ', brindando acompañamiento preventivo y recomendando a la persona afectada formalizar la denuncia respectiva ante la entidad competente.';
        if (c.includes('desapar'))
            return base + ' se tomó conocimiento sobre la presunta desaparición de una persona' + l + ', por lo que se orientó a los ciudadanos respecto al procedimiento correspondiente y se dejó constancia de la novedad para fines pertinentes.';
        if (c.includes('agresi'))
            return base + ' se verificó una novedad relacionada con agresión' + l + ', manteniendo presencia preventiva, procurando separar a las partes involucradas y coordinando la atención correspondiente según la situación observada.';
        if (c.includes('cámara') || c.includes('camara'))
            return base + ' se realizó visualización de cámaras relacionada con la novedad reportada' + l + ', revisando la información disponible y dejando constancia de los detalles relevantes para conocimiento superior.';
        if (c.includes('ausent'))
            return base + ' se registra permiso de ausentismo del servidor correspondiente, dejando constancia de la novedad para conocimiento superior y fines administrativos.';
        if (c.includes('martillo'))
            return base + ' durante el servicio asignado se mantuvo presencia preventiva' + l + ', verificando el orden en el sector y realizando acciones disuasivas conforme a las disposiciones operativas.';
        return base + ' durante el servicio establecido se verificó la novedad correspondiente a ' + cause + l + '.';
    }

    function generatePreview() {
        if (contenidoInput.value.trim() !== '') {
            previewOutput.value = contenidoInput.value;
            return;
        }

        const tipo = val('tipo_servicio').toUpperCase();
        const tipoC = val('tipo_cartilla');
        const eas = val('eas_nombre');
        const causa = val('causa');
        const distrito = val('distrito').toUpperCase();
        const circuito = val('circuito') || eas || 'EAS';
        const horario = val('horario') || 'POR DEFINIR';
        const direccion = val('direccion');
        const movil = val('movil');
        const cp = val('cp');
        const jp = val('jp');
        const policia = val('policia');
        const now = new Date();
        const hora = now.toLocaleTimeString('es-EC',{hour:'2-digit',minute:'2-digit'});
        const fecha = now.toLocaleDateString('es-EC');

        let texto = '*CUERPO DE AGENTES DE CONTROL MUNICIPAL*\n\n';

        if (tipoC.startsWith('Formación')) {
            texto += '*REPORTE DE ' + tipoC.toUpperCase() + '*\n';
        } else {
            texto += '*REPORTE DE ' + tipo + '*\n';
        }

        texto += '*DISTRITO:* ' + distrito + '\n';
        texto += '*CIRCUITO:* ' + circuito + '\n';
        texto += '*HORARIO:* ' + horario + '\n';
        texto += '*HORA:* ' + hora + '\n';
        texto += '*FECHA:* ' + fecha + '\n';
        texto += '*DIRECCIÓN:* ' + direccion + '\n\n';
        texto += '*CAUSA:* ' + causa + '\n\n';
        texto += '*PROCEDIMIENTO:*\n\n';

        const procedimiento = procedureByCause(causa, direccion);
        let puntoMartillo = '';
        if (!causa.toLowerCase().includes('ausent') && direccion) {
            puntoMartillo = ' Se procedió con punto martillo en la calle ' + direccion + '.';
        }

        texto += procedimiento + puntoMartillo + '\n\n';
        texto += 'Notifico novedades para fines correspondientes.\n';

        if (movil) texto += '\n*Móvil ' + movil + '*';

        texto += '\n\n*REPORTA:*\n\n';
        texto += '*CP:* ' + cp + '\n';
        texto += '*JP:* ' + jp;

        if (policia) texto += '\n*POLICÍA:* ' + policia;

        texto += '\n\n\"Lealtad, Valor y Orden\"\n\n';
        texto += 'Adjunto fotografía';

        previewOutput.value = texto;
    }

    function generateFromContent() {
        if (contenidoInput.value.trim() !== '') {
            previewOutput.value = contenidoInput.value;
        }
    }

    tipoServicio.addEventListener('change', toggleConductorFields);
    tipoCartilla.addEventListener('change', generatePreview);
    causaSelect.addEventListener('change', function() {
        toggleDetalleFields();
        generatePreview();
    });
    movilSelect.addEventListener('change', generatePreview);

    form.addEventListener('input', function(e) {
        if (e.target.name !== 'contenido') {
            generatePreview();
        }
    });

    contenidoInput.addEventListener('input', generateFromContent);

    document.getElementById('btnPrevisualizar').addEventListener('click', function() {
        contenidoInput.value = '';
        generatePreview();
    });

    document.getElementById('btnLimpiar').addEventListener('click', function() {
        form.reset();
        contenidoInput.value = '';
        previewOutput.value = '';
        toggleConductorFields();
        toggleDetalleFields();
    });

    toggleConductorFields();
    toggleDetalleFields();
    generatePreview();
});
</script>

</section>
