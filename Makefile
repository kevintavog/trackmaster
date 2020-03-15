BUILD_ID:=$(shell date +%s)

build:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

test:
	swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

release-build:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12" -c release

image:
	docker build  . -t docker.rangic:6000/trackmaster:${BUILD_ID}

push:
	docker push docker.rangic:6000/trackmaster:${BUILD_ID}
