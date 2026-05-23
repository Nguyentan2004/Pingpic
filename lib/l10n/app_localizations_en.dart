// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PingPic';

  @override
  String get navHome => 'Home';

  @override
  String get navFriends => 'Friends';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsReadAll => 'Read All';

  @override
  String get notificationsMarkedRead => 'All notifications marked as read.';

  @override
  String get notificationsNoNotifications => 'No notifications yet.';

  @override
  String get notificationsWeWillNotify => 'We will notify you about updates.';

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String notificationsMinutesAgo(Object count) {
    return '${count}m ago';
  }

  @override
  String notificationsHoursAgo(Object count) {
    return '${count}h ago';
  }

  @override
  String notificationsDaysAgo(Object count) {
    return '${count}d ago';
  }

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get inviteTitle => 'Create Your Circle';

  @override
  String get inviteDesc =>
      'PingPic is a private space for your real friends. Add friends to start sharing real-time moments!';

  @override
  String get inviteYourCode => 'YOUR INVITE CODE';

  @override
  String get inviteShareLink => 'SHAREABLE INVITE LINK';

  @override
  String get inviteCodeCopied => 'Invite code copied!';

  @override
  String get inviteLinkCopied => 'Invite link copied!';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue to PingPic';

  @override
  String get loginUsernameOrEmail => 'Username or Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginNoAccount => 'Don\'t have an account? Sign Up';

  @override
  String loginFailed(Object error) {
    return 'Login failed: $error';
  }

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Sign up to share moments with friends';

  @override
  String get registerFullName => 'Full Name';

  @override
  String get registerEmail => 'Email';

  @override
  String get registerUsername => 'Username';

  @override
  String get registerPassword => 'Password';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get registerHasAccount => 'Already have an account? Sign In';

  @override
  String registerFailed(Object error) {
    return 'Registration failed: $error';
  }

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsSearchPlaceholder =>
      'Enter friend\'s invite code or username...';

  @override
  String get friendsSearchResults => 'Search Results';

  @override
  String get friendsFriendRequests => 'Friend Requests';

  @override
  String friendsMyFriends(Object count) {
    return 'My Friends ($count)';
  }

  @override
  String get friendsNoFriendsDesc => 'No friends yet. Start adding some!';

  @override
  String get friendsWantsToBeFriends => 'wants to be friends';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsReject => 'Reject';

  @override
  String get friendsUnfriendConfirmTitle => 'Unfriend';

  @override
  String friendsUnfriendConfirmDesc(Object name) {
    return 'Are you sure you want to unfriend $name?';
  }

  @override
  String friendsUnfriendSuccess(Object name) {
    return 'Removed $name from friends.';
  }

  @override
  String get friendsUnfriendFailed => 'Failed to unfriend.';

  @override
  String get friendsInviteDesc =>
      'Share this code with your friends to connect!';

  @override
  String get friendsInviteCopied => 'Invite code copied to clipboard!';

  @override
  String get friendsCopy => 'Copy';

  @override
  String get friendsLastActiveJustNow => 'Active just now';

  @override
  String friendsLastActiveMinutes(Object count) {
    return 'Active ${count}m ago';
  }

  @override
  String friendsLastActiveHours(Object count) {
    return 'Active ${count}h ago';
  }

  @override
  String get friendsLastActiveYesterday => 'Active yesterday';

  @override
  String friendsLastActiveDays(Object count) {
    return 'Active $count days ago';
  }

  @override
  String get friendsOffline => 'Offline';

  @override
  String get friendsOnlineStatus => 'Online';

  @override
  String get friendsOnline => 'Friends Online';

  @override
  String friendsCount(Object count) {
    return '$count friends';
  }

  @override
  String get addFriendButton => 'Add Friend';

  @override
  String get friendRequestSent => 'Friend request sent!';

  @override
  String get friendRequestAccepted => 'Friend request accepted!';

  @override
  String get unfriendButton => 'Unfriend';

  @override
  String get friendRequested => 'Requested';

  @override
  String get friendAcceptRequest => 'Accept Request';

  @override
  String get friendSearchHint => 'Enter username or share code...';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileMomentsCount => 'Moments';

  @override
  String get profileFriendsCount => 'Friends';

  @override
  String get profileNoMoments => 'No moments posted yet.';

  @override
  String get profileNoMomentsDesc => 'Moments you capture will show up here.';

  @override
  String get profilePrivateDesc => 'Become friends to see their moments';

  @override
  String get profilePrivateSub =>
      'Moments shared by this user are only visible to friends.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkModeSubDark => 'Switch to light theme';

  @override
  String get settingsDarkModeSubLight => 'Switch to dark theme';

  @override
  String get settingsAccountInfo => 'Account Information';

  @override
  String get settingsFullNameLabel => 'Full Name';

  @override
  String get settingsFullNameHint => 'Enter your full name';

  @override
  String get settingsBioLabel => 'Bio';

  @override
  String get settingsBioHint => 'Tell others about yourself...';

  @override
  String get settingsSaveChanges => 'Save Changes';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get settingsLogoutConfirmTitle => 'Log Out';

  @override
  String get settingsLogoutConfirmDesc =>
      'Are you sure you want to log out of PingPic?';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsAppVersion => 'Version 1.0.0';

  @override
  String get settingsThemePreview => 'Theme Preview';

  @override
  String get settingsPreviewCardTitle => 'Nguyễn Nhật Tân';

  @override
  String get settingsPreviewCardTime => '5m ago';

  @override
  String get settingsPreviewCardCaption => 'Living in the moment! 🍊';

  @override
  String get cameraShareMoment => 'Share a Moment';

  @override
  String get cameraBroadcastDesc => 'Broadcast a photo to your entire circle';

  @override
  String get cameraUploadPhoto => 'Upload from Device';

  @override
  String get cameraTakePhoto => 'Take a Photo';

  @override
  String get cameraAddCaption => 'Add a caption...';

  @override
  String get cameraSharingWithCircle => 'Sharing with your circle: ';

  @override
  String get cameraSendToFriends => 'Send to Friends';

  @override
  String get cameraSending => 'Sending...';

  @override
  String get cameraPhotoSent => 'Moment shared!';

  @override
  String get cameraFriend => 'friend';

  @override
  String get cameraFriends => 'friends';

  @override
  String get notificationFriendRequestTitle => 'New Friend Request';

  @override
  String notificationFriendRequestBody(Object name) {
    return '$name sent you a friend request.';
  }

  @override
  String get notificationFriendAcceptedTitle => 'Friend Request Accepted';

  @override
  String notificationFriendAcceptedBody(Object name) {
    return '$name accepted your friend request.';
  }

  @override
  String get notificationMomentPostedTitle => 'New Moment Posted';

  @override
  String notificationMomentPostedBody(Object name) {
    return '$name posted a new photo.';
  }

  @override
  String get uploadDevice => 'Upload from Device';

  @override
  String get uploadCaptionHint => 'Add a caption...';

  @override
  String get uploadSuccess => 'Photo uploaded successfully!';

  @override
  String uploadFailed(Object error) {
    return 'Failed to upload photo: $error';
  }

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentsPrivateHint => 'Send a private comment...';

  @override
  String get commentsNoComments => 'No comments yet.';

  @override
  String get commentsNoCommentsDesc =>
      'Comments from friends will appear here.';

  @override
  String get commentsMe => 'Me';

  @override
  String get errPermissionDenied => 'You do not have permission.';

  @override
  String get errUsernameNotFound => 'Username does not exist!';

  @override
  String get errEmailNotLinked => 'Account has no linked email.';

  @override
  String get errInvalidCredential => 'Wrong username/email or password!';

  @override
  String get errInvalidEmail => 'Invalid email address!';

  @override
  String get errUserDisabled => 'This account has been disabled.';

  @override
  String get errTooManyRequests =>
      'Too many failed attempts. Please try again later.';

  @override
  String get errNetworkError => 'Connection error. Please try again.';

  @override
  String get errUnknown => 'An unexpected error occurred.';

  @override
  String get errUsernameAlreadyInUse => 'Username is already taken.';

  @override
  String get errEmailAlreadyInUse => 'Email is already taken.';

  @override
  String get errWeakPassword =>
      'Password is too weak. Please use a stronger password.';

  @override
  String get errOperationNotAllowed => 'Registration is currently disabled.';

  @override
  String get errResetFailed => 'Failed to send reset email.';

  @override
  String get errResetSuccess =>
      'Password reset link has been sent to your email!';

  @override
  String get loginForgotPassword => 'Forgot Password';

  @override
  String get loginForgotPasswordDesc =>
      'Enter your email to receive a password reset link.';

  @override
  String get loginEnterEmail => 'Please enter your email address!';

  @override
  String get loginInvalidEmail => 'Invalid email address!';

  @override
  String get loginSend => 'Send';

  @override
  String get loginForgotPasswordQ => 'Forgot Password?';

  @override
  String get loginFillAllFields => 'Please fill in all fields!';

  @override
  String get registerFillAllFields => 'Please fill in all fields!';

  @override
  String get registerUsernameLength =>
      'Username must be at least 3 characters!';

  @override
  String get registerUsernameInvalid =>
      'Username cannot contain spaces or \"@\"!';

  @override
  String get registerEmailInvalid => 'Invalid email address!';

  @override
  String get registerPasswordLength =>
      'Password must be at least 6 characters!';

  @override
  String get registerConfirmPassword => 'Confirm Password';

  @override
  String get registerPasswordMismatch => 'Passwords do not match!';

  @override
  String get settingsAvatarUpdated => 'Avatar updated successfully!';

  @override
  String get settingsAvatarUpdateFailed =>
      'Failed to update profile with new avatar.';

  @override
  String get settingsAvatarUploadFailed =>
      'Failed to upload avatar to storage.';

  @override
  String get settingsProfileUpdated => 'Profile updated successfully!';

  @override
  String get settingsProfileUpdateFailed =>
      'Failed to update profile. Please try again.';

  @override
  String settingsError(Object error) {
    return 'Error: $error';
  }

  @override
  String commentsSendFailed(Object error) {
    return 'Failed to send comment: $error';
  }

  @override
  String get deleteMomentTitle => 'Delete Moment';

  @override
  String get deleteMomentConfirm =>
      'Are you sure you want to delete this moment?';

  @override
  String get deleteMomentSuccess => 'Moment deleted successfully';

  @override
  String deleteMomentFailed(Object error) {
    return 'Failed to delete moment: $error';
  }

  @override
  String get deleteMomentLoading => 'Deleting moment...';

  @override
  String get deleteMomentTooltip => 'Delete photo';

  @override
  String get detailSentOn => 'Sent';

  @override
  String detailFriendsCount(Object count) {
    return '$count friends';
  }

  @override
  String detailReactionsCount(Object count) {
    return '$count reactions';
  }

  @override
  String get detailClose => 'Close';

  @override
  String get commentReceiverNotFound =>
      'Could not identify recipient for private comment.';

  @override
  String get commentSendSuccess => 'Comment sent successfully';

  @override
  String commentSendFailed(Object error) {
    return 'Failed to send comment: $error';
  }

  @override
  String get reportSubmitted => 'Report submitted. Thank you!';

  @override
  String reportFailed(Object error) {
    return 'Failed to submit report: $error';
  }

  @override
  String get reactionFailed => 'Failed to toggle reaction.';

  @override
  String generalError(Object error) {
    return 'Error: $error';
  }

  @override
  String get registerSuccess => 'Registration successful! Please sign in.';

  @override
  String get registerUsernameUnderscore =>
      'Username can only contain letters, numbers, and underscores!';

  @override
  String get delete => 'Delete';

  @override
  String commentsPrivateWith(String name) {
    return 'Comment privately with $name';
  }

  @override
  String get commentsStartPrivate => 'Start a private comment thread.';

  @override
  String profileUserMomentsTitle(String name) {
    return '$name\'s Moments';
  }

  @override
  String get profileMomentsGrid => 'Moments Grid';

  @override
  String get tooltipOptions => 'Options';

  @override
  String get menuDetails => 'View Details';

  @override
  String get menuDelete => 'Delete Moment';

  @override
  String get menuProfile => 'View Profile';

  @override
  String get errLoadImage => 'Could not load image';

  @override
  String get add => 'Add';

  @override
  String get navHistory => 'Moments History';
}
