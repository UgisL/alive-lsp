(defpackage :alive/lw/symbols
    (:use :cl)
    (:export :callable-p
             :get-lambda-list
             :function-p)
    (:local-nicknames (:utils :alive/utils)))

(in-package :alive/lw/symbols)


(defun get-lambda-list (fn-name &optional pkg-name)
    (let ((sym (utils:lookup-symbol fn-name pkg-name)))
        (when (and sym (fboundp sym))
              (multiple-value-bind (lambda-expr name plist)
                      (function-lambda-expression (symbol-function sym))
                  (declare (ignore name plist))
                  (when (and (consp lambda-expr)
                             (eq (first lambda-expr) 'lambda))
                        (second lambda-expr))))))


(defun function-p (sym-name &optional pkg-name)
    (let ((sym (utils:lookup-symbol sym-name pkg-name)))
        (and sym
             (fboundp sym)
             (not (macro-function sym)))))
