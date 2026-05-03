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
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Pin to the current main; bump deliberately when upstream releases.
RUN git clone --depth=1 https://github.com/MockbaTheBorg/RunCPM /src
RUN cd /src/RunCPM && make -f Makefile.posix

# Extract the upstream master CP/M disk so EXIT.COM (which calls
# the RunCPM-specific BDOS extension that halts the emulator) is
# present on drive A:. Without this, RunCPM doesn't exit on stdin
# EOF and we'd have to rely on a SIGALRM watchdog to stop the
# process — non-zero exit and 10-second wait on every successful
# run.
RUN mkdir -p /tmp/disk \
    && unzip -q /src/DISK/A0.ZIP -d /tmp/disk

FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /src/RunCPM/RunCPM /opt/runcpm/RunCPM
COPY --from=build /tmp/disk/A /opt/runcpm/A
COPY runcpm-run /opt/runcpm/runcpm-run

RUN chmod +x /opt/runcpm/runcpm-run

WORKDIR /opt/runcpm

# Default entrypoint: takes a path to a .com file (mounted from host),
# loads it onto drive A:, runs it under RunCPM, prints output, exits.
ENTRYPOINT ["/opt/runcpm/runcpm-run"]
