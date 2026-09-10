SHELL := /bin/sh

BUNDLE ?= bundle
RAKE ?= $(BUNDLE) exec rake
RSPEC ?= $(BUNDLE) exec rspec
REGENT ?= regent
REGENT_TEST_PATTERN ?= spec/{classes,defines}/**/*_spec.rb
FORGE_API_URL ?= https://forgeapi.puppetlabs.com

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
	$(REGENT) test . --pattern "$(REGENT_TEST_PATTERN)" --coverage

validate:
	$(RAKE) validate

build:
	mkdir -p pkg
	$(REGENT) build . --output pkg

publish: build
	@set -e; \
	api_key="$$BLACKSMITH_FORGE_API_KEY"; \
	[ -n "$$api_key" ] || api_key="$$BLACKSMITH_FORGE_TOKEN"; \
	[ -n "$$api_key" ] || api_key="$$PUPPET_FORGE_API_KEY"; \
	if [ -z "$$api_key" ]; then \
		if [ ! -t 0 ]; then \
			echo "No TTY available to prompt for credentials."; \
			echo "Set BLACKSMITH_FORGE_API_KEY, BLACKSMITH_FORGE_TOKEN, or PUPPET_FORGE_API_KEY."; \
			exit 1; \
		fi; \
		printf "Puppet Forge API key: "; \
		stty -echo; \
		read -r api_key; \
		stty echo; \
		printf "\n"; \
	fi; \
	if [ -z "$$api_key" ]; then \
		echo "No credential provided. Aborting publish."; \
		exit 1; \
	fi; \
	mod_name=`sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' metadata.json | head -1`; \
	mod_version=`sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' metadata.json | head -1`; \
	pkg_file="pkg/$$mod_name-$$mod_version.tar.gz"; \
	if [ ! -f "$$pkg_file" ]; then \
		echo "Package not found: $$pkg_file"; \
		exit 1; \
	fi; \
	echo "Publishing $$pkg_file to $(FORGE_API_URL)/v3/releases"; \
	body=`mktemp`; \
	trap 'rm -f "$$body"' EXIT; \
	code=`curl -sS -o "$$body" -w '%{http_code}' \
		-X POST "$(FORGE_API_URL)/v3/releases" \
		-H "Authorization: Bearer $$api_key" \
		-F "file=@$$pkg_file"`; \
	case "$$code" in \
		2*) echo "Published $$mod_name-$$mod_version successfully.";; \
		*) echo "Forge upload failed [HTTP $$code]:"; cat "$$body"; echo; exit 1;; \
	esac

bump-major:
	$(RAKE) module:bump:major

bump-minor:
	$(RAKE) module:bump:minor

bump-patch:
	$(RAKE) module:bump:patch
