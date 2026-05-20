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
  /// **'Resolved'**
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

  /// No description provided for @markAsReadSingle.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsReadSingle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNotifications;

  /// No description provided for @noNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'All caught up! Events will appear here.'**
  String get noNotificationsHint;

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
  /// **'Stay updated on events.'**
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
  /// **'Log'**
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
  /// **'Critical alerts requiring your attention.'**
  String get alertsHint;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get noAlerts;

  /// No description provided for @noAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'The system is secure. Alerts will appear here.'**
  String get noAlertsHint;

  /// No description provided for @alertResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get alertResolved;

  /// No description provided for @alertActive.
  ///
  /// In en, this message translates to:
  /// **'Active alert'**
  String get alertActive;

  /// No description provided for @alertResolvedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Alert resolved!'**
  String get alertResolvedFeedback;

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

  /// No description provided for @entry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entry;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @risk.
  ///
  /// In en, this message translates to:
  /// **'Risk'**
  String get risk;

  /// No description provided for @noLogsForObject.
  ///
  /// In en, this message translates to:
  /// **'No logs for this object.'**
  String get noLogsForObject;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

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

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get tryAgain;

  /// No description provided for @objectCreated.
  ///
  /// In en, this message translates to:
  /// **'Object created.'**
  String get objectCreated;

  /// No description provided for @objectUpdated.
  ///
  /// In en, this message translates to:
  /// **'Object updated.'**
  String get objectUpdated;

  /// No description provided for @objectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Object deleted.'**
  String get objectDeleted;

  /// No description provided for @addObject.
  ///
  /// In en, this message translates to:
  /// **'Add object'**
  String get addObject;

  /// No description provided for @objectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No objects yet.'**
  String get objectsEmpty;

  /// No description provided for @objectName.
  ///
  /// In en, this message translates to:
  /// **'Object name'**
  String get objectName;

  /// No description provided for @objectNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the object name.'**
  String get objectNameRequired;

  /// No description provided for @rfidTagRequired.
  ///
  /// In en, this message translates to:
  /// **'Please scan or enter the RFID tag.'**
  String get rfidTagRequired;

  /// No description provided for @rfidTagLabel.
  ///
  /// In en, this message translates to:
  /// **'RFID TAG'**
  String get rfidTagLabel;

  /// No description provided for @rfidTagRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the tag by passing it in front of the reader.'**
  String get rfidTagRequiredHint;

  /// No description provided for @scanningTag.
  ///
  /// In en, this message translates to:
  /// **'Scanning... pass the tag in front of the reader.'**
  String get scanningTag;

  /// No description provided for @startScan.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get startScan;

  /// No description provided for @stopScan.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopScan;

  /// No description provided for @rescanTag.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescanTag;

  /// No description provided for @tagScanned.
  ///
  /// In en, this message translates to:
  /// **'Tag scanned'**
  String get tagScanned;

  /// No description provided for @enterTagManually.
  ///
  /// In en, this message translates to:
  /// **'Enter tag manually'**
  String get enterTagManually;

  /// No description provided for @essential.
  ///
  /// In en, this message translates to:
  /// **'Essential'**
  String get essential;

  /// No description provided for @essentialHint.
  ///
  /// In en, this message translates to:
  /// **'Generates a special alert if left without the owner.'**
  String get essentialHint;

  /// No description provided for @loadingDots.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingDots;

  /// No description provided for @editObject.
  ///
  /// In en, this message translates to:
  /// **'Edit object'**
  String get editObject;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete object'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteConfirmBody;

  /// No description provided for @customTagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get customTagName;

  /// No description provided for @customTagColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get customTagColor;

  /// No description provided for @customTagIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get customTagIcon;

  /// No description provided for @customTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom tag'**
  String get customTagTitle;

  /// No description provided for @customTagHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a name, color and icon for this tag.'**
  String get customTagHint;

  /// No description provided for @bleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth (BLE)'**
  String get bleSectionTitle;

  /// No description provided for @bleSectionExplain.
  ///
  /// In en, this message translates to:
  /// **'Associate your phone\'s Bluetooth address so the Raspberry Pi can identify who is entering or leaving.'**
  String get bleSectionExplain;

  /// No description provided for @bleRegisteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered device'**
  String get bleRegisteredTitle;

  /// No description provided for @bleNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth device registered.'**
  String get bleNotRegistered;

  /// No description provided for @bleScan.
  ///
  /// In en, this message translates to:
  /// **'Scan nearby devices'**
  String get bleScan;

  /// No description provided for @bleSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get bleSelect;

  /// No description provided for @bleRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get bleRemove;

  /// No description provided for @bleRegistered.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth device registered.'**
  String get bleRegistered;

  /// No description provided for @bleRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth device removed.'**
  String get bleRemoved;

  /// No description provided for @bleNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found nearby.'**
  String get bleNoDevices;

  /// No description provided for @bleSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Setup'**
  String get bleSetupTitle;

  /// No description provided for @bleSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Associate your phone so the system can identify you when you enter/exit.'**
  String get bleSetupSubtitle;

  /// No description provided for @bleSetupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get bleSetupSkip;

  /// No description provided for @bleSetupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get bleSetupContinue;

  /// No description provided for @remoteAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote Access'**
  String get remoteAccessTitle;

  /// No description provided for @remoteAccessExplain.
  ///
  /// In en, this message translates to:
  /// **'Save the URL of your Cloudflare Tunnel to access the hub from anywhere.'**
  String get remoteAccessExplain;

  /// No description provided for @remoteUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Remote URL (https://...)'**
  String get remoteUrlLabel;

  /// No description provided for @remoteApply.
  ///
  /// In en, this message translates to:
  /// **'Apply & reconnect'**
  String get remoteApply;

  /// No description provided for @remoteSave.
  ///
  /// In en, this message translates to:
  /// **'Save URL'**
  String get remoteSave;

  /// No description provided for @remoteClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get remoteClear;

  /// No description provided for @remoteApplied.
  ///
  /// In en, this message translates to:
  /// **'Remote URL applied.'**
  String get remoteApplied;

  /// No description provided for @reconnectHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Reconnect hub'**
  String get reconnectHubTitle;

  /// No description provided for @reconnectHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Force reconnection to the current hub.'**
  String get reconnectHubSubtitle;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @reconnectingHub.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnectingHub;

  /// No description provided for @leaveHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave home'**
  String get leaveHomeTitle;

  /// No description provided for @leaveHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this device from the home.'**
  String get leaveHomeSubtitle;

  /// No description provided for @leaveHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deleted from the server. This action cannot be undone.'**
  String get leaveHomeBody;

  /// No description provided for @leaveHomeBodyAdmin.
  ///
  /// In en, this message translates to:
  /// **'You are the admin. Leaving will perform a factory reset of the entire home.'**
  String get leaveHomeBodyAdmin;

  /// No description provided for @leaveHome.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveHome;

  /// No description provided for @houseLabel.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get houseLabel;

  /// No description provided for @pushTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushTitle;

  /// No description provided for @pushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts even when the app is closed.'**
  String get pushSubtitle;

  /// No description provided for @pushUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Push notifications not available on this device.'**
  String get pushUnsupported;

  /// No description provided for @pushRegistered.
  ///
  /// In en, this message translates to:
  /// **'Push notifications enabled.'**
  String get pushRegistered;

  /// No description provided for @profileSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSectionTitle;

  /// No description provided for @changeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change username'**
  String get changeUsername;

  /// No description provided for @newUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'New username'**
  String get newUsernameLabel;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @newEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get newEmailLabel;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get newPasswordMin;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password.'**
  String get changePasswordSubtitle;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdated;

  /// No description provided for @emailChangedVerify.
  ///
  /// In en, this message translates to:
  /// **'Email changed. Please verify the new address.'**
  String get emailChangedVerify;

  /// No description provided for @profileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile.'**
  String get profileUpdateError;

  /// No description provided for @wrongCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get wrongCurrentPassword;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutTitle;

  /// No description provided for @logoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'End your current session.'**
  String get logoutSubtitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @factoryResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reset the entire home. Irreversible.'**
  String get factoryResetSubtitle;

  /// No description provided for @factoryResetAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Only admins can perform a factory reset.'**
  String get factoryResetAdminOnly;

  /// No description provided for @factoryResetDone.
  ///
  /// In en, this message translates to:
  /// **'Factory reset completed.'**
  String get factoryResetDone;

  /// No description provided for @pendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending Invites'**
  String get pendingInvites;

  /// No description provided for @showInviteQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get showInviteQr;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @revokedInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite revoked.'**
  String get revokedInvite;

  /// No description provided for @generateInvite.
  ///
  /// In en, this message translates to:
  /// **'Generate invite'**
  String get generateInvite;

  /// No description provided for @inviteAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get inviteAdult;

  /// No description provided for @inviteChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get inviteChild;

  /// No description provided for @noInvitesYet.
  ///
  /// In en, this message translates to:
  /// **'No invites generated yet.'**
  String get noInvitesYet;

  /// No description provided for @inviteCopiedBody.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard.'**
  String get inviteCopiedBody;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copiedToClipboard;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this member from the home?'**
  String get removeMemberConfirm;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed.'**
  String get memberRemoved;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsTitle;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @adult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get adult;

  /// No description provided for @child.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get child;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setupTitle;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @welcomeHubReady.
  ///
  /// In en, this message translates to:
  /// **'Your hub is ready.'**
  String get welcomeHubReady;

  /// No description provided for @setupTip1Title.
  ///
  /// In en, this message translates to:
  /// **'Smart Protection'**
  String get setupTip1Title;

  /// No description provided for @setupTip1Body.
  ///
  /// In en, this message translates to:
  /// **'GateKeeper tracks objects and people via RFID and Bluetooth.'**
  String get setupTip1Body;

  /// No description provided for @setupTip2Title.
  ///
  /// In en, this message translates to:
  /// **'Event Detection'**
  String get setupTip2Title;

  /// No description provided for @setupTip2Body.
  ///
  /// In en, this message translates to:
  /// **'The system detects every entry and exit at the door.'**
  String get setupTip2Body;

  /// No description provided for @setupTip3Title.
  ///
  /// In en, this message translates to:
  /// **'Instant Alerts'**
  String get setupTip3Title;

  /// No description provided for @setupTip3Body.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications even when the app is closed.'**
  String get setupTip3Body;

  /// No description provided for @startSetup.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startSetup;

  /// No description provided for @houseName.
  ///
  /// In en, this message translates to:
  /// **'House name'**
  String get houseName;

  /// No description provided for @adminUsername.
  ///
  /// In en, this message translates to:
  /// **'Admin username'**
  String get adminUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @factoryCode.
  ///
  /// In en, this message translates to:
  /// **'Factory code'**
  String get factoryCode;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get fillAllFields;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get invalidEmail;

  /// No description provided for @createAndPair.
  ///
  /// In en, this message translates to:
  /// **'Create and pair'**
  String get createAndPair;

  /// No description provided for @tagsStepHint.
  ///
  /// In en, this message translates to:
  /// **'Select the objects you want to track from the beginning. You can add more later.'**
  String get tagsStepHint;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @createTagsAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Create and continue'**
  String get createTagsAndContinue;

  /// No description provided for @inviteStepHint.
  ///
  /// In en, this message translates to:
  /// **'Invite family members. You can also do this later from the Members section.'**
  String get inviteStepHint;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishSetup;

  /// No description provided for @setupCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup complete!'**
  String get setupCompleteTitle;

  /// No description provided for @setupCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GateKeeper is ready to protect your home.'**
  String get setupCompleteSubtitle;

  /// No description provided for @exitSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit setup?'**
  String get exitSetupTitle;

  /// No description provided for @exitSetupBody.
  ///
  /// In en, this message translates to:
  /// **'The admin account has been created. You can continue the setup later from the Settings.'**
  String get exitSetupBody;

  /// No description provided for @exitAction.
  ///
  /// In en, this message translates to:
  /// **'Go to app'**
  String get exitAction;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyEmail;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email to complete registration.'**
  String get verifyEmailSubtitle;

  /// No description provided for @verifyEmailSend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get verifyEmailSend;

  /// No description provided for @verifyEmailSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get verifyEmailSending;

  /// No description provided for @verifyEmailCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get verifyEmailCodeHint;

  /// No description provided for @verifyEmailConfirm.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyEmailConfirm;

  /// No description provided for @verifyEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified!'**
  String get verifyEmailSuccess;

  /// No description provided for @verifyEmailError.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code.'**
  String get verifyEmailError;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerified;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRoleLabel;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get profileMemberSince;

  /// No description provided for @profileLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get profileLastSeen;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL. It must start with http:// or https://'**
  String get invalidUrl;

  /// No description provided for @remoteCleared.
  ///
  /// In en, this message translates to:
  /// **'Remote URL cleared.'**
  String get remoteCleared;

  /// No description provided for @inviteShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Invite'**
  String get inviteShareTitle;

  /// No description provided for @inviteShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share this QR code or token with the new member.'**
  String get inviteShareSubtitle;

  /// No description provided for @inviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires:'**
  String get inviteExpires;

  /// No description provided for @inviteRole.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get inviteRole;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @inviteByCode.
  ///
  /// In en, this message translates to:
  /// **'Invite with code'**
  String get inviteByCode;

  /// No description provided for @inviteBlockedRemote.
  ///
  /// In en, this message translates to:
  /// **'You cannot create new accounts while connected remotely. Return home first.'**
  String get inviteBlockedRemote;

  /// No description provided for @notifPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifPrefsTitle;

  /// No description provided for @notifOnEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry notification'**
  String get notifOnEntry;

  /// No description provided for @notifOnEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Notify me when this person/object enters.'**
  String get notifOnEntryHint;

  /// No description provided for @notifOnExit.
  ///
  /// In en, this message translates to:
  /// **'Exit notification'**
  String get notifOnExit;

  /// No description provided for @notifOnExitHint.
  ///
  /// In en, this message translates to:
  /// **'Notify me when this person/object exits.'**
  String get notifOnExitHint;

  /// No description provided for @notifTimeWindow.
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get notifTimeWindow;

  /// No description provided for @notifTimeWindowHint.
  ///
  /// In en, this message translates to:
  /// **'Always notify (no time restriction).'**
  String get notifTimeWindowHint;

  /// No description provided for @notifFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get notifFrom;

  /// No description provided for @notifTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get notifTo;

  /// No description provided for @objectsOutsideCount.
  ///
  /// In en, this message translates to:
  /// **'objects outside'**
  String get objectsOutsideCount;

  /// No description provided for @noMembers.
  ///
  /// In en, this message translates to:
  /// **'No members yet.'**
  String get noMembers;

  /// No description provided for @noObjects.
  ///
  /// In en, this message translates to:
  /// **'No objects yet.'**
  String get noObjects;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;
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
