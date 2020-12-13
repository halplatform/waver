##############################################################################
# waver - docker build environment
##############################################################################

# Specify the golang docker image to use to build the binary within
ARG GOLANG_IMAGE=golang:1.15.0
# Specify which layer to read the release binary from
# This is used in development to override to pre-build images
ARG BINARY_LOCATION=builder


##############################################################################
# Base Target
##############################################################################
FROM $GOLANG_IMAGE as base

ENV container docker

WORKDIR /app

# Force the use of go modules
ENV GO111MODULE on

# Cache the go vendor files in the base image to speed up rebuilds
COPY go.mod go.sum ./
RUN go mod download


##############################################################################
# Image with Development Workspace
##############################################################################
FROM base as workspace

# Copy the workspace files into the images for testing and compilation
COPY . .


##############################################################################
# Builder Target
##############################################################################
FROM workspace as builder

# Controls the build flags of the go binary. Production images
# strip out the debug information and produce smaller binaries.
ARG PRODUCTION=true

# Ensure we diable cgo support
ENV CGO_ENABLED=0

# Build the production binary image
RUN PRODUCTION=${PRODUCTION} make linux


##############################################################################
# Packaging Alias Target
##############################################################################
FROM ${BINARY_LOCATION} as packager


##############################################################################
# Production Target
##############################################################################
FROM scratch as production

# the binary path is the relative location for the build target that should
# be the final entrypoint in the resulting docker image
ARG BINARY_PATH=

COPY --from=base /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt
COPY --from=packager /app/${BINARY_PATH} /app

ENTRYPOINT ["/app"]
CMD ["version"]
