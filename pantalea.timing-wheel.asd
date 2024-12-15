(asdf:defsystem #:pantalea.timing-wheel
  :name "timing wheel"
  :depends-on (#:bordeaux-threads #:pantalea.queue)
  :serial T
  :pathname "source"
  :components ((:file "package")
               (:file "code")))
