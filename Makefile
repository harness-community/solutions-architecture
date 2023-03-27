# Makefile
# Standard top-level shared Makefile switchboard to consolidate all common
# rules which will be used when testing or executing this repository.
#

# Auto-include a Makefile.local if it exists in this local directory
ifneq ("$(wildcard Makefile.local)", "")
	include Makefile.local
endif

ifeq ($(DOCKER_COMMAND),)
	DOCKER_COMMAND=docker
endif
ifeq ($(TERRAFORM_VERSION),)
	TERRAFORM_VERSION=latest
endif
ifeq ($(DOCKER_IMAGE),)
	DOCKER_IMAGE=hashicorp/terraform
endif
ifeq ($(DOCKER_ENV),)
	DOCKER_ENV:=
endif
ifeq ($(DOCKER_MOUNTS),)
	DOCKER_MOUNTS:=
endif
ifeq ($(PROJECT_DIR),)
	PROJECT_DIR:=${PWD}
endif
ifeq ($(TEMPLATE_DIR),)
	TEMPLATE_DIR:=tests/integration
endif
ifeq ($(RESOURCE),)
	RESOURCE:=
endif
WORKDIR=/project
DOCKER_RUN=${DOCKER_COMMAND} run --rm -it ${DOCKER_ENV} -v ${PROJECT_DIR}:/project ${DOCKER_MOUNTS} -w ${WORKDIR}/${TEMPLATE_DIR} $(ENTRYPOINT) ${DOCKER_IMAGE}:${TERRAFORM_VERSION}

.PHONY: debug
debug:
	$(eval ENTRYPOINT=--entrypoint sh)
	@(${DOCKER_RUN})

.PHONY: init
init:
	${DOCKER_RUN} init

.PHONY: plan
plan: fmt
	${DOCKER_RUN} plan

.PHONY: apply
apply:
	${DOCKER_RUN} apply -auto-approve

.PHONY: destroy
destroy:
	${DOCKER_RUN} destroy -auto-approve

.PHONY: refresh
refresh:
	${DOCKER_RUN} refresh ${RESOURCE}

.PHONY: output
output:
	${DOCKER_RUN} output ${RESOURCE}

.PHONY: fmt
fmt:
	${DOCKER_RUN} fmt -recursive ${WORKDIR}/${TEMPLATE_DIR}

.PHONY: fmt_all
fmt_all:
	${DOCKER_RUN} fmt -recursive ${WORKDIR}

.PHONY: testing_cleanup
testing_cleanup:
	@(rm -rf ${TEMPLATE_DIR}/.terraform)

.PHONY: cycle
cycle: destroy apply plan

.PHONY: teardown
teardown: destroy testing_cleanup

.PHONY: all
all: init plan apply destroy testing_cleanup

.PHONY: full_suite
full_suite:
	@(for version in `cat .terraform_versions`; do \
		echo "Running Full Suite tests for Terraform Version: $$version"; \
		make all TERRAFORM_VERSION=$$version; \
	done;)
