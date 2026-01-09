(defpackage :alive/lw/streams
    (:use :cl)
    (:export :io-stream
             :flush-out-buffer
             :set-in-listener
             :set-out-listener))

(in-package :alive/lw/streams)


(defclass io-stream (stream:fundamental-character-input-stream
                     stream:fundamental-character-output-stream)
        ((in-buffer :accessor in-buffer
                    :initform nil
                    :initarg :in-buffer)
         (in-listener :accessor in-listener
                      :initform nil
                      :initarg :in-listener)
         (in-lock :accessor in-lock
                  :initform (bt:make-recursive-lock)
                  :initarg :in-lock)
         (in-cond-var :accessor in-cond-var
                      :initform (bt:make-condition-variable)
                      :initarg :in-cond-var)
         (line :accessor line
               :initform 1
               :initarg :line)
         (column :accessor column
                 :initform 0
                 :initarg :column)
         (pos-stack :accessor pos-stack
                    :initform nil
                    :initarg :pos-stack)

         (out-buffer :accessor out-buffer
                     :initform (make-string-output-stream)
                     :initarg :out-buffer)
         (out-listener :accessor out-listener
                       :initform nil
                       :initarg :out-listener)
         (out-lock :accessor out-lock
                   :initform (bt:make-recursive-lock)
                   :initarg :out-lock)
         (out-cond-var :accessor out-cond-var
                       :initform (bt:make-condition-variable)
                       :initarg :out-cond-var)))


(defmethod stream:stream-unread-char ((obj io-stream) ch)
    (if (eq :eof (in-buffer obj))
        (setf (in-buffer obj) (princ-to-string ch))
        (setf (in-buffer obj) (format nil "~C~A" ch (in-buffer obj))))

    (let ((prev (pop (pos-stack obj))))
        (when prev
              (setf (line obj) (car prev)
                    (column obj) (cdr prev))))

    nil)


(defmethod stream:stream-read-char ((obj io-stream))
    (bt:with-recursive-lock-held ((in-lock obj))
        (flush-out-buffer obj)

        (when (and (in-listener obj)
                   (not (in-buffer obj)))
              (setf (in-buffer obj)
                  (funcall (in-listener obj))))

        (if (or (eq :eof (in-buffer obj))
                (zerop (length (in-buffer obj))))

            (progn (setf (in-buffer obj) nil)
                   #\newline)

            (let ((ch (elt (in-buffer obj) 0)))
                (setf (in-buffer obj)
                    (subseq (in-buffer obj) 1))

                (when (zerop (length (in-buffer obj)))
                      (setf (in-buffer obj) :eof))

                (setf (pos-stack obj)
                      (list (cons (line obj) (column obj))))
                (if (char= ch #\newline)
                    (progn (incf (line obj))
                           (setf (column obj) 0))
                    (incf (column obj)))

                ch))))


(defmethod stream-element-type ((obj io-stream))
    (declare (ignore obj))
    'character)


(defmethod close ((obj io-stream) &key abort)
    (declare (ignore abort))

    (bt:with-recursive-lock-held ((out-lock obj))
        (bt:condition-notify (out-cond-var obj))))


(defun flush-out-buffer (obj)
    (let ((str (get-output-stream-string (out-buffer obj))))
        (when (and (out-listener obj)
                   (< 0 (length str)))
              (funcall (out-listener obj) str))))


(defmethod stream:stream-write-char ((obj io-stream) ch)
    (if (char= #\newline ch)
        (flush-out-buffer obj)
        (write-char ch (out-buffer obj))))

(defmethod stream:stream-line-column ((obj io-stream))
    (values (line obj) (column obj)))


(defun set-in-listener (obj listener)
    (when obj
          (setf (in-listener obj) listener)))


(defun set-out-listener (obj listener)
    (when obj
          (setf (out-listener obj) listener)))
