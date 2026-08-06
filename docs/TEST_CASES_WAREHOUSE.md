# WMS HHT (FBTHHT) — Tài liệu Test thủ công (Quản lý kho)

Tài liệu test case cho các chức năng **quản lý kho** trên máy HHT. Không bao gồm auto-update.

- **App:** FBTHHT / 倉庫管理システム
- **Thiết bị test:** Máy HHT (Keyence) hoặc điện thoại Android
- **Nhãn UI:** giữ nguyên tiếng Nhật để đối chiếu trực tiếp trên màn hình

## Quy ước

| Ký hiệu | Ý nghĩa |
|---|---|
| ✅ Pass | Kết quả đúng như mong đợi |
| ❌ Fail | Sai khác — ghi chi tiết vào cột Ghi chú |
| 🔊 | Có âm thanh phản hồi (chỉ màn Picking) |

**Điều kiện chung trước khi test:**
- Máy HHT kết nối mạng tới server WMS
- Đã có tài khoản đăng nhập hợp lệ
- Server có sẵn dữ liệu test (đơn nhập, picking, tồn kho...)

---

## 1. Đăng nhập (ログイン)

### 1a. Đăng nhập thường

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-LOGIN-01 | Ở màn hình login | Bỏ trống cả 2 ô → nhấn **ログイン** | Hiện lỗi đỏ **「ユーザー名とパスワードを入力してください」**, không gọi API | |
| TC-LOGIN-02 | Ở màn hình login | Nhập user, bỏ trống password → **ログイン** | Hiện lỗi **「ユーザー名とパスワードを入力してください」** | |
| TC-LOGIN-03 | Ở màn hình login | Nhập sai user/password → **ログイン** | Hiện lỗi **「ユーザー名またはパスワードが正しくありません。...」** | |
| TC-LOGIN-04 | Tắt mạng | Nhập user/pass đúng → **ログイン** | Hiện lỗi **「WMSサーバーに接続できません。...」** | |
| TC-LOGIN-05 | Ở màn hình login | Nhập đúng user/pass → **ログイン** | Spinner hiện, login thành công → chuyển tới **メニュー** (main menu) | |
| TC-LOGIN-06 | Ở ô パスワード | Nhấn icon con mắt | Password chuyển hiện/ẩn ký tự | |
| TC-LOGIN-07 | Ở ô ユーザー名 | Nhập user → nhấn Enter | Con trỏ nhảy xuống ô パスワード | |
| TC-LOGIN-08 | Ở ô パスワード | Nhấn Enter | Tự động submit login | |
| TC-LOGIN-09 | Ở màn hình login | Kiểm tra badge version dưới cùng | Hiển thị `v{version}` đúng version app đang cài | |

### 1b. Đăng nhập QR

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-QR-01 | Màn login | Nhấn **QRコードでログイン** | Mở màn camera quét QR, hiện **「QRコードをカメラに向けてください」** | |
| TC-QR-02 | Màn QR | Quét mã QR hợp lệ (`user\|pass`) | Login thành công → chuyển tới **テナント選択** (tenant selection) | |
| TC-QR-03 | Màn QR | Quét mã QR sai định dạng | Banner đỏ **「QRコードの形式が正しくありません」**, camera quét lại | |
| TC-QR-04 | Màn QR | Quét QR mà user/pass rỗng | Banner đỏ **「ユーザーとパスワードを入力してください」** | |
| TC-QR-05 | Tắt mạng, màn QR | Quét QR hợp lệ | Banner **「WMSサーバーに接続できません。...」** | |

---

## 2. Chọn Tenant / Location

### 2a. Chọn Tenant (テナント選択)

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-TEN-01 | Vào từ 入荷 | Mở màn tenant | Tiêu đề **「入荷 — テナント選択」**, AppBar màu xanh thép | |
| TC-TEN-02 | Vào từ ピッキング | Mở màn tenant | Tiêu đề **「ピッキング — テナント選択」**, AppBar màu hổ phách | |
| TC-TEN-03 | Danh sách tenant đã load | Gõ từ khóa vào ô **「テナントを検索...」** | Danh sách lọc theo tên (không phân biệt hoa thường) | |
| TC-TEN-04 | Có từ khóa tìm kiếm | Nhấn nút X (clear) | Xóa từ khóa, hiện lại toàn bộ danh sách | |
| TC-TEN-05 | Vào từ 入荷 | Chạm 1 tenant | Chuyển tới màn danh sách 入荷 của tenant đó | |
| TC-TEN-06 | Vào từ ピッキング | Chạm 1 tenant | Chuyển tới màn danh sách ピッキング của tenant đó | |
| TC-TEN-07 | Màn tenant | Nhấn mũi tên back | Quay về **メニュー** | |
| TC-TEN-08 | Lỗi mạng khi load | Mở màn tenant | Hiện icon lỗi + thông báo + nút **再試行**; nhấn 再試行 → tải lại | |
| TC-TEN-09 | Không có tenant | Mở màn tenant | Hiện **「テナントが見つかりません」** | |

### 2b. Chọn Location (ロケーション選択)

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-LOC-01 | Màn location | Gõ vào **「ロケーションを検索...」** | Lọc theo mã HOẶC tên location | |
| TC-LOC-02 | Danh sách location | Chạm 1 location | SnackBar xanh **「ロケーション: {mã} を選択しました」** → về **メニュー** | |
| TC-LOC-03 | Không có location | Mở màn | Hiện **「ロケーションが見つかりません」** | |

---

## 3. Menu chính (メニュー)

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-MENU-01 | Đã login | Xem màn menu | 6 ô module (2 cột) + nút **ログアウト** dưới cùng, badge version | |
| TC-MENU-02 | Menu | Chạm **入荷** | Sang **テナント選択** (funcNumber=1) | |
| TC-MENU-03 | Menu | Chạm **棚上げ** | Sang danh sách 棚上げ (không cần tenant) | |
| TC-MENU-04 | Menu | Chạm **ピッキング** | Sang **テナント選択** (funcNumber=3) | |
| TC-MENU-05 | Menu | Chạm **事前セット** | Sang danh sách 事前セット | |
| TC-MENU-06 | Menu | Chạm **棚移動** | Sang danh sách 棚移動 | |
| TC-MENU-07 | Menu | Chạm **棚卸** | Sang danh sách 棚卸 | |
| TC-MENU-08 | Menu | Chạm **ログアウト** | Dialog **「ログアウトしますか？」** với **いいえ / はい** | |
| TC-MENU-09 | Dialog logout | Nhấn **はい** | Đăng xuất → về màn **login** | |
| TC-MENU-10 | Dialog logout | Nhấn **いいえ** | Đóng dialog, ở lại menu | |
| TC-MENU-11 | Máy Keyence | Nhấn phím cứng cạnh máy (keyCode 8–14) | Mở đúng module tương ứng | |

> ⚠️ **Lưu ý QA:** phím cứng 入荷/ピッキング điều hướng thẳng vào module root (không qua tenant), trong khi chạm tay lại đi qua tenant. Cần test cả 2 đường.

---

## 4. 入荷 / Warehouse Receipt

### 4a. Danh sách (入荷一覧)

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-WR-01 | Đã chọn tenant | Mở danh sách | AppBar **「入荷一覧 ({company})」**, load danh sách đơn | |
| TC-WR-02 | Có danh sách | Gõ ô tìm kiếm **「フィルターする内容を入力してください。」** | Lọc danh sách theo nội dung | |
| TC-WR-03 | Có đơn scanStatus=2 | Xem trạng thái | Nhãn **進行中** (màu warning) | |
| TC-WR-04 | Có đơn scanStatus=3 | Chạm đơn | Dialog **通知** báo user khác đang xử lý, nút **閉じる**, KHÔNG điều hướng | |
| TC-WR-05 | Đơn bình thường | Chạm đơn | Sang màn chi tiết 入荷 | |
| TC-WR-06 | Màn danh sách | Nhấn **絞り込み** | Mở màn filter | |
| TC-WR-07 | Màn danh sách | Nhấn **戻る** | Về **メニュー** | |
| TC-WR-08 | Không có dữ liệu | Mở danh sách | Hiện **「入荷データがありません」** | |

### 4b. Lọc (絞り込み)

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-WRF-01 | Màn filter | Quét/nhập JAN không tồn tại vào **商品JANコード** | SnackBar đỏ **「プロダクトコードが存在しません」** | |
| TC-WRF-02 | Màn filter | Nhập JAN hợp lệ | Lưu productCode tương ứng (không báo lỗi) | |
| TC-WRF-03 | Đã nhập nhiều field | Nhấn **クリア** | Xóa toàn bộ điều kiện lọc | |
| TC-WRF-04 | Đã chọn điều kiện | Nhấn **適用** | Đóng màn, danh sách áp dụng bộ lọc | |
| TC-WRF-05 | Field JAN/商品番号 | Nhấn nút QR | Mở dialog camera quét mã | |

### 4c. Chi tiết (入荷詳細)

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-WRD-01 | Vào chi tiết | Xem màn | Header **入荷番号:** + vị trí `{i}/{tổng}`; con trỏ focus ô JANコード | |
| TC-WRD-02 | Đơn không có dòng | Vào chi tiết | Hiện **「明細データがありません」** + nút **入荷一覧** | |
| TC-WRD-03 | Ô JANコード | Quét mã JAN | Điền dữ liệu, submit → xóa barcode & focus 実際数量 | |
| TC-WRD-04 | Có nhiều dòng | Chọn dropdown **商品** | Nhảy tới dòng sản phẩm đã chọn | |
| TC-WRD-05 | Ô 実際数量 rỗng | Nhấn **保存** | Banner đỏ **「実際数量を入力してください」** | |
| TC-WRD-06 | Đã nhập 実際数量 | Nhấn **保存** | Banner **「保存しました」**, tự nhảy sang dòng tiếp theo | |
| TC-WRD-07 | Ô 賞味期限 | Nhấn để chọn ngày | Mở date picker (từ hôm nay trở đi) | |
| TC-WRD-08 | Ô 状態 | Chọn dropdown | Có 3 lựa chọn **通常 / NG / 不足** | |
| TC-WRD-09 | Màn chi tiết | Chụp ảnh sản phẩm (商品写真撮り) | Hiện thumbnail, đếm "{n} 枚", có nút X để xóa | |
| TC-WRD-10 | Ở dòng đầu | Nút ← (prev) | Bị disable | |
| TC-WRD-11 | Ở dòng cuối | Nút → (next) | Bị disable | |
| TC-WRD-12 | Màn chi tiết | Nhấn **入荷一覧** | Quay về danh sách | |

> 📝 **Lưu ý:** 保存 ở màn 入荷 chỉ lưu **trong bộ nhớ** (không gọi API submit).

---

## 5. 棚上げ / Putaway

### 5a. Danh sách (棚上げ一覧)

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-PA-01 | Từ menu | Mở danh sách | AppBar **「棚上げ一覧」** | |
| TC-PA-02 | Đơn scanStatus=3 | Chạm đơn | Dialog **通知** user khác đang xử lý, **閉じる** | |
| TC-PA-03 | Đơn bình thường | Chạm đơn | Sang màn chi tiết 棚上げ | |
| TC-PA-04 | Không có dữ liệu | Mở danh sách | Hiện **「棚上げデータがありません」** | |

### 5b. Chi tiết + Hoàn thành

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-PAD-01 | Vào chi tiết | Xem màn | Header productCode/name + `{i}/{tổng}`; focus ô 棚番号 | |
| TC-PAD-02 | Ô 棚番号 | Quét mã bin | Điền bin, focus 実際数量 | |
| TC-PAD-03 | 棚番号 rỗng | Nhấn **保存** | Banner đỏ **「棚番号を入力してください」** | |
| TC-PAD-04 | Đã nhập 棚番号 | Nhấn **保存** | Banner **「保存しました」**, tự nhảy dòng tiếp | |
| TC-PAD-05 | Có dòng thiếu 棚番号 | Nhấn **棚上げ完了** | Banner lỗi **「棚番号が未入力の明細があります:\n{...}」** | |
| TC-PAD-06 | Tất cả dòng đủ bin | Nhấn **棚上げ完了** | Dialog xác nhận "{code} — {n}件の棚上げを登録しますか？" (**キャンセル/完了**) | |
| TC-PAD-07 | Dialog xác nhận | Nhấn **完了** | Spinner "棚上げ登録中...", sync server | |
| TC-PAD-08 | Sync thành công | — | Banner **「棚上げが完了しました」** → về danh sách 棚上げ | |
| TC-PAD-09 | Sync lỗi | — | Banner đỏ **「棚上げ完了に失敗しました: {...}」** | |

---

## 6. ピッキング / Picking

### 6a. Danh sách + Items

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-PK-01 | Đã chọn tenant | Mở danh sách | AppBar **「ピッキング一覧 ({company})」**; mỗi dòng hiện **「{n} 棚」** | |
| TC-PK-02 | Đơn scanStatus=2 | Chạm đơn | Dialog **通知** khóa, **閉じる** | |
| TC-PK-03 | Đơn bình thường | Chạm đơn | Sang màn items **「ピッキング: {pickNo}」** | |
| TC-PK-04 | Màn items | Xem dòng đã hoàn thành | Badge check xanh, số lượng **「{actual}/{pick}」** màu xanh | |
| TC-PK-05 | Màn items | Nhấn **開始** | Nhảy tới dòng chưa hoàn thành đầu tiên | |
| TC-PK-06 | Màn items | Chạm 1 dòng | Sang màn chi tiết dòng đó | |

### 6b. Chi tiết — luồng scan chính (có âm thanh 🔊)

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-PKD-01 | Vào chi tiết | Xem màn | Thanh tiến độ **「進捗: {done}/{total} 件完了」**; card thông tin sản phẩm | |
| TC-PKD-02 | Ô **棚番スキャン** | Quét đúng bin | 🔊 playCorrect, focus ô QR | |
| TC-PKD-03 | Ô 棚番 | Quét bin KHÁC bin cần lấy | Dialog **確認** "スキャンした棚番 [...] が... と違います。続けますか？" (**いいえ/はい**) | |
| TC-PKD-04 | Dialog bin khác | Nhấn **いいえ** | Xóa & focus lại ô bin | |
| TC-PKD-05 | Ô **QRコードスキャン** | Quét QR sai định dạng | 🔊 playError + banner **「QRコードの形式が正しくありません」** | |
| TC-PKD-06 | Ô QR | Quét QR sản phẩm KHÁC | 🔊 playError + **「スキャンした商品がピッキングすべき商品と違います」** | |
| TC-PKD-07 | Ô QR | Quét đúng sản phẩm | Số lượng +1, 🔊 playCorrect | |
| TC-PKD-08 | Đã đủ số lượng | Quét thêm 1 lần | 🔊 playWarning + **「実数量が必要数量を超えました」**, giữ nguyên = pickQty | |
| TC-PKD-09 | Đủ số lượng dòng | — | Tự nhảy dòng tiếp (hoặc dialog sync nếu là dòng cuối) | |
| TC-PKD-10 | Dòng cuối, tất cả xong | Nhấn **完了・送信** | Dialog **確認** "ピッキング番号 {pickNo} が完了しました。送信しますか？" | |
| TC-PKD-11 | Dialog sync | Nhấn **はい** | Spinner "データ同期中...", sync server | |
| TC-PKD-12 | Sync thành công | — | Banner **「データは正常に同期されました」** → về danh sách picking | |
| TC-PKD-13 | Sync lỗi | — | Banner lỗi "データ同期に失敗しました: ..." | |

---

## 7. 事前セット / Bundle

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-BD-01 | Từ menu | Mở danh sách | AppBar **「事前セット一覧」** | |
| TC-BD-02 | Danh sách | Cuộn xuống cuối | Có tile DEMO **`DEMO-TEST-001`** (dữ liệu test — không phải đơn thật) | |
| TC-BD-03 | Đơn scanStatus=2 | Chạm đơn | Dialog **通知** khóa, **閉じる** | |
| TC-BD-04 | Đơn bình thường | Chạm đơn | Sang màn items **「事前セット: {transNo}」** | |
| TC-BD-05 | Màn items | Xem chip trạng thái | **完了 / 一部対応 / 未対応** đúng theo actualQty vs demandQty | |
| TC-BD-06 | Màn items | Nhấn **開始** | Nhảy tới dòng chưa đủ số lượng | |
| TC-BDD-01 | Chi tiết | Ô 棚番 quét bin | Điền bin, focus QR | |
| TC-BDD-02 | Ô QRコード | Quét QR thiếu trường | Banner **「QRコードのフォーマットが正しくありません」** | |
| TC-BDD-03 | Ô QRコード | Quét QR sản phẩm khác | **「スキャンした商品が事前セットすべきの商品と違います。ご確認ください。」** | |
| TC-BDD-04 | Đủ số lượng | Quét thêm | **「実数量が必要な数量を超えました」**, giữ nguyên = demandQty | |
| TC-BDD-05 | Dòng cuối đủ | Nhấn **完了・送信** | Dialog **確認** "事前セット {transNo} が完了しました。送信しますか？" | |
| TC-BDD-06 | Dialog | Nhấn **はい** | Sync; thành công → **「データは正常に同期されました」** → danh sách | |
| TC-BDD-07 | Dialog | Nhấn **いいえ** | Về danh sách 事前セット (không gửi) | |

---

## 8. 棚移動 / Bin Movement

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-BM-01 | Từ menu | Mở danh sách | AppBar **「棚移動一覧」**, dòng có transferNo + description | |
| TC-BM-02 | Đơn scanStatus=3 | Chạm đơn | Dialog **通知** khóa, **閉じる** | |
| TC-BM-03 | Đơn bình thường | Chạm đơn | Sang chi tiết 棚移動 | |
| TC-BM-04 | Không có dữ liệu | Mở danh sách | Hiện **「棚移動データがありません」** | |
| TC-BMD-01 | Chi tiết | Xem màn | Hiện 移動元棚番号 (read-only), mũi tên **移動**, ô 移動先棚番号; focus 移動先 | |
| TC-BMD-02 | Ô 移動先棚番号 | Quét bin đích | Điền, focus 実際数量 | |
| TC-BMD-03 | 移動先棚番号 rỗng | Nhấn **保存** | Banner đỏ **「移動先棚番号を入力してください」** | |
| TC-BMD-04 | Đã nhập bin đích | Nhấn **保存** | Banner **「保存しました」**, nhảy dòng tiếp | |
| TC-BMD-05 | Có dòng thiếu bin đích | Nhấn **棚移動完了** | Banner lỗi **「移動先棚番号が未入力の明細があります:\n{...}」** | |
| TC-BMD-06 | Đủ bin đích | Nhấn **棚移動完了** | Dialog "{transferNo} — {n}件の棚移動を登録しますか？" (**キャンセル/完了**) | |
| TC-BMD-07 | Xác nhận **完了** | — | Spinner "棚移動登録中..."; thành công → **「棚移動が完了しました」** → danh sách | |
| TC-BMD-08 | Sync lỗi | — | Banner **「棚移動完了に失敗しました: {...}」** | |

---

## 9. 棚卸 / Bin Audit

| ID | Tiền điều kiện | Các bước | Kết quả mong đợi | KQ |
|---|---|---|---|---|
| TC-BA-01 | Từ menu | Mở danh sách | AppBar **「棚卸一覧」**, dòng có stockTakeNo + ngày + **「#{recordNo}」** | |
| TC-BA-02 | Danh sách | Xem trạng thái | **完了** (xanh) / **進行中** / **未開始** đúng | |
| TC-BA-03 | Danh sách | Chạm 1 dòng | Sang chi tiết (không có dialog khóa ở module này) | |
| TC-BA-04 | Không có dữ liệu | Mở danh sách | Hiện **「棚卸データがありません」** | |
| TC-BAD-01 | Bản ghi đang xử lý | Vào chi tiết | Các ô 実際数量 **cho phép sửa**; nút **スキャン** + **保存** hiện | |
| TC-BAD-02 | Bản ghi đã hoàn thành (status=1) | Vào chi tiết | Các ô 実際数量 **read-only**; không có nút スキャン/保存 | |
| TC-BAD-03 | Chi tiết (sửa được) | Nhấn **スキャン**, quét mã sản phẩm khớp | actualQty của dòng đó +1, đánh dấu **未保存**, banner "{code}: {cũ} → {mới}" | |
| TC-BAD-04 | Chi tiết | Quét mã KHÔNG khớp dòng nào | Banner lỗi **「「{code}」に一致する明細が見つかりません」** | |
| TC-BAD-05 | Chi tiết | Sửa tay ô 実際数量 | Cập nhật số, đánh dấu 未保存, header hiện "(未保存: {n}件)" | |
| TC-BAD-06 | Không có thay đổi | Nhấn **保存** | Banner **「変更がありません」** | |
| TC-BAD-07 | Có dòng 未保存 | Nhấn **保存** | Spinner "保存中...", gọi API ngay; thành công → **「{n}件を保存しました」**, xóa cờ 未保存 | |
| TC-BAD-08 | Sync lỗi | Nhấn **保存** | Banner **「保存に失敗しました: {...}」** | |
| TC-BAD-09 | Chi tiết | Nhấn **戻る** | Về danh sách 棚卸 | |

> 📝 **Lưu ý:** Khác các module khác, 棚卸 **保存 gọi API ngay** (không phải chỉ lưu bộ nhớ).

---

## Phụ lục — Ghi chú chung cho QA

**Nhãn trạng thái dùng chung:** 未開始 / 進行中 / ロック / 完了 / 一部対応 / 未対応.
Mã khóa (`scanStatus`) khác nhau theo module:
- 入荷 & 棚移動: `3`=khóa, `2`=đang xử lý
- 棚上げ: `3`=khóa, `1`=đang xử lý
- ピッキング & 事前セット: `2`=khóa, `1`=đang xử lý

**Dialog khóa (通知):** "ユーザー「{user khác}」は別デバイスで {số} を対応してます。ご確認ください。" — nút **閉じる**, KHÔNG điều hướng.

**Âm thanh:** chỉ màn Picking chi tiết có 🔊 (correct/error/warning). Các module khác dùng banner thông báo màu (đỏ=lỗi, màu module=thành công).

**Giới hạn số lượng:**
- ピッキング & 事前セット: **chặn** vượt số lượng cần (giữ nguyên + cảnh báo)
- 入荷 / 棚上げ / 棚移動: nhập số tự do
- 棚卸: nhập số bất kỳ (quét = +1)

**Lưu vào bộ nhớ vs API:**
| Module | 保存 | Hoàn thành/Gửi |
|---|---|---|
| 入荷 | Bộ nhớ (không API) | — |
| 棚上げ | Bộ nhớ | 棚上げ完了 → API |
| 棚移動 | Bộ nhớ | 棚移動完了 → API |
| ピッキング | — | 完了・送信 → API |
| 事前セット | — | 完了・送信 → API |
| 棚卸 | **API ngay** | — |

**Date picker:** ở mọi màn, ngày bắt đầu = hôm nay, format `yyyy-MM-dd` (danh sách hiển thị `yyyy/MM/dd`).
