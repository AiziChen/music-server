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

(provide
 request-headers)

(define (request-headers [x-router "complexsearch.kugou.com"]
                         [user-agent "Android9-AndroidPhone-10259-47-0-SearchSong-wifi"]
                         [host "gateway.kugou.com"])
  (hasheq 'Host host
          'user-agent user-agent
          'kg-rec "0"
          'accept-encoding "gzip, deflate"
          'kg-rc "1"
          'x-router x-router))
