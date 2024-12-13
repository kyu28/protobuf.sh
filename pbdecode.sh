#!/bin/sh
#
# Protobuf wire format decoder
# dependency: xxd

# TODO
# repeat pack

TYPE_VARINT=0
TYPE_FIXED64=1
TYPE_BYTES=2
TYPE_FIXED32=5

automata() {
    n=
    t=
    len=0
    v=
    state=read_tag
    delimiter="{"
    for b in $@; do
        case $state in
        read_tag)
            printf "$delimiter"
            [ "$delimiter" = "{" ] && delimiter=","
            n=$((0x$b >> 3))
            printf "\"$n\":"
            t=$((0x$b & 0x7))
            case $t in
            $TYPE_VARINT)
                v=0x0
                state=read_varint_0;;
            $TYPE_FIXED64)
                buf=
                state=read_fixed64_0;;
            $TYPE_BYTES)
                buf=
                v=
                len=0x0
                state=read_length_0;;
            $TYPE_FIXED32)
                buf=
                state=read_fixed32_0;;
            *)
                echo "error: invalid field type" >&2
                return 1
                ;;
            esac
            buf=
            ;;
        read_length_*)
            nth=${state#read_length_}
            shifts=$(($nth * 7))
            num=$(printf "%x" $(((0x$b & 0x7f) << $shifts)))
            len=$(($len | 0x$num))
            if [ "$((0x$b >> 7))" -eq 0 ]; then
                if [ "$len" -gt 0 ]; then
                    state=read_bytes
                else
                    printf "\"\""
                    state=read_tag
                fi
            else
                state=read_length_$(($nth + 1))
            fi
            ;;
        read_varint_*)
            nth=${state#read_varint_}
            shifts=$(($nth * 7))
            num=$(printf "%x" $(((0x$b & 0x7f) << $shifts)))
            v=$(($v | 0x$num))
            if [ "$((0x$b >> 7))" -eq 0 ]; then
                printf "$v"
                state=read_tag
            else
                state=read_varint_$(($nth + 1))
            fi
            ;;
        read_fixed64_*)
            nth=${state#read_fixed64_}
            buf=$b$buf
            if [ "$nth" -eq 7 ]; then
                v=$(printf "%d" 0x$buf)
                printf "$v"
                state=read_tag
            else
                state=read_fixed64_$(($nth + 1))
            fi
            ;;
        read_bytes)
            buf="$buf $b"
            v=$v$(echo $b | xxd -r -p)
            len=$(($len - 1))
            if [ "$len" -eq 0 ]; then
                buf=$(automata $buf 2>&1)
                if [ $? -eq 0 ]; then
                    printf "$buf"
                else
                    printf "\"$v\""
                fi
                state=read_tag
            fi
            ;;
        read_fixed32_*)
            nth=${state#read_fixed32_}
            buf=$b$buf
            if [ "$nth" -eq 3 ]; then
                v=$(printf "%d" 0x$buf)
                buf=
                printf "$v"
                state=read_tag
            else
                state=read_fixed32_$(($nth + 1))
            fi
            ;;
        *)
            echo "error: invalid state \"$state\"" >&2
            return 1
            ;;
        esac
    done
    if [ $state != "read_tag" ]; then
        echo "error: incomplete protobuf" >&2
        return 1
    fi
    printf "}"
}

str=$(automata $(xxd -ps -c1))
[ $? -eq 0 ] && echo $str
