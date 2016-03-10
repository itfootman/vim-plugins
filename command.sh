function jgrep()
{
    find . -name .repo -prune -o -name .git -prune -o  -type f -name "*\.java" -print0 | xargs -0 grep --color -n "$@"
}

function cgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) -print0 | xargs -0 grep --color -n "$@"
}

function resgrep()
{
    for dir in `find . -name .repo -prune -o -name .git -prune -o -name res -type d`; do find $dir -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@"; done;
}

function addRoute() {
  SERVER=$1
  IP=`host $1 | awk '{print $4}' | head -n1`
  echo adding $IP to static route table
  ip route add $IP dev tun0
}

function xsh()
{
    if [ -z "$1" ]; then
        echo "usage:xssh alibuild2"
        return
    fi

    MY_TERM_NAME=`ps -p $(ps -p $$ -o ppid=) -o args=`
    CMD="bash -c -l \"export TERM_NAME=$MY_TERM_NAME;bash\""
    ssh $1 -t $CMD
}
