(defpackage :alive/lw/file
    (:use :cl)
    (:export :do-compile
             :do-load
             :try-compile)
    (:local-nicknames (:forms :alive/parse/forms)
                      (:comp-msg :alive/compile-message)
                      (:range :alive/range)
                      (:pos :alive/position)
                      (:types :alive/types)))

(in-package :alive/lw/file)


(defmacro with-forms ((path) &body body)
    (let ((file-id (gensym)))
        `(with-open-file (,file-id ,path)
             (let ((forms (forms:from-stream ,file-id)))
                 ,@body))))


(defun get-int-value (needle hay start delim)
    (let* ((pos (search needle hay :start2 start))
           (begin (when pos (+ pos (length needle))))
           (end (when begin (if delim
                                (search delim hay :start2 begin)
                                (length hay)))))
        (when (and begin end)
              (ignore-errors
                  (parse-integer (subseq hay begin end) :junk-allowed t)))))


(defun find-line-number (msg)
    (or (get-int-value "line: " msg 0 ",")
        (get-int-value "line " msg 0 ")")
        (get-int-value "line " msg 0 ",")
        (get-int-value "line " msg 0 " ")))


(defun parse-err-loc (err-msg)
    (let* ((msg (string-downcase err-msg))
           (line (find-line-number msg)))
        (when (and line (< 0 line))
              (range:create (pos:create (- line 1) 0)
                            (pos:create (- line 1) #xFFFF)))))


(defun get-err-location (err forms)
    (declare (ignore forms))
    (parse-err-loc (princ-to-string err)))


(defun send-message (out-fn forms sev err)
    (let* ((loc (get-err-location err forms))
           (msg (comp-msg:create :severity sev
                                 :location loc
                                 :message (format nil "~A" err))))
        (when loc
              (funcall out-fn msg))))


(defun already-have-msg-p (new-msg msgs)
    (find-if (lambda (msg)
                 (and (string= (gethash "severity" new-msg)
                               (gethash "severity" msg))
                      (string= (gethash "message" new-msg)
                               (gethash "message" msg))))
            msgs))


(defun should-filter-p (msg)
    (search "redefin" msg))


(defun add-message (msgs msg)
    (if (or (already-have-msg-p msg msgs)
            (should-filter-p (comp-msg:get-message msg)))
        msgs
        (cons msg msgs)))


(defun do-cmd (path cmd &optional (stop-on-error nil))
    (with-forms (path)
        (let* ((msgs nil)
               (capture-msg (lambda (msg)
                                (setf msgs (add-message msgs msg))))
               (handle-error (lambda (err)
                                 (send-message capture-msg forms types:*sev-error* err)
                                 (when stop-on-error
                                       (return-from do-cmd msgs)))))
            (labels ((handle-skippable (sev)
                                       (lambda (err)
                                           (send-message capture-msg forms sev err)
                                           (let ((skip (find-restart 'muffle-warning err)))
                                               (if skip
                                                   (invoke-restart skip)
                                                   (return-from do-cmd msgs))))))
                (handler-bind ((warning (handle-skippable types:*sev-warn*))
                               (error handle-error))
                    (funcall cmd path)
                    msgs)))))


(defun do-compile (path)
    (do-cmd path 'compile-file))

(defun do-load (path)
    (do-compile path)
    (do-cmd path 'load))

(defun try-compile (path)
    (do-cmd path 'compile-file T))
