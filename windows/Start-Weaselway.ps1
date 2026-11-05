# Starts the Weaselway session and both viewers, then maximizes each on its
# monitor: display 1 on the left, display 2 on the right. Safe to run again:
# it only starts what is missing and puts the windows back.

$ErrorActionPreference = "Stop"
# The shortcut hides this window, so this is the only trace of a failed start.
Start-Transcript -Path "$env:TEMP\weaselway-launch.log" -Force | Out-Null
$distro = "Weaselway"
$ports = @{ 1 = 3389; 2 = 3390 }

Add-Type -AssemblyName System.Windows.Forms
Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential, Pack = 4)]
public struct PropertyKey { public Guid Format; public uint Id; }
[StructLayout(LayoutKind.Sequential)]
public struct PropVariant { public ushort Type; public ushort R1, R2, R3; public IntPtr Value; public IntPtr Extra; }
[ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IPropertyStore {
    void GetCount(out uint count);
    void GetAt(uint index, out PropertyKey key);
    void GetValue(ref PropertyKey key, out PropVariant value);
    void SetValue(ref PropertyKey key, ref PropVariant value);
    void Commit();
}
public static class WeaselwayWindows {
    [DllImport("shell32.dll")] static extern int SHGetPropertyStoreForWindow(IntPtr hwnd, ref Guid iid, out IPropertyStore store);
    // The taskbar groups windows under the pin that has the same app id.
    public static void SetAppId(IntPtr hwnd, string appId) {
        Guid iid = typeof(IPropertyStore).GUID;
        IPropertyStore store;
        Marshal.ThrowExceptionForHR(SHGetPropertyStoreForWindow(hwnd, ref iid, out store));
        PropertyKey key = new PropertyKey { Format = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), Id = 5 };
        PropVariant value = new PropVariant { Type = 31, Value = Marshal.StringToCoTaskMemUni(appId) };
        store.SetValue(ref key, ref value);
        Marshal.FreeCoTaskMem(value.Value);
        Marshal.ReleaseComObject(store);
    }
    delegate bool EnumProc(IntPtr hwnd, IntPtr param);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
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
    # WMI can fail for a moment while Windows and WSL start. That must not end
    # the launch with only one viewer up, so give it a few tries.
    for ($try = 0; $try -lt 5; $try++) {
        try {
            $viewer = Get-CimInstance Win32_Process -Filter "Name = 'sdl-freerdp.exe'" |
                Where-Object { $_.CommandLine -match ":$port(\s|`"|$)" } |
                Select-Object -First 1
            if ($viewer) { return [uint32]$viewer.ProcessId }
            return $null
        } catch {
            Write-Warning "Could not list the viewers: $_"
            Start-Sleep -Seconds 1
        }
    }
    return $null
}

& wsl.exe -d $distro -- bash -lc "systemctl is-active --quiet weaselway-session || ww-start-session"

function Start-Viewer([int]$display) {
    $arguments = if ($display -eq 1) { "" } else { "--display $display " }
    & wsl.exe -d $distro -- bash -lc "ww-start-viewer $arguments-decorations -grab-keyboard"
}

foreach ($display in 1, 2) {
    if (-not (Get-ViewerPid $ports[$display])) { Start-Viewer $display }
}

# The monitors, not the laptop's own screen when it is open: with three screens
# the primary one is left out.
[void][WeaselwayWindows]::SetProcessDPIAware()
$screens = @([System.Windows.Forms.Screen]::AllScreens)
if ($screens.Count -gt 2) { $screens = @($screens | Where-Object { -not $_.Primary }) }
$screens = @($screens | Sort-Object { $_.Bounds.X })
foreach ($display in 1, 2) {
    $hwnd = [IntPtr]::Zero
    for ($i = 0; $i -lt 60 -and $hwnd -eq [IntPtr]::Zero; $i++) {
        $viewerPid = Get-ViewerPid $ports[$display]
        if ($viewerPid) {
            $hwnd = [WeaselwayWindows]::Find($viewerPid)
        } elseif ($i % 10 -eq 9) {
            # A viewer started right after the session can exit without a word.
            Start-Viewer $display
        }
        if ($hwnd -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 500 }
    }
    # One viewer's trouble must not leave the other one unplaced.
    if ($hwnd -eq [IntPtr]::Zero) {
        Write-Warning "No window for the viewer of display $display"
        continue
    }
    $screen = $screens[[Math]::Min($display - 1, $screens.Count - 1)]
    try {
        [WeaselwayWindows]::Maximize($hwnd, $screen.WorkingArea.X, $screen.WorkingArea.Y)
        [WeaselwayWindows]::SetAppId($hwnd, "Tkuipers.Weaselway")
    } catch {
        Write-Warning "Could not place the viewer of display ${display}: $_"
    }
}
