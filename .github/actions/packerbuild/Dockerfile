FROM docker.mirror.hashicorp.services/alpine:latest

ENV PACKER_VERSION=1.10.3

RUN apk --no-cache upgrade \
  && apk add --no-cache \
  bash \
  curl \
  git \
  openssl \
  wget \
  xorriso

ADD https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip ./
ADD https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS ./

RUN sed -i '/.*linux_amd64.zip/!d' packer_${PACKER_VERSION}_SHA256SUMS \
  && sha256sum -c packer_${PACKER_VERSION}_SHA256SUMS \
  && unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /bin \
  && rm -f packer_${PACKER_VERSION}_linux_amd64.zip packer_${PACKER_VERSION}_SHA256SUMS

COPY build.sh /bin/build.sh
RUN chmod +x /bin/build.sh

ENTRYPOINT ["/bin/build.sh"]
