# Keeps the Windows taskbar out of the way of Weaselway. Auto-hide gives the
# viewers the full height of the monitors, and the taskbars stay hidden even
# with the mouse on the bottom edge. Hold a Windows key with the mouse there, or
# have the Linux power menu open (it leaves a flag file here), to bring them
# back; they go again once the mouse leaves. With no viewer running
# the taskbars behave normally, so a dead session never strands the desktop.
# Started by Start-Weaselway.ps1. Safe to run again: only one copy stays.

$mutex = New-Object System.Threading.Mutex($false, "Local\WeaselwayTaskbar")
if (-not $mutex.WaitOne(0)) { exit }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;
public static class WeaselwayTaskbar {
    [StructLayout(LayoutKind.Sequential)] struct Point { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] struct Rect { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] struct AppBarData {
        public int Size; public IntPtr Window; public uint Message; public uint Edge; public Rect Bounds; public IntPtr Param;
    }
    delegate bool EnumProc(IntPtr hwnd, IntPtr param);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc proc, IntPtr param);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hwnd, StringBuilder name, int size);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hwnd, int cmd);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out Point point);
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int key);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindow(string name, string title);
    [DllImport("shell32.dll")] static extern IntPtr SHAppBarMessage(uint message, ref AppBarData data);

    const int Hide = 0, ShowNoActivate = 8;
    const int LeftWin = 0x5B, RightWin = 0x5C;
    const int EdgeHeight = 2;      // how near the bottom counts as on the edge
    const int TaskbarHeight = 64;  // how far the mouse may stray once it is up

    static List<IntPtr> Taskbars() {
        List<IntPtr> found = new List<IntPtr>();
        EnumWindows((hwnd, param) => {
            StringBuilder name = new StringBuilder(64);
            GetClassName(hwnd, name, name.Capacity);
            string text = name.ToString();
            if (text == "Shell_TrayWnd" || text == "Shell_SecondaryTrayWnd") found.Add(hwnd);
            return true;
        }, IntPtr.Zero);
        return found;
    }

    static void Set(bool visible) {
        foreach (IntPtr hwnd in Taskbars()) {
            if (IsWindowVisible(hwnd) != visible) ShowWindow(hwnd, visible ? ShowNoActivate : Hide);
        }
    }

    public static void AutoHide() {
        AppBarData data = new AppBarData();
        data.Size = Marshal.SizeOf(data);
        data.Window = FindWindow("Shell_TrayWnd", null);
        data.Param = (IntPtr)1;    // ABS_AUTOHIDE
        SHAppBarMessage(10, ref data);   // ABM_SETSTATE
    }

    static bool Held(int key) { return (GetAsyncKeyState(key) & 0x8000) != 0; }

    public static void Run(string menuFlag) {
        SetProcessDPIAware();
        bool revealed = false;
        int tick = 0;
        bool viewers = true;
        while (true) {
            if (tick++ % 20 == 0) viewers = Process.GetProcessesByName("sdl-freerdp").Length > 0;
            Point cursor;
            GetCursorPos(out cursor);
            int bottom = Screen.FromPoint(new System.Drawing.Point(cursor.X, cursor.Y)).Bounds.Bottom;
            int distance = bottom - cursor.Y;
            if (distance <= EdgeHeight && (Held(LeftWin) || Held(RightWin) || File.Exists(menuFlag))) revealed = true;
            else if (distance > TaskbarHeight) revealed = false;
            Set(revealed || !viewers);
            Thread.Sleep(100);
        }
    }

    public static void Restore() { Set(true); }
}
'@

[WeaselwayTaskbar]::AutoHide()
try { [WeaselwayTaskbar]::Run("$PSScriptRoot\power-menu-open") } finally { [WeaselwayTaskbar]::Restore() }
