# waver - Feature Flags for the Undecided

## Getting Started

Install the latest version of the command line tool using go get

```bash
go get -u github.com/halplatform/waver
```

### User Guide

If you are interesting in learning how to use the `waver` command line tool
please review the more detailed [User Guide](./docs/usage.md)

### Developer - Getting Started

This project is primarily written in [Go](https://golang.org/doc/install) and uses
a Makefile `make` in order to interact with the various build stages.

Prerequisites:
* [Docker](https://docs.docker.com/get-docker/)

```bash
# clone this repo
git clone github.com/halplatform/waver; cd waver
```

The below cheatsheet contains many useful commands

```bash
# display the Makefile primary targets
make help

# build a docker image as development build
PRODUCTION=false make docker-image

# build production docker image
make docker-image

# install the waver command line tool using development build
make install
```

## Release Testing

After modifying any code one should ensure the changes do not break existing features. In order to run the lint check and unit tests with the following command:

Run the linter, unit tests, benchmarks and builds locally

```bash
make precheckin
```

Checks that there are no stray or modified files in the workspace.

```bash
make release-precheck
```

Once the code is passing all the test and the code coverage is high one can build the final binaries.

```bash
make release
```

## Contributing

In the event you would like to update or tweak a sections of the documentation please feel free to fork this repo and submit a pull-request (PR). If you would like to make a larger change to the code please file and issue first and explain what you would like to achieve to ensure the change has a higher chance of being accepted. In all cases ensure you have signed the contributor license agreement (CLA) *BEFORE* making any changes to ensure there are no delays.
