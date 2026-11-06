# Keeps the Windows taskbars out of the way of Weaselway. They stay hidden, even
# with the mouse on the bottom edge. Hold a Windows key with the mouse there, or
# have the Linux power menu open (it leaves a flag file here), to bring them back;
# they go again once the mouse leaves and focus is back on Linux. Auto-hide stays
# off: it fights all of this, and Start-Weaselway.ps1 sizes the viewers to the
# whole monitor instead. With no viewer running the taskbars behave normally, so
# a dead session never strands the desktop.
# Started by Start-Weaselway.ps1. Safe to run again: only one copy stays.

$mutex = New-Object System.Threading.Mutex($false, "Local\WeaselwayTaskbar")
if (-not $mutex.WaitOne(0)) { exit }

Add-Type @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
public static class WeaselwayTaskbar {
    [StructLayout(LayoutKind.Sequential)] struct Point { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] struct Rect { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] struct MonitorInfo { public int Size; public Rect Monitor; public Rect Work; public uint Flags; }
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
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern IntPtr MonitorFromPoint(Point point, uint flags);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromWindow(IntPtr hwnd, uint flags);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int w, int h, uint flags);
    [DllImport("user32.dll")] static extern bool GetMonitorInfo(IntPtr monitor, ref MonitorInfo info);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindow(string name, string title);
    [DllImport("shell32.dll")] static extern IntPtr SHAppBarMessage(uint message, ref AppBarData data);

    const int Hide = 0, ShowNoActivate = 8;
    const uint NoMoveSizeActivate = 0x0013;
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

    static List<IntPtr> Viewers() {
        List<IntPtr> found = new List<IntPtr>();
        foreach (Process viewer in Process.GetProcessesByName("sdl-freerdp")) {
            if (viewer.MainWindowHandle != IntPtr.Zero) found.Add(viewer.MainWindowHandle);
        }
        return found;
    }

    // Explorer will not keep a taskbar above a full-screen window, so while one is
    // up the viewer under the mouse goes just below it instead. The other viewer
    // is left alone.
    static void TuckViewer(IntPtr monitor) {
        List<IntPtr> taskbars = Taskbars();
        foreach (IntPtr viewer in Viewers()) {
            if (MonitorFromWindow(viewer, 2) != monitor) continue;
            foreach (IntPtr hwnd in taskbars) {
                if (MonitorFromWindow(hwnd, 2) == monitor) SetWindowPos(viewer, hwnd, 0, 0, 0, 0, NoMoveSizeActivate);
            }
        }
    }

    // True while the keyboard is on Linux. Anything else, like a tray popup or the
    // Start menu, means the taskbar is in use and has to stay.
    static bool ViewerFocused() {
        StringBuilder name = new StringBuilder(64);
        GetClassName(GetForegroundWindow(), name, name.Capacity);
        return name.ToString() == "SDL_app";
    }

    static void RestoreViewers() {
        foreach (IntPtr viewer in Viewers()) SetWindowPos(viewer, IntPtr.Zero, 0, 0, 0, 0, NoMoveSizeActivate);
    }

    public static void AutoHideOff() {
        AppBarData data = new AppBarData();
        data.Size = Marshal.SizeOf(data);
        data.Window = FindWindow("Shell_TrayWnd", null);
        data.Param = (IntPtr)2;    // ABS_ALWAYSONTOP
        SHAppBarMessage(10, ref data);   // ABM_SETSTATE
    }

    // Asked every time: this starts at sign-in, before the monitors have settled,
    // and .NET's Screen keeps the layout it first saw.
    static int BottomOf(Point cursor) {
        MonitorInfo info = new MonitorInfo();
        info.Size = Marshal.SizeOf(info);
        GetMonitorInfo(MonitorFromPoint(cursor, 2), ref info);   // MONITOR_DEFAULTTONEAREST
        return info.Monitor.Bottom;
    }

    static bool Held(int key) { return (GetAsyncKeyState(key) & 0x8000) != 0; }

    public static void Run(string menuFlag) {
        SetProcessDPIAware();
        bool revealed = false;
        IntPtr tucked = IntPtr.Zero;
        int tick = 0;
        bool viewers = true;
        while (true) {
            if (tick++ % 20 == 0) viewers = Process.GetProcessesByName("sdl-freerdp").Length > 0;
            Point cursor;
            GetCursorPos(out cursor);
            int distance = BottomOf(cursor) - cursor.Y;
            if (distance <= EdgeHeight && (Held(LeftWin) || Held(RightWin) || File.Exists(menuFlag))) revealed = true;
            else if (distance > TaskbarHeight && ViewerFocused()) revealed = false;
            Set(revealed || !viewers);
            IntPtr monitor = revealed ? MonitorFromPoint(cursor, 2) : IntPtr.Zero;
            if (monitor != tucked) {
                if (tucked != IntPtr.Zero) RestoreViewers();
                if (revealed) TuckViewer(monitor);
                tucked = monitor;
            }
            Thread.Sleep(100);
        }
    }

    public static void Restore() { Set(true); }
}
'@

[WeaselwayTaskbar]::AutoHideOff()
try { [WeaselwayTaskbar]::Run("$PSScriptRoot\power-menu-open") } finally { [WeaselwayTaskbar]::Restore() }
