<?php

namespace App\Modules\Cartillas;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class CartillasController
{
    public function index(?string $error = null, ?string $success = null): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $eas = [];
        $catalogs = [];
        $assignments = [];
        $tempCp = '';
        $chief = '';
        $preview = $_POST['contenido'] ?? '';
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $eas = $api->get('cartillas/eas')['datos'] ?? [];
            $catalogs = $api->get('cartillas/catalogos-operativos')['datos'] ?? [];
            $assignments = $api->get('cartillas/asignaciones-eas-moviles')['datos'] ?? [];
            $tempCp = $api->get('cartillas/temp/cp')['datos']['nombreCp'] ?? '';
            $chief = $api->get('cartillas/jefe-control-municipal')['datos']['nombre'] ?? '';
        } catch (\Throwable $exception) {
            $error = $error ?? $exception->getMessage();
        }

        View::render('cartillas/index', [
            'title' => 'Cartillas',
            'eas' => $eas,
            'catalogs' => $catalogs,
            'assignments' => $assignments,
            'tempCp' => $tempCp,
            'chief' => $chief,
            'preview' => $preview,
            'error' => $error,
            'success' => $success,
        ]);
    }

    public function store(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $causa = trim($_POST['causa'] ?? '');
        $contenido = trim($_POST['contenido'] ?? '');
        if ($contenido === '') {
            $contenido = $this->buildInstitutionalText($_POST);
        }

        if ($contenido === '') {
            $this->index('El contenido de la cartilla es obligatorio.');
            return;
        }

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $response = $api->post('cartillas', [
                'causa' => $causa,
                'contenido' => $contenido,
                'tipo' => trim($_POST['tipo_servicio'] ?? ''),
                'subtipo' => trim($_POST['tipo_cartilla'] ?? ''),
                'datos' => array_filter($_POST, static fn($key) => !in_array($key, ['contenido'], true), ARRAY_FILTER_USE_KEY),
            ]);
            $_POST['contenido'] = $contenido;
            if (!empty($_POST['cp'])) $api->put('cartillas/temp/cp',['nombreCp'=>trim($_POST['cp'])]);

            $total = $response['total_cartillas_generadas'] ?? null;
            $message = $total === null
                ? 'Cartilla generada correctamente.'
                : "Cartilla generada correctamente. Total: {$total}";
            $this->index(null, $message);
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    private function buildInstitutionalText(array $input): string
    {
        $momento = $this->greeting();
        $distrito = strtoupper(trim($input['distrito'] ?? 'MODELO'));
        $circuito = trim($input['circuito'] ?? $input['eas_nombre'] ?? 'EAS');
        $horario = trim($input['horario'] ?? 'Automático');
        $direccion = trim($input['direccion'] ?? '');
        $causa = trim($input['causa'] ?? 'Novedades');
        $procedimiento = trim($input['procedimiento'] ?? '');
        $movil = trim($input['movil'] ?? '');
        $cp = trim($input['cp'] ?? '');
        $jp = trim($input['jp'] ?? '');
        $policia = trim($input['policia'] ?? '');

        $fecha = date('d/m/Y');
        $hora = date('H:i');
        $puntoMartillo = stripos($causa, 'ausent') === false && $direccion !== ''
            ? " Se procedió con punto martillo en la calle {$direccion}."
            : '';

        if ($procedimiento === '') {
            $procedimiento = $this->procedureByCause($causa, $momento, $direccion, $puntoMartillo, $input);
        }

        $movilLine = $movil !== '' ? "\n\nMóvil {$movil}" : '';
        $policiaLine = $policia !== '' ? "\n*POLICÍA:* {$policia}" : '';

        return "*CUERPO DE AGENTES DE CONTROL MUNICIPAL*\n\n"
            . "*DISTRITO:* {$distrito}\n"
            . "*CIRCUITO:* {$circuito}\n"
            . "*HORARIO:* {$horario}\n"
            . "*HORA:* {$hora}\n"
            . "*FECHA:* {$fecha}\n"
            . "*DIRECCIÓN:* {$direccion}\n\n"
            . "*CAUSA:* {$causa}\n\n"
            . "*PROCEDIMIENTO:*\n\n"
            . "{$procedimiento}\n\n"
            . "Notifico novedades para fines correspondientes."
            . "{$movilLine}\n\n"
            . "*REPORTA:*\n\n"
            . "*CP:* {$cp}\n"
            . "*JP:* {$jp}"
            . "{$policiaLine}\n\n"
            . "\"Lealtad, Valor y Orden\"\n\n"
            . "Adjunto fotografía";
    }

    private function greeting(): string
    {
        $hour = (int) date('G');
        if ($hour >= 6 && $hour < 12) {
            return 'buenos días';
        }
        if ($hour >= 12 && $hour < 19) {
            return 'buenas tardes';
        }
        return 'buenas noches';
    }

    private function procedureByCause(string $causa, string $momento, string $direccion, string $puntoMartillo, array $input): string
    {
        $base = "Muy {$momento}, Sr. Maldonado Cabrera Freddy, Jefe de Control Municipal, muy respetuosamente me permito informarle que";
        $cause = strtolower($causa);
        $detalle = trim($input['detalle'] ?? '');
        $lugar = $direccion !== '' ? " en la dirección {$direccion}" : "";

        if (str_contains($cause, 'desalojo')) {
            return "{$base} durante el recorrido preventivo se evidenció la presencia de vendedores ocupando el espacio público{$lugar}, por lo que se procedió a dialogar de manera respetuosa, indicando la normativa vigente y solicitando el retiro voluntario del lugar. La intervención se desarrolló sin novedades adicionales, manteniendo presencia preventiva en el sector.{$puntoMartillo}";
        }

        if (str_contains($cause, 'retiro')) {
            return "{$base} se realizó el retiro temporal correspondiente{$lugar}, verificando previamente las condiciones del sitio y coordinando la actuación de forma ordenada para precautelar la seguridad ciudadana y el uso adecuado del espacio público.{$puntoMartillo}";
        }

        if (str_contains($cause, 'requerimiento')) {
            return "{$base} se atendió un requerimiento ciudadano/institucional{$lugar}, tomando contacto con las partes involucradas y brindando la colaboración operativa necesaria conforme a las competencias del Cuerpo de Agentes de Control Municipal.{$puntoMartillo}";
        }

        if (str_contains($cause, 'ronda')) {
            return "{$base} se ejecutaron rondas disuasivas{$lugar}, manteniendo presencia preventiva, verificando puntos sensibles y observando el normal desarrollo de las actividades en el sector asignado.{$puntoMartillo}";
        }

        if (str_contains($cause, 'entidades')) {
            return "{$base} se brindó colaboración operativa a otras entidades{$lugar}, acompañando el procedimiento solicitado y manteniendo presencia institucional hasta la culminación de la novedad, sin registrarse incidentes adicionales.{$puntoMartillo}";
        }

        if (str_contains($cause, 'ciudadana')) {
            return "{$base} se brindó colaboración ciudadana{$lugar}, orientando a la persona requirente y realizando las gestiones operativas necesarias dentro del ámbito de competencia institucional.{$puntoMartillo}";
        }

        if (str_contains($cause, 'accidente')) {
            $extra = $detalle !== '' ? " Según lo informado, {$detalle}." : "";
            return "{$base} se tomó conocimiento de un accidente{$lugar}, verificando la situación en territorio y precautelando el área mientras se coordinaba la atención correspondiente con las entidades competentes.{$extra} Se mantuvo presencia preventiva hasta normalizar la novedad.";
        }

        if (str_contains($cause, 'robo')) {
            $extra = $detalle !== '' ? " De acuerdo con la información recabada, {$detalle}." : "";
            return "{$base} se tomó conocimiento de una alerta relacionada con presunto robo{$lugar}, por lo que se mantuvo presencia preventiva, se verificó la novedad y se orientó a la persona afectada para la coordinación con las entidades competentes.{$extra}";
        }

        if (str_contains($cause, 'extorsi')) {
            $extra = $detalle !== '' ? " La novedad referida indica {$detalle}." : "";
            return "{$base} se recibió información relacionada con una presunta extorsión{$lugar}, manteniendo reserva y orientando a la persona involucrada sobre la canalización correspondiente con las autoridades competentes.{$extra}";
        }

        if (str_contains($cause, 'amenaza')) {
            $extra = $detalle !== '' ? " Como antecedente se indicó que {$detalle}." : "";
            return "{$base} se atendió una novedad por amenazas{$lugar}, brindando acompañamiento preventivo y recomendando a la persona afectada formalizar la denuncia respectiva ante la entidad competente.{$extra}";
        }

        if (str_contains($cause, 'desapar')) {
            $extra = $detalle !== '' ? " La información proporcionada señala que {$detalle}." : "";
            return "{$base} se tomó conocimiento sobre la presunta desaparición de una persona{$lugar}, por lo que se orientó a los ciudadanos respecto al procedimiento correspondiente y se dejó constancia de la novedad para fines pertinentes.{$extra}";
        }

        if (str_contains($cause, 'agresi')) {
            $extra = $detalle !== '' ? " Según lo indicado en sitio, {$detalle}." : "";
            return "{$base} se verificó una novedad relacionada con agresión{$lugar}, manteniendo presencia preventiva, procurando separar a las partes involucradas y coordinando la atención correspondiente según la situación observada.{$extra}";
        }

        if (str_contains($cause, 'cámara') || str_contains($cause, 'camara')) {
            $extra = $detalle !== '' ? " Durante la revisión se observó que {$detalle}." : "";
            return "{$base} se realizó visualización de cámaras relacionada con la novedad reportada{$lugar}, revisando la información disponible y dejando constancia de los detalles relevantes para conocimiento superior.{$extra}";
        }

        if (str_contains($cause, 'ausent')) {
            $extra = $detalle !== '' ? " El motivo indicado corresponde a {$detalle}." : "";
            return "{$base} se registra permiso de ausentismo del servidor correspondiente, dejando constancia de la novedad para conocimiento superior y fines administrativos.{$extra}";
        }

        if (str_contains($cause, 'martillo')) {
            return "{$base} durante el servicio asignado se mantuvo presencia preventiva{$lugar}, verificando el orden en el sector y realizando acciones disuasivas conforme a las disposiciones operativas.{$puntoMartillo}";
        }

        return "{$base} durante el servicio establecido se verificó la novedad correspondiente a {$causa}{$lugar}.{$puntoMartillo}";
    }
}
