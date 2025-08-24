$setwallpapersource = @"
using System.Runtime.InteropServices;
public class spi
{
    public const int SetDesktopWallpaper = 20;
    public const int UpdateIniFile = 0x01;
    public const int SendWinIniChange = 0x02;
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void SetWallpaper ( string path )
    {
        SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
    }
}
"@

Add-Type -TypeDefinition $setwallpapersource

$addr =  Get-NetRoute -AddressFamily IPv4 |Where-Object {$_.RouteMetric -eq "0"}|Where-Object {$_.DestinationPrefix -like "*/32"}
if ($addr.DestinationPrefix -eq $null) {
    # Normal
    $wallpaper= Join-Path -Path $env:USERPROFILE -ChildPath "Pictures\normal.bmp"
} else {
    # When VPN connected
    $wallpaper= Join-Path -Path $env:USERPROFILE -ChildPath "Pictures\vpn.bmp"
}
[spi]::SetWallpaper($wallpaper)

exit
