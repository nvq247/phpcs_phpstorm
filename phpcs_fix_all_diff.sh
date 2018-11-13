#=========DEFINE=====
#require: install git-bash, php
extensions='\.(php|php5|php4)'
phppath='php'
sname=''
dname="$1"
[ "$2" = 1 ] &&  lib="phpcs.phar"
[ "$2" = 2 ] &&  lib="phpcbf.phar"
[ "$2" = 3 ] &&  lib="php-cs-fixer.phar"
[ "$2" = 4 ] &&  lib="php-cs-fixer.phar"

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
   echo "$dname/phpcs.xml";
    [ "$2" -lt 3 ] && [ -f "$dname/phpcs.xml" ] && break
    [ "$2" -gt 2 ] && [ -f "$dname/.php_cs.dist" ] && break
    [ "$2" = 5 ] && [ -f "$dname/phpcs.xml" ] && break
    [ "$2" = 5 ] && [ -f "$dname/.php_cs.dist" ] && break
    sname="$(basename $dname)/$sname"
    dname=$(dirname $dname)
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
[ "$2" = 0 ] && exit
echo "===========================FIX FILES ($2)===================================="
[ "$2" = "1" ] && [ -f "./phpcs.phar"  ]          || $(cd $dname && curl -sOL "https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar")
[ "$2" = "2" ] && [ -f "./phpcbf.phar" ]          || $(cd $dname && curl -sOL "https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar")
[ "$2" = "5" ] && [ -f "./phpcbf.phar" ]          || $(cd $dname && curl -sOL "https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar")
[ "$2" -gt "2" ] && [ -f "./php-cs-fixer.phar" ]    || $(cd $dname && curl -L "https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar" -o php-cs-fixer.phar )

[ "$2" = "1" ] && [ "$fixphpcs" ] && cd $dname && $phppath "./phpcs.phar" -p -s -v --warning-severity=0  --standard=phpcs.xml  --colors --report-width=200  --ignore-annotations --report=full,code,summary $fixphpcs && exit
[ "$2" = "2" ] && [ "$fixphpcs" ] && cd $dname && $phppath "./phpcbf.phar" -p -s -v --warning-severity=0  --standard=phpcs.xml  --colors --report-width=200  --ignore-annotations --report=full,code,summary $fixphpcs && exit
[ "$2" = "5" ] && [ "$fixphpcs" ] && cd $dname && $phppath "./phpcbf.phar" -p -s -v --warning-severity=0  --standard=phpcs.xml  --colors --report-width=200  --ignore-annotations --report=full,code,summary $fixphpcs && exit
[ "$2" = "3" ] && [ "$fixphpcs" ] && cd $dname && $phppath "./php-cs-fixer.phar" fix --verbose --config=./.php_cs.dist --ansi --dry-run --diff --diff-format=sbd --show-progress=estimating  $fixphpcs && exit
[ "$2" -gt "4" ] && [ "$fixphpcs" ] && cd $dname && $phppath "./php-cs-fixer.phar" fix --verbose --config=./.php_cs.dist --ansi           --diff --diff-format=sbd --show-progress=estimating  $fixphpcs  && exit

echo $warning