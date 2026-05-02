# HI-TECH C 3.09 host toolchain in a portable container.
#
# Build:  docker build -t hitech .
# Use:    docker run --rm -v "$PWD:/work" hitech zc hello.c
#         (output .com lands in $PWD)
#
# The image bundles all 18 host tools plus the vendored Z80 target
# runtime (runtime/include80 + runtime/lib80) under /opt/hitech.
# PATH, INCDIR80 and LIBDIR80 are pre-set so zc Just Works.

FROM ubuntu:24.04 AS build

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        build-essential \
        perl \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

# Mark the bind-mount safe for git so getVersion.pl can read history
# without complaining about the working tree owner inside the container.
RUN git config --global --add safe.directory /src \
    && make -C Linux

FROM ubuntu:24.04

# libc6 is already in the base image; no extra runtime deps are needed.
COPY --from=build /src/Linux/Install /opt/hitech/bin
COPY --from=build /src/runtime       /opt/hitech/runtime

ENV PATH="/opt/hitech/bin:${PATH}" \
    INCDIR80="/opt/hitech/runtime/include80" \
    LIBDIR80="/opt/hitech/runtime/lib80"

WORKDIR /work

# No ENTRYPOINT so any of the 18 tools (zc, cpp, p1, cgen, optim, zas,
# link, objtohex, …) can be invoked directly via `docker run … <tool>`.
CMD ["zc", "-h"]
