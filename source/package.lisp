(cl:defpackage #:pantalea.timing-wheel
  (:use #:common-lisp #:iterate)
  (:local-nicknames
   (#:q #:pantalea.queue))
  (:import-from #:metabang.bind
                #:bind)
  (:export
   #:stop!
   #:run
   #:add!))
