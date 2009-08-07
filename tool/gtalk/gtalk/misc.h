/* Copyright (c) 2000-2006                             */
/*   Takao Kobayashi, Takashi Masuko, Masatsune Tamura */
/*   (Tokyo Institute of Technology)                   */
/*   Keiichi Tokuda, Takayoshi Yoshimura, Heiga Zen    */
/*   (Nagoya Institute of Technology)                  */
/*   All rights reserved                               */

/************************************************************************
*									*
*    Miscellaneous Functions						*
*									*
*					2000.1 M.Tamura			*
*									*
************************************************************************/
FILE *getfp (char *, char *);
int fwritef (double *, unsigned int, int, FILE *);
int freadf (double *, unsigned int, int, FILE *);
void GetToken (FILE *, char *, int);
void movem ();

typedef enum {FA,TR} Boolean;
typedef enum {DURATION,PITCH,MCEP} Mtype;

