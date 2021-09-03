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
         racket/contract
         racket/string
         "./tools.rkt"
         "./constants.rkt")

(provide
 get-cover)

(define/contract (get-cover album-audio-id hash)
  (-> non-empty-string? non-empty-string? (or/c non-empty-string? #f))
  (define params
    `((r . "play/getdata")
      (callback . "")
      (hash . ,hash)
      (dfid . ,*dfid*)
      (appid . "1014")
      (platid . "4")
      (mid . ,*mid*)
      (album_id . ,album-audio-id)
      (_ . ,(current-kgstyle-time))))
  (define res
    (response-json
     (get "https://wwwapi.kugou.com/yy/index.php"
          #:params params)))
  (if (= (hash-ref res 'status -1) 1)
      (hash-ref (hash-ref res 'data) 'img)
      #f))
