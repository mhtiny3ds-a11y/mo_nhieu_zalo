# Mở nhiều Zalo

Mở **nhiều tài khoản Zalo PC cùng một lúc** trên Windows, không cần cài phần mềm lạ.

Zalo PC chỉ cho mở một cửa sổ vì nó lưu dữ liệu đăng nhập ở một thư mục cố định (`%APPDATA%`). Repo này cho mỗi tài khoản phụ một thư mục dữ liệu riêng bằng cách chạy Zalo với các biến `USERPROFILE`, `APPDATA`, `LOCALAPPDATA` trỏ sang chỗ khác. Kết quả là mỗi tài khoản chạy một cửa sổ Zalo độc lập, song song với nhau.

Có 3 cách dùng, chọn một cách phù hợp:

| Cách | Dành cho | Cần làm gì |
|---|---|---|
| [1. Web app tạo file .bat](#cách-1-web-app-tạo-file-bat) | Người muốn đặt tên tài khoản tùy ý | Mở trang web, bấm Tải về |
| [2. File .bat có sẵn](#cách-2-file-bat-có-sẵn) | Người muốn dùng ngay | Tải file, nhấp đúp |
| [3. App có giao diện](#cách-3-app-có-giao-diện-monhieuzalo) | Người muốn quản lý nhiều tài khoản bằng nút bấm | Chạy app hoặc file .exe |

Cả 3 cách dùng **chung một thư mục dữ liệu** (`%USERPROFILE%\ZaloMulti\<tên>`). Vì vậy bạn có thể bắt đầu bằng file `.bat` rồi chuyển sang app mà không phải đăng nhập lại, miễn là tên thư mục trùng nhau.

---

## Cách 1: Web app tạo file .bat

Mở **https://mhtiny3ds-a11y.github.io/mo_nhieu_zalo/** (cần bật GitHub Pages, xem [bên dưới](#bật-github-pages)), hoặc mở file [`index.html`](index.html) ngay trên máy.

1. Nhập tên các tài khoản phụ, ví dụ `Bán hàng`, `Cá nhân`. Tên có dấu cũng được, tên thư mục sẽ tự bỏ dấu.
2. Chọn kiểu file:
   - **Một file mở tất cả**: nhấp đúp một lần, mọi cửa sổ lần lượt hiện ra.
   - **Mỗi tài khoản một file**: mở riêng từng tài khoản.
3. Bấm **Tải về** (hoặc **Sao chép** rồi dán vào Notepad và lưu với đuôi `.bat`).
4. Nhấp đúp file `.bat` vừa tải.

Trang chạy hoàn toàn trên trình duyệt và không gửi dữ liệu đi đâu.

## Cách 2: File .bat có sẵn

Trong thư mục [`bat/`](bat):

| File | Tác dụng |
|---|---|
| [`Mo-tat-ca-Zalo.bat`](bat/Mo-tat-ca-Zalo.bat) | Mở Zalo chính và 3 tài khoản phụ (`TaiKhoan2`, `TaiKhoan3`, `TaiKhoan4`), mỗi cửa sổ cách nhau 3 giây |
| [`Zalo-TaiKhoan2.bat`](bat/Zalo-TaiKhoan2.bat) | Chỉ mở tài khoản phụ 2 |
| [`Zalo-TaiKhoan3.bat`](bat/Zalo-TaiKhoan3.bat) | Chỉ mở tài khoản phụ 3 |
| [`Zalo-TaiKhoan4.bat`](bat/Zalo-TaiKhoan4.bat) | Chỉ mở tài khoản phụ 4 |

**Cách tải:** mở file trên GitHub, bấm nút **Download raw file** (biểu tượng mũi tên xuống) ở góc phải. Hoặc tải cả repo: nút **Code → Download ZIP**.

**Muốn thêm hoặc bớt tài khoản:** mở file bằng Notepad.
- Trong `Mo-tat-ca-Zalo.bat`, thêm hoặc xóa dòng `call :open "TenThuMuc"`.
- Muốn có thêm file lẻ, copy `Zalo-TaiKhoan2.bat` thành file mới rồi sửa `TaiKhoan2` thành tên khác.
- Tên thư mục chỉ nên gồm chữ không dấu, số, `-` và `_`.

**Không muốn mở Zalo chính:** xóa 2 dòng ngay dưới `:: Zalo chinh`.

## Cách 3: App có giao diện (MoNhieuZalo)

App nằm trong thư mục [`app/`](app). Đây là một cửa sổ Windows (viết bằng PowerShell + WinForms) với các chức năng:

- Danh sách tài khoản, hiện trạng thái *Đã có dữ liệu* hoặc *Chưa mở lần nào*.
- **Mở đã chọn** (giữ `Ctrl` để chọn nhiều, hoặc nhấp đúp một dòng) và **Mở tất cả**, có tùy chọn mở kèm Zalo chính.
- **Thêm, đổi tên, xóa tài khoản.** Khi xóa có thể chọn xóa luôn dữ liệu đăng nhập hoặc chỉ xóa khỏi danh sách.
- **Mở thư mục dữ liệu** của từng tài khoản.
- **Chỉnh thời gian chờ** giữa các cửa sổ và **chọn lại đường dẫn `Zalo.exe`** nếu Zalo cài ở chỗ khác.
- Danh sách tài khoản và cài đặt được lưu ở `%APPDATA%\MoNhieuZalo\config.json`.

### Chạy không cần build

Tải 2 file `app/MoNhieuZalo.ps1` và `app/Chay-MoNhieuZalo.bat` vào **cùng một thư mục**, rồi nhấp đúp `Chay-MoNhieuZalo.bat`.

### Tải file .exe có sẵn

Mỗi lần mã trong `app/` thay đổi trên nhánh `main`, GitHub Actions tự build `MoNhieuZalo.exe`:

1. Vào tab **Actions** của repo, chọn lần chạy mới nhất của **Build MoNhieuZalo.exe**.
2. Ở mục **Artifacts**, tải `MoNhieuZalo` (file `.zip` chứa `MoNhieuZalo.exe`). Mục này yêu cầu đăng nhập GitHub.

Khi tạo một **Release** trên GitHub, file `.exe` cũng được tự đính kèm vào Release đó. Ai cũng tải được, không cần đăng nhập.

### Tự build .exe trên máy

Mở PowerShell trong thư mục `app` rồi chạy:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

Script sẽ tự cài module [ps2exe](https://github.com/MScholtes/PS2EXE) (chỉ lần đầu) rồi tạo `MoNhieuZalo.exe`. Muốn exe có biểu tượng riêng, đặt file `icon.ico` cạnh `build.ps1` trước khi build.

---

## Lần đầu đăng nhập

- Mỗi cửa sổ Zalo mới mở ra màn hình **quét mã QR**. Bạn quét bằng ứng dụng Zalo trên điện thoại của đúng tài khoản đó. Từ lần sau Zalo tự đăng nhập.
- Tài khoản phụ có dữ liệu riêng, nên lần đầu có thể phải **đồng bộ tin nhắn** từ điện thoại.
- Tài khoản chính vẫn dùng dữ liệu Zalo gốc trên máy, không bị ảnh hưởng.

## Đăng xuất hoặc xóa một tài khoản phụ

- **Trong app:** chọn tài khoản → **Xóa tài khoản** → **Có**.
- **Thủ công:** đóng cửa sổ Zalo của tài khoản đó, rồi xóa thư mục `%USERPROFILE%\ZaloMulti\<tên>`. Dán đường dẫn này vào thanh địa chỉ của File Explorer để mở nhanh.

## Câu hỏi thường gặp

**Windows báo "Windows protected your PC" (SmartScreen)?**
Vì file tải từ Internet và chưa được ký số. Bấm **More info → Run anyway**. Bạn có thể mở file `.bat` hoặc `.ps1` bằng Notepad để tự kiểm tra: chỉ có vài lệnh tạo thư mục và mở Zalo.

**Báo "Không tìm thấy Zalo"?**
Zalo được cài ở chỗ khác. Chuột phải shortcut Zalo → **Open file location** để xem đường dẫn thật.
- Với file `.bat`: sửa dòng `set "ZALO_EXE=..."`.
- Với app: bấm **Đổi...**

**Cửa sổ thứ hai không hiện ra, hoặc hiện ra nhưng vẫn là tài khoản chính?**
- Đảm bảo bạn mở qua file `.bat` hoặc app, không mở bằng shortcut Zalo gốc.
- Thử tăng thời gian chờ lên 5 đến 10 giây.
- Nếu một bản cập nhật Zalo làm cách này ngừng hoạt động, hãy [tạo issue](https://github.com/mhtiny3ds-a11y/mo_nhieu_zalo/issues) kèm phiên bản Zalo (Cài đặt → Thông tin phiên bản). Trong lúc chờ sửa, có thể dùng [Sandboxie-Plus](https://sandboxie-plus.com/) hoặc Zalo Web (`chat.zalo.me`) ở một trình duyệt khác.

**Cách này có an toàn cho tài khoản không?**
Repo chỉ mở chính phần mềm Zalo gốc trên máy bạn, không sửa file của Zalo, không đọc hay gửi dữ liệu đi đâu. Đừng tải các bản "Zalo nhân bản" không rõ nguồn: chúng hay chứa mã độc đánh cắp tài khoản.

**Có dùng trên macOS được không?**
Không. Repo này chỉ dành cho Windows.

## Cấu trúc repo

```
index.html                 Web app tạo file .bat (dùng cho GitHub Pages)
bat/                       Các file .bat mẫu
app/MoNhieuZalo.ps1        App có giao diện
app/Chay-MoNhieuZalo.bat   Chạy app không cần build
app/build.ps1              Build app thành .exe (ps2exe)
.github/workflows/         Tự build .exe trên GitHub Actions
```

## Bật GitHub Pages

Dành cho chủ repo: vào **Settings → Pages**. Ở mục *Build and deployment*, chọn **Source: Deploy from a branch**, **Branch: `main`**, thư mục **`/ (root)`**, rồi bấm **Save**. Sau khoảng 1 phút, web app có ở `https://mhtiny3ds-a11y.github.io/mo_nhieu_zalo/`.

---

Công cụ không chính thức, không liên quan tới Zalo hay VNG.
