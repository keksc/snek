%define TCGETS 0x5401
%define TCSETS 0x5402
%define TIOCGWINSZ 0x5413

%define STDIN 0x0
%define STDOUT 0x1
%define STDERR 0x2

%define PROT_READ 0x1
%define PROT_WRITE 0x2
%define MAP_PRIVATE 0x2
%define MAP_ANONYMOUS 0x20

%define WRITE 0x1
%define MMAP 0x9
%define IOCTL 0x10
%define NANOSLEEP 0x23
%define EXIT 0x3c

%define EXIT_SUCCESS 0x0

%define TERMIOS_C_LFLAG_OFFSET 0xc
%define TERMIOS_ICANON 0x2
%define TERMIOS_ECHO 0x8

%define WINSIZE_ROWS_OFFSET 0x0
%define WINSIZE_COLS_OFFSET 0x2

