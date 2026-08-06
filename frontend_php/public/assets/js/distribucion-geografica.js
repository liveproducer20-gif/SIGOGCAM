(function () {
    'use strict';
    const app = document.querySelector('.geo-app');
    if (!app) return;

    const $ = (s, r = document) => r.querySelector(s);
    const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
    const permissions = {
        create: app.dataset.canCreate === '1', edit: app.dataset.canEdit === '1',
        assign: app.dataset.canAssign === '1', catalogs: app.dataset.canCatalogs === '1'
    };
    const stateColors = { ACTIVA: '#2563EB', INACTIVA: '#6b7280', CUBIERTO: '#55ad38', SIN_ASIGNACION: '#aeb7c2', BORRADOR: '#e3ad23' };
    let map, wizardMap, previewMap, draftMarker, drawingLayer, drawMode = false;
    let markerLayer, selectedMarker = null;
    let currentRoute = null, currentRouteGeo = null;
    let tempPoints = [];

    async function api(resource, options = {}) {
        const response = await fetch(`/distribucion-geografica/api?resource=${encodeURIComponent(resource)}`, {
            method: options.method || 'GET',
            headers: options.body ? { 'Content-Type': 'application/json' } : {},
            body: options.body ? JSON.stringify(options.body) : undefined
        });
        const payload = await response.json().catch(() => ({ ok: false, mensaje: 'Respuesta inválida' }));
        if (!response.ok || payload.ok !== true) throw new Error(payload.mensaje || payload.detail || 'Error');
        return payload;
    }

    function notify(msg, err = false) {
        const t = $('#geoToast');
        t.textContent = msg; t.classList.toggle('is-error', err); t.classList.add('is-visible');
        clearTimeout(notify._t); notify._t = setTimeout(() => t.classList.remove('is-visible'), 4000);
    }

    function esc(v) { const d = document.createElement('div'); d.textContent = v ?? ''; return d.innerHTML; }
    function timeTxt(v) { return v ? String(v).slice(0, 5) : '—'; }

    // ===================================================================
    // MAP INIT
    // ===================================================================
    function initMap() {
        if (!window.L) { $('#geoMap').innerHTML = '<div class="geo-map-empty">No se pudo cargar el mapa.</div>'; return; }
        map = L.map('geoMap', { zoomControl: true }).setView([-2.1894, -79.8891], 14);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 20, attribution: '&copy; OpenStreetMap' }).addTo(map);
        markerLayer = L.featureGroup().addTo(map);
        setTimeout(() => map.invalidateSize(), 100);
    }

    // ===================================================================
    // PIN MARKER
    // ===================================================================
    function pinIcon(color, selected = false) {
        const sz = selected ? 44 : 36;
        return L.divIcon({
            className: '',
            iconSize: [sz, sz + 14],
            iconAnchor: [sz / 2, sz + 10],
            html: `<div class="geo-pin-marker ${selected ? 'selected' : ''}" style="--pin-color:${color};width:${sz}px;height:${sz}px">
                <img src="/assets/img/pin-avatar.png" alt="Punto" width="${sz}" height="${sz}">
                <svg class="geo-pin-arrow" width="20" height="14" viewBox="0 0 20 14"><path d="M10 14L0 0h20z" fill="${color}"/></svg>
            </div>`
        });
    }

    // ===================================================================
    // DISTRICT → ROUTE FLOW
    // ===================================================================
    $('#filterDistrict')?.addEventListener('change', async e => {
        const routeSelect = $('#filterRoute');
        const lieuSelect = $('#filterServicePlace');
        routeSelect.innerHTML = '<option value="">Seleccione una ruta</option>';
        routeSelect.disabled = true;
        lieuSelect.innerHTML = '<option value="">Todos los lugares</option>';
        lieuSelect.disabled = true;
        clearMap();
        if (!e.target.value) return;
        try {
            const routes = (await api(`distritos/${e.target.value}/rutas`)).datos || [];
            routes.forEach(r => routeSelect.add(new Option(r.nombre, r.id)));
            routeSelect.add(new Option('— Dibujar nueva ruta —', 'nueva'));
            routeSelect.disabled = false;
        } catch (err) { notify(err.message, true); }
    });

    $('#filterRoute')?.addEventListener('change', async e => {
        const lieuSelect = $('#filterServicePlace');
        lieuSelect.innerHTML = '<option value="">Todos los lugares</option>';
        lieuSelect.disabled = true;
        clearMap();
        const addBtn = $('#btnAddPlace');
        if (addBtn) addBtn.style.display = 'none';
        if (!e.target.value) return;
        if (e.target.value === 'nueva') { openDrawWizard(); return; }
        try {
            const rutaId = e.target.value;
            const geoData = (await api(`rutas/${rutaId}/geografia`)).datos;
            const places = (await api(`rutas/${rutaId}/lugares-servicio`)).datos || [];
            if (geoData) { currentRouteGeo = geoData; drawRouteOnMap(geoData); }
            currentRoute = { id: rutaId };
            places.forEach(p => lieuSelect.add(new Option(p.nombre, p.id)));
            lieuSelect.disabled = false;
            loadServicePlaceMarkers(places);
            if (addBtn) addBtn.style.display = '';
        } catch (err) { notify(err.message, true); }
    });

    $('#filterServicePlace')?.addEventListener('change', async e => {
        if (!e.target.value) { loadServicePlaceMarkers(null); return; }
        try {
            const place = (await api(`lugares-servicio/${e.target.value}`)).datos;
            if (place && place.latitud && place.longitud) {
                markerLayer.clearLayers();
                const m = L.marker([place.latitud, place.longitud], { icon: pinIcon('#2563EB', true) }).addTo(map);
                m.bindTooltip(place.nombre, { permanent: true, direction: 'top', offset: [0, -18] });
                map.setView([place.latitud, place.longitud], 17);
            }
        } catch (err) { notify(err.message, true); }
    });

    function clearMap() {
        markerLayer.clearLayers();
        if (drawingLayer) { map.removeLayer(drawingLayer); drawingLayer = null; }
        currentRouteGeo = null; currentRoute = null;
    }

    function drawRouteOnMap(geo) {
        if (!geo || !geo.geojson || !window.L) return;
        try {
            const data = typeof geo.geojson === 'string' ? JSON.parse(geo.geojson) : geo.geojson;
            const style = { color: geo.color || '#2563EB', weight: geo.grosor || 6, opacity: geo.opacidad || 0.55 };
            if (data.type === 'FeatureCollection') {
                drawingLayer = L.geoJSON(data, { style }).addTo(map);
            } else if (data.type === 'Feature') {
                drawingLayer = L.geoJSON(data, { style }).addTo(map);
            } else {
                drawingLayer = L.geoJSON(data, { style }).addTo(map);
            }
            if (drawingLayer.getBounds) map.fitBounds(drawingLayer.getBounds(), { padding: [40, 40] });
        } catch (e) { console.error('Error dibujando ruta:', e); }
    }

    function loadServicePlaceMarkers(places) {
        markerLayer.clearLayers();
        if (!places || !window.L) return;
        places.forEach(p => {
            if (!p.latitud || !p.longitud) return;
            const m = L.marker([p.latitud, p.longitud], { icon: pinIcon(stateColors.CUBIERTO) }).addTo(map);
            m.bindTooltip(p.nombre, { direction: 'top', offset: [0, -18] });
            m.on('click', () => showServicePlaceDetail(p));
        });
    }

    // ===================================================================
    // SERVICE PLACE DETAIL
    // ===================================================================
    async function showServicePlaceDetail(place) {
        try {
            const full = (await api(`lugares-servicio/${place.id}`)).datos;
            const assigns = (await api(`lugares-servicio/${place.id}/asignaciones`)).datos || [];
            const assignsHtml = assigns.map(a => `<div class="geo-agent-chip"><span>${esc(a.agente)}</span><b>${esc(a.codigo)}</b></div>`).join('') || '<span class="geo-agent-chip">Sin personal asignado</span>';
            $('#geoDetail').innerHTML = `<header><h2>Lugar de servicio</h2><button type="button" id="closeDetail" aria-label="Cerrar">×</button></header>
              <div class="geo-point-head"><div class="geo-point-avatar">${assigns.length ? '♟' : '○'}</div><div><span class="geo-status">${esc(full.estado)}</span><h3>${esc(full.nombre)}</h3><small>${esc(full.direccion_referencial || '')}</small></div></div>
              <div class="geo-detail-list"><dl><dt>Ruta</dt><dd>${esc(full.ruta)}</dd><dt>Dirección referencial</dt><dd>${esc(full.direccion_referencial || '—')}</dd><dt>Coordenadas</dt><dd>${full.latitud || '—'}, ${full.longitud || '—'}</dd><dt>Agentes asignados (${assigns.length})</dt><dd><div class="geo-agent-chips">${assignsHtml}</div></dd></dl></div>
              <div class="geo-detail-actions">${permissions.assign ? `<button class="geo-primary" type="button" data-assign-place="${full.id}">Asignar agente</button>` : ''}${permissions.edit ? `<button class="geo-secondary" type="button" data-edit-place="${full.id}">Editar</button>` : ''}</div>`;
            $('#geoDetail').classList.add('is-open');
            $('#closeDetail')?.addEventListener('click', () => $('#geoDetail').classList.remove('is-open'));
            $$('[data-assign-place]').forEach(b => b.addEventListener('click', () => openAssignWizard(Number(b.dataset.assignPlace))));
            $$('[data-edit-place]').forEach(b => b.addEventListener('click', () => openEditPlaceWizard(Number(b.dataset.editPlace))));
        } catch (err) { notify(err.message, true); }
    }

    // ===================================================================
    // DRAW WIZARD (Crear nueva ruta)
    // ===================================================================
    const drawWizard = $('#drawWizard');

    function openDrawWizard() {
        if (!drawWizard) return;
        drawWizard.hidden = false;
        document.body.style.overflow = 'hidden';
        $('#drawRouteName').value = '';
        $('#drawRouteDesc').value = '';
        $('#drawRouteColor').value = '#2563EB';
        $('#drawRouteWidth').value = '6';
        $('#drawRouteOpacity').value = '0.55';
        $('#drawRouteState').value = 'ACTIVA';
        $('#drawRouteGeometry').value = 'lineal';
        setupDrawMap();
    }

    function closeDrawWizard() { if (!drawWizard) return; drawWizard.hidden = true; document.body.style.overflow = ''; stopDrawing(); }

    function setupDrawMap() {
        if (!wizardMap) {
            wizardMap = L.map('drawMap').setView([-2.1894, -79.8891], 14);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 20, attribution: '&copy; OSM' }).addTo(wizardMap);
        }
        setTimeout(() => wizardMap.invalidateSize(), 80);
        drawingLayer = L.featureGroup().addTo(wizardMap);
    }

    function startDrawing() {
        drawMode = true; tempPoints = [];
        wizardMap.getContainer().style.cursor = 'crosshair';
        wizardMap.on('click', onMapClick);
        $('#drawTools').hidden = false;
        $('#startDraw').hidden = true;
    }

    function stopDrawing() {
        drawMode = false; tempPoints = [];
        wizardMap?.getContainer().style.cursor = '';
        wizardMap?.off('click', onMapClick);
    }

    function onMapClick(e) {
        tempPoints.push([e.latlng.lat, e.latlng.lng]);
        drawingLayer.clearLayers();
        const color = $('#drawRouteColor').value;
        const weight = Number($('#drawRouteWidth').value) || 6;
        const opacity = Number($('#drawRouteOpacity').value) || 0.55;
        if (tempPoints.length >= 2) {
            L.polyline(tempPoints, { color, weight, opacity }).addTo(drawingLayer);
        }
        tempPoints.forEach((p, i) => {
            L.circleMarker(p, { radius: 5, color: '#fff', fillColor: color, fillOpacity: 1, weight: 2 }).addTo(drawingLayer);
        });
    }

    function undoPoint() { if (tempPoints.length) { tempPoints.pop(); redrawTemp(); } }
    function clearDrawing() { tempPoints = []; drawingLayer.clearLayers(); }

    function redrawTemp() {
        drawingLayer.clearLayers();
        const color = $('#drawRouteColor').value;
        const weight = Number($('#drawRouteWidth').value) || 6;
        const opacity = Number($('#drawRouteOpacity').value) || 0.55;
        if (tempPoints.length >= 2) L.polyline(tempPoints, { color, weight, opacity }).addTo(drawingLayer);
        tempPoints.forEach(p => L.circleMarker(p, { radius: 5, color: '#fff', fillColor: color, fillOpacity: 1, weight: 2 }).addTo(drawingLayer));
    }

    async function saveRoute() {
        const name = $('#drawRouteName').value.trim();
        if (!name) return notify('Ingrese el nombre de la ruta.', true);
        if (tempPoints.length < 2) return notify('Dibuje al menos 2 puntos.', true);
        const districtId = $('#filterDistrict').value;
        if (!districtId) return notify('Seleccione un distrito.', true);
        const payload = {
            distrito_id: Number(districtId),
            ruta_id: 0,
            nombre: name,
            descripcion: $('#drawRouteDesc').value.trim() || null,
            tipo_geometria: $('#drawRouteGeometry').value,
            geojson: JSON.stringify({ type: 'LineString', coordinates: tempPoints.map(p => [p[1], p[0]]) }),
            color: $('#drawRouteColor').value,
            grosor: Number($('#drawRouteWidth').value),
            opacidad: Number($('#drawRouteOpacity').value),
            estado: $('#drawRouteState').value
        };
        try {
            const result = await api('rutas-geograficas', { method: 'POST', body: payload });
            notify('Ruta guardada correctamente.');
            closeDrawWizard();
            const routeSelect = $('#filterRoute');
            if (routeSelect) {
                const opt = document.createElement('option');
                opt.value = result.id; opt.textContent = name;
                routeSelect.insertBefore(opt, routeSelect.querySelector('[value="nueva"]'));
                routeSelect.value = String(result.id);
                routeSelect.dispatchEvent(new Event('change'));
            }
        } catch (err) { notify(err.message, true); }
    }

    $('#startDraw')?.addEventListener('click', startDrawing);
    $('#undoPoint')?.addEventListener('click', undoPoint);
    $('#clearDrawing')?.addEventListener('click', clearDrawing);
    $('#saveRoute')?.addEventListener('click', saveRoute);
    $('#cancelDraw')?.addEventListener('click', closeDrawWizard);
    $('#cancelDraw2')?.addEventListener('click', closeDrawWizard);
    $('#drawRouteColor')?.addEventListener('input', redrawTemp);
    drawWizard?.addEventListener('click', e => { if (e.target === drawWizard) closeDrawWizard(); });

    $('#btnNewRoute')?.addEventListener('click', () => openDrawWizard());
    $('#btnAddPlace')?.addEventListener('click', () => window.openAddPlaceWizard());

    // ===================================================================
    // ADD / EDIT SERVICE PLACE WIZARD
    // ===================================================================
    const placeWizard = $('#placeWizard');
    const placeForm = $('#placeForm');

    window.openAddPlaceWizard = function () {
        if (!currentRoute) return notify('Seleccione una ruta primero.', true);
        placeForm.reset();
        $('#placeWizardTitle').textContent = 'Agregar lugar de servicio';
        $('#place_id').value = '';
        placeWizard.hidden = false;
        document.body.style.overflow = 'hidden';
        setupPlaceMap();
    };

    window.openEditPlaceWizard = async function (placeId) {
        try {
            const place = (await api(`lugares-servicio/${placeId}`)).datos;
            placeForm.reset();
            $('#placeWizardTitle').textContent = 'Editar lugar de servicio';
            $('#place_id').value = place.id;
            placeForm.elements.nombre.value = place.nombre || '';
            placeForm.elements.descripcion.value = place.descripcion || '';
            placeForm.elements.direccion_referencial.value = place.direccion_referencial || '';
            placeForm.elements.latitud.value = place.latitud || '';
            placeForm.elements.longitud.value = place.longitud || '';
            placeForm.elements.estado.value = place.estado || 'ACTIVO';
            placeWizard.hidden = false;
            document.body.style.overflow = 'hidden';
            setupPlaceMap();
            if (place.latitud && place.longitud) setPlaceMarker(Number(place.latitud), Number(place.longitud));
        } catch (err) { notify(err.message, true); }
    };

    function closePlaceWizard() { if (!placeWizard) return; placeWizard.hidden = true; document.body.style.overflow = ''; }

    let placeMap, placeMarker;
    function setupPlaceMap() {
        if (!placeMap) {
            placeMap = L.map('placeMap').setView([-2.1894, -79.8891], 14);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 20, attribution: '&copy; OSM' }).addTo(placeMap);
            placeMap.on('click', e => setPlaceMarker(e.latlng.lat, e.latlng.lng));
        }
        setTimeout(() => placeMap.invalidateSize(), 80);
    }

    function setPlaceMarker(lat, lng) {
        placeForm.elements.latitud.value = lat.toFixed(7);
        placeForm.elements.longitud.value = lng.toFixed(7);
        if (placeMarker) placeMarker.setLatLng([lat, lng]);
        else {
            placeMarker = L.marker([lat, lng], { draggable: true, icon: pinIcon('#e3ad23', true) }).addTo(placeMap);
            placeMarker.on('dragend', () => { const p = placeMarker.getLatLng(); setPlaceMarker(p.lat, p.lng); });
        }
        placeMap.setView([lat, lng], 17);
    }

    placeForm?.addEventListener('submit', async e => {
        e.preventDefault();
        const id = $('#place_id').value;
        const payload = {
            ruta_id: Number(currentRoute.id),
            nombre: placeForm.elements.nombre.value.trim(),
            descripcion: placeForm.elements.descripcion.value.trim() || null,
            direccion_referencial: placeForm.elements.direccion_referencial.value.trim() || null,
            latitud: placeForm.elements.latitud.value ? Number(placeForm.elements.latitud.value) : null,
            longitud: placeForm.elements.longitud.value ? Number(placeForm.elements.longitud.value) : null,
            estado: placeForm.elements.estado.value
        };
        try {
            if (id) await api(`lugares-servicio/${id}`, { method: 'PUT', body: payload });
            else await api('lugares-servicio', { method: 'POST', body: payload });
            notify(id ? 'Lugar actualizado.' : 'Lugar creado.');
            closePlaceWizard();
            $('#filterRoute')?.dispatchEvent(new Event('change'));
        } catch (err) { notify(err.message, true); }
    });

    $('#cancelPlace')?.addEventListener('click', closePlaceWizard);
    $('#cancelPlace2')?.addEventListener('click', closePlaceWizard);
    placeWizard?.addEventListener('click', e => { if (e.target === placeWizard) closePlaceWizard(); });

    // ===================================================================
    // ASSIGN AGENT WIZARD
    // ===================================================================
    const assignWizard = $('#assignWizard');
    let assignPlaceId = null, selectedAgent = null;

    window.openAssignWizard = function (placeId) {
        if (!assignWizard) return;
        assignPlaceId = placeId; selectedAgent = null;
        $('#assignEditor').hidden = true;
        $('#agentResults').innerHTML = '';
        $('#agentSearch').value = '';
        assignWizard.hidden = false;
        document.body.style.overflow = 'hidden';
    };

    function closeAssignWizard() { if (!assignWizard) return; assignWizard.hidden = true; document.body.style.overflow = ''; }

    let searchTimer;
    $('#agentSearch')?.addEventListener('input', e => {
        clearTimeout(searchTimer);
        const q = e.target.value.trim();
        if (q.length < 2) { $('#agentResults').innerHTML = ''; return; }
        searchTimer = setTimeout(async () => {
            try {
                const people = (await api(`personal/buscar?q=${encodeURIComponent(q)}`)).datos || [];
                $('#agentResults').innerHTML = people.slice(0, 10).map(p => `<div class="geo-agent-result" data-person='${esc(JSON.stringify(p))}'><i>${esc((p.nombres?.[0] || '') + (p.apellidos?.[0] || ''))}</i><span><strong>${esc(p.nombre_completo)}</strong><small>${esc(p.cargo || 'Agente')} · ${esc(p.estado_personal || '')}</small></span></div>`).join('') || '<div class="geo-agent-result">Sin resultados.</div>';
                $$('.geo-agent-result[data-person]', $('#agentResults')).forEach(row => row.addEventListener('click', () => {
                    selectedAgent = JSON.parse(row.dataset.person);
                    $('#agentResults').innerHTML = '';
                    $('#agentSearch').value = '';
                    $('#selectedAgent').innerHTML = `<i>${esc((selectedAgent.nombres?.[0] || '') + (selectedAgent.apellidos?.[0] || ''))}</i><span><strong>${esc(selectedAgent.nombre_completo)}</strong><small>${esc(selectedAgent.cedula)} · ${esc(selectedAgent.cargo || 'Agente')}</small></span>`;
                    $('#assignmentEditor').hidden = false;
                }));
            } catch (err) { notify(err.message, true); }
        }, 280);
    });

    $('#addAgent')?.addEventListener('click', async () => {
        if (!selectedAgent || !assignPlaceId) return;
        if (!$('#assignStartDate').value || !$('#assignStartTime').value || !$('#assignEndTime').value) return notify('Complete fecha y horario.', true);
        try {
            await api(`lugares-servicio/${assignPlaceId}/asignaciones`, { method: 'POST', body: {
                personal_id: selectedAgent.id,
                tipo_asignacion: $('#assignType').value,
                fecha_inicio: $('#assignStartDate').value,
                fecha_fin: $('#assignEndDate').value || null,
                turno_id: Number($('#assignShift').value) || 1,
                hora_inicio: $('#assignStartTime').value,
                hora_fin: $('#assignEndTime').value,
                funcion: $('#assignRole').value || null,
                observaciones: $('#assignNotes').value || null
            }});
            notify('Agente asignado.');
            closeAssignWizard();
            $('#filterServicePlace')?.dispatchEvent(new Event('change'));
        } catch (err) { notify(err.message, true); }
    });

    $('#cancelAssign')?.addEventListener('click', closeAssignWizard);
    $('#cancelAssign2')?.addEventListener('click', closeAssignWizard);
    assignWizard?.addEventListener('click', e => { if (e.target === assignWizard) closeAssignWizard(); });

    // ===================================================================
    // TOOLBAR
    // ===================================================================
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

    $('#geoMenuToggle')?.addEventListener('click', () => app.classList.toggle('menu-open'));

    initMap();
})();
