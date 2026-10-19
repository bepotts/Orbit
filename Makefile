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

.PHONY: help build analyze clean test test-unit test-ui lint swiftlint-analyze format style

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
	@echo "  make style      Run SwiftFormat, then SwiftLint"
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
	$(SWIFTLINT) lint --config .swiftlint.yml --no-cache

swiftlint-analyze:
	@mkdir -p "$(TEST_OUTPUT_DIR)"
	@: > "$(SWIFTLINT_ANALYZE_OUTPUT_FILE)"
	@set -o pipefail; \
		xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" clean build 2>&1 | tee "$(SWIFTLINT_ANALYZE_BUILD_LOG)" | tee -a "$(SWIFTLINT_ANALYZE_OUTPUT_FILE)"
	@set -o pipefail; \
		$(SWIFTLINT) analyze --config .swiftlint.yml --compiler-log-path "$(SWIFTLINT_ANALYZE_BUILD_LOG)" 2>&1 | tee -a "$(SWIFTLINT_ANALYZE_OUTPUT_FILE)"
	@echo "SwiftLint analyze output saved to $(SWIFTLINT_ANALYZE_OUTPUT_FILE)"

format:
	$(SWIFTFORMAT) . --config .swiftformat --cache ignore

style:
	$(MAKE) format
	$(MAKE) lint
