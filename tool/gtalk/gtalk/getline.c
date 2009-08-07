/* Copyright (c) 2000-2006                  */
/*   Yamashita Lab., Ritsumeikan University */
/*   All rights reserved                    */


#include <stdio.h>
#include <string.h>
#ifdef HAVE_READLINE
#include <readline/readline.h>
#include <readline/history.h>
#endif

#ifdef HAVE_READLINE

void getline( char *buf, int MAX_LENGTH )
{
	char *s;
	int p;

	s = readline( NULL );
	if( s == NULL || s[0] == '\0' ) {
		strncpy(buf, "set Run = EXIT", MAX_LENGTH-1);
		buf[MAX_LENGTH-1] = '\0';
		return;
	}
	strncpy( buf, s, MAX_LENGTH-1);
	free( s );

	buf[MAX_LENGTH-1] = '\0';
	p = strlen( buf ) - 1;
	if( buf[p] == '\n' )  buf[p] = '\0';
	add_history( buf );
}
 
#else  /* ~HAVE_READLINE */

void getline( char *buf, int MAX_LENGTH )
{
	int p;

	fgets( buf, MAX_LENGTH, stdin );
	p = strlen( buf ) - 1;
	if( buf[p] == '\n' )  buf[p] = '\0';
}

#endif /* HAVE_READLINE */

