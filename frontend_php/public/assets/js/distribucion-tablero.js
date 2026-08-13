(function () {
    'use strict';
    const app = document.querySelector('.td-app');
    if (!app) return;
    const $ = (selector, root = document) => root.querySelector(selector);
    const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));
    const catalogs = JSON.parse($('#tdCatalogs')?.textContent || '{}');
    const canAssign = app.dataset.canAssign === '1';
    const canDelete = app.dataset.canDelete === '1';
    const canForce = app.dataset.canForce === '1';

    const state = {
        districtId: 0, circuitId: 0, shiftId: 0, board: null, routeId: 0,
        places: new Map(), assignments: [], districtManager: null, circuitManagers: new Map(), routeManagers: new Map(), agentTarget: null, availability: null,
        saved: null, editingId: 0,
        circuitDraft: null, promptedDistrictKey: '',
        agentModal: { page: 1, filters: {}, search: '', data: null },
    };

    async function api(resource, options = {}) {
        const response = await fetch(`/distribucion-tablero/api?resource=${encodeURIComponent(resource)}`, {
            method: options.method || 'GET',
            headers: options.body ? {'Content-Type': 'application/json'} : {},
            body: options.body ? JSON.stringify(options.body) : undefined,
        });
        const payload = await response.json().catch(() => ({ok: false, mensaje: 'Respuesta invalida del servidor.'}));
        if (!response.ok || payload.ok !== true) throw new Error(payload.mensaje || payload.detail || 'No fue posible completar la operacion.');
        return payload.datos;
    }

    function esc(value) { const node = document.createElement('div'); node.textContent = value ?? ''; return node.innerHTML; }
    function notify(message, error = false) {
        const toast = $('#tdToast'); toast.textContent = message; toast.classList.toggle('is-error', error); toast.classList.add('is-visible');
        clearTimeout(notify.timer); notify.timer = setTimeout(() => toast.classList.remove('is-visible'), 4300);
    }
    function loading(button, active) {
        if (!button) return; button.disabled = active;
        if (active) { button.dataset.label = button.innerHTML; button.innerHTML = '<span class="td-loading"></span> Procesando...'; }
        else if (button.dataset.label) button.innerHTML = button.dataset.label;
    }
    function openModal(id) { const modal = document.getElementById(id); if (modal) modal.hidden = false; }
    function closeModal(id) { const modal = document.getElementById(id); if (modal) modal.hidden = true; }
    function selectedDate() { return $('#tdBoardDate')?.value || ''; }
    function draftKey() { return `sigo-distribucion-draft:${state.districtId}:${state.shiftId}:${selectedDate()}`; }
    function saveDraft() {
        if (!state.districtId || !state.shiftId) return;
        sessionStorage.setItem(draftKey(), JSON.stringify({assignments: state.assignments, districtManager: state.districtManager, circuitManagers:Array.from(state.circuitManagers.entries()), routeManagers: Array.from(state.routeManagers.entries()), updatedAt: new Date().toISOString()}));
    }
    function restoreDraft() {
        try {
            const draft = JSON.parse(sessionStorage.getItem(draftKey()) || '{}');
            state.assignments = draft.assignments || []; state.districtManager = draft.districtManager || null;
            state.circuitManagers = new Map(draft.circuitManagers || []);
            state.routeManagers = new Map(draft.routeManagers || []);
        } catch (_) { state.assignments = []; state.districtManager = null; state.circuitManagers = new Map(); state.routeManagers = new Map(); }
    }
    function usedAgentIds(exceptAgentId = 0) {
        const ids = state.assignments.map(item => Number(item.agente_id));
        if (state.districtManager?.agente_id) ids.push(Number(state.districtManager.agente_id));
        for (const item of state.circuitManagers.values()) {
            if (item?.agente_id && !item.usar_encargado_distrito) ids.push(Number(item.agente_id));
            if (item?.auxiliar_1_id) ids.push(Number(item.auxiliar_1_id));
            if (item?.auxiliar_2_id) ids.push(Number(item.auxiliar_2_id));
        }
        for (const item of state.routeManagers.values()) if (item?.agente_id) ids.push(Number(item.agente_id));
        return ids.filter(id => id !== Number(exceptAgentId));
    }
    function assignmentsFor(placeId) { return state.assignments.filter(item => Number(item.lugar_id) === Number(placeId)); }
    function initials(name) { return String(name || 'A').split(/\s+/).filter(Boolean).slice(-2).map(part => part[0]).join('').toUpperCase(); }

    const estadoChipColors = {
        'ACTIVO': 'td-chip-green', 'FRANCO': 'td-chip-blue', 'VACACIONES': 'td-chip-orange',
        'PERMISO': 'td-chip-yellow', 'AUSENTE': 'td-chip-red', 'INCAPACIDAD': 'td-chip-red',
        'EN SERVICIO': 'td-chip-blue', 'NO DISPONIBLE': 'td-chip-gray', 'SUSPENDIDO': 'td-chip-red',
        'REPOSO MEDICO': 'td-chip-red', 'COMISION SERVICIO': 'td-chip-purple',
        'OPERATIVO': 'td-chip-green', 'SIN ESTADO': 'td-chip-gray',
    };
    function estadoChipClass(estado) { return estadoChipColors[String(estado).toUpperCase()] || 'td-chip-gray'; }

    async function loadCircuitsForDistrict(){
        const districtId=Number($('#tdDistrict').value||0); const select=$('#tdCircuit');
        state.circuitId=0;select.disabled=true;select.innerHTML='<option value="">Cargando circuitos...</option>';
        if(!districtId){select.innerHTML='<option value="">Seleccione distrito</option>';return;}
        try{
            const circuits=await api(`distritos/${districtId}/circuitos`)||[];
            select.innerHTML='<option value="">Todos los circuitos</option>'+circuits.map(item=>`<option value="${item.id}">${esc(item.nombre)}</option>`).join('');select.disabled=false;
        }catch(error){select.innerHTML='<option value="">Sin circuitos disponibles</option>';notify(error.message,true);}
    }

    async function applyCircuitFilter(){
        state.circuitId=Number($('#tdCircuit').value||0);state.routeId=0;renderRoutes();renderCircuitManagers();
        const first=visibleRoutes().find(route=>Number(route.lugares||0)>0)||visibleRoutes()[0];
        if(first)await selectRoute(Number(first.id));else showEmpty('No existen rutas para el circuito y turno seleccionados.');
    }

    async function loadBoard() {
        state.districtId = Number($('#tdDistrict').value || 0);
        state.circuitId = Number($('#tdCircuit').value || 0);
        state.shiftId = Number($('#tdShift').value || 0);
        if (!state.districtId || !state.shiftId) {
            state.board = null; state.routeId = 0; state.assignments = []; state.places.clear();
            $('#tdRouteList').innerHTML = '<div class="td-empty-small">Seleccione distrito y turno.</div>';
            showEmpty(); return;
        }
        try {
            state.board = await api(`distribucion-tablero/tablero?distrito_id=${state.districtId}&turno_id=${state.shiftId}&fecha=${selectedDate()}`);
            state.places.clear(); state.assignments = []; state.districtManager = null; state.circuitManagers = new Map(); state.routeManagers = new Map(); state.saved = null; state.editingId = 0;
            if (state.board.distribucion_id) {
                state.saved = await api(`distribucion-tablero/distribuciones/${state.board.distribucion_id}`);
                state.editingId = Number(state.saved.id);
                const routeManagerDetails = (state.saved.detalles || []).filter(item => String(item.lugar || '').trim().toUpperCase() === 'ENCARGADO DE RUTA');
                state.assignments = (state.saved.detalles || []).filter(item => item.agente_id && String(item.lugar || '').trim().toUpperCase() !== 'ENCARGADO DE RUTA').map(item => ({lugar_id:Number(item.lugar_id),agente_id:Number(item.agente_id),tipo_asignacion:item.tipo_asignacion || 'MANUAL',agente:{id:Number(item.agente_id),nombre_completo:item.agente,cedula:item.cedula}}));
                for (const item of state.saved.encargados || []) {
                    const manager = item.agente_id ? {agente_id:Number(item.agente_id),tipo_asignacion:item.tipo_asignacion || 'MANUAL',agente:{id:Number(item.agente_id),nombre_completo:item.agente,cedula:item.cedula}} : null;
                    if (item.tipo_responsabilidad === 'ENCARGADO_DISTRITO') state.districtManager = manager;
                    else if (item.tipo_responsabilidad === 'ENCARGADO_CIRCUITO') state.circuitManagers.set(Number(item.circuito_id), {
                        usar_encargado_distrito:Boolean(item.usar_encargado_distrito),...(manager || {}),movil_id:item.movil_id?Number(item.movil_id):null,
                        numero_movil:item.numero_movil,placa:item.placa,
                        auxiliar_1_id:item.auxiliar_1_id?Number(item.auxiliar_1_id):null,auxiliar_1:item.auxiliar_1?{id:Number(item.auxiliar_1_id),nombre_completo:item.auxiliar_1,cedula:item.auxiliar_1_cedula}:null,
                        auxiliar_2_id:item.auxiliar_2_id?Number(item.auxiliar_2_id):null,auxiliar_2:item.auxiliar_2?{id:Number(item.auxiliar_2_id),nombre_completo:item.auxiliar_2,cedula:item.auxiliar_2_cedula}:null
                    });
                    else state.routeManagers.set(Number(item.ruta_id), {requiere_encargado:Boolean(item.requiere_encargado),...(manager || {})});
                }
                // Convierte asignaciones antiguas del registro tecnico en la responsabilidad superior.
                for (const item of routeManagerDetails) {
                    const routeId = Number(item.ruta_id);
                    if (!item.agente_id || state.routeManagers.get(routeId)?.agente_id) continue;
                    state.routeManagers.set(routeId, {requiere_encargado:true,agente_id:Number(item.agente_id),tipo_asignacion:item.tipo_asignacion || 'MANUAL',agente:{id:Number(item.agente_id),nombre_completo:item.agente,cedula:item.cedula}});
                }
            } else restoreDraft();
            for (const route of state.board.rutas || []) if (route.asignar_encargado && !state.routeManagers.has(Number(route.id))) state.routeManagers.set(Number(route.id), {requiere_encargado:false});
            renderRoutes();
            populateOperationalCatalogs();
            const first = visibleRoutes().find(route => Number(route.lugares || 0) > 0) || visibleRoutes()[0];
            if (first) await selectRoute(Number(first.id)); else showEmpty('No existen rutas para la seleccion actual.');
            await refreshAvailability();
            const promptKey=`${state.districtId}:${state.shiftId}:${selectedDate()}`;
            if (canAssign && !state.districtManager?.agente_id && state.promptedDistrictKey!==promptKey) {
                state.promptedDistrictKey=promptKey; await openManagerSelector('district');
            }
        } catch (error) { notify(error.message, true); showEmpty(error.message); }
    }

    function showEmpty(message = 'Elija un distrito, turno y una ruta para comenzar la distribucion.') {
        $('#tdEmptyBoard').hidden = false; $('#tdRouteWorkspace').hidden = true;
        $('#tdEmptyBoard p').textContent = message;
    }
    function renderRoutes() {
        const query = $('#tdRouteSearch').value.trim().toLowerCase();
        const routes = visibleRoutes().filter(route => String(route.nombre).toLowerCase().includes(query));
        $('#tdRouteList').innerHTML = routes.length ? routes.map(route => `
            <button class="td-route-item ${Number(route.id) === state.routeId ? 'is-active' : ''}" type="button" data-route-id="${route.id}">
                <i class="td-shift-icon">${shiftIcon()}</i><span><b>${esc(route.nombre)}</b><small>${Number(route.lugares || 0)} ${Number(route.lugares || 0) === 1 ? 'lugar' : 'lugares'}</small></span>
            </button>`).join('') : '<div class="td-empty-small">No se encontraron rutas.</div>';
    }
    function visibleRoutes() {
        const routes=state.board?.rutas || [];
        return state.circuitId ? routes.filter(route=>Number(route.circuito_id||0)===state.circuitId) : routes;
    }
    function shiftIcon() {
        const name=String(state.board?.turno?.nombre || $('#tdShift').selectedOptions[0]?.textContent || '').toUpperCase();
        if(name.includes('NOCT')) return '☾';
        if(name.includes('VESPERT')||name.includes('TARDE')) return '🌤';
        return '☀';
    }
    async function ensurePlaces(routeId) {
        if (!state.places.has(routeId)) state.places.set(routeId, await api(`distribucion-tablero/rutas/${routeId}/lugares?turno_id=${state.shiftId}`));
        return state.places.get(routeId);
    }
    async function ensureAllPlaces() {
        await Promise.all((state.board?.rutas || []).map(route => ensurePlaces(Number(route.id))));
    }
    async function selectRoute(routeId) {
        state.routeId = routeId; renderRoutes();
        try { await ensurePlaces(routeId); renderWorkspace(); }
        catch (error) { notify(error.message, true); }
    }

    function routeData() { return (state.board?.rutas || []).find(route => Number(route.id) === state.routeId); }
    function routeStats() {
        const places = state.places.get(state.routeId) || [];
        const required = places.reduce((sum, place) => sum + Number(place.cantidad_requerida || 0), 0);
        const assigned = places.reduce((sum, place) => sum + assignmentsFor(place.id).length, 0);
        return {places: places.length, required, assigned, pending: Math.max(0, required - assigned), coverage: required ? Math.round(assigned / required * 100) : 0};
    }
    function renderWorkspace() {
        const route = routeData(); if (!route) return showEmpty();
        const places = state.places.get(state.routeId) || []; const stats = routeStats();
        $('#tdEmptyBoard').hidden = true; $('#tdRouteWorkspace').hidden = false;
        $('#tdRouteName').textContent = route.nombre;
        $('#tdRoutePlacesBadge').textContent = `${stats.places} ${stats.places === 1 ? 'lugar' : 'lugares'}`;
        $('#tdKpiPlaces').textContent = stats.places; $('#tdKpiRequired').textContent = stats.required;
        $('#tdKpiAssigned').textContent = stats.assigned; $('#tdKpiPending').textContent = stats.pending;
        $('#tdKpiCoverage').textContent = `${stats.coverage}%`; $('#tdCoverageBar').style.width = `${Math.min(100, stats.coverage)}%`;
        $('#tdCoverageLabel').textContent = stats.coverage >= 100 ? 'Ruta completa' : 'Ruta incompleta';
        renderManagers();
        $('#tdPlacesBody').innerHTML = places.length ? places.map((place, index) => renderPlaceRow(place, index)).join('') : '<tr><td colspan="6"><div class="td-empty-small">Esta ruta no tiene lugares de servicio activos.</div></td></tr>';
    }
    function managerLabel(item, fallback) {
        return item?.agente?.nombre_completo ? `${item.agente.nombre_completo}${item.agente.cedula ? ` · ${item.agente.cedula}` : ''}` : fallback;
    }
    function populateOperationalCatalogs() {
        const circuits=state.board?.circuitos || [];
        const options='<option value="">Todos los circuitos</option>'+circuits.map(item=>`<option value="${item.id}">${esc(item.nombre)}</option>`).join('');
        const filter=$('#tdCircuit');
        if(filter){const current=state.circuitId;filter.innerHTML=options;filter.disabled=false;filter.value=current&&circuits.some(c=>Number(c.id)===current)?String(current):'';state.circuitId=Number(filter.value||0);}
        const circuitOptions='<option value="">Seleccione circuito</option>'+circuits.map(item=>`<option value="${item.id}">${esc(item.nombre)}</option>`).join('');
        if($('#tdDistrictManagerCircuit')) $('#tdDistrictManagerCircuit').innerHTML=circuitOptions;
        if($('#tdCircuitManagerCircuit')) $('#tdCircuitManagerCircuit').innerHTML=circuitOptions;
        if($('#tdCircuitMobile')) $('#tdCircuitMobile').innerHTML='<option value="">Sin móvil</option>'+(state.board?.moviles||[]).map(item=>`<option value="${item.id}">${esc(item.numero_movil)}${item.placa?` · ${esc(item.placa)}`:''}</option>`).join('');
    }
    function renderManagers() {
        const districtEnabled = Boolean(state.board?.distrito?.asignar_encargado);
        $('#tdDistrictManagerCard').hidden = !districtEnabled;
        if (districtEnabled) {
            $('#tdDistrictManagerValue').textContent = managerLabel(state.districtManager, 'Sin asignar');
            if ($('#tdAssignDistrictManager')) $('#tdAssignDistrictManager').textContent = state.districtManager ? 'Cambiar encargado' : 'Asignar encargado de distrito';
            if ($('#tdRemoveDistrictManager')) $('#tdRemoveDistrictManager').hidden = !state.districtManager;
            const shared=Array.from(state.circuitManagers.entries()).find(([,item])=>item.usar_encargado_distrito);
            if($('#tdDistrictAsCircuitManager')) $('#tdDistrictAsCircuitManager').checked=Boolean(shared);
            if($('#tdDistrictManagerCircuit')) $('#tdDistrictManagerCircuit').value=shared?String(shared[0]):'';
        }
        renderCircuitManagers();
        const route = routeData(); const routeEnabled = Boolean(route?.asignar_encargado);
        $('#tdRouteManagerCard').hidden = !routeEnabled;
        if (routeEnabled) {
            const item = state.routeManagers.get(Number(route.id)) || {requiere_encargado:false};
            if ($('#tdRouteManagerRequired')) $('#tdRouteManagerRequired').checked = Boolean(item.requiere_encargado);
            if ($('#tdAssignRouteManager')) { $('#tdAssignRouteManager').hidden = !item.requiere_encargado; $('#tdAssignRouteManager').textContent = item.agente_id ? 'Cambiar encargado' : 'Seleccionar agente'; }
            $('#tdRouteManagerValue').textContent = item.requiere_encargado
                ? managerLabel(item, 'Debe seleccionar un encargado de ruta')
                : 'Sin encargado de ruta · Responsable: Encargado del Distrito';
        }
    }
    function circuitName(circuitId){return (state.board?.circuitos||[]).find(item=>Number(item.id)===Number(circuitId))?.nombre || `Circuito ${circuitId}`;}
    function renderCircuitManagers(){
        const list=$('#tdCircuitManagersList'); if(!list)return;
        const items=Array.from(state.circuitManagers.entries()).filter(([id])=>!state.circuitId||Number(id)===state.circuitId);
        list.innerHTML=items.length?items.map(([circuitId,item])=>`<article class="td-circuit-manager-item"><div><b>${esc(circuitName(circuitId))}</b><strong>${esc(item.agente?.nombre_completo||'Sin encargado')}</strong><small>${item.usar_encargado_distrito?'También encargado del distrito':'Encargado propio'} · Móvil: ${esc(item.numero_movil||'Sin móvil')}</small><small>Auxiliares: ${esc(item.auxiliar_1?.nombre_completo||'—')} / ${esc(item.auxiliar_2?.nombre_completo||'—')}</small></div>${canAssign?`<div><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-edit-circuit-manager="${circuitId}">Editar</button><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-remove-circuit-manager="${circuitId}">Quitar</button></div>`:''}</article>`).join(''):'<p class="td-empty-small">No existen encargados de circuito asignados.</p>';
    }
    function renderPlaceRow(place, index) {
        const assigned = assignmentsFor(place.id); const required = Number(place.cantidad_requerida || 0); const covered = assigned.length >= required && required > 0;
        const agents = assigned.length ? assigned.map(item => {
            const isForced = item.tipo_asignacion === 'FORZADA';
            const forcedBadge = isForced ? '<span class="td-forced-badge" title="Este agente fue asignado manualmente a pesar de encontrarse en estado no disponible.">&#9888; Forzada</span>' : '';
            return `<div class="td-agent"><span class="td-avatar">${esc(initials(item.agente?.nombre_completo))}</span><div><b>${esc(item.agente?.nombre_completo || `Agente ${item.agente_id}`)}</b><small>${esc(item.agente?.cedula || '')}</small>${forcedBadge}${isForced ? `<small class="td-forced-original">Estado original: ${esc(item.estado_original || '')}</small>` : ''}</div></div>`;
        }).join('') : '<div class="td-empty-agent"><span class="td-avatar">&#9823;</span><div><b>Sin asignar</b><small>Seleccione un agente</small></div></div>';
        const actions = canAssign ? `${assigned.map(item => `<button type="button" data-change-agent="${item.agente_id}" data-place-id="${place.id}">Cambiar</button><button class="td-remove" type="button" data-remove-agent="${item.agente_id}" data-place-id="${place.id}">Quitar</button>`).join('')}${assigned.length < required ? `<button type="button" data-assign-place="${place.id}">&#9823; Asignar</button>` : ''}` : '&mdash;';
        return `<tr><td><span class="td-row-number">${index + 1}</span></td><td><div class="td-place-cell"><i>&#9214;</i><div><b>${esc(place.nombre)}</b><small>${esc(place.referencia)}</small></div></div></td><td class="td-required"><b>${required}</b>${required === 1 ? 'Agente' : 'Agentes'}</td><td>${agents}</td><td><span class="td-status ${covered ? 'td-status-assigned' : 'td-status-pending'}">${covered ? 'Asignado' : 'Pendiente'}</span></td><td><div class="td-actions">${actions}</div></td></tr>`;
    }

    async function refreshAvailability() {
        if (!state.districtId || !state.shiftId) return;
        try {
            state.availability = await api(`distribucion-tablero/disponibilidad?distrito_id=${state.districtId}&turno_id=${state.shiftId}&excluidos=${usedAgentIds().join(',')}`);
            $('#tdAvailable').textContent = state.availability.disponibles || 0; $('#tdInService').textContent = state.availability.en_servicio || 0;
            $('#tdUnavailable').textContent = state.availability.no_disponibles || 0; $('#tdTotalAgents').textContent = state.availability.total_agentes || 0;
        } catch (error) { notify(error.message, true); }
    }

    let agentSearchTimer = null;
    async function openAgentSelector(placeId, replaceAgentId = 0) {
        const place = (state.places.get(state.routeId) || []).find(item => Number(item.id) === Number(placeId));
        const replaceAgent = replaceAgentId ? state.assignments.find(a => Number(a.agente_id) === Number(replaceAgentId) && Number(a.lugar_id) === Number(placeId)) : null;
        state.agentTarget = {
            kind: 'place', routeId: state.routeId,
            placeId: Number(placeId), replaceAgentId: Number(replaceAgentId),
            placeNombre: place?.nombre || '', rutaNombre: routeData()?.nombre || '',
            turnoNombre: $('#tdShift').selectedOptions[0]?.textContent || '',
            replaceAgentNombre: replaceAgent?.agente?.nombre_completo || '',
        };
        state.agentModal = { page: 1, filters: {}, search: '', data: null };

        $('#tdAgentModalTitle').textContent = replaceAgentId ? 'Cambiar agente asignado' : 'Asignar agente al lugar';
        $('#tdAgentModalSubtitle').textContent = `${place?.nombre || ''} | ${routeData()?.nombre || ''}`;
        $('#tdAgentInfoBar').innerHTML = `
            <div class="td-info-row"><b>Lugar de servicio:</b> ${esc(place?.nombre || '')} | ${esc(routeData()?.nombre || '')}</div>
            ${replaceAgentId ? `<div class="td-info-row"><b>Agente actual:</b> ${esc(replaceAgent?.agente?.nombre_completo || '')}</div>` : ''}
            <div class="td-info-row"><b>Turno:</b> ${esc(state.agentTarget.turnoNombre)}</div>
        `;

        $('#tdAgentSearch').value = '';
        $$('#tdFilterGrupo, #tdFilterTipoServicio, #tdFilterGrado, #tdFilterEstado').forEach(sel => sel.value = '');
        $('#tdAgentTableBody').innerHTML = '<tr><td colspan="8"><div class="td-empty-small">Consultando personal...</div></td></tr>';
        $('#tdAgentPagination').innerHTML = '';
        openModal('tdAgentModal');
        await fetchAgentList();
    }

    async function openManagerSelector(kind, routeId = 0) {
        const current = kind === 'district' ? state.districtManager : state.routeManagers.get(Number(routeId));
        const route = (state.board?.rutas || []).find(item => Number(item.id) === Number(routeId));
        state.agentTarget = {
            kind, routeId:Number(routeId) || null, placeId:null,
            replaceAgentId:Number(current?.agente_id || 0), placeNombre:kind === 'district' ? state.board?.distrito?.nombre : route?.nombre,
            rutaNombre:route?.nombre || '', turnoNombre:$('#tdShift').selectedOptions[0]?.textContent || ''
        };
        state.agentModal = {page:1,filters:{},search:'',data:null};
        const title = kind === 'district' ? 'Encargado de distrito' : 'Encargado de ruta';
        $('#tdAgentModalTitle').textContent = current?.agente_id ? `Cambiar ${title.toLowerCase()}` : `Asignar ${title.toLowerCase()}`;
        $('#tdAgentModalSubtitle').textContent = kind === 'district' ? state.board?.distrito?.nombre || '' : route?.nombre || '';
        $('#tdAgentInfoBar').innerHTML = `<div class="td-info-row"><b>${title}:</b> ${esc(kind === 'district' ? state.board?.distrito?.nombre : route?.nombre)}</div>${current?.agente?.nombre_completo ? `<div class="td-info-row"><b>Agente actual:</b> ${esc(current.agente.nombre_completo)}</div>` : ''}<div class="td-info-row"><b>Turno:</b> ${esc(state.agentTarget.turnoNombre)}</div>`;
        $('#tdAgentSearch').value=''; $$('#tdFilterGrupo, #tdFilterTipoServicio, #tdFilterGrado, #tdFilterEstado').forEach(sel=>sel.value='');
        $('#tdAgentTableBody').innerHTML='<tr><td colspan="8"><div class="td-empty-small">Consultando personal...</div></td></tr>'; $('#tdAgentPagination').innerHTML='';
        openModal('tdAgentModal'); await fetchAgentList();
    }

    function emptyCircuitDraft(circuitId=0){
        return {circuito_id:Number(circuitId||0),usar_encargado_distrito:false,agente_id:null,agente:null,auxiliar_1_id:null,auxiliar_1:null,auxiliar_2_id:null,auxiliar_2:null,movil_id:null};
    }
    function openCircuitEditor(circuitId=0,useDistrictManager=false){
        const selected=Number(circuitId||state.circuitId||0);
        const current=state.circuitManagers.get(selected);
        state.circuitDraft=current?structuredClone({...current,circuito_id:selected,_original_circuito_id:selected}):emptyCircuitDraft(selected);
        if(useDistrictManager&&state.districtManager){state.circuitDraft.usar_encargado_distrito=true;state.circuitDraft.agente_id=Number(state.districtManager.agente_id);state.circuitDraft.agente=state.districtManager.agente;}
        renderCircuitEditor(); openModal('tdCircuitManagerModal');
    }
    function renderCircuitEditor(){
        const draft=state.circuitDraft||emptyCircuitDraft();
        $('#tdCircuitManagerCircuit').value=draft.circuito_id?String(draft.circuito_id):'';
        $('#tdCircuitManagerName').textContent=draft.agente?.nombre_completo||'Sin seleccionar';
        $('#tdCircuitAux1Name').textContent=draft.auxiliar_1?.nombre_completo||'Sin seleccionar';
        $('#tdCircuitAux2Name').textContent=draft.auxiliar_2?.nombre_completo||'Sin seleccionar';
        $('#tdCircuitMobile').value=draft.movil_id?String(draft.movil_id):'';
        const managerButton=$('[data-circuit-role="manager"]'); if(managerButton)managerButton.disabled=Boolean(draft.usar_encargado_distrito);
    }
    async function openCircuitRoleSelector(role){
        const draft=state.circuitDraft; if(!draft?.circuito_id)return notify('Seleccione un circuito.',true);
        const roleConfig={manager:['circuitManager','agente_id','agente','Encargado de circuito'],aux1:['circuitAux1','auxiliar_1_id','auxiliar_1','Auxiliar 1'],aux2:['circuitAux2','auxiliar_2_id','auxiliar_2','Auxiliar 2']}[role];
        if(!roleConfig)return;
        const [kind,idKey,valueKey,title]=roleConfig; const current=draft[valueKey];
        state.agentTarget={kind,circuitRole:role,replaceAgentId:Number(draft[idKey]||0),placeNombre:circuitName(draft.circuito_id),rutaNombre:'',turnoNombre:$('#tdShift').selectedOptions[0]?.textContent||''};
        state.agentModal={page:1,filters:{},search:'',data:null};
        $('#tdAgentModalTitle').textContent=current?`Cambiar ${title.toLowerCase()}`:`Seleccionar ${title.toLowerCase()}`;
        $('#tdAgentModalSubtitle').textContent=circuitName(draft.circuito_id);
        $('#tdAgentInfoBar').innerHTML=`<div class="td-info-row"><b>${title}:</b> ${esc(circuitName(draft.circuito_id))}</div><div class="td-info-row"><b>Turno:</b> ${esc(state.agentTarget.turnoNombre)}</div>`;
        $('#tdAgentSearch').value=''; $$('#tdFilterGrupo, #tdFilterTipoServicio, #tdFilterGrado, #tdFilterEstado').forEach(sel=>sel.value='');
        openModal('tdAgentModal'); await fetchAgentList();
    }

    async function fetchAgentList() {
        if (!state.agentTarget) return;
        const excluded = usedAgentIds(state.agentTarget.replaceAgentId);
        const body = {
            distrito_id: state.districtId, turno_id: state.shiftId,
            tipo_responsabilidad: state.agentTarget.kind === 'district' ? 'ENCARGADO_DISTRITO' : state.agentTarget.kind === 'route' ? 'ENCARGADO_RUTA' : state.agentTarget.kind === 'circuitManager' ? 'ENCARGADO_CIRCUITO' : state.agentTarget.kind.startsWith('circuitAux') ? 'AUXILIAR_CIRCUITO' : 'AGENTE_LUGAR',
            fecha_distribucion: selectedDate(),
            excluidos: excluded,
            page: state.agentModal.page, limit: 20,
        };
        if (state.agentTarget.kind !== 'district' && !state.agentTarget.kind.startsWith('circuit')) body.ruta_id = state.agentTarget.routeId || state.routeId;
        if (state.agentTarget.placeId) body.lugar_id = state.agentTarget.placeId;
        const search = $('#tdAgentSearch').value.trim();
        if (search) body.search = search;
        const grupoId = $('#tdFilterGrupo').value;
        if (grupoId) body.grupo_id = Number(grupoId);
        const tipoId = $('#tdFilterTipoServicio').value;
        if (tipoId) body.tipo_servicio_id = Number(tipoId);
        const gradoId = $('#tdFilterGrado').value;
        if (gradoId) body.grado_id = Number(gradoId);
        const estado = $('#tdFilterEstado').value;
        if (estado) body.estado = estado;

        try {
            const data = await api('distribucion-tablero/agentes-disponibles', {method: 'POST', body});
            state.agentModal.data = data;
            populateFilterOptions(data.catalogos);
            renderAgentTable(data);
        } catch (error) {
            $('#tdAgentTableBody').innerHTML = `<tr><td colspan="8"><div class="td-empty-small">${esc(error.message)}</div></td></tr>`;
        }
    }

    function populateFilterOptions(cats) {
        if (!cats) return;
        const grupoSel = $('#tdFilterGrupo');
        if (grupoSel.options.length <= 1 && cats.grupos?.length) {
            grupoSel.innerHTML = '<option value="">Grupo</option>' + cats.grupos.map(g => `<option value="${g.id}">${esc(g.nombre)}</option>`).join('');
        }
        const tipoSel = $('#tdFilterTipoServicio');
        if (tipoSel.options.length <= 1 && cats.tipos_servicio?.length) {
            tipoSel.innerHTML = '<option value="">Tipo servicio</option>' + cats.tipos_servicio.map(t => `<option value="${t.id}">${esc(t.nombre)}</option>`).join('');
        }
        const gradoSel = $('#tdFilterGrado');
        if (gradoSel.options.length <= 1 && cats.grados?.length) {
            gradoSel.innerHTML = '<option value="">Grado</option>' + cats.grados.map(g => `<option value="${g.id}">${esc(g.nombre)}</option>`).join('');
        }
        const estadoSel = $('#tdFilterEstado');
        if (estadoSel.options.length <= 1 && cats.estados?.length) {
            estadoSel.innerHTML = '<option value="">Estado</option>' + cats.estados.map(e => `<option value="${esc(e.nombre)}">${esc(e.nombre)}</option>`).join('');
        }
    }

    function renderAgentTable(data) {
        const agents = data.agentes || [];
        if (!agents.length) {
            $('#tdAgentTableBody').innerHTML = '<tr><td colspan="8"><div class="td-empty-small">No se encontraron agentes con los filtros seleccionados.</div></td></tr>';
            $('#tdAgentPagination').innerHTML = '';
            return;
        }
        $('#tdAgentTableBody').innerHTML = agents.map(agent => {
            const isAvailable = agent.disponible;
            const chipClass = estadoChipClass(agent.estado_laboral);
            const availLabel = isAvailable ? '<span class="td-avail td-avail-ok">Disponible</span>' : `<span class="td-avail td-avail-no">${esc(agent.motivo_no_disponible || 'No disponible')}</span>`;
            const actionBtn = isAvailable
                ? `<button class="td-btn td-btn-primary td-btn-sm" type="button" data-select-agent="${agent.id}">Seleccionar</button>`
                : canForce
                    ? `<button class="td-btn td-btn-warning td-btn-sm" type="button" data-select-agent="${agent.id}" data-requires-force="1">Forzar</button>`
                    : `<span class="td-avail td-avail-no">No disponible</span>`;
            return `<tr class="${isAvailable ? '' : 'td-row-unavailable'}">
                <td><div class="td-agent-cell"><span class="td-avatar-sm">${esc(initials(agent.nombre_completo))}</span><b>${esc(agent.nombre_completo)}</b></div></td>
                <td>${esc(agent.cedula)}</td>
                <td>${esc(agent.grupo)}</td>
                <td>${esc(agent.tipo_servicio)}</td>
                <td>${esc(agent.grado)}</td>
                <td><span class="td-chip ${chipClass}">${esc(agent.estado_laboral)}</span></td>
                <td>${availLabel}</td>
                <td>${actionBtn}</td>
            </tr>`;
        }).join('');

        const totalPages = data.total_pages || 1;
        const currentPage = data.page || 1;
        let paginationHtml = `<span class="td-pagination-info">Mostrando ${(currentPage-1)*20+1}-${Math.min(currentPage*20, data.total)} de ${data.total}</span><div class="td-pagination-btns">`;
        if (currentPage > 1) paginationHtml += `<button class="td-btn td-btn-ghost td-btn-sm" data-page="${currentPage-1}">&lt;</button>`;
        for (let p = 1; p <= totalPages && p <= 7; p++) {
            paginationHtml += `<button class="td-btn td-btn-sm ${p === currentPage ? 'td-btn-primary' : 'td-btn-ghost'}" data-page="${p}">${p}</button>`;
        }
        if (totalPages > 7) paginationHtml += `<span class="td-pagination-ellipsis">...</span><button class="td-btn td-btn-sm td-btn-ghost" data-page="${totalPages}">${totalPages}</button>`;
        if (currentPage < totalPages) paginationHtml += `<button class="td-btn td-btn-ghost td-btn-sm" data-page="${currentPage+1}">&gt;</button>`;
        paginationHtml += '</div>';
        $('#tdAgentPagination').innerHTML = paginationHtml;
    }

    async function chooseAgent(agentId, requiresForce = false) {
        const target = state.agentTarget; if (!target) return;
        const agent = state.agentModal.data?.agentes?.find(a => Number(a.id) === Number(agentId));
        if (!agent) return;

        if (requiresForce || agent.requiere_forzado) {
            $('#tdForceAgentStatus').textContent = agent.estado_laboral;
            $('#tdForceAgentName').textContent = agent.nombre_completo;
            $('#tdForceAgentEstado').textContent = agent.estado_laboral;
            $('#tdForceLugar').textContent = `${target.placeNombre} | ${target.rutaNombre}`;
            $('#tdForceTurno').textContent = target.turnoNombre;
            $('#tdForceJustificacion').value = '';
            state.agentTarget.pendingForceAgent = agent;
            openModal('tdForceModal');
            return;
        }

        if (usedAgentIds(target.replaceAgentId).includes(Number(agentId))) return notify('El agente ya esta asignado en este borrador.', true);
        applyAgentToTarget(target, agent, 'MANUAL');
        if(target.kind.startsWith('circuit')){closeModal('tdAgentModal');state.agentTarget=null;renderCircuitEditor();return;}
        saveDraft(); closeModal('tdAgentModal'); state.agentTarget = null; renderWorkspace(); refreshAvailability();
    }

    function applyAgentToTarget(target, agent, assignmentType, extra = {}) {
        const value = {agente_id:Number(agent.id),tipo_asignacion:assignmentType,agente:{id:Number(agent.id),nombre_completo:agent.nombre_completo,cedula:agent.cedula,estado_personal:agent.estado_laboral},...extra};
        if (target.kind === 'district') {
            state.districtManager = value;
            for(const [circuitId,item] of state.circuitManagers.entries())if(item.usar_encargado_distrito)state.circuitManagers.set(circuitId,{...item,agente_id:value.agente_id,agente:value.agente});
        }
        else if (target.kind === 'route') state.routeManagers.set(Number(target.routeId), {requiere_encargado:true,...value});
        else if (target.kind.startsWith('circuit')) {
            const mapping={circuitManager:['agente_id','agente'],circuitAux1:['auxiliar_1_id','auxiliar_1'],circuitAux2:['auxiliar_2_id','auxiliar_2']}[target.kind];
            if(mapping&&state.circuitDraft){state.circuitDraft[mapping[0]]=Number(agent.id);state.circuitDraft[mapping[1]]=value.agente;}
        }
        else {
            if (target.replaceAgentId) state.assignments = state.assignments.filter(item => !(Number(item.lugar_id) === Number(target.placeId) && Number(item.agente_id) === Number(target.replaceAgentId)));
            state.assignments.push({lugar_id:Number(target.placeId),...value});
        }
    }

    async function confirmForceAssignment() {
        const target = state.agentTarget; if (!target?.pendingForceAgent) return;
        const agent = target.pendingForceAgent;
        const justificacion = $('#tdForceJustificacion').value.trim();
        if (!justificacion) return notify('Debe especificar el motivo de la asignacion forzada.', true);

        const button = $('#tdConfirmForce');
        loading(button, true);
        try {
            if (target.kind === 'place') await api('distribucion-tablero/cambiar-agente', {method: 'POST', body: {
                distrito_id: state.districtId, turno_id: state.shiftId, ruta_id: state.routeId, lugar_id: target.placeId,
                agente_nuevo_id: agent.id, agente_anterior_id: target.replaceAgentId || null, tipo_responsabilidad:'AGENTE_LUGAR',
                forzado: true, motivo_forzado: justificacion,
            }});
            if (usedAgentIds(target.replaceAgentId).includes(Number(agent.id))) {
                loading(button, false);
                return notify('El agente ya esta asignado en este borrador.', true);
            }
            applyAgentToTarget(target, agent, 'FORZADA', {estado_original:agent.estado_laboral,motivo_forzado:justificacion});
            saveDraft(); closeModal('tdForceModal'); closeModal('tdAgentModal');
            if(target.kind.startsWith('circuit')){state.agentTarget=null;renderCircuitEditor();notify('Responsable seleccionado.');return;}
            state.agentTarget = null; renderWorkspace(); refreshAvailability();
            notify('Asignacion forzada registrada correctamente.');
        } catch (error) { notify(error.message, true); }
        finally { loading(button, false); }
    }

    function removeAgent(placeId, agentId) {
        state.assignments = state.assignments.filter(item => !(Number(item.lugar_id) === Number(placeId) && Number(item.agente_id) === Number(agentId)));
        saveDraft(); renderWorkspace(); refreshAvailability();
    }

    async function randomAssign() {
        if (!state.circuitId) return notify('Seleccione un circuito para realizar la asignación aleatoria.', true);
        if (state.board?.distrito?.asignar_encargado && !state.districtManager?.agente_id) return notify('Primero seleccione el encargado del distrito.', true);
        const circuitManager = state.circuitManagers.get(Number(state.circuitId));
        if (!circuitManager?.agente_id) return notify(`Primero seleccione el encargado de ${circuitName(state.circuitId)}.`, true);
        const circuitRoutes = (state.board?.rutas || []).filter(route => Number(route.circuito_id) === Number(state.circuitId));
        for (const route of circuitRoutes) {
            if (!route.asignar_encargado) continue;
            const manager = state.routeManagers.get(Number(route.id));
            if (!manager || (manager.requiere_encargado && !manager.agente_id)) return notify(`Primero defina el encargado de la ruta ${route.nombre}.`, true);
        }
        const button = $('#tdRandomAssign'); loading(button, true);
        try {
            const result = await api('distribucion-tablero/asignacion-aleatoria', {method: 'POST', body: {distrito_id: state.districtId, turno_id: state.shiftId, circuito_id: state.circuitId, excluidos:usedAgentIds(), asignaciones: state.assignments.map(({lugar_id, agente_id, tipo_asignacion}) => ({lugar_id, agente_id, tipo_asignacion}))}});
            for (const assignment of result.asignaciones || []) state.assignments.push(assignment);
            saveDraft(); renderWorkspace(); await refreshAvailability();
            notify(result.insuficiente ? result.mensaje : 'Circuito asignado aleatoriamente sin repetir agentes.', Boolean(result.insuficiente));
        } catch (error) { notify(error.message, true); }
        finally { loading(button, false); }
    }

    function saveCircuitManagerDraft(){
        const draft=state.circuitDraft; const circuitId=Number($('#tdCircuitManagerCircuit').value||0);
        if(!draft||!circuitId)return notify('Seleccione un circuito.',true);
        if(!draft.agente_id)return notify('Seleccione el encargado del circuito.',true);
        const people=[draft.agente_id,draft.auxiliar_1_id,draft.auxiliar_2_id].filter(Boolean).map(Number);
        if(new Set(people).size!==people.length)return notify('No puede repetir una persona como encargado y auxiliar.',true);
        draft.circuito_id=circuitId;draft.movil_id=Number($('#tdCircuitMobile').value||0)||null;
        const mobile=(state.board?.moviles||[]).find(item=>Number(item.id)===Number(draft.movil_id));draft.numero_movil=mobile?.numero_movil||null;draft.placa=mobile?.placa||null;
        if(draft._original_circuito_id&&Number(draft._original_circuito_id)!==circuitId)state.circuitManagers.delete(Number(draft._original_circuito_id));
        const {_original_circuito_id,...persisted}=draft;state.circuitManagers.set(circuitId,{...persisted});state.circuitDraft=null;saveDraft();closeModal('tdCircuitManagerModal');renderManagers();refreshAvailability();
    }
    function syncDistrictCircuitAssignment(){
        const checked=$('#tdDistrictAsCircuitManager').checked; const circuitId=Number($('#tdDistrictManagerCircuit').value||0);
        for(const [id,item] of state.circuitManagers.entries())if(item.usar_encargado_distrito&&(!checked||Number(id)!==circuitId))state.circuitManagers.delete(id);
        if(!checked){saveDraft();renderManagers();return;}
        if(!state.districtManager?.agente_id){$('#tdDistrictAsCircuitManager').checked=false;notify('Primero seleccione el encargado del distrito.',true);openManagerSelector('district');return;}
        if(!circuitId)return notify('Seleccione el circuito que también tendrá a cargo.',true);
        const current=state.circuitManagers.get(circuitId)||emptyCircuitDraft(circuitId);
        state.circuitManagers.set(circuitId,{...current,usar_encargado_distrito:true,agente_id:Number(state.districtManager.agente_id),agente:state.districtManager.agente});
        saveDraft();renderManagers();
    }

    function formatDate(value) { if (!value) return 'DD/MM/AAAA'; const [year, month, day] = value.split('-'); return `${day}/${month}/${year}`; }
    async function draftTotals() {
        await ensureAllPlaces(); let required = 0;
        for (const places of state.places.values()) for (const place of places) required += Number(place.cantidad_requerida || 0);
        return {required, assigned: state.assignments.length, pending: Math.max(0, required - state.assignments.length)};
    }
    async function openSave() {
        if (!state.districtId || !state.shiftId) return notify('Seleccione distrito y turno.', true);
        try { const totals = await draftTotals(); if (!totals.required) return notify('No existen lugares para guardar.', true); }
        catch (error) { return notify(error.message, true); }
        if (state.board?.distrito?.asignar_encargado && !state.districtManager?.agente_id) return notify('Debe asignar el encargado de distrito.', true);
        for(const [circuitId,item] of state.circuitManagers.entries()){
            if(!item.agente_id)return notify(`Seleccione el encargado de ${circuitName(circuitId)}.`,true);
            const people=[item.agente_id,item.auxiliar_1_id,item.auxiliar_2_id].filter(Boolean).map(Number);
            if(new Set(people).size!==people.length)return notify(`Revise las personas asignadas en ${circuitName(circuitId)}.`,true);
        }
        for (const route of state.board?.rutas || []) {
            if (!route.asignar_encargado) continue;
            const manager = state.routeManagers.get(Number(route.id));
            if (!manager) return notify(`Defina la responsabilidad de la ruta ${route.nombre}.`, true);
            if (manager.requiere_encargado && !manager.agente_id) return notify(`Seleccione el encargado de la ruta ${route.nombre}.`, true);
            if (!manager.requiere_encargado && !state.districtManager?.agente_id) return notify(`La ruta ${route.nombre} necesita encargado porque no existe un encargado de distrito responsable.`, true);
        }
        const editingDate = selectedDate();
        $('#tdDistributionDate').value = editingDate;
        $('#tdGeneratedName').textContent = `DISTRIBUCION DE PERSONAL FECHA ${formatDate(editingDate)}`;
        openModal('tdSaveModal');
    }
    async function requestSave() {
        const date = selectedDate(); if (!date) return notify('Seleccione la fecha de distribucion.', true);
        const button = $('#tdConfirmSave'); loading(button, true);
        try {
            const resource = state.editingId ? `distribucion-tablero/distribuciones/${state.editingId}` : 'distribucion-tablero/distribuciones';
            const saved = await api(resource, {method: state.editingId ? 'PUT' : 'POST', body: {
                distrito_id:state.districtId,turno_id:state.shiftId,fecha_distribucion:date,guardar_con_pendientes:true,
                encargado_distrito_id:state.districtManager?.agente_id || null,
                encargados_circuito:Array.from(state.circuitManagers.entries()).map(([circuito_id,item])=>({circuito_id:Number(circuito_id),usar_encargado_distrito:Boolean(item.usar_encargado_distrito),agente_id:Number(item.agente_id),auxiliar_1_id:item.auxiliar_1_id||null,auxiliar_2_id:item.auxiliar_2_id||null,movil_id:item.movil_id||null,tipo_asignacion:item.tipo_asignacion||'MANUAL'})),
                encargados_ruta:Array.from(state.routeManagers.entries()).map(([ruta_id,item])=>({ruta_id:Number(ruta_id),requiere_encargado:Boolean(item.requiere_encargado),agente_id:item.agente_id || null,tipo_asignacion:item.tipo_asignacion || 'MANUAL'})),
                asignaciones:state.assignments.map(({lugar_id,agente_id,tipo_asignacion})=>({lugar_id,agente_id,tipo_asignacion}))
            }});
            state.saved = await api(`distribucion-tablero/distribuciones/${saved.id}`);
            state.editingId = 0;
            sessionStorage.removeItem(draftKey()); closeModal('tdSaveModal'); closeModal('tdPendingModal'); renderSaved(); openModal('tdResultModal');
            notify(saved.pendientes ? `Distribucion guardada. Quedaron ${saved.pendientes} puestos pendientes.` : 'Distribucion guardada correctamente.');
        } catch (error) { notify(error.message, true); }
        finally { loading(button, false); }
    }
    function renderSaved() {
        const saved = state.saved; if (!saved) return;
        $('#tdSavedName').textContent = saved.nombre;
        $('#tdSavedSummary').textContent = `${saved.distrito} · ${saved.turno} · ${Number(saved.porcentaje_cobertura || 0)}% de cobertura`;
        const groups = new Map(); for (const detail of saved.detalles || []) { if (!groups.has(detail.ruta)) groups.set(detail.ruta, []); groups.get(detail.ruta).push(detail); }
        $('#tdSavedDetail').innerHTML = Array.from(groups.entries()).map(([route, details]) => `<div class="td-saved-route"><b>${esc(route)}</b><div>${details.filter(item => item.agente_id).length} asignados · ${details.filter(item => !item.agente_id).length} pendientes</div></div>`).join('');
    }

    $('#tdDistrict').addEventListener('change',async()=>{await loadCircuitsForDistrict();if($('#tdShift').value)await loadBoard();else showEmpty('Seleccione un turno para cargar las rutas disponibles.');});
    $('#tdCircuit').addEventListener('change',applyCircuitFilter);
    $('#tdShift').addEventListener('change', loadBoard); $('#tdBoardDate').addEventListener('change', loadBoard);
    $('#tdRouteSearch').addEventListener('input', renderRoutes); $('#tdRouteList').addEventListener('click', event => { const item = event.target.closest('[data-route-id]'); if (item) selectRoute(Number(item.dataset.routeId)); });
    $('#tdPlacesBody').addEventListener('click', event => {
        const assign = event.target.closest('[data-assign-place]'); const change = event.target.closest('[data-change-agent]'); const remove = event.target.closest('[data-remove-agent]');
        if (assign) openAgentSelector(assign.dataset.assignPlace);
        if (change) openAgentSelector(change.dataset.placeId, change.dataset.changeAgent);
        if (remove) removeAgent(remove.dataset.placeId, remove.dataset.removeAgent);
    });

    let agentSearchDebounce = null;
    $('#tdAgentSearch').addEventListener('input', () => {
        clearTimeout(agentSearchDebounce);
        agentSearchDebounce = setTimeout(() => { state.agentModal.page = 1; fetchAgentList(); }, 350);
    });
    $$('#tdFilterGrupo, #tdFilterTipoServicio, #tdFilterGrado, #tdFilterEstado').forEach(sel => {
        sel.addEventListener('change', () => { state.agentModal.page = 1; fetchAgentList(); });
    });
    $('#tdClearAgentFilters').addEventListener('click', () => {
        $('#tdAgentSearch').value = '';
        $$('#tdFilterGrupo, #tdFilterTipoServicio, #tdFilterGrado, #tdFilterEstado').forEach(sel => sel.value = '');
        state.agentModal.page = 1; fetchAgentList();
    });
    $('#tdAgentTableBody').addEventListener('click', event => {
        const btn = event.target.closest('[data-select-agent]');
        if (btn) chooseAgent(btn.dataset.selectAgent, btn.dataset.requiresForce === '1');
    });
    $('#tdAgentPagination').addEventListener('click', event => {
        const btn = event.target.closest('[data-page]');
        if (btn) { state.agentModal.page = Number(btn.dataset.page); fetchAgentList(); }
    });
    $('#tdConfirmForce').addEventListener('click', confirmForceAssignment);

    $('#tdAssignDistrictManager')?.addEventListener('click',()=>openManagerSelector('district'));
    $('#tdRemoveDistrictManager')?.addEventListener('click',()=>{state.districtManager=null;for(const [id,item] of state.circuitManagers.entries())if(item.usar_encargado_distrito)state.circuitManagers.delete(id);saveDraft();renderWorkspace();refreshAvailability();});
    $('#tdDistrictAsCircuitManager')?.addEventListener('change',syncDistrictCircuitAssignment);
    $('#tdDistrictManagerCircuit')?.addEventListener('change',()=>{if($('#tdDistrictAsCircuitManager').checked)syncDistrictCircuitAssignment();});
    $('#tdAddCircuitManager')?.addEventListener('click',()=>openCircuitEditor(state.circuitId));
    $('#tdCircuitManagersList')?.addEventListener('click',event=>{const edit=event.target.closest('[data-edit-circuit-manager]');const remove=event.target.closest('[data-remove-circuit-manager]');if(edit)openCircuitEditor(edit.dataset.editCircuitManager);if(remove){state.circuitManagers.delete(Number(remove.dataset.removeCircuitManager));saveDraft();renderManagers();refreshAvailability();}});
    $$('#tdCircuitManagerModal [data-circuit-role]').forEach(button=>button.addEventListener('click',()=>openCircuitRoleSelector(button.dataset.circuitRole)));
    $('#tdCircuitManagerCircuit')?.addEventListener('change',event=>{if(state.circuitDraft)state.circuitDraft.circuito_id=Number(event.target.value||0);});
    $('#tdSaveCircuitManager')?.addEventListener('click',saveCircuitManagerDraft);
    $('#tdRouteManagerRequired')?.addEventListener('change',event=>{
        const routeId=Number(state.routeId); const enabled=event.target.checked;
        state.routeManagers.set(routeId,{requiere_encargado:enabled}); saveDraft(); renderWorkspace();
        if(enabled) openManagerSelector('route',routeId);
    });
    $('#tdAssignRouteManager')?.addEventListener('click',()=>openManagerSelector('route',state.routeId));

    $('#tdRandomAssign')?.addEventListener('click', randomAssign); $('#tdSaveDraft')?.addEventListener('click', openSave);
    $('#tdDistributionDate').addEventListener('change', event => { $('#tdGeneratedName').textContent = `DISTRIBUCION DE PERSONAL FECHA ${formatDate(event.target.value)}`; });
    $('#tdConfirmSave').addEventListener('click', requestSave); $('#tdForceSave')?.addEventListener('click', requestSave);
    $$('[data-close]').forEach(button => button.addEventListener('click', () => closeModal(button.dataset.close)));
    $$('.td-modal').forEach(modal => modal.addEventListener('click', event => { if (event.target === modal) modal.hidden = true; }));
    $('#tdViewSaved').addEventListener('click', () => { renderSaved(); notify('Detalle de la distribucion cargado.'); });
    $('#tdEditSaved').addEventListener('click', () => {
        if (!state.saved) return;
        state.editingId = Number(state.saved.id);
        state.assignments = (state.saved.detalles || []).filter(item => item.agente_id).map(item => ({
            lugar_id: Number(item.lugar_id), agente_id: Number(item.agente_id), tipo_asignacion: item.tipo_asignacion || 'MANUAL',
            agente: {id: Number(item.agente_id), nombre_completo: item.agente, cedula: item.cedula},
        }));
        saveDraft(); closeModal('tdResultModal'); renderWorkspace(); refreshAvailability();
        notify('Distribucion abierta para edicion. Realice los cambios y pulse Guardar distribucion.');
    });
    $('#tdPrintSaved').addEventListener('click', () => window.print()); $('#tdPdfSaved').addEventListener('click', () => { notify('Seleccione "Guardar como PDF" en el dialogo de impresion.'); setTimeout(() => window.print(), 250); });
    $('#tdDeleteSaved')?.addEventListener('click', async () => {
        if (!state.saved || !canDelete || !confirm('¿Eliminar esta distribucion y cancelar sus asignaciones?')) return;
        try { await api(`distribucion-tablero/distribuciones/${state.saved.id}`, {method: 'DELETE'}); closeModal('tdResultModal'); state.saved = null; state.editingId = 0; notify('Distribucion eliminada correctamente.'); }
        catch (error) { notify(error.message, true); }
    });
    if (catalogs.distritos?.length === 1) $('#tdDistrict').value = String(catalogs.distritos[0].id);
    if (catalogs.turnos?.length === 1) $('#tdShift').value = String(catalogs.turnos[0].id);

    const urlParams = new URLSearchParams(window.location.search);
    const preDistrict = urlParams.get('distrito_id');
    const preShift = urlParams.get('turno_id');
    const preDate = urlParams.get('fecha_distribucion') || urlParams.get('fecha');
    if (preDistrict) {
        const distSel = $('#tdDistrict');
        if (distSel) distSel.value = preDistrict;
    }
    if (preShift) {
        const shiftSel = $('#tdShift');
        if (shiftSel) shiftSel.value = preShift;
    }
    if (preDate && /^\d{4}-\d{2}-\d{2}$/.test(preDate)) $('#tdBoardDate').value = preDate;
    if (($('#tdDistrict').value && $('#tdShift').value) || (preDistrict && preShift)) loadBoard();
})();
