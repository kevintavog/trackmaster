# From https://github.com/vapor/web-template/blob/master/web.Dockerfile
# Which seems based off of: https://github.com/apple/swift-docker/blob/master/5.0/ubuntu/18.04/slim/Dockerfile
FROM swift:5.0.2 AS builder

RUN apt-get -qq update && apt-get install -y \
  libssl-dev zlib1g-dev \
  && rm -r /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*so* /build/lib

RUN swift build -c release && \
    mv `swift build -c release --show-bin-path` /build/bin

FROM ubuntu:18.04

RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libatomic1 libicu60 libxml2 libcurl4 libz-dev libbsd0 tzdata \
  && rm -r /var/lib/apt/lists/*

COPY --from=builder /build/bin/TrackMaster /
COPY --from=builder /build/bin/Indexer /
COPY --from=builder /build/lib/* /usr/lib/
EXPOSE 8080
