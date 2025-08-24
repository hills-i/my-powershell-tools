# VPN Wallpaper Switcher

This PowerShell script changes your desktop wallpaper based on whether a VPN connection is active. When connected to a VPN, it sets `vpn.bmp`; when disconnected, it sets `normal.bmp`.

## Prerequisites

- Windows 10 or later with PowerShell
- Execution policy set to allow script execution (e.g., `RemoteSigned` or `Bypass`)
- Two BMP images named `normal.bmp` and `vpn.bmp` placed in your `Pictures` folder (`%USERPROFILE%\Pictures`)
- (Optional) Administrator privileges if needed for workspace or policy restrictions

## Installation

1. Clone or download this repository.

2. Copy your wallpaper images into the Pictures folder:

3. Ensure the script can run:
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

## Usage

Run the script manually in PowerShell:
```powershell
.\vpn-wallpaper.ps1
```

### Automate at Login

To run automatically on user logon:

1. Open Task Scheduler (`taskschd.msc`).
2. Create a new task:
   - **Trigger**: At log on (Any user or specific user)
   - **Action**: Start a program
     - **Program/script**: `powershell.exe`
     - **Add arguments**: `-ExecutionPolicy Bypass -File "C:\path\to\vpn-check\vpn-wallpaper.ps1"`
3. (Optional) Enable **Run with highest privileges**.
4. Save the task.

### Automate on Network Change

You can also configure a Task Scheduler trigger for network state changes (e.g., Event ID 4400) to re-run the script on VPN connect/disconnect.

## How It Works

- Uses `Get-NetRoute` to look for IPv4 routes with a metric of `0` and a `/32` destination prefix (common for virtual VPN adapters).
- If such a route exists, the script assumes a VPN is connected and sets `vpn.bmp`.
- Otherwise, it sets `normal.bmp`.
- Leverages a small C# helper class (`SystemParametersInfo`) to invoke the Windows API and update the desktop wallpaper.

## Customization

- Edit the image paths or file names by modifying the `$wallpaper` assignment in `vpn-wallpaper.ps1`.
- Adjust the route detection logic if your VPN uses different metrics or prefixes.

## Troubleshooting

- **Wallpaper does not change**:
  - Confirm the script runs without errors.
  - Verify your BMP files exist in the specified folder.
  - Check your PowerShell execution policy.
  - Ensure your user account has permission to modify desktop settings.