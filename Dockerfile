FROM debian:12-slim@sha256:d02c76d82364cedca16ba3ed6f9102406fa9fa8833076a609cabf14270f43dfc AS builder
WORKDIR /app/git
ARG TARGETPLATFORM
RUN apt-get update && \
    apt-get install --no-install-recommends -y git ca-certificates build-essential libboost-system-dev libboost-program-options-dev libboost-regex-dev libboost-filesystem-dev libsoapysdr-dev && \
    git clone --depth 1 --branch v9.0 https://github.com/flightaware/dump978.git /app/git && \
    make -j$(nproc) dump978-fa && \
    mv dump978-fa /usr/local/bin && \
    chmod +x /usr/local/bin/dump978-fa
# Since distroless doesn't have a shell, we have to queue up the supporting libraries to copy
# in the builder.  Put them in /libs and then copy all of /libs over in the final image.
WORKDIR /copylibs
RUN LIB_ARCH=$(case ${TARGETPLATFORM} in \
    "linux/amd64")   echo "x86_64-linux-gnu"  ;; \
    "linux/arm/v7")  echo "arm-linux-gnueabihf"   ;; \
    "linux/arm64")   echo "aarch64-linux-gnu" ;; \
    *)               echo ""        ;; esac) \
    && echo "LIB_ARCH=$LIB_ARCH" && \
    mkdir -p /copylibs/${LIB_ARCH} && \
    cp /lib/${LIB_ARCH}/libboost_program_options.so.1.74.0 /copylibs/${LIB_ARCH}/libboost_program_options.so.1.74.0 && \
    cp /lib/${LIB_ARCH}/libboost_regex.so.1.74.0 /copylibs/${LIB_ARCH}/libboost_regex.so.1.74.0 && \
    cp /lib/${LIB_ARCH}/libSoapySDR.so.0.8 /copylibs/${LIB_ARCH}/libSoapySDR.so.0.8 && \
    cp /lib/${LIB_ARCH}/libicui18n.so.72 /copylibs/${LIB_ARCH}/libicui18n.so.72 && \
    cp /lib/${LIB_ARCH}/libicuuc.so.72 /copylibs/${LIB_ARCH}/libicuuc.so.72 && \
    cp /lib/${LIB_ARCH}/libicudata.so.72 /copylibs/${LIB_ARCH}/libicudata.so.72

FROM gcr.io/distroless/cc-debian12:nonroot@sha256:548d3e91231ffc84c1543da0b63e4063defc1f9620aa969e7f5abfafeb35afbe
COPY --from=builder /usr/local/bin/dump978-fa /usr/local/bin/dump978-fa
COPY --from=builder /copylibs/* /lib/

# https://www.baeldung.com/ops/docker-cmd-override
ENTRYPOINT ["/usr/local/bin/dump978-fa"]
