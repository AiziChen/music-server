;; MUSIC-SERVER
;; Copyright (C) 2021 Quanye Chen (quanyec@gmail.com)

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
#lang racket/base
(require file/md5
         net/uri-codec
         racket/contract
         racket/string
         "./constants.rkt")

(provide (all-defined-out))

(define (current-kgstyle-time)
  (number->string (round (/ (current-milliseconds) 1000))))

;;; GET SIGNATURE BY parameters
(define (get-signature plst)
  (-> (listof (cons/c symbol? (or/c false/c string?))) non-empty-string?)
  (define rlst
        (sort plst
              (lambda (v1 v2)
                (string<? (symbol->string (car v1)) (symbol->string (car v2))))))
  (bytes->string/locale
   (md5
    (string-append
     "OIlwieks28dk2k092lksi2UIkp"
     (string-replace (uri-decode (alist->form-urlencoded rlst)) "&" "")
     "OIlwieks28dk2k092lksi2UIkp"))))

;;; HASH FILTER
(define (hash-filter ht predicate)
  (for/fold ([filter-pairs (hash-clear ht)])
            ([(k v) (in-hash ht)])
    (if (predicate k v)
        (hash-set filter-pairs k v)
        filter-pairs)))

;;; generate key with music-file-hash
(define (generate-key hash)
  (bytes->string/locale
   (md5 (string-append hash
                       *pidversion-secrect*
                       *appid*
                       *mid*
                       *userid*))))
