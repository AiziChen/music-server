# Music Server

a music api server base on Racket


`note: api test is in `api-test.http` file.`


## Use it

* download this repository
* download racket from https://download.racket-lang.org
* add missing constants in `api/constant.rkt.bak` file, then rename file name from `constants.rkt.bak` to `constants.rkt`
* install it and it's extras packages using:
```shell
raco pkg install music-server/
```
* enter this directory, then run it:
```shell
racket -t server.rkt
```


## server running test:
open you terminal, type these in:
```shell
curl 127.0.0.1:8787
```
if the server is on, it will result `"server is running."` on the terminal.


## Build it

```shell
# create binary file
raco exe server.rkt
# distribute it
raco distribute bin-dir server
```

