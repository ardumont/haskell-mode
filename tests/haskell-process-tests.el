;;; haskell-process-tests.el

;;; Code:

(require 'ert)
(require 'el-mock)

(require 'haskell-process)

(ert-deftest haskell-process-wrapper-command-function-identity ()
  "No wrapper, return directly the command."
  (should (equal '("ghci")
                 (progn
                   (custom-set-variables '(haskell-process-wrapper-function #'identity))
                   (apply haskell-process-wrapper-function (list '("ghci")))))))

(ert-deftest haskell-process-wrapper-function-non-identity ()
  "Wrapper as a string, return the wrapping command as a string."
  (should (equal '("nix-shell" "default.nix" "--command" "cabal\\ run")
                 (progn
                   (custom-set-variables '(haskell-process-wrapper-function (lambda (argv)
                                                                              (append '("nix-shell" "default.nix" "--command")
                                                                                      (list (shell-quote-argument argv))))))
                   (apply haskell-process-wrapper-function (list "cabal run"))))))

(ert-deftest test-haskell-process--compute-process-log-and-command-ghci ()
  (should (equal '("Starting inferior GHCi process ghci ..." "dumses1" nil "ghci" "-ferror-spans")
                 (let ((haskell-process-path-ghci "ghci")
                       (haskell-process-args-ghci '("-ferror-spans")))
                   (custom-set-variables '(haskell-process-wrapper-function #'identity))
                   (mocklet (((haskell-session-name "dummy-session") => "dumses1"))
                     (haskell-process-compute-process-log-and-command "dummy-session" 'ghci))))))

(ert-deftest test-haskell-process--with-wrapper-compute-process-log-and-command-ghci ()
  (should (equal '("Starting inferior GHCi process ghci ..." "dumses1" nil "nix-shell" "default.nix" "--command" "ghci\\ -ferror-spans")
                 (let ((haskell-process-path-ghci "ghci")
                       (haskell-process-args-ghci '("-ferror-spans")))
                   (custom-set-variables '(haskell-process-wrapper-function
                                           (lambda (argv) (append (list "nix-shell" "default.nix" "--command" )
                                                             (list (shell-quote-argument (mapconcat 'identity argv " ")))))))
                   (mocklet (((haskell-session-name "dummy-session") => "dumses1"))
                     (haskell-process-compute-process-log-and-command "dummy-session" 'ghci))))))

(ert-deftest test-haskell-process--compute-process-log-and-command-cabal-repl ()
  (should (equal '("Starting inferior `cabal repl' process using cabal ..." "dumses2" nil "cabal" "repl" "--ghc-option=-ferror-spans" "dumdum-session")
                 (let ((haskell-process-path-cabal      "cabal")
                       (haskell-process-args-cabal-repl '("--ghc-option=-ferror-spans")))
                   (custom-set-variables '(haskell-process-wrapper-function #'identity))
                   (mocklet (((haskell-session-name "dummy-session2") => "dumses2")
                             ((haskell-session-target "dummy-session2") => "dumdum-session"))
                     (haskell-process-compute-process-log-and-command "dummy-session2" 'cabal-repl))))))

(ert-deftest test-haskell-process--with-wrapper-compute-process-log-and-command-cabal-repl ()
  (should (equal '("Starting inferior `cabal repl' process using cabal ..." "dumses2" nil "nix-shell" "default.nix" "--command" "cabal\\ repl\\ --ghc-option\\=-ferror-spans" "dumdum-session")
                 (let ((haskell-process-path-cabal      "cabal")
                       (haskell-process-args-cabal-repl '("--ghc-option=-ferror-spans")))
                   (custom-set-variables '(haskell-process-wrapper-function
                                           (lambda (argv) (append (list "nix-shell" "default.nix" "--command" )
                                                             (list (shell-quote-argument (mapconcat 'identity argv " ")))))))
                   (mocklet (((haskell-session-name "dummy-session2") => "dumses2")
                             ((haskell-session-target "dummy-session2") => "dumdum-session"))
                     (haskell-process-compute-process-log-and-command "dummy-session2" 'cabal-repl))))))

(ert-deftest test-haskell-process--compute-process-log-and-command-cabal-ghci ()
  (should (equal '("Starting inferior cabal-ghci process using cabal-ghci ..." "dumses3" nil "cabal-ghci")
                 (let ((haskell-process-path-ghci "ghci"))
                   (custom-set-variables '(haskell-process-wrapper-function #'identity))
                   (mocklet (((haskell-session-name "dummy-session3") => "dumses3"))
                     (haskell-process-compute-process-log-and-command "dummy-session3" 'cabal-ghci))))))

(ert-deftest test-haskell-process--with-wrapper-compute-process-log-and-command-cabal-ghci ()
  (should (equal '("Starting inferior cabal-ghci process using cabal-ghci ..." "dumses3" nil "nix-shell" "default.nix" "--command" "cabal-ghci")
                 (let ((haskell-process-path-ghci "ghci"))
                   (custom-set-variables '(haskell-process-wrapper-function
                                           (lambda (argv) (append (list "nix-shell" "default.nix" "--command" )
                                                             (list (shell-quote-argument (mapconcat 'identity argv " ")))))))
                   (mocklet (((haskell-session-name "dummy-session3") => "dumses3"))
                     (haskell-process-compute-process-log-and-command "dummy-session3" 'cabal-ghci))))))

(ert-deftest test-haskell-process--compute-process-log-and-command-cabal-dev ()
  (should (equal '("Starting inferior cabal-dev process cabal-dev -s directory/cabal-dev ..." "dumses4" nil "cabal-dev" "ghci" "-s" "directory/cabal-dev")
                 (let ((haskell-process-path-cabal-dev "cabal-dev"))
                   (custom-set-variables '(haskell-process-wrapper-function #'identity))
                   (mocklet (((haskell-session-name "dummy-session4")      => "dumses4")
                             ((haskell-session-cabal-dir "dummy-session4") => "directory"))
                     (haskell-process-compute-process-log-and-command "dummy-session4" 'cabal-dev))))))

(ert-deftest test-haskell-process--with-wrapper-compute-process-log-and-command-cabal-dev ()
  (should (equal '("Starting inferior cabal-dev process cabal-dev -s directory/cabal-dev ..." "dumses4" nil "run-with-docker" "cabal-dev\\ ghci\\ -s\\ directory/cabal-dev")
                 (let ((haskell-process-path-cabal-dev "cabal-dev"))
                   (custom-set-variables '(haskell-process-wrapper-function
                                           (lambda (argv) (append (list "run-with-docker")
                                                             (list (shell-quote-argument (mapconcat 'identity argv " ")))))))
                   (mocklet (((haskell-session-name "dummy-session4") => "dumses4")
                             ((haskell-session-cabal-dir "dummy-session4") => "directory"))
                     (haskell-process-compute-process-log-and-command "dummy-session4" 'cabal-dev))))))

(ert-deftest test-haskell-process-make ()
  (should (equal '((name . hello))
                 (haskell-process-make 'hello)))
  (should (equal '((name . ok))
                 (haskell-process-make 'ok))))

(ert-deftest test-haskell-process-sentinel ()
  ;; no project for this process, nothing is done
  (should-not (mocklet (((haskell-process-project-by-proc 'proc) => nil))
                (haskell-process-sentinel 'proc 'event)))
  ;; a process for this session is currently restarting, nothing is done
  (should-not (mocklet (((haskell-process-project-by-proc 'proc) => 'session)
                        ((haskell-session-process 'session) => 'process)
                        ((haskell-process-restarting 'process) => 'restarting))
                (haskell-process-sentinel 'proc 'event)))
  ;; no process for the current session, we start one
  (should (equal 'hook-ran
                 (mocklet (((haskell-process-project-by-proc 'proc) => 'session)
                           ((haskell-session-process 'session) => 'process)
                           ((haskell-process-restarting 'process) => nil)
                           ((haskell-process-log *) => nil)
                           ((run-hook-with-args 'haskell-process-ended-hook 'process) => 'hook-ran))
                   (haskell-process-sentinel 'proc 'event)))))

(ert-deftest test-haskell-process-project-by-proc ()
  ;; no session so nothing is found
  (should-not (let ((haskell-sessions))
                (haskell-process-project-by-proc "proc-to-find")))
  ;; no session matching so nothing is found
  (should-not (let ((haskell-sessions (list "prj1" "prj2")))
                (mocklet (((haskell-session-name *)      => "prj1-session-name" :times 2)
                          ((process-name "proc-to-find") => "prj2-session-name"))
                  (haskell-process-project-by-proc "proc-to-find"))))
  ;; session found
  (should (equal "prj1"
                 (let ((haskell-sessions (list "prj1" "prj2" "prj3")))
                   (mocklet (((haskell-session-name *)      => "prj2-session-name" :times 1)
                             ((process-name "proc-to-find") => "prj2-session-name"))
                            (haskell-process-project-by-proc "proc-to-find"))))))

(ert-deftest test-haskell-process-filter ()
  ;; no session found, nothing to do
  (should-not (mocklet (((haskell-process--propertize-response 'response) => nil)
                        ((haskell-process-project-by-proc 'proc) => nil))
                (haskell-process-filter 'proc 'response)))
  ;; session found but no current command is found on session, so just log a message
  (should (equal 'result
                 (mocklet (((haskell-process--propertize-response "response") => nil)
                           ((haskell-process-project-by-proc 'proc) => 'session)
                           ((haskell-session-process 'session) => 'session-process)
                           ((haskell-process-cmd 'session-process) => nil)
                           ((haskell-process-log *) => 'result))
                   (haskell-process-filter 'proc "response"))))
  ;; session found, a current command is found, we collect and return
  (should (equal 'result
                 (mocklet (((haskell-process--propertize-response "response")              => nil)
                           ((haskell-process-project-by-proc 'proc)                        => 'session)
                           ((haskell-session-process 'session)                             => 'session-process)
                           ((haskell-process-cmd 'session-process)                         => 'current-cmd)
                           ((haskell-process-collect 'session "response" 'session-process) => 'result))
                   (haskell-process-filter 'proc "response")))))

(ert-deftest test-haskell-process-log ()
  (should (string= ""
                   (let ((haskell-process-log nil)
                         (buf                 (get-buffer-create "*haskell-process-log*")))
                     ;; before make sure the buffer if it exists is emptied
                     (with-current-buffer buf
                       (erase-buffer)
                       ;; log
                       (haskell-process-log "This is a message to log in the haskell process log buffer.")
                       ;; and retrieve its content
                       (buffer-string)))))
  (should (string= "This is a message to log in the haskell process log buffer.\n"
                   (let ((haskell-process-log 'with-log)
                         (buf                  (get-buffer-create "*haskell-process-log*")))
                     ;; before make sure the buffer if it exists is emptied
                     (with-current-buffer buf
                       (erase-buffer)
                       ;; log
                       (haskell-process-log "This is a message to log in the haskell process log buffer.")
                       ;; and retrieve its content
                       (buffer-string))))))
;;; haskell-process-tests.el ends here
