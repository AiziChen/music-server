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
             (platform . ,*android-platform*)
             (tag . ,*tag*)
             (iscorrection . "1")
             (privilegefilter . "0")
             (appid . ,*appid*)
             (area_code . "1")
             (clienttime . ,(current-kgstyle-time))
             (dopicfull . "1")
             (mid . ,*mid*)
             (dfid . ,*dfid*)
             (uuid . ,*uuid*))])
      (cons
       `(signature . ,(get-signature tmp))
       tmp)))
  (define res
    (response-json
     (get "https://gateway.kugou.com/v2/search/song"
          #:params params
          #:headers (request-headers))))
  (if (= (hash-ref res 'status -1) 1)
      (let ([data (hash-ref res 'data)])
        (hasheq 'status 1 'total (hash-ref data 'total)
                'list
                (for/list ([item (hash-ref (hash-ref res 'data) 'lists)])
                  (hash-filter item
                               (lambda (k _)
                                 (set-member? *music-result-filter* k))))))
      (hasheq 'status -1 'msg "internal error, please try again")))


(define *song-result-filter*
  (list->set '(bitRate extName fileSize timeLength url)))
(define/contract (get-song album-id
                           album-audio-id
                           hash
                           key
                           [vip-type "0"]
                           [cmd "26"]
                           [behavior "play"])
  (->* (string? string? non-empty-string? non-empty-string?)
       (non-empty-string? non-empty-string? non-empty-string?)
       hash?)
  (define params
    `((album_id . ,album-id)
      (userid . ,*userid*)
      (area_code . "1")
      (hash . ,hash)
      (module . "")
      (appid . ,*appid*)
      (version . ,*clientver*)
      (vipType . ,vip-type)
      (ptype . "0")
      (token . ,*token*)
      (mtype . "1")
      (album_audio_id . ,album-audio-id)
      (behavior . ,behavior)
      (pid . "2")
      (cmd . ,cmd)
      (mid . ,*mid*)
      (dfid . ,*dfid*)
      (pidversion . ,*pidversion*)
      (key . ,key)
      (with_res_tag . "0")))
  (define res
    (response-json
     (get "https://gateway.kugou.com/i/v2/"
          #:params params
          #:headers (request-headers "tracker.kugou.com" "Android9-AndroidPhone-10259-47-0-NetMusic-wifi"))))
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
  (define keyword "蒋雪璇")
  (let ([data (music-search keyword 1)])
    (when (= (hash-ref data 'status -1) 1)
      (define song-list (hash-ref data 'list))
      (define 1st-song (car song-list))
      (define album-id (hash-ref 1st-song 'AlbumID))
      (define album-audio-id (hash-ref 1st-song 'ID))
      (define duration (hash-ref 1st-song 'Duration))
      (define nq-hash (string-downcase (hash-ref 1st-song 'FileHash)))
      (define hq-hash (string-downcase (hash-ref 1st-song 'HQFileHash)))
      (define sq-hash (string-downcase (hash-ref 1st-song 'SQFileHash)))
      (define key
        (bytes->string/locale
         (md5 (string-append sq-hash
                             *pidversion-secrect*
                             *appid*
                             *mid*
                             *userid*))))

      ;; get song
      (get-song album-id album-audio-id sq-hash key)

      ;; get cover
      (get-cover album-id sq-hash)

      ;; get lyric
      (define candidates (search-lyric keyword sq-hash duration album-audio-id))
      (when (> (length candidates) 0)
        (let* ([candidate (car candidates)]
               [id (hash-ref candidate 'id)]
               [access-key (hash-ref candidate 'accesskey)])
          (printf "~a, ~a~n" id access-key)
          (get-lyric id access-key))))))
