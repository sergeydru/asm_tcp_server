;using sockets on linux with the 0x80 inturrprets.
;
;assemble
;  nasm -o socket.o -f elf32 -g socket.asm
;link
;  ld -o socket socket.o
;
;
;Just some assigns for better readability
 
%assign SOCK_STREAM         1
%assign AF_INET             2
%assign SYS_socketcall      102
%assign SYS_SOCKET          1
%assign SYS_CONNECT         3
%assign SYS_SEND            9
%assign SYS_RECV            10
 
section .text
  global _start
 
;--------------------------------------------------
;Functions to make things easier. :]
;--------------------------------------------------
_socket:
  mov [cArray+0], dword AF_INET
  mov [cArray+4], dword SOCK_STREAM
  mov [cArray+8], dword 0
  mov eax, SYS_socketcall
  mov ebx, SYS_SOCKET
  mov ecx, cArray
  int 0x80
  ret
 
_connect:
  call _socket
  mov dword [sock], eax
  mov dx, si
  mov byte [edi+3], dl
  mov byte [edi+2], dh
  mov [cArray+0], eax     ;sock;
  mov [cArray+4], edi     ;&sockaddr_in;
  mov edx, 16
  mov [cArray+8], edx   ;sizeof(sockaddr_in);
  mov eax, SYS_socketcall
  mov ebx, SYS_CONNECT
  mov ecx, cArray
  int 0x80
  ret
 
_send:
  mov edx, [sock]
  mov [sArray+0],edx
  mov [sArray+4],eax
  mov [sArray+8],ecx
  mov [sArray+12], dword 0
  mov eax, SYS_socketcall
  mov ebx, SYS_SEND
  mov ecx, sArray
  int 0x80
  ret
 
_exit:
  push 0x1
  mov eax, 1
  push eax
  int 0x80
 
_print:
  mov ebx, 1
  mov eax, 4  
  int 0x80   
  ret         
;--------------------------------------------------
;Main code body
;--------------------------------------------------
 
_start:
  mov esi, szIp    
  mov edi, sockaddr_in
  xor eax,eax
  xor ecx,ecx
  xor edx,edx
  .cc:
    xor   ebx,ebx
  .c:
    lodsb
    inc   edx
    sub   al,'0'
    jb   .next
    imul ebx,byte 10
    add   ebx,eax
    jmp   short .c
  .next:
    mov   [edi+ecx+4],bl
    inc   ecx
    cmp   ecx,byte 4
    jne   .cc
 
  mov word [edi], AF_INET 
  mov esi, szPort 
  xor eax,eax
  xor ebx,ebx
  .nextstr1:   
    lodsb      
    test al,al
    jz .ret1
    sub   al,'0'
    imul ebx,10
    add   ebx,eax   
    jmp   .nextstr1
  .ret1:
    xchg ebx,eax   
    mov [sport], eax
 
  mov si, [sport]  
  call _connect
  cmp eax, 0
  jnz short _fail
  mov eax, msg
  mov ecx, msglen
  call _send
  call _exit
 
_fail:
  mov edx, cerrlen
  mov ecx, cerrmsg
  call _print
  call _exit
 
 
_recverr: 
  call _exit
_dced: 
  call _exit
 
section .data
cerrmsg      db 'failed to connect :(',0xa
cerrlen      equ $-cerrmsg
msg          db 'Hello socket world!',0xa
msglen       equ $-msg
 
szIp         db '127.0.0.1',0
szPort       db '256',0
 
section .bss
sock         resd 1
;general 'array' for syscall_socketcall argument arg.
cArray       resd 1
             resd 1
	     resd 1
             resd 1
 
;send 'array'.
sArray      resd 1
            resd 1
            resd 1
            resd 1
;duh?
sockaddr_in resb 16
;..
sport       resb 2
buff        resb 1024
