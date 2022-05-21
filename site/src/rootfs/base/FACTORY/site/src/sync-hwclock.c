/* ugly prog that triggers a hwclock sync */
#include <stdlib.h>
#include <sys/time.h>

int main (void) {
    struct timeval tp;
    struct timezone tzp;

    if ( gettimeofday ( &tp, &tzp ) != 0 ) { return 1; }
    return settimeofday ( &tp, &tzp );
}
