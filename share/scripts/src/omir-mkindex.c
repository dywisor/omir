#define _DEFAULT_SOURCE
#define _GNU_SOURCE

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <string.h>

static int visit ( void );

int main ( void ) {
    /* multiple args: chdir(arg) && visit */
    return visit();
}

static int visit_process_entries (
    const int num_entries,
    struct dirent** const namelist,
    struct stat** const statlist
) {
    int k;
    size_t num_blocks_total;

    num_blocks_total = 0;
    for ( k = 0; k < num_entries; k++ ) {
        if ( statlist[k] != NULL ) {
            num_blocks_total += statlist[k]->st_blocks;
        }
    }

    printf ( "total %zu\n", num_blocks_total );

    for ( k = 0; k < num_entries; k++ ) {
        struct dirent* ent;
        struct stat* sb;
        size_t fsize;
        char fsize_unit;

        ent = namelist[k];
        sb = statlist[k];

        if ( sb != NULL ) {
            /* FIXME: outsource to separate function */
            fsize = sb->st_size;
            fsize_unit = 'B';
            while ( fsize >= 1024 && fsize_unit != 'T' ) {
                fsize /= 1024;
                switch ( fsize_unit ) {
                    case 'B': fsize_unit = 'K'; break;
                    case 'K': fsize_unit = 'M'; break;
                    case 'M': fsize_unit = 'G'; break;
                    case 'G': fsize_unit = 'T'; break;
                    default: return -1;
                }
            }

            printf (
                "%s %d %d %d %4zu%c %s %s %s %s %s\n",
                ( (ent->d_type == DT_DIR) ? "drwxr-xr-x" : "-rw-r--r--" ),
                ( (ent->d_type == DT_DIR) ? 2 : 1 ),
                1001, 1001,
                fsize, fsize_unit,
                "Jan", "10", "01:10:01", "2020",
                ent->d_name
            );
        }
    }

    return EXIT_SUCCESS;
}


static int visit_filter ( const struct dirent* const ent ) {
    const char* s;

    switch ( ent->d_type ) {
        case DT_DIR:
        case DT_REG:
        case DT_LNK:
            break;

        default:
            return 0;
    }

    s = ent->d_name;
    if ( s == NULL ) {
        return 0;
    } else {
        switch ( *s ) {
            case '\0':
                return 0;

            case '.':
                /* any hidden file and '.', '..' entries */
                return 0;

            default:
                if ( strcmp ( s, "index.txt" ) == 0 ) {
                    return 0;
                }
                break;  /* nop */
        }
    }

    return 1;
}


static void x_free_arr_items ( const int argc, void** const argv ) {
    int k;

    if ( argv == NULL ) { return; }

    for ( k = 0; k < argc; k++ ) {
        void* node;

        node = argv[k];
        if ( node != NULL ) {
            argv[k] = NULL;
            free ( node );
        }
    }
}


static void x_free_arr ( const int argc, void*** const argv ) {
    if ( *argv != NULL ) {
        x_free_arr_items ( argc, *argv );
        free ( *argv );
        *argv = NULL;
    }
}




static struct stat** visit_create_statlist (
    const int argc, struct dirent** const argv
) {
    struct stat** statlist;
    struct stat* sb;
    int k;
    int ret;

    statlist = malloc ( argc * (sizeof *statlist) );

    if ( statlist != NULL ) {
        for ( k = 0; k < argc; k++ ) { statlist[k] = NULL; }

        sb = malloc ( sizeof *sb );
        if ( sb == NULL ) {
            x_free_arr ( argc, (void***) &statlist );
            return NULL;
        }

        for ( k = 0; k < argc; k++ ) {
            /* follow links */
            ret = stat ( argv[k]->d_name, sb );
            if ( ret < 0 ) {
                statlist[k] = NULL;  /* no-op */

            } else {
                statlist[k] = sb;
                sb = malloc ( sizeof *sb );
                if ( sb == NULL ) {
                    x_free_arr ( argc, (void***) &statlist );
                    return NULL;
                }
            }
        }
    }

    return statlist;
}


static int visit ( void ) {
    /* struct dirent: man 3 readdir */
    struct dirent** namelist;
    struct stat** statlist;
    int num_entries;
    int rc;

    num_entries = scandir ( ".", &namelist, visit_filter, versionsort );

    rc = EXIT_FAILURE;

    if ( num_entries == 0 ) {
        x_free_arr ( num_entries, (void***) &namelist );
        rc = EXIT_SUCCESS;

    } else if ( num_entries > 0 ) {
        statlist = visit_create_statlist ( num_entries, namelist );

        if ( statlist != NULL ) {
            rc = visit_process_entries ( num_entries, namelist, statlist );

            x_free_arr ( num_entries, (void***) &statlist );
            free ( statlist );

        } else {
            perror("statlist");
        }

        x_free_arr ( num_entries, (void***) &namelist );

    } else {
        perror("scandir");
    }

    return rc;
}
