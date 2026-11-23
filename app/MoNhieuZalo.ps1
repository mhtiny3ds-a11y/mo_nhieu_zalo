#Requires -Version 5.1
<#
  MoNhieuZalo - mo nhieu tai khoan Zalo PC cung luc tren Windows.

  Moi tai khoan phu duoc chay voi USERPROFILE / APPDATA / LOCALAPPDATA tro toi
  mot thu muc rieng, nen Zalo luu du lieu dang nhap tach biet va cho phep mo
  nhieu cua so song song. Thu muc mac dinh (%USERPROFILE%\ZaloMulti\<ten>)
  trung voi cac file .bat trong repo, nen hai cach dung chung du lieu voi nhau.

  Chay: nhap dup Chay-MoNhieuZalo.bat, hoac build ra .exe bang build.ps1.
  Luu y: file nay phai duoc luu dang UTF-8 co BOM de Windows PowerShell 5.1
  hien dung tieng Viet.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()

$ErrorActionPreference = 'Stop'
$AppTitle = 'Mở Nhiều Zalo'

# Duong dan that cua nguoi dung (khong bi anh huong boi bien moi truong)
$RealAppData = [Environment]::GetFolderPath('ApplicationData')
$RealLocal   = [Environment]::GetFolderPath('LocalApplicationData')
$RealProfile = [Environment]::GetFolderPath('UserProfile')
$ConfigDir   = Join-Path $RealAppData 'MoNhieuZalo'
$ConfigFile  = Join-Path $ConfigDir 'config.json'

# ---------------------------------------------------------------- cau hinh

function New-DefaultConfig {
    [pscustomobject]@{
        ZaloExe      = Join-Path $RealLocal 'Programs\Zalo\Zalo.exe'
        BaseDir      = Join-Path $RealProfile 'ZaloMulti'
        DelaySeconds = 3
        OpenMain     = $true
        Accounts     = @([pscustomobject]@{ Name = 'Tài khoản 2'; Folder = 'TaiKhoan2' })
    }
}

function Import-AppConfig {
    $def = New-DefaultConfig
    if (-not (Test-Path -LiteralPath $ConfigFile)) { return $def }
    try {
        $raw = Get-Content -LiteralPath $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Không đọc được file cấu hình, sẽ dùng cấu hình mặc định.`n$ConfigFile", $AppTitle) | Out-Null
        return $def
    }
    foreach ($p in 'ZaloExe', 'BaseDir', 'DelaySeconds', 'OpenMain') {
        if ($null -ne $raw.$p -and "$($raw.$p)" -ne '') { $def.$p = $raw.$p }
    }
    if ($null -ne $raw.Accounts) {
        $def.Accounts = @($raw.Accounts | Where-Object { $_.Folder } |
            ForEach-Object { [pscustomobject]@{ Name = [string]$_.Name; Folder = [string]$_.Folder } })
    }
    return $def
}

function Save-AppConfig {
    if (-not (Test-Path -LiteralPath $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
    $script:Config.Accounts = @($script:Config.Accounts)
    $script:Config | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ConfigFile -Encoding UTF8
}

# ---------------------------------------------------------------- tien ich

function ConvertTo-Slug([string]$Text) {
    $d = $Text.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $d.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    $s = $sb.ToString() -creplace 'đ', 'd' -creplace 'Đ', 'D'
    $s = ($s -replace '[^A-Za-z0-9_-]+', '-').Trim('-')
    if (-not $s) { $s = 'TaiKhoan' }
    return $s
}

function Get-UniqueFolder([string]$Name) {
    $base = ConvertTo-Slug $Name
    $used = @($script:Config.Accounts | ForEach-Object { $_.Folder.ToLower() })
    $f = $base; $n = 2
    while ($used -contains $f.ToLower()) { $f = "$base-$n"; $n++ }
    return $f
}

function Get-ProfileDir($Account) { Join-Path $script:Config.BaseDir $Account.Folder }

function Show-Error([string]$Msg) {
    [System.Windows.Forms.MessageBox]::Show($Msg, $AppTitle, 'OK', 'Error') | Out-Null
}

function Select-ZaloExe {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Chọn file Zalo.exe'
    $dlg.Filter = 'Zalo.exe|Zalo.exe|Chương trình (*.exe)|*.exe'
    $cur = $script:Config.ZaloExe
    if ($cur -and (Test-Path -LiteralPath (Split-Path $cur -Parent))) { $dlg.InitialDirectory = Split-Path $cur -Parent }
    if ($dlg.ShowDialog() -eq 'OK') {
        $script:Config.ZaloExe = $dlg.FileName
        Save-AppConfig
        Update-Status
        return $true
    }
    return $false
}

function Test-ZaloExe {
    if (Test-Path -LiteralPath $script:Config.ZaloExe) { return $true }
    $r = [System.Windows.Forms.MessageBox]::Show(
        "Không tìm thấy Zalo tại:`n$($script:Config.ZaloExe)`n`nBạn muốn chọn file Zalo.exe ngay bây giờ?",
        $AppTitle, 'YesNo', 'Warning')
    if ($r -eq 'Yes') { return (Select-ZaloExe) }
    return $false
}

# ---------------------------------------------------------------- mo Zalo

function Start-ZaloMain {
    Start-Process -FilePath $script:Config.ZaloExe -WorkingDirectory (Split-Path $script:Config.ZaloExe -Parent)
}

function Start-ZaloProfile($Account) {
    $dir = Get-ProfileDir $Account
    $roaming = Join-Path $dir 'AppData\Roaming'
    $local   = Join-Path $dir 'AppData\Local'
    New-Item -ItemType Directory -Path $roaming, $local -Force | Out-Null

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:Config.ZaloExe
    $psi.WorkingDirectory = Split-Path $script:Config.ZaloExe -Parent
    $psi.UseShellExecute = $false
    $psi.EnvironmentVariables['USERPROFILE']  = $dir
    $psi.EnvironmentVariables['APPDATA']      = $roaming
    $psi.EnvironmentVariables['LOCALAPPDATA'] = $local
    [System.Diagnostics.Process]::Start($psi) | Out-Null
}

function Wait-Delay {
    $ms = [int]$script:Config.DelaySeconds * 1000
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $ms) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }
}

function Open-Accounts($Accounts, [bool]$WithMain) {
    if (-not (Test-ZaloExe)) { return }
    $form.Cursor = 'WaitCursor'
    $form.Enabled = $false
    try {
        $first = $true
        if ($WithMain) { Start-ZaloMain; $first = $false }
        foreach ($a in $Accounts) {
            if (-not $first) { Wait-Delay }
            $lblStatus.Text = "Đang mở: $($a.Name)..."
            [System.Windows.Forms.Application]::DoEvents()
            Start-ZaloProfile $a
            $first = $false
        }
    } catch {
        Show-Error "Không mở được Zalo: $($_.Exception.Message)"
    } finally {
        $form.Enabled = $true
        $form.Cursor = 'Default'
        Update-Status
        Update-List
    }
}

# ---------------------------------------------------------------- giao dien

$script:Config = Import-AppConfig

$form = New-Object System.Windows.Forms.Form
$form.Text = $AppTitle
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(640, 460)
$form.MinimumSize = New-Object System.Drawing.Size(560, 380)
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($script:Config.ZaloExe) } catch { }

$layout = New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock = 'Fill'
$layout.Padding = New-Object System.Windows.Forms.Padding(10)
$layout.ColumnCount = 1
$layout.RowCount = 3
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100)))
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('AutoSize')))
$form.Controls.Add($layout)

$lblIntro = New-Object System.Windows.Forms.Label
$lblIntro.AutoSize = $true
$lblIntro.MaximumSize = New-Object System.Drawing.Size(600, 0)
$lblIntro.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 8)
$lblIntro.Text = 'Chọn tài khoản rồi bấm Mở (giữ Ctrl để chọn nhiều). Lần đầu, mỗi tài khoản cần quét mã QR bằng điện thoại; từ lần sau Zalo tự đăng nhập.'
$layout.Controls.Add($lblIntro, 0, 0)

# Hang giua: danh sach + cot nut
$mid = New-Object System.Windows.Forms.Panel
$mid.Dock = 'Fill'
$mid.Margin = New-Object System.Windows.Forms.Padding(0)
$layout.Controls.Add($mid, 0, 1)

$buttons = New-Object System.Windows.Forms.FlowLayoutPanel
$buttons.Dock = 'Right'
$buttons.FlowDirection = 'TopDown'
$buttons.WrapContents = $false
$buttons.Width = 170
$buttons.Padding = New-Object System.Windows.Forms.Padding(10, 0, 0, 0)
$mid.Controls.Add($buttons)

$list = New-Object System.Windows.Forms.ListView
$list.Dock = 'Fill'
$list.View = 'Details'
$list.FullRowSelect = $true
$list.HideSelection = $false
$list.MultiSelect = $true
[void]$list.Columns.Add('Tài khoản', 190)
[void]$list.Columns.Add('Thư mục', 120)
[void]$list.Columns.Add('Trạng thái', 110)
$mid.Controls.Add($list)
$list.BringToFront()

function New-Button([string]$Text, [bool]$Primary = $false) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Width = 155
    $b.Height = 32
    $b.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 6)
    if ($Primary) { $b.Font = New-Object System.Drawing.Font($form.Font, [System.Drawing.FontStyle]::Bold) }
    $buttons.Controls.Add($b)
    return $b
}

$btnOpen    = New-Button 'Mở đã chọn' $true
$btnOpenAll = New-Button 'Mở tất cả' $true
$sep = New-Object System.Windows.Forms.Label; $sep.Height = 8; $sep.Width = 10; $buttons.Controls.Add($sep)
$btnAdd     = New-Button 'Thêm tài khoản'
$btnRename  = New-Button 'Đổi tên'
$btnRemove  = New-Button 'Xóa tài khoản'
$btnFolder  = New-Button 'Mở thư mục dữ liệu'

# Hang duoi: tuy chon
$bottom = New-Object System.Windows.Forms.TableLayoutPanel
$bottom.Dock = 'Fill'
$bottom.AutoSize = $true
$bottom.ColumnCount = 3
$bottom.RowCount = 3
$bottom.Margin = New-Object System.Windows.Forms.Padding(0, 10, 0, 0)
[void]$bottom.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
[void]$bottom.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
[void]$bottom.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
$layout.Controls.Add($bottom, 0, 2)

$chkMain = New-Object System.Windows.Forms.CheckBox
$chkMain.Text = 'Khi bấm "Mở tất cả", mở kèm Zalo chính'
$chkMain.AutoSize = $true
$chkMain.Checked = [bool]$script:Config.OpenMain
$bottom.Controls.Add($chkMain, 0, 0)
$bottom.SetColumnSpan($chkMain, 2)

$delayPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$delayPanel.AutoSize = $true
$delayPanel.WrapContents = $false
$delayPanel.Margin = New-Object System.Windows.Forms.Padding(0)
$lblDelay = New-Object System.Windows.Forms.Label
$lblDelay.Text = 'Chờ giữa các cửa sổ (giây):'
$lblDelay.AutoSize = $true
$lblDelay.Margin = New-Object System.Windows.Forms.Padding(0, 6, 4, 0)
$numDelay = New-Object System.Windows.Forms.NumericUpDown
$numDelay.Minimum = 0
$numDelay.Maximum = 15
$numDelay.Width = 50
$numDelay.Value = [Math]::Min(15, [Math]::Max(0, [int]$script:Config.DelaySeconds))
$delayPanel.Controls.AddRange(@($lblDelay, $numDelay))
$bottom.Controls.Add($delayPanel, 2, 0)

$lblExeCap = New-Object System.Windows.Forms.Label
$lblExeCap.Text = 'Zalo.exe:'
$lblExeCap.AutoSize = $true
$lblExeCap.Margin = New-Object System.Windows.Forms.Padding(0, 9, 6, 0)
$bottom.Controls.Add($lblExeCap, 0, 1)

$txtExe = New-Object System.Windows.Forms.TextBox
$txtExe.ReadOnly = $true
$txtExe.Dock = 'Fill'
$txtExe.Margin = New-Object System.Windows.Forms.Padding(0, 6, 6, 0)
$bottom.Controls.Add($txtExe, 1, 1)

$btnExe = New-Object System.Windows.Forms.Button
$btnExe.Text = 'Đổi...'
$btnExe.Width = 70
$btnExe.Height = 28
$btnExe.Margin = New-Object System.Windows.Forms.Padding(0, 4, 0, 0)
$bottom.Controls.Add($btnExe, 2, 1)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.AutoSize = $true
$lblStatus.ForeColor = [System.Drawing.SystemColors]::GrayText
$lblStatus.Margin = New-Object System.Windows.Forms.Padding(0, 8, 0, 0)
$bottom.Controls.Add($lblStatus, 0, 2)
$bottom.SetColumnSpan($lblStatus, 3)

function Update-Status {
    $txtExe.Text = $script:Config.ZaloExe
    if (Test-Path -LiteralPath $script:Config.ZaloExe) {
        $lblStatus.Text = "Dữ liệu tài khoản phụ lưu tại: $($script:Config.BaseDir)"
        $lblStatus.ForeColor = [System.Drawing.SystemColors]::GrayText
    } else {
        $lblStatus.Text = 'Không tìm thấy Zalo.exe. Bấm "Đổi..." để chọn đúng file.'
        $lblStatus.ForeColor = [System.Drawing.Color]::Firebrick
    }
}

function Update-List {
    $sel = @($list.SelectedItems | ForEach-Object { $_.Tag.Folder })
    $list.BeginUpdate()
    $list.Items.Clear()
    foreach ($a in $script:Config.Accounts) {
        $item = New-Object System.Windows.Forms.ListViewItem($a.Name)
        [void]$item.SubItems.Add($a.Folder)
        $state = if (Test-Path -LiteralPath (Join-Path (Get-ProfileDir $a) 'AppData\Roaming')) { 'Đã có dữ liệu' } else { 'Chưa mở lần nào' }
        [void]$item.SubItems.Add($state)
        $item.Tag = $a
        if ($sel -contains $a.Folder) { $item.Selected = $true }
        [void]$list.Items.Add($item)
    }
    $list.EndUpdate()
    $has = $list.SelectedItems.Count -gt 0
    $btnOpen.Enabled = $has
    $btnRename.Enabled = $list.SelectedItems.Count -eq 1
    $btnRemove.Enabled = $has
    $btnOpenAll.Enabled = ($script:Config.Accounts.Count -gt 0) -or $chkMain.Checked
}

function Get-SelectedAccounts { @($list.SelectedItems | ForEach-Object { $_.Tag }) }

# ---------------------------------------------------------------- su kien

$list.Add_SelectedIndexChanged({
    $has = $list.SelectedItems.Count -gt 0
    $btnOpen.Enabled = $has
    $btnRename.Enabled = $list.SelectedItems.Count -eq 1
    $btnRemove.Enabled = $has
})
$list.Add_DoubleClick({ $s = Get-SelectedAccounts; if ($s.Count) { Open-Accounts $s $false } })

$btnOpen.Add_Click({ Open-Accounts (Get-SelectedAccounts) $false })
$btnOpenAll.Add_Click({ Open-Accounts @($script:Config.Accounts) $chkMain.Checked })

$btnAdd.Add_Click({
    $n = $script:Config.Accounts.Count + 2
    $name = [Microsoft.VisualBasic.Interaction]::InputBox('Tên tài khoản (ví dụ: Bán hàng, Cá nhân):', $AppTitle, "Tài khoản $n")
    $name = $name.Trim()
    if (-not $name) { return }
    $acc = [pscustomobject]@{ Name = $name; Folder = (Get-UniqueFolder $name) }
    $script:Config.Accounts = @($script:Config.Accounts) + $acc
    Save-AppConfig
    Update-List
})

$btnRename.Add_Click({
    $a = (Get-SelectedAccounts)[0]
    if (-not $a) { return }
    $name = [Microsoft.VisualBasic.Interaction]::InputBox('Tên mới (thư mục dữ liệu giữ nguyên, không phải đăng nhập lại):', $AppTitle, $a.Name)
    $name = $name.Trim()
    if (-not $name) { return }
    $a.Name = $name
    Save-AppConfig
    Update-List
})

$btnRemove.Add_Click({
    $sel = Get-SelectedAccounts
    if (-not $sel.Count) { return }
    $names = ($sel | ForEach-Object { "• $($_.Name)" }) -join "`n"
    $r = [System.Windows.Forms.MessageBox]::Show(
        "Xóa khỏi danh sách:`n$names`n`nXóa luôn dữ liệu đăng nhập (tin nhắn đã tải, file nhận) của các tài khoản này?`n`nCó: xóa cả dữ liệu   Không: chỉ xóa khỏi danh sách   Hủy: không làm gì",
        $AppTitle, 'YesNoCancel', 'Question')
    if ($r -eq 'Cancel') { return }
    $baseFull = [IO.Path]::GetFullPath($script:Config.BaseDir).TrimEnd('\') + '\'
    foreach ($a in $sel) {
        if ($r -eq 'Yes') {
            $dir = [IO.Path]::GetFullPath((Get-ProfileDir $a))
            if ($dir.StartsWith($baseFull, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $dir)) {
                try { Remove-Item -LiteralPath $dir -Recurse -Force }
                catch { Show-Error "Không xóa được dữ liệu của `"$($a.Name)`". Hãy đóng cửa sổ Zalo của tài khoản này rồi thử lại.`n`n$($_.Exception.Message)"; continue }
            }
        }
        $script:Config.Accounts = @($script:Config.Accounts | Where-Object { $_.Folder -ne $a.Folder })
    }
    Save-AppConfig
    Update-List
})

$btnFolder.Add_Click({
    $sel = Get-SelectedAccounts
    $target = if ($sel.Count -eq 1 -and (Test-Path -LiteralPath (Get-ProfileDir $sel[0]))) { Get-ProfileDir $sel[0] } else { $script:Config.BaseDir }
    if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
    Start-Process explorer.exe -ArgumentList "`"$target`""
})

$btnExe.Add_Click({ [void](Select-ZaloExe) })
$chkMain.Add_CheckedChanged({ $script:Config.OpenMain = $chkMain.Checked; Save-AppConfig; Update-List })
$numDelay.Add_ValueChanged({ $script:Config.DelaySeconds = [int]$numDelay.Value; Save-AppConfig })
$form.Add_Activated({ Update-List })

Update-Status
Update-List
[void]$form.ShowDialog()
