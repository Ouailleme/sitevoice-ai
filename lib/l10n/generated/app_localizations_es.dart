import 'app_localizations.dart';

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get app_name => 'SiteVoice AI';

  @override
  String get tagline => 'Deja de escribir. Habla.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get close => 'Cerrar';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Omitir';

  @override
  String get finish => 'Terminar';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get warning => 'Advertencia';

  @override
  String get confirm => 'Confirmar';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get signup => 'Registrarse';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get email => 'Email';

  @override
  String get password => 'Contraseña';

  @override
  String get forgot_password => '¿Olvidaste tu contraseña?';

  @override
  String get reset_password => 'Restablecer contraseña';

  @override
  String get email_required => 'El email es obligatorio';

  @override
  String get password_required => 'La contraseña es obligatoria';

  @override
  String get invalid_email => 'Dirección de email inválida';

  @override
  String get weak_password => 'Contraseña demasiado débil';

  @override
  String get welcome_title => 'Bienvenido a\nSiteVoice AI';

  @override
  String get welcome_subtitle => 'El asistente vocal inteligente\npara tus informes de campo';

  @override
  String get what_is_your_name => '¿Cómo te llamas?';

  @override
  String get your_first_name => 'Tu nombre';

  @override
  String get import_contacts_title => 'Importación rápida';

  @override
  String get import_contacts_subtitle => 'Importa tus contactos de clientes\npara comenzar rápidamente';

  @override
  String get import_contacts_button => 'Importar mis contactos';

  @override
  String get import_contacts_optional => 'Opcional - Puedes hacerlo más tarde';

  @override
  String contacts_imported(int count) {
    return '$count contactos importados';
  }

  @override
  String get referral_code_title => 'Código de referido';

  @override
  String get referral_code_subtitle => '¿Te invitó un colega?';

  @override
  String get referral_code_description => 'Introduce su código de referido\npara obtener 1 MES GRATIS';

  @override
  String get referral_code_placeholder => 'Ej: JUAN-8392';

  @override
  String get referral_code_benefit => 'Tú y tu colega obtendréis 1 mes gratis';

  @override
  String get language_selection_title => 'Idioma';

  @override
  String get language_selection_subtitle => 'Elige tu idioma preferido';

  @override
  String get start_recording => 'Iniciar grabación';

  @override
  String get stop_recording => 'Detener';

  @override
  String get pause_recording => 'Pausar';

  @override
  String get resume_recording => 'Reanudar';

  @override
  String recording_duration(String duration) {
    return 'Duración: $duration';
  }

  @override
  String get recording_limit_warning => 'Límite: 10 minutos';

  @override
  String get recording_saved => 'Grabación guardada';

  @override
  String get recording_error => 'Error de grabación';

  @override
  String get jobs => 'Trabajos';

  @override
  String get new_job => 'Nuevo trabajo';

  @override
  String get job_details => 'Detalles del trabajo';

  @override
  String get client => 'Cliente';

  @override
  String get description => 'Descripción';

  @override
  String get status => 'Estado';

  @override
  String get date => 'Fecha';

  @override
  String get total_amount => 'Importe total';

  @override
  String get status_pending => 'Pendiente';

  @override
  String get status_processing => 'En proceso';

  @override
  String get status_completed => 'Completado';

  @override
  String get status_failed => 'Fallido';

  @override
  String get dashboard => 'Panel de control';

  @override
  String get overview => 'Resumen';

  @override
  String get map => 'Mapa';

  @override
  String get invoicing => 'Facturación';

  @override
  String get team => 'Equipo';

  @override
  String get settings => 'Ajustes';

  @override
  String get revenue_this_month => 'Ingresos del mes';

  @override
  String get interventions => 'Intervenciones';

  @override
  String get average_time => 'Tiempo promedio';

  @override
  String get satisfaction => 'Satisfacción';

  @override
  String get recent_activity => 'Actividad reciente';

  @override
  String get free_limit_reached => '¡Límite gratuito alcanzado!';

  @override
  String get free_limit_message => 'Has usado tus 3 informes de prueba.\n¡Actualiza a Premium para seguir ahorrando tiempo!';

  @override
  String get upgrade_to_premium => 'Actualizar a Premium';

  @override
  String price_per_month(String price) {
    return '$price/mes';
  }

  @override
  String get no_commitment => 'Sin compromiso';

  @override
  String get later => 'Más tarde';

  @override
  String get unlimited_reports => 'Informes ilimitados';

  @override
  String get ai_transcription => 'Transcripción IA';

  @override
  String get automatic_invoicing => 'Facturación automática';

  @override
  String get realtime_sync => 'Sincronización en tiempo real';

  @override
  String get priority_support => 'Soporte prioritario';

  @override
  String get not_ready_yet => '¿Aún no estás listo?';

  @override
  String get refer_friend_earn_month => '¡Refiere a un colega → 1 mes gratis para ambos!';

  @override
  String get my_referral_code => 'Mi código de referido';

  @override
  String get share_code => 'Compartir código';

  @override
  String get referral_stats => 'Estadísticas de referidos';

  @override
  String get total_referrals => 'Referencias totales';

  @override
  String get pending_referrals => 'Pendientes';

  @override
  String get converted_referrals => 'Convertidos';

  @override
  String get months_earned => 'Meses ganados';

  @override
  String get invite_colleague => 'Invitar a un colega';

  @override
  String get profile => 'Perfil';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get privacy => 'Privacidad';

  @override
  String get about => 'Acerca de';

  @override
  String get version => 'Versión';

  @override
  String get network_error => 'Error de red. Por favor, verifica tu conexión.';

  @override
  String get permission_denied => 'Permiso denegado';

  @override
  String get microphone_permission_required => 'Se requiere permiso de micrófono para grabar';

  @override
  String get location_permission_required => 'Se requiere permiso de ubicación';

  @override
  String get contacts_permission_required => 'Se requiere permiso de contactos';

  @override
  String get unknown_error => 'Se produjo un error desconocido';

  @override
  String get saved_successfully => 'Guardado exitosamente';

  @override
  String get deleted_successfully => 'Eliminado exitosamente';

  @override
  String get updated_successfully => 'Actualizado exitosamente';

  @override
  String get referral_code_applied => '¡Código de referido validado! 1 mes ofrecido';

  @override
  String get currency_symbol => '€';

  @override
  String currency_format(String symbol, String amount) {
    return '$amount$symbol';
  }
}
