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

(require net/http-easy
         net/base64
         racket/contract
         racket/string
         racket/math
         "./constants.rkt"
         "./tools.rkt"
         "./request.rkt")

(provide
 search-lyric
 get-lyric)

(define/contract (search-lyric keyword hash duration)
  (-> non-empty-string? non-empty-string? integer?
      (listof hash?))
  (define params
    (let ([tmp
           `((keyword . ,keyword)
             (userid . ,*userid*)
             (ver . "1")
             (duration . ,(number->string duration))
             (lrctxt . "1")
             (client . "mobi")
             (clientver . ,*clientver*)
             (man . "no")
             (appid . ,*appid*)
             (clienttime . ,(current-kgstyle-time))
             (hash . ,hash)
             (mid . ,*mid*)
             (dfid . ,*dfid*)
             (uuid . ,*uuid*))])
      (cons
       `(signature . ,(get-signature tmp))
       tmp)))
  (define res
    (response-json
     (get "https://gateway.kugou.com/v1/search"
          #:params params
          #:headers (request-headers "krcs.kugou.com" "Android9-AndroidPhone-10259-47-0-Lyric-wifi"))))
  (if (equal? (hash-ref res 'info #f) "OK")
      (hash-ref res 'candidates)
      '()))


(define/contract (get-lyric id access-key)
  (-> non-empty-string? non-empty-string? string?)
  (define params
    `((ver . "1")
      (client . "mobi")
      (fmt . "lrc")
      (charset . "utf8")
      (id . ,id)
      (accesskey . ,access-key)))
  (define res
    (response-json
     (get "http://lyrics.kugou.com/download"
          #:params params
          #:headers (request-headers
                     "lyrics.kugou.com"
                     "Android9-AndroidPhone-10259-47-0-Lyric-wifi"
                     "lyrics.kugou.com"))))
  (if (equal? (hash-ref res 'info #f) "OK")
      (bytes->string/utf-8
       (base64-decode
        (string->bytes/locale (hash-ref res 'content))))
      ""))
