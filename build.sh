nasm -f elf64 -o http.o http.s
ld -o http http.o -I /lib64/ld-linux-x86-64.so.2

while getopts ":t,:r" option; do
    case "${option}" in
        t) strace -f ./http ;;
        r) ./http ;;
        *) ;;
    esac
done
