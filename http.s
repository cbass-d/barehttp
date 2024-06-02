; RAX RDI RSI RDX R10 R8 R9

;; Define sockaddr_in data structure
struc sockaddr_in       ;;      
    .sin_fam resw 1     ;;  sokcet family
    .sin_port resw 1    ;;  htons port number
    .sin_addr resd 1    ;;  in_address structure
    .sin_zero resq 1    ;;  /0
endstruc                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Declared memory to hold the sockfd and clientfd to
;; be created
section .bss
    sockfd resw 2
    clientfd resw 2

;; Declared data
section .data

    ;; Error and status messages
    socket_created_msg db "(+) Socket successfully created.", 0xa, 0
    socket_created_msg_len equ $ - socket_created_msg

    binded_success_msg db "(+) Binded to socket.", 0xa, 0
    binded_success_msg_len equ $ - binded_success_msg

    listening_msg db "(+) Listening on socket.",  0xa, 0
    listening_msg_len equ $ - listening_msg

    accepting_msg db "(+) Accepting connections on localhost:4545", 0xa, 0
    accepting_msg_len equ $ - accepting_msg
    
    connection_msg db "(+) Connection received", 0xa, 0
    connection_msg_len equ $ - connection_msg

    create_error_msg db "(-) Could not create socket.", 0xa, 0
    create_error_msg_len equ $ - create_error_msg
    
    bind_error_msg db "(-) Could not bind to socket.", 0xa, 0
    bind_error_msg_len equ $ - bind_error_msg
    listen_error_msg db "(-) Could not setup listening on socket.", 0xa, 0
    listen_error_msg_len equ $ - listen_error_msg

    accept_error_msg db "(-) Accept failed.", 0xa, 0
    accept_error_msg_len equ $ - accept_error_msg

    open_file_err_msg db "(-) Could not open file.", 0xa, 0
    open_file_err_msg_len equ $ - open_file_err_msg

    ;; HTTP stuff
    http_200: 
        db "HTTP/1.1 200 OK", 0x0d, 0x0a
        db "Server: x86_64 Bare HTTP", 0x0d, 0x0a
        db "Content-Type: text/html", 0x0d, 0x0a
        db "Date: Fri, 12 Aug 1977 12:00 UTC", 0x0d, 0x0a
        db "Content-Length: 22", 0x0d, 0x0a
        db "", 0x0a
        db "c[] Morning! :)", 0x0a, 0
    http_200_len equ $ - http_200

    ;; sockaddr_in structure for host
    host_sockaddr_in istruc sockaddr_in
        at sockaddr_in.sin_fam, dw 2
        at sockaddr_in.sin_port, dw 0xc111      ; port(4545)
        at sockaddr_in.sin_addr, dd 0x0100007F  ; 127.0.0.1
        at sockaddr_in.sin_zero, dq 0
    iend
    sockaddr_len equ $ - host_sockaddr_in

section .text
    
global _start

_start:
    xor rax, rax
    xor rdi, rdi
    xor rsi, rsi

    ;; Make socket call
    mov rax, 0x29
    mov rdi, 2   ; AF_INET
    mov rsi, 1   ; SOCK_STREAM
    mov rdx, 0
    syscall
    
    ;; Check for error condition
    cmp rax, 0
    jl create_error
   
    ;; Store created sockfd
    mov [sockfd], rax

    ;; Print status message
    mov rax, 0x1
    mov rdi, 1
    lea rsi, socket_created_msg
    mov rdx, socket_created_msg_len
    syscall

    ;; Make bind socket call
    mov rax, 0x31
    mov rdi, [sockfd]
    lea rsi, host_sockaddr_in
    mov rdx, sockaddr_len
    syscall

    cmp rax, 0
    jl bind_error

    mov rax, 0x01
    mov rdi, 1
    lea rsi, binded_success_msg
    mov rdx, binded_success_msg_len
    syscall

    ;; Make listen call using created sockfd
    mov rax, 0x32
    mov rdi, [sockfd]
    mov rsi, 5		;; Max queue length of 5
    syscall

    cmp rax, 0
    jl listen_error

    mov rax, 0x01
    mov rdi, 1
    lea rsi, listening_msg
    mov rdx, listening_msg_len
    syscall

    mov rax, 0x01
    mov rdi, 1
    lea rsi, accepting_msg
    mov rdx, accepting_msg_len
    syscall

    ;; Main accept loop
 loop:
    ;; Make accept call
    mov rax, 0x2b
    mov rdi, [sockfd]
    mov rsi, 0
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jle accept_error
    
    ;; Store client fd
    mov [clientfd], rax
	
    ;; Fork call
    ;; Child process will handle connections
   ;; mov rax, 0x39
    ;;syscall
    ;;cmp rax, 0
    jmp connection_handler
    
    ;; Close client fd in parent
   ;; mov rax, 0x03
   ;; mov rdi, [clientfd]

    ;; Wait call
    ;;mov rax, 0x3d
    ;;mov rdi, -1
    ;;mov rsi, 0
    ;;mov rdx, 0
    ;;syscall

    ;;jmp loop

connection_handler:
    mov rax, 0x01
    mov rdi, 1
    lea rsi, connection_msg
    mov rdx, connection_msg_len
    syscall

    ;; Close listener fd in child
    ;;mov rax, 0x03
    ;;mov rdi, [sockfd]
    ;;syscall

    ;; Send HTTP 200 to client
    mov rax, 0x2c
    mov rdi, [clientfd]
    lea rsi, http_200
    mov rdx, http_200_len
    mov r10, 0
    mov r8, 0
    mov r9, 0
    syscall

    mov rax, 0x03
    mov rdi, [clientfd]
    syscall
 
    ;; Set exit code to 0
    mov rdi, 0
    jmp loop

create_error:
    mov rax, 0x01
    mov rdi, 1
    lea rsi, create_error_msg
    mov rdx, create_error_msg_len
    syscall

    ;; Set  status to -1
    mov rdi, -1
    jmp close_server

bind_error:
    mov rax, 0x01
    mov rdi, 1
    lea rsi, bind_error_msg
    mov rdx, bind_error_msg_len
    syscall
    
    mov rdi, -1
    jmp close_server

listen_error:
    mov rax, 0x01
    mov rdi, 1
    lea rsi, listen_error_msg
    mov rdx, listen_error_msg_len
    syscall

    mov rdi, -1
    jmp close_server

accept_error:
    mov rax, 0x1
    mov rdi, 1
    lea rsi, accept_error_msg
    mov rdx, accept_error_msg_len
    syscall 

    mov rdi, -1
    jmp close_server

open_file_error:
    mov rax, 0x1
    mov rdi, 1
    lea rsi, open_file_err_msg
    mov rdx, open_file_err_msg_len
    syscall 

    mov rdi, -1
    jmp close_server

close_server:
    ;; Close fd
    mov rax, 0x3
    mov rdi, [clientfd]
    syscall

    ;; Close sockfd
    mov rax, 0x3
    mov rdi, [sockfd]
    syscall

    ;; Set exit status to 0, if no error
    cmp rdi, -1
    je exit  
    mov rdi, 0

exit:
    mov rax, 0x3c
    syscall

