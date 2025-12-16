import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'SiteVoice AI';

  @override
  String get tagline => 'Stop typing. Speak.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get finish => 'Finish';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get confirm => 'Confirm';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgot_password => 'Forgot password?';

  @override
  String get reset_password => 'Reset password';

  @override
  String get email_required => 'Email is required';

  @override
  String get password_required => 'Password is required';

  @override
  String get invalid_email => 'Invalid email address';

  @override
  String get weak_password => 'Password too weak';

  @override
  String get welcome_title => 'Welcome to\nSiteVoice AI';

  @override
  String get welcome_subtitle => 'The smart voice assistant\nfor your field reports';

  @override
  String get what_is_your_name => 'What\'s your name?';

  @override
  String get your_first_name => 'Your first name';

  @override
  String get import_contacts_title => 'Quick Import';

  @override
  String get import_contacts_subtitle => 'Import your client contacts\nto get started quickly';

  @override
  String get import_contacts_button => 'Import my contacts';

  @override
  String get import_contacts_optional => 'Optional - You can do this later';

  @override
  String contacts_imported(int count) {
    return '$count contacts imported';
  }

  @override
  String get referral_code_title => 'Referral Code';

  @override
  String get referral_code_subtitle => 'Got invited by a colleague?';

  @override
  String get referral_code_description => 'Enter their referral code\nto get 1 FREE MONTH';

  @override
  String get referral_code_placeholder => 'Ex: JOHN-8392';

  @override
  String get referral_code_benefit => 'You and your colleague get 1 free month';

  @override
  String get language_selection_title => 'Language';

  @override
  String get language_selection_subtitle => 'Choose your preferred language';

  @override
  String get start_recording => 'Start Recording';

  @override
  String get stop_recording => 'Stop';

  @override
  String get pause_recording => 'Pause';

  @override
  String get resume_recording => 'Resume';

  @override
  String recording_duration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get recording_limit_warning => 'Limit: 10 minutes';

  @override
  String get recording_saved => 'Recording saved successfully';

  @override
  String get recording_error => 'Recording error';

  @override
  String get jobs => 'Jobs';

  @override
  String get new_job => 'New Job';

  @override
  String get job_details => 'Job Details';

  @override
  String get client => 'Client';

  @override
  String get description => 'Description';

  @override
  String get status => 'Status';

  @override
  String get date => 'Date';

  @override
  String get total_amount => 'Total Amount';

  @override
  String get status_pending => 'Pending';

  @override
  String get status_processing => 'Processing';

  @override
  String get status_completed => 'Completed';

  @override
  String get status_failed => 'Failed';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get overview => 'Overview';

  @override
  String get map => 'Map';

  @override
  String get invoicing => 'Invoicing';

  @override
  String get team => 'Team';

  @override
  String get settings => 'Settings';

  @override
  String get revenue_this_month => 'Revenue this month';

  @override
  String get interventions => 'Interventions';

  @override
  String get average_time => 'Average time';

  @override
  String get satisfaction => 'Satisfaction';

  @override
  String get recent_activity => 'Recent activity';

  @override
  String get free_limit_reached => 'Free limit reached!';

  @override
  String get free_limit_message => 'You\'ve used your 3 trial reports.\nUpgrade to Premium to keep saving time!';

  @override
  String get upgrade_to_premium => 'Upgrade to Premium';

  @override
  String price_per_month(String price) {
    return '$price/month';
  }

  @override
  String get no_commitment => 'No commitment';

  @override
  String get later => 'Later';

  @override
  String get unlimited_reports => 'Unlimited reports';

  @override
  String get ai_transcription => 'AI Transcription';

  @override
  String get automatic_invoicing => 'Automatic invoicing';

  @override
  String get realtime_sync => 'Realtime sync';

  @override
  String get priority_support => 'Priority support';

  @override
  String get not_ready_yet => 'Not ready yet?';

  @override
  String get refer_friend_earn_month => 'Refer a colleague → 1 free month for both!';

  @override
  String get my_referral_code => 'My referral code';

  @override
  String get share_code => 'Share code';

  @override
  String get referral_stats => 'Referral stats';

  @override
  String get total_referrals => 'Total referrals';

  @override
  String get pending_referrals => 'Pending';

  @override
  String get converted_referrals => 'Converted';

  @override
  String get months_earned => 'Months earned';

  @override
  String get invite_colleague => 'Invite a colleague';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get network_error => 'Network error. Please check your connection.';

  @override
  String get permission_denied => 'Permission denied';

  @override
  String get microphone_permission_required => 'Microphone permission is required to record';

  @override
  String get location_permission_required => 'Location permission is required';

  @override
  String get contacts_permission_required => 'Contacts permission is required';

  @override
  String get unknown_error => 'An unknown error occurred';

  @override
  String get saved_successfully => 'Saved successfully';

  @override
  String get deleted_successfully => 'Deleted successfully';

  @override
  String get updated_successfully => 'Updated successfully';

  @override
  String get referral_code_applied => 'Referral code validated! 1 month offered';

  @override
  String get currency_symbol => '\$';

  @override
  String currency_format(String symbol, String amount) {
    return '$symbol$amount';
  }
}
