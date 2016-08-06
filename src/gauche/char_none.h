/*
 * char-none.h
 *
 *   Copyright (c) 2000-2016  Shiro Kawai  <shiro@acm.org>
 *
 *   Redistribution and use in source and binary forms, with or without
 *   modification, are permitted provided that the following conditions
 *   are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   3. Neither the name of the authors nor the names of its contributors
 *      may be used to endorse or promote products derived from this
 *      software without specific prior written permission.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SCM_CHAR_ENCODING_BODY
/*===============================================================
 * Header part
 */

/* The name of the encoding.  Scheme procedure
 * gauche-character-encoding returns a symbol with this name.
 */
#define SCM_CHAR_ENCODING_NAME "none"

/* Given first byte of the multibyte character, returns # of
 * bytes that follows, i.e. if the byte consists a single-byte
 * character, it returns 0; if the byte is the first byte of
 * two-byte character, it returns 1.   It may return -1 if
 * the given byte can't be a valid first byte of multibyte characters.
 */
#define SCM_CHAR_NFOLLOWS(ch)  0

/* Given wide character CH, returns # of bytes used when CH is
 * encoded in multibyte string.
 */
#define SCM_CHAR_NBYTES(ch)    1

/* Maximun # of multibyte character */
#define SCM_CHAR_MAX_BYTES     1

#define SCM_CHAR_GET(cp, ch) ((ch) = *(const unsigned char*)(cp))
#define SCM_CHAR_PUT(cp, ch)  (*(cp) = (ch))

#define SCM_CHAR_BACKWARD(cp, start, result)    \
    do {                                        \
        if ((cp) > (start)) (result) = (cp)-1;  \
        else (result) = NULL;                   \
    } while (0)

/* C is an ScmChar > 0x80.  Returns true if C is a whitespace character. */
#define SCM_CHAR_EXTRA_WHITESPACE(c)  ((c) == 0xa0) /* nbws */
/* Like SCM_CHAR_EXTRA_WHITESPACE, but excludes Zl and Zp.
   See R6RS on the intraline whitespaces. */
#define SCM_CHAR_EXTRA_WHITESPACE_INTRALINE(c) SCM_CHAR_EXTRA_WHITESPACE(c)

#else  /* !SCM_CHAR_ENCODING_BODY */
/*==================================================================
 * This part is included in char.c
 */

/* Array of character encoding names, recognizable by iconv, that are
   compatible with this native encoding. */
static const char *supportedCharacterEncodings[] = {
    "NONE",
    "ASCII",
    "US-ASCII",
    "ISO-8859-1",
    "ISO_8859-1",
    "ISO_8859-1:1987",
    "ISO-8859-2",
    "ISO_8859-2",
    "ISO_8859-2:1987",
    "ISO-8859-3",
    "ISO_8859-3",
    "ISO_8859-3:1988",
    "ISO-8859-4",
    "ISO_8859-4",
    "ISO_8859-4:1988",
    "ISO-8859-5",
    "ISO_8859-5",
    "ISO_8859-5:1988",
    "ISO-8859-6",
    "ISO_8859-6",
    "ISO_8859-7:1987",
    "ISO-8859-7",
    "ISO_8859-7",
    "ISO_8859-7:1987",
    "ISO-8859-8",
    "ISO_8859-8",
    "ISO_8859-8:1988",
    "ISO-8859-9",
    "ISO_8859-9",
    "ISO_8859-9:1989",
    "ISO-8859-10",
    "ISO_8859-10",
    "ISO_8859-10:1993",
    "ISO-8859-14",
    "ISO_8859-14",
    "ISO_8859-14:1998",
    NULL
};

/*
 * Lookup character category.  The tables are in char_attr.c, automatically
 * generated by gen-unicode.scm.
 */
static inline unsigned char Scm__LookupCharCategory(ScmChar ch)
{
    if (ch == SCM_CHAR_INVALID || ch > 0xff) return SCM_CHAR_CATEGORY_Cn;
    return ucs_general_category_00000[ch];
}

#endif /* !SCM_CHAR_ENCODING_BODY */
