## 📱 Mobile App Structure (Flutter)

Thành phần Frontend nằm trong thư mục `app_trash/`, được tổ chức theo kiến trúc phân lớp:

```text
app_trash/
├── lib/                      # Mã nguồn chính (Dart)
│   ├── models/               # Định nghĩa các kiểu dữ liệu (PredictionModel...)
│   ├── services/             # Xử lý Logic ngoại vi (API Service, Firebase)
│   ├── utils/                # Cấu hình & Tiện ích chung (Config)
│   └── views/                # Giao diện người dùng (Screens & UI components)
├── android/                  # Cấu hình nền tảng Android (Firebase integration)
├── ios/                      # Cấu hình nền tảng iOS
├── assets/                   # Hình ảnh, Fonts và tài nguyên tĩnh
├── pubspec.yaml              # Quản lý thư viện và phiên bản app
└── test/                     # Unit & Widget testing
## ⚙️ Backend Architecture (FastAPI)

Hệ thống Backend được xây dựng theo mô hình phân lớp (Layered Architecture) để đảm bảo tính mở rộng và dễ bảo trì:

```text
app/
├── main.py              # Entry point - Khởi tạo và kết nối các Router
├── database.py          # Cấu hình kết nối Cơ sở dữ liệu (SQLAlchemy)
├── models.py            # Định nghĩa các Schema/Table (Database Models)
├── crud.py              # Các thao tác CRUD cơ bản với Database
├── dependencies.py      # Quản lý phụ thuộc (Authentication, DB Session)
├── routes/              # Lớp giao tiếp API (Endpoint definitions)
├── controllers/         # Lớp điều khiển luồng (Request/Response handling)
└── services/            # Lớp nghiệp vụ chuyên sâu (Business Logic - e.g., AI Inference)

Mô hình dùng ngrok để triển khai server để app_trash tức là app mobile nhận các api từ server và trả ngược về
Để dùng tải các file từ ml_model đưa vào app_trash các model đã training mới chạy được app_trash
