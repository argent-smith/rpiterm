FROM argentoff/ocaml-workbench:arm32v7-en-0.0.3

MAINTAINER Pavel Argentov (argentoff@gmail.com)

RUN opam switch 4.05.0

RUN eval `opam config env`

RUN opam update

RUN opam upgrade -y

RUN opam pin add core_kernel "https://github.com/argent-smith/core_kernel.git#v0.9.1-ag"

RUN opam install core utop

RUN opam install uri.1.9.2

RUN opam install prometheus prometheus-app
