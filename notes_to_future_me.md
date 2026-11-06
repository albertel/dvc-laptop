- On linux box setup Apache
- in /var/www/html/index.html, note that this file, the `CreateUserDataTarball.ps1` and `Do-LaptopConfigure.ps1` have the ip address of the server

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <body>
   <p><a href="http://10.50.7.1:5000/">The Shutdown The Computers Page</a></p>
  </body>
</html>

- On a machine that has the extension configured run `CreateUserDataTarball.ps1` to create a backup tarball and send it to the machine running apache
- Make sure that the token at https://admin.google.com/ac/chrome/browser-tokens is the one in `Do-LaptopConfigure.ps1`
- Setup for machines can be found in "DVC Tech Configs 2026 - NOTES" but the script will now do the BIOS on Lenovos so that may be skippable

- For steady state, the shutdown.py is a python webapp running on port 5000
- It expects stable known IP addresses
- It expects a password in a file named after the account in the local dir


- For Cleanup
    - Enabling `Reset` in `Do-LaptopConfigure.ps1` with setup `De-ConfigureLaptop.ps1` to run on next boot


*** IDEAS
- what would it look like to enable winrm, setup network to private as admin account and then do configure from there?
- Can we seperate the settings to two scripts one that needs admin (all the HKLM stuff) and not (all the HKCU stuff)
- Setup two tasks two run, the admin one as admin account and leave DVC account as not?
- Task existance is a global thing etc.

    
