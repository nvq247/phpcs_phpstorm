#=========DEFINE=====
#require: install git-bash, php
extensions='\.(php|php5|php4)'
phppath='php'
sname=''
dname="$1"
[ "$2" = 1 ] &&  lib="phpcs.phar"
[ "$2" = 2 ] &&  lib="phpcbf.phar"
echo "==============================SELECTED FILES============================="
cd "$dname" 2>/dev/null ||  cd $(dirname "$dname")
[ -f $dname ] && sname=$(basename $dname) && dname=$(dirname $dname)
while [ "$dname" != "$(dirname $dname)" ]
  do
    [ -f "$dname/phpcs.xml" ] && break
    sname="$(basename $dname)/$sname"  dname=$(dirname $dname)
  done

for fi  in  $(git diff origin/master  --name-only --diff-filter=ARCM| grep -P "$extensions" |grep -P "^$sname")
do
echo "Selected: $fi"
fixphpcs=" $fi $fixphpcs"
ignores="$fi|$ignores"
done
echo "==============================IGNORE FILES============================="
for fi  in $(git diff origin/master  --name-only --diff-filter=ARCM | grep -P -v  "(${ignores}xxx)")
  do
    echo "Not selected: $fi"
  done
[ "$lib" ] || exit
echo "===========================FIX FILES===================================="
[ -f "./$lib" ] || $(cd $dname && curl -sOL "https://squizlabs.github.io/PHP_CodeSniffer/$lib")
[ "$fixphpcs" ] && cd $dname && $phppath "./$lib" -p -s -v --warning-severity=0  --standard=phpcs.xml  --colors --report-width=200  --ignore-annotations --report=full,code,summary $fixphpcs
