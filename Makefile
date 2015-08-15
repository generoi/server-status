all: check

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

check:

install: check
	ln -s ${ROOT_DIR}/server-status.sh /usr/local/bin/server-status
