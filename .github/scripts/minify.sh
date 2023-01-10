echo Creating Directory
mkdir -p minified
echo Creating Structure
find src -type d -exec mkdir -p minified/{} \;
echo Finding Files
files=$(find src -name "*.lua" ! -name "*.min.js")
pwd=$(pwd)
echo Minifying files
for file in $files
do
	echo $file
	cat $file | luamin -c > minified/$file
	cat minified/$file #Debug
done

echo $?
echo Done
exit 0