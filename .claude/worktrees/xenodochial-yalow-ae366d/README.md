# FBT HHT Flutter - Warehouse Management System

Ứng dụng quản lý kho hàng được xây dựng bằng Flutter + Dart, clone từ dự án React Native gốc.

## 🚀 Tính năng

- ✅ Authentication (Login với username/password hoặc QR code)
- ✅ Dashboard/Main Menu với 7 modules chính
- ✅ Warehouse Receipt (入荷)
- ✅ Putaway (棚上げ)
- ✅ Picking (ピッキング)
- ✅ Bundle (事前セット)
- ✅ Bin Movement (棚移動)
- ✅ Bin Audit (棚卸)

## 📁 Cấu trúc dự án

```
lib/
├── config/              # Configuration files
│   ├── app_config.dart
│   └── theme_config.dart
├── core/                # Core functionality
│   ├── network/         # API client, endpoints
│   ├── storage/         # Local storage
│   └── utils/           # Utilities
├── data/                # Data layer
│   ├── models/          # Data models
│   ├── repositories/    # Repository pattern
│   └── datasources/    # Remote & local data sources
├── presentation/        # UI layer
│   ├── auth/           # Authentication screens
│   ├── dashboard/      # Main menu
│   ├── widgets/        # Reusable widgets
│   └── providers/      # State management
├── routes/             # Navigation
└── services/           # Services (scanner, sound, etc.)
```

## 🎨 Components

### Core Components
- **CustomButton**: Button với nhiều styles (primary, secondary, danger, success, outline)
- **CustomInput**: Text input với validation
- **CustomCheckbox**: Checkbox component
- **CustomDropdown**: Dropdown với search và custom items

### UI Components
- **DataTableWidget**: Table hiển thị dữ liệu dạng bảng
- **ListViewWidget**: List view với empty state và loading
- **FilterWidget**: Filter component với nhiều loại field
- **ImageUploadWidget**: Upload và preview ảnh
- **ImageViewWidget**: Xem ảnh với fullscreen mode

## 🛠️ Cài đặt

1. Clone repository:
```bash
git clone <repository-url>
cd fbt_hht_flutter
```

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Chạy ứng dụng:
```bash
flutter run
```
## 🔧 Configuration

### App Config (`lib/config/app_config.dart`)
- API host
- Storage keys
- Version info

### Theme Config (`lib/config/theme_config.dart`)
- Colors
- Typography
- Theme settings

## 📄 License

Private project
