cd C:\Users\DVC_volunteer\AppData\Local\Google\Chrome
tar -c -f C:\Users\DVC_volunteer\Downloads\UserDataStart.tar "User Data"
cd C:\Users\DVC_volunteer\Downloads
rm -r temp
mkdir temp
cd temp
tar -x -f ..\UserDataStart.tar
cd "User Data"
rm -r optimization_guide_model_store
rm -r GrShaderCache
rm -r ShaderCache
rm -r GPUPersistentCache
rm -r Default/Cache
rm -r Default/GPUCache
rm -r Default/DawnGraphiteCache
rm -r Default/DawnWebGPUCache
cd ..
tar -c -v -z -f UserData.test.tgz "User Data"
scp UserData.test.tgz dvc@10.50.7.1:/var/www/html
