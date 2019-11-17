FROM debian:10
RUN apt-get update -qq && apt-get install -y openssl

COPY lib.sh /usr/local/bin

COPY genca.sh /usr/local/bin
COPY gencert.sh /usr/local/bin
COPY genpkey.sh /usr/local/bin

RUN \
  chmod +x /usr/local/bin/lib.sh && \
  chmod +x /usr/local/bin/genca.sh && \
  chmod +x /usr/local/bin/gencert.sh && \
  chmod +x /usr/local/bin/genpkey.sh

ENTRYPOINT [ "/usr/local/bin/gencert.sh" ]
