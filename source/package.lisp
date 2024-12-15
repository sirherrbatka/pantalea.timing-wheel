(cl:defpackage #:pantalea.timing-wheel
  (:use #:common-lisp #:iterate #:metabang.bind)
  (:local-nicknames
   (#:q #:pantalea.queue))
  (:import-from #:log4cl
                #:log-info
                #:log-warn)
  (:export
   #:join-thread!
   #:stop-thread
   #:run
   #:add!))
