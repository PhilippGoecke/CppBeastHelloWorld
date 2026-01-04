FROM debian:trixie-slim as build-env

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
  # install dependencies
  && apt install -y --no-install-recommends --no-install-suggests curl tar bzip2 git ca-certificates \
  # install boost dependencies
  && apt install -y --no-install-recommends --no-install-suggests g++ gcc \
  # make image smaller
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives \
  && rm -rf /tmp/* /var/tmp/*

WORKDIR /tmp

RUN curl -L https://archives.boost.io/release/1.90.0/source/boost_1_90_0.tar.bz2 -o boost.tar.bz2 \
  && echo "49551aff3b22cbc5c5a9ed3dbc92f0e23ea50a0f7325b0d198b705e8ee3fc305 boost.tar.bz2" | sha256sum --strict --check - \
  && mkdir -p /usr/include/boost \
  && tar xfvj boost.tar.bz2 -C /usr/include/boost --strip-components=1 \
  && rm ./boost*

WORKDIR /usr/include/boost

RUN ls -lisah \
  && ./bootstrap.sh --prefix=/usr/local \
  && ./b2 install \
  && rm -rf /tmp/*

RUN curl https://raw.githubusercontent.com/boostorg/beast/develop/example/http/server/async/http_server_async.cpp -o http_server_async.cpp \
  && g++ http_server_async.cpp -o http-server-async \
  && install http-server-async /usr/local/bin/

FROM debian:trixie-slim as prod-env

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
  # install dependencies
  && apt install -y --no-install-recommends --no-install-suggests curl \
  # make image smaller
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives \
  && rm -rf /tmp/* /var/tmp/*

COPY --from=build-env /usr/local/bin/ /usr/local/bin/

RUN echo "Hello World!" > /srv/index.html

ARG USER=beast
RUN groupadd -r $USER \
  && useradd -r -g $USER $USER
USER $USER

CMD http-server-async 0.0.0.0 8080 /srv 1

HEALTHCHECK CMD curl -f "http://localhost:8080" || exit 1
