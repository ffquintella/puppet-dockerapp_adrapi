SHELL := /bin/sh

BUNDLE ?= bundle
RAKE ?= $(BUNDLE) exec rake
RSPEC ?= $(BUNDLE) exec rspec
REGENT ?= /Users/felipe/Dev/regent/target/release/regent
REGENT_TEST_PATTERN ?= spec/{classes,defines}/**/*_spec.rb

.PHONY: help setup fixtures test validate build publish bump-major bump-minor bump-patch

help:
	@echo "Available targets:"
	@echo "  setup    - Install Ruby dependencies into vendor/bundle"
	@echo "  fixtures - Prepare spec fixtures"
	@echo "  test     - Run module specs"
	@echo "  validate - Run module validation checks"
	@echo "  build    - Build Puppet module package"
	@echo "  publish  - Build and publish module to Puppet Forge"
	@echo "  bump-major - Bump module version major (x.0.0)"
	@echo "  bump-minor - Bump module version minor (0.x.0)"
	@echo "  bump-patch - Bump module version patch (0.0.x)"

setup:
	$(BUNDLE) config set --local path 'vendor/bundle'
	$(BUNDLE) install

fixtures:
	$(RAKE) spec_prep

test: fixtures
	$(REGENT) test . --pattern "$(REGENT_TEST_PATTERN)"

validate:
	$(RAKE) validate

build:
	mkdir -p pkg
	$(REGENT) build . --output pkg

publish: build
	@set -e; \
	if [ -n "$$PUPPET_FORGE_API_KEY" ] && [ -z "$$BLACKSMITH_FORGE_API_KEY" ]; then \
		export BLACKSMITH_FORGE_API_KEY="$$PUPPET_FORGE_API_KEY"; \
	fi; \
	if [ -z "$$BLACKSMITH_FORGE_API_KEY" ] && [ -z "$$BLACKSMITH_FORGE_TOKEN" ]; then \
		if [ ! -t 0 ]; then \
			echo "No TTY available to prompt for credentials."; \
			echo "Set BLACKSMITH_FORGE_API_KEY, BLACKSMITH_FORGE_TOKEN, or PUPPET_FORGE_API_KEY."; \
			exit 1; \
		fi; \
		printf "Puppet Forge API key: "; \
		stty -echo; \
		read -r input_api_key; \
		stty echo; \
		printf "\n"; \
		if [ -z "$$input_api_key" ]; then \
			echo "No credential provided. Aborting publish."; \
			exit 1; \
		fi; \
		export BLACKSMITH_FORGE_API_KEY="$$input_api_key"; \
	fi; \
	$(RAKE) module:push

bump-major:
	$(RAKE) module:bump:major

bump-minor:
	$(RAKE) module:bump:minor

bump-patch:
	$(RAKE) module:bump:patch
