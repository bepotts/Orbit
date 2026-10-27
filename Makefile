PROJECT ?= Orbit.xcodeproj
SCHEME ?= Orbit
CONFIGURATION ?= Debug
SWIFTLINT ?= swiftlint
SWIFTFORMAT ?= swiftformat
TEST_OUTPUT_DIR ?= TestReports
TEST_OUTPUT_FILE ?= $(TEST_OUTPUT_DIR)/$@.log
SWIFTLINT_ANALYZE_BUILD_LOG ?= $(TEST_OUTPUT_DIR)/swiftlint-analyze-build.log
SWIFTLINT_ANALYZE_OUTPUT_FILE ?= $(TEST_OUTPUT_DIR)/swiftlint-analyze.log

SHELL := /bin/bash

define RUN_AND_LOG
@mkdir -p "$(TEST_OUTPUT_DIR)"
@set -o pipefail; \
	$(1) 2>&1 | tee "$(TEST_OUTPUT_FILE)"
@echo "Test output saved to $(TEST_OUTPUT_FILE)"
endef

.PHONY: help build analyze clean test test-unit test-ui lint swiftlint-analyze format format-check style

help:
	@echo "Available targets:"
	@echo "  make build      Build $(SCHEME) in $(CONFIGURATION)"
	@echo "  make analyze    Run Xcode static analysis"
	@echo "  make clean      Clean build artifacts"
	@echo "  make test-unit  Run all unit tests"
	@echo "  make test-ui    Run all UI tests"
	@echo "  make test       Run all unit and UI tests"
	@echo "  make lint       Run SwiftLint"
	@echo "  make swiftlint-analyze"
	@echo "                  Run SwiftLint analyzer rules"
	@echo "  make format     Run SwiftFormat"
	@echo "  make format-check Check SwiftFormat without modifying files"
	@echo "  make style      Run SwiftFormat, then SwiftLint"
	@echo ""
	@echo "Local GitHub Actions (act):"
	@echo "  make act / act-pr       Run CI for push / pull_request"
	@echo "  make act-list / act-dryrun List jobs / preview execution"
	@echo "  make act-style / act-test Run style / both test platforms"
	@echo "  make act-test-ios / act-test-macos Run one test platform"
	@echo "  Add ACT_FLAGS=\"--verbose\" for extra act options"
	@echo ""
	@echo "Test output:"
	@echo "  Defaults to $(TEST_OUTPUT_DIR)/<target>.log"
	@echo "  Override with TEST_OUTPUT_FILE=path/to/output.log"

build:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" build

analyze:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" analyze

clean:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" clean

test-unit:
	$(call RUN_AND_LOG,xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" test -only-testing:OrbitTests)

test-ui:
	$(call RUN_AND_LOG,xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" test -only-testing:OrbitUITests)

test:
	$(call RUN_AND_LOG,xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" test)

lint:
	$(SWIFTLINT) lint --strict --config .swiftlint.yml --no-cache

swiftlint-analyze:
	@mkdir -p "$(TEST_OUTPUT_DIR)"
	@: > "$(SWIFTLINT_ANALYZE_OUTPUT_FILE)"
	@set -o pipefail; \
		xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" clean build 2>&1 | tee "$(SWIFTLINT_ANALYZE_BUILD_LOG)" | tee -a "$(SWIFTLINT_ANALYZE_OUTPUT_FILE)"
	@set -o pipefail; \
		$(SWIFTLINT) analyze --strict --config .swiftlint.yml --compiler-log-path "$(SWIFTLINT_ANALYZE_BUILD_LOG)" 2>&1 | tee -a "$(SWIFTLINT_ANALYZE_OUTPUT_FILE)"
	@echo "SwiftLint analyze output saved to $(SWIFTLINT_ANALYZE_OUTPUT_FILE)"

format-check:
	$(SWIFTFORMAT) . --config .swiftformat --cache ignore --lint

format:
	$(SWIFTFORMAT) . --config .swiftformat --cache ignore

style:
	$(MAKE) format
	$(MAKE) lint

# Run the checked-in GitHub Actions workflow locally.
ACT ?= act
ACT_FLAGS ?=
ACT_ARTIFACT_DIR ?= /tmp/Orbit-act-artifacts
ACT_OPTIONS = --workflows .github/workflows/ci.yml --env-file /dev/null --platform macos-26=-self-hosted --artifact-server-path "$(ACT_ARTIFACT_DIR)"

.PHONY: act act-list act-dryrun act-pr act-style act-test act-test-ios act-test-macos

act:
	$(ACT) push $(ACT_OPTIONS) $(ACT_FLAGS)

act-list:
	$(ACT) --list $(ACT_OPTIONS) $(ACT_FLAGS)

act-dryrun:
	$(ACT) push --dryrun $(ACT_OPTIONS) $(ACT_FLAGS)

act-pr:
	$(ACT) pull_request $(ACT_OPTIONS) $(ACT_FLAGS)

act-style:
	$(ACT) push --job style $(ACT_OPTIONS) $(ACT_FLAGS)

act-test:
	$(ACT) push --job test $(ACT_OPTIONS) $(ACT_FLAGS)

act-test-ios:
	$(ACT) push --job test --matrix platform:iOS $(ACT_OPTIONS) $(ACT_FLAGS)

act-test-macos:
	$(ACT) push --job test --matrix platform:macOS $(ACT_OPTIONS) $(ACT_FLAGS)
