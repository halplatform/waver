#
# waver - Feature Flags for the Undecided
#
BINARY         = waver
PACKAGE        = github.com/halplatform/waver
DOCKER_IMAGE   ?= ghcr.io/halplatform/$(BINARY):$(DOCKER_TAG)
DOCKER_PREFIX  ?= ghcr.io/halplatform/
DOCKER_TAG     ?= latest
DOCKER_PUSH    ?= false
PRODUCTION     ?= true
DEVEL_ENV      = DEBUG=true
DATE           = $(shell date "+%Y-%m-%d")
GIT_BRANCH     = $(shell git rev-parse --abbrev-ref 2>/dev/null)
GIT_COMMIT     = $(shell git rev-parse HEAD 2>/dev/null)
GIT_TAG        = $(shell if [ -z "`git status --porcelain`" ]; then git describe --exact-match --tags HEAD 2>/dev/null; fi)
GIT_TREE_STATE = $(shell if [ -z "`git status --porcelain`" ]; then echo "clean" ; else echo "dirty"; fi)
VERSIONREL     = $(shell if [ -z "`git status --porcelain`" ]; then echo "" ; else echo "-dirty"; fi)
PKGS           = $(shell go list ./... | grep -v /vendor)
LDFLAGS        = -X $(PACKAGE)/cmd/version.Version="dev$(VERSIONREL)" -X $(PACKAGE)/cmd/version.commit="$(GIT_COMMIT)" -X $(PACKAGE)/cmd/version.Date="$(DATE)"
GOIMAGE        = golang:1.15.6
CACHE_VOLUME   = $(BINARY)-build-cache
GOBUILD_ARGS   = -i
GORELEASER_VER = v0.149.0
BIN_DIR        = $(GOPATH)/bin
GOLANGCI-LINT  = $(BIN_DIR)/golangci-lint
PLATFORMS      = windows linux darwin
os             = $(word 1, $@)

ifneq (${GIT_TAG},)
override DOCKER_TAG = ${GIT_TAG}
override LDFLAGS = -X $(PACKAGE)/cmd/version.Version=$(GIT_TAG) -X $(PACKAGE)/cmd/version.commit=$(GIT_COMMIT) -X $(PACKAGE)/cmd/version.Date=$(DATE)
endif

ifeq (${PRODUCTION}, true)
LDFLAGS += -w -s -extldflags "-static"
GOBUILD_ARGS += -v
endif

.PHONY: help
help:  ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: all
all: windows linux darwin precheckin release  ## Build binary with production settings.

.PHONY: lint
lint:  ## Lint the golang code to ensure code sanity.
	golangci-lint run

.PHONY: test
test:  ## Run the golang unit tests.
	@echo "INFO: Running all golang unit tests."
	go test $(PKGS)

.PHONY: coverage
coverage:  ## Report the unit test code coverage.
	@echo "INFO: Generating unit test coverage report."
	go test $(PKGS) -coverprofile=coverage.out
	go tool cover -func=coverage.out

.PHONY: bench
bench:  ## Run the golang benchmark tests.
	@echo "INFO: Running all golang benchmark tests, Skipping all unit tests."
	go test -run=XXX -bench=. $(PKGS)

.PHONY: run
run:  ## Run the development server.
	@echo "INFO: Starting the server locally."
	$(DEVEL_ENV) go run -ldflags '$(LDFLAGS)' main.go server --dev

.PHONY: install
install:
	go install

.PHONY: build
build: linux darwin windows  ## Build the multi-arch binaries

.PHONY: $(PLATFORMS)
$(PLATFORMS):
	mkdir -p release
	GOOS=$(os) GOARCH=amd64 go build $(GOBUILD_ARGS) -ldflags '$(LDFLAGS)' -o release/$(BINARY)-$(os)-amd64 .

.PHONY: arm
arm:
	mkdir -p release
	GOOS=linux GOARCH=arm GOARM=6 go build $(GOBUILD_ARGS) -ldflags '$(LDFLAGS)' -o release/$(BINARY)-linux-armv6 .
	GOOS=linux GOARCH=arm64 GOARM=8 go build $(GOBUILD_ARGS) -ldflags '$(LDFLAGS)' -o release/$(BINARY)-linux-arm64v8 .

.PHONY: docker-image
docker-image: linux  ## Build the docker image
ifeq ($(PRODUCTION), true)
	@echo "INFO: Build Production image inside clean docker container"
	docker build . --build-arg GOLANG_IMAGE=$(GOIMAGE) --build-arg BINARY_PATH=release/$(BINARY)-linux-amd64 -t $(DOCKER_PREFIX)$(BINARY):$(DOCKER_TAG) -t $(DOCKER_PREFIX)$(BINARY):$(GIT_COMMIT)
else
	@echo "INFO: Build Development image using local Go cache..."
	docker build . --build-arg GOLANG_IMAGE=$(GOIMAGE) --build-arg PRODUCTION=$(PRODUCTION) --build-arg BINARY_LOCATION=workspace --build-arg BINARY_PATH=release/$(BINARY)-linux-amd64 -t $(DOCKER_PREFIX)$(BINARY):$(DOCKER_TAG) -t $(DOCKER_PREFIX)$(BINARY):$(GIT_COMMIT)
endif
	@if [ "$(DOCKER_PUSH)" = "true" ] ; then docker push $(DOCKER_PREFIX)$(BINARY):$(DOCKER_TAG) ; fi

.PHONY: manifests
manifests:  ## Build kubernetes install.yaml file
	mkdir -p manifests
	kubectl create namespace waver --dry-run -o=yaml > manifests/install.yaml
	kubectl create deployment waver --image=$(DOCKER_IMAGE) --dry-run -o=yaml >> manifests/install.yaml
	# sed -i.bak "s@- .*/$(BINARY):.*@- $(DOCKER_PREFIX)$(BINARY):$(DOCKER_TAG)@" manifests/install.yaml

.PHONY: precheckin
precheckin: test bench lint build  ## Run all the tests and linters which must pass before checking in code

.PHONY: release-precheck
release-precheck:
	@if [ "$(GIT_TREE_STATE)" != "clean" ]; then echo 'ERROR: git tree state is $(GIT_TREE_STATE)' ; exit 1; fi
	@if [ -z "$(GIT_TAG)" ]; then echo 'ERROR: commit must be tagged to perform release' ; exit 1; fi

.PHONY: release
release: precheckin linux darwin windows docker-image release-precheck  ## Run goreleaser to publish binaries
	curl -sL https://git.io/goreleaser | VERSION=$(GORELEASER_VER) bash -s -- --parallelism=8 --rm-dist

# Tooling and Support Targets
$(GOLANGCI-LINT):
	@echo "INFO: Download golangci-lint binary"
	go get github.com/golangci/golangci-lint/cmd/golangci-lint@v1.33.0

.PHONY: clean
clean:
	rm -rf $(BINARY) dist/ release/ bin/ manifests/install.yaml
