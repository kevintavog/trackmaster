BUILD_ID:=$(shell date +%s)

build:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

release-build:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12" -c release

docker-build:
	swift build -c release

image:
	docker build  . -t docker.rangic:6000/trackmaster:${BUILD_ID}
