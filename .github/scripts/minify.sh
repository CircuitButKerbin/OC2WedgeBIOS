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
	# Change minified file name to end in .min.lua instead of .lua
	mv minified/$file minified/${file%.lua}.min.lua
	cat minified/$file #Debug
done

echo $?
echo Done
exit 0