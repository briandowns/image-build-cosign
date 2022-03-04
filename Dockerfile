ARG UBI_IMAGE=registry.access.redhat.com/ubi7/ubi-minimal:latest
ARG GO_IMAGE=rancher/hardened-build-base:v1.17.6b7
FROM ${UBI_IMAGE} as ubi
FROM ${GO_IMAGE} as builder

RUN set -x &&          \
    apk --no-cache add \
    file               \
    git                \
    make \
    ncurses

ARG SRC="github.com/sigstore/cosign"
ARG TAG="v1.6.0"
ARG ARCH="amd64"
RUN git clone --depth=1 https://${SRC}.git ${GOPATH}/src/${SRC}
WORKDIR ${GOPATH}/src/${SRC}
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
RUN mkdir bin                                                                   && \
    GOARCH=${ARCH} CGO_ENABLED=1                                                   \
    go build                                                                       \
        -gcflags=-trimpath=${GOPATH}/src                                           \
        -ldflags "-linkmode=external -extldflags \"-static -Wl,--fatal-warnings\"" \
        -o bin/cosign ./cmd/cosign

RUN go-assert-static.sh bin/cosign
RUN go-assert-boring.sh bin/cosign
	    
RUN install -s bin/* /usr/local/bin

FROM ubi
RUN microdnf update -y && \ 
    rm -rf /var/cache/yum
COPY --from=builder /usr/local/bin/ /usr/local/bin/
