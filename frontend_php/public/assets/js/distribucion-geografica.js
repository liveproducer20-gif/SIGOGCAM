(function () {
    'use strict';
    const app = document.querySelector('.geo-app');
    if (!app) return;

    const $ = (selector, root = document) => root.querySelector(selector);
    const esc = value => { const node = document.createElement('div'); node.textContent = value ?? ''; return node.innerHTML; };
    const permissions = { trace: app.dataset.canTrace === '1', edit: app.dataset.canEdit === '1' };
    const colors = { ASIGNADO: '#22a447', PENDIENTE: '#f59e0b', NOVEDAD: '#dc3545', INACTIVO: '#8c98a8' };
    let map, districtLayer, circuitLayer, routeLayer, pointLayer, personnelLayer, editLayer, temporaryMarker;
    let selection = { districtId: null, districtName: '', circuitoId: null, circuitoName: '', routeId: null, routeName: '', shiftId: null, fecha: new Date().toISOString().slice(0, 10) };
    let mapData = null, mode = null, traceTarget = 'RUTA', tracePoints = [], pendingLocation = null;
    const serviceTypeInputs = () => Array.from(document.querySelectorAll('#geoServiceOptions input[type="checkbox"]'));
    const serviceKey = value => String(value || '').trim().toLocaleUpperCase('es');
    let selectedServiceTypes = new Set(serviceTypeInputs().filter(input => input.checked).map(input => serviceKey(input.value)));

    async function api(resource, options = {}) {
        const response = await fetch(`/distribucion-geografica/api?resource=${encodeURIComponent(resource)}`, {
            method: options.method || 'GET',
            headers: options.body ? { 'Content-Type': 'application/json' } : {},
            body: options.body ? JSON.stringify(options.body) : undefined
        });
        const payload = await response.json().catch(() => ({ ok: false, mensaje: 'Respuesta inválida del servidor' }));
        if (!response.ok || payload.ok !== true) throw new Error(payload.mensaje || payload.detail || 'No se pudo completar la operación');
        return payload.datos;
    }

    function qs(params) {
        const parts = [];
        for (const [k, v] of Object.entries(params)) {
            if (v !== null && v !== undefined && v !== '') parts.push(`${k}=${encodeURIComponent(v)}`);
        }
        return parts.length ? '?' + parts.join('&') : '';
    }

    function notify(message, error = false) {
        const toast = $('#geoToast');
        if (!toast) return;
        toast.textContent = message;
        toast.classList.toggle('is-error', error);
        toast.classList.add('is-visible');
        clearTimeout(notify.timer);
        notify.timer = setTimeout(() => toast.classList.remove('is-visible'), 4200);
    }

    function openDetailPanel() {
        const detail = $('#geoDetail');
        const workspace = $('.geo-workspace');
        if (!detail || !workspace) return;
        workspace.classList.remove('is-detail-closed');
        detail.classList.add('is-open');
        detail.setAttribute('aria-hidden', 'false');
        setTimeout(() => map?.invalidateSize(), 300);
    }

    function closeDetailPanel() {
        const detail = $('#geoDetail');
        const workspace = $('.geo-workspace');
        if (!detail || !workspace) return;
        detail.classList.remove('is-open');
        detail.setAttribute('aria-hidden', 'true');
        workspace.classList.add('is-detail-closed');
        setTimeout(() => map?.invalidateSize(), 300);
    }

    $('#geoDetail')?.addEventListener('click', event => {
        if (event.target.closest('#closeDetail')) closeDetailPanel();
    });

    function pinIcon(state, temporary = false, serviceType = '') {
        const color = temporary ? '#2563EB' : (colors[state] || colors.PENDIENTE);
        const normalizedType = String(serviceType).toUpperCase().replace(/\s+/g, '');
        if (!temporary) {
            if (normalizedType.includes('PEDESTRE')) {
                return L.divIcon({
                    className: 'geo-pin-host geo-service-pin-host', iconSize: [46, 54], iconAnchor: [23, 52], popupAnchor: [0, -50],
                    html: `<span class="geo-service-pin" style="--pin-color:${color}"><img src="/assets/img/pinp.png" alt="" draggable="false"></span>`
                });
            }
            if (normalizedType.includes('ENCARGADODERUTA')) {
                return L.divIcon({
                    className: 'geo-pin-host geo-service-pin-host', iconSize: [46, 54], iconAnchor: [23, 52], popupAnchor: [0, -50],
                    html: `<span class="geo-service-pin" style="--pin-color:${color}"><img src="/assets/img/aj-icon.png?v=2" alt="" draggable="false"></span>`
                });
            }
        }
        return L.divIcon({
            className: 'geo-pin-host', iconSize: [34, 44], iconAnchor: [17, 42], popupAnchor: [0, -39],
            html: `<span class="geo-pin${temporary ? ' is-temporary' : ''}" style="--pin-color:${color}"><i></i></span>`
        });
    }

    function initializeMap() {
        if (!window.L) return notify('No se pudo cargar la librería del mapa.', true);
        map = L.map('geoMap', { zoomControl: true }).setView([-2.1894, -79.8891], 14);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 20, attribution: '&copy; OpenStreetMap'
        }).addTo(map);
        districtLayer = L.featureGroup().addTo(map);
        circuitLayer = L.featureGroup().addTo(map);
        routeLayer = L.featureGroup().addTo(map);
        pointLayer = L.featureGroup().addTo(map);
        personnelLayer = L.featureGroup().addTo(map);
        editLayer = L.featureGroup().addTo(map);
        map.on('click', onMapClick);
        setTimeout(() => map.invalidateSize(), 100);
    }

    function resetMap() {
        cancelEditing(false);
        districtLayer?.clearLayers();
        circuitLayer?.clearLayers();
        routeLayer?.clearLayers();
        pointLayer?.clearLayers();
        personnelLayer?.clearLayers();
        editLayer?.clearLayers();
        mapData = null;
        $('#visiblePointCount').textContent = '0';
        ['statRegistered', 'statCovered', 'statUnassigned', 'statPersonnel', 'statRoutes'].forEach(id => { const el = $('#' + id); if (el) el.textContent = '0'; });
        const traceButton = $('#btnTrace');
        const locationButton = $('#btnLocation');
        if (traceButton) traceButton.disabled = true;
        if (locationButton) locationButton.disabled = true;
        closeDetailPanel();
    }

    $('#filterDistrict')?.addEventListener('change', async event => {
        const circuitoSelect = $('#filterCircuito');
        const routeSelect = $('#filterRoute');
        resetMap();
        const fechaVal = $('#filterDate')?.value || new Date().toISOString().slice(0, 10);
        const shiftVal = $('#filterShift')?.value || '';
        selection = { districtId: event.target.value ? Number(event.target.value) : null,
            districtName: event.target.selectedOptions[0]?.textContent || '',
            circuitoId: null, circuitoName: '', routeId: null, routeName: '', shiftId: shiftVal ? Number(shiftVal) : null, fecha: fechaVal };
        circuitoSelect.innerHTML = '<option value="">Cargando circuitos...</option>';
        circuitoSelect.disabled = true;
        routeSelect.innerHTML = '<option value="">Seleccione un circuito primero</option>';
        routeSelect.disabled = true;
        if (!selection.districtId) {
            circuitoSelect.innerHTML = '<option value="">Seleccione un distrito primero</option>';
            await loadGlobalMap();
            return;
        }
        try {
            const circuits = await api(`distritos/${selection.districtId}/circuitos`) || [];
            circuitoSelect.innerHTML = '<option value="">Todos los circuitos</option>';
            circuits.forEach(c => circuitoSelect.add(new Option(c.nombre, c.id)));
            circuitoSelect.disabled = false;
            circuitoSelect.value = '';
            circuitoSelect.dispatchEvent(new Event('change'));
        } catch (error) { notify(error.message, true); }
    });

    $('#filterCircuito')?.addEventListener('change', async event => {
        const routeSelect = $('#filterRoute');
        resetMap();
        const val = event.target.value;
        selection.circuitoId = val ? Number(val) : null;
        selection.circuitoName = val ? (event.target.selectedOptions[0]?.textContent || '') : '';
        selection.routeId = null;
        selection.routeName = '';
        routeSelect.innerHTML = '<option value="">Cargando rutas...</option>';
        routeSelect.disabled = true;
        if (!selection.circuitoId) {
            routeSelect.innerHTML = '<option value="">Todas las rutas</option>';
            selection.showAll = true;
            await loadAllRoutesMap();
            return;
        }
        try {
            const routes = await api(`circuitos/${selection.circuitoId}/rutas`) || [];
            routeSelect.innerHTML = '<option value="">Todas las Rutas</option>';
            if (routes.length === 0) {
                routeSelect.innerHTML = '<option value="">Sin rutas disponibles</option>';
            } else {
                routes.forEach(route => routeSelect.add(new Option(route.nombre, route.id)));
            }
            routeSelect.disabled = false;
            routeSelect.value = '';
            routeSelect.dispatchEvent(new Event('change'));
        } catch (error) { notify(error.message, true); }
    });

    $('#filterRoute')?.addEventListener('change', async event => {
        resetMap();
        const val = event.target.value;
        selection.routeId = val ? Number(val) : null;
        selection.routeName = val ? (event.target.selectedOptions[0]?.textContent || '') : '';
        selection.showAll = !val;
        if (!selection.districtId) return;
        if (selection.showAll && selection.circuitoId) {
            await loadAllRoutesMap();
        } else if (selection.routeId) {
            await loadRouteMap();
        }
    });

    $('#filterDate')?.addEventListener('change', async () => {
        const fechaVal = $('#filterDate')?.value || new Date().toISOString().slice(0, 10);
        selection.fecha = fechaVal;
        resetMap();
        if (!selection.districtId) {
            await loadGlobalMap();
        } else if (selection.showAll) {
            await loadAllRoutesMap();
        } else if (selection.routeId) {
            await loadRouteMap();
        }
    });

    $('#filterShift')?.addEventListener('change', async event => {
        selection.shiftId = event.target.value ? Number(event.target.value) : null;
        if (!selection.districtId) { await loadGlobalMap(); return; }
        await loadPersonnelOnly();
    });

    async function loadGlobalMap() {
        try {
            mapData = await api(`distribucion-geografica/mapa${qs({fecha: selection.fecha, turno_id: selection.shiftId})}`);
            renderGlobalMap();
        } catch (error) {
            resetMap(); notify(error.message, true);
        }
    }

    async function loadAllRoutesMap() {
        try {
            mapData = await api(`distribucion-geografica/distrito/${selection.districtId}/mapa-todas${qs({fecha: selection.fecha, circuito_id: selection.circuitoId, turno_id: selection.shiftId})}`);
            renderAllRoutesMap();
        } catch (error) {
            resetMap();
            notify(error.message, true);
        }
    }

    async function loadRouteMap() {
        try {
            mapData = await api(`distribucion-geografica/rutas/${selection.routeId}/mapa${qs({distrito_id: selection.districtId, circuito_id: selection.circuitoId, fecha: selection.fecha, turno_id: selection.shiftId})}`);
            renderRouteMap();
        } catch (error) {
            resetMap();
            notify(error.message, true);
        }
    }

    async function loadPersonnelOnly() {
        try {
            const personnel = await api(`distribucion-geografica/personal-mapa${qs({distrito_id: selection.districtId, circuito_id: selection.circuitoId, ruta_id: selection.routeId, fecha: selection.fecha, turno_id: selection.shiftId})}`);
            mapData.lugares = personnel?.lugares || [];
            mapData.encargados = personnel?.encargados || [];
            renderPersonnelOnly(mapData.lugares, mapData.encargados, selection.routeId ? 1 : (mapData.rutas || []).length);
        } catch (error) { notify(error.message, true); }
    }

    async function reloadCurrentMap() {
        if (!selection.districtId) return loadGlobalMap();
        if (selection.routeId) return loadRouteMap();
        return loadAllRoutesMap();
    }

    function renderGlobalMap() { renderAllRoutesMap(); }

    function addTrace(trace, layer, fallbackColor) {
        if (!trace?.geojson) return;
        try {
            const geojson = typeof trace.geojson === 'string' ? JSON.parse(trace.geojson) : trace.geojson;
            L.geoJSON(geojson, { style: {
                color: trace.color || fallbackColor, weight: Number(trace.grosor || 5),
                opacity: Number(trace.opacidad || .55), fillColor: trace.color || fallbackColor,
                fillOpacity: trace.tipo_geometria === 'area' ? Math.min(Number(trace.opacidad || .35), .35) : 0
            }}).addTo(layer);
        } catch (_) { notify('Uno de los trazados guardados no contiene GeoJSON válido.', true); }
    }

    function renderTraceLayers() {
        districtLayer.clearLayers(); circuitLayer.clearLayers(); routeLayer.clearLayers(); editLayer.clearLayers();
        if (mapData?.trazado_distrito) addTrace(mapData.trazado_distrito, districtLayer, '#7C3AED');
        (mapData?.trazados_distritos || []).forEach(item => addTrace(item.trace, districtLayer, '#7C3AED'));
        (mapData?.trazados_circuitos || []).forEach(item => addTrace(item.trace, circuitLayer, '#0891B2'));
        (mapData?.trazados || []).forEach(item => addTrace(item.trace, routeLayer, '#2563EB'));
        applyTraceVisibility();
        updateTraceButtons();
    }

    function updateTraceButtons() {
        const routeButton=$('#btnTrace');
        if (routeButton) {
            routeButton.disabled=!permissions.trace||(!selection.districtId&&!selection.circuitoId&&!selection.routeId);
        }
    }

    function renderAllRoutesMap() {
        const places = mapData?.lugares || [];
        const rutas = mapData?.rutas || [];
        renderTraceLayers();
        renderPersonnelLayer(places, mapData?.encargados || [], rutas.length);
        const bounds = L.featureGroup([districtLayer,circuitLayer,routeLayer,pointLayer,personnelLayer]).getBounds();
        if (bounds.isValid()) map.fitBounds(bounds, { padding: [42, 42], maxZoom: 17 });
    }

    function renderRouteMap() {
        const route = mapData?.ruta;
        const places = mapData?.lugares || [];
        if (!route) return;
        selection.routeName = route.nombre;
        const locationButton = $('#btnLocation');
        if (locationButton) locationButton.disabled = !permissions.edit;
        renderTraceLayers();
        renderPersonnelLayer(places, mapData?.encargados || [], 1);
        const bounds = L.featureGroup([districtLayer,circuitLayer,routeLayer,pointLayer,personnelLayer]).getBounds();
        if (bounds.isValid()) map.fitBounds(bounds, { padding: [42, 42], maxZoom: 17 });
    }

    function renderPersonnelLayer(places, managers, routeCount) {
        pointLayer.clearLayers();
        renderPersonnelOnly(places,managers,routeCount);
    }

    function renderPersonnelOnly(places,managers,routeCount) {
        personnelLayer.clearLayers();
        const allServiceTypesSelected = serviceTypeInputs().length > 0 && serviceTypeInputs().every(input => input.checked);
        const visiblePlaces = (places || []).filter(place => {
            const key = serviceKey(place.tipo_servicio);
            return selectedServiceTypes.has(key) || (allServiceTypesSelected && !key);
        });
        const visibleManagers = (managers || []).filter(manager => selectedServiceTypes.has(serviceKey(manager.tipo_servicio)));
        visiblePlaces.filter(place=>place.latitud!=null&&place.longitud!=null).forEach(place=>{
            if (!pointLayer.getLayers().some(layer=>Number(layer.options?.placeId)===Number(place.id))) addPointBaseMarker(place);
            if (place.agente_id) addPlaceMarker(place,personnelLayer);
        });
        visibleManagers.filter(manager => manager.latitud != null && manager.longitud != null).forEach(addManagerMarker);
        $('#visiblePointCount').textContent = String(visiblePlaces.length+visibleManagers.length);
        $('#statRegistered').textContent = String(visiblePlaces.length);
        $('#statCovered').textContent = String(visiblePlaces.filter(item => item.agente_id).length + visibleManagers.length);
        $('#statUnassigned').textContent = String(visiblePlaces.filter(item => !item.agente_id).length);
        const personnelIds = [...visiblePlaces.filter(item => item.agente_id).map(item => `P-${item.agente_id}`), ...visibleManagers.map(item => `P-${item.agente_id}`)];
        $('#statPersonnel').textContent = String(new Set(personnelIds).size);
        $('#statRoutes').textContent = String(routeCount || 0);
    }

    function rerenderPersonnelOnly() {
        if (!mapData) { personnelLayer?.clearLayers(); pointLayer?.clearLayers(); $('#visiblePointCount').textContent = '0'; return; }
        const routeCount = selection.routeId ? 1 : Number((mapData.rutas || []).length);
        renderPersonnelLayer(mapData.lugares || [], mapData.encargados || [], routeCount);
    }

    function addPointBaseMarker(place) {
        const base={...place,agente_id:null,agente:null,grado:null,hora_inicio:null,hora_fin:null,estado_mapa:'PENDIENTE'};
        const marker=L.marker([Number(place.latitud),Number(place.longitud)],{icon:pinIcon('PENDIENTE',false,place.tipo_servicio),placeId:Number(place.id)}).addTo(pointLayer);
        marker.bindTooltip(esc(place.nombre),{direction:'top',offset:[0,-30]});
        marker.bindPopup(placePopup(base),{maxWidth:320});
        marker.on('click',()=>showPlaceDetail(base));
    }

    function addPlaceMarker(place, layer = personnelLayer) {
        const state = String(place.estado_operativo || '').toUpperCase() === 'NOVEDAD' ? 'NOVEDAD' : place.estado_mapa;
        const marker = L.marker([Number(place.latitud), Number(place.longitud)], { icon: pinIcon(state, false, place.tipo_servicio) }).addTo(layer);
        marker.bindTooltip(esc(place.nombre), { direction: 'top', offset: [0, -30] });
        marker.bindPopup(placePopup(place), { maxWidth: 320 });
        marker.on('click', () => showPlaceDetail(place));
    }

    function managerIcon(manager) {
        const isDistrict = manager.tipo_responsabilidad === 'ENCARGADO_DISTRITO';
        const color = isDistrict ? '#6d3fd1' : '#1267d5';
        if (isDistrict) {
            return L.divIcon({
                className:'geo-manager-pin-host',iconSize:[46,54],iconAnchor:[23,52],popupAnchor:[0,-48],
                html:`<span class="geo-manager-pin" style="--manager-color:${color}"><b>ED</b></span>`
            });
        }
        return L.divIcon({
            className:'geo-manager-pin-host',iconSize:[46,54],iconAnchor:[23,52],popupAnchor:[0,-48],
            html:`<span class="geo-manager-pin geo-manager-pin--route" style="--manager-color:${color}"><img src="/assets/img/aj-icon.png?v=2" alt="ER"></span>`
        });
    }

    function addManagerMarker(manager) {
        const marker=L.marker([Number(manager.latitud),Number(manager.longitud)],{icon:managerIcon(manager)}).addTo(personnelLayer);
        marker.bindTooltip(esc(manager.tipo_servicio),{direction:'top',offset:[0,-30]});
        marker.bindPopup(managerPopup(manager),{maxWidth:340});
        marker.on('click',()=>showManagerDetail(manager));
    }

    function managerPopup(manager) {
        const routeRow=manager.tipo_responsabilidad==='ENCARGADO_RUTA'?`<dt>Ruta</dt><dd>${esc(manager.ruta || '—')}</dd>`:'';
        return `<div class="geo-popup"><h3>${esc(manager.tipo_servicio)}</h3><dl><dt>Agente</dt><dd>${esc(manager.agente || '—')}</dd><dt>Rango / grado</dt><dd>${esc(manager.grado || '—')}</dd><dt>Distrito</dt><dd>${esc(manager.distrito || '—')}</dd>${routeRow}<dt>Horario</dt><dd>${time(manager.hora_inicio)} - ${time(manager.hora_fin)}</dd><dt>Fecha</dt><dd>${esc(selection.fecha || '—')}</dd></dl><span class="geo-popup-state is-assigned">Asignado</span></div>`;
    }

    function showManagerDetail(manager) {
        const detail=$('#geoDetail'); if(!detail)return;
        const routeRow=manager.tipo_responsabilidad==='ENCARGADO_RUTA'?`<dt>Ruta</dt><dd>${esc(manager.ruta || '—')}</dd>`:'';
        detail.innerHTML=`<header><h2>Información del encargado</h2><button type="button" id="closeDetail" aria-label="Cerrar">×</button></header><div class="geo-point-head"><div class="geo-point-avatar">${manager.tipo_responsabilidad==='ENCARGADO_DISTRITO'?'ED':'ER'}</div><div><span class="geo-status">${esc(manager.tipo_servicio)}</span><h3>${esc(manager.agente || '—')}</h3><small>${esc(manager.grado || '')}</small></div></div><div class="geo-detail-list"><dl><dt>Fecha</dt><dd>${esc(selection.fecha || '—')}</dd><dt>Distrito</dt><dd>${esc(manager.distrito || '—')}</dd>${routeRow}<dt>Agente</dt><dd>${esc(manager.agente || '—')}</dd><dt>Rango / grado</dt><dd>${esc(manager.grado || '—')}</dd><dt>Horario</dt><dd>${time(manager.hora_inicio)} - ${time(manager.hora_fin)}</dd><dt>Tipo de servicio</dt><dd>${esc(manager.tipo_servicio)}</dd></dl></div>`;
        openDetailPanel();
    }

    function placePopup(place) {
        const assigned = Boolean(place.agente_id);
        return `<div class="geo-popup"><h3>${esc(place.nombre)}</h3>
            <dl><dt>Fecha</dt><dd>${esc(selection.fecha || '—')}</dd>
            <dt>Agente asignado</dt><dd>${assigned ? esc(place.agente) : 'Sin asignación'}</dd>
            <dt>Grado / rango</dt><dd>${assigned ? esc(place.grado || '—') : '—'}</dd>
            <dt>Horario</dt><dd>${assigned ? `${time(place.hora_inicio)} - ${time(place.hora_fin)}` : '—'}</dd>
            <dt>Tipo de servicio</dt><dd>${esc(place.tipo_servicio || '—')}</dd></dl>
            <span class="geo-popup-state ${assigned ? 'is-assigned' : ''}">${assigned ? 'Asignado' : 'Sin asignación'}</span></div>`;
    }

    function showPlaceDetail(place) {
        const detail = $('#geoDetail');
        if (!detail) return;
        const routeLabel = place.route_name || selection.routeName || '';
        const canEditPin = permissions.edit && place.latitud && place.longitud;
        detail.innerHTML = `<header><h2>Información del lugar</h2><button type="button" id="closeDetail" aria-label="Cerrar">×</button></header>
            <div class="geo-point-head"><div class="geo-point-avatar">⌖</div><div><span class="geo-status">${place.agente_id ? 'Asignado' : 'Sin asignación'}</span><h3>${esc(place.nombre)}</h3><small>${esc(place.direccion_referencial || '')}</small></div></div>
            <div class="geo-detail-list"><dl><dt>Fecha</dt><dd>${esc(selection.fecha || '—')}</dd><dt>Ruta</dt><dd>${esc(routeLabel)}</dd><dt>Coordenadas</dt><dd>${place.latitud}, ${place.longitud}</dd>
            <dt>Agente</dt><dd>${esc(place.agente || 'Sin asignación')}</dd><dt>Grado</dt><dd>${esc(place.grado || '—')}</dd>
            <dt>Horario</dt><dd>${place.agente_id ? `${time(place.hora_inicio)} - ${time(place.hora_fin)}` : '—'}</dd><dt>Tipo de servicio</dt><dd>${esc(place.tipo_servicio || '—')}</dd></dl></div>
            ${canEditPin ? `<div class="geo-detail-actions"><button class="geo-btn-delete-pin" type="button" id="deletePin" data-place-id="${place.id}">✕ Eliminar pin del mapa</button></div>` : ''}`;
        openDetailPanel();
        $('#deletePin')?.addEventListener('click', () => removePlacePin(place));
    }

    async function removePlacePin(place) {
        if (!confirm(`¿Está seguro de eliminar el pin "${place.nombre}" del mapa?\n\nEl lugar de servicio seguirá existiendo, pero se perderá su ubicación geográfica.`)) return;
        try {
            await api(`distribucion-geografica/lugares/${place.id}/ubicacion`, { method: 'DELETE' });
            notify('Pin eliminado correctamente');
            closeDetailPanel();
            if (selection.showAll) {
                await loadAllRoutesMap();
            } else if (selection.routeId) {
                await loadRouteMap();
            }
        } catch (error) {
            notify(error.message, true);
        }
    }

    function time(value) { return value ? String(value).slice(0, 5) : '—'; }

    function traceForTarget(target) {
        if (target==='DISTRITO') return mapData?.trazado_distrito;
        if (target==='CIRCUITO') return (mapData?.trazados_circuitos||[]).find(x=>Number(x.circuito_id)===selection.circuitoId)?.trace;
        return mapData?.ruta?.trazado||(mapData?.trazados||[]).find(x=>Number(x.route_id)===selection.routeId)?.trace;
    }

    function startTrace(target) {
        if (!selection.districtId) return notify('Seleccione un distrito.',true);
        if (target==='CIRCUITO'&&!selection.circuitoId) return notify('Seleccione un circuito específico; “Todos los circuitos” no se puede editar.',true);
        if (target==='RUTA'&&!selection.routeId) return notify('Seleccione una ruta específica.',true);
        cancelEditing(false);
        mode = 'trace';
        traceTarget=target;
        tracePoints = [];
        editLayer.clearLayers();
        ({DISTRITO:districtLayer,CIRCUITO:circuitLayer,RUTA:routeLayer}[target])?.clearLayers();
        const savedTrace=traceForTarget(target);
        $('#traceType').value=savedTrace?.tipo_geometria==='lineal'?'lineal':(target==='RUTA'?'lineal':'area');
        $('#traceColor').value = /^#[0-9a-f]{6}$/i.test(savedTrace?.color || '') ? savedTrace.color : '#2563EB';
        $('#traceWidth').value = String(Number(savedTrace?.grosor || 6));
        updateTraceOptions();
        map.getContainer().classList.add('is-drawing');
        $('#traceTools').hidden = false;
        $('#traceOptions').hidden = false;
        const label=target==='DISTRITO'?'distrito':target==='CIRCUITO'?'circuito':'ruta';
        notify(`Haga clic en el mapa para definir el trazado del ${label}.`);
    }
    const traceDropdown=$('#traceDropdown');
    const traceMenu=$('#traceMenu');
    if ($('#btnTrace')) {
        $('#btnTrace').addEventListener('click',e=>{
            e.stopPropagation();
            if ($('#btnTrace').disabled) return;
            const open=!traceMenu.hidden;
            traceMenu.hidden=open;
            $('#btnTrace').setAttribute('aria-expanded',String(!open));
        });
    }
    if (traceMenu) {
        traceMenu.querySelectorAll('button').forEach(btn=>{
            btn.addEventListener('click',()=>{
                traceMenu.hidden=true;
                $('#btnTrace')?.setAttribute('aria-expanded','false');
                const target=btn.dataset.traceTarget||btn.id==='btnDistrictTrace'?'DISTRITO':btn.id==='btnCircuitTrace'?'CIRCUITO':'RUTA';
                startTrace(target);
            });
        });
    }
    document.addEventListener('click',()=>{if(traceMenu)traceMenu.hidden=true;});
    if (traceDropdown) traceDropdown.addEventListener('click',e=>e.stopPropagation());

    function onMapClick(event) {
        if (mode === 'trace') {
            tracePoints.push([event.latlng.lat, event.latlng.lng]);
            renderTemporaryTrace();
        } else if (mode === 'location') {
            pendingLocation = { latitud: event.latlng.lat, longitud: event.latlng.lng };
            if (temporaryMarker) temporaryMarker.setLatLng(event.latlng);
            else temporaryMarker = L.marker(event.latlng, { icon: pinIcon('PENDIENTE', true) }).addTo(editLayer);
            map.getContainer().classList.remove('is-locating');
            mode = null;
            $('#locationHint').hidden = true;
            openLocationModal();
        }
    }

    function renderTemporaryTrace() {
        editLayer.clearLayers();
        const type = $('#traceType').value;
        const color = $('#traceColor').value;
        const weight = Number($('#traceWidth').value);
        if (type === 'area' && tracePoints.length > 2) {
            L.polygon(tracePoints, { color, weight, opacity: .85, fillColor: color, fillOpacity: .18, dashArray: '8 5' }).addTo(editLayer);
        } else if (tracePoints.length > 1) {
            L.polyline(tracePoints, { color, weight, opacity: .8, dashArray: '8 5' }).addTo(editLayer);
        }
        tracePoints.forEach(point => L.circleMarker(point, { radius: 5, color: '#fff', weight: 2, fillColor: color, fillOpacity: 1 }).addTo(editLayer));
    }

    function updateTraceOptions() {
        const type = $('#traceType').value;
        $('#traceColorValue').textContent = $('#traceColor').value.toUpperCase();
        $('#traceWidthValue').textContent = `${$('#traceWidth').value} px`;
        $('#traceTypeHelp').textContent = type === 'area'
            ? 'Marque al menos tres puntos; el sistema cerrará el área automáticamente.'
            : 'Marque al menos dos puntos para formar el recorrido.';
        renderTemporaryTrace();
    }
    $('#traceType')?.addEventListener('change', updateTraceOptions);
    $('#traceColor')?.addEventListener('input', updateTraceOptions);
    $('#traceWidth')?.addEventListener('input', updateTraceOptions);

    $('#undoTrace')?.addEventListener('click', () => { tracePoints.pop(); renderTemporaryTrace(); });
    $('#cancelTrace')?.addEventListener('click', () => cancelEditing(true));
    $('#saveTrace')?.addEventListener('click', async () => {
        const traceType = $('#traceType').value;
        const minimum = traceType === 'area' ? 3 : 2;
        if (tracePoints.length < minimum) return notify(`Dibuje al menos ${minimum} puntos para guardar ${traceType === 'area' ? 'el área' : 'el trazado'}.`, true);
        const targetName=traceTarget==='DISTRITO'?selection.districtName:traceTarget==='CIRCUITO'?selection.circuitoName:selection.routeName;
        if (!window.confirm(`¿Desea guardar este trazado para ${targetName}?`)) return;
        try {
            const coordinates = tracePoints.map(point => [point[1], point[0]]);
            const geojson = traceType === 'area'
                ? { type: 'Polygon', coordinates: [[...coordinates, coordinates[0]]] }
                : { type: 'LineString', coordinates };
            const body={tipo_geometria:traceType,geojson,color:$('#traceColor').value,grosor:Number($('#traceWidth').value),opacidad:.55};
            let resource;
            if(traceTarget==='DISTRITO') resource=`distribucion-geografica/distritos/${selection.districtId}/trazado`;
            else if(traceTarget==='CIRCUITO') resource=`distribucion-geografica/circuitos/${selection.circuitoId}/trazado`;
            else { resource=`distribucion-geografica/rutas/${selection.routeId}/trazado`; body.distrito_id=selection.districtId; body.circuito_id=selection.circuitoId; }
            await api(resource,{method:'PUT',body});
            cancelEditing(false);
            notify('Trazado guardado correctamente.');
            await reloadCurrentMap();
        } catch (error) { notify(error.message, true); }
    });

    $('#btnLocation')?.addEventListener('click', () => {
        if (!selection.routeId) return notify('Seleccione un distrito y una ruta.', true);
        cancelEditing(false);
        mode = 'location';
        map.getContainer().classList.add('is-locating');
        $('#locationHint').hidden = false;
    });
    $('#cancelLocation')?.addEventListener('click', () => cancelEditing(true));

    function openLocationModal() {
        const modal = $('#locationModal');
        const select = $('#locationPlace');
        if (!modal || !pendingLocation) return;
        $('#locationDistrict').textContent = selection.districtName;
        $('#locationRoute').textContent = selection.routeName;
        $('#locationLat').textContent = pendingLocation.latitud.toFixed(7);
        $('#locationLng').textContent = pendingLocation.longitud.toFixed(7);
        select.innerHTML = '<option value="">Seleccione un lugar de servicio</option>';
        (mapData?.lugares || []).forEach(place => {
            const option = new Option(place.nombre, place.id);
            option.dataset.hasLocation = place.latitud != null && place.longitud != null ? '1' : '0';
            select.add(option);
        });
        $('#replaceWarning').hidden = true;
        $('#saveLocation').textContent = 'Guardar ubicación';
        modal.hidden = false;
        document.body.style.overflow = 'hidden';
    }

    $('#locationPlace')?.addEventListener('change', event => {
        const replace = event.target.selectedOptions[0]?.dataset.hasLocation === '1';
        $('#replaceWarning').hidden = !replace;
        $('#saveLocation').textContent = replace ? 'Reemplazar ubicación' : 'Guardar ubicación';
    });

    $('#locationForm')?.addEventListener('submit', async event => {
        event.preventDefault();
        const select = $('#locationPlace');
        const placeId = Number(select.value);
        if (!placeId || !pendingLocation) return notify('Seleccione un lugar de servicio.', true);
        const replace = select.selectedOptions[0]?.dataset.hasLocation === '1';
        if (replace && !window.confirm('Este lugar ya posee una ubicación. ¿Desea reemplazarla?')) return;
        try {
            await api(`distribucion-geografica/lugares/${placeId}/ubicacion`, { method: 'PUT', body: {
                distrito_id: selection.districtId, ruta_id: selection.routeId,
                latitud: pendingLocation.latitud, longitud: pendingLocation.longitud, reemplazar: replace
            }});
            closeLocationModal(false);
            notify(replace ? 'Ubicación reemplazada correctamente.' : 'Ubicación asignada correctamente.');
            await loadRouteMap();
        } catch (error) { notify(error.message, true); }
    });

    function closeLocationModal(restore = true) {
        const modal = $('#locationModal');
        if (modal) modal.hidden = true;
        document.body.style.overflow = '';
        pendingLocation = null;
        if (temporaryMarker) { editLayer.removeLayer(temporaryMarker); temporaryMarker = null; }
        if (restore && mapData) (selection.routeId ? renderRouteMap() : renderAllRoutesMap());
    }
    $('#closeLocation')?.addEventListener('click', () => closeLocationModal(true));
    $('#cancelLocationModal')?.addEventListener('click', () => closeLocationModal(true));

    function cancelEditing(restore = true) {
        mode = null;
        tracePoints = [];
        pendingLocation = null;
        temporaryMarker = null;
        editLayer?.clearLayers();
        map?.getContainer().classList.remove('is-drawing', 'is-locating');
        if ($('#traceTools')) $('#traceTools').hidden = true;
        if ($('#traceOptions')) $('#traceOptions').hidden = true;
        if ($('#locationHint')) $('#locationHint').hidden = true;
        if (restore && mapData) (selection.routeId ? renderRouteMap() : renderAllRoutesMap());
    }

    $('#centerGeoMap')?.addEventListener('click', () => {
        const bounds = L.featureGroup([districtLayer,circuitLayer,routeLayer,pointLayer,personnelLayer]).getBounds();
        if (bounds.isValid()) map.fitBounds(bounds, { padding: [35, 35], maxZoom: 17 });
        else map.setView([-2.1894, -79.8891], 14);
    });
    $('#fullscreenGeoMap')?.addEventListener('click', () => {
        $('.geo-map-wrap')?.classList.toggle('is-fullscreen');
        setTimeout(() => map.invalidateSize(), 220);
    });
    $('#geoFilterToggle')?.addEventListener('click', () => $('#geoFilters')?.classList.toggle('is-open'));

    function updateServiceTypeSelection() {
        selectedServiceTypes = new Set(serviceTypeInputs().filter(input=>input.checked).map(input=>serviceKey(input.value)));
        const total=serviceTypeInputs().length,selected=selectedServiceTypes.size;
        const button=$('#geoServiceToggle');
        const label=button?.querySelector('.geo-toggle-label');
        if(label) label.textContent=selected===0?'Sin tipos':selected===total?'Todos los tipos':`${selected} tipos seleccionados`;
        rerenderPersonnelOnly();
    }
    $('#geoServiceToggle')?.addEventListener('click',()=>{
        const menu=$('#geoServiceMenu'); const open=menu.hidden; menu.hidden=!open; $('#geoServiceToggle').setAttribute('aria-expanded',String(open));
    });
    $('#geoServiceOptions')?.addEventListener('change',updateServiceTypeSelection);
    $('#geoSelectAllTypes')?.addEventListener('click',()=>{serviceTypeInputs().forEach(input=>input.checked=true);updateServiceTypeSelection();});
    $('#geoClearTypes')?.addEventListener('click',()=>{serviceTypeInputs().forEach(input=>input.checked=false);updateServiceTypeSelection();});
    function applyTraceVisibility(){
        if(!map)return;
        const visible=new Set(Array.from(document.querySelectorAll('#geoLayerOptions input:checked')).map(input=>input.value));
        [[districtLayer,'district'],[circuitLayer,'circuit'],[routeLayer,'route']].forEach(([layer,key])=>{
            if(!layer)return;
            if(visible.has(key)){if(!map.hasLayer(layer))layer.addTo(map);}else if(map.hasLayer(layer))map.removeLayer(layer);
        });
        const button=$('#geoLayerToggle'); const label=button?.querySelector('.geo-toggle-label');
        if(label)label.textContent=`${visible.size} ${visible.size===1?'capa visible':'capas visibles'}`;
    }
    $('#geoLayerToggle')?.addEventListener('click',()=>{const menu=$('#geoLayerMenu');const open=menu.hidden;menu.hidden=!open;$('#geoLayerToggle').setAttribute('aria-expanded',String(open));});
    $('#geoLayerOptions')?.addEventListener('change',applyTraceVisibility);
    document.addEventListener('click',event=>{
        const filter=$('#geoServiceFilter'); if(filter&&!filter.contains(event.target)){ $('#geoServiceMenu').hidden=true; $('#geoServiceToggle').setAttribute('aria-expanded','false'); }
        const layerFilter=$('#geoLayerFilter'); if(layerFilter&&!layerFilter.contains(event.target)){ $('#geoLayerMenu').hidden=true; $('#geoLayerToggle').setAttribute('aria-expanded','false'); }
    });

    initializeMap();
    loadGlobalMap();
})();
