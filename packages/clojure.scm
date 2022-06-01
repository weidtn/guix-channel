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

(define-public clojure
  (let* ((lib (lambda (prefix version hash)
                (origin (method url-fetch)
                        (uri (string-append "https://github.com/clojure/"
                                            prefix version ".tar.gz"))
                        (sha256 (base32 hash)))))
         ;; The libraries below are needed to run the tests.
         (libraries
          `(("core-specs-alpha-src"
             ,(lib "core.specs.alpha/archive/core.specs.alpha-"
                   "0.1.24"
                   "0v2a0svf1ar2y42ajxwsjr7zmm5j7pp2zwrd2jh3k7xzd1p9x1fv"))
            ("data-generators-src"
             ,(lib "data.generators/archive/data.generators-"
                   "0.1.2"
                   "0kki093jp4ckwxzfnw8ylflrfqs8b1i1wi9iapmwcsy328dmgzp1"))
            ("spec-alpha-src"
             ,(lib "spec.alpha/archive/spec.alpha-"
                   "0.1.143"
                   "00alf0347licdn773w2jarpllyrbl52qz4d8mw61anjksacxylzz"))
            ("test-check-src"
             ,(lib "test.check/archive/test.check-"
                   "0.9.0"
                   "0p0mnyhr442bzkz0s4k5ra3i6l5lc7kp6ajaqkkyh4c2k5yck1md"))
            ("test-generative-src"
             ,(lib "test.generative/archive/test.generative-"
                   "0.5.2"
                   "1pjafy1i7yblc7ixmcpfq1lfbyf3jaljvkgrajn70sws9xs7a9f8"))
            ("tools-namespace-src"
             ,(lib "tools.namespace/archive/tools.namespace-"
                   "0.2.11"
                   "10baak8v0hnwz2hr33bavshm7y49mmn9zsyyms1dwjz45p5ymhy0"))))
         (library-names (match libraries
                          (((library-name _) ...)
                           library-name))))

    (package
      (name "clojure")
      (version "1.10.0")
      (source (let ((name+version (string-append name "-" version)))
                (origin
                  (method git-fetch)
                  (uri (git-reference
                        (url "https://github.com/clojure/clojure")
                        (commit name+version)))
                  (file-name (string-append name+version "-checkout"))
                  (sha256
                   (base32 "1kcyv2836acs27vi75hvf3r773ahv2nlh9b3j9xa9m9sdanz1h83")))))
      (build-system ant-build-system)
      (inputs
       `(("jre" ,icedtea)))
      (arguments
       `(#:imported-modules ((guix build clojure-utils)
                             (guix build guile-build-system)
                             ,@%ant-build-system-modules)
         #:modules ((guix build ant-build-system)
                    (guix build clojure-utils)
                    (guix build java-utils)
                    (guix build utils)
                    (srfi srfi-26))
         #:test-target "test"
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'unpack-library-sources
             (lambda* (#:key inputs #:allow-other-keys)
               (define (extract-library name)
                 (mkdir-p name)
                 (with-directory-excursion name
                   (invoke "tar"
                           "--extract"
                           "--verbose"
                           "--file" (assoc-ref inputs name)
                           "--strip-components=1"))
                 (copy-recursively (string-append name "/src/main/clojure/")
                                   "src/clj/"))
               (for-each extract-library ',library-names)
               #t))
           (add-after 'unpack-library-sources 'fix-manifest-classpath
             (lambda _
               (substitute* "build.xml"
                 (("<attribute name=\"Class-Path\" value=\".\"/>") ""))
               #t))
           (add-after 'build 'build-javadoc ant-build-javadoc)
           (replace 'install (install-jars "./"))
           (add-after 'install-license-files 'install-doc
             (cut install-doc #:doc-dirs '("doc/clojure/") <...>))
           (add-after 'install-doc 'install-javadoc
             (install-javadoc "target/javadoc/")))))
      (native-inputs libraries)
      (home-page "https://clojure.org/")
      (synopsis "Lisp dialect running on the JVM")
      (description "Clojure is a dynamic, general-purpose programming language,
combining the approachability and interactive development of a scripting
language with an efficient and robust infrastructure for multithreaded
programming.  Clojure is a compiled language, yet remains completely dynamic
– every feature supported by Clojure is supported at runtime.  Clojure
provides easy access to the Java frameworks, with optional type hints and type
inference, to ensure that calls to Java can avoid reflection.

Clojure is a dialect of Lisp, and shares with Lisp the code-as-data philosophy
and a powerful macro system.  Clojure is predominantly a functional programming
language, and features a rich set of immutable, persistent data structures.
When mutable state is needed, Clojure offers a software transactional memory
system and reactive Agent system that ensure clean, correct, multithreaded
designs.")
      ;; Clojure is licensed under EPL1.0
      ;; ASM bytecode manipulation library is licensed under BSD-3
      ;; Guava Murmur3 hash implementation is licensed under APL2.0
      ;; src/clj/repl.clj is licensed under CPL1.0

      ;; See readme.html or readme.txt for details.
      (license (list license:epl1.0
                     license:bsd-3
                     license:asl2.0
                     license:cpl1.0)))))

(package
  (name "clojure-tools")
  (version "1.10.3.1040")
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
