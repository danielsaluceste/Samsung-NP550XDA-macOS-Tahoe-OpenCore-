// Detecta movimento do cursor e declara atividade do usuario (acorda o display).
// Nao le teclado nem cliques; usa apenas a posicao global do cursor.
#include <ApplicationServices/ApplicationServices.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static CGPoint cursor_pos(void) {
    CGEventRef ev = CGEventCreate(NULL);
    CGPoint p = CGEventGetLocation(ev);
    CFRelease(ev);
    return p;
}

int main(int argc, char **argv) {
    if (argc >= 2 && strcmp(argv[1], "--pos") == 0) {
        CGPoint p = cursor_pos();
        printf("%.0f %.0f\n", p.x, p.y);
        return 0;
    }
    if (argc >= 4 && strcmp(argv[1], "--warp") == 0) {
        CGWarpMouseCursorPosition(CGPointMake(atof(argv[2]), atof(argv[3])));
        return 0;
    }

    CGPoint last = cursor_pos();
    for (;;) {
        usleep(500000);
        CGPoint p = cursor_pos();
        if (p.x != last.x || p.y != last.y) {
            last = p;
            IOPMAssertionID id = 0;
            IOReturn r = IOPMAssertionDeclareUserActivity(
                CFSTR("local.cursor-wake"), kIOPMUserActiveLocal, &id);
            if (r == kIOReturnSuccess) {
                sleep(2);
                if (id) IOPMAssertionRelease(id);
            }
        }
    }
    return 0;
}
