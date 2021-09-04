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

(require koyo/json
         json
         web-server/http/request-structs
         racket/string
         (prefix-in api: "api/music-api.rkt")
         (prefix-in api: "api/lyric-api.rkt")
         (prefix-in api: "api/cover-api.rkt")
         "api/tools.rkt")

(provide
 search
 get-song
 get-lyric
 get-cover)

(define (search req)
  (define resp
    (let* ([jsexp (bytes->jsexpr (request-post-data/raw req))]
           [keyword (hash-ref jsexp 'keyword #f)]
           [page (hash-ref jsexp 'page #f)])
      (and keyword page
           (with-handlers ([exn? (lambda (_)
                                   (hasheq 'status -1
                                           'msg "server internal error"))])
             (api:music-search (string-replace keyword " " "") page)))))
  (response/json
   (if resp resp (hasheq 'status -1 'msg "incorrect arguments"))))


(define (get-song req)
  (define resp
    (let* ([jsexp (bytes->jsexpr (request-post-data/raw req))]
           [album-id (hash-ref jsexp 'album-id #f)]
           [hash (hash-ref jsexp 'hash #f)])
      (and album-id hash
           (with-handlers ([exn? (lambda (_)
                                   (hasheq 'status -1
                                           'msg "server internal error"))])
             (let ([key (generate-key hash)])
               (api:get-song album-id hash key))))))
  (response/json
   (if resp resp (hasheq 'status -1 'msg "incorrect arguments"))))


(define (get-lyric req)
  (define resp
    (let* ([jsexp (bytes->jsexpr (request-post-data/raw req))]
           [keyword (hash-ref jsexp 'keyword #f)]
           [duration (hash-ref jsexp 'duration #f)]
           [hash (hash-ref jsexp 'hash #f)])
      (and keyword duration hash
           (with-handlers ([exn? (lambda (_)
                                   (hasheq 'status -1
                                           'msg "server internal error"))])
             (let ()
               (define lrcs (api:search-lyric (string-replace keyword " " "") hash duration))
               (define 1st-lrc (car lrcs))
               (api:get-lyric (hash-ref 1st-lrc 'id "") (hash-ref 1st-lrc 'accesskey "")))))))
  (response/json
   (if resp resp (hasheq 'status -1 'msg "incorrect arguments"))))


(define (get-cover req)
  (define resp
    (let* ([jsexp (bytes->jsexpr (request-post-data/raw req))]
           [hash (hash-ref jsexp 'hash #f)])
      (and hash
           (with-handlers ([exn? (lambda (_)
                                   (hasheq 'status -1
                                           'msg "server internal error"))])
             (api:get-cover hash)))))
  (response/json
   (if resp resp (hasheq 'status -1 'msg "incorrect arguments"))))
