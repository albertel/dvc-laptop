# TODO:
#  More aggressive bluetooth siable
#  Pin chrome
#  would be better if we examined the possible screen resoulotions and picked on rather than trying to blindly set one we expect to exist

Set-StrictMode -version latest

Function Set-ScreenResolution { 

<# 
    .Synopsis 
        Sets the Screen Resolution of the primary monitor 
    .Description 
        Uses Pinvoke and ChangeDisplaySettings Win32API to make the change 
    .Example 
        Set-ScreenResolution -Width 1024 -Height 768         
    #> 
param ( 
[Parameter(Mandatory=$true, 
           Position = 0)] 
[int] 
$Width, 

[Parameter(Mandatory=$true, 
           Position = 1)] 
[int] 
$Height 
) 

$pinvokeCode = @" 

using System; 
using System.Runtime.InteropServices; 

namespace Resolution 
{ 

    [StructLayout(LayoutKind.Sequential)] 
    public struct DEVMODE1 
    { 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmDeviceName; 
        public short dmSpecVersion; 
        public short dmDriverVersion; 
        public short dmSize; 
        public short dmDriverExtra; 
        public int dmFields; 

        public short dmOrientation; 
        public short dmPaperSize; 
        public short dmPaperLength; 
        public short dmPaperWidth; 

        public short dmScale; 
        public short dmCopies; 
        public short dmDefaultSource; 
        public short dmPrintQuality; 
        public short dmColor; 
        public short dmDuplex; 
        public short dmYResolution; 
        public short dmTTOption; 
        public short dmCollate; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmFormName; 
        public short dmLogPixels; 
        public short dmBitsPerPel; 
        public int dmPelsWidth; 
        public int dmPelsHeight; 

        public int dmDisplayFlags; 
        public int dmDisplayFrequency; 

        public int dmICMMethod; 
        public int dmICMIntent; 
        public int dmMediaType; 
        public int dmDitherType; 
        public int dmReserved1; 
        public int dmReserved2; 

        public int dmPanningWidth; 
        public int dmPanningHeight; 
    }; 



    class User_32 
    { 
        [DllImport("user32.dll")] 
        public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode); 
        [DllImport("user32.dll")] 
        public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags); 

        public const int ENUM_CURRENT_SETTINGS = -1; 
        public const int CDS_UPDATEREGISTRY = 0x01; 
        public const int CDS_TEST = 0x02; 
        public const int DISP_CHANGE_SUCCESSFUL = 0; 
        public const int DISP_CHANGE_RESTART = 1; 
        public const int DISP_CHANGE_FAILED = -1; 
    } 



    public class PrmaryScreenResolution 
    { 
        static public string ChangeResolution(int width, int height) 
        { 

            DEVMODE1 dm = GetDevMode1(); 

            if (0 != User_32.EnumDisplaySettings(null, User_32.ENUM_CURRENT_SETTINGS, ref dm)) 
            { 

                dm.dmPelsWidth = width; 
                dm.dmPelsHeight = height; 

                int iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_TEST); 

                if (iRet == User_32.DISP_CHANGE_FAILED) 
                { 
                    return "Unable To Process Your Request. Sorry For This Inconvenience."; 
                } 
                else 
                { 
                    iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_UPDATEREGISTRY); 
                    switch (iRet) 
                    { 
                        case User_32.DISP_CHANGE_SUCCESSFUL: 
                            { 
                                return "Success"; 
                            } 
                        case User_32.DISP_CHANGE_RESTART: 
                            { 
                                return "You Need To Reboot For The Change To Happen.\n If You Feel Any Problem After Rebooting Your Machine\nThen Try To Change Resolution In Safe Mode."; 
                            } 
                        default: 
                            { 
                                return "Failed To Change The Resolution"; 
                            } 
                    } 

                } 


            } 
            else 
            { 
                return "Failed To Change The Resolution."; 
            } 
        } 

        private static DEVMODE1 GetDevMode1() 
        { 
            DEVMODE1 dm = new DEVMODE1(); 
            dm.dmDeviceName = new String(new char[32]); 
            dm.dmFormName = new String(new char[32]); 
            dm.dmSize = (short)Marshal.SizeOf(dm); 
            return dm; 
        } 
    } 
} 

"@ 

Add-Type $pinvokeCode -ErrorAction SilentlyContinue 
[Resolution.PrmaryScreenResolution]::ChangeResolution($width,$height) 
} 

Function Set-MouseSpeed {
  [CmdletBinding()]
  param (
      [validateRange(1,20)]
      [int] $newSpeed
  )

  $winApi = add-type -name user32 -namespace tq84 -passThru -memberDefinition '
   [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo(
       uint uiAction,
       uint uiParam ,
       uint pvParam ,
       uint fWinIni
    );
' 
  $SPI_SETMOUSESPEED = 0x0071
  Write-Verbose "$winApi"
  Write-Verbose "MouseSensitivity before WinAPI call: $((Get-ItemProperty 'HKCU:\Control Panel\Mouse').MouseSensitivity)"
  $result = $winApi::SystemParametersInfo($SPI_SETMOUSESPEED, 0, $newSpeed, 0)
  Write-Verbose "MouseSensitivity after WinAPI call: $((Get-ItemProperty 'HKCU:\Control Panel\Mouse').MouseSensitivity)"
  Set-ItemProperty 'HKCU:\Control Panel\Mouse' -name MouseSensitivity -value $newSpeed
}

Function TestExistance-ItemProperty($path, $name) {
	$exists = Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
        Write-Verbose "TestExistance-ItemProperty: $exists $($exists -eq $null)"
	return ($exists -ne $null)
}

# Set Screen resolution
$result = Set-ScreenResolution -Width 1920 -Height 1080
"Set-ScreenResolution for 1920x1080 resulted in $result"
if ($result -ne "Success") {
	$result = Set-ScreenResolution -Width 1600 -Height 900
	"Set-ScreenResolution for 1600x900 resulted in $result"
	if ($result -ne "Success") {
 		Exit
   	}
}

# Hide Wi-Fi and Bluetooth
Get-NetAdapter | Where {$_.Name -like "*Wi-Fi*" } | Disable-NetAdapter -confirm:$false
Get-NetAdapter | Where {$_.Name -like "*bluetooth*" } | Disable-NetAdapter -confirm:$false

# Make windows update not run
$startDate = "2024-08-07T00:00:00Z"
$endDate = "2024-11-07T00:00:00Z"
$winUpPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

Set-ItemProperty -Name "PauseUpdatesStartTime" -Path $winUpPath -Value $startDate
Set-ItemProperty -Name "PauseUpdatesExpiryTime" -Path $winUpPath -Value $endDate
Set-ItemProperty -Name "PauseQualityUpdatesStartTime" -Path $winUpPath -Value $startDate
Set-ItemProperty -Name "PauseQualityUpdatesExpiryTime" -Path $winUpPath -Value $endDate
Set-ItemProperty -Name "PauseFeatureUpdatesStartTime" -Path $winUpPath -Value $startDate
Set-ItemProperty -Name "PauseFeatureUpdatesExpiryTime" -Path $winUpPath -Value $endDate

# Fix Mouse Speed
Set-MouseSpeed -newSpeed 10

# Disable screen timeout
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 0
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 0

# Disable ScreenSaver
$scrnPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $scrnPath -Name ScreenSaveActive -Value 0
Set-ItemProperty -Path $scrnPath -Name ScreenSaverIsSecure -Value 0
Set-ItemProperty -Path $scrnPath -Name ScreenSaveTimeout -Value 0
if (TestExistance-ItemProperty -Path $scrnPath -Name "SCRNSAVE.EXE" -Verbose) {
	Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name SCRNSAVE.EXE
}

# Set chrome to start
$runPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\run"
$name = "Google_chrome"

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (!(Test-Path -Path $chromePath)) {
   $chromePath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
   if (!(Test-Path -Path $chromePath)) {
       "Uname to find Chrome install path"
       Exit
   }
}

$value = $chromePath + " -start-maximized"
if (TestExistance-ItemProperty -Path $runPath -Name $name) {
	Set-ItemProperty -Path $runPath -Name $name -Value $value
} else {
	New-ItemProperty -Path  $runPath -Name $name -Value $value -PropertyType "String"
}

# Cleanup TaskBar, doesn;t handle file explorer/shutdown shortcut 
((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where { -not ($_.Name -like "*Chrome*")} | ?{$_.Name}).Verbs() | ?{$_.Name.Replace('&', '') -match 'Unpin from taskbar'} | %{$_.DoIt(); $exec = $true}

# Set Policy to Hide desktop
$policyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$name = "NoDesktop"
$value = "1"
if (!(Test-Path -Path $policyPath)) {
	New-Item $policyPath -Force
}
if (TestExistance-ItemProperty -Path $policyPath -Name $name) {
	Set-ItemProperty -Path $policyPath -Name $name -Value $value
} else {
	New-ItemProperty -Path  $policyPath -Name $name -Value $value -PropertyType "DWORD"
}

# Clear background and set to a dark blue
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value ''
Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name Background -Value '0 5 50'
