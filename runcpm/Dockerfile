# RunCPM v6.x in a portable container.
#
# Build:  docker build -t runcpm runcpm/
# Use:    docker run --rm -v "$PWD:/work" runcpm /work/hello.com
#         (loads hello.com onto drive A:, executes it, prints output)
#
# RunCPM is Marcelo Dantas' Z80 / CP/M emulator from
# https://github.com/MockbaTheBorg/RunCPM. The image bundles its
# internal CCP (no external CCP-XX.6XK files needed). Useful as a
# lightweight runner for HI-TECH C cross-compiled .com binaries.

FROM ubuntu:24.04 AS build

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*

# Pin to the current main; bump deliberately when upstream releases.
RUN git clone --depth=1 https://github.com/MockbaTheBorg/RunCPM /src
RUN cd /src/RunCPM && make -f Makefile.posix

FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        perl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /src/RunCPM/RunCPM /opt/runcpm/RunCPM
COPY runcpm-run /opt/runcpm/runcpm-run

RUN mkdir -p /opt/runcpm/A/0 \
    && chmod +x /opt/runcpm/runcpm-run

WORKDIR /opt/runcpm

# Default entrypoint: takes a path to a .com file (mounted from host),
# loads it onto drive A:, runs it under RunCPM, prints output, exits.
ENTRYPOINT ["/opt/runcpm/runcpm-run"]
