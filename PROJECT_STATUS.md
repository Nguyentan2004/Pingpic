# PROJECT_STATUS - PingPic (LocketWeb Clone)

## 1. Tổng quan dự án (Project Overview)
| Hạng mục | Chi tiết |
|---|---|
| **Tên dự án** | PingPic |
| **Mục tiêu cốt lõi** | Xây dựng ứng dụng chia sẻ ảnh thời gian thực với bạn bè (concept tương tự Locket) tối ưu hóa cho nền tảng Web. |
| **Frontend** | Flutter Web (Material 3) |
| **State Management** | Provider |
| **Routing** | GoRouter (hỗ trợ deep-linking và Web URLs) |
| **Backend Dự kiến** | .NET 8 Web API + SignalR (Realtime communication) |
| **Kiến trúc** | Clean Architecture / Feature-based |

---

## 2. Những việc đã hoàn thành (Completed Milestones)

### 🧩 Cấu trúc & Cốt lõi
- [x] Thiết lập cấu trúc thư mục Clean Architecture chuẩn mực (`core/`, `presentation/`, `data/`, `domain/`).
- [x] Tích hợp `AppRouter` điều hướng mượt mà cho các trang `/home`, `/history`, `/login`, v.v.
- [x] Setup `AppTheme` với Dark Mode mặc định và Google Fonts (Inter).

### 📱 Màn hình UI (Presentation Layer)
- [x] **HomeScreen (Responsive 3 Layouts)**: 
  - *Desktop (≥ 1200px)*: Sidebar trái, Feed ở giữa, Camera Panel cố định bên phải.
  - *Tablet (900-1200px)*: Top bar, Feed (60%) + Camera Panel (40%).
  - *Mobile (< 900px)*: Full Feed, Bottom Nav, Nút Camera nổi (FAB) mở Bottom Sheet Modal.
- [x] **HistoryScreen (My Moments)**: Hiển thị dạng lưới (GridView) có thể toggle sang List. Hỗ trợ hover overlay mượt mà hiển thị thống kê ảnh và Dialog xem chi tiết ảnh.
- [x] **Widgets Reusable**: 
  - `PhotoCard`: Feed ảnh cuộn có hiệu ứng hover lift, gradient overlay, và animation thả tim (double-tap).
  - `FriendStrip`: Danh sách bạn bè kèm trạng thái online (chấm xanh).

### ⚙️ Logic & Services
- [x] **ImageService (`image_picker_for_web`)**: Xử lý logic chụp ảnh từ webcam và chọn ảnh từ File Explorer. Xử lý triệt để các lỗi (`CameraPermissionDeniedException`, kích thước file, sai định dạng).
- [x] **CameraPanel Logic**: Tích hợp luồng chọn ảnh, render preview bằng `Image.memory` (chuẩn web), hỗ trợ Replace ảnh, viết caption và nút Send.
- [x] **FeedProvider**: Xây dựng state management quản lý feed. Đã tích hợp luồng **Mock Realtime** (cứ 10s đẩy 1 ảnh mới lên top feed tự động update UI).

---

## 3. Những điểm cần cải thiện & Tồn tại (Limitations & Pending)

### Dữ liệu & API
- Toàn bộ ứng dụng hiện đang chạy trên **Dummy Data** (ảnh từ Picsum, logic push tự động từ `Stream.periodic`).
- Thiếu implementation cho `AuthRepository` và `PhotoRepository`.

### Hiệu năng Web (Web Performance Issues)
- Render nhiều ảnh (Infinite Scroll) trên Flutter Web bằng CanvasKit có thể gây hao tốn RAM. Cần cơ chế Lazy Loading / Pagination mạnh hơn.
- `Image.memory` cho ảnh chất lượng gốc từ Camera có thể gây khựng frame (jank) khi render trực tiếp chưa qua nén.

### Lỗi & Hạn chế UX (Bugs/UX Limits)
- Trên Mobile Web, trải nghiệm xin quyền Camera đôi khi bị trình duyệt (Safari/Chrome iOS) chặn popup.
- Tính năng kéo thả (Drag & Drop) file trực tiếp vào vùng `CameraPanel` chưa được implement hoàn chỉnh (mới chỉ có hover UI).

---

## 4. Đề xuất kỹ thuật tiếp theo (Next Technical Steps)

1. **Tích hợp SignalR Client**: Mở khóa comment trong `FeedProvider` để kết nối thật tới backend .NET qua WebSocket. Chuyển đổi từ Dummy event sang `connection.on("ReceiveNewPhoto", ...)`.
2. **Tối ưu Nén ảnh Client-side**: Sử dụng `flutter_image_compress` hoặc HTML Canvas để resize/compress ảnh (giảm từ 5MB -> <500KB) *trước khi* upload lên Server, tối ưu băng thông.
3. **Hoàn thiện Auth Flow**: Xây dựng UI Login/Register và xử lý lưu trữ JWT Token an toàn vào LocalStorage/Cookie.
4. **Tích hợp Dio Interceptors**: Cấu hình tự động gắn Token vào Request Header cho các thao tác upload/fetch.

---

## 5. Câu hỏi / Thách thức gửi Chuyên gia phân tích (Challenges for Analyst)

* **Vấn đề 1: Trạng thái kết nối ngầm (Background Connection):** Khi user chuyển tab trên trình duyệt Web (Browser Throttling), SignalR connection có thể bị rớt. Cần chiến lược Reconnect hoặc Sync dữ liệu khi user quay lại tab như thế nào cho tối ưu mà không tải lại toàn bộ Feed?
* **Vấn đề 2: Caching ảnh trên Web:** Gói `cached_network_image` có hạn chế trên Flutter Web (đặc biệt với CanvasKit). Cách tốt nhất để cache các bức ảnh lớn mà không làm phình bộ nhớ RAM của tab trình duyệt là gì?
* **Vấn đề 3: Tương thích Camera Mobile Web:** Việc gọi `ImageSource.camera` trên một số trình duyệt In-App (như Zalo/Facebook Browser) thường gặp lỗi thiếu quyền. Ta có nên code fallback fallback sang thẻ `<input type="file" accept="image/*" capture="camera">` thông qua `dart:html` không?
