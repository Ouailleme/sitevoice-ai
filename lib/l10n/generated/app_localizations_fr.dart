import 'app_localizations.dart';

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get app_name => 'SiteVoice AI';

  @override
  String get tagline => 'Arrêtez de taper. Parlez.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get finish => 'Terminer';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get warning => 'Attention';

  @override
  String get confirm => 'Confirmer';

  @override
  String get login => 'Connexion';

  @override
  String get signup => 'Inscription';

  @override
  String get logout => 'Déconnexion';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgot_password => 'Mot de passe oublié ?';

  @override
  String get reset_password => 'Réinitialiser le mot de passe';

  @override
  String get email_required => 'L\'email est requis';

  @override
  String get password_required => 'Le mot de passe est requis';

  @override
  String get invalid_email => 'Adresse email invalide';

  @override
  String get weak_password => 'Mot de passe trop faible';

  @override
  String get welcome_title => 'Bienvenue sur\nSiteVoice AI';

  @override
  String get welcome_subtitle => 'L\'assistant vocal intelligent\npour vos rapports d\'intervention';

  @override
  String get what_is_your_name => 'Comment vous appelez-vous ?';

  @override
  String get your_first_name => 'Votre prénom';

  @override
  String get import_contacts_title => 'Import rapide';

  @override
  String get import_contacts_subtitle => 'Importez vos contacts clients\npour démarrer rapidement';

  @override
  String get import_contacts_button => 'Importer mes contacts';

  @override
  String get import_contacts_optional => 'Optionnel - Vous pourrez le faire plus tard';

  @override
  String contacts_imported(int count) {
    return '$count contacts importés';
  }

  @override
  String get referral_code_title => 'Code parrain';

  @override
  String get referral_code_subtitle => 'Un collègue vous a invité ?';

  @override
  String get referral_code_description => 'Entrez son code parrainage\npour obtenir 1 MOIS GRATUIT';

  @override
  String get referral_code_placeholder => 'Ex : JEAN-8392';

  @override
  String get referral_code_benefit => 'Vous et votre collègue obtiendrez 1 mois gratuit';

  @override
  String get language_selection_title => 'Langue';

  @override
  String get language_selection_subtitle => 'Choisissez votre langue préférée';

  @override
  String get start_recording => 'Démarrer l\'enregistrement';

  @override
  String get stop_recording => 'Arrêter';

  @override
  String get pause_recording => 'Pause';

  @override
  String get resume_recording => 'Reprendre';

  @override
  String recording_duration(String duration) {
    return 'Durée : $duration';
  }

  @override
  String get recording_limit_warning => 'Limite : 10 minutes';

  @override
  String get recording_saved => 'Enregistrement sauvegardé';

  @override
  String get recording_error => 'Erreur d\'enregistrement';

  @override
  String get jobs => 'Interventions';

  @override
  String get new_job => 'Nouvelle intervention';

  @override
  String get job_details => 'Détails de l\'intervention';

  @override
  String get client => 'Client';

  @override
  String get description => 'Description';

  @override
  String get status => 'Statut';

  @override
  String get date => 'Date';

  @override
  String get total_amount => 'Montant total';

  @override
  String get status_pending => 'En attente';

  @override
  String get status_processing => 'En cours';

  @override
  String get status_completed => 'Terminé';

  @override
  String get status_failed => 'Échec';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get overview => 'Vue d\'ensemble';

  @override
  String get map => 'Carte';

  @override
  String get invoicing => 'Facturation';

  @override
  String get team => 'Équipe';

  @override
  String get settings => 'Paramètres';

  @override
  String get revenue_this_month => 'CA du mois';

  @override
  String get interventions => 'Interventions';

  @override
  String get average_time => 'Temps moyen';

  @override
  String get satisfaction => 'Satisfaction';

  @override
  String get recent_activity => 'Activité récente';

  @override
  String get free_limit_reached => 'Limite gratuite atteinte !';

  @override
  String get free_limit_message => 'Vous avez utilisé vos 3 rapports d\'essai.\nPassez Premium pour continuer à gagner du temps !';

  @override
  String get upgrade_to_premium => 'Passer Premium';

  @override
  String price_per_month(String price) {
    return '$price/mois';
  }

  @override
  String get no_commitment => 'Sans engagement';

  @override
  String get later => 'Plus tard';

  @override
  String get unlimited_reports => 'Rapports illimités';

  @override
  String get ai_transcription => 'Transcription IA';

  @override
  String get automatic_invoicing => 'Facturation automatique';

  @override
  String get realtime_sync => 'Sync temps réel';

  @override
  String get priority_support => 'Support prioritaire';

  @override
  String get not_ready_yet => 'Pas encore prêt ?';

  @override
  String get refer_friend_earn_month => 'Parrainez un collègue → 1 mois gratuit pour vous deux !';

  @override
  String get my_referral_code => 'Mon code de parrainage';

  @override
  String get share_code => 'Partager le code';

  @override
  String get referral_stats => 'Statistiques parrainage';

  @override
  String get total_referrals => 'Parrainages totaux';

  @override
  String get pending_referrals => 'En attente';

  @override
  String get converted_referrals => 'Convertis';

  @override
  String get months_earned => 'Mois gagnés';

  @override
  String get invite_colleague => 'Inviter un collègue';

  @override
  String get profile => 'Profil';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';

  @override
  String get network_error => 'Erreur réseau. Vérifiez votre connexion.';

  @override
  String get permission_denied => 'Permission refusée';

  @override
  String get microphone_permission_required => 'La permission microphone est nécessaire pour enregistrer';

  @override
  String get location_permission_required => 'La permission localisation est nécessaire';

  @override
  String get contacts_permission_required => 'La permission contacts est nécessaire';

  @override
  String get unknown_error => 'Une erreur inconnue s\'est produite';

  @override
  String get saved_successfully => 'Enregistré avec succès';

  @override
  String get deleted_successfully => 'Supprimé avec succès';

  @override
  String get updated_successfully => 'Mis à jour avec succès';

  @override
  String get referral_code_applied => 'Code parrainage validé ! 1 mois offert';

  @override
  String get currency_symbol => '€';

  @override
  String currency_format(String symbol, String amount) {
    return '$amount$symbol';
  }
}
