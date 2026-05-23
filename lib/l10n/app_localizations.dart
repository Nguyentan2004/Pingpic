import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PingPic'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsReadAll.
  ///
  /// In en, this message translates to:
  /// **'Read All'**
  String get notificationsReadAll;

  /// No description provided for @notificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read.'**
  String get notificationsMarkedRead;

  /// No description provided for @notificationsNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsNoNotifications;

  /// No description provided for @notificationsWeWillNotify.
  ///
  /// In en, this message translates to:
  /// **'We will notify you about updates.'**
  String get notificationsWeWillNotify;

  /// No description provided for @notificationsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsJustNow;

  /// No description provided for @notificationsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String notificationsMinutesAgo(Object count);

  /// No description provided for @notificationsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String notificationsHoursAgo(Object count);

  /// No description provided for @notificationsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String notificationsDaysAgo(Object count);

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Circle'**
  String get inviteTitle;

  /// No description provided for @inviteDesc.
  ///
  /// In en, this message translates to:
  /// **'PingPic is a private space for your real friends. Add friends to start sharing real-time moments!'**
  String get inviteDesc;

  /// No description provided for @inviteYourCode.
  ///
  /// In en, this message translates to:
  /// **'YOUR INVITE CODE'**
  String get inviteYourCode;

  /// No description provided for @inviteShareLink.
  ///
  /// In en, this message translates to:
  /// **'SHAREABLE INVITE LINK'**
  String get inviteShareLink;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied!'**
  String get inviteCodeCopied;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied!'**
  String get inviteLinkCopied;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to PingPic'**
  String get loginSubtitle;

  /// No description provided for @loginUsernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Username or Email'**
  String get loginUsernameOrEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get loginNoAccount;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(Object error);

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to share moments with friends'**
  String get registerSubtitle;

  /// No description provided for @registerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerFullName;

  /// No description provided for @registerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerEmail;

  /// No description provided for @registerUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get registerUsername;

  /// No description provided for @registerPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPassword;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get registerButton;

  /// No description provided for @registerHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get registerHasAccount;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed: {error}'**
  String registerFailed(Object error);

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @friendsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter friend\'s invite code or username...'**
  String get friendsSearchPlaceholder;

  /// No description provided for @friendsSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get friendsSearchResults;

  /// No description provided for @friendsFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendsFriendRequests;

  /// No description provided for @friendsMyFriends.
  ///
  /// In en, this message translates to:
  /// **'My Friends ({count})'**
  String friendsMyFriends(Object count);

  /// No description provided for @friendsNoFriendsDesc.
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Start adding some!'**
  String get friendsNoFriendsDesc;

  /// No description provided for @friendsWantsToBeFriends.
  ///
  /// In en, this message translates to:
  /// **'wants to be friends'**
  String get friendsWantsToBeFriends;

  /// No description provided for @friendsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAccept;

  /// No description provided for @friendsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get friendsReject;

  /// No description provided for @friendsUnfriendConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfriend'**
  String get friendsUnfriendConfirmTitle;

  /// No description provided for @friendsUnfriendConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unfriend {name}?'**
  String friendsUnfriendConfirmDesc(Object name);

  /// No description provided for @friendsUnfriendSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed {name} from friends.'**
  String friendsUnfriendSuccess(Object name);

  /// No description provided for @friendsUnfriendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unfriend.'**
  String get friendsUnfriendFailed;

  /// No description provided for @friendsInviteDesc.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your friends to connect!'**
  String get friendsInviteDesc;

  /// No description provided for @friendsInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard!'**
  String get friendsInviteCopied;

  /// No description provided for @friendsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get friendsCopy;

  /// No description provided for @friendsLastActiveJustNow.
  ///
  /// In en, this message translates to:
  /// **'Active just now'**
  String get friendsLastActiveJustNow;

  /// No description provided for @friendsLastActiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'Active {count}m ago'**
  String friendsLastActiveMinutes(Object count);

  /// No description provided for @friendsLastActiveHours.
  ///
  /// In en, this message translates to:
  /// **'Active {count}h ago'**
  String friendsLastActiveHours(Object count);

  /// No description provided for @friendsLastActiveYesterday.
  ///
  /// In en, this message translates to:
  /// **'Active yesterday'**
  String get friendsLastActiveYesterday;

  /// No description provided for @friendsLastActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active {count} days ago'**
  String friendsLastActiveDays(Object count);

  /// No description provided for @friendsOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get friendsOffline;

  /// No description provided for @friendsOnlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get friendsOnlineStatus;

  /// No description provided for @friendsOnline.
  ///
  /// In en, this message translates to:
  /// **'Friends Online'**
  String get friendsOnline;

  /// No description provided for @friendsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} friends'**
  String friendsCount(Object count);

  /// No description provided for @addFriendButton.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriendButton;

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent!'**
  String get friendRequestSent;

  /// No description provided for @friendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted!'**
  String get friendRequestAccepted;

  /// No description provided for @unfriendButton.
  ///
  /// In en, this message translates to:
  /// **'Unfriend'**
  String get unfriendButton;

  /// No description provided for @friendRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get friendRequested;

  /// No description provided for @friendAcceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept Request'**
  String get friendAcceptRequest;

  /// No description provided for @friendSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter username or share code...'**
  String get friendSearchHint;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileMomentsCount.
  ///
  /// In en, this message translates to:
  /// **'Moments'**
  String get profileMomentsCount;

  /// No description provided for @profileFriendsCount.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get profileFriendsCount;

  /// No description provided for @profileNoMoments.
  ///
  /// In en, this message translates to:
  /// **'No moments posted yet.'**
  String get profileNoMoments;

  /// No description provided for @profileNoMomentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Moments you capture will show up here.'**
  String get profileNoMomentsDesc;

  /// No description provided for @profilePrivateDesc.
  ///
  /// In en, this message translates to:
  /// **'Become friends to see their moments'**
  String get profilePrivateDesc;

  /// No description provided for @profilePrivateSub.
  ///
  /// In en, this message translates to:
  /// **'Moments shared by this user are only visible to friends.'**
  String get profilePrivateSub;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkModeSubDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to light theme'**
  String get settingsDarkModeSubDark;

  /// No description provided for @settingsDarkModeSubLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get settingsDarkModeSubLight;

  /// No description provided for @settingsAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get settingsAccountInfo;

  /// No description provided for @settingsFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get settingsFullNameLabel;

  /// No description provided for @settingsFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get settingsFullNameHint;

  /// No description provided for @settingsBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get settingsBioLabel;

  /// No description provided for @settingsBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about yourself...'**
  String get settingsBioHint;

  /// No description provided for @settingsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get settingsSaveChanges;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogoutConfirmTitle;

  /// No description provided for @settingsLogoutConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of PingPic?'**
  String get settingsLogoutConfirmDesc;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settingsAppVersion;

  /// No description provided for @settingsThemePreview.
  ///
  /// In en, this message translates to:
  /// **'Theme Preview'**
  String get settingsThemePreview;

  /// No description provided for @settingsPreviewCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Nguyễn Nhật Tân'**
  String get settingsPreviewCardTitle;

  /// No description provided for @settingsPreviewCardTime.
  ///
  /// In en, this message translates to:
  /// **'5m ago'**
  String get settingsPreviewCardTime;

  /// No description provided for @settingsPreviewCardCaption.
  ///
  /// In en, this message translates to:
  /// **'Living in the moment! 🍊'**
  String get settingsPreviewCardCaption;

  /// No description provided for @cameraShareMoment.
  ///
  /// In en, this message translates to:
  /// **'Share a Moment'**
  String get cameraShareMoment;

  /// No description provided for @cameraBroadcastDesc.
  ///
  /// In en, this message translates to:
  /// **'Broadcast a photo to your entire circle'**
  String get cameraBroadcastDesc;

  /// No description provided for @cameraUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload from Device'**
  String get cameraUploadPhoto;

  /// No description provided for @cameraTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get cameraTakePhoto;

  /// No description provided for @cameraAddCaption.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get cameraAddCaption;

  /// No description provided for @cameraSharingWithCircle.
  ///
  /// In en, this message translates to:
  /// **'Sharing with your circle: '**
  String get cameraSharingWithCircle;

  /// No description provided for @cameraSendToFriends.
  ///
  /// In en, this message translates to:
  /// **'Send to Friends'**
  String get cameraSendToFriends;

  /// No description provided for @cameraSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get cameraSending;

  /// No description provided for @cameraPhotoSent.
  ///
  /// In en, this message translates to:
  /// **'Moment shared!'**
  String get cameraPhotoSent;

  /// No description provided for @cameraFriend.
  ///
  /// In en, this message translates to:
  /// **'friend'**
  String get cameraFriend;

  /// No description provided for @cameraFriends.
  ///
  /// In en, this message translates to:
  /// **'friends'**
  String get cameraFriends;

  /// No description provided for @notificationFriendRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'New Friend Request'**
  String get notificationFriendRequestTitle;

  /// No description provided for @notificationFriendRequestBody.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a friend request.'**
  String notificationFriendRequestBody(Object name);

  /// No description provided for @notificationFriendAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend Request Accepted'**
  String get notificationFriendAcceptedTitle;

  /// No description provided for @notificationFriendAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted your friend request.'**
  String notificationFriendAcceptedBody(Object name);

  /// No description provided for @notificationMomentPostedTitle.
  ///
  /// In en, this message translates to:
  /// **'New Moment Posted'**
  String get notificationMomentPostedTitle;

  /// No description provided for @notificationMomentPostedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} posted a new photo.'**
  String notificationMomentPostedBody(Object name);

  /// No description provided for @uploadDevice.
  ///
  /// In en, this message translates to:
  /// **'Upload from Device'**
  String get uploadDevice;

  /// No description provided for @uploadCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get uploadCaptionHint;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded successfully!'**
  String get uploadSuccess;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo: {error}'**
  String uploadFailed(Object error);

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @commentsPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Send a private comment...'**
  String get commentsPrivateHint;

  /// No description provided for @commentsNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get commentsNoComments;

  /// No description provided for @commentsNoCommentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Comments from friends will appear here.'**
  String get commentsNoCommentsDesc;

  /// No description provided for @commentsMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get commentsMe;

  /// No description provided for @errPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission.'**
  String get errPermissionDenied;

  /// No description provided for @errUsernameNotFound.
  ///
  /// In en, this message translates to:
  /// **'Username does not exist!'**
  String get errUsernameNotFound;

  /// No description provided for @errEmailNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Account has no linked email.'**
  String get errEmailNotLinked;

  /// No description provided for @errInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Wrong username/email or password!'**
  String get errInvalidCredential;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address!'**
  String get errInvalidEmail;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errUserDisabled;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later.'**
  String get errTooManyRequests;

  /// No description provided for @errNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please try again.'**
  String get errNetworkError;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errUnknown;

  /// No description provided for @errUsernameAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Username is already taken.'**
  String get errUsernameAlreadyInUse;

  /// No description provided for @errEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email is already taken.'**
  String get errEmailAlreadyInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please use a stronger password.'**
  String get errWeakPassword;

  /// No description provided for @errOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Registration is currently disabled.'**
  String get errOperationNotAllowed;

  /// No description provided for @errResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get errResetFailed;

  /// No description provided for @errResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset link has been sent to your email!'**
  String get errResetSuccess;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get loginForgotPassword;

  /// No description provided for @loginForgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a password reset link.'**
  String get loginForgotPasswordDesc;

  /// No description provided for @loginEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address!'**
  String get loginEnterEmail;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address!'**
  String get loginInvalidEmail;

  /// No description provided for @loginSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get loginSend;

  /// No description provided for @loginForgotPasswordQ.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPasswordQ;

  /// No description provided for @loginFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields!'**
  String get loginFillAllFields;

  /// No description provided for @registerFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields!'**
  String get registerFillAllFields;

  /// No description provided for @registerUsernameLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters!'**
  String get registerUsernameLength;

  /// No description provided for @registerUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Username cannot contain spaces or \"@\"!'**
  String get registerUsernameInvalid;

  /// No description provided for @registerEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address!'**
  String get registerEmailInvalid;

  /// No description provided for @registerPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters!'**
  String get registerPasswordLength;

  /// No description provided for @registerConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerConfirmPassword;

  /// No description provided for @registerPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match!'**
  String get registerPasswordMismatch;

  /// No description provided for @settingsAvatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated successfully!'**
  String get settingsAvatarUpdated;

  /// No description provided for @settingsAvatarUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile with new avatar.'**
  String get settingsAvatarUpdateFailed;

  /// No description provided for @settingsAvatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar to storage.'**
  String get settingsAvatarUploadFailed;

  /// No description provided for @settingsProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get settingsProfileUpdated;

  /// No description provided for @settingsProfileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile. Please try again.'**
  String get settingsProfileUpdateFailed;

  /// No description provided for @settingsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String settingsError(Object error);

  /// No description provided for @commentsSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send comment: {error}'**
  String commentsSendFailed(Object error);

  /// No description provided for @deleteMomentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Moment'**
  String get deleteMomentTitle;

  /// No description provided for @deleteMomentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this moment?'**
  String get deleteMomentConfirm;

  /// No description provided for @deleteMomentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Moment deleted successfully'**
  String get deleteMomentSuccess;

  /// No description provided for @deleteMomentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete moment: {error}'**
  String deleteMomentFailed(Object error);

  /// No description provided for @deleteMomentLoading.
  ///
  /// In en, this message translates to:
  /// **'Deleting moment...'**
  String get deleteMomentLoading;

  /// No description provided for @deleteMomentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deleteMomentTooltip;

  /// No description provided for @detailSentOn.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get detailSentOn;

  /// No description provided for @detailFriendsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} friends'**
  String detailFriendsCount(Object count);

  /// No description provided for @detailReactionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reactions'**
  String detailReactionsCount(Object count);

  /// No description provided for @detailClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get detailClose;

  /// No description provided for @commentReceiverNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not identify recipient for private comment.'**
  String get commentReceiverNotFound;

  /// No description provided for @commentSendSuccess.
  ///
  /// In en, this message translates to:
  /// **'Comment sent successfully'**
  String get commentSendSuccess;

  /// No description provided for @commentSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send comment: {error}'**
  String commentSendFailed(Object error);

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you!'**
  String get reportSubmitted;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report: {error}'**
  String reportFailed(Object error);

  /// No description provided for @reactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle reaction.'**
  String get reactionFailed;

  /// No description provided for @generalError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String generalError(Object error);

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please sign in.'**
  String get registerSuccess;

  /// No description provided for @registerUsernameUnderscore.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscores!'**
  String get registerUsernameUnderscore;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @commentsPrivateWith.
  ///
  /// In en, this message translates to:
  /// **'Comment privately with {name}'**
  String commentsPrivateWith(String name);

  /// No description provided for @commentsStartPrivate.
  ///
  /// In en, this message translates to:
  /// **'Start a private comment thread.'**
  String get commentsStartPrivate;

  /// No description provided for @profileUserMomentsTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Moments'**
  String profileUserMomentsTitle(String name);

  /// No description provided for @profileMomentsGrid.
  ///
  /// In en, this message translates to:
  /// **'Moments Grid'**
  String get profileMomentsGrid;

  /// No description provided for @tooltipOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get tooltipOptions;

  /// No description provided for @menuDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get menuDetails;

  /// No description provided for @menuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Moment'**
  String get menuDelete;

  /// No description provided for @menuProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get menuProfile;

  /// No description provided for @errLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get errLoadImage;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'Moments History'**
  String get navHistory;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
