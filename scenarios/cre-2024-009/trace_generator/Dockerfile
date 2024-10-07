ARG BUILD_IMAGE=513710883148.dkr.ecr.us-east-2.amazonaws.com/prequel-builder:0.0.8@sha256:56626b98feede633b8683655a363e51785946583d190b1074813a0dac603b476
ARG GO_OCI_BASE_LIBC=gcr.io/distroless/base-nossl@sha256:73c3d3f3030516665c916ebc9baa80f89c1a90e438dc02f1fed525ed246c0c2a
ARG GO_OCI_BASE_STATIC=gcr.io/distroless/static@sha256:41972110a1c1a5c0b6adb283e8aa092c43c31f7c5d79b8656fbffff2c3e61f05

FROM $BUILD_IMAGE AS generator-builder

COPY . .

RUN \
    --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=ssh \
    env go build -buildmode=pie -trimpath -o ./bin/generator generator.go

########
# Build the collector binary and copy to the host machine

FROM scratch AS binary
COPY --from=generator-builder /go/src/bin/generator ./

FROM $GO_OCI_BASE_LIBC AS generator-image

USER nonroot:nonroot

COPY ./bin/generator /app/generator

ENTRYPOINT ["/app/generator"]
