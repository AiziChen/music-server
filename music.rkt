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
             (api:music-search keyword page)))))
  (response/json
   (if resp resp (hasheq 'status -1 'msg "incorrect arguments"))))


(define (get-song req)
  (define resp
    (let* ([jsexp (bytes->jsexpr (request-post-data/raw req))]
           [album-id (hash-ref jsexp 'album-id #f)]
           [album-audio-id (hash-ref jsexp 'id #f)]
           [hash (hash-ref jsexp 'hash #f)])
      (and album-id album-audio-id hash
           (with-handlers ([exn? (lambda (_)
                                   (hasheq 'status -1
                                           'msg "server internal error"))])
             (let ([key (generate-key hash)])
               (api:get-song album-id album-audio-id hash key))))))
  (response/json
   (if resp resp (hasheq 'status -1 'msg "incorrect arguments"))))


(define (get-lyric req)
  (define resp
    (let* ([jsexp (bytes->jsexpr (request-post-data/raw req))]
           [keyword (hash-ref jsexp 'keyword #f)]
           [album-audio-id (hash-ref jsexp 'id #f)]
           [duration (hash-ref jsexp 'duration #f)]
           [hash (hash-ref jsexp 'hash #f)])
      (and keyword album-audio-id duration hash
           (with-handlers ([exn? (lambda (_)
                                   (hasheq 'status -1
                                           'msg "server internal error"))])
             (let ()
               (define lrcs (api:search-lyric keyword hash duration album-audio-id))
               (define 1st-lrc (car lrcs))
               (api:get-lyric (hash-ref 1st-lrc 'id "") (hash-ref 1st-lrc 'accesskey "")))))))
  (response/json
   (if resp resp (hasheq 'status -1 'msg "incorrect arguments"))))


(define (get-cover req)
  (define resp
    (let* ([jsexp (bytes->jsexpr (request-post-data/raw req))]
           [album-audio-id (hash-ref jsexp 'id #f)]
           [hash (hash-ref jsexp 'hash #f)])
      (and album-audio-id hash
           (with-handlers ([exn? (lambda (_)
                                   (hasheq 'status -1
                                           'msg "server internal error"))])
             (api:get-cover album-audio-id hash)))))
  (response/json
   (if resp resp (hasheq 'status -1 'msg "incorrect arguments"))))
