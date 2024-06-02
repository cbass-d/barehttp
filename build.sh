
echo 'Compiling....'
nasm -f elf64 -o http.o http.s
echo 'Linking...'
ld -o http http.o -I /lib64/ld-linux-x86-64.so.2
echo 'Done'

while getopts ":t,:r" option; do
    case "${option}" in
        t) echo 'Running with strace'; strace -f ./http ;;
        r) echo 'Running'; ./http ;;
        *) ;;
    esac
done
