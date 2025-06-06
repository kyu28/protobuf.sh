#!/bin/sh
#
# protoc --decode_raw processor

INDENT_STEP="  "

trim() {
    echo ${1%:}
}

is_message() {
    if [ ${2}x = '{x' ]; then
        return 0
    else
        return 1
    fi
}

print_message() {
    while IFS= read -r line; do
        [ "$(trim $line)" = "}" ] && echo "${1%$INDENT_STEP}}" && return
        printf "$1"
        echo $line
        is_message $line && print_message "$1$INDENT_STEP" && continue
    done
}

print_value() {
    echo $2
}

skip_message() {
    while IFS= read -r line; do
        is_message $line && skip_message && continue
        [ "$(trim $line)" = "}" ] && return
    done
}

search() {
    oldcur=$cur
    cur=$1
    if [ $# -gt 0 ]; then
        shift 1
    fi
    while IFS= read -r line; do
        num=$(trim $line)
        [ "$num" = "}" ] && break
        if [ "$num" = "$cur" ]; then
            if is_message $line; then
                if [ $# -eq 0 ]; then
                    echo $line
                    print_message "$INDENT_STEP"
                    continue
                else
                    search "$@"
                fi
            else
                if [ $# -eq 0 ]; then
                    print_value $line
                    continue
                else
                    echo error: $cur is not a message >&2
                    exit 1
                fi
            fi
        elif is_message $line; then
            skip_message
        fi
    done
    cur=$oldcur
}

usage() {
    echo "usage: $0 [fields...]"
    echo
    echo "example:"
    echo "$0 1 1 2"
}

case "$1" in
'')
    while IFS= read -r line; do
        echo "$line"
    done
    ;;
-h) usage;;
*) (search "$@");;
esac

