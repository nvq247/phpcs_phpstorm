#=========DEFINE=====
#require: install git-bash, php
extensions='\.(php|php5|php4)'
phppath='php'
sname=''
dname="$1"
[ "$2" = 1 ] &&  lib="phpcs.phar"
[ "$2" = 2 ] &&  lib="phpcbf.phar"

masters=$(git --no-pager log origin/master |grep -E -o "commit [a-z0-9]+" |grep -E -o "\w{30,}");
branchs=$(git --no-pager log |grep -E -o "commit [a-z0-9]+" |grep -E -o "\w{30,}");

##CHECK UPTODATE
last=$(for m in $masters ; do  [ $(echo "$branchs" | grep "$m") ] && echo $m && break ;done)
[ "$last" ] || last='origin/master'


echo "==============================SELECTED FILES============================="
cd "$dname" 2>/dev/null ||  cd $(dirname "$dname")
[ -f $dname ] && sname=$(basename $dname) && dname=$(dirname $dname)
while [ "$dname" != "$(dirname $dname)" ]
  do
    [ -f "$dname/phpcs.xml" ] && break
    sname="$(basename $dname)/$sname"  dname=$(dirname $dname)
  done

for fi  in  $(git diff $last  --name-only --diff-filter=ARCM| grep -P "$extensions" |grep -P "^$sname")
do
echo "Selected: $fi"
fixphpcs=" $fi $fixphpcs"
ignores="$fi|$ignores"
done
ignores=$(git diff origin/master  --name-only --diff-filter=ARCM | grep -P -v  "(${ignores}xxx)")
[  "$ignores" ] && echo "==============================IGNORE FILES ============================="
for fi  in $ignores
  do
    echo "Not selected: $fi"
  done

 #Warning update master
warning=$(for m in $masters ; do  [ $(echo "$branchs" | grep "$m") ]  && break; echo -e "\033[33;7m ----- Your branch is not up to date with origin/master --- \e[0m";break;done)
echo $warning
[ "$lib" ] || exit
echo "===========================FIX FILES===================================="
[ -f "./$lib" ] || $(cd $dname && curl -sOL "https://squizlabs.github.io/PHP_CodeSniffer/$lib")
[ "$fixphpcs" ] && cd $dname && $phppath "./$lib" -p -s -v --warning-severity=0  --standard=phpcs.xml  --colors --report-width=200  --ignore-annotations --report=full,code,summary $fixphpcs
echo $warning