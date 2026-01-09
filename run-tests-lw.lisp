
;; Script to run alive-lsp tests in LispWorks

(require "asdf")
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))
;; Alive path
(defvar *alive-dir* nil)
(setq *alive-dir* (princ-to-string (or *load-truename* *compile-file-truename*)))
(setq *alive-dir* (subseq *alive-dir* 0 (- (length *alive-dir*) 17)))
(print *alive-dir*)
(push (pathname *alive-dir*) asdf:*central-registry*)
(asdf:load-system :alive-lsp)
(asdf:load-system :alive-lsp/test)
(alive/test/suite:run-all)
(quit)
