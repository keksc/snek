default rel

%include "headers.asm"

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
cursorToPos2 db ";"
cursorToPos2_len equ $ - cursorToPos2
cursorToPos3 db "H"
cursorToPos3_len equ $ - cursorToPos3
gameOverMsg db "Game Over!"
gameOverMsg_len equ $ - gameOverMsg

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
tv: resq 2
fds: resq 16

section .text
global _start

moveCursorTo:
  push rax
  push rbx

  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [cursorToPos1]
  mov rdx, cursorToPos1_len
  syscall

  pop rax

  call printNumber

  mov rax, WRITE
  lea rsi, [cursorToPos2]
  mov rdx, cursorToPos2_len
  syscall

  pop rax
  call printNumber

  mov rax, WRITE
  lea rsi, [cursorToPos3]
  mov rdx, cursorToPos3_len
  syscall

  ret

printNumber:
  lea rsi, [buf + 19]
  mov byte [rsi], 0
  mov rbx, 10
  xor rcx, rcx
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

  and word [termiosNew + TERMIOS_C_LFLAG_OFFSET], ~(TERMIOS_ICANON | TERMIOS_ECHO)

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

  movzx rax, word [winSizeStruct + WINSIZE_ROWS_OFFSET]
  movzx rbx, word [winSizeStruct + WINSIZE_COLS_OFFSET]
  mov [ROWS], rax
  mov [COLS], rbx

  mul rbx
  mov rbx, 4
  mul rbx
  mov [screenBufSize], rax

  xor rdi, rdi
  mov rsi, rax
  sub rsi, 90
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

genApple:
  rdtsc
  shl rdx, 32
  or rax, rdx ; full 64-bit timestamp into rax

  mov rbx, [COLS]
  sub rbx, 2
  xor rdx, rdx
  div rbx
  inc rdx
  mov rcx, rdx

  rdtsc
  shl rdx, 32
  or rax, rdx

  mov rbx, [ROWS]
  sub rbx, 2
  xor rdx, rdx
  div rbx
  inc rdx
  mov rbx, rdx

  mov rax, rbx
  mul qword [COLS]
  add rax, rcx
  mov rcx, 4
  mul rcx

  mov rdi, [screenBufPtr]
  add rdi, rax
  mov eax, '❤'
  mov [rdi], eax

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
  call genApple

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

.mainLoop:
  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [cursorToTop]
  mov rdx, cursorToTop_len
  syscall

  call renderTable

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
  je .mainLoop
  cmp al, 'a'
  je .mainLoop
  cmp al, 'r'
  je .mainLoop
  cmp al, 's'
  je .mainLoop

  jmp .mainLoop

.exit:
  call cleanup
  call exit
