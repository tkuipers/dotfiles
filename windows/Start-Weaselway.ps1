# Starts the Weaselway session and both viewers, then maximizes each on its
# monitor: display 1 on the left, display 2 on the right. Safe to run again:
# it only starts what is missing and puts the windows back.

$ErrorActionPreference = "Stop"
$distro = "Weaselway"
$ports = @{ 1 = 3389; 2 = 3390 }

Add-Type -AssemblyName System.Windows.Forms
Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class WeaselwayWindows {
    delegate bool EnumProc(IntPtr hwnd, IntPtr param);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc proc, IntPtr param);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hwnd, int cmd);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int w, int h, uint flags);
    public static IntPtr Find(uint wanted) {
        IntPtr found = IntPtr.Zero;
        EnumWindows((hwnd, param) => {
            uint pid;
            GetWindowThreadProcessId(hwnd, out pid);
            if (pid == wanted && IsWindowVisible(hwnd)) { found = hwnd; return false; }
            return true;
        }, IntPtr.Zero);
        return found;
    }
    public static void Maximize(IntPtr hwnd, int x, int y) {
        ShowWindow(hwnd, 9);                                   // SW_RESTORE
        SetWindowPos(hwnd, IntPtr.Zero, x, y, 0, 0, 0x0015);   // no size, z-order or activation
        ShowWindow(hwnd, 3);                                   // SW_MAXIMIZE
    }
}
'@

function Get-ViewerPid([int]$port) {
    $viewer = Get-CimInstance Win32_Process -Filter "Name = 'sdl-freerdp.exe'" |
        Where-Object { $_.CommandLine -match ":$port(\s|`"|$)" } |
        Select-Object -First 1
    if ($viewer) { return [uint32]$viewer.ProcessId }
    return $null
}

& wsl.exe -d $distro -- bash -lc "systemctl is-active --quiet weaselway-session || ww-start-session"

foreach ($display in 1, 2) {
    if (Get-ViewerPid $ports[$display]) { continue }
    if ($display -eq 1) {
        & wsl.exe -d $distro -- bash -lc "ww-start-viewer -decorations -grab-keyboard"
    } else {
        & wsl.exe -d $distro -- bash -lc "ww-start-viewer --display $display -decorations -grab-keyboard"
    }
}

$screens = @([System.Windows.Forms.Screen]::AllScreens | Sort-Object { $_.Bounds.X })
foreach ($display in 1, 2) {
    $hwnd = [IntPtr]::Zero
    for ($i = 0; $i -lt 60 -and $hwnd -eq [IntPtr]::Zero; $i++) {
        $viewerPid = Get-ViewerPid $ports[$display]
        if ($viewerPid) { $hwnd = [WeaselwayWindows]::Find($viewerPid) }
        if ($hwnd -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 500 }
    }
    if ($hwnd -eq [IntPtr]::Zero) { throw "No window for the viewer of display $display" }
    $screen = $screens[[Math]::Min($display - 1, $screens.Count - 1)]
    [WeaselwayWindows]::Maximize($hwnd, $screen.WorkingArea.X, $screen.WorkingArea.Y)
}
