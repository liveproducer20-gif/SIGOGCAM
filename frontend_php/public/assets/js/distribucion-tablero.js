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
    const canConfigure = app.dataset.canConfigure === '1';

    const state = {
        districtId: 0, circuitId: 0, shiftId: 0, board: null, routeId: 0,
        places: new Map(), assignments: [], districtManager: null, circuitManagers: new Map(), routeManagers: new Map(), agentTarget: null, availability: null,
        saved: null, editingId: 0,
        circuitDraft: null, promptedDistrictKey: '',
        districtSummaries: [], dirty: false, pendingDistrictId: 0,
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
    const modalStack = [];
    function syncModalStack() {
        for (let index = modalStack.length - 1; index >= 0; index -= 1) {
            if (!modalStack[index]?.isConnected || modalStack[index].hidden) modalStack.splice(index, 1);
        }
        modalStack.forEach((modal, index) => {
            modal.style.zIndex = String(10000 + (index * 20));
            modal.classList.toggle('is-modal-underlay', index < modalStack.length - 1);
        });
        document.body.classList.toggle('td-modal-open', modalStack.length > 0);
    }
    function openModal(id) {
        const modal = document.getElementById(id);
        if (!modal) return;
        if (modal.parentElement !== document.body) document.body.appendChild(modal);
        const previousIndex = modalStack.indexOf(modal);
        if (previousIndex >= 0) modalStack.splice(previousIndex, 1);
        modal.hidden = false;
        modalStack.push(modal);
        syncModalStack();
    }
    function closeModal(id) {
        const modal = document.getElementById(id);
        if (!modal) return;
        modal.hidden = true;
        modal.style.removeProperty('z-index');
        modal.classList.remove('is-modal-underlay');
        const stackIndex = modalStack.indexOf(modal);
        if (stackIndex >= 0) modalStack.splice(stackIndex, 1);
        syncModalStack();
    }
    function selectedDate() { return $('#tdBoardDate')?.value || ''; }
    function draftKey() { return `sigo-distribucion-draft:${state.districtId}:${state.shiftId}:${selectedDate()}`; }
    function renderSaveState() {
        const status=$('#tdUnsavedState'),button=$('#tdSaveDraft');
        if(status){status.classList.toggle('is-dirty',state.dirty);status.innerHTML=state.dirty?'&#9679; Cambios sin guardar':'&#10003; Guardado';}
        if(button)button.disabled=!state.dirty;
    }
    function saveDraft() {
        if (!state.districtId || !state.shiftId) return;
        sessionStorage.setItem(draftKey(), JSON.stringify({assignments: state.assignments, districtManager: state.districtManager, circuitManagers:Array.from(state.circuitManagers.entries()), routeManagers: Array.from(state.routeManagers.entries()), updatedAt: new Date().toISOString()}));
        state.dirty=true;renderSaveState();
    }
    function restoreDraft() {
        try {
            const stored=sessionStorage.getItem(draftKey());const draft = JSON.parse(stored || '{}');
            state.assignments = draft.assignments || []; state.districtManager = draft.districtManager || null;
            state.circuitManagers = new Map(draft.circuitManagers || []);
            state.routeManagers = new Map(draft.routeManagers || []);
            state.dirty=Boolean(stored);
        } catch (_) { state.assignments = []; state.districtManager = null; state.circuitManagers = new Map(); state.routeManagers = new Map(); state.dirty=false; }
        renderSaveState();
    }
    function usedAgentIds(exceptAgentId = 0) {
        const ids = state.assignments.map(item => Number(item.agente_id));
        if (state.districtManager?.agente_id) ids.push(Number(state.districtManager.agente_id));
        if (state.districtManager?.conductor_id) ids.push(Number(state.districtManager.conductor_id));
        if (state.districtManager?.auxiliar_1_id) ids.push(Number(state.districtManager.auxiliar_1_id));
        if (state.districtManager?.auxiliar_2_id) ids.push(Number(state.districtManager.auxiliar_2_id));
        for (const item of state.circuitManagers.values()) {
            if (item?.agente_id && !item.usar_encargado_distrito) ids.push(Number(item.agente_id));
            if (item?.conductor_id && !item.usar_encargado_distrito) ids.push(Number(item.conductor_id));
            if (item?.auxiliar_1_id && !item.usar_encargado_distrito) ids.push(Number(item.auxiliar_1_id));
            if (item?.auxiliar_2_id && !item.usar_encargado_distrito) ids.push(Number(item.auxiliar_2_id));
        }
        for (const item of state.routeManagers.values()) if (item?.agente_id) ids.push(Number(item.agente_id));
        return ids.filter(id => id !== Number(exceptAgentId));
    }
    function assignmentsFor(placeId) { return state.assignments.filter(item => Number(item.lugar_id) === Number(placeId)); }
    function initials(name) { return String(name || 'A').split(/\s+/).filter(Boolean).slice(-2).map(part => part[0]).join('').toUpperCase(); }
    function personDisplayName(name){return String(name||'').replace(/^Agente\s+[1-4]\s+/i,'').trim();}

    function districtSummary(districtId){return state.districtSummaries.find(item=>Number(item.distrito_id)===Number(districtId));}
    async function loadDistrictSummaries(){
        const container=$('#tdDistrictCards');if(!container)return;
        try{state.districtSummaries=await api(`distribucion-tablero/resumen-distritos?fecha=${selectedDate()}`)||[];renderDistrictCards();}
        catch(error){container.innerHTML=`<div class="td-empty-small">${esc(error.message)}</div>`;}
    }
    function renderDistrictCards(){
        const container=$('#tdDistrictCards');if(!container)return;
        const palette=[['#0ea5a8','#e6f8f8'],['#16a34a','#eaf8ee'],['#0891b2','#e8f7fb'],['#f59e0b','#fff7e6'],['#7c3aed','#f2ecff'],['#ea580c','#fff0e8'],['#22c55e','#ebfaef'],['#2563eb','#eaf1ff'],['#9333ea','#f5ebff']];
        const icons=['&#128205;','&#129309;','&#127970;','&#11088;','&#128737;','&#128110;','&#9851;','&#128101;','&#9670;'];
        container.innerHTML=state.districtSummaries.length?state.districtSummaries.map((item,index)=>{
            const selected=Number(item.distrito_id)===state.districtId;const complete=item.estado_turnos==='COMPLETO';
            const circuits=Number(item.numero_circuitos||0),required=Number(item.puestos_requeridos||0),assigned=Number(item.puestos_asignados||0),unconfigured=circuits===0&&required===0;
            const [accent,soft]=palette[index%palette.length];
            return `<button class="td-district-card ${selected?'is-selected':''}" style="--card-accent:${accent};--card-soft:${soft}" type="button" data-district-card="${item.distrito_id}">
                <header><span class="td-district-icon" aria-hidden="true">${icons[index%icons.length]}</span><h3>${esc(item.nombre)}</h3>${selected?'<span class="td-selected-tag">Seleccionado</span>':''}</header>
                <div class="td-district-numbers"><div><b>${circuits}</b> <span>circuitos</span></div><small>${unconfigured?'Sin puestos configurados':`${assigned}/${required} puestos`}</small></div>
                <div class="td-district-progress"><i style="width:${Math.min(100,Number(item.porcentaje||0))}%"></i></div>
                <footer><span class="td-turn-status ${unconfigured?'is-unconfigured':complete?'is-complete':'is-missing'}">${unconfigured?'● Sin configurar':complete?'● Completo':'● Turno faltante'}</span>${complete?'':`<span class="td-detail-button" data-district-detail="${item.distrito_id}">${unconfigured?'Ver configuración':'Ver detalle'} →</span>`}</footer>
            </button>`;
        }).join(''):'<div class="td-empty-small">No existen distritos activos.</div>';
    }
    function renderPendingDetail(summary){
        $('#tdDistrictDetailTitle').textContent=summary.nombre;
        $('#tdDistrictPendingDetail').innerHTML=(summary.turnos||[]).map(turn=>{
            if(turn.completo)return `<section class="td-pending-shift is-complete"><header><h4>${esc(turn.nombre)}</h4><span>✓ Completo</span></header></section>`;
            const districtPending=turn.encargado_distrito_pendiente?'<div class="td-pending-circuit"><b>Responsabilidad del distrito</b><span>⚠ Encargado o recursos obligatorios pendientes</span></div>':'';
            const circuits=(turn.circuitos||[]).map(circuit=>`<div class="td-pending-circuit"><b>⚠ ${esc(circuit.nombre)}</b>${circuit.recursos_pendientes?'<span>Recursos obligatorios incompletos</span>':''}${(circuit.rutas||[]).map(route=>`<div class="td-pending-route"><strong>${esc(route.nombre)}</strong>${route.encargado_pendiente?'<div>⚠ Encargado de ruta sin definir</div>':''}${(route.lugares||[]).map(place=>`<div class="td-pending-place"><span>⚠ ${esc(place.nombre)}</span><span>Requerido: ${place.requerido} · Asignado: ${place.asignado} · Faltan: ${place.faltan}</span></div>`).join('')}</div>`).join('')}</div>`).join('');
            return `<section class="td-pending-shift is-pending"><header><h4>${esc(turn.nombre)}</h4><span>⚠ Pendiente</span></header>${turn.guardado?'':'<div class="td-pending-circuit"><b>Turno sin distribución guardada</b></div>'}${districtPending}${circuits}</section>`;
        }).join('')||'<div class="td-pending-empty">No existen turnos pendientes.</div>';
        openModal('tdDistrictDetailModal');
    }

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
        renderCircuitAccordion();
        const first=visibleRoutes().find(route=>Number(route.lugares||0)>0)||visibleRoutes()[0];
        if(first)await selectRoute(Number(first.id));else showEmpty('No existen rutas para el circuito y turno seleccionados.');
    }

    function renderCircuitAccordion(){
        const panel=$('#tdSelectedDistrictPanel'),container=$('#tdCircuitAccordion');if(!panel||!container)return;
        panel.hidden=!state.districtId;
        $('#tdSelectedDistrictName').textContent=state.board?.distrito?.nombre||districtSummary(state.districtId)?.nombre||'';
        const circuits=state.board?.circuitos||[];
        const palette=[
            {accent:'#1267d5',soft:'#eef5ff',rgb:'18,103,213'},
            {accent:'#07988f',soft:'#edf9f7',rgb:'7,152,143'},
            {accent:'#7c3aed',soft:'#f5f0ff',rgb:'124,58,237'},
            {accent:'#d97706',soft:'#fff7e8',rgb:'217,119,6'},
            {accent:'#db2777',soft:'#fff0f6',rgb:'219,39,119'},
        ];
        container.innerHTML=circuits.length?circuits.map((item,index)=>{
            const color=palette[index%palette.length];const selected=Number(item.id)===state.circuitId;
            return `<button class="td-circuit-toggle ${selected?'is-open':''}" type="button" data-circuit-toggle="${item.id}" aria-pressed="${selected}" style="--circuit-accent:${color.accent};--circuit-soft:${color.soft};--circuit-rgb:${color.rgb}"><i aria-hidden="true">${index+1}</i><span>${esc(item.nombre)}</span><small>${selected?'Seleccionado':'Seleccionar'}</small></button>`;
        }).join(''):'<div class="td-empty-small">Este distrito no tiene circuitos activos.</div>';
        const selectedIndex=circuits.findIndex(item=>Number(item.id)===state.circuitId);
        const workspace=$('.td-workspace');
        if(selectedIndex>=0){
            const color=palette[selectedIndex%palette.length];
            [panel,workspace].forEach(element=>{element.style.setProperty('--selected-circuit-accent',color.accent);element.style.setProperty('--selected-circuit-soft',color.soft);element.style.setProperty('--selected-circuit-rgb',color.rgb);});
            workspace?.classList.add('has-circuit-accent');panel.classList.add('has-circuit-accent');
        }else{
            [panel,workspace].forEach(element=>{element?.style.removeProperty('--selected-circuit-accent');element?.style.removeProperty('--selected-circuit-soft');element?.style.removeProperty('--selected-circuit-rgb');element?.classList.remove('has-circuit-accent');});
        }
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
            state.dirty=false;
            if (state.board.distribucion_id) {
                state.saved = await api(`distribucion-tablero/distribuciones/${state.board.distribucion_id}`);
                state.editingId = Number(state.saved.id);
                const routeManagerDetails = (state.saved.detalles || []).filter(item => String(item.lugar || '').trim().toUpperCase() === 'ENCARGADO DE RUTA');
                state.assignments = (state.saved.detalles || []).filter(item => item.agente_id && String(item.lugar || '').trim().toUpperCase() !== 'ENCARGADO DE RUTA').map(item => ({lugar_id:Number(item.lugar_id),agente_id:Number(item.agente_id),tipo_asignacion:item.tipo_asignacion || 'MANUAL',agente:{id:Number(item.agente_id),nombre_completo:item.agente,cedula:item.cedula}}));
                for (const item of state.saved.encargados || []) {
                    const manager = item.agente_id ? {agente_id:Number(item.agente_id),tipo_asignacion:item.tipo_asignacion || 'MANUAL',agente:{id:Number(item.agente_id),nombre_completo:item.agente,cedula:item.cedula}} : null;
                    const resources={movil_id:item.movil_id?Number(item.movil_id):null,numero_movil:item.numero_movil,placa:item.placa,
                        conductor_id:item.conductor_id?Number(item.conductor_id):null,conductor:item.conductor?{id:Number(item.conductor_id),nombre_completo:item.conductor,grado:item.conductor_grado}:null,
                        auxiliar_1_id:item.auxiliar_1_id?Number(item.auxiliar_1_id):null,auxiliar_1:item.auxiliar_1?{id:Number(item.auxiliar_1_id),nombre_completo:item.auxiliar_1,grado:item.auxiliar_1_grado}:null,
                        auxiliar_2_id:item.auxiliar_2_id?Number(item.auxiliar_2_id):null,auxiliar_2:item.auxiliar_2?{id:Number(item.auxiliar_2_id),nombre_completo:item.auxiliar_2,grado:item.auxiliar_2_grado}:null};
                    if (item.tipo_responsabilidad === 'ENCARGADO_DISTRITO') state.districtManager = {...(manager||{}),...resources};
                    else if (item.tipo_responsabilidad === 'ENCARGADO_CIRCUITO') state.circuitManagers.set(Number(item.circuito_id), {
                        usar_encargado_distrito:Boolean(item.usar_encargado_distrito),...(manager || {}),...resources
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
            if(!state.circuitId&&(state.board.circuitos||[]).length){state.circuitId=Number(state.board.circuitos[0].id);$('#tdCircuit').value=String(state.circuitId);}
            for (const route of state.board.rutas || []) if (route.asignar_encargado && !state.routeManagers.has(Number(route.id))) state.routeManagers.set(Number(route.id), {requiere_encargado:false});
            renderRoutes();
            renderCircuitAccordion();renderDistrictCards();renderSaveState();
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
                <span><b>${esc(route.nombre)}</b><small>${Number(route.lugares || 0)} ${Number(route.lugares || 0) === 1 ? 'lugar' : 'lugares'}</small></span>
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
        $('#tdPlacesBody').innerHTML = places.length ? places.map((place, index) => renderPlaceRow(place, index)).join('') : '<tr><td colspan="5"><div class="td-empty-small">Esta ruta no tiene lugares de servicio activos.</div></td></tr>';
    }
    function managerLabel(item, fallback) {
        return personDisplayName(item?.agente?.nombre_completo) || fallback;
    }
    function resourcesComplete(item){return Boolean(item?.movil_id&&item?.conductor_id&&item?.auxiliar_1_id);}
    function resourcePerson(label,person,required=true){return `<div><span>${label}${required?' <em>Requerido</em>':' <em>Opcional</em>'}</span><strong>${esc(personDisplayName(person?.nombre_completo)||'Sin asignar')}</strong>${person?.grado?`<small>${esc(person.grado)}</small>`:''}</div>`;}
    function resourceSummary(item){const complete=resourcesComplete(item);return `<header><b>RECURSOS ASIGNADOS</b><span class="td-resource-state ${complete?'is-complete':'is-incomplete'}">${complete?'Completo':'Incompleto'}</span></header><div><div><span>Móvil <em>Requerido</em></span><strong>${esc(item?.numero_movil||'Sin asignar')}</strong></div>${resourcePerson('Conductor',item?.conductor)}${resourcePerson('Auxiliar 1',item?.auxiliar_1)}${resourcePerson('Auxiliar 2',item?.auxiliar_2,false)}</div>`;}
    function populateOperationalCatalogs() {
        const circuits=state.board?.circuitos || [];
        const options='<option value="">Todos los circuitos</option>'+circuits.map(item=>`<option value="${item.id}">${esc(item.nombre)}</option>`).join('');
        const filter=$('#tdCircuit');
        if(filter){const current=state.circuitId;filter.innerHTML=options;filter.disabled=false;filter.value=current&&circuits.some(c=>Number(c.id)===current)?String(current):'';state.circuitId=Number(filter.value||0);}
        const circuitOptions='<option value="">Seleccione circuito</option>'+circuits.map(item=>`<option value="${item.id}">${esc(item.nombre)}</option>`).join('');
        if($('#tdDistrictManagerCircuit')) $('#tdDistrictManagerCircuit').innerHTML=circuitOptions;
        if($('#tdCircuitManagerCircuit')) $('#tdCircuitManagerCircuit').innerHTML=circuitOptions;
        if($('#tdCircuitMobile')) $('#tdCircuitMobile').innerHTML='<option value="">Seleccione móvil</option>'+(state.board?.moviles||[]).map(item=>`<option value="${item.id}">${esc(item.numero_movil)}${item.placa?` · ${esc(item.placa)}`:''}</option>`).join('');
    }
    function renderManagers() {
        const districtEnabled = Boolean(state.board?.distrito?.asignar_encargado);
        $('#tdDistrictManagerCard').hidden = !districtEnabled;
        if (districtEnabled) {
            $('#tdDistrictManagerValue').textContent = managerLabel(state.districtManager, 'Sin asignar');
            if($('#tdDistrictResources')) $('#tdDistrictResources').innerHTML=resourceSummary(state.districtManager);
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
            if (item.requiere_encargado) $('#tdRouteManagerValue').textContent = managerLabel(item, 'Debe seleccionar un encargado de ruta');
            else $('#tdRouteManagerValue').innerHTML = 'Sin encargado de ruta<br><em>Responsable: Encargado del circuito</em>';
        }
    }
    function circuitName(circuitId){return (state.board?.circuitos||[]).find(item=>Number(item.id)===Number(circuitId))?.nombre || `Circuito ${circuitId}`;}
    function renderCircuitManagers(){
        const list=$('#tdCircuitManagersList'); if(!list)return;
        const items=Array.from(state.circuitManagers.entries()).filter(([id])=>!state.circuitId||Number(id)===state.circuitId);
        list.innerHTML=items.length?items.map(([circuitId,item])=>`<article class="td-circuit-manager-item"><div><b>${esc(circuitName(circuitId))}</b><strong>${esc(personDisplayName(item.agente?.nombre_completo)||'Sin encargado')}</strong>${resourceSummary(item)}</div>${canAssign?`<div><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-edit-circuit-manager="${circuitId}">Editar</button><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-remove-circuit-manager="${circuitId}">Quitar</button></div>`:''}</article>`).join(''):'<p class="td-empty-small">No existen encargados de circuito asignados.</p>';
    }
    function renderPlaceRow(place, index) {
        const assigned = assignmentsFor(place.id); const required = Number(place.cantidad_requerida || 0); const covered = assigned.length >= required && required > 0;
        const agents = assigned.length ? assigned.map(item => {
            const isForced = item.tipo_asignacion === 'FORZADA';
            const forcedBadge = isForced ? '<span class="td-forced-badge" title="Este agente fue asignado manualmente a pesar de encontrarse en estado no disponible.">&#9888; Forzada</span>' : '';
            const displayName=personDisplayName(item.agente?.nombre_completo);
            return `<div class="td-agent"><span class="td-avatar">${esc(initials(displayName))}</span><div><b>${esc(displayName||'Sin nombre')}</b>${item.agente?.grado ? `<small>Grado: ${esc(item.agente.grado)}</small>` : ''}${forcedBadge}${isForced ? `<small class="td-forced-original">Estado original: ${esc(item.estado_original || '')}</small>` : ''}</div></div>`;
        }).join('') : '<div class="td-empty-agent"><span class="td-avatar">&#9823;</span><div><b>Sin asignar</b><small>Seleccione un agente</small></div></div>';
        let actions = '&mdash;';
        if (canAssign) {
            const missing = required - assigned.length;
            const addBtn = missing > 0
                ? `<button class="td-action-add" type="button" data-assign-place="${place.id}">&#9823; ${assigned.length === 0 ? 'Asignar' : 'Agregar agente'}</button>`
                : '';
            if (assigned.length === 0) {
                actions = addBtn || '&mdash;';
            } else if (assigned.length === 1) {
                actions = `${addBtn}<button class="td-action-icon td-action-change" type="button" data-change-agent="${assigned[0].agente_id}" data-place-id="${place.id}" title="Cambiar agente" aria-label="Cambiar agente"><svg aria-hidden="true" viewBox="0 0 24 24"><path d="M20 11a8 8 0 0 0-14.9-4M4 5v5h5M4 13a8 8 0 0 0 14.9 4M20 19v-5h-5"/></svg></button><button class="td-action-icon td-remove" type="button" data-remove-agent="${assigned[0].agente_id}" data-place-id="${place.id}" title="Eliminar asignación" aria-label="Eliminar asignación"><svg aria-hidden="true" viewBox="0 0 24 24"><path d="M4 7h16M9 7V4h6v3m3 0-1 13H7L6 7m4 4v5m4-5v5"/></svg></button>`;
            } else {
                actions = `${addBtn}<button type="button" data-manage-place="${place.id}">Gestionar</button>`;
            }
        }
        const requiredCell = canConfigure
            ? `<div class="td-required-stepper" title="Agentes requeridos para este lugar de servicio"><button type="button" class="td-req-btn" data-req-minus="${place.id}" ${required <= assigned.length ? 'disabled' : ''} aria-label="Disminuir requeridos" aria-disabled="${required <= assigned.length}">−</button><b>${required}</b><button type="button" class="td-req-btn" data-req-plus="${place.id}" ${required >= 100 ? 'disabled' : ''} aria-label="Aumentar requeridos" aria-disabled="${required >= 100}">+</button><small>${required === 1 ? 'Agente' : 'Agentes'}</small></div>`
            : `<b>${required}</b>${required === 1 ? 'Agente' : 'Agentes'}`;
        return `<tr><td><div class="td-place-cell"><div><b>${esc(place.nombre)}</b></div></div></td><td class="td-required">${requiredCell}</td><td>${agents}</td><td><span class="td-status ${covered ? 'td-status-assigned' : 'td-status-pending'}">${covered ? 'Asignado' : 'Pendiente'}</span></td><td><div class="td-actions">${actions}</div></td></tr>`;
    }

    async function updatePlaceRequirement(placeId, delta) {
        if (!canConfigure || !state.routeId) return;
        const places = state.places.get(state.routeId) || [];
        const place = places.find(item => Number(item.id) === Number(placeId));
        if (!place) return;
        const assigned = assignmentsFor(placeId).length;
        const next = Math.max(0, Math.min(100, Number(place.cantidad_requerida || 0) + delta));
        if (next < assigned) return notify('No puede reducir los requeridos por debajo de los agentes ya asignados.', true);
        try {
            await api('distribucion-tablero/sectores/requerimiento', {method: 'PUT', body: {ruta_id: state.routeId, sectores: [{sector_id: Number(placeId), cantidad_agentes_requeridos: next}]}});
            place.cantidad_requerida = next;
            renderWorkspace();
            await loadDistrictSummaries();
            if (next > assigned && canAssign) {
                notify('Requeridos actualizados. Seleccione el agente adicional.');
                openAgentSelector(place.id);
            } else {
                notify(delta > 0 ? `Requeridos aumentados a ${next} para ${place.nombre}.` : `Requeridos reducidos a ${next} para ${place.nombre}.`);
            }
        } catch (error) { notify(error.message, true); }
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

        $('#tdAgentModalEyebrow').textContent = replaceAgentId ? 'Cambiar agente asignado' : 'Asignacion de personal';
        $('#tdAgentModalTitle').textContent = replaceAgentId ? 'Cambiar agente asignado' : 'Asignar agente al lugar';
        $('#tdAgentModalSubtitle').textContent = `${place?.nombre || ''} | ${routeData()?.nombre || ''}`;
        const reqChip = $('#tdAgentRequiredChip');
        if (reqChip) { reqChip.hidden = false; reqChip.textContent = `Requerido: ${Number(place?.cantidad_requerida || 0)}`; }
        $('#tdAgentInfoBar').innerHTML = `
            <div class="td-agent-summary-item"><i>&#128506;</i><span><small>Lugar de servicio</small><b>${esc(place?.nombre || '—')}</b><em>${esc(routeData()?.nombre || '')}</em></span></div>
            <div class="td-agent-summary-item"><i>&#128100;</i><span><small>Agente actual</small><b>${esc(replaceAgent?.agente?.nombre_completo || 'Sin asignar')}</b><em>${replaceAgent?.agente?.grado ? esc(replaceAgent.agente.grado) : ''}</em></span></div>
            <div class="td-agent-summary-item"><i>&#128337;</i><span><small>Turno</small><b>${esc(state.agentTarget.turnoNombre || '—')}</b></span></div>
        `;

        $('#tdAgentSearch').value = '';
        $$('#tdFilterGrupo, #tdFilterTipoServicio, #tdFilterGrado, #tdFilterEstado').forEach(sel => sel.value = '');
        $('#tdAgentTableBody').innerHTML = '<tr><td colspan="7"><div class="td-empty-small">Consultando personal...</div></td></tr>';
        $('#tdAgentPagination').innerHTML = '';
        $('#tdAgentFooterInfo').textContent = 'Consultando personal...';
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
        const scopeName = kind === 'district' ? (state.board?.distrito?.nombre || '') : (route?.nombre || '');
        $('#tdAgentModalEyebrow').textContent = current?.agente_id ? `Cambiar ${title.toLowerCase()}` : `Asignacion de ${title.toLowerCase()}`;
        $('#tdAgentModalTitle').textContent = current?.agente_id ? `Cambiar ${title.toLowerCase()}` : `Asignar ${title.toLowerCase()}`;
        $('#tdAgentModalSubtitle').textContent = scopeName;
        const reqChip = $('#tdAgentRequiredChip'); if (reqChip) reqChip.hidden = true;
        $('#tdAgentInfoBar').innerHTML = `
            <div class="td-agent-summary-item"><i>&#128205;</i><span><small>${title}</small><b>${esc(scopeName)}</b></span></div>
            <div class="td-agent-summary-item"><i>&#128100;</i><span><small>Agente actual</small><b>${esc(current?.agente?.nombre_completo || 'Sin asignar')}</b></span></div>
            <div class="td-agent-summary-item"><i>&#128337;</i><span><small>Turno</small><b>${esc(state.agentTarget.turnoNombre || '—')}</b></span></div>
        `;
        $('#tdAgentSearch').value=''; $$('#tdFilterGrupo, #tdFilterTipoServicio, #tdFilterGrado, #tdFilterEstado').forEach(sel=>sel.value='');
        $('#tdAgentTableBody').innerHTML='<tr><td colspan="7"><div class="td-empty-small">Consultando personal...</div></td></tr>'; $('#tdAgentPagination').innerHTML='';
        $('#tdAgentFooterInfo').textContent = 'Consultando personal...';
        openModal('tdAgentModal'); await fetchAgentList();
    }

    function emptyCircuitDraft(circuitId=0){
        return {_scope:'circuit',circuito_id:Number(circuitId||0),usar_encargado_distrito:false,agente_id:null,agente:null,conductor_id:null,conductor:null,auxiliar_1_id:null,auxiliar_1:null,auxiliar_2_id:null,auxiliar_2:null,movil_id:null};
    }
    function openCircuitEditor(circuitId=0,useDistrictManager=false){
        const selected=Number(circuitId||state.circuitId||0);
        const current=state.circuitManagers.get(selected);
        state.circuitDraft=current?structuredClone({...current,_scope:'circuit',circuito_id:selected,_original_circuito_id:selected}):emptyCircuitDraft(selected);
        if(useDistrictManager&&state.districtManager){
            state.circuitDraft={...state.circuitDraft,usar_encargado_distrito:true,
                agente_id:Number(state.districtManager.agente_id),agente:state.districtManager.agente,
                conductor_id:state.districtManager.conductor_id||null,conductor:state.districtManager.conductor||null,
                auxiliar_1_id:state.districtManager.auxiliar_1_id||null,auxiliar_1:state.districtManager.auxiliar_1||null,
                auxiliar_2_id:state.districtManager.auxiliar_2_id||null,auxiliar_2:state.districtManager.auxiliar_2||null,
                movil_id:state.districtManager.movil_id||null,numero_movil:state.districtManager.numero_movil||null,placa:state.districtManager.placa||null};
        }
        renderCircuitEditor(); openModal('tdCircuitManagerModal');
    }
    function openDistrictResourceEditor(){
        if(!state.districtManager?.agente_id)return notify('Primero seleccione el encargado del distrito.',true);
        state.circuitDraft=structuredClone({...state.districtManager,_scope:'district',circuito_id:0});
        renderCircuitEditor();openModal('tdCircuitManagerModal');
    }
    function renderCircuitEditor(){
        const draft=state.circuitDraft||emptyCircuitDraft();
        const districtScope=draft._scope==='district';
        $('#tdResourceModalTitle').textContent=districtScope?'Recursos del encargado de distrito':'Recursos del encargado de circuito';
        $('#tdResourceModalSubtitle').textContent=districtScope?(state.board?.distrito?.nombre||''):circuitName(draft.circuito_id);
        $('#tdCircuitManagerCircuitField').hidden=districtScope;
        $('#tdCircuitManagerCircuit').value=draft.circuito_id?String(draft.circuito_id):'';
        $('#tdCircuitManagerName').textContent=personDisplayName(draft.agente?.nombre_completo)||'Sin seleccionar';
        $('#tdCircuitDriverName').textContent=personDisplayName(draft.conductor?.nombre_completo)||'Sin seleccionar';
        $('#tdCircuitAux1Name').textContent=personDisplayName(draft.auxiliar_1?.nombre_completo)||'Sin seleccionar';
        $('#tdCircuitAux2Name').textContent=personDisplayName(draft.auxiliar_2?.nombre_completo)||'Sin seleccionar';
        $('#tdCircuitMobile').value=draft.movil_id?String(draft.movil_id):'';
        const managerButton=$('[data-circuit-role="manager"]'); if(managerButton){managerButton.hidden=districtScope;managerButton.disabled=Boolean(draft.usar_encargado_distrito);}
    }
    async function openCircuitRoleSelector(role){
        const draft=state.circuitDraft; if(!draft)return;
        if(draft._scope!=='district'&&!draft.circuito_id)return notify('Seleccione un circuito.',true);
        const roleConfig={manager:['circuitManager','agente_id','agente','Encargado de circuito'],driver:['circuitDriver','conductor_id','conductor','Conductor'],aux1:['circuitAux1','auxiliar_1_id','auxiliar_1','Auxiliar 1'],aux2:['circuitAux2','auxiliar_2_id','auxiliar_2','Auxiliar 2']}[role];
        if(!roleConfig)return;
        const [kind,idKey,valueKey,title]=roleConfig; const current=draft[valueKey];
        const scopeName=draft._scope==='district'?(state.board?.distrito?.nombre||'Distrito'):circuitName(draft.circuito_id);
        state.agentTarget={kind,circuitRole:role,replaceAgentId:Number(draft[idKey]||0),placeNombre:scopeName,rutaNombre:'',turnoNombre:$('#tdShift').selectedOptions[0]?.textContent||''};
        state.agentModal={page:1,filters:{},search:'',data:null};
        $('#tdAgentModalEyebrow').textContent=current?`Cambiar ${title.toLowerCase()}`:`Seleccionar ${title.toLowerCase()}`;
        $('#tdAgentModalTitle').textContent=current?`Cambiar ${title.toLowerCase()}`:`Seleccionar ${title.toLowerCase()}`;
        $('#tdAgentModalSubtitle').textContent=scopeName;
        const reqChip = $('#tdAgentRequiredChip'); if (reqChip) reqChip.hidden = true;
        $('#tdAgentInfoBar').innerHTML=`
            <div class="td-agent-summary-item"><i>&#128205;</i><span><small>${title}</small><b>${esc(scopeName)}</b></span></div>
            <div class="td-agent-summary-item"><i>&#128100;</i><span><small>Responsable</small><b>${esc(current?.nombre_completo || 'Sin asignar')}</b></span></div>
            <div class="td-agent-summary-item"><i>&#128337;</i><span><small>Turno</small><b>${esc(state.agentTarget.turnoNombre || '—')}</b></span></div>
        `;
        $('#tdAgentSearch').value=''; $$('#tdFilterGrupo, #tdFilterTipoServicio, #tdFilterGrado, #tdFilterEstado').forEach(sel=>sel.value='');
        $('#tdAgentFooterInfo').textContent = 'Consultando personal...';
        openModal('tdAgentModal'); await fetchAgentList();
    }

    async function fetchAgentList() {
        if (!state.agentTarget) return;
        const draftPeople=state.circuitDraft?[state.circuitDraft.agente_id,state.circuitDraft.conductor_id,state.circuitDraft.auxiliar_1_id,state.circuitDraft.auxiliar_2_id].filter(Boolean).map(Number):[];
        const excluded = Array.from(new Set([...usedAgentIds(state.agentTarget.replaceAgentId),...draftPeople])).filter(id=>id!==Number(state.agentTarget.replaceAgentId||0));
        const body = {
            distrito_id: state.districtId, turno_id: state.shiftId,
            tipo_responsabilidad: state.agentTarget.kind === 'district' ? 'ENCARGADO_DISTRITO' : state.agentTarget.kind === 'route' ? 'ENCARGADO_RUTA' : state.agentTarget.kind === 'circuitManager' ? 'ENCARGADO_CIRCUITO' : state.agentTarget.kind === 'circuitDriver' ? 'CONDUCTOR' : state.agentTarget.kind.startsWith('circuitAux') ? 'AUXILIAR' : 'AGENTE_LUGAR',
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
            $('#tdAgentTableBody').innerHTML = `<tr><td colspan="7"><div class="td-empty-small">${esc(error.message)}</div></td></tr>`;
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
        const resourceSelector=Boolean(state.agentTarget&&!['place'].includes(state.agentTarget.kind));
        const agents = (data.agentes || []).filter(agent=>!resourceSelector||agent.disponible);
        if (!agents.length) {
            $('#tdAgentTableBody').innerHTML = '<tr><td colspan="7"><div class="td-empty-small">No se encontraron agentes con los filtros seleccionados.</div></td></tr>';
            $('#tdAgentPagination').innerHTML = '';
            $('#tdAgentFooterInfo').textContent = 'No se encontraron agentes.';
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
                <td><div class="td-agent-cell"><span class="td-avatar-sm">${esc(initials(personDisplayName(agent.nombre_completo)))}</span><b>${esc(personDisplayName(agent.nombre_completo))}</b></div></td>
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
        $('#tdAgentFooterInfo').textContent = `Mostrando ${(currentPage-1)*20+1}-${Math.min(currentPage*20, data.total)} de ${data.total} agentes`;
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
            $('#tdForceAgentName').textContent = personDisplayName(agent.nombre_completo);
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
        const value = {agente_id:Number(agent.id),tipo_asignacion:assignmentType,agente:{id:Number(agent.id),nombre_completo:agent.nombre_completo,grado:agent.grado,estado_personal:agent.estado_laboral},...extra};
        if (target.kind === 'district') {
            state.districtManager = {...state.districtManager,...value};
            for(const [circuitId,item] of state.circuitManagers.entries())if(item.usar_encargado_distrito)state.circuitManagers.set(circuitId,{...item,agente_id:value.agente_id,agente:value.agente});
        }
        else if (target.kind === 'route') state.routeManagers.set(Number(target.routeId), {requiere_encargado:true,...value});
        else if (target.kind.startsWith('circuit')) {
            const mapping={circuitManager:['agente_id','agente'],circuitDriver:['conductor_id','conductor'],circuitAux1:['auxiliar_1_id','auxiliar_1'],circuitAux2:['auxiliar_2_id','auxiliar_2']}[target.kind];
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

    function openManageAgents(placeId) {
        const place = (state.places.get(state.routeId) || []).find(p => Number(p.id) === Number(placeId));
        if (!place) return;
        const assigned = assignmentsFor(placeId);
        const required = Number(place.cantidad_requerida || 0);
        const title = $('#tdManageAgentsTitle');
        const info = $('#tdManagePlaceInfo');
        const list = $('#tdManageAgentsList');
        const reqInfo = $('#tdManageRequiredInfo');
        if (title) title.textContent = `Agentes - ${place.nombre}`;
        if (info) info.innerHTML = `<b>${esc(place.nombre)}</b><span>${assigned.length} de ${required} asignados</span>`;
        if (list) {
            list.innerHTML = assigned.length ? assigned.map(item => {
                const isForced = item.tipo_asignacion === 'FORZADA';
                return `<div class="td-manage-agent-row">
                    <div class="td-manage-agent-info">
                        <span class="td-avatar">${esc(initials(personDisplayName(item.agente?.nombre_completo)))}</span>
                        <div><b>${esc(personDisplayName(item.agente?.nombre_completo)||'Sin nombre')}</b>
                        <small>${esc(item.agente?.grado || '')}${isForced ? ' &middot; <em style="color:#c2410c">Forzada</em>' : ''}</small></div>
                    </div>
                    <div class="td-manage-agent-actions">
                        <button class="td-btn td-btn-ghost td-btn-sm" type="button" data-manage-change="${item.agente_id}" data-place-id="${placeId}">Cambiar</button>
                        <button class="td-btn td-btn-danger td-btn-sm" type="button" data-manage-remove="${item.agente_id}" data-place-id="${placeId}">Quitar</button>
                    </div>
                </div>`;
            }).join('') : '<p class="td-empty-small">Sin agentes asignados.</p>';
            list.onclick = function(e) {
                const changeBtn = e.target.closest('[data-manage-change]');
                const removeBtn = e.target.closest('[data-manage-remove]');
                if (changeBtn) { closeModal('tdManageAgentsModal'); openAgentSelector(changeBtn.dataset.placeId, changeBtn.dataset.manageChange); }
                if (removeBtn) { removeAgent(removeBtn.dataset.placeId, removeBtn.dataset.manageRemove); openManageAgents(placeId); }
            };
        }
        if (reqInfo) reqInfo.textContent = `Requeridos: ${required}`;
        openModal('tdManageAgentsModal');
        const addBtn = $('#tdManageAddAgent');
        if (addBtn) { addBtn.onclick = () => { closeModal('tdManageAgentsModal'); openAgentSelector(placeId); }; }
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
        const draft=state.circuitDraft;if(!draft)return;
        const districtScope=draft._scope==='district';const circuitId=Number($('#tdCircuitManagerCircuit').value||0);
        if(!districtScope&&!circuitId)return notify('Seleccione un circuito.',true);
        if(!draft.agente_id)return notify(`Seleccione el encargado del ${districtScope?'distrito':'circuito'}.`,true);
        draft.movil_id=Number($('#tdCircuitMobile').value||0)||null;
        if(!draft.movil_id||!draft.conductor_id||!draft.auxiliar_1_id)return notify('Debe asignar móvil, conductor y auxiliar 1.',true);
        const people=[draft.agente_id,draft.conductor_id,draft.auxiliar_1_id,draft.auxiliar_2_id].filter(Boolean).map(Number);
        if(new Set(people).size!==people.length)return notify('No puede repetir una persona como encargado, conductor o auxiliar.',true);
        const mobile=(state.board?.moviles||[]).find(item=>Number(item.id)===Number(draft.movil_id));draft.numero_movil=mobile?.numero_movil||null;draft.placa=mobile?.placa||null;
        if(districtScope){const {_scope,...resources}=draft;state.districtManager={...state.districtManager,...resources};for(const [id,item] of state.circuitManagers.entries())if(item.usar_encargado_distrito)state.circuitManagers.set(id,{...item,agente_id:state.districtManager.agente_id,agente:state.districtManager.agente,conductor_id:resources.conductor_id,conductor:resources.conductor,auxiliar_1_id:resources.auxiliar_1_id,auxiliar_1:resources.auxiliar_1,auxiliar_2_id:resources.auxiliar_2_id,auxiliar_2:resources.auxiliar_2,movil_id:resources.movil_id,numero_movil:resources.numero_movil,placa:resources.placa});state.circuitDraft=null;saveDraft();closeModal('tdCircuitManagerModal');renderManagers();refreshAvailability();return;}
        draft.circuito_id=circuitId;
        if(draft._original_circuito_id&&Number(draft._original_circuito_id)!==circuitId)state.circuitManagers.delete(Number(draft._original_circuito_id));
        const {_original_circuito_id,_scope,...persisted}=draft;state.circuitManagers.set(circuitId,{...persisted});state.circuitDraft=null;saveDraft();closeModal('tdCircuitManagerModal');renderManagers();refreshAvailability();
    }
    function syncDistrictCircuitAssignment(){
        const checked=$('#tdDistrictAsCircuitManager').checked; const circuitId=Number($('#tdDistrictManagerCircuit').value||0);
        for(const [id,item] of state.circuitManagers.entries())if(item.usar_encargado_distrito&&(!checked||Number(id)!==circuitId))state.circuitManagers.delete(id);
        if(!checked){saveDraft();renderManagers();return;}
        if(!state.districtManager?.agente_id){$('#tdDistrictAsCircuitManager').checked=false;notify('Primero seleccione el encargado del distrito.',true);openManagerSelector('district');return;}
        if(!circuitId)return notify('Seleccione el circuito que también tendrá a cargo.',true);
        const current=state.circuitManagers.get(circuitId)||emptyCircuitDraft(circuitId);
        state.circuitManagers.set(circuitId,{...current,usar_encargado_distrito:true,agente_id:Number(state.districtManager.agente_id),agente:state.districtManager.agente,conductor_id:state.districtManager.conductor_id||null,conductor:state.districtManager.conductor||null,auxiliar_1_id:state.districtManager.auxiliar_1_id||null,auxiliar_1:state.districtManager.auxiliar_1||null,auxiliar_2_id:state.districtManager.auxiliar_2_id||null,auxiliar_2:state.districtManager.auxiliar_2||null,movil_id:state.districtManager.movil_id||null,numero_movil:state.districtManager.numero_movil||null,placa:state.districtManager.placa||null});
        saveDraft();renderManagers();
    }

    async function performDistrictSelection(districtId){
        state.pendingDistrictId=0;state.districtId=Number(districtId);$('#tdDistrict').value=String(state.districtId);
        await loadCircuitsForDistrict();
        renderDistrictCards();
        if(state.shiftId||$('#tdShift').value)await loadBoard();
        else{renderCircuitAccordion();showEmpty('Seleccione un turno para cargar los circuitos del distrito.');}
    }
    async function requestDistrictSelection(districtId){
        districtId=Number(districtId);if(!districtId||districtId===state.districtId)return;
        if(state.dirty&&state.districtId){state.pendingDistrictId=districtId;$('#tdUnsavedMessage').textContent=`Tiene cambios sin guardar en ${state.board?.distrito?.nombre||districtSummary(state.districtId)?.nombre||'el distrito seleccionado'}.`;openModal('tdUnsavedModal');return;}
        await performDistrictSelection(districtId);
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
        if(!resourcesComplete(state.districtManager))return notify('Complete móvil, conductor y auxiliar 1 del encargado de distrito.',true);
        for(const [circuitId,item] of state.circuitManagers.entries()){
            if(!item.agente_id)return notify(`Seleccione el encargado de ${circuitName(circuitId)}.`,true);
            if(!resourcesComplete(item))return notify(`Complete móvil, conductor y auxiliar 1 de ${circuitName(circuitId)}.`,true);
            const people=[item.agente_id,item.conductor_id,item.auxiliar_1_id,item.auxiliar_2_id].filter(Boolean).map(Number);
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
                distrito_movil_id:state.districtManager?.movil_id||null,distrito_conductor_id:state.districtManager?.conductor_id||null,
                distrito_auxiliar_1_id:state.districtManager?.auxiliar_1_id||null,distrito_auxiliar_2_id:state.districtManager?.auxiliar_2_id||null,
                encargados_circuito:Array.from(state.circuitManagers.entries()).map(([circuito_id,item])=>({circuito_id:Number(circuito_id),usar_encargado_distrito:Boolean(item.usar_encargado_distrito),agente_id:Number(item.agente_id),conductor_id:item.conductor_id||null,auxiliar_1_id:item.auxiliar_1_id||null,auxiliar_2_id:item.auxiliar_2_id||null,movil_id:item.movil_id||null,tipo_asignacion:item.tipo_asignacion||'MANUAL'})),
                encargados_ruta:Array.from(state.routeManagers.entries()).map(([ruta_id,item])=>({ruta_id:Number(ruta_id),requiere_encargado:Boolean(item.requiere_encargado),agente_id:item.agente_id || null,tipo_asignacion:item.tipo_asignacion || 'MANUAL'})),
                asignaciones:state.assignments.map(({lugar_id,agente_id,tipo_asignacion})=>({lugar_id,agente_id,tipo_asignacion}))
            }});
            state.saved = await api(`distribucion-tablero/distribuciones/${saved.id}`);
            state.editingId = Number(saved.id);state.dirty=false;renderSaveState();
            sessionStorage.removeItem(draftKey()); closeModal('tdSaveModal'); closeModal('tdPendingModal'); renderSaved(); openModal('tdResultModal');
            notify(saved.pendientes ? `Distribucion guardada. Quedaron ${saved.pendientes} puestos pendientes.` : 'Distribucion guardada correctamente.');
            await loadDistrictSummaries();
            if(state.pendingDistrictId){const next=state.pendingDistrictId;state.pendingDistrictId=0;closeModal('tdResultModal');await performDistrictSelection(next);}
            return true;
        } catch (error) { notify(error.message, true); return false; }
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
    $('#tdShift').addEventListener('change', loadBoard); $('#tdBoardDate').addEventListener('change',async()=>{await loadDistrictSummaries();if(state.districtId)await loadBoard();});
    $('#tdDistrictCards')?.addEventListener('click',event=>{const detail=event.target.closest('[data-district-detail]');if(detail){event.stopPropagation();const summary=districtSummary(detail.dataset.districtDetail);if(summary)renderPendingDetail(summary);return;}const card=event.target.closest('[data-district-card]');if(card)requestDistrictSelection(card.dataset.districtCard);});
    $('#tdCircuitAccordion')?.addEventListener('click',event=>{const button=event.target.closest('[data-circuit-toggle]');if(!button)return;$('#tdCircuit').value=button.dataset.circuitToggle;applyCircuitFilter();});
    $('#tdRouteSearch').addEventListener('input', renderRoutes); $('#tdRouteList').addEventListener('click', event => { const item = event.target.closest('[data-route-id]'); if (item) selectRoute(Number(item.dataset.routeId)); });
    $('#tdPlacesBody').addEventListener('click', event => {
        const assign = event.target.closest('[data-assign-place]'); const change = event.target.closest('[data-change-agent]'); const remove = event.target.closest('[data-remove-agent]'); const manage = event.target.closest('[data-manage-place]');
        const reqMinus = event.target.closest('[data-req-minus]'); const reqPlus = event.target.closest('[data-req-plus]');
        if (assign) openAgentSelector(assign.dataset.assignPlace);
        if (change) openAgentSelector(change.dataset.placeId, change.dataset.changeAgent);
        if (remove) removeAgent(remove.dataset.placeId, remove.dataset.removeAgent);
        if (manage) openManageAgents(Number(manage.dataset.managePlace));
        if (reqMinus) updatePlaceRequirement(reqMinus.dataset.reqMinus, -1);
        if (reqPlus) updatePlaceRequirement(reqPlus.dataset.reqPlus, 1);
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
    $('#tdEditDistrictResources')?.addEventListener('click',openDistrictResourceEditor);
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
    $('#tdDiscardDistrict')?.addEventListener('click',async()=>{const next=state.pendingDistrictId;sessionStorage.removeItem(draftKey());state.dirty=false;closeModal('tdUnsavedModal');if(next)await performDistrictSelection(next);});
    $('#tdSaveAndSwitchDistrict')?.addEventListener('click',()=>{closeModal('tdUnsavedModal');openSave();});
    $('#tdDistributionDate').addEventListener('change', event => { $('#tdGeneratedName').textContent = `DISTRIBUCION DE PERSONAL FECHA ${formatDate(event.target.value)}`; });
    $('#tdConfirmSave').addEventListener('click', requestSave); $('#tdForceSave')?.addEventListener('click', requestSave);
    $$('[data-close]').forEach(button => button.addEventListener('click', () => {if(button.dataset.close==='tdUnsavedModal')state.pendingDistrictId=0;closeModal(button.dataset.close);}));
    $$('.td-modal').forEach(modal => modal.addEventListener('click', event => { if (event.target === modal) {if(modal.id==='tdUnsavedModal')state.pendingDistrictId=0;closeModal(modal.id);} }));
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
    if (catalogs.turnos?.length && !$('#tdShift').value) $('#tdShift').value = String(catalogs.turnos[0].id);

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
    state.shiftId=Number($('#tdShift').value||0);loadDistrictSummaries();
    if (($('#tdDistrict').value && $('#tdShift').value) || (preDistrict && preShift)) {loadCircuitsForDistrict().then(loadBoard);}
})();
