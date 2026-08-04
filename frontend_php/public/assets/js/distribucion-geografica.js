(function () {
    'use strict';
    const app = document.querySelector('.geo-app');
    if (!app) return;

    const $ = (selector, root = document) => root.querySelector(selector);
    const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));
    const catalogData = JSON.parse($('#geoCatalogs')?.textContent || '{}');
    const permissions = {
        create: app.dataset.canCreate === '1', edit: app.dataset.canEdit === '1',
        assign: app.dataset.canAssign === '1', catalogs: app.dataset.canCatalogs === '1'
    };
    const stateColors = { CUBIERTO: '#55ad38', SIN_ASIGNACION: '#aeb7c2', FUERA_TURNO: '#2480e9', NOVEDAD: '#e63c3c', INACTIVO: '#6b7280', PENDIENTE: '#e3ad23' };
    let map, wizardMap, previewMap, draftMarker, selectedPointId = null, currentStep = 1;
    let markerLayer, selectedMarker, selectedAgent = null, assignments = [], originalAssignmentIds = [];

    async function api(resource, options = {}) {
        const response = await fetch(`/distribucion-geografica/api?resource=${encodeURIComponent(resource)}`, {
            method: options.method || 'GET',
            headers: options.body ? { 'Content-Type': 'application/json' } : {},
            body: options.body ? JSON.stringify(options.body) : undefined
        });
        const payload = await response.json().catch(() => ({ ok: false, mensaje: 'La respuesta del servidor no es válida.' }));
        if (!response.ok || payload.ok !== true) throw new Error(payload.mensaje || payload.detail || 'No se pudo completar la operación.');
        return payload;
    }

    function notify(message, error = false) {
        const toast = $('#geoToast');
        toast.textContent = message; toast.classList.toggle('is-error', error); toast.classList.add('is-visible');
        clearTimeout(notify.timer); notify.timer = setTimeout(() => toast.classList.remove('is-visible'), 4200);
    }

    function escapeHtml(value) {
        const element = document.createElement('div'); element.textContent = value ?? ''; return element.innerHTML;
    }

    function timeText(value) { return value ? String(value).slice(0, 5) : '—'; }
    function stateText(value) { return ({ CUBIERTO: 'Punto cubierto', SIN_ASIGNACION: 'Sin asignación', FUERA_TURNO: 'Fuera de turno', NOVEDAD: 'Con novedad', INACTIVO: 'Inactivo' })[value] || value || 'Sin asignación'; }

    function markerIcon(point, isSelected = false) {
        const color = isSelected ? '#8844c7' : (stateColors[point.estado] || '#aeb7c2');
        const empty = point.estado === 'SIN_ASIGNACION';
        return L.divIcon({ className: '', iconSize: [36, 45], iconAnchor: [18, 43], html: `<div class="geo-marker ${empty ? 'unassigned' : ''} ${isSelected ? 'selected' : ''}" style="--marker:${color}">${empty ? '○' : '♟'}</div>` });
    }

    function initMaps() {
        if (!window.L) {
            $('#geoMap').innerHTML = '<div class="geo-map-empty">No se pudo cargar la biblioteca del mapa. Verifique la conexión de red.</div>';
            return;
        }
        map = L.map('geoMap', { zoomControl: true }).setView([-2.1894, -79.8891], 14);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 20, attribution: '&copy; OpenStreetMap' }).addTo(map);
        markerLayer = L.featureGroup().addTo(map);
        loadAll();
    }

    async function loadAll() {
        await Promise.allSettled([loadPoints(), loadSummary()]);
    }

    async function loadPoints() {
        if (!map) return;
        try {
            const params = new URLSearchParams(new FormData($('#geoFilters')));
            [...params.keys()].forEach(key => { if (!params.get(key)) params.delete(key); });
            const result = await api(`distribucion-geografica/puntos${params.toString() ? '?' + params : ''}`);
            markerLayer.clearLayers(); selectedMarker = null;
            const bounds = [];
            (result.datos || []).forEach(point => {
                const marker = L.marker([Number(point.latitud), Number(point.longitud)], { icon: markerIcon(point), keyboard: true, title: point.nombre });
                marker.pointData = point;
                marker.on('click', () => selectPoint(point.id, marker));
                marker.addTo(markerLayer); bounds.push([Number(point.latitud), Number(point.longitud)]);
            });
            const visibleCounter = $('#visiblePointCount'); if (visibleCounter) visibleCounter.textContent = String(bounds.length);
            $('#geoMapEmpty').hidden = bounds.length > 0;
            if (bounds.length === 1) map.setView(bounds[0], 17);
            else if (bounds.length > 1) map.fitBounds(bounds, { padding: [35, 35], maxZoom: 17 });
            else map.setView([-2.1894, -79.8891], 14);
        } catch (error) { notify(error.message, true); }
    }

    async function loadSummary() {
        try {
            const data = (await api('distribucion-geografica/resumen')).datos || {};
            $('#statRegistered').textContent = data.puntos_registrados || 0;
            $('#statCovered').textContent = data.puntos_cubiertos || 0;
            $('#statUnassigned').textContent = data.puntos_sin_asignacion || 0;
            $('#statPersonnel').textContent = data.personal_asignado || 0;
            $('#statRoutes').textContent = data.rutas_activas || 0;
        } catch (error) { notify(error.message, true); }
    }

    async function selectPoint(id, marker = null) {
        try {
            const point = (await api(`distribucion-geografica/puntos/${id}`)).datos;
            selectedPointId = id;
            if (selectedMarker?.pointData) selectedMarker.setIcon(markerIcon(selectedMarker.pointData));
            selectedMarker = marker || markerLayer.getLayers().find(item => item.pointData?.id === id);
            if (selectedMarker) { selectedMarker.setIcon(markerIcon(point, true)); map.panTo(selectedMarker.getLatLng()); }
            renderDetail(point); $('#geoDetail').classList.add('is-open');
        } catch (error) { notify(error.message, true); }
    }

    function renderDetail(point) {
        const personnel = (point.asignaciones || []).map(item => `<span class="geo-agent-chip"><span>${escapeHtml(item.agente)}</span><b>${escapeHtml(item.codigo)}</b></span>`).join('') || '<span class="geo-agent-chip">Sin personal asignado</span>';
        $('#geoDetail').innerHTML = `<header><h2>Información del punto</h2><button type="button" id="closeDetail" aria-label="Cerrar">×</button></header>
          <div class="geo-point-head"><div class="geo-point-avatar">${point.estado === 'SIN_ASIGNACION' ? '○' : '♟'}</div><div><span class="geo-status">${escapeHtml(stateText(point.estado))}</span><h3>${escapeHtml(point.nombre)}</h3><small>${escapeHtml(point.ubicacion_especifica)}</small></div></div>
          <div class="geo-detail-list"><dl><dt>Distrito</dt><dd>${escapeHtml(point.distrito)}</dd><dt>Ruta</dt><dd>${escapeHtml(point.ruta)}</dd><dt>Sector</dt><dd>${escapeHtml(point.sector)}</dd><dt>Dirección o referencia</dt><dd>${escapeHtml(point.direccion)}</dd><dt>Tipo de servicio</dt><dd>${escapeHtml(point.tipo_servicio)}</dd><dt>Coordenadas</dt><dd>${escapeHtml(point.latitud)}, ${escapeHtml(point.longitud)}</dd><dt>Turno y horario</dt><dd>${escapeHtml(point.turno)} · ${timeText(point.hora_inicio)} - ${timeText(point.hora_fin)}</dd><dt>Cantidad requerida</dt><dd>${point.cantidad_requerida} agente(s)</dd><dt>Personal asignado (${(point.asignaciones || []).length})</dt><dd><div class="geo-agent-chips">${personnel}</div></dd><dt>Observaciones</dt><dd>${escapeHtml(point.observaciones || 'Sin observaciones')}</dd></dl></div>
          <div class="geo-detail-actions"><button class="geo-primary" type="button" data-view-point>Ver detalles</button>${permissions.edit ? '<button class="geo-secondary" type="button" data-edit-point>Editar punto</button>' : ''}${permissions.assign ? '<button class="geo-secondary assign" type="button" data-assign-point>Administrar asignaciones</button>' : ''}</div>`;
        $('#closeDetail').onclick = () => $('#geoDetail').classList.remove('is-open');
        $('[data-view-point]')?.addEventListener('click', () => $('.geo-detail-list').scrollIntoView({ behavior: 'smooth', block: 'start' }));
        $('[data-edit-point]')?.addEventListener('click', () => openWizard(point, 2));
        $('[data-assign-point]')?.addEventListener('click', () => openWizard(point, 3));
    }

    async function loadRoutes(districtId, target, selected = '') {
        target.innerHTML = '<option value="">Seleccione</option>'; target.disabled = !districtId;
        const sectorTarget = target === $('#filterRoute') ? $('#filterSector') : $('#formSector');
        sectorTarget.innerHTML = '<option value="">Seleccione una ruta</option>'; sectorTarget.disabled = true;
        if (!districtId) return;
        const items = (await api(`distritos/${districtId}/rutas`)).datos || [];
        items.forEach(item => target.add(new Option(item.nombre, item.id)));
        if (selected) target.value = String(selected);
    }

    async function loadSectors(routeId, target, selected = '') {
        target.innerHTML = '<option value="">Seleccione</option>'; target.disabled = !routeId;
        if (!routeId) return;
        const items = (await api(`rutas/${routeId}/sectores`)).datos || [];
        items.forEach(item => target.add(new Option(item.nombre, item.id)));
        if (selected) target.value = String(selected);
    }

    $('#filterDistrict').addEventListener('change', async e => { try { await loadRoutes(e.target.value, $('#filterRoute')); } catch (error) { notify(error.message, true); } });
    $('#filterRoute').addEventListener('change', async e => { try { await loadSectors(e.target.value, $('#filterSector')); } catch (error) { notify(error.message, true); } });
    $('#geoFilters').addEventListener('submit', e => { e.preventDefault(); loadPoints(); });
    $('#geoFilters').addEventListener('reset', () => setTimeout(() => { $('#filterRoute').disabled = true; $('#filterSector').disabled = true; loadPoints(); }, 0));
    $('#geoFilterToggle')?.addEventListener('click', () => $('#geoFilters').classList.toggle('is-open'));
    $('#geoMenuToggle').addEventListener('click', () => app.classList.toggle('menu-open'));
    $('#closeDetail')?.addEventListener('click', () => $('#geoDetail').classList.remove('is-open'));
    $('#centerGeoMap')?.addEventListener('click', () => {
        const layers = markerLayer?.getLayers() || [];
        if (layers.length === 1) map.setView(layers[0].getLatLng(), 17);
        else if (layers.length > 1) map.fitBounds(markerLayer.getBounds(), { padding: [35, 35], maxZoom: 17 });
        else map.setView([-2.1894, -79.8891], 14);
    });
    $('#fullscreenGeoMap')?.addEventListener('click', () => {
        $('.geo-map-wrap')?.classList.toggle('is-fullscreen');
        setTimeout(() => map?.invalidateSize(), 220);
    });

    const wizard = $('#pointWizard');
    if (!wizard) { initMaps(); return; }
    const form = $('#pointForm');
    function setupWizardMaps() {
        if (!window.L) return;
        if (!wizardMap) {
            wizardMap = L.map('wizardMap').setView([-2.1894, -79.8891], 14);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 20, attribution: '&copy; OpenStreetMap' }).addTo(wizardMap);
            wizardMap.on('click', event => setDraftLocation(event.latlng.lat, event.latlng.lng));
        }
        setTimeout(() => wizardMap.invalidateSize(), 80);
    }

    function setDraftLocation(lat, lng, pan = true) {
        lat = Number(lat); lng = Number(lng);
        if (!Number.isFinite(lat) || !Number.isFinite(lng)) return notify('Ingrese coordenadas válidas.', true);
        form.elements.latitud.value = lat.toFixed(7); form.elements.longitud.value = lng.toFixed(7);
        if (draftMarker) draftMarker.setLatLng([lat, lng]);
        else {
            draftMarker = L.marker([lat, lng], { draggable: true, icon: L.divIcon({ className: '', iconSize: [36, 45], iconAnchor: [18, 43], html: '<div class="geo-marker" style="--marker:#e3ad23">⌖</div>' }) }).addTo(wizardMap);
            draftMarker.on('dragend', () => { const point = draftMarker.getLatLng(); setDraftLocation(point.lat, point.lng, false); });
        }
        if (pan) wizardMap.setView([lat, lng], 17);
    }

    async function openWizard(point = null, targetStep = 1) {
        form.reset(); assignments = []; originalAssignmentIds = []; selectedAgent = null; selectedPointId = point?.id || null;
        form.elements.point_id.value = point?.id || '';
        $('#wizardTitle').textContent = point ? 'Editar punto georreferenciado' : 'Crear punto georreferenciado';
        $('#wizardEyebrow').textContent = point ? 'Punto de servicio existente' : 'Nuevo punto de servicio';
        wizard.hidden = false; document.body.style.overflow = 'hidden'; setupWizardMaps();
        if (draftMarker) { draftMarker.remove(); draftMarker = null; }
        if (point) {
            form.elements.latitud.value = point.latitud; form.elements.longitud.value = point.longitud; form.elements.direccion.value = point.direccion;
            setDraftLocation(point.latitud, point.longitud);
            form.elements.distrito_id.value = point.distrito_id;
            await loadRoutes(point.distrito_id, $('#formRoute'), point.ruta_id);
            await loadSectors(point.ruta_id, $('#formSector'), point.sector_id);
            ['nombre','ubicacion_especifica','tipo_servicio_id','turno_id','cantidad_requerida','estado','observaciones'].forEach(name => { if (form.elements[name]) form.elements[name].value = point[name] ?? ''; });
            form.elements.hora_inicio.value = timeText(point.hora_inicio).replace('—',''); form.elements.hora_fin.value = timeText(point.hora_fin).replace('—','');
            assignments = (point.asignaciones || []).map(item => ({
                id: item.id, personal_id: item.personal_id, agente: item.agente, codigo: item.codigo,
                tipo_asignacion: item.tipo_asignacion, fecha_inicio: String(item.fecha_inicio).slice(0,10), fecha_fin: item.fecha_fin ? String(item.fecha_fin).slice(0,10) : null,
                turno_id: item.turno_id, turno: item.turno, hora_inicio: timeText(item.hora_inicio), hora_fin: timeText(item.hora_fin), funcion: item.funcion || '', observaciones: item.observaciones || ''
            }));
            originalAssignmentIds = assignments.map(item => item.id);
        } else {
            const today = new Date().toISOString().slice(0, 10); $('#assignStartDate').value = today;
        }
        renderAssignments(); showStep(targetStep);
    }

    function closeWizard() { wizard.hidden = true; document.body.style.overflow = ''; selectedAgent = null; }
    $$('[data-open-wizard]').forEach(button => button.addEventListener('click', () => openWizard()));
    $$('[data-close-wizard]').forEach(button => button.addEventListener('click', closeWizard));
    $('#cancelWizard').addEventListener('click', closeWizard);
    wizard.addEventListener('click', event => { if (event.target === wizard) closeWizard(); });

    function showStep(step) {
        currentStep = Math.max(1, Math.min(4, step));
        $$('.geo-step-panel', wizard).forEach(panel => panel.classList.toggle('is-active', Number(panel.dataset.step) === currentStep));
        $$('#wizardSteps li').forEach((item, index) => { item.classList.toggle('is-active', index + 1 === currentStep); item.classList.toggle('is-complete', index + 1 < currentStep); });
        $('#prevStep').hidden = currentStep === 1; $('#nextStep').hidden = currentStep === 4; $('#savePoint').hidden = currentStep !== 4;
        if (currentStep === 1) setTimeout(() => wizardMap?.invalidateSize(), 50);
        if (currentStep === 4) renderSummary();
    }

    function validateStep(step) {
        if (step === 1) {
            if (!draftMarker || !form.elements.latitud.value || !form.elements.longitud.value) { notify('Seleccione una ubicación en el mapa antes de continuar.', true); return false; }
            const lat = Number(form.elements.latitud.value), lon = Number(form.elements.longitud.value);
            if (lat < -2.45 || lat > -1.85 || lon < -80.15 || lon > -79.70) { notify('Las coordenadas están fuera del área operativa permitida de Guayaquil.', true); return false; }
            if (!form.elements.direccion.value.trim()) { notify('Ingrese una dirección o referencia.', true); return false; }
        }
        if (step === 2) {
            const invalid = $$('[data-step="2"] [required]').find(field => !field.value);
            if (invalid) { invalid.focus(); notify(`Complete el campo ${invalid.closest('label')?.childNodes[0]?.textContent?.trim() || 'requerido'}.`, true); return false; }
        }
        return true;
    }
    $('#nextStep').addEventListener('click', () => { if (validateStep(currentStep)) showStep(currentStep + 1); });
    $('#prevStep').addEventListener('click', () => showStep(currentStep - 1));
    $('#locateCoordinates').addEventListener('click', () => setDraftLocation(form.elements.latitud.value, form.elements.longitud.value));
    $('#formDistrict').addEventListener('change', async e => { try { await loadRoutes(e.target.value, $('#formRoute')); } catch (error) { notify(error.message, true); } });
    $('#formRoute').addEventListener('change', async e => { try { await loadSectors(e.target.value, $('#formSector')); } catch (error) { notify(error.message, true); } });
    $('#formShift').addEventListener('change', e => { const option = e.target.selectedOptions[0]; form.elements.hora_inicio.value = option?.dataset.start || ''; form.elements.hora_fin.value = option?.dataset.end || ''; $('#assignShift').value = e.target.value; $('#assignStartTime').value = form.elements.hora_inicio.value; $('#assignEndTime').value = form.elements.hora_fin.value; });

    $('#createRoute')?.addEventListener('click', async () => {
        const districtId = form.elements.distrito_id.value; if (!districtId) return notify('Seleccione primero un distrito.', true);
        const name = prompt('Nombre de la nueva ruta:'); if (!name?.trim()) return;
        try {
            const body = { distrito_id: Number(districtId), nombre: name.trim(), turno_id: form.elements.turno_id.value ? Number(form.elements.turno_id.value) : null, hora_inicio: form.elements.hora_inicio.value || null, hora_fin: form.elements.hora_fin.value || null };
            const result = await api(`distritos/${districtId}/rutas`, { method: 'POST', body });
            await loadRoutes(districtId, $('#formRoute'), result.datos.id); notify(result.mensaje);
        } catch (error) { notify(error.message, true); }
    });
    $('#createSector')?.addEventListener('click', async () => {
        const districtId = form.elements.distrito_id.value, routeId = form.elements.ruta_id.value;
        if (!routeId) return notify('Seleccione primero una ruta.', true);
        const name = prompt('Nombre del nuevo sector:'); if (!name?.trim()) return;
        try {
            const result = await api(`rutas/${routeId}/sectores`, { method: 'POST', body: { distrito_id: Number(districtId), ruta_id: Number(routeId), nombre: name.trim() } });
            await loadSectors(routeId, $('#formSector'), result.datos.id); notify(result.mensaje);
        } catch (error) { notify(error.message, true); }
    });

    let searchTimer;
    $('#agentSearch').addEventListener('input', event => {
        clearTimeout(searchTimer); const query = event.target.value.trim(); if (query.length < 2) { $('#agentResults').innerHTML = ''; return; }
        searchTimer = setTimeout(async () => {
            try {
                const people = (await api(`personal/buscar?q=${encodeURIComponent(query)}`)).datos || [];
                $('#agentResults').innerHTML = people.slice(0, 12).map(person => `<div class="geo-agent-result" data-person='${escapeHtml(JSON.stringify(person))}'><i>${escapeHtml((person.nombres?.[0] || '') + (person.apellidos?.[0] || ''))}</i><span><strong>${escapeHtml(person.nombre_completo)}</strong><small>${escapeHtml(person.cargo || 'Agente de control')} · ${escapeHtml(person.area || 'Área operativa')}</small></span><b>${escapeHtml(person.cedula)}</b></div>`).join('') || '<div class="geo-agent-result">No se encontraron agentes.</div>';
                $$('.geo-agent-result[data-person]', $('#agentResults')).forEach(row => row.addEventListener('click', () => chooseAgent(JSON.parse(row.dataset.person))));
            } catch (error) { notify(error.message, true); }
        }, 280);
    });

    function chooseAgent(person) {
        selectedAgent = person; $('#agentResults').innerHTML = ''; $('#agentSearch').value = '';
        $('#selectedAgent').innerHTML = `<i>${escapeHtml((person.nombres?.[0] || '') + (person.apellidos?.[0] || ''))}</i><span><strong>${escapeHtml(person.nombre_completo)}</strong><small>Código: ${escapeHtml(person.cedula)} · ${escapeHtml(person.cargo || 'Agente de control')} · ${escapeHtml(person.estado_personal || '')}</small></span>`;
        $('#assignmentEditor').hidden = false;
        $('#assignShift').value = form.elements.turno_id.value || $('#assignShift').value;
        $('#assignStartTime').value = form.elements.hora_inicio.value; $('#assignEndTime').value = form.elements.hora_fin.value;
        if (!$('#assignStartDate').value) $('#assignStartDate').value = new Date().toISOString().slice(0, 10);
    }

    $('#addAgent').addEventListener('click', () => {
        if (!selectedAgent) return;
        if (!$('#assignStartDate').value || !$('#assignStartTime').value || !$('#assignEndTime').value) return notify('Complete la fecha y el horario de la asignación.', true);
        const duplicate = assignments.some(item => Number(item.personal_id) === Number(selectedAgent.id) && item.fecha_inicio === $('#assignStartDate').value && Number(item.turno_id) === Number($('#assignShift').value));
        if (duplicate) return notify('El agente ya fue agregado para la misma fecha y turno.', true);
        const shiftName = $('#assignShift').selectedOptions[0]?.textContent || '';
        assignments.push({ personal_id: selectedAgent.id, agente: selectedAgent.nombre_completo, codigo: selectedAgent.cedula, tipo_asignacion: $('#assignType').value, fecha_inicio: $('#assignStartDate').value, fecha_fin: $('#assignEndDate').value || null, turno_id: Number($('#assignShift').value), turno: shiftName, hora_inicio: $('#assignStartTime').value, hora_fin: $('#assignEndTime').value, funcion: $('#assignRole').value, observaciones: $('#assignNotes').value });
        selectedAgent = null; $('#assignmentEditor').hidden = true; renderAssignments();
    });

    function renderAssignments() {
        const body = $('#assignmentRows');
        if (!assignments.length) { body.innerHTML = '<tr class="empty"><td colspan="6">Aún no se ha agregado personal.</td></tr>'; return; }
        body.innerHTML = assignments.map((item, index) => `<tr><td>${escapeHtml(item.agente)}</td><td>${escapeHtml(item.codigo)}</td><td>${escapeHtml(item.turno)}</td><td>${escapeHtml(item.funcion || '—')}</td><td><span class="geo-status">Activa</span></td><td><button class="geo-edit-agent" type="button" data-edit-agent="${index}">Editar</button> <button class="geo-remove-agent" type="button" data-remove-agent="${index}">Quitar</button></td></tr>`).join('');
        $$('[data-edit-agent]', body).forEach(button => button.addEventListener('click', () => editAssignment(Number(button.dataset.editAgent))));
        $$('[data-remove-agent]', body).forEach(button => button.addEventListener('click', () => { assignments.splice(Number(button.dataset.removeAgent), 1); renderAssignments(); }));
    }

    function editAssignment(index) {
        const item = assignments[index]; if (!item) return;
        selectedAgent = { id: item.personal_id, nombre_completo: item.agente, cedula: item.codigo, nombres: item.agente, apellidos: '' };
        $('#selectedAgent').innerHTML = `<i>${escapeHtml(item.agente?.[0] || 'A')}</i><span><strong>${escapeHtml(item.agente)}</strong><small>Código: ${escapeHtml(item.codigo)}</small></span>`;
        $('#assignType').value = item.tipo_asignacion; $('#assignStartDate').value = item.fecha_inicio;
        $('#assignEndDate').value = item.fecha_fin || ''; $('#assignShift').value = String(item.turno_id);
        $('#assignStartTime').value = item.hora_inicio; $('#assignEndTime').value = item.hora_fin;
        $('#assignRole').value = item.funcion || ''; $('#assignNotes').value = item.observaciones || '';
        assignments.splice(index, 1); renderAssignments(); $('#assignmentEditor').hidden = false;
        $('#assignmentEditor').scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    function collectPayload() {
        return { distrito_id: Number(form.elements.distrito_id.value), ruta_id: Number(form.elements.ruta_id.value), sector_id: Number(form.elements.sector_id.value), nombre: form.elements.nombre.value.trim(), ubicacion_especifica: form.elements.ubicacion_especifica.value.trim(), direccion: form.elements.direccion.value.trim(), latitud: Number(form.elements.latitud.value), longitud: Number(form.elements.longitud.value), tipo_servicio_id: Number(form.elements.tipo_servicio_id.value), turno_id: Number(form.elements.turno_id.value), hora_inicio: form.elements.hora_inicio.value, hora_fin: form.elements.hora_fin.value, cantidad_requerida: Number(form.elements.cantidad_requerida.value), observaciones: form.elements.observaciones.value.trim() || null, estado: assignments.length ? 'CUBIERTO' : form.elements.estado.value, asignaciones: assignments.filter(item => !item.id).map(({ agente, codigo, turno, id, ...item }) => item) };
    }

    function renderSummary() {
        const payload = collectPayload();
        const label = (select) => select.selectedOptions[0]?.textContent || '—';
        const values = [['Distrito',label(form.elements.distrito_id)],['Ruta',label(form.elements.ruta_id)],['Sector',label(form.elements.sector_id)],['Punto',payload.nombre],['Ubicación específica',payload.ubicacion_especifica],['Dirección',payload.direccion],['Latitud',payload.latitud],['Longitud',payload.longitud],['Tipo de servicio',label(form.elements.tipo_servicio_id)],['Turno',label(form.elements.turno_id)],['Horario',`${payload.hora_inicio} - ${payload.hora_fin}`],['Cantidad requerida',payload.cantidad_requerida],['Agentes asignados',assignments.map(item => item.agente).join(', ') || 'Sin cobertura'],['Observaciones',payload.observaciones || 'Sin observaciones']];
        $('#pointSummary').innerHTML = values.map(([key, value]) => `<dt>${escapeHtml(key)}</dt><dd>${escapeHtml(value)}</dd>`).join('');
        if (!window.L) return;
        if (!previewMap) { previewMap = L.map('previewMap', { zoomControl: false, dragging: false, scrollWheelZoom: false }).setView([payload.latitud, payload.longitud], 16); L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '&copy; OpenStreetMap' }).addTo(previewMap); }
        previewMap.eachLayer(layer => { if (layer instanceof L.Marker) layer.remove(); });
        L.marker([payload.latitud, payload.longitud], { icon: markerIcon({ estado: assignments.length ? 'CUBIERTO' : 'SIN_ASIGNACION' }) }).addTo(previewMap); previewMap.setView([payload.latitud, payload.longitud], 16); setTimeout(() => previewMap.invalidateSize(), 50);
    }

    form.addEventListener('submit', async event => {
        event.preventDefault(); if (!validateStep(2)) return showStep(2);
        if (!assignments.length && !confirm('El punto quedará registrado sin cobertura. ¿Desea continuar?')) return;
        const payload = collectPayload(); const pointId = form.elements.point_id.value;
        $('#savePoint').disabled = true; $('#savePoint').textContent = 'Guardando…';
        try {
            let result;
            if (pointId) {
                result = await api(`distribucion-geografica/puntos/${pointId}`, { method: 'PUT', body: payload });
                if (permissions.assign) {
                    const removed = originalAssignmentIds.filter(id => !assignments.some(item => Number(item.id) === Number(id)));
                    for (const id of removed) await api(`distribucion-geografica/asignaciones/${id}`, { method: 'DELETE' });
                    for (const item of assignments.filter(entry => !entry.id)) { const { agente, codigo, turno, ...assignment } = item; await api(`distribucion-geografica/puntos/${pointId}/asignaciones`, { method: 'POST', body: assignment }); }
                }
            } else result = await api('distribucion-geografica/puntos', { method: 'POST', body: payload });
            const savedId = Number(pointId || result.datos.id); closeWizard(); await loadAll();
            const marker = markerLayer.getLayers().find(item => Number(item.pointData?.id) === savedId); await selectPoint(savedId, marker);
            notify(result.mensaje || 'Punto georreferenciado guardado correctamente.');
        } catch (error) { notify(error.message, true); }
        finally { $('#savePoint').disabled = false; $('#savePoint').textContent = 'Guardar punto georreferenciado'; }
    });

    initMaps();
    if (new URLSearchParams(window.location.search).get('crear') === '1' && permissions.create) setTimeout(() => openWizard(), 150);
})();
