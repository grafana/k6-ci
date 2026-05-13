MAKEFLAGS += --silent
GOLANGCI_CONFIG ?= .golangci.yml

all: clean lint test build

## help: Prints a list of available build targets.
help:
	echo "Usage: make <OPTIONS> ... <TARGETS>"
	echo ""
	echo "Available targets are:"
	echo ''
	sed -n 's/^##//p' ${PWD}/Makefile | column -t -s ':' | sed -e 's/^/ /'
	echo
	echo "Targets run by default are: `sed -n 's/^all: //p' ./Makefile | sed -e 's/ /, /g' | sed -e 's/\(.*\), /\1, and /'`"


## build: Builds a custom 'k6' with the local extension.
build:
	xk6 build --with $(shell go list -m)=.

## check-linter-version: Warns if the installed golangci-lint differs from the version pinned on line 1 of $(GOLANGCI_CONFIG).
check-linter-version:
	(golangci-lint version | grep "version $(shell head -n 1 $(GOLANGCI_CONFIG) | tr -d '\# ')") || echo "Your installation of golangci-lint differs from the one pinned in $(GOLANGCI_CONFIG) ($(shell head -n 1 $(GOLANGCI_CONFIG) | tr -d '\# ')). CI results may differ."

## test: Executes any tests.
test:
	echo "Running tests..."
	go test -race -timeout 30s ./...

## lint: Runs the linters.
lint: check-linter-version
	echo "Running linters..."
	golangci-lint run ./...

## check: Runs the linters and tests.
check: lint test

## clean: Removes any previously created artifacts/downloads.
clean:
	echo "Cleaning up..."
	rm -f ./k6

.PHONY: test clean help lint check build
