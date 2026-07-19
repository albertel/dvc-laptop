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
pushd Default/Extensions/ghbmnnjooekpmoecnnnilnnbdlolhkhi/1.108.1_0/_locales
rm -r ?? en_CA/ en_GB/ f* p* z*
popd
pushd Default/Extensions/nmmhkkegccagdldgiimedpiccmgmieda/1.0.0.6_0/_locales
mv en ..
rm -r  ?? es_419/ en_GB/ fil pt* z*
mv ../en .
popd
cd ..
tar -c -v -z -f UserData.test.tgz "User Data"
scp UserData.test.tgz dvc@192.168.1.81:/var/www/html
