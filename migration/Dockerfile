FROM golang:1.22-bookworm

WORKDIR /tmp
RUN curl -OL https://www.sqlite.org/2024/sqlite-autoconf-3450300.tar.gz \
  && tar xvzf sqlite-autoconf-3450300.tar.gz \
  && cd sqlite-autoconf-3450300 \
  && ./configure \
  && make \
  && make install \
  && rm -r /tmp/*
RUN go install github.com/rubenv/sql-migrate/...@latest

WORKDIR /workspace
