#|
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1) Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2) Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
|#
(cl:in-package #:pantalea.timing-wheel)


(defclass timing-wheel ()
  ((%tick-duration
    :initarg :tick-duration
    :documentation "Tick duration in ms"
    :accessor tick-duration)
   (%buckets
    :initarg :buckets
    :accessor buckets)
   (%lock
    :initform (bt2:make-lock :name "TIMING-WHEEL lock")
    :accessor lock)
   (%wheel-pointer
    :initform 0
    :accessor wheel-pointer)
   (%thread
    :initarg :thread
    :initform nil
    :accessor thread)))

(define-condition stop-thread ()
  ())

(defun make-timing-wheel (size tick-duration)
  (assert (> size 0))
  (assert (> tick-duration 0))
  (make-instance 'timing-wheel
                 :tick-duration tick-duration
                 :buckets (map-into (make-array size) #'q:make-queue)))

(defstruct task
  callback
  (remaining-rounds 0 :type fixnum))

(defun task-run! (task &aux (callback (task-callback task)))
  (funcall callback))

(defun tick! (timing-wheel)
  (declare (optimize (speed 3) (safety 0)))
  (bind ((buckets (buckets timing-wheel))
         (wheel-pointer (wheel-pointer timing-wheel))
         (bucket (svref buckets wheel-pointer)))
    (declare (type simple-vector buckets)
             (type fixnum wheel-pointer))
    (q:queue-filter! bucket
                     (lambda (task)
                       (if (<= (task-remaining-rounds task) 0)
                           (progn
                             (task-run! task)
                             nil)
                           (progn
                             (decf (task-remaining-rounds task))
                             t))))
    (bt2:with-lock-held ((lock timing-wheel))
      (setf (wheel-pointer timing-wheel)
            (mod (1+ wheel-pointer) (length buckets))))))

(defun run (size tick-duration)
  (let ((timing-wheel (make-timing-wheel size tick-duration))
        (sleep-duration (/ tick-duration 1000.0)))
    (setf (thread timing-wheel)
          (bt2:make-thread (lambda ()
                             (l:log-info "TMING-WHEEL thread starting.")
                             (handler-case
                                 (iterate
                                   (tick! timing-wheel)
                                   (sleep sleep-duration))
                               (stop-thread (e)
                                 (declare (ignore e))
                                 (log4cl:log-info "TMING-WHEEL thread stopping."))))
                           :name "Timer wheel thread"))
    timing-wheel))

(defun add! (timing-wheel delay callback)
  (bind ((tick-duration (tick-duration timing-wheel))
         (ticks (round (+ delay tick-duration) tick-duration))
         (buckets (buckets timing-wheel))
         (size (length buckets))
         (pointer (mod (+ (bt2:with-lock-held ((lock timing-wheel))
                            (wheel-pointer timing-wheel))
                          ticks)
                       size)))
    (declare (type simple-vector buckets))
    (q:queue-push! (aref buckets pointer)
                   (make-task :callback callback
                              :remaining-rounds (truncate ticks size)))
    callback))

(defun join-thread! (timing-wheel)
  (bt2:join-thread (thread timing-wheel)))
