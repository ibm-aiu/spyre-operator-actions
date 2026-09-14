#!/bin/bash
# +-------------------------------------------------------------------+
# | (C) Copyright IBM Corp. 2025, 2026                                |
# | SPDX-License-Identifier: Apache-2.0                               |
# +-------------------------------------------------------------------+
# Usage: bash scripts/test-patch-e2e-config.bash
# Requires: yq (v3 or v4)
set -o pipefail

PASS=0; FAIL=0

# ── helpers ────────────────────────────────────────────────────────────────────

BASELINE_CONFIG_URL="https://raw.githubusercontent.com/ibm-aiu/spyre-operator/refs/heads/main/test/config.yaml"

setup() {
	mkdir -p test
	curl -fsSL "${BASELINE_CONFIG_URL}" > test/config.yaml
}

assert_eq() {
	local test_name="$1" field="$2" expected="$3"
	local actual
	actual=$(yq ".$field" test/config.yaml)
	if [[ "$actual" == "$expected" ]]; then
		echo "  PASS: $test_name — .$field == $expected"
		PASS=$((PASS + 1))
	else
		echo "  FAIL: $test_name — .$field: expected '$expected', got '$actual'"
		FAIL=$((FAIL + 1))
	fi
}

run_patch() {
	env "$@" bash scripts/patch-e2e-config.bash
}

# ── tests ──────────────────────────────────────────────────────────────────────

echo "=== TEST: unknown TEST_REPO is a no-op (all components unchanged) ==="
setup
run_patch \
	TEST_REPO=some-unknown-repo \
	TEST_REGISTRY=my.registry.io/x \
	TEST_TAG=pr-1
assert_eq "operator unchanged"         "operator.version"         "1.4.0-dev"
assert_eq "catalog unchanged"          "catalog.version"          "1.4.0-dev"
assert_eq "bundle unchanged"           "bundle.version"           "1.4.0-dev"
assert_eq "devicePlugin unchanged"     "devicePlugin.version"     "1.4.0-dev"
assert_eq "devicePluginInit unchanged" "devicePluginInit.version" "1.4.0-dev"
assert_eq "scheduler unchanged"        "scheduler.version"        "1.4.0-dev"
assert_eq "podValidator unchanged"     "podValidator.version"     "1.4.0-dev"
assert_eq "healthChecker unchanged"    "healthChecker.version"    "1.4.0-dev"
assert_eq "draDriver unchanged"        "draDriver.version"        "1.4.0-dev"
assert_eq "exporter unchanged"         "exporter.version"         "1.4.0-dev"
assert_eq "mockUser unchanged"         "mockUser.version"         "1.4.0-dev"
# repository fields must not have been created
assert_eq "operator repo unchanged"    "operator.repository"      "null"

echo ""
echo "=== TEST: operator sets catalog + bundle when TEST_CATALOG_REGISTRY present ==="
setup
run_patch \
	TEST_REPO=spyre-operator \
	TEST_REGISTRY=my.registry.io/op \
	TEST_TAG=pr-7 \
	TEST_CATALOG_REGISTRY=my.registry.io/catalog
assert_eq "operator repo"           "operator.repository"              "my.registry.io/op"
assert_eq "operator tag"            "operator.version"                 "pr-7"
assert_eq "operator policy"         "operator.imagePullPolicy"         "IfNotPresent"
assert_eq "catalog repo"            "catalog.repository"               "my.registry.io/catalog"
assert_eq "catalog tag"             "catalog.version"                  "pr-7"
assert_eq "catalog policy"          "catalog.imagePullPolicy"          "IfNotPresent"
assert_eq "bundle repo"             "bundle.repository"                "my.registry.io/catalog"
assert_eq "bundle tag"              "bundle.version"                   "pr-7"
assert_eq "bundle policy"           "bundle.imagePullPolicy"           "IfNotPresent"

echo ""
echo "=== TEST: operator without TEST_CATALOG_REGISTRY skips catalog + bundle ==="
setup
run_patch \
	TEST_REPO=spyre-operator \
	TEST_REGISTRY=my.registry.io/op \
	TEST_TAG=pr-8
assert_eq "operator repo"           "operator.repository"              "my.registry.io/op"
assert_eq "catalog repo unchanged"  "catalog.repository"               "null"
assert_eq "bundle repo unchanged"   "bundle.repository"                "null"

echo ""
echo "=== TEST: spyre-device-plugin sets devicePlugin ==="
setup
run_patch \
	TEST_REPO=spyre-device-plugin \
	TEST_REGISTRY=my.registry.io/dp \
	TEST_TAG=pr-10
assert_eq "devicePlugin repo"       "devicePlugin.repository"          "my.registry.io/dp"
assert_eq "devicePlugin tag"        "devicePlugin.version"             "pr-10"
assert_eq "devicePlugin policy"     "devicePlugin.imagePullPolicy"     "IfNotPresent"

echo ""
echo "=== TEST: spyre-scheduler-plugins sets scheduler ==="
setup
run_patch \
	TEST_REPO=spyre-scheduler-plugins \
	TEST_REGISTRY=my.registry.io/sched \
	TEST_TAG=pr-20
assert_eq "scheduler repo"          "scheduler.repository"             "my.registry.io/sched"
assert_eq "scheduler tag"           "scheduler.version"                "pr-20"
assert_eq "scheduler policy"        "scheduler.imagePullPolicy"        "IfNotPresent"

echo ""
echo "=== TEST: spyre-scheduler-plugins uses TEST_SECONDARY_SCHED_REGISTRY when set ==="
setup
run_patch \
	TEST_REPO=spyre-scheduler-plugins \
	TEST_REGISTRY=my.registry.io/sched \
	TEST_SECONDARY_SCHED_REGISTRY=my.secondary.io/sched \
	TEST_TAG=pr-21
assert_eq "scheduler secondary repo" "scheduler.repository"            "my.secondary.io/sched"
assert_eq "scheduler tag"            "scheduler.version"               "pr-21"
assert_eq "scheduler policy"         "scheduler.imagePullPolicy"       "IfNotPresent"

echo ""
echo "=== TEST: spyre-webhook-validator sets podValidator ==="
setup
run_patch \
	TEST_REPO=spyre-webhook-validator \
	TEST_REGISTRY=my.registry.io/val \
	TEST_TAG=pr-30
assert_eq "podValidator repo"       "podValidator.repository"          "my.registry.io/val"
assert_eq "podValidator tag"        "podValidator.version"             "pr-30"
assert_eq "podValidator policy"     "podValidator.imagePullPolicy"     "IfNotPresent"

echo ""
echo "=== TEST: spyre-health-checker sets healthChecker ==="
setup
run_patch \
	TEST_REPO=spyre-health-checker \
	TEST_REGISTRY=my.registry.io/hc \
	TEST_TAG=pr-40
assert_eq "healthChecker repo"      "healthChecker.repository"         "my.registry.io/hc"
assert_eq "healthChecker tag"       "healthChecker.version"            "pr-40"
assert_eq "healthChecker policy"    "healthChecker.imagePullPolicy"    "IfNotPresent"

echo ""
echo "=== TEST: dra-driver-spyre sets draDriver ==="
setup
run_patch \
	TEST_REPO=dra-driver-spyre \
	TEST_REGISTRY=my.registry.io/dra \
	TEST_TAG=pr-50
assert_eq "draDriver repo"          "draDriver.repository"             "my.registry.io/dra"
assert_eq "draDriver tag"           "draDriver.version"                "pr-50"
assert_eq "draDriver policy"        "draDriver.imagePullPolicy"        "IfNotPresent"


echo ""
echo "=== TEST: spyre-device-plugin-init sets devicePluginInit ==="
setup
run_patch \
	TEST_REPO=spyre-device-plugin-init \
	TEST_REGISTRY=my.registry.io/init \
	TEST_TAG=pr-42
assert_eq "devicePluginInit repo"   "devicePluginInit.repository"      "my.registry.io/init"
assert_eq "devicePluginInit tag"    "devicePluginInit.version"         "pr-42"
assert_eq "devicePluginInit policy" "devicePluginInit.imagePullPolicy" "IfNotPresent"

echo ""
echo "=== TEST: spyre-metrics-exporter sets exporter + mockUser ==="
setup
run_patch \
	TEST_REPO=spyre-metrics-exporter \
	TEST_REGISTRY=my.registry.io/exporter \
	TEST_TAG=pr-99
assert_eq "exporter repo"           "exporter.repository"              "my.registry.io/exporter"
assert_eq "exporter tag"            "exporter.version"                 "pr-99"
assert_eq "exporter pullPolicy"     "exporter.imagePullPolicy"         "IfNotPresent"
assert_eq "mockUser repo mirrored"  "mockUser.repository"              "my.registry.io/exporter"
assert_eq "mockUser tag mirrored"   "mockUser.version"                 "pr-99"
assert_eq "mockUser pullPolicy"     "mockUser.imagePullPolicy"         "IfNotPresent"
assert_eq "devicePlugin unchanged"  "devicePlugin.version"             "1.4.0-dev"

# ── summary ────────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
	echo "ERROR: $FAIL test(s) failed" >&2
	exit 1
fi
