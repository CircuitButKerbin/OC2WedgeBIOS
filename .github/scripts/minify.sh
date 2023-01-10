echo Creating Directory
mkdir -p minified
echo Creating Structure
find src -type d -exec mkdir -p minified/{} \;
echo Finding Files
tmp1=$(find src -name "*.lua" ! -name "*.min.js")
echo Minifying files
luamin -f $tmp1 >minified/$tmp1
echo $?
echo Done
exit 0