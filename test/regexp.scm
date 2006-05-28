;;
;; testing regexp
;;

;; $Id: regexp.scm,v 1.23 2006-05-28 02:29:16 shirok Exp $

(use gauche.test)
(use srfi-1)

(test-start "regexp")

;; Some test examples are taken from the test suite of Henry Spencer's
;; regexp package and PCRE.

(define (match&list rx input)
  (cond ((rxmatch rx input)
         => (lambda (match)
              (map (lambda (n) (rxmatch-substring match n))
                   (iota (rxmatch-num-matches match)))))
        (else #f)))

;;-------------------------------------------------------------------------
(test-section "regexp-parse")

(define-syntax test-regexp-parse
  (syntax-rules ()
    ((_ re ast)
     (test* #`"regexp-parse \",re\"" ast (regexp-parse re)))))

(test-regexp-parse "a" '(0 #f #\a))
(test-regexp-parse "ab" '(0 #f #\a #\b))
(test-regexp-parse "(?:ab)" '(0 #f (seq #\a #\b)))
(test-regexp-parse "(a)" '(0 #f (1 #f #\a)))
(test-regexp-parse "a?" '(0 #f (rep 0 1 #\a)))
(test-regexp-parse "a*" '(0 #f (rep 0 #f #\a)))
(test-regexp-parse "a+" '(0 #f (rep 1 #f #\a)))
(test-regexp-parse "a{3,5}" '(0 #f (rep 3 5 #\a)))
(test-regexp-parse "a{3}" '(0 #f (rep 3 3 #\a)))
(test-regexp-parse "a|b" '(0 #f (alt #\a #\b)))
(test-regexp-parse "[ab]" '(0 #f #[ab]))
(test-regexp-parse "[^ab]" '(0 #f (comp . #[ab])))
(test-regexp-parse "." '(0 #f any))
(test-regexp-parse "^" '(0 #f bol))
(test-regexp-parse "$" '(0 #f eol))
(test-regexp-parse "\\b" '(0 #f wb))
(test-regexp-parse "\\B" '(0 #f nwb))
(test-regexp-parse "(?>a)" '(0 #f (once #\a)))
(test-regexp-parse "a*+" '(0 #f (once (rep 0 #f #\a))))
(test-regexp-parse "a++" '(0 #f (once (rep 1 #f #\a))))
(test-regexp-parse "a?+" '(0 #f (once (rep 0 1 #\a))))
(test-regexp-parse "(?i:a)" '(0 #f (seq-uncase #\a)))
(test-regexp-parse "(?-i:a)" '(0 #f (seq-case #\a)))
(test-regexp-parse "(?=a)" '(0 #f (assert #\a)))
(test-regexp-parse "(?!a)" '(0 #f (nassert #\a)))
(test-regexp-parse "(?<=ab)" '(0 #f (assert (lookbehind #\a #\b))))
(test-regexp-parse "(?<!ab)" '(0 #f (nassert (lookbehind #\a #\b))))
(test-regexp-parse "(?<name>a)" '(0 #f (1 name #\a)))
(test-regexp-parse "(?(?=)y)" '(0 #f (cpat (assert) (#\y) #f)))
(test-regexp-parse "(?(?=)y|n)" '(0 #f (cpat (assert) (#\y) (#\n))))
(test-regexp-parse "(?(?<=)y)" '(0 #f (cpat (assert (lookbehind)) (#\y) #f)))
(test-regexp-parse "(?(?<=)y|n)" '(0 #f (cpat (assert (lookbehind)) (#\y) (#\n))))
(test-regexp-parse "()(?(1)y)" '(0 #f (1 #f) (cpat 1 (#\y) #f)))
(test-regexp-parse "()(?(1)y|n)"'(0 #f (1 #f) (cpat 1 (#\y) (#\n))))
(test-regexp-parse "()\\1" '(0 #f (1 #f) (backref . 1)))
(test-regexp-parse "(?<name>)\\k<name>" '(0 #f (1 name) (backref . 1)))
(test-regexp-parse "(?<name>)(?<name>)\\k<name>"
                   '(0 #f (1 name) (2 name) (alt (backref . 2) (backref . 1))))

;;-------------------------------------------------------------------------
(test-section "compile")

(define-syntax test-regexp-compile
  (syntax-rules ()
    ((_ pat)
     (test* #`"regexp-compile \",|pat|\"" #t
           (regexp? (regexp-compile (regexp-parse pat)))))))

(test-regexp-compile "a")
(test-regexp-compile "ab")
(test-regexp-compile "(?:ab)")
(test-regexp-compile "(a)")
(test-regexp-compile "a?")
(test-regexp-compile "a*")
(test-regexp-compile "a+")
(test-regexp-compile "a{3,5}")
(test-regexp-compile "a{3}")
(test-regexp-compile "a|b")
(test-regexp-compile "[ab]")
(test-regexp-compile "[^ab]")
(test-regexp-compile ".")
(test-regexp-compile "^")
(test-regexp-compile "$")
(test-regexp-compile "\\b")
(test-regexp-compile "\\B")
(test-regexp-compile "(?>a)")
(test-regexp-compile "a*+")
(test-regexp-compile "a++")
(test-regexp-compile "a?+")
(test-regexp-compile "(?i:a)")
(test-regexp-compile "(?-i:a)")
(test-regexp-compile "(?=a)")
(test-regexp-compile "(?!a)")
(test-regexp-compile "(?<=ab)")
(test-regexp-compile "(?<!ab)")
(test-regexp-compile "(?<name>a)")
(test-regexp-compile "(?(?=)y)")
(test-regexp-compile "(?(?=)y|n)")
(test-regexp-compile "(?(?<=)y)")
(test-regexp-compile "(?(?<=)y|n)")
(test-regexp-compile "()(?(1)y)")
(test-regexp-compile "()(?(1)y|n)")
(test-regexp-compile "()\\1")
(test-regexp-compile "(?<name>)\\k<name>")
(test-regexp-compile "(?<name>)(?<name>)\\k<name>")

;;-------------------------------------------------------------------------
(test-section "basics")

(test* "a" '("a")
       (match&list #/a/ "a"))
(test* "a" #f
       (match&list #/a/ "A"))
(test* "a" '("a")
       (match&list #/a/ "ba"))
(test* "a" '("a")
       (match&list #/a/ "bac"))
(test* "a" #f      ;; input null str
       (match&list #/a/ ""))
(test* "a" '("a")  ;; input includes NUL character
       (match&list #/a/ (string (integer->char 0) #\a #\b)))
(test* "abc" '("abc")
       (match&list #/abc/ "abc"))
(test* "abc" #f
       (match&list #/abc/ "abbc"))
(test* "abc" '("abc")
       (match&list #/abc/ "babcd"))
(test* "abc|de" '("abc")
       (match&list #/abc|de/ "dabce"))
(test* "abc|de" '("de")
       (match&list #/abc|de/ "abdec"))
(test* "abc|de" #f
       (match&list #/abc|de/ "abe"))
(test* "a|b|c" '("a")
       (match&list #/a|b|c/ "abc"))
(test* "a|b|c" '("b")
       (match&list #/a|b|c/ "bac"))
(test* "a|b|c" #f
       (match&list #/a|b|c/ "def"))
(test* "|abc" '("")
       (match&list #/|abc/ "abc"))
(test* "abc|" '("abc")
       (match&list #/abc|/ "abc"))
(test* "abc|" '("")
       (match&list #/abc|/ "abd"))

;;-------------------------------------------------------------------------
(test-section "parens")

(test* "a(b)c" '("abc" "b")
       (match&list #/a(b)c/ "abc"))
(test* "a((b)(c))" '("abc" "bc" "b" "c")
       (match&list #/a((b)(c))/ "abc"))
(test* "a((((b))))c" '("abc" "b" "b" "b" "b")
       (match&list #/a((((b))))c/ "abc"))
(test* "a((((b))))c" '#f
       (match&list #/a((((b))))c/ "a(b)c"))
(test* "a\\(" '("a(")
       (match&list #/a\(/ "a("))
(test* "a()b" '("ab" "")
       (match&list #/a()b/ "ab"))
(test* "a()()b" '("ab" "" "")
       (match&list #/a()()b/ "ab"))
(test* "(we|wee|week|frob)(knights|night|day)"
       '("weeknights" "wee" "knights")
       (match&list #/(we|wee|week|frob)(knights|night|day)/
                   "weeknights"))
(test* "aa|(bb)|cc" '("aa" #f)
       (match&list #/aa|(bb)|cc/ "aabb"))
(test* "aa|(bb)|cc" '("bb" "bb")
       (match&list #/aa|(bb)|cc/ "abbaa"))
(test* "aa|(bb)|cc" '("cc" #f)
       (match&list #/aa|(bb)|cc/ "bccaa"))
(test* "aa|a(b)|cc" '("ab" "b")
       (match&list #/aa|a(b)|cc/ "abaab"))
(test* "aa|a(b)" '("ab" "b")
       (match&list #/aa|a(b)/ "abaab"))
(test* "aa|(a(b))|ac" '("ab" "ab" "b")
       (match&list #/aa|(a(b))|cc/ "abaabcc"))
(test* "(ab)|ac" '("ab" "ab")
       (match&list #/(ab)|ac/ "aaaabcc"))
(test* "(a(b))|ac" '("ab" "ab" "b")
       (match&list #/(a(b))|ac/ "abaabcc"))
(test* "ab|(ac)" '("ab" #f)
       (match&list #/ab|(ac)/ "aaaabcc"))
(test* "ab|(ac)" '("ac" "ac")
       (match&list #/ab|(ac)/ "aaaacbc"))
(test* "aa|(ab|(ac))|ad" '("ac" "ac" "ac")
       (match&list #/aa|(ab|(ac))|ad/ "cac"))
(test* "(aa|(a(b)|a(c))|ad)" '("ac" "ac" "ac" #f "c")
       (match&list #/(aa|(a(b)|a(c))|ad)/ "cac"))
(test* "(.)*" '("abc" "c")
       (match&list #/(.)*/ "abc"))
(test* "(a([^a])*)*" '("abcaBC" "aBC" "C")
       (match&list #/(a([^a])*)*/ "abcaBC"))
(test* "b|()|a" '("" "")
       (match&list #/b|()|a/ "cac"))

;;-------------------------------------------------------------------------
(test-section "simple meta")

(test* "a.c" '("abc")
       (match&list #/a.c/ "abc"))
(test* "a.." '("abc")
       (match&list #/a../ "abc"))
(test* "a.." #f
       (match&list #/a../ "ab"))
(test* "..." #f
       (match&list #/.../ "ab"))
(test* "." '("a")
       (match&list #/./ "abc"))
(test* "." #f
       (match&list #/./ ""))

;;-------------------------------------------------------------------------
(test-section "anchors")

(test* "^abc" '("abc")
       (match&list #/^abc/ "abcd"))
(test* "^abc" #f
       (match&list #/^abc/ "aabcd"))
(test* "^^" '("^")
       (match&list #/^^/ "^^abc"))
(test* "^^" #f
       (match&list #/^^/ "a^^c"))
(test* "^abc|def" '("abc")
       (match&list #/^abc|def/ "abc"))
(test* "^abc|def" #f
       (match&list #/^abc|def/ "zabc"))
(test* "^abc|def" '("def")
       (match&list #/^abc|def/ "zabcdef"))
(test* "abc|^def" '("def")
       (match&list #/abc|^def/ "defabc"))
(test* "abc|^def" '("abc")
       (match&list #/abc|^def/ "abcdef"))
(test* "abc|^def" '("def")
       (match&list #/abc|^def/ "defabbc"))
(test* "abc|^def" #f
       (match&list #/abc|^def/ "adefbc"))
(test* "^(abc|def)" '("abc" "abc")
       (match&list #/^(abc|def)/ "abc"))
(test* "^(abc|def)" #f
       (match&list #/^(abc|def)/ "aabc"))
(test* "(^abc|def)" '("abc" "abc")
       (match&list #/(^abc|def)/ "abcdef"))
(test* "(^abc|def)" '("def" "def")
       (match&list #/(^abc|def)/ "^abcdef"))
(test* "a(^bc|def)" '("a^bc" "^bc")
       (match&list #/a(^bc|def)/ "a^bcdef"))
(test* "a(^bc|def)" #f
       (match&list #/a(^bc|def)/ "abcdef"))
(test* "^" '("")
       (match&list #/^/ "hoge"))
(test* "$" '("")
       (match&list #/$/ "hoge"))
(test* "abc$" '("abc")
       (match&list #/abc$/ "bcabc"))
(test* "abc$" #f
       (match&list #/abc$/ "abcab"))
(test* "^abc$" '("abc")
       (match&list #/^abc$/ "abc"))
(test* "abc$$" #f
       (match&list #/abc$$/ "abc"))
(test* "abc$$" '("abc$")
       (match&list #/abc$$/ "abc$"))
(test* "$$" '("$")
       (match&list #/$$/ "abc$"))
(test* "^$" '("")
       (match&list #/^$/ ""))
(test* "^$" #f
       (match&list #/^$/ "a"))
(test* "^^$$" '("^$")
       (match&list #/^^$$/ "^$"))
(test* "abc$|def" '("abc")
       (match&list #/abc$|def/ "abc"))
(test* "abc$|def" '("def")
       (match&list #/abc$|def/ "defabc"))
(test* "^abc|def$" '("abc")
       (match&list #/^abc|def$/ "abcdef"))
(test* "^abc|def$" #f
       (match&list #/^abc|def$/ "defabc"))
(test* "^abc|def$" #f
       (match&list #/^abc|def$/ "defabc"))
(test* "(^abc|def$)" '("def" "def")
       (match&list #/(^abc|def$)/ "aaadef"))
(test* "(^abc|def$)$" #f
       (match&list #/(^abc|def$)$/ "aaadef"))
(test* "(^abc|def$)$" '("def$" "def$")
       (match&list #/(^abc|def$)$/ "aaadef$"))
(test* "(abc$|def)$" #f
       (match&list #/(abc$|def)$/ "aaabc"))
(test* "(abc$|def)$" '("abc$" "abc$")
       (match&list #/(abc$|def)$/ "aaabc$"))
(test* "a$b" '("a$b")
       (match&list #/a$b/ "aa$bb"))
(test* "ab\\$" '("ab$")
       (match&list #/ab\$/ "ab$cd"))

;;-------------------------------------------------------------------------
(test-section "backslash escape")

(test* "a\\*c" '("a*c")
       (match&list #/a\*c/ "a*c"))
(test* "a\\.c" '("a.c")
       (match&list #/a\.c/ "a.c"))
(test* "a\\.c" #f
       (match&list #/a\.c/ "abc"))
(test* "a\\\\b" '("a\\b")
       (match&list #/a\\b/ "a\\b"))
(test* "a\\\\\\*b" '("a\\*b")
       (match&list #/a\\\*b/ "a\\*b"))
(test* "a\\jc" '("ajc")
       (match&list #/a\jc/ "ajc"))
(test* "a\\\\bc" '("a\\bc")
       (match&list #/a\\bc/ "a\\bc"))
(test* "a\\[b" '("a[b")
       (match&list #/a\[b/ "a[b"))

;;-------------------------------------------------------------------------
(test-section "word boundary")

(test* ".z\\b" '("oz")
       (match&list #/.z\b/ "bzbazoz ize"))
(test* "\\b.z" '("iz")
       (match&list #/\b.z/ "brzbazoz ize"))
(test* ".z\\B" '("iz")
       (match&list #/.z\B/ "bz baz oz ize"))
(test* "\\B.z" '("az")
       (match&list #/\B.z/ "bz baz oz ize"))

;;-------------------------------------------------------------------------
(test-section "repetitions")

(test* "ab*c" '("abc")
       (match&list #/ab*c/ "abc"))
(test* "ab*c" '("ac")
       (match&list #/ab*c/ "ac"))
(test* "ab*c" '("abbbc")
       (match&list #/ab*c/ "abbbc"))
(test* "ab*c" '("abbc")
       (match&list #/ab*c/ "abbabaabbc"))
(test* "ab+c" '("abc")
       (match&list #/ab+c/ "abc"))
(test* "ab+c" '("abbc")
       (match&list #/ab+c/ "abbc"))
(test* "ab+c" '("abbc")
       (match&list #/ab+c/ "abbabaabbc"))
(test* "ab?c" '("abc")
       (match&list #/ab?c/ "abc"))
(test* "ab?c" '("ac")
       (match&list #/ab?c/ "abbaac"))
(test* "a.*c" '("abc")
       (match&list #/a.*c/ "abc"))
(test* "a.*c" '("aabcabcabcabcc")
       (match&list #/a.*c/ "zaabcabcabcabcczab"))
(test* "a(b*|c)d" '("abbd" "bb")
       (match&list #/a(b*|c)d/ "abbd"))
(test* "a(b*|c)d" '("ad" "")
       (match&list #/a(b*|c)d/ "ad"))
(test* "a(b*|c)d" '("acd" "c")
       (match&list #/a(b*|c)d/ "acd"))
(test* "a(b*|c)d" #f
       (match&list #/a(b*|c)d/ "abcd"))
(test* "a.*c" '("ac")
       (match&list #/a.*c/ "bacbababbbbadbaba"))
(test* "a.*c" #f
       (match&list #/a.*c/ "abaaaabababbadbabdba"))

;;-------------------------------------------------------------------------
(test-section "repetitions (non-greedy)")

(test* "ab*?." '("ab")
       (match&list #/ab*?./ "abc"))
(test* "ab*?." '("ac")
       (match&list #/ab*?./ "ac"))
(test* "a.*?c" '("abbbc")
       (match&list #/a.*?c/ "abbbc"))
(test* "a.*?a" '("abba")
       (match&list #/a.*?a/ "abbabaabbc"))
(test* "<.*?>" '("<tag1>")
       (match&list #/<.*?>/ "<tag1><tag2><tag3>"))

(test* "ab+?." '("abc")
       (match&list #/ab+?./ "abc"))
(test* "ab+?." '("abb")
       (match&list #/ab+?./ "abbc"))
(test* "a.+?a" '("abba")
       (match&list #/a.+?a/ "abbabaabbc"))
(test* "<.+?>" '("<><tag1>")
       (match&list #/<.+?>/ " <><tag1><tag2>"))

(test* "ab??c" '("abc")
       (match&list #/ab??c/ "abc"))
(test* "ab??c" '("ac")
       (match&list #/ab??c/ "abbaac"))
(test* "ab??." '("ab")
       (match&list #/ab??./ "abbaac"))
(test* "a(hoge)??hoge" '("ahoge" #f)
       (match&list #/a(hoge)??hoge/ "ahogehoge"))
(test* "(foo)??bar" '("foobar" "foo")
       (match&list #/(foo)??bar/ "foobar"))
(test* "(foo)??bar" '("foobar" "foo")
       (match&list #/(foo)??bar/ "foofoobar"))
(test* "(foo)*?bar" '("foofoobar" "foo")
       (match&list #/(foo)*?bar/ "foofoobar"))

;;-------------------------------------------------------------------------
(test-section "character class")

(test* "a[bc]d" '("abd")
       (match&list #/a[bc]d/ "abd"))
(test* "a[bc]d" '("acd")
       (match&list #/a[bc]d/ "acd"))
(test* "a[bc]d" #f
       (match&list #/a[bc]d/ "aed"))
(test* "a[a-z]d" '("aed")
       (match&list #/a[a-z]d/ "aed"))
(test* "a[a-z]d" #f
       (match&list #/a[a-z]d/ "aEd"))
(test* "a[]]d" '("a]d")
       (match&list #/a[]]d/ "a]d"))
(test* "a[]-]d" '("a-d")
       (match&list #/a[]-]d/ "a-d"))
(test* "a[]-^]d" #f
       (match&list #/a[]-^]d/ "a-d"))
(test* "a[]-^]d" '("a]d")
       (match&list #/a[]-^]d/ "a]d"))
(test* "a[a-z-]d" '("a-d")
       (match&list #/a[a-z-]d/ "a-d"))
(test* "a[a-z-]d" '("afd")
       (match&list #/a[a-z-]d/ "afd"))
(test* "a[az-]d" '("a-d")
       (match&list #/a[az-]d/ "a-d"))
(test* "a[a-]d" '("a-d")
       (match&list #/a[a-]d/ "a-d"))
(test* "a[az-]d" #f
       (match&list #/a[az-]d/ "afd"))
(test* "a[az-]d" '("azd")
       (match&list #/a[az-]d/ "azd"))
(test* "a[^ab]c" '("acc")
       (match&list #/a[^ab]c/ "abacc"))
(test* "a[^]]c" '("abc")
       (match&list #/a[^]]c/ "abc"))
(test* "a[^]]c" #f
       (match&list #/a[^]]c/ "a]c"))
(test* "a[^^]c" '("abc")
       (match&list #/a[^^]c/ "abc"))
(test* "a[^^]c" #f
       (match&list #/a[^^]c/ "a^c"))
(test* "a[Bc]*d" '("aBccBd")
       (match&list #/a[Bc]*d/ "aBccBd"))
(test* "[a]b[c]" '("abc")
       (match&list #/[a]b[c]/ "abc"))
(test* "[abc]b[abc]" '("abc")
       (match&list #/[abc]b[abc]/ "abc"))
(test* "a[bc]d" '("abd")
       (match&list #/a[bc]d/ "xyzaaabcaababdacd"))
(test* "a[ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab](wee|week)(knights|night)"
       '("aaaaabaaaabaaaabaaaabweeknights" "wee" "knights")
       (match&list #/a[ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab][ab](wee|week)(knights|night)/
                   "aaaaabaaaabaaaabaaaabweeknights"))
(test* "[ab][cd][ef][gh][ij][kl][mn]"
       '("acegikm")
       (match&list #/[ab][cd][ef][gh][ij][kl][mn]/
                   "xacegikmoq"))
(test* "[ab][cd][ef][gh][ij][kl][mn][op]"
       '("acegikmo")
       (match&list #/[ab][cd][ef][gh][ij][kl][mn][op]/
                   "xacegikmoq"))
(test* "[ab][cd][ef][gh][ij][kl][mn][op][qr]"
       '("acegikmoq")
       (match&list #/[ab][cd][ef][gh][ij][kl][mn][op][qr]/
                   "xacegikmoqy"))
(test* "[ab][cd][ef][gh][ij][kl][mn][op][q]"
       '("acegikmoq")
       (match&list #/[ab][cd][ef][gh][ij][kl][mn][op][q]/
                   "xacegikmoqy"))

;; this tests optimizer
(test* "[^a]*." '("b")
       (match&list #/[^a]*./ "b"))

(test* "\\s" '(" ")  (match&list #/\s/ "  "))
(test* "\\s" '("  ")  (match&list #/\s\s/ "  "))
(test* "\\s" '("\t")  (match&list #/\s/ "\t "))
(test* "\\s" #f  (match&list #/\s\s/ "\\s"))
(test* "\\\\s" '("\\s ")  (match&list #/\\s\s/ "\\s "))
(test* "\\s\\S" '("\txyz   " "\t" "xyz" "   ")
       (match&list #/(\s*)(\S+)(\s*)/ "\txyz   abc"))
(test* "\\d\\D" '("1234) 5678-9012" "1234" ") " "5678" "-" "9012")
       (match&list #/(\d+)(\D+)(\d+)(\D+)(\d+)/
                   " (1234) 5678-9012 "))
(test* "\\w\\W" '("three o" "three" " " "o")
       (match&list #/(\w+)(\W+)(\w+)/
                   "three o'clock"))

(test* "[ab\\sc]+" '(" ba ") (match&list #/[ab\sc]+/ "d ba e"))
(test* "[\\sa-c]+" '(" ba ") (match&list #/[\sabc]+/ "d ba e"))
(test* "[\\S\\t]+" '("\tab") (match&list #/[\S\t]+/ "\tab cd"))
(test* "[\\s\\d]+" '(" 1 2 3 ")
       (match&list #/[\s\d]+/ "a 1 2 3 b "))
(test* "[\\s\\D]+" '("a ")
       (match&list #/[\s\D]+/ "a 1 2 3 b "))

;; this tests optimizer
(test* "^\\[?([^\\]]*)\\]?:(\\d+)$" '("127.0.0.1:80" "127.0.0.1" "80")
       (match&list #/^\[?([^\]]*)\]?:(\d+)$/ "127.0.0.1:80"))
(test* "^\\[?([^\\]]*)\\]?:(\\d+)$" '("[127.0.0.1:80" "127.0.0.1" "80")
       (match&list #/^\[?([^\]]*)\]?:(\d+)$/ "[127.0.0.1:80"))
(test* "^\\[?([^\\]]*)\\]?:(\\d+)$" '("[127.0.0.1]:80" "127.0.0.1" "80")
       (match&list #/^\[?([^\]]*)\]?:(\d+)$/ "[127.0.0.1]:80"))

;;-------------------------------------------------------------------------
(test-section "{n,m}")

(test* "a{2}"   "aabaa"    (rxmatch-after (#/a{2}/ "abaaaabaa")))
(test* "a{2,}"  "baa"      (rxmatch-after (#/a{2,}/ "abaaaabaa")))
(test* "a{1,2}" "baaaabaa" (rxmatch-after (#/a{1,2}/ "abaaaabaa")))
(test* "a{2,3}" "abaa"     (rxmatch-after (#/a{2,3}/ "abaaaabaa")))
(test* "a{b,c}" "def"      (rxmatch-after (#/a{b,c}/ "za{b,c}def")))
(test* "a{,2}*" "def"       (rxmatch-after (#/a{,2}*/  "za{,2}}def")))

(test* "(ab){2}"   "abba"      (rxmatch-after (#/(ab){2}/ "babbabababba")))
(test* "(ab){2,2}" "abba"      (rxmatch-after (#/(ab){2,2}/ "babbabababba")))
(test* "(ab){2,}"  "ba"        (rxmatch-after (#/(ab){2,}/ "babbabababba")))
(test* "(ab){1,2}" "babababba" (rxmatch-after (#/(ab){1,2}/ "babbabababba")))
(test* "(ab){2,3}" "ba"        (rxmatch-after (#/(ab){2,3}/ "babbabababba")))
(test* "(ab){b,c}" "def"       (rxmatch-after (#/(ab){b,c}/ "zab{b,c}def")))

(test* "(\\d{2})(\\d{2})" '("1234" "12" "34")
       (match&list #/(\d{2})(\d{2})/ "a12345b"))
(test* "(\\d{2,})(\\d{2,})" '("12345" "123" "45")
       (match&list #/(\d{2,})(\d{2,})/ "a12345b"))
(test* "(\\d{2})(\\d{2,})" '("12345" "12" "345")
       (match&list #/(\d{2})(\d{2,})/ "a12345b"))
(test* "(\\d{1,3})(\\d{2,})" '("1234" "12" "34")
       (match&list #/(\d{1,3})(\d{2,})/ "a1234b"))
(test* "(\\d{1,3})(\\d{0,2})" '("1234" "123" "4")
       (match&list #/(\d{1,3})(\d{0,2})/ "a1234b"))
(test* "(\\d{2}){2}" '("1234" "34")
       (match&list #/(\d{2}){2}/ "a12345b"))

(test* "{2}" *test-error*  (regexp? (string->regexp "{2}")))
(test* "{z}" #t            (regexp? (string->regexp "{z}")))
(test* "{-1}" #t           (regexp? (string->regexp "{-1}")))
(test* "{300}" *test-error* (regexp? (string->regexp "{300}")))
(test* "{3,1}" *test-error* (regexp? (string->regexp "{3,1}")))

;;-------------------------------------------------------------------------
(test-section "{n,m} (non-greedy)")

(test* "a{2}?"   "aabaa"    (rxmatch-after (#/a{2}?/ "abaaaabaa")))
(test* "a{2,}?"  "aabaa"    (rxmatch-after (#/a{2,}?/ "abaaaabaa")))
(test* "a{1,2}?" "baaaabaa" (rxmatch-after (#/a{1,2}?/ "abaaaabaa")))
(test* "a{2,3}?" "aabaa"    (rxmatch-after (#/a{2,3}?/ "abaaaabaa")))

(test* "(ab){2}?"   "abba"      (rxmatch-after (#/(ab){2}?/ "babbabababba")))
(test* "(ab){2,2}?" "abba"      (rxmatch-after (#/(ab){2,2}?/ "babbabababba")))
(test* "(ab){2,}?"  "abba"      (rxmatch-after (#/(ab){2,}?/ "babbabababba")))
(test* "(ab){1,2}?" "babababba" (rxmatch-after (#/(ab){1,2}?/ "babbabababba")))
(test* "(ab){2,3}?" "abba"      (rxmatch-after (#/(ab){2,3}?/ "babbabababba")))

(test* "(\\d{2,}?)(\\d{2,}?)" '("1234" "12" "34")
       (match&list #/(\d{2,}?)(\d{2,}?)/ "a12345b"))
(test* "(\\d{2,})(\\d{2,}?)" '("12345" "123" "45")
       (match&list #/(\d{2,})(\d{2,}?)/ "a12345b"))
(test* "(\\d{2,}?)(\\d{2,})" '("12345" "12" "345")
       (match&list #/(\d{2,}?)(\d{2,})/ "a12345b"))
(test* "(\\d{1,3}?)(\\d{2,}?)" '("123" "1" "23")
       (match&list #/(\d{1,3}?)(\d{2,}?)/ "a1234b"))
(test* "(\\d{1,3}?)(\\d{0,2}?)" '("1" "1" "")
       (match&list #/(\d{1,3}?)(\d{0,2}?)/ "a1234b"))

;;-------------------------------------------------------------------------
(test-section "uncapturing group")

(test* "a(?:b)*c(d)"  "d"
       (rxmatch-substring (#/a(?:b)*c(d)/ "abcdbcdefg") 1))
(test* "a(?:bcd)*e(f)"  "f"
       (rxmatch-substring (#/a(?:bcd)*e(f)/ "abcdbcdefg") 1))
(test* "a(?:bcd)*e(f)"  "f"
       (rxmatch-substring (#/a(?:bcd)*e(f)/ "aefg") 1))
(test* "a(?:bcd)+e(f)"  #f
       (rxmatch-substring (#/a(?:bcd)+e(f)/ "aefg") 1))
(test* "a(?:bc(de(?:fg)?hi)jk)?l" "defghi"
       (rxmatch-substring (#/a(?:bc(de(?:fg)?hi)jk)?l/ "abcdefghijkl") 1))
(test* "a(?:bc(de(?:fg)?hi)jk)?l" "dehi"
       (rxmatch-substring (#/a(?:bc(de(?:fg)?hi)jk)?l/ "abcdehijkl") 1))

(test* "a(?i:bc)d" "aBCd"
       (rxmatch-substring (#/a(?i:bc)d/ "!aBCd!")))
(test* "a(?i:bc)d" #f
       (rxmatch-substring (#/a(?i:bc)d/ "!aBCD!")))
(test* "a(?i:[a-z]+)d" "aBcd"
       (rxmatch-substring (#/a(?i:[a-z]+)d/ "!aBcd!")))
(test* "a(?i:[a-z]+)d" #f
       (rxmatch-substring (#/a(?i:[a-z]+)d/ "!ABcd!")))

(test* "A(?-i:Bc)D" "ABcD"
       (rxmatch-substring (#/A(?-i:Bc)D/ "!ABcD!")))
(test* "A(?-i:Bc)D" #f
       (rxmatch-substring (#/A(?-i:Bc)D/ "!ABcd!")))
(test* "A(?-i:[A-Z]+)D" "ABCD"
       (rxmatch-substring (#/A(?-i:[A-Z]+)D/ "!ABCD!")))
(test* "A(?-i:[A-Z]+)D" #f
       (rxmatch-substring (#/A(?-i:[A-Z]+)D/ "!abCD!")))

(test* "A(?-i:Bc)D/i" "aBcd"
       (rxmatch-substring (#/A(?-i:Bc)D/i "!aBcd!")))
(test* "A(?-i:Bc)D/i" #f
       (rxmatch-substring (#/A(?-i:Bc)D/i "!abCd!")))
(test* "A(?-i:[A-Z]+)D/i" "aBCd"
       (rxmatch-substring (#/A(?-i:[A-Z]+)D/i "!aBCd!")))
(test* "A(?-i:[A-Z]+)D/i" #f
       (rxmatch-substring (#/A(?-i:[A-Z]+)D/i "!abcd!")))

;; these test optimizer
(test* "^(?i:a*).$" "b"
       (rxmatch-substring (#/^(?i:a*).$/ "b")))
(test* "^(?i:a*).$" "a"
       (rxmatch-substring (#/^(?i:a*).$/ "a")))
(test* "^(?i:a*).$" "A"
       (rxmatch-substring (#/^(?i:a*).$/ "A")))
(test* "^(?i:a*).$" "Ab"
       (rxmatch-substring (#/^(?i:a*).$/ "Ab")))

;;-------------------------------------------------------------------------
(test-section "backreference")
(test* "^(.)\\1$" '("aa" "a")
       (match&list #/^(.)\1$/ "aa"))
(test* "^(.)\\1$" #f
       (match&list #/^(.)\1$/ "ab"))
(test* "(.+)\\1" '("123123" "123")
       (match&list #/(.+)\1/ "a123123j"))
(test* "/(.+)\\1/i" '("AbCaBC" "AbC")
       (match&list #/(.+)\1/i "AbCaBC"))
(test* "/(.+)\\1/i" #f
       (match&list #/(.+)\1/ "AbCAb1"))
(test* "^\\1(.)$" *test-error*
       (string->regexp "^\\1(.)"))
(test* "^(\\1)$" *test-error*
       (string->regexp "^(\\1)$"))

;;-------------------------------------------------------------------------
(test-section "independent subexpression")
(test* "(?>.*\\/)foo" #f
       (match&list #/(?>.*\/)foo/ "/this/is/a/long/line/"))
(test* "(?>.*\\/)foo" '("/this/is/a/long/line/foo")
       (match&list #/(?>.*\/)foo/ "/this/is/a/long/line/foo"))
(test* "(?>(\.\d\d[1-9]?))\d+" '(".230003938" ".23")
       (match&list #/(?>(\.\d\d[1-9]?))\d+/ "1.230003938"))
(test* "(?>(\.\d\d[1-9]?))\d+" '(".875000282" ".875")
       (match&list #/(?>(\.\d\d[1-9]?))\d+/ "1.875000282"))
(test* "(?>(\.\d\d[1-9]?))\d+" #f
       (match&list #/(?>(\.\d\d[1-9]?))\d+/ "1.235"))
(test* "^((?>\\w+)|(?>\\s+))*$" '("foo bar" "bar")
       (match&list #/^((?>\w+)|(?>\s+))*$/ "foo bar"))
(test* "a*+a" #f
       (match&list #/a*+a/ "aaa"))
(test* "a*+b" '("aab")
       (match&list #/a*+b/ "aab"))
(test* "a++a" #f
       (match&list #/a++a/ "aaa"))
(test* "a++b" '("aab")
       (match&list #/a++b/ "aab"))
(test* "(a?+)a" #f
       (match&list #/a?+a/ "a"))
(test* "(a?+)b" '("ab")
       (match&list #/a?+b/ "ab"))

;;-------------------------------------------------------------------------
(test-section "lookahead assertion")

(test* "^(?=ab(de))(abd)(e)" '("abde" "de" "abd" "e")
       (match&list #/^(?=ab(de))(abd)(e)/ "abde"))
(test* "^(?!(ab)de|x)(abd)(f)" '("abdf" #f "abd" "f")
       (match&list #/^(?!(ab)de|x)(abd)(f)/ "abdf"))
(test* "^(?=(ab(cd)))(ab)" '("ab" "abcd" "cd" "ab")
       (match&list #/^(?=(ab(cd)))(ab)/ "abcd"))
(test* "\w+(?=\t)" '("brown")
       (match&list #/\w+(?=\t)/ "the quick brown\t fox"))
(test* "foo(?!bar)(.*)" '("foolish see?" "lish see?")
       (match&list #/foo(?!bar)(.*)/ "foobar is foolish see?"))
(test* "(?:(?!foo)...|^.{0,2})bar(.*)" '("rowbar etc" " etc")
       (match&list #/(?:(?!foo)...|^.{0,2})bar(.*)/ "foobar crowbar etc"))
(test* "(?:(?!foo)...|^.{0,2})bar(.*)" '("barrel" "rel")
       (match&list #/(?:(?!foo)...|^.{0,2})bar(.*)/ "barrel"))
(test* "(?:(?!foo)...|^.{0,2})bar(.*)" '("2barrel" "rel")
       (match&list #/(?:(?!foo)...|^.{0,2})bar(.*)/ "2barrel"))
(test* "(?:(?!foo)...|^.{0,2})bar(.*)" '("A barrel" "rel")
       (match&list #/(?:(?!foo)...|^.{0,2})bar(.*)/ "A barrel"))
(test* "^(\D*)(?=\d)(?!123)" '("abc" "abc")
       (match&list #/^(\D*)(?=\d)(?!123)/ "abc456"))
(test* "^(\D*)(?=\d)(?!123)" #f
       (match&list #/^(\D*)(?=\d)(?!123)/ "abc123"))
(test* "(?!^)abc" '("abc")
       (match&list #/(?!^)abc/ "the abc"))
(test* "(?!^)abc" #f
       (match&list #/(?!^)abc/ "abc"))
(test* "(?=^)abc" '("abc")
       (match&list #/(?=^)abc/ "abc"))
(test* "(?=^)abc" #f
       (match&list #/(?=^)abc/ "the abc"))
(test* "(\.\d\d((?=0)|\d(?=\d)))" '(".23" ".23" "")
       (match&list #/(\.\d\d((?=0)|\d(?=\d)))/ "1.230003938"))
(test* "(\.\d\d((?=0)|\d(?=\d)))" '(".875" ".875" "5")
       (match&list #/(\.\d\d((?=0)|\d(?=\d)))/ "1.875000282"))
(test* "(\.\d\d((?=0)|\d(?=\d)))" #f
       (match&list #/(\.\d\d((?=0)|\d(?=\d)))/ "1.235"))
(test* "^\D*(?!123)" '("AB")
       (match&list #/^\D*(?!123)/ "ABC123"))
(test* "^(\D*)(?=\d)(?!123)" '("ABC" "ABC")
       (match&list #/^(\D*)(?=\d)(?!123)/ "ABC445"))
(test* "^(\D*)(?=\d)(?!123)" #f
       (match&list #/^(\D*)(?=\d)(?!123)/ "ABC123"))
(test* "a(?!b)." '("ad")
       (match&list #/a(?!b)./ "abad"))
(test* "a(?!b)" '("a")
       (match&list #/a(?!b)/ "abad"))
(test* "a(?=d)." '("ad")
       (match&list #/a(?=d)./ "abad"))
(test* "a(?=c|d)." '("ad")
       (match&list #/a(?=c|d)./ "abad"))

;;-------------------------------------------------------------------------
(test-section "lookbehind assertion")
(test* "(?<=a)b" #f
       (match&list #/(?<=a)b/ "b"))
(test* "(?<=a)b" '("b")
       (match&list #/(?<=a)b/ "ab"))
(test* "(?<=a+)b" '("b")
       (match&list #/(?<=a+)b/ "aab"))
(test* "(?<=x[yz])b" '("b")
       (match&list #/(?<=x[yz])b/ "xzb"))
(test* "(?<=zyx)b" #f
       (match&list #/(?<=zyx)b/ "xyzb"))
(test* "(?<=[ab]+)c" '("c")
       (match&list #/(?<=[ab]+)c/ "abc"))
(test* "(?<!<[^>]+)foo" #f
       (match&list #/(?<!<[^>]*)foo/ "<foo>"))
(test* "(?<!<[^>]+)foo" '("foo")
       (match&list #/(?<!<[^>]*)foo/ "<bar>foo"))
(test* "(?<=^a)b" '("b")
       (match&list #/(?<=^a)b/ "ab"))
(test* "(?<=^)b" #f
       (match&list #/(?<=^)b/ "ab"))
(test* "(?<=^)b" '("b")
       (match&list #/(?<=^)b/ "b"))
(test* ".(?<=^)b" '("^b")
       (match&list #/.(?<=^)b/ "a^b"))
(test* "(?<=^a$)" '("")
       (match&list #/(?<=^a$)/ "a"))
(test* "(?<=^a$)b" '("b")
       (match&list #/(?<=^a$)b/ "a$b"))
(test* "(?<=(a))b" '("b" "a")
       (match&list #/(?<=(a))b/ "ab"))
(test* "(?<=(a)(b))c" '("c" "a" "b")
       (match&list #/(?<=(a)(b))c/ "abc"))
(test* "(?<=(a)|(b))c" '("c" #f "b")
       (match&list #/(?<=(a)|(b))c/ "bc"))
(test* "(?<=(?<!foo)bar)baz" '("baz")
       (match&list #/(?<=(?<!foo)bar)baz/ "abarbaz"))
(test* "(?<=(?<!foo)bar)baz" #f
       (match&list #/(?<=(?<!foo)bar)baz/ "foobarbaz"))
(test* "(?<=\d{3})(?<!999)foo" '("foo")
       (match&list #/(?<=\d{3})(?<!999)foo/ "865foo"))
(test* "(?<=\d{3})(?<!999)foo" #f
       (match&list #/(?<=\d{3})(?<!999)foo/ "999foo"))
(test* "(?<=(?>a*))" *test-error*
       (string->regexp "(?<=(?>a*))"))
(test* "(abc)...(?<=\\1)" '("abcabc" "abc")
       (match&list #/(abc)...(?<=\1)/ "abcabc"))
(test* "/(abC)...(?<=\\1)/i" '("abCAbc" "abC")
       (match&list #/(abC)...(?<=\1)/i "abCAbc"))

;;-------------------------------------------------------------------------
(test-section "named group")
(test* "(?<foo>a)" '("a" "a")
       (match&list #/(?<foo>a)/ "a"))
(test* "(?<foo>a)" "a"
       (let1 m (#/(?<foo>a)/ "a")
         (m 'foo)))
(test* "(?<foo>a)(?<bar>.*)" '("a" "bcd")
       (let1 m (#/(?<foo>a)(?<bar>.*)/ "abcd")
         (list (m 'foo) (m 'bar))))
(test* "(?<foo>a)(?<bar>.*)" '("abcd" "a" "bcd")
       (match&list #/(?<foo>a)(?<bar>.*)/ "abcd"))
(test* "(?<foo>a)" *test-error*
       (let1 m (#/(?<foo>a)/ "abcd")
         (m 'bar)))
(test* "(?<foo>^a$)" '("a" "a")
       (match&list #/(?<foo>^a$)/ "a"))
(test* "(?<foo>^a$)" #f
       (match&list #/(?<foo>^a$)/ "ab"))
(test* "(?<name-with-hyphen>a)" '("a" "a")
       (match&list #/(?<name-with-hyphen>a)/ "a"))
(test* "(?<host>\d+.\d+.\d+.\d+)|(?<host>[\w.]+)"
       '("127.0.0.1" "127.0.0.1" #f "127.0.0.1")
       (let1 m (#/(?<host>\d+.\d+.\d+.\d+)|(?<host>[\w.]+)/ "127.0.0.1")
         (list (m 0) (m 1) (m 2) (m 'host))))
(test* "(?<host>\d+.\d+.\d+.\d+)|(?<host>[\w.]+)"
       '("foo.com" #f "foo.com" "foo.com")
       (let1 m (#/(?<host>\d+.\d+.\d+.\d+)|(?<host>[\w.]+)/ "foo.com")
         (list (m 0) (m 1) (m 2) (m 'host))))
(test* "(?<foo>.+)\\k<foo>" '("abcabc" "abc")
       (match&list #/(?<foo>.+)\k<foo>/ "abcabc"))
(test* "(?<foo>.+)\\k<foo>" #f
       (match&list #/(?<foo>.+)\k<foo>/ "abcdef"))
(test* "\\k<foo>" *test-error*
       (regexp-parse "\\k<foo>"))
(test* "rxmatch-before" "abc"
       (rxmatch-before (#/(?<foo>def)/ "abcdefghi") 'foo))
(test* "rxmatch-after" "ghi"
       (rxmatch-after (#/(?<foo>def)/ "abcdefghi") 'foo))
(test* "rxmatch-start" 3
       (rxmatch-start (#/(?<foo>def)/ "abcdefghi") 'foo))
(test* "rxmatch-end" 6
       (rxmatch-end (#/(?<foo>def)/ "abcdefghi") 'foo))

;;-------------------------------------------------------------------------
(test-section "conditional subexpression")
(test* "(a)(?(1)b)" '("ab" "a")
       (match&list #/(a)(?(1)b)/ "ab"))
(test* "(a)(?(1)b)" #f
       (match&list #/(a)(?(1)b)/ "aa"))
(test* "(a)(?(1)b|c)" #f
       (match&list #/(a)(?(1)b)/ "ac"))
(test* "(a)?(?(1)b|c)" #f
       (match&list #/(a)?(?(1)b|c)/ "xb"))
(test* "(a)?(?(1)b|c)" '("c" #f)
       (match&list #/(a)?(?(1)b|c)/ "xc"))
(test* "(?(?<=a)b)" '("b")
       (match&list #/(?(?<=a)b)/ "ab"))
(test* "(?(?<=a)b)" #f
       (match&list #/(?(?<=a)b)/ "ac"))
(test* "(?(?<=a)b)" #f
       (match&list #/(?(?<=a)b)/ "xb"))
(test* "(?(?<=a)b|c)" '("b")
       (match&list #/(?(?<=a)b)/ "ab"))
(test* "(?(?<=a)b|c)" #f
       (match&list #/(?(?<=a)b)/ "ac"))
(test* "(?(?a)b|c)" *test-error*
       (regexp-parse "(?(?a)b|c)"))
(test* "()(?(1))" '("" "")
       (match&list #/()(?(1))/ ""))

(test* "()(?(" *test-error*
       (regexp-parse "()((?("))
(test* "()(?(1" *test-error*
       (regexp-parse "()((?(1"))
(test* "()(?(1)b|c|d)" *test-error*
       (regexp-parse "()(?(1)b|c|d)"))

;;-------------------------------------------------------------------------
(test-section "regexp macros")

(use gauche.regexp)

(test* "rxmatch-let" '("23:59:58" "23" "59" "58")
       (rxmatch-let (rxmatch #/(\d+):(\d+):(\d+)/
                             "Jan  1 23:59:58, 2001")
           (time hh mm ss)
         (list time hh mm ss)))
(test* "rxmatch-let" '("23" "59")
       (rxmatch-let (rxmatch #/(\d+):(\d+):(\d+)/
                             "Jan  1 23:59:58, 2001")
           (#f hh mm)
         (list hh mm)))

(test* "rxmatch-if" "time is 11:22"
       (rxmatch-if (rxmatch #/(\d+:\d+)/ "Jan 1 11:22:33")
           (time)
         (format #f "time is ~a" time)
         "unknown time"))
(test* "rxmatch-if" "unknown time"
       (rxmatch-if (rxmatch #/(\d+:\d+)/ "Jan 1 11-22-33")
           (time)
         (format #f "time is ~a" time)
         "unknown time"))

(define (test-parse-date str)
  (rxmatch-cond
    (test (not (string? str)) #f)
    ((rxmatch #/^(\d\d?)\/(\d\d?)\/(\d\d\d\d)$/ str)
     (#f mm dd yyyy)
     (map string->number (list yyyy mm dd)))
    ((rxmatch #/^(\d\d\d\d)\/(\d\d?)\/(\d\d?)$/ str)
     (#f yyyy mm dd)
     (map string->number (list yyyy mm dd)))
    ((rxmatch #/^\d+\/\d+\/\d+$/ str)
     (#f)
     (error "ambiguous:" str))
    (else (error "bogus:" str))))

(test* "rxmatch-cond" '(2001 2 3)
       (test-parse-date "2001/2/3"))
(test* "rxmatch-cond" '(1999 12 25)
       (test-parse-date "1999/12/25"))
(test* "rxmatch-cond" #f
       (test-parse-date 'abc))

(define (test-parse-date2 str)
  (rxmatch-case str
    (test (lambda (s) (not (string? s))) #f)
    (#/^(\d\d?)\/(\d\d?)\/(\d\d\d\d)$/ (#f mm dd yyyy)
        (map string->number (list yyyy mm dd)))
    (#/^(\d\d\d\d)\/(\d\d?)\/(\d\d?)$/ (#f yyyy mm dd)
        (map string->number (list yyyy mm dd)))
    (#/^\d+\/\d+\/\d+$/  (#f) (error "ambiguous:" str))
    (else (error "bogus:" str))))

(test* "rxmatch-case" '(2001 2 3)
       (test-parse-date2 "2001/2/3"))
(test* "rxmatch-case" '(1999 12 25)
       (test-parse-date2 "1999/12/25"))
(test* "rxmatch-case" #f
       (test-parse-date2 'abc))

(test* "regexp-replace" "abc|def|ghi"
       (regexp-replace #/def|DEF/ "abcdefghi" "|\\0|"))

(test* "regexp-replace" "abc|\\0|ghi"
       (regexp-replace #/def|DEF/ "abcdefghi" "|\\\\0|"))

(test* "regexp-replace" "abraabra**brabra**brabrabracadabrabrabra"
       (regexp-replace #/a((bra)+)cadabra/
                       "abraabraabrabracadabrabrabrabracadabrabrabra"
                       "**\\1**"))

(test* "regexp-replace-all" "abraabra**brabra**br**brabra**brabra"
       (regexp-replace-all #/a((bra)+)cadabra/
                           "abraabraabrabracadabrabrabrabracadabrabrabra"
                           "**\\1**"))

(test* "regexp-replace" "abfedhi"
       (regexp-replace #/c(.*)g/ "abcdefghi" 
                       (lambda (m)
                         (list->string
                          (reverse
                           (string->list (rxmatch-substring m 1)))))))

(test* "regexp-replace-all" "abraabra(bra^2)br(bra^2)brabra"
       (regexp-replace-all #/a((bra)+)cadabra/
                           "abraabraabrabracadabrabrabrabracadabrabrabra"
                           (lambda (m)
                             (format #f "(bra^~a)"
                                     (/ (string-length (rxmatch-substring m 1))
                                        3)))))

(test* "regexp-replace-all" *test-error*
       (regexp-replace-all #/\d*/ "abcdef" "X"))
(test* "regexp-replace-all" *test-error*
       (regexp-replace-all #/\d*/ "123abcdef" "X"))

(test* "regexp-replace*" "cbazzbc"
       (regexp-replace* "abcbabc"
                        #/abc/ "cba"
                        #/aba/ "abc"
                        #/bc/  "zz"))

(test* "regexp-replace-all*" "cbazzccbazz"
       (regexp-replace-all* "abcbacabcbc"
                            #/abc/ "cba"
                            #/aba/ "abc"
                            #/bc/  "zz"))

;;-------------------------------------------------------------------------
(test-section "regexp cimatch")

(test* "regexp/ci" "BC"
       (cond ((rxmatch #/bc/i "ABCD") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" "bC"
       (cond ((rxmatch #/Bc/i "AbCD") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" "bc"
       (cond ((rxmatch #/BC/i "AbcD") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" #f
       (cond ((rxmatch #/Bc/ "AbCD") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" #f
       (cond ((rxmatch #/BC/ "ABcD") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" "PAD"
       (cond ((rxmatch #/p[a-z]d/i "PAD") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" "pad"
       (cond ((rxmatch #/P[A-Z]D/i "pad") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" "bad"
       (cond ((rxmatch #/.[a-pQ-Z][A-Pq-z]/i "bad") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" #f
       (cond ((rxmatch #/p[a-z]d/ "PAD") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" #f
       (cond ((rxmatch #/P[A-Z]D/ "pad") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" #f
       (cond ((rxmatch #/.[a-pQ-Z][A-Pq-z]/ "bad") => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" "pad"
       (cond ((rxmatch (string->regexp "p[A-Z]d" :case-fold #t) "pad")
              => rxmatch-substring)
             (else #f)))
(test* "regexp/ci" #f
       (cond ((rxmatch (string->regexp "p[A-Z]d") "pad")
              => rxmatch-substring)
             (else #f)))

;;-------------------------------------------------------------------------
(test-section "applicable regexp")

(define match #f)

(test* "object-apply regexp" #t
       (begin
         (set! match (#/(\d+)\.(\d+)/ "pi=3.14..."))
         (regmatch? match)))

(test* "object-apply regmatch (index)" '("3.14" "3" "14")
       (list (match) (match 1) (match 2)))

(test* "object-apply regmatch (symbol)" '("..." ".14..." "pi=" "pi=3.")
       (list (match 'after) (match 'after 1)
             (match 'before) (match 'before 2)))

(set! match (#/(?<int>\d+)\.(?<frac>\d+)/ "pi=3.14..."))

(test* "object-apply regmatch (index)" '("3.14" "3" "14" "3" "14")
       (list (match) (match 1) (match 2)
             (match 'int) (match 'frac)))

(test* "object-apply regmatch (symbol)"
       '("..." ".14..." ".14..." "pi=" "pi=3." "pi=3.")
       (list (match 'after) (match 'after 1) (match 'after 'int)
             (match 'before) (match 'before 2) (match 'before 'frac)))

(test* "object-apply regmatch (named submatch)"
       '("..." ".14..." ".14..." "pi=" "pi=3." "pi=3.")
       (list (match 'after) (match 'after 1) (match 'after 'int)
             (match 'before) (match 'before 2) (match 'before 'frac)))

;;-------------------------------------------------------------------------
(test-section "regexp quote")

(test* "regexp-quote" #t
       (let ((str "^(#$%#}{)\\-+?^$"))
         (regmatch? (rxmatch (string->regexp (regexp-quote str)) str))))

;;-------------------------------------------------------------------------
(test-section "regexp comparison")

(test* "equal #/abc/ #/abc/" #t
       (equal? #/abc/ #/abc/))
(test* "not equal #/abc/ #/a(bc)/" #f
       (equal? #/abc/ #/a(bc)/))
(test* "not equal #/abc/ #/abc/i" #f
       (equal? #/abc/ #/abc/i))
(test* "not equal #/abc/i #/abc/" #f
       (equal? #/abc/i #/abc/))
(test* "equal #/abc/i #/abc/i" #t
       (equal? #/abc/i #/abc/i))

(test-end)
