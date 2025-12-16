import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'SiteVoice AI'**
  String get app_name;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Stop typing. Speak.'**
  String get tagline;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgot_password;

  /// No description provided for @reset_password.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get reset_password;

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get email_required;

  /// No description provided for @password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get password_required;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalid_email;

  /// No description provided for @weak_password.
  ///
  /// In en, this message translates to:
  /// **'Password too weak'**
  String get weak_password;

  /// No description provided for @welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nSiteVoice AI'**
  String get welcome_title;

  /// No description provided for @welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'The smart voice assistant\nfor your field reports'**
  String get welcome_subtitle;

  /// No description provided for @what_is_your_name.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get what_is_your_name;

  /// No description provided for @your_first_name.
  ///
  /// In en, this message translates to:
  /// **'Your first name'**
  String get your_first_name;

  /// No description provided for @import_contacts_title.
  ///
  /// In en, this message translates to:
  /// **'Quick Import'**
  String get import_contacts_title;

  /// No description provided for @import_contacts_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Import your client contacts\nto get started quickly'**
  String get import_contacts_subtitle;

  /// No description provided for @import_contacts_button.
  ///
  /// In en, this message translates to:
  /// **'Import my contacts'**
  String get import_contacts_button;

  /// No description provided for @import_contacts_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional - You can do this later'**
  String get import_contacts_optional;

  /// No description provided for @contacts_imported.
  ///
  /// In en, this message translates to:
  /// **'{count} contacts imported'**
  String contacts_imported(int count);

  /// No description provided for @referral_code_title.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referral_code_title;

  /// No description provided for @referral_code_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Got invited by a colleague?'**
  String get referral_code_subtitle;

  /// No description provided for @referral_code_description.
  ///
  /// In en, this message translates to:
  /// **'Enter their referral code\nto get 1 FREE MONTH'**
  String get referral_code_description;

  /// No description provided for @referral_code_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Ex: JOHN-8392'**
  String get referral_code_placeholder;

  /// No description provided for @referral_code_benefit.
  ///
  /// In en, this message translates to:
  /// **'You and your colleague get 1 free month'**
  String get referral_code_benefit;

  /// No description provided for @language_selection_title.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language_selection_title;

  /// No description provided for @language_selection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get language_selection_subtitle;

  /// No description provided for @start_recording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get start_recording;

  /// No description provided for @stop_recording.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop_recording;

  /// No description provided for @pause_recording.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause_recording;

  /// No description provided for @resume_recording.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume_recording;

  /// No description provided for @recording_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String recording_duration(String duration);

  /// No description provided for @recording_limit_warning.
  ///
  /// In en, this message translates to:
  /// **'Limit: 10 minutes'**
  String get recording_limit_warning;

  /// No description provided for @recording_saved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved successfully'**
  String get recording_saved;

  /// No description provided for @recording_error.
  ///
  /// In en, this message translates to:
  /// **'Recording error'**
  String get recording_error;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @new_job.
  ///
  /// In en, this message translates to:
  /// **'New Job'**
  String get new_job;

  /// No description provided for @job_details.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get job_details;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @total_amount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get total_amount;

  /// No description provided for @status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get status_pending;

  /// No description provided for @status_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get status_processing;

  /// No description provided for @status_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get status_completed;

  /// No description provided for @status_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get status_failed;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @invoicing.
  ///
  /// In en, this message translates to:
  /// **'Invoicing'**
  String get invoicing;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @revenue_this_month.
  ///
  /// In en, this message translates to:
  /// **'Revenue this month'**
  String get revenue_this_month;

  /// No description provided for @interventions.
  ///
  /// In en, this message translates to:
  /// **'Interventions'**
  String get interventions;

  /// No description provided for @average_time.
  ///
  /// In en, this message translates to:
  /// **'Average time'**
  String get average_time;

  /// No description provided for @satisfaction.
  ///
  /// In en, this message translates to:
  /// **'Satisfaction'**
  String get satisfaction;

  /// No description provided for @recent_activity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recent_activity;

  /// No description provided for @free_limit_reached.
  ///
  /// In en, this message translates to:
  /// **'Free limit reached!'**
  String get free_limit_reached;

  /// No description provided for @free_limit_message.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your 3 trial reports.\nUpgrade to Premium to keep saving time!'**
  String get free_limit_message;

  /// No description provided for @upgrade_to_premium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgrade_to_premium;

  /// No description provided for @price_per_month.
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String price_per_month(String price);

  /// No description provided for @no_commitment.
  ///
  /// In en, this message translates to:
  /// **'No commitment'**
  String get no_commitment;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @unlimited_reports.
  ///
  /// In en, this message translates to:
  /// **'Unlimited reports'**
  String get unlimited_reports;

  /// No description provided for @ai_transcription.
  ///
  /// In en, this message translates to:
  /// **'AI Transcription'**
  String get ai_transcription;

  /// No description provided for @automatic_invoicing.
  ///
  /// In en, this message translates to:
  /// **'Automatic invoicing'**
  String get automatic_invoicing;

  /// No description provided for @realtime_sync.
  ///
  /// In en, this message translates to:
  /// **'Realtime sync'**
  String get realtime_sync;

  /// No description provided for @priority_support.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get priority_support;

  /// No description provided for @not_ready_yet.
  ///
  /// In en, this message translates to:
  /// **'Not ready yet?'**
  String get not_ready_yet;

  /// No description provided for @refer_friend_earn_month.
  ///
  /// In en, this message translates to:
  /// **'Refer a colleague → 1 free month for both!'**
  String get refer_friend_earn_month;

  /// No description provided for @my_referral_code.
  ///
  /// In en, this message translates to:
  /// **'My referral code'**
  String get my_referral_code;

  /// No description provided for @share_code.
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get share_code;

  /// No description provided for @referral_stats.
  ///
  /// In en, this message translates to:
  /// **'Referral stats'**
  String get referral_stats;

  /// No description provided for @total_referrals.
  ///
  /// In en, this message translates to:
  /// **'Total referrals'**
  String get total_referrals;

  /// No description provided for @pending_referrals.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending_referrals;

  /// No description provided for @converted_referrals.
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get converted_referrals;

  /// No description provided for @months_earned.
  ///
  /// In en, this message translates to:
  /// **'Months earned'**
  String get months_earned;

  /// No description provided for @invite_colleague.
  ///
  /// In en, this message translates to:
  /// **'Invite a colleague'**
  String get invite_colleague;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @network_error.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get network_error;

  /// No description provided for @permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permission_denied;

  /// No description provided for @microphone_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record'**
  String get microphone_permission_required;

  /// No description provided for @location_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get location_permission_required;

  /// No description provided for @contacts_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is required'**
  String get contacts_permission_required;

  /// No description provided for @unknown_error.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknown_error;

  /// No description provided for @saved_successfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saved_successfully;

  /// No description provided for @deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deleted_successfully;

  /// No description provided for @updated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get updated_successfully;

  /// No description provided for @referral_code_applied.
  ///
  /// In en, this message translates to:
  /// **'Referral code validated! 1 month offered'**
  String get referral_code_applied;

  /// No description provided for @currency_symbol.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get currency_symbol;

  /// No description provided for @currency_format.
  ///
  /// In en, this message translates to:
  /// **'{symbol}{amount}'**
  String currency_format(String symbol, String amount);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
