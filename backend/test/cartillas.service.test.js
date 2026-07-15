const test = require('node:test');
const assert = require('node:assert/strict');
const { validarConductor, validarAccesoEspecial } = require('../src/validators/cartillas.validator');

const valid = {
    cedula_ultimos_4: '0191',
    opcion: 'ENTRADA_PERSONAL',
    kilometraje: 11216
};

test('acepta datos válidos y conserva ceros iniciales', () => {
    assert.doesNotThrow(() => validarConductor(valid));
});

for (const cedula of ['123', '12345', '12A4']) {
    test(`rechaza cédula inválida ${cedula}`, () => {
        assert.throws(() => validarConductor({ ...valid, cedula_ultimos_4: cedula }));
    });
}

test('rechaza opción fuera del catálogo', () => {
    assert.throws(() => validarConductor({ ...valid, opcion: 'OTRA' }));
});

test('rechaza kilometraje negativo o vacío', () => {
    assert.throws(() => validarConductor({ ...valid, kilometraje: -1 }));
    assert.throws(() => validarConductor({ ...valid, kilometraje: '' }));
});

test('aplica roles especiales en backend', () => {
    assert.doesNotThrow(() => validarAccesoEspecial('FORMACION', 'RADIOPERADOR_SEGURA_EP'));
    assert.throws(() => validarAccesoEspecial('FORMACION', 'PERSONAL_OPERATIVO'));
    assert.throws(() => validarAccesoEspecial('CONDUCTOR', 'AUDITORIA'));
    assert.doesNotThrow(() => validarAccesoEspecial('CONDUCTOR', 'OPERACIONES'));
});
