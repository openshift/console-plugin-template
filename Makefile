# OpenShift Console Plugin - Makefile

# Configuration
PLUGIN_NAME ?= console-plugin-template
QUAY_USER ?= <your-username>
IMAGE ?= quay.io/$(QUAY_USER)/$(PLUGIN_NAME):latest
NAMESPACE ?= $(PLUGIN_NAME)

# Validate QUAY_USER is set for targets that need it
.PHONY: check-quay-user
check-quay-user:
	@if [ "$(QUAY_USER)" = "<your-username>" ]; then \
		echo "Error: QUAY_USER is not set."; \
		echo "Run: export QUAY_USER=your-quay-username"; \
		exit 1; \
	fi

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make build    - Build container image"
	@echo "  make push     - Push image to quay.io"
	@echo "  make deploy   - Deploy to OpenShift"
	@echo "  make status   - Check deployment status"
	@echo "  make logs     - View pod logs"
	@echo "  make undeploy - Remove from OpenShift"
	@echo ""
	@echo "Required: export QUAY_USER=your-username"
	@echo "Image: quay.io/$(QUAY_USER)/$(PLUGIN_NAME):latest"

.PHONY: build
build: check-quay-user
	podman build -t $(IMAGE) .

.PHONY: push
push: check-quay-user
	podman push $(IMAGE)

.PHONY: deploy
deploy: check-quay-user
	helm upgrade -i $(PLUGIN_NAME) charts/openshift-console-plugin \
		-n $(NAMESPACE) --create-namespace \
		--set plugin.image=$(IMAGE)

.PHONY: status
status:
	@echo "=== Pods ==="
	@oc get pods -n $(NAMESPACE)
	@echo ""
	@echo "=== ConsolePlugin ==="
	@oc get consoleplugin $(PLUGIN_NAME)
	@echo ""
	@echo "=== Enabled Plugins ==="
	@oc get consoles.operator.openshift.io cluster -o jsonpath='{.spec.plugins}'
	@echo ""

.PHONY: logs
logs:
	oc logs -n $(NAMESPACE) deployment/$(PLUGIN_NAME) -f

.PHONY: undeploy
undeploy:
	helm uninstall $(PLUGIN_NAME) -n $(NAMESPACE)
	oc delete namespace $(NAMESPACE)
