(cl:defpackage #:pantalea.timing-wheel
  (:use #:common-lisp #:iterate)
  (:local-nicknames
   (#:q #:pantalea.queue))
  (:import-from #:metabang.bind
                #:bind)
  (:import-from #:log4cl
                #:log-info
                #:log-warn)
  (:export
   #:stop-thread
   #:stop!
   #:run
   #:add!))
