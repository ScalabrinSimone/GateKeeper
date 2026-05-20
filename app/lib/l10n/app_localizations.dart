import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'GateKeeper'**
  String get appName;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @objects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get objects;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @allSecure.
  ///
  /// In en, this message translates to:
  /// **'ALL SECURE'**
  String get allSecure;

  /// No description provided for @hazardsDetected.
  ///
  /// In en, this message translates to:
  /// **'Hazards Detected'**
  String get hazardsDetected;

  /// No description provided for @unresolvedAlerts.
  ///
  /// In en, this message translates to:
  /// **'ALERTS TO RESOLVE'**
  String get unresolvedAlerts;

  /// No description provided for @usersInside.
  ///
  /// In en, this message translates to:
  /// **'Users Inside'**
  String get usersInside;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last sighting'**
  String get lastSeen;

  /// No description provided for @systemSmooth.
  ///
  /// In en, this message translates to:
  /// **'System is running smoothly via Raspberry Pi 4.'**
  String get systemSmooth;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'ADD TAG'**
  String get addTag;

  /// No description provided for @liveEvents.
  ///
  /// In en, this message translates to:
  /// **'Live Events'**
  String get liveEvents;

  /// No description provided for @fullHistory.
  ///
  /// In en, this message translates to:
  /// **'VIEW FULL HISTORY'**
  String get fullHistory;

  /// No description provided for @markResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get markResolved;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @inside.
  ///
  /// In en, this message translates to:
  /// **'INSIDE'**
  String get inside;

  /// No description provided for @outside.
  ///
  /// In en, this message translates to:
  /// **'OUTSIDE'**
  String get outside;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'PICKED UP'**
  String get pickedUp;

  /// No description provided for @outOfReach.
  ///
  /// In en, this message translates to:
  /// **'OUT OF REACH'**
  String get outOfReach;

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get inviteMember;

  /// No description provided for @manageFamily.
  ///
  /// In en, this message translates to:
  /// **'Manage family access and permissions.'**
  String get manageFamily;

  /// No description provided for @monitorObjects.
  ///
  /// In en, this message translates to:
  /// **'Check which objects are currently inside or outside.'**
  String get monitorObjects;

  /// No description provided for @configureHub.
  ///
  /// In en, this message translates to:
  /// **'Configure your GateKeeper hardware hub.'**
  String get configureHub;

  /// No description provided for @raspberryPairing.
  ///
  /// In en, this message translates to:
  /// **'Raspberry Pi Pairing'**
  String get raspberryPairing;

  /// No description provided for @wifiHome.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Home'**
  String get wifiHome;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @activeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Active for entries & risks'**
  String get activeNotifications;

  /// No description provided for @audioHub.
  ///
  /// In en, this message translates to:
  /// **'Audio Hub'**
  String get audioHub;

  /// No description provided for @doorBeeper.
  ///
  /// In en, this message translates to:
  /// **'Door beeper volume'**
  String get doorBeeper;

  /// No description provided for @databaseBackup.
  ///
  /// In en, this message translates to:
  /// **'Database & Backup'**
  String get databaseBackup;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: 2h ago'**
  String get lastBackup;

  /// No description provided for @firmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get firmware;

  /// No description provided for @profileInfo.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInfo;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @searchEvents.
  ///
  /// In en, this message translates to:
  /// **'Search events...'**
  String get searchEvents;

  /// No description provided for @viewDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get viewDay;

  /// No description provided for @viewWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get viewWeek;

  /// No description provided for @viewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get viewMonth;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @activeSessions.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessions;

  /// No description provided for @mfaActive.
  ///
  /// In en, this message translates to:
  /// **'MFA Active'**
  String get mfaActive;

  /// No description provided for @onlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get onlineNow;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNotifications;

  /// No description provided for @appPreferences.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferences;

  /// No description provided for @connectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get connectivity;

  /// No description provided for @notificationsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Alerts'**
  String get notificationsAlerts;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @italian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get italian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @monitorMovements.
  ///
  /// In en, this message translates to:
  /// **'Monitor every registered movement.'**
  String get monitorMovements;

  /// No description provided for @stayUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stay updated on critical events.'**
  String get stayUpdated;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get noEvents;

  /// No description provided for @objectsTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check which objects are currently inside or outside.'**
  String get objectsTitleSubtitle;

  /// No description provided for @tagShort.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tagShort;

  /// No description provided for @logShort.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logShort;

  /// No description provided for @permissionsShort.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsShort;

  /// No description provided for @exportLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPORT'**
  String get exportLabel;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get statusWarning;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Via Roma, 12 - Milano'**
  String get address;

  /// No description provided for @raspberryHub.
  ///
  /// In en, this message translates to:
  /// **'Raspberry Pi 4'**
  String get raspberryHub;

  /// No description provided for @cpuTemp.
  ///
  /// In en, this message translates to:
  /// **'CPU Temp'**
  String get cpuTemp;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'LOGS'**
  String get logs;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @navHistoryShort.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get navHistoryShort;

  /// No description provided for @alertsHint.
  ///
  /// In en, this message translates to:
  /// **'Important alerts from the system.'**
  String get alertsHint;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to GateKeeper'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to an existing home or set up a new Raspberry hub.'**
  String get welcomeSubtitle;

  /// No description provided for @signInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInAction;

  /// No description provided for @pairAction.
  ///
  /// In en, this message translates to:
  /// **'Start setup'**
  String get pairAction;

  /// No description provided for @haveInvite.
  ///
  /// In en, this message translates to:
  /// **'I have an invite code'**
  String get haveInvite;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your hub'**
  String get discoverTitle;

  /// No description provided for @noHubFound.
  ///
  /// In en, this message translates to:
  /// **'No hub found. Make sure the Raspberry is on and on the same Wi-Fi network.'**
  String get noHubFound;

  /// No description provided for @factoryResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Factory reset'**
  String get factoryResetTitle;

  /// No description provided for @factoryResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? Users, devices, logs and events will be erased.'**
  String get factoryResetConfirm;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get openApp;

  /// No description provided for @joinHome.
  ///
  /// In en, this message translates to:
  /// **'Join the home'**
  String get joinHome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
