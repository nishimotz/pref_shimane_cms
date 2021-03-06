/* Copyright (c) 2000-2006                  */
/*   Studio ARC, ASTEM RI/Kyoto             */
/*   All rights reserved                    */

#ifndef _CHAONE_H_

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) && !defined(__CYGWIN32__)
#define KANJICODE "Shift_JIS"
#else
#define KANJICODE "EUC-JP"
#endif
    
void refresh_chaone();
char* make_chaone_process( char* pszXmlIn );

#ifdef __cplusplus
}
#endif

#endif /* _CHAONE_H_ */
