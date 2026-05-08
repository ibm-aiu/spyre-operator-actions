#!/bin/bash
# +-------------------------------------------------------------------+
# | (C) Copyright IBM Corp. 2025, 2026                                |
# | SPDX-License-Identifier: Apache-2.0                               |
# +-------------------------------------------------------------------+
set -e -o pipefail
readonly TEST_CONFIG=test/config.yaml

# Detect yq version and set appropriate command
YQ_VERSION=$(yq --version 2>&1 | grep -oE '[0-9]+' | head -n1)
if [ "$YQ_VERSION" -eq 4 ]; then
	# Version 4 syntax: eval is default, -i for in-place
	YQ_CMD="yq -i"
else
	# Version 3 syntax: requires 'eval' or 'write'
	YQ_CMD="yq eval -i"
fi

function patch_test_config() {
	if [[ -n ${HAS_DEVICE} ]]; then
		echo "updating HAS_DEVICE to ${HAS_DEVICE}"
		${YQ_CMD} '.hasDevice=(strenv(HAS_DEVICE) == "true")' ${TEST_CONFIG}
	fi

	if [[ -n ${WORKLOAD_IMAGE} ]]; then
		echo "updating WORKLOAD_IMAGE to ${WORKLOAD_IMAGE}"
		${YQ_CMD} '.workloadImage=strenv(WORKLOAD_IMAGE)' ${TEST_CONFIG}
	fi

	if [[ -n ${NODE_NAME} ]]; then
		${YQ_CMD} '.nodeName=strenv(NODE_NAME)' ${TEST_CONFIG}
	fi

	if [[ -n ${PSEUDO_DEVICE_MODE} ]]; then
		echo "updating PSEUDO_DEVICE_MODE to ${PSEUDO_DEVICE_MODE}"
		${YQ_CMD} '.pseudoDeviceMode = (strenv(PSEUDO_DEVICE_MODE) == "true")' ${TEST_CONFIG}
	fi

	if [[ -n ${OPERTOR_CHANNEL} ]]; then
		${YQ_CMD} '.defaultChannel=strenv(OPERTOR_CHANNEL)' ${TEST_CONFIG}
	fi

	if [[ -n ${OPERATOR_TAG} ]]; then
		${YQ_CMD} '.operator.version=strenv(OPERATOR_TAG)' ${TEST_CONFIG}
		${YQ_CMD} '.catalog.version=strenv(OPERATOR_TAG)' ${TEST_CONFIG}
		${YQ_CMD} '.bundle.version=strenv(OPERATOR_TAG)' ${TEST_CONFIG}
	fi

	if [[ -n ${DEVICE_PLUGIN_TAG} ]]; then
		${YQ_CMD} '.devicePlugin.version=strenv(DEVICE_PLUGIN_TAG)' ${TEST_CONFIG}

		# Comment out to force to use latest release init container image
		# TODO: add back when enabling init container image build
		# ${YQ_CMD} '.devicePluginInit.version=strenv(DEVICE_PLUGIN_TAG)' ${TEST_CONFIG}
	fi

	if [[ -n ${SCHEDULER_PLUGIN_TAG} ]]; then
		${YQ_CMD} '.scheduler.version=strenv(SCHEDULER_PLUGIN_TAG)' ${TEST_CONFIG}
	fi

	if [[ -n ${VALIDATOR_TAG} ]]; then
		${YQ_CMD} '.podValidator.version=strenv(VALIDATOR_TAG)' ${TEST_CONFIG}
	fi

	if [[ -n ${HEALTH_CHECKER_TAG} ]]; then
		${YQ_CMD} '.healthChecker.version=strenv(HEALTH_CHECKER_TAG)' ${TEST_CONFIG}
	fi

	if [[ -n ${REGISTRY} ]]; then
		echo "Replacing docker.io/spyre-operator with ${REGISTRY}"
		# Replace docker.io/spyre-operator with REGISTRY in all image references
		${YQ_CMD} '(.. | select(type == "!!str" and (. == "*docker.io/spyre-operator*"))) |= sub("docker.io/spyre-operator", strenv(REGISTRY))' ${TEST_CONFIG}
	fi
}

patch_test_config
