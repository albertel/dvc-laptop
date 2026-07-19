cd C:\Users\DVC_volunteer\AppData\Local\Google\Chrome
tar -c -f C:\Users\DVC_volunteer\Downloads\UserDataStart.tar "User Data"
cd C:\Users\DVC_volunteer\Downloads
rm -r temp
mkdir temp
cd temp
tar -x -f ..\UserDataStart.tar
rm -r Cache
