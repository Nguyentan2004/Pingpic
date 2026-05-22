# 📋 PINGPIC - PROJECT ROADMAP & AUDIT REPORT

**Date:** 2026-05-11
**Role:** Technical Project Manager & Senior Flutter Architect

---

## 1. Bản đồ cấu trúc dự án (Current Architecture)

Dựa trên việc quét mã nguồn thực tế, dự án đang theo mô hình **Clean Architecture cơ bản** kết hợp Feature-based, nhưng các tầng Data và Domain chưa được triển khai hoàn chỉnh.

### 📁 Cấu trúc thư mục hiện tại:
*   `lib/core/`: [Đang hoạt động] Chứa các cấu hình cốt lõi (`app_router.dart`, `app_theme.dart`), Hằng số (`app_colors.dart`, `app_strings.dart`, `dummy_data.dart`) và Core Services (`image_service.dart`).
*   `lib/presentation/`: [Đang hoạt động] Chứa toàn bộ UI và State (Pages, Widgets, Providers). Đây là thư mục chứa 95% logic hiện tại.
*   `lib/data/`: [Trống/Chưa sử dụng] Đã tạo thư mục nhưng chưa có mã nguồn (Repositories, Models thật, API Clients).
*   `lib/domain/`: [Trống/Chưa sử dụng] Chứa Use Cases, Entities cốt lõi (chưa có code).

### 🛠 Công nghệ đang thực sự hoạt động:
*   **State Management:** `provider` (^6.1.2) - Đang sử dụng tích cực (`AuthProvider`, `FeedProvider`, `HistoryProvider`, v.v.).
*   **Routing:** `go_router` (^14.3.0) - Cấu hình tốt tại `app_router.dart` với các đường dẫn rõ ràng.
*   **Thư viện Ảnh:** `image_picker` (và `image_picker_for_web`) - Đang hoạt động ở `CameraPanel`. *(Lưu ý: package `cached_network_image` có trong pubspec nhưng UI hiện tại đa phần đang dùng `Image.network` và `Image.memory` thuần)*.
*   **Networking:** `dio` - Đang dùng thực tế tại `AuthProvider`.

---

## 2. Ma trận tính năng (Feature Status Matrix)

| Feature | Sub-feature | Trạng thái thực tế trong Code |
| :--- | :--- | :--- |
| **Xác thực** | Login | ✅ **[Hoàn thành]** (Dio gọi API, lưu SharedPreferences) |
| | Register | 🔴 **[Chưa thực hiện]** (Chỉ có placeholder "Register Page - TODO") |
| | Logout | ✅ **[Hoàn thành]** (Xóa token trong `AuthProvider`) |
| | Lưu Token | ✅ **[Hoàn thành]** (`jwt_token` trong SharedPreferences) |
| **Home Feed** | Hiển thị ảnh (PageView) | ⚠️ **[Đang Mock]** (Dùng `DummyData.feed` tĩnh) |
| | Vuốt Lên/Xuống & Phím | ✅ **[Hoàn thành]** (Đã tích hợp PageView.builder) |
| | Chụp ảnh mới & Send | ⚠️ **[Đang Mock]** (Chụp ảnh và đẩy vào state bộ nhớ, chưa gọi API Upload) |
| | Xem ảnh bạn bè | ⚠️ **[Đang Mock]** (Sử dụng dữ liệu tĩnh từ bạn bè ảo) |
| **History** | Lưới ảnh / Danh sách | ⚠️ **[Đang Mock]** (Giao diện chuẩn, dùng Provider lưu bộ nhớ tạm) |
| | Xem chi tiết (Popup) | ✅ **[Hoàn thành]** (Responsive, hết lỗi overflow) |
| | Xóa ảnh | 🔴 **[Chưa thực hiện]** (Không có nút Xóa hay hàm delete nào) |
| **Friends** | Tìm kiếm bạn bè | 🔴 **[Chưa thực hiện]** |
| | Gửi lời mời / Kết bạn | 🔴 **[Chưa thực hiện]** (`FriendsPage` chỉ là dòng text TODO) |
| | Danh sách bạn bè | ⚠️ **[Đang Mock]** (Thanh ngang hiển thị "3 online" được code cứng) |
| **Real-time** | Kết nối SignalR/WebSocket| 🔴 **[Chưa thực hiện]** (Code `connectSignalR` đang bị comment, hiện tại dùng Pull-to-refresh giả lập) |

---

## 3. Đánh giá kỹ thuật & Lỗ hổng (Technical Gaps)

### 🚨 Hard-coded Data (Dữ liệu chết)
*   **`dummy_data.dart`**: Toàn bộ danh sách `DummyPhoto`, `DummyHistoryPhoto` và thông tin friends (`https://i.pravatar.cc`).
*   **`home_page.dart`**: `_buildFriendStrip()` đang gán cứng text `'3 online'` và các tham số như `'5 friends'`.
*   **`camera_panel.dart`**: Khi bấm "Send", app tự khởi tạo ID bằng thời gian và đẩy data ảo (`mock_url`) vào Provider.

### 🎨 UI/UX Issues
*   **Thiếu Feedback khi Loading Feed:** Trong lúc gọi `fetchNewPhotos`, chưa có hiệu ứng Skeleton loading (dù đã cài package `shimmer`).
*   **Image Caching:** App sử dụng nhiều ảnh mạng nặng (`picsum`), nhưng việc dùng `Image.network` có thể khiến ảnh tải đi tải lại. Cần chuyển sang `CachedNetworkImage`.

### ⚠️ Error Handling (Tình trạng xử lý lỗi)
*   **Cục bộ:** `CameraPanel` xử lý lỗi rất tốt (Bắt `FileTooLargeException`, Permission denied và hiện Error Banner).
*   **Toàn cục (Global):** Không có! Nếu mất mạng giữa chừng hoặc API server sập, ngoài màn Login bị văng Exception trong try/catch (console log), không có giao diện Fallback, SnackBar, hay trang Error chung.

---

## 4. Kế hoạch hoàn thiện (Prioritized Action Plan)

Để chuyển biến PingPic từ một bản "Demo giao diện đẹp" sang một "Sản phẩm thực tế có thể sử dụng", dưới đây là lộ trình kiến trúc:

### 🔴 Phase 1: Mở thông đường truyền dữ liệu chính (Highest Priority)
1.  **API Image Upload (Backend & Frontend):** Xây dựng `PhotoRepository` và gọi API upload multipart/form-data khi người dùng bấm "Send" thay vì chỉ đẩy vào Provider ảo.
2.  **API Get Feed & Get History:** Chuyển đổi `FeedProvider` và `HistoryProvider` sang việc call Dio API thay vì load từ `DummyData`.
3.  **Thay thế `Image.network` bằng `CachedNetworkImage`:** Tối ưu hiệu năng cuộn ở màn Home.

### 🟠 Phase 2: Hoàn thiện Luồng Người dùng cơ bản (High Priority)
4.  **Trang Register (Đăng ký):** Viết logic và UI cho trang đăng ký để thu hút user thật.
5.  **Luồng Friends (Bạn bè):** Viết logic tìm kiếm, thêm bạn và fetch danh sách bạn bè thật (Xóa dải "3 online" code cứng).
6.  **Global Error Boundary:** Thêm interceptors vào `Dio` để tự động pop up Toast/SnackBar khi mất kết nối Internet hoặc lỗi 500 từ server.

### 🟡 Phase 3: Tính năng Real-time & Nâng cao (Medium Priority)
7.  **Mở khóa SignalR:** Xóa comment code trong `FeedProvider`, thực thi lắng nghe hub `ReceiveNewPhoto` để nhận ảnh từ bạn bè ngay lập tức mà không cần pull-to-refresh.
8.  **Xóa ảnh trong History:** Thêm nút Delete trong popup chi tiết và tích hợp API.
9.  **Skeleton Loading:** Áp dụng package `shimmer` cho các đoạn loading.
