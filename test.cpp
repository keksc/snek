#include <stdio.h>
#include <termios.h>

int main() {
    printf("%zu\n", sizeof(struct termios));
    return 0;
}
