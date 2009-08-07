/* Copyright (c) 2000-2006                  */
/*   Yamashita Lab., Ritsumeikan University */
/*   All rights reserved                    */

#ifdef WIN32
#include "pronunciation_sjis.h"
#else
#include "pronunciation_eucjp.h"
#endif

#define	NUM_KANA	(sizeof(prnTable)/sizeof(prnTable[0]))
