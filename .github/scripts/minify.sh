mkdir -p minified
find src -type d -exec mkdir -p minified/{} \;
tmp1=$(find src -name "*.lua" ! -name "*.min.js")
luamin -f $tmp1 >minified/$tmp1
