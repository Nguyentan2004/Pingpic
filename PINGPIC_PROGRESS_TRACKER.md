# 🚀 PINGPIC - PROGRESS TRACKER & CHANGELOG

**Mục đích:** Theo dõi tiến độ tích hợp API thực tế, loại bỏ dữ liệu giả (Hard-coded) và hoàn thiện các luồng tính năng cốt lõi cho dự án PingPic (Flutter + .NET 8).

## 🟢 PHASE 1: KẾT NỐI API & XỬ LÝ LỖI TOÀN CỤC (CORE NETWORKING)
| Trạng thái | Tính năng / Task | Mục đích & Chi tiết triển khai | Ngày hoàn thành |
| :---: | :--- | :--- | :--- |
| [x] | **Setup Network Core & Interceptors** | Cấu hình `Dio` client, tự động gắn JWT Token vào header. Thêm Global Error Handler để pop-up SnackBar khi mất mạng hoặc server 500. | 11/05/2026 |
| [x] | **Tích hợp API Upload Ảnh** | Xây dựng `PhotoRepository`. Sửa logic nút "Send" ở `CameraPanel` để gọi HTTP POST multipart/form-data thay vì đẩy vào list ảo. | 11/05/2026 |
| [x] | **Fetch Real Feed & History** | Thay thế `DummyData`. Gọi API GET để lấy danh sách ảnh từ DB. Tích hợp `CachedNetworkImage` thay cho `Image.network` để tối ưu RAM. | 11/05/2026 |

## 🟡 PHASE 2: HOÀN THIỆN LUỒNG NGƯỜI DÙNG CƠ BẢN (USER FLOW)
| Trạng thái | Tính năng / Task | Mục đích & Chi tiết triển khai | Ngày hoàn thành |
| :---: | :--- | :--- | :--- |
| [x] | **Xây dựng UI/Logic Register** | Thêm trang Đăng ký tài khoản (validation form: email, password, confirm password) và gọi API `POST /register`. | 11/05/2026 |
| [x] | **Tính năng Xóa Ảnh (History)** | Bổ sung nút Delete (icon thùng rác) trong Dialog chi tiết ảnh. Gọi API `DELETE` và xóa khỏi `HistoryProvider`. | 11/05/2026 |
| [x] | **Skeleton Loading** | Tích hợp package `shimmer` hiển thị khung xám mờ trong thời gian chờ API trả về dữ liệu cho Feed và History. | 11/05/2026 |

## 🟠 PHASE 3: BẠN BÈ & REAL-TIME (ADVANCED)
| Trạng thái | Tính năng / Task | Mục đích & Chi tiết triển khai | Ngày hoàn thành |
| :---: | :--- | :--- | :--- |
| [x] | **Logic Tìm & Thêm Bạn Bè** | Xây dựng `FriendsScreen`. Tìm kiếm user bằng API, gửi/nhận lời mời kết bạn. | 11/05/2026 |
| [x] | **Hiển thị Danh sách Bạn Bè** | Lấy danh sách bạn bè thật từ backend thay cho dải text "3 online" code cứng ở Trang chủ. | 11/05/2026 |
| [x] | **Kích hoạt SignalR Client** | Mở khóa comment code kết nối WebSocket. Xử lý sự kiện `ReceiveNewPhoto` để tự động đẩy ảnh mới lên đầu Feed mà không cần load lại. | 11/05/2026 |