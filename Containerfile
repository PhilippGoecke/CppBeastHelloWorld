FROM debian:bookworm-slim as build-env

RUN DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y \
  # install dependencies
  && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends wget curl tar bzip2 git ca-certificates \
  # install boost dependencies
  && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends g++ gcc \
  # make image smaller
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives \
  && rm -rf /tmp/* /var/tmp/*

WORKDIR /tmp

RUN wget https://boostorg.jfrog.io/artifactory/main/release/1.85.0/source/boost_1_85_0.tar.bz2 \
  && echo "7009fe1faa1697476bdc7027703a2badb84e849b7b0baad5086b087b971f8617	boost_1_85_0.tar.bz2" > boost.sha256 \
  && sha256sum -c boost.sha256 \
  && mkdir -p /usr/include/boost \
  && tar xfvj boost_1_85_0.tar.bz2 -C /usr/include/boost --strip-components=1 \
  && rm ./boost*

WORKDIR /usr/include/boost

RUN ls -lisah \
  && ./bootstrap.sh --prefix=/usr/local \
  && ./b2 install \
  && rm -rf /tmp/*

RUN wget https://raw.githubusercontent.com/boostorg/beast/develop/example/http/server/async/http_server_async.cpp \
  && g++ http_server_async.cpp -o http-server-async \
  && install http-server-async /usr/local/bin/

USER user

RUN echo "Hello World" > /srv/index.html

CMD http-server-async 0.0.0.0 8080 /srv 1

HEALTHCHECK CMD curl -f "http://localhost:8080" || exit 1
