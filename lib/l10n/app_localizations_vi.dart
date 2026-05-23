// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'PingPic';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navFriends => 'Bạn bè';

  @override
  String get navNotifications => 'Thông báo';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get notificationsReadAll => 'Đọc tất cả';

  @override
  String get notificationsMarkedRead =>
      'Đã đánh dấu tất cả thông báo là đã đọc.';

  @override
  String get notificationsNoNotifications => 'Chưa có thông báo nào.';

  @override
  String get notificationsWeWillNotify =>
      'Chúng tôi sẽ thông báo cho bạn khi có cập nhật.';

  @override
  String get notificationsJustNow => 'Vừa xong';

  @override
  String notificationsMinutesAgo(Object count) {
    return '$count phút trước';
  }

  @override
  String notificationsHoursAgo(Object count) {
    return '$count giờ trước';
  }

  @override
  String notificationsDaysAgo(Object count) {
    return '$count ngày trước';
  }

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get inviteTitle => 'Tạo vòng kết nối của bạn';

  @override
  String get inviteDesc =>
      'PingPic là không gian riêng tư dành cho bạn bè thực sự. Hãy kết bạn để bắt đầu chia sẻ những khoảnh khắc thời gian thực!';

  @override
  String get inviteYourCode => 'MÃ MỜI CỦA BẠN';

  @override
  String get inviteShareLink => 'LIÊN KẾT MỜI CHIA SẺ';

  @override
  String get inviteCodeCopied => 'Đã sao chép mã mời!';

  @override
  String get inviteLinkCopied => 'Đã sao chép liên kết mời!';

  @override
  String get loginTitle => 'Chào mừng quay trở lại';

  @override
  String get loginSubtitle => 'Đăng nhập để tiếp tục trải nghiệm PingPic';

  @override
  String get loginUsernameOrEmail => 'Tên đăng nhập hoặc Email';

  @override
  String get loginPassword => 'Mật khẩu';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get loginNoAccount => 'Chưa có tài khoản? Đăng ký ngay';

  @override
  String loginFailed(Object error) {
    return 'Đăng nhập thất bại: $error';
  }

  @override
  String get registerTitle => 'Tạo tài khoản mới';

  @override
  String get registerSubtitle => 'Đăng ký để chia sẻ khoảnh khắc với bạn bè';

  @override
  String get registerFullName => 'Họ và Tên';

  @override
  String get registerEmail => 'Địa chỉ Email';

  @override
  String get registerUsername => 'Tên đăng nhập';

  @override
  String get registerPassword => 'Mật khẩu';

  @override
  String get registerButton => 'Đăng ký';

  @override
  String get registerHasAccount => 'Đã có tài khoản? Đăng nhập ngay';

  @override
  String registerFailed(Object error) {
    return 'Đăng ký thất bại: $error';
  }

  @override
  String get friendsTitle => 'Bạn bè';

  @override
  String get friendsSearchPlaceholder =>
      'Nhập mã mời hoặc tên đăng nhập của bạn bè...';

  @override
  String get friendsSearchResults => 'Kết quả tìm kiếm';

  @override
  String get friendsFriendRequests => 'Yêu cầu kết bạn';

  @override
  String friendsMyFriends(Object count) {
    return 'Bạn bè của tôi ($count)';
  }

  @override
  String get friendsNoFriendsDesc => 'Chưa có bạn bè. Hãy bắt đầu kết nối!';

  @override
  String get friendsWantsToBeFriends => 'muốn kết bạn';

  @override
  String get friendsAccept => 'Chấp nhận';

  @override
  String get friendsReject => 'Từ chối';

  @override
  String get friendsUnfriendConfirmTitle => 'Hủy kết bạn';

  @override
  String friendsUnfriendConfirmDesc(Object name) {
    return 'Bạn có chắc chắn muốn hủy kết bạn với $name không?';
  }

  @override
  String friendsUnfriendSuccess(Object name) {
    return 'Đã hủy kết bạn với $name.';
  }

  @override
  String get friendsUnfriendFailed => 'Hủy kết bạn thất bại.';

  @override
  String get friendsInviteDesc => 'Chia sẻ mã này với bạn bè để kết nối!';

  @override
  String get friendsInviteCopied => 'Đã sao chép mã mời vào khay nhớ tạm!';

  @override
  String get friendsCopy => 'Sao chép';

  @override
  String get friendsLastActiveJustNow => 'Hoạt động vừa xong';

  @override
  String friendsLastActiveMinutes(Object count) {
    return 'Hoạt động $count phút trước';
  }

  @override
  String friendsLastActiveHours(Object count) {
    return 'Hoạt động $count giờ trước';
  }

  @override
  String get friendsLastActiveYesterday => 'Hoạt động hôm qua';

  @override
  String friendsLastActiveDays(Object count) {
    return 'Hoạt động $count ngày trước';
  }

  @override
  String get friendsOffline => 'Ngoại tuyến';

  @override
  String get friendsOnlineStatus => 'Đang hoạt động';

  @override
  String get friendsOnline => 'Bạn bè đang hoạt động';

  @override
  String friendsCount(Object count) {
    return '$count người bạn';
  }

  @override
  String get addFriendButton => 'Kết bạn';

  @override
  String get friendRequestSent => 'Đã gửi yêu cầu kết bạn!';

  @override
  String get friendRequestAccepted => 'Đã chấp nhận yêu cầu kết bạn!';

  @override
  String get unfriendButton => 'Hủy kết bạn';

  @override
  String get friendRequested => 'Đã yêu cầu';

  @override
  String get friendAcceptRequest => 'Chấp nhận';

  @override
  String get friendSearchHint => 'Nhập tên đăng nhập hoặc mã chia sẻ...';

  @override
  String get profileTitle => 'Hồ sơ cá nhân';

  @override
  String get profileMomentsCount => 'Khoảnh khắc';

  @override
  String get profileFriendsCount => 'Bạn bè';

  @override
  String get profileNoMoments => 'Chưa đăng khoảnh khắc nào.';

  @override
  String get profileNoMomentsDesc =>
      'Những khoảnh khắc bạn chụp sẽ xuất hiện ở đây.';

  @override
  String get profilePrivateDesc => 'Trở thành bạn bè để xem khoảnh khắc của họ';

  @override
  String get profilePrivateSub =>
      'Những khoảnh khắc được chia sẻ bởi người dùng này chỉ hiển thị với bạn bè.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsDarkMode => 'Chế độ tối';

  @override
  String get settingsDarkModeSubDark => 'Chuyển sang chế độ sáng';

  @override
  String get settingsDarkModeSubLight => 'Chuyển sang chế độ tối';

  @override
  String get settingsAccountInfo => 'Thông tin tài khoản';

  @override
  String get settingsFullNameLabel => 'Họ và Tên';

  @override
  String get settingsFullNameHint => 'Nhập họ và tên của bạn';

  @override
  String get settingsBioLabel => 'Tiểu sử';

  @override
  String get settingsBioHint => 'Chia sẻ đôi nét về bản thân...';

  @override
  String get settingsSaveChanges => 'Lưu thay đổi';

  @override
  String get settingsLogout => 'Đăng xuất';

  @override
  String get settingsLogoutConfirmTitle => 'Đăng xuất';

  @override
  String get settingsLogoutConfirmDesc =>
      'Bạn có chắc chắn muốn đăng xuất khỏi PingPic không?';

  @override
  String get settingsCancel => 'Hủy bỏ';

  @override
  String get settingsAppVersion => 'Phiên bản 1.0.0';

  @override
  String get settingsThemePreview => 'Xem trước giao diện';

  @override
  String get settingsPreviewCardTitle => 'Nguyễn Nhật Tân';

  @override
  String get settingsPreviewCardTime => '5 phút trước';

  @override
  String get settingsPreviewCardCaption => 'Sống trọn từng khoảnh khắc! 🍊';

  @override
  String get cameraShareMoment => 'Chia sẻ khoảnh khắc';

  @override
  String get cameraBroadcastDesc =>
      'Gửi một bức ảnh tới toàn bộ bạn bè của bạn';

  @override
  String get cameraUploadPhoto => 'Tải ảnh từ thiết bị';

  @override
  String get cameraTakePhoto => 'Chụp ảnh mới';

  @override
  String get cameraAddCaption => 'Thêm mô tả...';

  @override
  String get cameraSharingWithCircle => 'Chia sẻ với bạn bè: ';

  @override
  String get cameraSendToFriends => 'Gửi tới bạn bè';

  @override
  String get cameraSending => 'Đang gửi...';

  @override
  String get cameraPhotoSent => 'Đã chia sẻ khoảnh khắc!';

  @override
  String get cameraFriend => 'người bạn';

  @override
  String get cameraFriends => 'người bạn';

  @override
  String get notificationFriendRequestTitle => 'Yêu cầu kết bạn mới';

  @override
  String notificationFriendRequestBody(Object name) {
    return '$name đã gửi cho bạn một yêu cầu kết bạn.';
  }

  @override
  String get notificationFriendAcceptedTitle => 'Đã chấp nhận yêu cầu kết bạn';

  @override
  String notificationFriendAcceptedBody(Object name) {
    return '$name đã chấp nhận yêu cầu kết bạn của bạn.';
  }

  @override
  String get notificationMomentPostedTitle => 'Khoảnh khắc mới được đăng';

  @override
  String notificationMomentPostedBody(Object name) {
    return '$name đã đăng một ảnh mới.';
  }

  @override
  String get notificationLikedMomentTitle => 'Lượt thích mới';

  @override
  String notificationLikedMoment(String name) {
    return '$name đã thích khoảnh khắc của bạn.';
  }

  @override
  String get notificationCommentedMomentTitle => 'Bình luận mới';

  @override
  String notificationCommentedMoment(String name) {
    return '$name đã bình luận về khoảnh khắc của bạn.';
  }

  @override
  String get notificationRepliedCommentTitle => 'Phản hồi mới';

  @override
  String notificationRepliedComment(String name) {
    return '$name đã phản hồi bình luận của bạn.';
  }

  @override
  String get uploadDevice => 'Tải ảnh từ thiết bị';

  @override
  String get uploadCaptionHint => 'Thêm mô tả...';

  @override
  String get uploadSuccess => 'Tải khoảnh khắc lên thành công!';

  @override
  String uploadFailed(Object error) {
    return 'Tải khoảnh khắc lên thất bại: $error';
  }

  @override
  String get commentsTitle => 'Phản hồi';

  @override
  String get commentsPrivateHint => 'Gửi phản hồi riêng tư...';

  @override
  String get commentsNoComments => 'Chưa có phản hồi nào.';

  @override
  String get commentsNoCommentsDesc => 'Phản hồi từ bạn bè sẽ hiển thị ở đây.';

  @override
  String get commentsMe => 'Tôi';

  @override
  String get errPermissionDenied => 'Bạn không có quyền truy cập.';

  @override
  String get errUsernameNotFound => 'Tên đăng nhập không tồn tại!';

  @override
  String get errEmailNotLinked => 'Tài khoản không có email liên kết.';

  @override
  String get errInvalidCredential => 'Sai tài khoản hoặc mật khẩu!';

  @override
  String get errInvalidEmail => 'Địa chỉ email không hợp lệ!';

  @override
  String get errUserDisabled => 'Tài khoản này đã bị khóa.';

  @override
  String get errTooManyRequests =>
      'Quá nhiều yêu cầu đăng nhập thất bại. Vui lòng thử lại sau.';

  @override
  String get errNetworkError => 'Đã xảy ra lỗi kết nối. Vui lòng thử lại.';

  @override
  String get errUnknown => 'Đã xảy ra lỗi không xác định.';

  @override
  String get errUsernameAlreadyInUse => 'Tên đăng nhập này đã được sử dụng.';

  @override
  String get errEmailAlreadyInUse => 'Địa chỉ email này đã được sử dụng.';

  @override
  String get errWeakPassword =>
      'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.';

  @override
  String get errOperationNotAllowed =>
      'Đăng ký bằng email/password chưa được kích hoạt.';

  @override
  String get errResetFailed => 'Không thể gửi email đặt lại mật khẩu.';

  @override
  String get errResetSuccess =>
      'Liên kết đặt lại mật khẩu đã được gửi đến email của bạn!';

  @override
  String get loginForgotPassword => 'Quên mật khẩu';

  @override
  String get loginForgotPasswordDesc =>
      'Nhập email của bạn để nhận liên kết đặt lại mật khẩu.';

  @override
  String get loginEnterEmail => 'Vui lòng nhập địa chỉ email!';

  @override
  String get loginInvalidEmail => 'Địa chỉ email không hợp lệ!';

  @override
  String get loginSend => 'Gửi';

  @override
  String get loginForgotPasswordQ => 'Quên mật khẩu?';

  @override
  String get loginFillAllFields => 'Vui lòng điền đầy đủ thông tin!';

  @override
  String get registerFillAllFields => 'Vui lòng điền đầy đủ thông tin!';

  @override
  String get registerUsernameLength =>
      'Tên đăng nhập phải chứa ít nhất 3 ký tự!';

  @override
  String get registerUsernameInvalid =>
      'Tên đăng nhập không được chứa khoảng trắng hoặc ký tự \"@\"!';

  @override
  String get registerEmailInvalid => 'Địa chỉ email không hợp lệ!';

  @override
  String get registerPasswordLength => 'Mật khẩu phải chứa ít nhất 6 ký tự!';

  @override
  String get registerConfirmPassword => 'Xác nhận mật khẩu';

  @override
  String get registerPasswordMismatch => 'Mật khẩu xác nhận không khớp!';

  @override
  String get settingsAvatarUpdated => 'Đã cập nhật ảnh đại diện thành công!';

  @override
  String get settingsAvatarUpdateFailed => 'Cập nhật ảnh đại diện thất bại.';

  @override
  String get settingsAvatarUploadFailed =>
      'Không thể tải ảnh đại diện lên lưu trữ.';

  @override
  String get settingsProfileUpdated => 'Hồ sơ đã được cập nhật thành công!';

  @override
  String get settingsProfileUpdateFailed =>
      'Cập nhật hồ sơ thất bại. Vui lòng thử lại.';

  @override
  String settingsError(Object error) {
    return 'Lỗi: $error';
  }

  @override
  String commentsSendFailed(Object error) {
    return 'Gửi bình luận thất bại: $error';
  }

  @override
  String get deleteMomentTitle => 'Xóa ảnh';

  @override
  String get deleteMomentConfirm =>
      'Bạn có chắc chắn muốn xóa khoảnh khắc này không?';

  @override
  String get deleteMomentSuccess => 'Đã xóa khoảnh khắc thành công';

  @override
  String deleteMomentFailed(Object error) {
    return 'Lỗi khi xóa: $error';
  }

  @override
  String get deleteMomentLoading => 'Đang xóa ảnh...';

  @override
  String get deleteMomentTooltip => 'Xóa ảnh';

  @override
  String get detailSentOn => 'Đã gửi';

  @override
  String detailFriendsCount(Object count) {
    return '$count người bạn';
  }

  @override
  String detailReactionsCount(Object count) {
    return '$count tương tác';
  }

  @override
  String get detailClose => 'Đóng';

  @override
  String get commentReceiverNotFound =>
      'Không xác định được người nhận phản hồi.';

  @override
  String get commentSendSuccess => 'Đã gửi bình luận thành công';

  @override
  String commentSendFailed(Object error) {
    return 'Gửi phản hồi thất bại: $error';
  }

  @override
  String get reportSubmitted => 'Báo cáo đã được gửi. Cảm ơn bạn!';

  @override
  String reportFailed(Object error) {
    return 'Gửi báo cáo thất bại: $error';
  }

  @override
  String get reactionFailed => 'Không thể thay đổi cảm xúc.';

  @override
  String generalError(Object error) {
    return 'Lỗi: $error';
  }

  @override
  String get registerSuccess => 'Đăng ký thành công! Vui lòng đăng nhập.';

  @override
  String get registerUsernameUnderscore =>
      'Tên đăng nhập chỉ được chứa chữ cái, chữ số và dấu gạch dưới!';

  @override
  String get delete => 'Xóa';

  @override
  String commentsPrivateWith(String name) {
    return 'Phản hồi riêng tư với $name';
  }

  @override
  String get commentsStartPrivate => 'Bắt đầu cuộc trò chuyện riêng tư.';

  @override
  String profileUserMomentsTitle(String name) {
    return 'Khoảnh khắc của $name';
  }

  @override
  String get profileMomentsGrid => 'Lưới khoảnh khắc';

  @override
  String get tooltipOptions => 'Tùy chọn';

  @override
  String get menuDetails => 'Xem chi tiết';

  @override
  String get menuDelete => 'Xóa khoảnh khắc';

  @override
  String get menuProfile => 'Xem trang cá nhân';

  @override
  String get errLoadImage => 'Không thể tải hình ảnh';

  @override
  String get add => 'Thêm';

  @override
  String get navHistory => 'Lịch sử khoảnh khắc';
}
