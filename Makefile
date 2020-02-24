# Copyright 2020 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Default goal
.DEFAULT_GOAL:=help

# This repo is build locally for dev/test by default;
# Override this variable in CI env.
BUILD_LOCALLY ?= 1

# The namespce that the operator will be deployed in
NAMESPACE=ibm-catalog-operator

# Image URL to use all building/pushing image targets;
# Use your own docker registry and image name for dev/test by overridding the IMG and REGISTRY environment variable.
IMG ?= ibm-catalog-operator
REGISTRY ?= quay.io/opencloudio
CSV_VERSION ?= 0.0.1

QUAY_USERNAME ?=
QUAY_PASSWORD ?=

# Github host to use for checking the source tree;
# Override this variable ue with your own value if you're working on forked repo.
GIT_HOST ?= github.com/IBM

BASE_DIR := ibm-catalog-operator

TESTARGS_DEFAULT := "-v"
export TESTARGS ?= $(TESTARGS_DEFAULT)
DEST := $(GIT_HOST)/$(BASE_DIR)
VERSION ?= $(shell git describe --exact-match 2> /dev/null || \
                 git describe --match=$(git rev-parse --short=8 HEAD) --always --dirty --abbrev=8)

LOCAL_OS := $(shell uname)
ifeq ($(LOCAL_OS),Linux)
    TARGET_OS ?= linux
    XARGS_FLAGS="-r"
else ifeq ($(LOCAL_OS),Darwin)
    TARGET_OS ?= darwin
    XARGS_FLAGS=
else
    $(error "This system's OS $(LOCAL_OS) isn't recognized/supported")
endif

ARCH := $(shell uname -m)
LOCAL_ARCH := "amd64"
ifeq ($(ARCH),x86_64)
    LOCAL_ARCH="amd64"
else ifeq ($(ARCH),ppc64le)
    LOCAL_ARCH="ppc64le"
else ifeq ($(ARCH),s390x)
    LOCAL_ARCH="s390x"
else
    $(error "This system's ARCH $(ARCH) isn't recognized/supported")
endif

all: check test build images


include commonUtil/Makefile.common.mk


############################################################
# check section
############################################################

check: lint ## Check all files lint error

# All available linters: lint-dockerfiles lint-scripts lint-yaml lint-copyright-banner lint-go lint-python lint-helm lint-markdown lint-sass lint-typescript lint-protos
# Default value will run all linters, override these make target with your requirements:
#    eg: lint: lint-go lint-yaml
lint: lint-all

############################################################
# test section
############################################################

test: test-e2e

test-e2e: ## Run integration e2e tests with different options
	@echo ... Running the same e2e tests with different args ...
	@echo ... Running locally ...
	- operator-sdk test local ./test/e2e --verbose --up-local --namespace=${NAMESPACE}
	# @echo ... Running with the param ...
	# - operator-sdk test local ./test/e2e --namespace=${NAMESPACE}

scorecard: ## Run scorecard test
	@echo ... Running the scorecard test
	- operator-sdk scorecard --verbose


############################################################
# build section
############################################################

ifeq ($(BUILD_LOCALLY),0)
    export CONFIG_DOCKER_TARGET = config-docker
config-docker:
endif

build: install-operator-sdk $(CONFIG_DOCKER_TARGET) build-amd64 build-ppc64le build-s390x build-release ## Build multi-arch images

build-amd64:
	@echo "Building the ${IMG} amd64 binary..."
	@operator-sdk build --image-build-args "-f build/Dockerfile" $(REGISTRY)/$(IMG)-amd64:$(VERSION)

build-ppc64le:
	@echo "Building the ${IMG} ppc64le binary..."
	@operator-sdk build --image-build-args "-f build/Dockerfile.ppc64le" $(REGISTRY)/$(IMG)-ppc64le:$(VERSION)

build-s390x:
	@echo "Building the ${IMG} s390x binary..."
	@operator-sdk build --image-build-args "-f build/Dockerfile.s390x" $(REGISTRY)/$(IMG)-s390x:$(VERSION)

build-release:
ifeq ($(LOCAL_OS),Linux)
ifeq ($(LOCAL_ARCH),x86_64)
	@curl -L -o /tmp/manifest-tool https://github.com/estesp/manifest-tool/releases/download/v1.0.0/manifest-tool-linux-amd64
	@chmod +x /tmp/manifest-tool
	/tmp/manifest-tool push from-args --platforms linux/amd64,linux/ppc64le,linux/s390x --template $(REGISTRY)/$(IMG)-ARCH:$(VERSION) --target $(REGISTRY)/$(IMG) --ignore-missing
	/tmp/manifest-tool push from-args --platforms linux/amd64,linux/ppc64le,linux/s390x --template $(REGISTRY)/$(IMG)-ARCH:$(VERSION) --target $(REGISTRY)/$(IMG):$(VERSION) --ignore-missing
endif
endif

############################################################
# images section
############################################################

images: build push-images

push-images:
	@docker tag $(REGISTRY)/$(IMG):$(VERSION) $(REGISTRY)/$(IMG)
	@if [ $(BUILD_LOCALLY) -ne 1 ]; then docker push $(REGISTRY)/$(IMG):$(VERSION); docker push $(REGISTRY)/$(IMG); fi

############################################################
# application section
############################################################

install: ## Install all resources (CR/CRD's, RBCA and Operator)
	@echo ....... Set environment variables ......
	- export DEPLOY_DIR=deploy/crds
	- export WATCH_NAMESPACE=${NAMESPACE}
	@echo ....... Creating namespace .......
	- kubectl create namespace ${NAMESPACE}
	@echo ....... Applying CRDS and Operator .......
	- kubectl apply -f deploy/crds/charts.helm.k8s.io_icpcatalogcharts_crd.yaml --validate=false
	@echo ....... Applying RBAC .......
	- kubectl apply -f deploy/service_account.yaml -n ${NAMESPACE}
	- kubectl apply -f deploy/role.yaml -n ${NAMESPACE}
	- kubectl apply -f deploy/role_binding.yaml -n ${NAMESPACE}
	@echo ....... Applying Operator .......
	- kubectl apply -f deploy/operator.yaml -n ${NAMESPACE}
	@echo ....... Creating the Instance .......
	- kubectl apply -f deploy/crds/charts.helm.k8s.io_v1alpha1_icpcatalogchart_cr.yaml -n ${NAMESPACE}

uninstall: ## Uninstall all that all performed in the $ make install
	@echo ....... Uninstalling .......
	@echo ....... Deleting CR .......
	- kubectl delete -f deploy/crds/charts.helm.k8s.io_v1alpha1_icpcatalogchart_cr.yaml -n ${NAMESPACE}
	@echo ....... Deleting Operator .......
	- kubectl delete -f deploy/operator.yaml -n ${NAMESPACE}
	@echo ....... Deleting CRDs.......
	- kubectl delete -f deploy/crds/charts.helm.k8s.io_icpcatalogcharts_crd.yaml
	@echo ....... Deleting Rules and Service Account .......
	- kubectl delete -f deploy/role_binding.yaml -n ${NAMESPACE}
	- kubectl delete -f deploy/service_account.yaml -n ${NAMESPACE}
	- kubectl delete -f deploy/role.yaml -n ${NAMESPACE}
	@echo ....... Deleting namespace ${NAMESPACE}.......
	- kubectl delete namespace ${NAMESPACE}

############################################################
# clean section
############################################################
clean: ## Clean build binary
	@docker images | grep "${REGISTRY}/${IMG}" | tr -s ' ' | awk -F' ' '{print $$1 ":" $$2;}' | xargs -I {}  docker rmi {}
	@rm -f build/_output/bin/$(IMG)


############################################################
# help section
############################################################
help: ## Display this help
	@echo "Usage:\n  make \033[36m<target>\033[0m"
	@awk 'BEGIN {FS = ":.*##"}; \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: all build check lint test images