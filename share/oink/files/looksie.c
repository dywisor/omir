/*
 * Usage:
 *   looksie [-4|-6] <name> [<alt_name>]
 *   looksie -r <ip> [<alt_ip>]
 *   looksie -h
 *
 *   By default, looksie looks up an IP for the given name using getaddrinfo().
 *
 *   Additional names may be specified,
 *   the first one to return an IP will be picked (left-to-right).
 *   The address family can be restricted with '-4' or '-6'.
 *
 *   The '-r' option will cause a reverse lookup.
 *
 *
 *   The overall motivation for this program is to have
 *   a small, static nslookup-like utility in OpenBSD.
 *   First attempts at compiling a static host(1) program
 *   resulted in a binary size of 8MiB, way larger than this prog.
 */

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <sysexits.h>

static int do_lookup ( const int af, const int reverse, const char* const arg );
static int print_addrinfo ( const int reverse, struct addrinfo* const res );

#define STR_IS_NONEMPTY(_s)   ( ((_s) != NULL) && (*(_s) != '\0') )
#define STR_IS_SHORTOPT(_s)  ( ((_s) != NULL) && ((_s)[0] == '-') && ((_s)[1] != '\0') && ((_s)[2] == '\0') )

int main ( int argc, char* argv[] ) {
	const char* arg;
	int k;
	int rc;
	int af;
	int reverse;

	if ( argc < 2 ) { return EX_USAGE; }

	af = AF_UNSPEC;
	reverse = 0;

	k = 1;

	/* only one option may be specified. */
	arg = argv[k];
	if ( STR_IS_SHORTOPT ( arg ) ) {
		/* ""getopt"" */
		switch ( arg[1] ) {
			case 'h':
				fprintf ( stdout, "Usage: %s [-4|-6|-r] <name> [<alt_name>]\n", argv[0] );
				return 0;
				break;  /* redundant */

			case '4':
				af = AF_INET;
				k++;
				break;

			case '6':
				af = AF_INET6;
				k++;
				break;

			case 'r':
				k++;
				reverse = 1;
				break;

			case '-':
				k++;
				break;

			default:
				break;
		}
	}

	if ( (argc - k) < 1 ) { return EX_USAGE; }

	for ( ; k < argc; k++ ) {
		arg = argv[k];

		if ( STR_IS_NONEMPTY ( arg ) ) {
			rc = do_lookup ( af, reverse, arg );

			if ( rc == 0 ) {
				return EXIT_SUCCESS;

			} else if ( rc < 0 ) {
				return EX_SOFTWARE;

			} /* else keep going */
		}
	}

	return EXIT_FAILURE;
}

int do_lookup ( const int af, const int reverse, const char* const arg ) {
	const struct addrinfo hints = {
		.ai_flags     = ( AI_ADDRCONFIG | AI_FQDN ),
		.ai_family    = af,  /* determined at runtime */
		.ai_socktype  = SOCK_STREAM,
		.ai_protocol  = 0,
		.ai_addrlen   = 0,
		.ai_addr      = NULL,
		.ai_canonname = NULL,
		.ai_next      = NULL
	};

	int ret;
	struct addrinfo* resv;

	resv = NULL;
	ret = getaddrinfo (
		arg,      /* hostname */
		NULL,     /* servname */ 
		&hints,   /* hints */
		&resv     /* res */
	);

	if ( ret == 0 ) {
		struct addrinfo* res;

		ret = 1;

		if ( af == AF_UNSPEC ) {
			for ( res = resv; res != NULL; res = res->ai_next ) {
				if ( (res->ai_family == AF_INET) || (res->ai_family == AF_INET6) ) {
					if ( print_addrinfo ( reverse, res ) == 0 ) {
						ret = 0;
						break;
					}
				}
			}

		} else {
			for ( res = resv; res != NULL; res = res->ai_next ) {
				if ( res->ai_family == af ) {
					if ( print_addrinfo ( reverse, res ) == 0 ) {
						ret = 0;
						break;
					}
				}
			}
		}

		/* not necessary to call free() on getaddrinfo error, according to man page */
		if ( resv != NULL ) {
			freeaddrinfo ( resv );
		}

	} else {
		/* FIXME MAYBE: check errno */
		ret = 2;
	}

	return ret;
}

int print_addrinfo ( const int reverse, struct addrinfo* const res ) {
	static char sbuf[NI_MAXHOST];

	int err;
	
	err = getnameinfo (
		res->ai_addr, res->ai_addrlen,  /* sa, salen */
		sbuf, sizeof(sbuf),             /* host, hostlen */
		NULL, 0,                        /* serv, servlen */
		(reverse) ? NI_NAMEREQD : NI_NUMERICHOST
	);

	if ( err == 0 ) {
		fprintf ( stdout, "%s\n", sbuf );
	}

	return err;
}
