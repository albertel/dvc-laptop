Disable-PSRemoting -Force
Stop-Service WinRM -PassThru
Set-Service WinRM -StartupType Disabled -PassThru
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 0
Set-ExecutionPolicy -Force:$true -ExecutionPolicy Undefined
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Public