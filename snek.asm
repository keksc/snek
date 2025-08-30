default rel

%define TCGETS 0x5401
%define TCSETS 0x5402
%define TIOCGWINSZ 0x5413

%define WRITE 1
%define MMAP 9
%define IOCTL 16
%define NANOSLEEP 35
%define EXIT 60

%define PROT_READ 1
%define PROT_WRITE 2
%define MAP_PRIVATE 2
%define MAP_ANONYMOUS 32

%define STDIN 0
%define STDOUT 1
%define STDERR 2

%define EXIT_SUCCESS 0

section .data
showCursor db 0x1b, "[?25h"
showCursor_len equ $ - showCursor
hideCursor db 0x1b, "[?25l"
hideCursor_len equ $ - hideCursor
enableAltScreen db 0x1b, "[?1049h"
enableAltScreen_len equ $ - enableAltScreen
disableAltScreen db 0x1b, "[?1049l"
disableAltScreen_len equ $ - disableAltScreen
cursorToTop db 0x1b, "[H"
cursorToTop_len equ $ - cursorToTop
cursorToPos1 db 0x1b, "["
cursorToPos1_len equ $ - cursorToPos1
cursorToPos2 db 0x1b, ";"
cursorToPos2_len equ $ - cursorToPos2
cursorToPos3 db 0x1b, "H"
cursorToPos3_len equ $ - cursorToPos3

section .bss
termiosOld: resb 60
termiosNew: resb 60
winSizeStruct: resb 8
buf: resb 20
letterBuf: resb 1
timespec:
  resq 1
  resq 1
screenBufPtr: resq 1
screenBufSize: resq 1
ROWS: resq 1
COLS: resq 1
x: resq 1
y: resq 1
xdir: resq 1
ydir: resq 1
head: resq 1
tail: resq 1
applex: resq 1
appley: resq 1
tv: resq 2
fds: resq 16

section .text
global _start

moveCursorTo:
  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [cursorToPos1]
  mov rdx, cursorToPos1_len
  syscall

  call printNumber

  lea rsi, [cursorToPos2]
  mov rdx, cursorToPos2_len
  syscall

  mov rax, rbx
  call printNumber

  lea rsi, [cursorToPos3]
  mov rdx, cursorToPos3_len
  syscall

  ret
  
printNumber:
  lea rsi, [buf + 19]
  mov byte [rsi], 0
  mov rbx, 10
  mov rcx, 0
  test rax, rax
  jnz .convert_loop
  dec rsi
  mov byte [rsi], '0'
  inc rcx
  jmp .print

.convert_loop:
  xor rdx, rdx
  div rbx
  add dl, '0'
  dec rsi
  mov [rsi], dl
  inc rcx
  test rax, rax
  jnz .convert_loop

.print:
  mov rax, WRITE
  mov rdi, STDOUT
  mov rdx, rcx
  syscall

  ret

init:
  mov rax, IOCTL
  mov rdi, STDIN
  mov rsi, TCGETS
  lea rdx, [termiosOld]
  syscall

  lea rsi, [termiosOld]
  lea rdi, [termiosNew]
  mov rcx, 60
.copyLoop:
  mov al, [rsi]
  mov [rdi], al
  inc rsi
  inc rdi
  dec rcx
  jnz .copyLoop

  lea rdi, [termiosNew + 12]
  mov rax, [rdi]
  and rax, 0xfffffffffffffeF5
  mov [rdi], rax

  mov rax, IOCTL
  mov rdi, STDIN
  mov rsi, TCSETS
  lea rdx, [termiosNew]
  syscall

  mov rax, IOCTL
  mov rdi, STDIN
  mov rsi, TIOCGWINSZ
  lea rdx, [winSizeStruct]
  syscall

  movzx rax, word [winSizeStruct]      ; rows
  movzx rbx, word [winSizeStruct+2]    ; cols
  mov [ROWS], rax
  mov [COLS], rbx

  imul rax, rbx
  imul rax, 4
  mov [screenBufSize], rax

  xor rdi, rdi
  mov rsi, [screenBufSize]
  mov rdx, PROT_READ | PROT_WRITE
  mov r10, MAP_PRIVATE | MAP_ANONYMOUS
  mov r8, -1
  xor r9, r9
  mov rax, MMAP
  syscall
  mov [screenBufPtr], rax

  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [enableAltScreen]
  mov rdx, enableAltScreen_len
  syscall

  ret

beginGrid:
  mov eax, '┌'
  stosd

  mov rcx, rbx
  mov eax, '─'
  rep stosd

  mov eax, '┐'
  stosd

  ret

endGrid:
  mov eax, '└'
  stosd

  mov rcx, rbx
  mov eax, '─'
  rep stosd

  mov eax, '┘'
  stosd

  ret
  
fillGrid:
  mov rdi, [screenBufPtr]
  mov rbx, [COLS]
  sub rbx, 2
  mov rdx, [ROWS]
  sub rdx, 2

  cld

  call beginGrid

  mov rcx, rdx

.fillGridLoop:
  push rcx
  mov eax, '│'
  stosd
  mov eax, '·'
  mov rcx, rbx
  rep stosd
  mov eax, '│'
  stosd
  pop rcx
  dec rcx
  jnz .fillGridLoop

  call endGrid

  ret

renderTable:
  mov rax, WRITE
  mov rdi, STDOUT
  mov rsi, [screenBufPtr]
  mov rdx, [screenBufSize]
  syscall

  ret

cleanup:
  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [disableAltScreen]
  mov rdx, disableAltScreen_len
  syscall

  mov rax, IOCTL
  mov rdi, STDIN
  mov rsi, TCSETS
  lea rdx, [termiosOld]
  syscall
  ret

exit:
  mov rax, EXIT
  mov rdi, EXIT_SUCCESS
  syscall

sleep:
  mov [timespec], rax
  mov rax, NANOSLEEP
  lea rdi, [timespec]
  xor rsi, rsi
  syscall
  ret

_start:
  call init
  call fillGrid

  mov rax, [COLS]
  xor rdx, rdx
  mov rbx, 2
  div rbx
  mov [x], rax

  mov rax, [ROWS]
  xor rdx, rdx
  mov rbx, 2
  div rbx
  mov [y], rax

  mov rdi, [screenBufPtr]
  mov rax, [y]
  dec rax
  imul rax, [COLS]
  add rax, [x]
  shl rax, 2
  add rdi, rax
  mov eax, 'S'
  stosd

  mov qword [tail], 0
  mov qword [head], 0
  mov qword [xdir], 0
  mov qword [ydir], 0
  mov qword [applex], 0
  
  call renderTable

  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [cursorToTop]
  mov rdx, cursorToTop_len
  syscall

.mainLoop:
  mov rax, 0
  mov rdi, STDIN
  lea rsi, [buf]
  mov rdx, 1
  syscall

  cmp rax, 1
  jne .mainLoop
  
  mov al, byte [buf]
  cmp al, 0x1b
  je .exit
  cmp al, 'w'
  je .printMsg
  cmp al, 'a'
  je .printMsg
  cmp al, 'r'
  je .printMsg
  cmp al, 's'
  je .printMsg

  jmp .mainLoop

.exit:
  call cleanup
  call exit

.printMsg:
  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [buf]
  mov rdx, 1
  syscall

  jmp .mainLoop
