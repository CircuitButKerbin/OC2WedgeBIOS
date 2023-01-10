echo Creating Directory
mkdir -p minified
echo Creating Structure
find src -type d -exec mkdir -p minified/{} \;
echo Finding Files
files=$(find src -name "*.lua" ! -name "*.min.js")
pwd=$(pwd)
echo Minifying files
echo $tmp1
luamin -f $pwd/$files > minified/$files
echo $?
echo Done
exit 0