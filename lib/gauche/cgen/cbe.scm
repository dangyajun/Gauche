;;;
;;; gauche.cgen.cbe - C back-end
;;;
;;;   Copyright (c) 2022  Shiro Kawai  <shiro@acm.org>
;;;
;;;   Redistribution and use in source and binary forms, with or without
;;;   modification, are permitted provided that the following conditions
;;;   are met:
;;;
;;;   1. Redistributions of source code must retain the above copyright
;;;      notice, this list of conditions and the following disclaimer.
;;;
;;;   2. Redistributions in binary form must reproduce the above copyright
;;;      notice, this list of conditions and the following disclaimer in the
;;;      documentation and/or other materials provided with the distribution.
;;;
;;;   3. Neither the name of the authors nor the names of its contributors
;;;      may be used to endorse or promote products derived from this
;;;      software without specific prior written permission.
;;;
;;;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;;;   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;;;   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;;;   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;;;   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;;   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
;;;   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;;;   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;;;   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;;   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;;   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;;

(define-module gauche.cgen.cbe
  (use gauche.cgen)
  (use gauche.cgen.bbb)
  (use gauche.vm.insn)
  (use gauche.sequence)
  (use scheme.list)
  (use scheme.set)
  (use srfi-13)
  (use util.match)
  (use text.tr)
  (export compile-b->c))
(select-module gauche.cgen.cbe)

(define (compile-b->c toplevel-benv)
  (parameterize ([cgen-current-unit (make <cgen-unit> :name "t")])
    (cgen-decl "#include <gauche.h>"
               "#include <gauche/precomp.h>"
               "")
    (benv->c toplevel-benv)
    (cgen-emit-c (cgen-current-unit))))

(define (benv->c benv)
  (for-each benv->c (~ benv'children))
  (for-each cluster->c (~ benv'clusters)))

(define (cluster->c cluster)
  (define cfn-name (cluster-cfn-name cluster))
  (cgen-decl #"static ScmObj ~|cfn-name|(ScmObj, void**);")
  (unless (and (set-empty? (~ cluster'xregs))
               (set-empty? (~ cluster'aregs)))
    (cgen-decl #"struct ~|cfn-name|_ENV {")
    (set-for-each (^r (cgen-decl #"  ScmObj ~(reg-safe-name r);"))
                  (~ cluster'xregs))
    (set-for-each (^r (cgen-decl #"  ScmObj ~(reg-safe-name r);"))
                  (~ cluster'aregs))
    (cgen-decl "};"))
  (cgen-decl "")
  (cgen-body ""
             #"ScmObj ~|cfn-name|(ScmObj VAL0, void **DATA)"
             #"{")
  (unless (and (set-empty? (~ cluster'xregs))
               (set-empty? (~ cluster'aregs)))
    (cgen-body #" struct ~|cfn-name|_ENV *ENV ="
               #"   (struct ~|cfn-name|_ENV *)DATA[1];"))
  (cgen-body (string-concatenate
              `(" ScmObj "
                ,@($ intersperse ","
                     (map (cut reg-cexpr cluster <>)
                          (set->list (~ cluster'lregs))))
                ";")))
  (unless (null? (~ cluster'entry-blocks))
    (cgen-body #" switch ((int)DATA[0]) {")
    (for-each-with-index
     (^[i bb] (cgen-body #"    case ~(+ i 1): goto ~(bb-name bb);"))
     (~ cluster'entry-blocks))
    (cgen-body #" }"))
  (for-each block->c (reverse (~ cluster'blocks)))
  (cgen-body #"}"))

(define (block->c block)
  (cgen-body #"~(cgen-safe-name-friendly (bb-name block)):")
  (for-each (cute insn->c (~ block'cluster) <>)
            (reverse (~ block'insns))))

(define (insn->c c insn)
  (define (R reg) (reg-cexpr c reg))
  (match insn
    [('MOV rd rs) (cgen-body #" ~(R rd) = ~(R rs);")]
    [('LD r id)   (let1 c-id (cgen-literal id)
                    (cgen-body
                     #" ~(R r) = /* ~(cgen-safe-comment (~ id'name)) */"
                     #"  Scm_IdentifierGlobalRef(~(cgen-cexpr c-id), NULL);"))]
    [('ST r id)   (let1 c-id (cgen-literal id)
                    (cgen-body
                     #" /* ~(cgen-safe-comment (~ id'name)) */"
                     #" Scm_GlobalVariableSet(~(cgen-cexpr c-id),"
                     #"                       ~(R r),"
                     #"                       NULL);"))]
    [('CLOSE r b) (cgen-body #" ~(R r) ="
                             #"   %%WRITEME%%Scm_MakeClosure ~(x->string b);")]
    [('BR r b1 b2)(cgen-body #" if (SCM_FALSEP(~(R r)))")
                  (gen-jump-cstmt c b1)
                  (cgen-body #" else")
                  (gen-jump-cstmt c b2)]
    [('JP b)      (gen-jump-cstmt c b)]
    [('CONT b)    (gen-cont-cstmt c b)]
    [('CALL bb proc r ...) (gen-vmcall c proc r)]
    [('RET r . rs)(cgen-body #" return ~(R r);")]
    [('DEF id flags r)
     (let1 c-id (cgen-literal id)
       (cgen-body #" /* ~(cgen-safe-comment (~ id'name)) */"
                  #" Scm_Define(~(cgen-cexpr c-id), ~(R r));"))]
    ;; Builtin operations
    [('CONS r x y) (builtin-2arg c "Scm_Cons" r x y)]
    [('CAR r x) (builtin-1arg c "Scm_Car" r x)]
    [('CDR r x) (builtin-1arg c "Scm_Cdr" r x)]
    [('CAAR r x) (builtin-1arg c "Scm_Caar" r x)]
    [('CADR r x) (builtin-1arg c "Scm_Cadr" r x)]
    [('CDAR r x) (builtin-1arg c "Scm_Cdar" r x)]
    [('CDDR r x) (builtin-1arg c "Scm_Cddr" r x)]
    [('LIST r . xs) (cgen-body #"  ~(R r) = ~(gen-list c xs);")]
    [('LIST* r . xs) (cgen-body #"  ~(R r) = ~(gen-list* c xs);")]
    [('LENGTH r x) (builtin-1arg c "Scm_Length" r x)]
    [('MEMQ r x y) (builtin-2arg c "Scm_Memq" r x y)]
    [('MEMV r x y) (builtin-2arg c "Scm_Memv" r x y)]
    [('ASSQ r x y) (builtin-2arg c "Scm_Assq" r x y)]
    [('ASSV r x y) (builtin-2arg c "Scm_Assv" r x y)]
    [('EQ r x y) (builtin-2arg/bool c "SCM_EQ" r x y)]
    [('EQV r x y) (builtin-2arg/bool c "Scm_EqvP" r x y)]
    [('APPEND r . xs) (cgen-body #" /* WRITEME: APPEND */")]
    [('NOT r x) (cgen-body #" ~(R r) = SCM_MAKE_BOOL(SCM_FALSEP(~(R x)));")]
    [('REVERSE r x) (builtin-1arg c "Scm_Reverse" r x)]
    [('APPLY r . xs) (cgen-body #" /* WRITEME: APPLY */")]
    [('TAIL-APPLY r . xs) (cgen-body #" /* WRITEME: TAIL-APPLY */")]
    [('IS-A r x y) (builtin-2arg/bool c "SCM_ISA" r x y)]
    [('NULLP r x) (builtin-1arg/bool c "SCM_NULLP" r x)]
    [('PAIRP r x) (builtin-1arg/bool c "SCM_PAIRP" r x)]
    [('CHARP r x) (builtin-1arg/bool c "SCM_CHARP" r x)]
    [('EOFP r x) (builtin-1arg/bool c "SCM_EOFP" r x)]
    [('STRINGP r x) (builtin-1arg/bool c "SCM_STRINGP" r x)]
    [('SYMBOLP r x) (builtin-1arg/bool c "SCM_SYMBOLP" r x)]
    [('VECTORP r x) (builtin-1arg/bool c "SCM_VECTORP" r x)]
    [('NUMBERP r x) (builtin-1arg/bool c "SCM_NUMBERP" r x)]
    [('REALP r x) (builtin-1arg/bool c "SCM_REALP" r x)]
    [('IDENTIFIERP r x) (builtin-1arg/bool c "SCM_IDENTIFIERP" r x)]
    [('SETTER r x) (builtin-1arg c "Scm_Setter" r x)]
    [('VEC r . xs) (cgen-body #" /* WRITEME: VEC */")]
    [('LIST->VEC r x) (cgen-body #" /* WRITEME: LIST->VEC */")]
    [('APP-VEC r . xs) (cgen-body #" /* WRITEME: APP-VEC */")]
    [('VEC-LEN r x) (builtin-1arg c "SCM_VECTOR_SIZE" r x)]
    [('VEC-REF r x y)
     (let ([n (gensym 'n)]
           [v (gensym 'v)])
       (cgen-body #"  ScmSmallInt ~n = SCM_PC_GET_INDEX(~(reg-cexpr c y));"
                  #"  ScmVector *~v = SCM_PC_ENSURE_VEC(~(reg-cexpr c x)));"
                  #"  SCM_PC_BOUND_CHECK(SCM_VECTOR_SIZE(~v), ~n);"
                  #"  ~(reg-cexpr c r) = SCM_VECTOR_ELEMENT(~v, ~n);"))]
    [('VEC-SET r x y z)
     (let ([n (gensym 'n)]
           [v (gensym 'v)])
       (cgen-body #"  ScmSmallInt ~n = SCM_PC_GET_INDEX(~(reg-cexpr c y));"
                  #"  ScmVector *~v = SCM_PC_ENSURE_VEC(~(reg-cexpr c x)));"
                  #"  SCM_PC_BOUND_CHECK(SCM_VECTOR_SIZE(~v), ~n);"
                  #"  SCM_VECTOR_ELEMENT(~v, ~n) = ~(reg-cexpr c z);"
                  #"  ~(reg-cexpr c r) = SCM_UNDEFINED;"))]
    [('UVEC-REF r x y z) (cgen-body #" /* WRITEME: UVEC-REF */")]
    [('NUMEQ2 r x y) (builtin-2arg/bool c "SCM_NUMEQ2" r x y)]
    [('NUMLT2 r x y) (builtin-2arg/bool c "SCM_NUMLT2" r x y)]
    [('NUMLE2 r x y) (builtin-2arg/bool c "SCM_NUMLE2" r x y)]
    [('NUMGT2 r x y) (builtin-2arg/bool c "SCM_NUMGT2" r x y)]
    [('NUMGE2 r x y) (builtin-2arg/bool c "SCM_NUMGE2" r x y)]
    [('NUMADD2 r x y) (builtin-2arg c "Scm_Add" r x y)]
    [('NUMSUB2 r x y) (builtin-2arg c "Scm_Sub" r x y)]
    [('NUMMUL2 r x y) (builtin-2arg c "Scm_Mul" r x y)]
    [('NUMDIV2 r x y) (builtin-2arg c "Scm_Div" r x y)]
    [('NUMMOD2 r x y) (builtin-2arg c "SCM_MOD2" r x y)]
    [('NUMREM2 r x y) (builtin-2arg c "SCM_REM2" r x y)]
    [('NEGATE r x) (builtin-1arg c "Scm_Negate" r x)]
    [('ASH r x y) (builtin-2arg c "Scm_Ash" r x y)]
    [('LOGAND r x y) (builtin-2arg c "Scm_LogAnd" r x y)]
    [('LOGIOR r x y) (builtin-2arg c "Scm_LogIor" r x y)]
    [('LOGXOR r x y) (builtin-2arg c "Scm_LogXor" r x y)]
    [('CURIN r) (builtin-0arg c "SCM_CURIN" r)]
    [('CUROUT r) (builtin-0arg c "SCM_CUROUT" r)]
    [('CURERR r) (builtin-0arg c "SCM_CURERR" r)]
    [('UNBOX r x) (builtin-1arg c "Scm_Unbox" r x)]
    ))

(define (builtin-0arg c v r)
  (cgen-body #"  ~(reg-cexpr c r) = SCM_OBJ(~|v|);"))

(define (builtin-1arg c fn r x)
  (cgen-body #"  ~(reg-cexpr c r) = ~|fn|(~(reg-cexpr c x));"))

(define (builtin-1arg/bool c fn r x)
  (cgen-body #"  ~(reg-cexpr c r) = SCM_MAKE_BOOL(~|fn|(~(reg-cexpr c x)));"))

(define (builtin-2arg c fn r x y)
  (cgen-body #"  ~(reg-cexpr c r) = ~|fn|(~(reg-cexpr c x), ~(reg-cexpr c y));"))

(define (builtin-2arg/bool c fn r x y)
  (cgen-body #"  ~(reg-cexpr c r) = SCM_MAKE_BOOL(~|fn|(~(reg-cexpr c x), ~(reg-cexpr c y)));"))

(define (cluster-cfn-name c)
  (cgen-safe-name (x->string (~ c'id))))

;; Returns bb's entry index.
(define (entry-block-index bb)
  (if-let1 i (find-index (cut eq? bb <>) (~ bb'cluster'entry-blocks))
    (+ i 1)
    0))

(define (gen-jump-cstmt c dest-bb)
  (if (eq? c (~ dest-bb'cluster))
    (cgen-body #"  goto ~(bb-name dest-bb);")
    (let ([index (entry-block-index dest-bb)]
          [cfn (cluster-cfn-name (~ dest-bb'cluster))])
      (cgen-body #"  {"
                 #"     ScmWord data[2];"
                 #"     data[0] = SCM_WORD(~index);")
      (prepare-env c (~ dest-bb'cluster))
      (cgen-body #"     data[1] = SCM_WORD(EN2);"
                 #"     return ~|cfn|(SCM_FALSE, data);"
                 #"  }"))))

(define (gen-cont-cstmt c dest-bb)
  (let ([index (entry-block-index dest-bb)]
        [cfn (cluster-cfn-name (~ dest-bb'cluster))])
    (cgen-body #" {"
               #"   ScmWord data[2];"
               #"   data[0] = SCM_WORD(~index);")
    (prepare-env c (~ dest-bb'cluster))
    (cgen-body #"   data[1] = ENV2;"
               #"   Scm_VMPsuhCC(~|cfn|, data, 2);"
               #" }")))

(define (gen-vmcall c proc regs)
  (cgen-body #" return Scm_VMApply(~(reg-cexpr c proc), ~(gen-list c regs));"))

;; Generate code that construct env struct for destination cluster (dest-c)
;; from the env of current cluster (c).  The C variable name for the new
;; env is ENV2.
(define (prepare-env c dest-c)
  (cgen-body #"  struct ~(cluster-cfn-name dest-c)_ENV ENV2 {")
  (set-for-each
   (^r (cgen-body #"     .~(reg-safe-name r) = ~(reg-cexpr c r);"))
   (~ dest-c'xregs))
  (set-for-each
   (^r (cgen-body #"     .~(reg-safe-name r) = ~(reg-cexpr c r);"))
   (~ dest-c'aregs))
  (cgen-body #"  };"))

(define (gen-list c regs)
  (define (rec regs)
    (match regs
      [() '("SCM_NIL")]
      [(reg . regs) `("Scm_Cons(" ,(reg-cexpr c reg) ", " ,@(rec regs) ")")]))
  (string-concatenate (rec regs)))

(define (gen-list* c regs)
  (define (rec regs)
    (match regs
      [(reg) (reg-cexpr c reg)]
      [(reg . regs) `("Scm_Cons(" ,(reg-cexpr c reg) ", " ,@(rec regs) ")")]))
  (string-concatenate (rec regs)))

(define *constant-literals* (make-hash-table 'eq?)) ;; const -> <literal>

(define (reg-safe-name r)
  (let1 m (#/^%(\d+)\.(\d+)(?:\.(.*))?/ (x->string (~ r'name)))
    (format "R~d_~d~a" (m 1) (m 2)
            (if-let1 name (m 3)
              #"_~(cgen-safe-name-friendly name)"
              ""))))

(define (reg-cexpr cluster r)
  (cond
   [(is-a? r <reg>)
    (let1 name (reg-safe-name r)
      (if (set-contains? (~ cluster'lregs) r)
        name
        #"ENV->~name"))]
   [(is-a? r <const>)
    (let1 lit (or (hash-table-get *constant-literals* r #f)
                  (rlet1 lit (cgen-literal (const-value r))
                    (hash-table-put! *constant-literals* r lit)))
      (cgen-cexpr lit))]
   [(eq? r '%VAL0) "VAL0"]
   [else (error "Invalid register: " r)]))