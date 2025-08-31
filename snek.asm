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
pollfd: resb 8  ; Structure for poll: fd (4 bytes), events (2 bytes), revents (2 bytes)

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

  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [hideCursor]
  mov rdx, hideCursor_len
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
  or rax, rdx

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

  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [showCursor]
  mov rdx, showCursor_len
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

getOffset:
  xchg rax, rbx
  mul qword [COLS]
  add rax, rbx
  shl rax, 2

  ret

setCurrentCharacter:
  push rax

  mov rax, [x]
  mov rbx, [y]
  call getOffset
  mov rdi, [screenBufPtr]
  add rdi, rax
  pop rax
  mov [rdi], eax
  
  ret

_start:
  call init
  call fillGrid
  call genApple

  mov rax, [COLS]
  shr rax, 1
  mov [x], rax
  mov rbx, [ROWS]
  shr rbx, 1
  mov [y], rbx

  call getOffset

  mov rdi, [screenBufPtr]
  add rdi, rax
  mov eax, '▓'
  mov [rdi], eax

.mainLoop:
  mov rax, WRITE
  mov rdi, STDOUT
  lea rsi, [cursorToTop]
  mov rdx, cursorToTop_len
  syscall

  call renderTable

  ; Set up pollfd structure for non-blocking input check
  mov dword [pollfd], STDIN
  mov word [pollfd + 4], POLL_IN
  mov word [pollfd + 6], 0      ; revents = 0

  mov rax, POLL
  lea rdi, [pollfd]
  mov rsi, 1
  mov rdx, 0
  syscall

  cmp rax, 0
  jle .mainLoop

  ; Read 1 byte initially
  mov rax, 0
  mov rdi, STDIN
  lea rsi, [buf]
  mov rdx, 1
  syscall

  cmp rax, 0
  je .mainLoop

  cmp byte [buf], 0x1b
  je .checkEscape

  ; Handle single-character inputs
  mov al, [buf]
  cmp al, 'w'
  je .up
  cmp al, 'a'
  je .left
  cmp al, 'r'
  je .down
  cmp al, 's'
  je .right
  cmp al, 'q'
  je .exit

  jmp .mainLoop

.checkEscape:
  ; Check if more input is available
  mov dword [pollfd], STDIN
  mov word [pollfd + 4], POLL_IN
  mov word [pollfd + 6], 0

  mov rax, 7
  lea rdi, [pollfd]
  mov rsi, 1
  mov rdx, 0
  syscall

  cmp rax, 0
  jle .exit

  ; Read up to 2 more bytes
  mov rax, 0
  mov rdi, STDIN
  lea rsi, [buf + 1]
  mov rdx, 2
  syscall

  cmp rax, 0
  je .exit

  cmp byte [buf + 1], '['
  jne .exit

  cmp rax, 2
  jne .mainLoop

  cmp byte [buf + 2], 'A' ; Up arrow
  je .up
  cmp byte [buf + 2], 'B' ; Down arrow
  je .down
  cmp byte [buf + 2], 'C' ; Right arrow
  je .right
  cmp byte [buf + 2], 'D' ; Left arrow
  je .left

  jmp .mainLoop

.up:
  mov rax, [y]
  cmp rax, 1          ; Check if y > 1 (top border)
  jle .mainLoop       ; Skip if at or above top border
  mov eax, '·'
  call setCurrentCharacter
  dec qword [y]
  mov eax, '▓'
  call setCurrentCharacter
  jmp .mainLoop

.down:
  mov rax, [ROWS]
  sub rax, 2          ; ROWS-2 is the bottom border
  cmp [y], rax
  jge .mainLoop       ; Skip if at or below bottom border
  mov eax, '·'
  call setCurrentCharacter
  inc qword [y]
  mov eax, '▓'
  call setCurrentCharacter
  jmp .mainLoop

.left:
  mov rax, [x]
  cmp rax, 1          ; Check if x > 1 (left border)
  jle .mainLoop       ; Skip if at or left of left border
  mov eax, '·'
  call setCurrentCharacter
  dec qword [x]
  mov eax, '▓'
  call setCurrentCharacter
  jmp .mainLoop

.right:
  mov rax, [COLS]
  sub rax, 2          ; COLS-2 is the right border
  cmp [x], rax
  jge .mainLoop       ; Skip if at or right of right border
  mov eax, '·'
  call setCurrentCharacter
  inc qword [x]
  mov eax, '▓'
  call setCurrentCharacter
  jmp .mainLoop

.exit:
  call cleanup
  call exit
