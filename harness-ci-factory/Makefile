# Makefile
# Standard top-level shared Makefile switchboard to consolidate all common
# rules which will be used when testing or executing this repository.
#

PROJECT_DIR=${PWD}/../
TEMPLATE_DIR=$(notdir $(shell pwd))

# Auto-include the repository root Makefile to access shared resources
ifneq ("$(wildcard ../Makefile)", "")
	include ../Makefile
endif
ifneq ("$(wildcard ../Makefile.local)", "")
	include ../Makefile.local
endif
ifneq ("$(wildcard Makefile.local)", "")
	include Makefile.local
endif
