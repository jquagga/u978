FROM debian:12-slim@sha256:155280b00ee0133250f7159b567a07d7cd03b1645714c3a7458b2287b0ca83cb AS builder
WORKDIR /app/git
ARG TARGETPLATFORM
RUN apt-get update && \
    apt-get install --no-install-recommends -y git ca-certificates build-essential libboost-system1.74-dev libboost-program-options1.74-dev \ 
    libboost-regex1.74-dev libboost-filesystem1.74-dev libsoapysdr-dev apt-rdepends && \
    git clone --depth 1 --branch v9.0 https://github.com/flightaware/dump978.git /app/git && \
    make -j$(nproc) dump978-fa && \
    mv dump978-fa /usr/local/bin && \
    chmod +x /usr/local/bin/dump978-fa

# This uses apt-rdepends to download the dependencies for dump978, removes the libc/gcc ones provided by distroless
# and put it all in the /newroot directory to be copied over to the stage 2 image
WORKDIR /dpkg
RUN apt-get download --no-install-recommends $(apt-rdepends soapysdr-module-rtlsdr libboost-system1.74.0 libboost-regex1.74.0 \
    libboost-filesystem1.74.0 libboost-system1.74.0 libboost-program-options1.74.0 |grep -v "^ ") && \
    rm libc* libgcc* gcc* 
WORKDIR /newroot
RUN dpkg --unpack -R --force-all --root=/newroot /dpkg/

FROM gcr.io/distroless/cc-debian12:nonroot@sha256:b9452f5cd004c1610d4056be70343a8a7ea3d46bcf0fda3ce90f1ed90e70989c
COPY --from=builder /newroot /
COPY --from=builder /usr/local/bin/dump978-fa /usr/local/bin/dump978-fa

# https://www.baeldung.com/ops/docker-cmd-override
ENTRYPOINT ["/usr/local/bin/dump978-fa"]
#ENTRYPOINT ["/bin/bash"]
