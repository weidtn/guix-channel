(use-modules
 (gnu packages)
 (gnu packages java)
 (gnu packages maven)
 (gnu packages readline)
 (guix packages)
 (guix download)
 (guix git-download)
 (guix build-system ant)
 (guix build-system clojure)
 (guix build-system copy)
 (ice-9 match)
 ((guix licenses) #:prefix license:))

(package
  (name "clojure-tools")
  (version "1.11.1.1113")
  (source
   (origin
     (method url-fetch)
     (uri (string-append "https://download.clojure.org/install/clojure-tools-"
                         version
                         ".tar.gz"))
     (sha256 (base32 "0xvr9nmk9q789vp32zmmzj4macv8v7y9ivnfd6lf7i8vxgg6hvgv"))
     ;; Remove AOT compiled JAR.  The other JAR only contains uncompiled
     ;; Clojure source code.
     (snippet
      `(delete-file ,(string-append "clojure-tools-" version ".jar")))))
  (build-system copy-build-system)
  (arguments
   `(#:install-plan
     '(("deps.edn" "lib/clojure/")
       ("example-deps.edn" "lib/clojure/")
       ("tools.edn" "lib/clojure/")
       ("exec.jar" "lib/clojure/libexec/")
       ("clojure" "bin/")
       ("clj" "bin/"))
     #:modules ((guix build copy-build-system)
                (guix build utils)
                (srfi srfi-1)
                (ice-9 match))
     #:phases
     (modify-phases %standard-phases
       (add-after 'unpack 'fix-paths
         (lambda* (#:key outputs #:allow-other-keys)
           (substitute* "clojure"
             (("PREFIX") (string-append (assoc-ref outputs "out") "/lib/clojure")))
           (substitute* "clj"
             (("BINDIR") (string-append (assoc-ref outputs "out") "/bin"))
             (("rlwrap") (which "rlwrap")))))
       (add-after 'fix-paths 'copy-tools-deps-alpha-jar
         (lambda* (#:key inputs outputs #:allow-other-keys)
           (substitute* "clojure"
             (("\\$install_dir/libexec/clojure-tools-\\$version\\.jar")
              (string-join
               (append-map (match-lambda
                             ((label . dir)
                              (find-files dir "\\.jar$")))
                           inputs)
               ":"))))))))
  (inputs (list rlwrap
                clojure
                clojure-tools-deps-alpha
                java-commons-logging-minimal))
  (home-page "https://clojure.org/releases/tools")
  (synopsis "CLI tools for the Clojure programming language")
  (description "The Clojure command line tools can be used to start a
Clojure repl, use Clojure and Java libraries, and start Clojure programs.")
  (license license:epl1.0))
