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
         racket/string
         racket/port
         racket/contract
         racket/math
         racket/set
         "./constants.rkt"
         "./request.rkt"
         "./tools.rkt")

(provide
 music-search
 get-song)

(define *music-result-filter*
  (list->set
   '(AlbumID ID Duration FileHash SQFileHash HQFileHash
             SingerName SongName ExtName AlbumName)))

(define/contract (music-search keyword page)
  (-> non-empty-string? positive-integer? hash?)
  (define params
    (let ([tmp
           `((keyword . ,keyword)
             (page . ,(number->string page))
             (pagesize . "30")
             (userid . ,*userid*)
             (clientver . ,*clientver*)
             (platform . ,*web-platform*)
             (iscorrection . "7")
             (area_code . "1")
             (tag . ,*tag*))])
      (cons
       `(signature . ,(get-signature tmp))
       tmp)))
  (define res
    (response-json
     (get "http://songsearchretry.kugou.com/song_search_v2"
          #:params params
          #:headers (request-headers))))

  (if (= (hash-ref res 'status -1) 1)
      (let ([data (hash-ref res 'data)])
        (hasheq 'status 1 'total (hash-ref data 'total)
                'list
                (for/list ([item (hash-ref (hash-ref res 'data) 'lists)])
                  (hash-set
                   (hash-set
                    (hash-filter item
                                 (lambda (k _)
                                   (set-member? *music-result-filter* k)))
                    'SingerName (hash-ref item 'SingerName))
                   'SongName (hash-ref item 'SongName)))))
      (hasheq 'status -1 'msg "internal error, please try again")))


(define *song-result-filter*
  (list->set '(bitRate extName fileSize timeLength url)))
(define/contract (get-song album-id
                           hash
                           key
                           [vip-type "0"]
                           [cmd "26"]
                           [behavior "play"])
  (->* (string? non-empty-string? non-empty-string?)
       (non-empty-string? non-empty-string? non-empty-string?)
       hash?)
  (define params
    `((album_id . ,album-id)
      (userid . ,*userid*)
      (authType . "1")
      (hash . ,hash)
      (module . "")
      (appid . ,*appid*)
      (version . ,*clientver*)
      (vipType . ,vip-type)
      (token . ,*token*)
      (behavior . ,behavior)
      (pid . "4")
      (cmd . ,cmd)
      (mid . ,*mid*)
      (key . ,key)))
  (define res
    (response-json
     (get "http://trackercdn.kugou.com/i/v2/"
          #:params params
          #:headers (request-headers "trackercdn.kugou.com"
                                     "%E9%85%B7%E7%8B%97%E9%9F%B3%E4%B9%90/1104 CFNetwork/1240.0.4 Darwin/20.6.0"
                                     "trackercdn.kugou.com"))))
  (displayln res)
  (if (= (hash-ref res 'status -1) 1)
      (hash-filter res
                   (lambda (k _)
                     (set-member? *song-result-filter* k)))
      (hasheq 'status -1 'msg "internal error, please try again")))


(module+ test
  (require rackunit
           file/md5
           "./lyric-api.rkt"
           "./cover-api.rkt")
  (define keyword "热爱")
  (let ([data (music-search keyword 1)])
    (when (= (hash-ref data 'status -1) 1)
      (define song-list (hash-ref data 'list))
      (define 1st-song (car song-list))
      (define album-id (hash-ref 1st-song 'AlbumID))
      (define album-audio-id (hash-ref 1st-song 'ID))
      (define duration (hash-ref 1st-song 'Duration))
      (define nq-hash (hash-ref 1st-song 'FileHash))
      (define hq-hash (hash-ref 1st-song 'HQFileHash))
      (define sq-hash (hash-ref 1st-song 'SQFileHash))
      (define key
        (bytes->string/locale
         (md5 (string-append hq-hash
                             "kgcloudv2"
                             *appid*
                             *mid*
                             *userid*))))

      ;; get song
      (get-song album-id hq-hash key)

      ;; get cover
      (get-cover sq-hash)

      ;; get lyric
      (define candidates (search-lyric keyword sq-hash duration))
      (when (> (length candidates) 0)
        (let* ([candidate (car candidates)]
               [id (hash-ref candidate 'id)]
               [access-key (hash-ref candidate 'accesskey)])
          (printf "~a, ~a~n" id access-key)
          (get-lyric id access-key))))))
