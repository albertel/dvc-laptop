"Deconfigure Laptop Version 1"
$nicGUIDs = (Get-NetAdapter | Where {$_.Name -like "*ethernet*"}).InterfaceGuid
foreach ($nicGUID in $nicGUIDs) {
	$regpath = "HKLM:\SOFTWARE\Microsoft\DusmSvc\Profiles\$nicGUID\*"
	Remove-ItemProperty -Path $regpath -Name UserCost
}

Get-NetAdapter | Where {$_.Name -like "*Wi-Fi*" } | Enable-NetAdapter -confirm:$false
Get-NetAdapter | Where {$_.Name -like "*bluetooth*" } | Enable-NetAdapter -confirm:$false

$winUpPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
Remove-ItemProperty -Name "PauseUpdatesStartTime" -Path $winUpPath
Remove-ItemProperty -Name "PauseUpdatesExpiryTime" -Path $winUpPath
Remove-ItemProperty -Name "PauseQualityUpdatesStartTime" -Path $winUpPath
Remove-ItemProperty -Name "PauseQualityUpdatesExpiryTime" -Path $winUpPath
Remove-ItemProperty -Name "PauseFeatureUpdatesStartTime" -Path $winUpPath
Remove-ItemProperty -Name "PauseFeatureUpdatesExpiryTime" -Path $winUpPath
	
# Disable screen timeout
powercfg -change -monitor-timeout-ac 15
powercfg -change -monitor-timeout-dc 5
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 60

Remove-Item -Recurse -Path "HKLM:\SOFTWARE\Policies\Google\Chrome"
Remove-Item -Recurse -Path "HKLM:\SOFTWARE\Policies\Google\Update"
Remove-Item -Recurse -Path "HKLM:\SOFTWARE\Google\Chrome"
Remove-Item -Recurse -Path "HKLM:\SOFTWARE\WOW6432Node\Google\Enrollment"

(Get-WmiObject -class Lenovo_SetBiosSetting -namespace root\wmi).SetBiosSetting("OnByAcAttach,Disable")
(Get-WmiObject -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings()


Disable-PSRemoting -Force
Stop-Service WinRM -PassThru
Set-Service WinRM -StartupType Disabled -PassThru

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 0
Set-ExecutionPolicy -Force:$true -ExecutionPolicy Undefined
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Public

Start-Sleep -Seconds 60
Unregister-ScheduledTask -TaskName 'LaptopConfigure' -Confirm:$false
Unregister-ScheduledTask -TaskName 'LaptopDeConfigure' -Confirm:$false
Remove-LocalUser -Name DVC_volunteer
Start-Sleep -Seconds 60
