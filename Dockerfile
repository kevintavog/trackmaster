# See https://github.com/marcusjwhelan/swiftDevOpsTester for 5.x & Vapor Dockerfile
FROM swift:5.0.1

COPY . /code

RUN cd /code && make docker-build && cp /code/.build/release/TrackMaster /TrackMaster && cd / && rm -Rf /code

EXPOSE 9999
ENTRYPOINT ["/TrackMaster"]
