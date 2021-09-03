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

(require koyo/dispatch
         koyo/url
         koyo/json
         koyo/cors
         web-server/web-server
         web-server/servlet-dispatch
         (prefix-in sequencer: web-server/dispatchers/dispatch-sequencer)
         racket/list
         "music.rkt")

(define-values (dispatch url roles)
  (dispatch-rules+roles
   [("") (lambda (_) (response/json "server is running."))]
   [("api" "music" "search") #:method "post" search]
   [("api" "music" "get-song") #:method "post" get-song]
   [("api" "music" "get-lyric") #:method "post" get-lyric]
   [("api" "music" "get-cover") #:method "post" get-cover]))


(current-cors-origin "*")

(define (stack handler)
  (wrap-cors handler))

(define dispatchers
  (list
   (dispatch/servlet (stack dispatch))))

(define stop
  (serve
   #:dispatch (apply sequencer:make (filter-map values dispatchers))
   #:listen-ip #f
   #:port 8787))

(with-handlers
  ([exn:break? (lambda (_) (stop))])
  (sync/enable-break never-evt))

