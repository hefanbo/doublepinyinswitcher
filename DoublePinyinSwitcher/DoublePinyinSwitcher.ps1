# Create a tray icon application to toggle between full-pinyin and double-pinyin for Microsoft Pinyin

Add-Type -AssemblyName System.Drawing, System.Windows.Forms

$reg_path = "Registry::HKEY_CURRENT_USER\Software\Microsoft\InputMethod\Settings\CHS"
$reg_name = "Enable Double Pinyin"

$icon_full = [System.Drawing.Icon]::ExtractAssociatedIcon("full.ico")
$icon_double = [System.Drawing.Icon]::ExtractAssociatedIcon("double.ico")

function isDoublePinyin {
    return (Get-ItemProperty -Path $reg_path -Name $reg_name).$reg_name -eq 1
}

# Create a tray icon
$notifyicon = New-Object System.Windows.Forms.NotifyIcon
$notifyicon.Text = "全拼/双拼切换"
if (isDoublePinyin) {
    $notifyicon.Icon = $icon_double
} else {
    $notifyicon.Icon = $icon_full
}
$notifyicon.Visible = $true

$menuitem = New-Object System.Windows.Forms.MenuItem
$menuitem.Text = "退出"

$contextmenu = New-Object System.Windows.Forms.ContextMenu
$notifyicon.ContextMenu = $contextmenu
$notifyicon.contextMenu.MenuItems.AddRange($menuitem)

# Left click to toggle full/double-pinyin
$notifyicon.add_Click({
    if ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
        if (isDoublePinyin) {
            Set-ItemProperty -Path $reg_path -Name $reg_name -Value 0
            $notifyicon.Icon = $icon_full
        } else {
            Set-ItemProperty -Path $reg_path -Name $reg_name -Value 1
            $notifyicon.Icon = $icon_double
        }
    }
})

# Exit
$menuitem.add_Click({
   $notifyicon.Visible = $false
   Stop-Process $pid
})

# Hide PowerShell window
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)

# Force garbage collection
[System.GC]::Collect()

# Improve responsiveness, especially when clicking Exit
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)
