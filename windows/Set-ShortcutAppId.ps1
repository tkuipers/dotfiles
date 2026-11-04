# Gives the Weaselway shortcuts the app id the launcher puts on the viewer
# windows, so the taskbar groups both viewers under the pin. Run once.

$ErrorActionPreference = "Stop"

Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
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
public static class WeaselwayShortcut {
    public static void SetAppId(string path, string appId) {
        object link = Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("00021401-0000-0000-C000-000000000046")));
        IPersistFile file = (IPersistFile)link;
        file.Load(path, 2);
        IPropertyStore store = (IPropertyStore)link;
        PropertyKey key = new PropertyKey { Format = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), Id = 5 };
        PropVariant value = new PropVariant { Type = 31, Value = Marshal.StringToCoTaskMemUni(appId) };
        store.SetValue(ref key, ref value);
        store.Commit();
        file.Save(path, true);
        Marshal.FreeCoTaskMem(value.Value);
    }
    public static string GetAppId(string path) {
        object link = Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("00021401-0000-0000-C000-000000000046")));
        ((IPersistFile)link).Load(path, 0);
        PropertyKey key = new PropertyKey { Format = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), Id = 5 };
        PropVariant value;
        ((IPropertyStore)link).GetValue(ref key, out value);
        return value.Type == 31 ? Marshal.PtrToStringUni(value.Value) : "";
    }
}
'@

$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = [Environment]::GetFolderPath("Programs")
$pins = Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
foreach ($folder in $pins, $startMenu, $desktop) {
    $path = Join-Path $folder "Weaselway.lnk"
    if (Test-Path $path) {
        [WeaselwayShortcut]::SetAppId($path, "Tkuipers.Weaselway")
        "$path = $([WeaselwayShortcut]::GetAppId($path))"
    }
}
