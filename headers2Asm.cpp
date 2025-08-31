#include <csignal>
#include <linux/termios.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

#include <print>

int main() {
  std::println("%define TCGETS {:#x}", TCGETS);
  std::println("%define TCSETS {:#x}", TCSETS);
  std::println("%define TIOCGWINSZ {:#x}\n", TIOCGWINSZ);

  std::println("%define STDIN {:#x}", STDIN_FILENO);
  std::println("%define STDOUT {:#x}", STDOUT_FILENO);
  std::println("%define STDERR {:#x}\n", STDERR_FILENO);

  std::println("%define PROT_READ {:#x}", PROT_READ);
  std::println("%define PROT_WRITE {:#x}", PROT_WRITE);
  std::println("%define MAP_PRIVATE {:#x}", MAP_PRIVATE);
  std::println("%define MAP_ANONYMOUS {:#x}\n", MAP_ANONYMOUS);

  std::println("%define WRITE {:#x}", SYS_write);
  std::println("%define POLL {:#x}", SYS_poll);
  std::println("%define MMAP {:#x}", SYS_mmap);
  std::println("%define IOCTL {:#x}", SYS_ioctl);
  std::println("%define NANOSLEEP {:#x}", SYS_nanosleep);
  std::println("%define EXIT {:#x}\n", SYS_exit);

  std::println("%define EXIT_SUCCESS {:#x}", EXIT_SUCCESS);
  std::println("%define EXIT_FAILURE {:#x}\n", EXIT_FAILURE);

  std::println("%define TERMIOS_C_LFLAG_OFFSET {:#x}", offsetof(termios, c_lflag));
  std::println("%define TERMIOS_ICANON {:#x}", ICANON);
  std::println("%define TERMIOS_ECHO {:#x}\n", ECHO);

  std::println("%define WINSIZE_ROWS_OFFSET {:#x}", offsetof(winsize, ws_row));
  std::println("%define WINSIZE_COLS_OFFSET {:#x}\n", offsetof(winsize, ws_col));

  std::println("%define POLL_IN {:#x}\n", static_cast<uint8_t>(POLL_IN));

  return 0;
}
