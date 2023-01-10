mkdir -p minified
find src -type d -exec mkdir -p minified/{} \;
files=$(find src -name "*.lua" ! -name "*.min.js")
pwd=$(pwd)
for file in $files
do
	cat $file | luamin -c > minified/$file
	# Change minified file name to end in .min.lua instead of .lua
	mv minified/$file minified/${file%.lua}.min.lua
done
exit 0