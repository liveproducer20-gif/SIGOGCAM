(function () {
    'use strict';
    const app = document.querySelector('.geo-app');
    if (!app) return;

    const $ = (selector, root = document) => root.querySelector(selector);
    const esc = value => { const node = document.createElement('div'); node.textContent = value ?? ''; return node.innerHTML; };
    const permissions = { trace: app.dataset.canTrace === '1', edit: app.dataset.canEdit === '1' };
    const colors = { ASIGNADO: '#22a447', PENDIENTE: '#f59e0b', NOVEDAD: '#dc3545', INACTIVO: '#8c98a8' };
    let map, routeLayer, markerLayer, editLayer, temporaryMarker;
    let selection = { districtId: null, districtName: '', routeId: null, routeName: '', fecha: new Date().toISOString().slice(0, 10) };
    let mapData = null, mode = null, tracePoints = [], pendingLocation = null;

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

    function notify(message, error = false) {
        const toast = $('#geoToast');
        if (!toast) return;
        toast.textContent = message;
        toast.classList.toggle('is-error', error);
        toast.classList.add('is-visible');
        clearTimeout(notify.timer);
        notify.timer = setTimeout(() => toast.classList.remove('is-visible'), 4200);
    }

    function pinIcon(state, temporary = false, serviceType = '') {
        const color = temporary ? '#2563EB' : (colors[state] || colors.PENDIENTE);
        const isPedestrian = String(serviceType).toUpperCase().includes('PEDESTRE');
        if (isPedestrian && !temporary) {
            return L.divIcon({
                className: 'geo-pin-host geo-service-pin-host', iconSize: [46, 54], iconAnchor: [23, 52], popupAnchor: [0, -50],
                html: `<span class="geo-service-pin" style="--pin-color:${color}"><img src="/assets/img/pinp.png" alt="" draggable="false"></span>`
            });
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
        routeLayer = L.featureGroup().addTo(map);
        markerLayer = L.featureGroup().addTo(map);
        editLayer = L.featureGroup().addTo(map);
        map.on('click', onMapClick);
        setTimeout(() => map.invalidateSize(), 100);
    }

    function resetMap() {
        cancelEditing(false);
        routeLayer?.clearLayers();
        markerLayer?.clearLayers();
        editLayer?.clearLayers();
        mapData = null;
        $('#visiblePointCount').textContent = '0';
        ['statRegistered', 'statCovered', 'statUnassigned', 'statPersonnel', 'statRoutes'].forEach(id => { const el = $('#' + id); if (el) el.textContent = '0'; });
        const traceButton = $('#btnTrace');
        const locationButton = $('#btnLocation');
        if (traceButton) traceButton.disabled = true;
        if (locationButton) locationButton.disabled = true;
        $('#geoDetail')?.classList.remove('is-open');
    }

    $('#filterDistrict')?.addEventListener('change', async event => {
        const routeSelect = $('#filterRoute');
        resetMap();
        const fechaVal = $('#filterDate')?.value || new Date().toISOString().slice(0, 10);
        selection = { districtId: event.target.value ? Number(event.target.value) : null,
            districtName: event.target.selectedOptions[0]?.textContent || '', routeId: null, routeName: '', fecha: fechaVal };
        routeSelect.innerHTML = '<option value="">Seleccione una ruta</option>';
        routeSelect.disabled = true;
        if (!selection.districtId) return;
        try {
            const routes = await api(`distritos/${selection.districtId}/rutas`) || [];
            routeSelect.add(new Option('Todas las Rutas', 'all'), 0);
            routes.forEach(route => routeSelect.add(new Option(route.nombre, route.id)));
            routeSelect.disabled = false;
            routeSelect.value = 'all';
            routeSelect.dispatchEvent(new Event('change'));
        } catch (error) { notify(error.message, true); }
    });

    $('#filterRoute')?.addEventListener('change', async event => {
        resetMap();
        const val = event.target.value;
        selection.routeId = val === 'all' ? null : (val ? Number(val) : null);
        selection.routeName = val === 'all' ? 'Todas las Rutas' : (event.target.selectedOptions[0]?.textContent || '');
        selection.showAll = val === 'all';
        if (!selection.districtId) return;
        if (selection.showAll) {
            await loadAllRoutesMap();
        } else if (selection.routeId) {
            await loadRouteMap();
        }
    });

    $('#filterDate')?.addEventListener('change', async () => {
        const fechaVal = $('#filterDate')?.value || new Date().toISOString().slice(0, 10);
        selection.fecha = fechaVal;
        if (!selection.districtId) return;
        resetMap();
        if (selection.showAll) {
            await loadAllRoutesMap();
        } else if (selection.routeId) {
            await loadRouteMap();
        }
    });

    async function loadAllRoutesMap() {
        try {
            mapData = await api(`distribucion-geografica/distrito/${selection.districtId}/mapa-todas?fecha=${encodeURIComponent(selection.fecha || '')}`);
            renderAllRoutesMap();
        } catch (error) {
            resetMap();
            notify(error.message, true);
        }
    }

    async function loadRouteMap() {
        try {
            mapData = await api(`distribucion-geografica/rutas/${selection.routeId}/mapa?distrito_id=${selection.districtId}&fecha=${encodeURIComponent(selection.fecha || '')}`);
            renderRouteMap();
        } catch (error) {
            resetMap();
            notify(error.message, true);
        }
    }

    function renderAllRoutesMap() {
        routeLayer.clearLayers();
        markerLayer.clearLayers();
        editLayer.clearLayers();
        const trazados = mapData?.trazados || [];
        const places = mapData?.lugares || [];
        const rutas = mapData?.rutas || [];
        trazados.forEach(item => {
            const trace = item.trace;
            if (trace?.geojson) {
                try {
                    const geojson = typeof trace.geojson === 'string' ? JSON.parse(trace.geojson) : trace.geojson;
                    L.geoJSON(geojson, { style: { color: trace.color || '#2563EB', weight: Number(trace.grosor || 6), opacity: Number(trace.opacidad || .55) } }).addTo(routeLayer);
                } catch (_) {}
            }
        });
        places.filter(place => place.latitud != null && place.longitud != null).forEach(addPlaceMarker);
        $('#visiblePointCount').textContent = String(markerLayer.getLayers().length);
        $('#statRegistered').textContent = String(places.length);
        $('#statCovered').textContent = String(places.filter(p => p.agente_id).length);
        $('#statUnassigned').textContent = String(places.filter(p => !p.agente_id).length);
        $('#statPersonnel').textContent = String(new Set(places.filter(p => p.agente_id).map(p => p.agente_id)).size);
        $('#statRoutes').textContent = String(rutas.length);
        const bounds = L.featureGroup([routeLayer, markerLayer]).getBounds();
        if (bounds.isValid()) map.fitBounds(bounds, { padding: [42, 42], maxZoom: 17 });
    }

    function renderRouteMap() {
        routeLayer.clearLayers();
        markerLayer.clearLayers();
        editLayer.clearLayers();
        const route = mapData?.ruta;
        const places = mapData?.lugares || [];
        if (!route) return;
        selection.routeName = route.nombre;
        const traceButton = $('#btnTrace');
        const locationButton = $('#btnLocation');
        if (traceButton) { traceButton.disabled = !permissions.trace; traceButton.textContent = route.tiene_trazado ? '⌁ Redibujar trazado' : '⌁ Asignar trazado'; }
        if (locationButton) locationButton.disabled = !permissions.edit;
        const trace = route.trazado;
        if (trace?.geojson) {
            try {
                const geojson = typeof trace.geojson === 'string' ? JSON.parse(trace.geojson) : trace.geojson;
                L.geoJSON(geojson, { style: { color: trace.color || '#2563EB', weight: Number(trace.grosor || 6), opacity: Number(trace.opacidad || .55) } }).addTo(routeLayer);
            } catch (_) { notify('El trazado guardado no contiene GeoJSON válido.', true); }
        }
        places.filter(place => place.latitud != null && place.longitud != null).forEach(addPlaceMarker);
        $('#visiblePointCount').textContent = String(markerLayer.getLayers().length);
        $('#statRegistered').textContent = String(places.length);
        $('#statCovered').textContent = String(places.filter(p => p.agente_id).length);
        $('#statUnassigned').textContent = String(places.filter(p => !p.agente_id).length);
        $('#statPersonnel').textContent = String(new Set(places.filter(p => p.agente_id).map(p => p.agente_id)).size);
        $('#statRoutes').textContent = '1';
        const bounds = L.featureGroup([routeLayer, markerLayer]).getBounds();
        if (bounds.isValid()) map.fitBounds(bounds, { padding: [42, 42], maxZoom: 17 });
    }

    function addPlaceMarker(place) {
        const state = String(place.estado_operativo || '').toUpperCase() === 'NOVEDAD' ? 'NOVEDAD' : place.estado_mapa;
        const marker = L.marker([Number(place.latitud), Number(place.longitud)], { icon: pinIcon(state, false, place.tipo_servicio) }).addTo(markerLayer);
        marker.bindTooltip(esc(place.nombre), { direction: 'top', offset: [0, -30] });
        marker.bindPopup(placePopup(place), { maxWidth: 320 });
        marker.on('click', () => showPlaceDetail(place));
    }

    function placePopup(place) {
        const assigned = Boolean(place.agente_id);
        return `<div class="geo-popup"><h3>${esc(place.nombre)}</h3>
            <dl><dt>Agente asignado</dt><dd>${assigned ? esc(place.agente) : 'Sin asignar'}</dd>
            <dt>Grado / rango</dt><dd>${assigned ? esc(place.grado || '—') : '—'}</dd>
            <dt>Horario</dt><dd>${assigned ? `${time(place.hora_inicio)} - ${time(place.hora_fin)}` : 'Pendiente'}</dd>
            <dt>Tipo de servicio</dt><dd>${esc(place.tipo_servicio || '—')}</dd></dl>
            <span class="geo-popup-state ${assigned ? 'is-assigned' : ''}">${assigned ? 'Asignado' : 'Pendiente'}</span></div>`;
    }

    function showPlaceDetail(place) {
        const detail = $('#geoDetail');
        if (!detail) return;
        const routeLabel = place.route_name || selection.routeName || '';
        detail.innerHTML = `<header><h2>Información del lugar</h2><button type="button" id="closeDetail" aria-label="Cerrar">×</button></header>
            <div class="geo-point-head"><div class="geo-point-avatar">⌖</div><div><span class="geo-status">${place.agente_id ? 'Asignado' : 'Pendiente'}</span><h3>${esc(place.nombre)}</h3><small>${esc(place.direccion_referencial || '')}</small></div></div>
            <div class="geo-detail-list"><dl><dt>Ruta</dt><dd>${esc(routeLabel)}</dd><dt>Coordenadas</dt><dd>${place.latitud}, ${place.longitud}</dd>
            <dt>Agente</dt><dd>${esc(place.agente || 'Sin asignar')}</dd><dt>Grado</dt><dd>${esc(place.grado || '—')}</dd>
            <dt>Horario</dt><dd>${place.agente_id ? `${time(place.hora_inicio)} - ${time(place.hora_fin)}` : 'Pendiente'}</dd><dt>Tipo de servicio</dt><dd>${esc(place.tipo_servicio || '—')}</dd></dl></div>`;
        detail.classList.add('is-open');
        $('#closeDetail')?.addEventListener('click', () => detail.classList.remove('is-open'));
    }

    function time(value) { return value ? String(value).slice(0, 5) : '—'; }

    $('#btnTrace')?.addEventListener('click', () => {
        if (!selection.routeId) return notify('Seleccione un distrito y una ruta.', true);
        cancelEditing(false);
        mode = 'trace';
        tracePoints = [];
        editLayer.clearLayers();
        routeLayer.clearLayers();
        const savedTrace = mapData?.ruta?.trazado;
        $('#traceType').value = savedTrace?.tipo_geometria === 'area' ? 'area' : 'lineal';
        $('#traceColor').value = /^#[0-9a-f]{6}$/i.test(savedTrace?.color || '') ? savedTrace.color : '#2563EB';
        $('#traceWidth').value = String(Number(savedTrace?.grosor || 6));
        updateTraceOptions();
        map.getContainer().classList.add('is-drawing');
        $('#traceTools').hidden = false;
        $('#traceOptions').hidden = false;
        notify('Haga clic en el mapa para definir el recorrido de la ruta.');
    });

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
        if (!window.confirm(`¿Desea asignar este trazado a ${selection.routeName}?`)) return;
        try {
            const coordinates = tracePoints.map(point => [point[1], point[0]]);
            const geojson = traceType === 'area'
                ? { type: 'Polygon', coordinates: [[...coordinates, coordinates[0]]] }
                : { type: 'LineString', coordinates };
            await api(`distribucion-geografica/rutas/${selection.routeId}/trazado`, { method: 'PUT', body: {
                distrito_id: selection.districtId,
                tipo_geometria: traceType, geojson,
                color: $('#traceColor').value, grosor: Number($('#traceWidth').value), opacidad: .55
            }});
            cancelEditing(false);
            notify('Trazado guardado correctamente.');
            await loadRouteMap();
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
        if (restore && mapData) renderRouteMap();
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
        if (restore && mapData) renderRouteMap();
    }

    $('#centerGeoMap')?.addEventListener('click', () => {
        const bounds = L.featureGroup([routeLayer, markerLayer]).getBounds();
        if (bounds.isValid()) map.fitBounds(bounds, { padding: [35, 35], maxZoom: 17 });
        else map.setView([-2.1894, -79.8891], 14);
    });
    $('#fullscreenGeoMap')?.addEventListener('click', () => {
        $('.geo-map-wrap')?.classList.toggle('is-fullscreen');
        setTimeout(() => map.invalidateSize(), 220);
    });
    $('#geoFilterToggle')?.addEventListener('click', () => $('#geoFilters')?.classList.toggle('is-open'));

    initializeMap();
})();
