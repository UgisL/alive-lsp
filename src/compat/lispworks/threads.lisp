(defpackage :alive/lw/threads
    (:use :cl)
    (:export :get-thread-id))

(in-package :alive/lw/threads)


(declaim (ftype (function (T) (values (or null simple-string) &optional)) get-thread-id))
(defun get-thread-id (thread)
    (bt:thread-name thread))
