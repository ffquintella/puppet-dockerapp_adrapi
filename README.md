# dockerapp_adrapi

This module installs and configures ADRAPI (Active Directory REST API) in Docker
using the `ffquintella/dockerapp` base module.

## Description

The module:

- Creates the ADRAPI runtime / config / log directories under `/srv`.
- Generates `appsettings.json` from Puppet parameters (including the new
  `security`, `ldap.pinStore`, and `rateLimit.auth` sections).
- Provisions a writable `cfg/` directory mounted at `/app/cfg` inside the
  container, holding the SQLite API-key + encrypted-secrets store
  (`api-keys.db`), the seed file (`.seed`, mode `0600`), and the LDAPS pin
  store (`ldap-trusted-certs.json`).
- Exposes the new ADRAPI CLIs via Puppet-managed defined types:
  - `dockerapp_adrapi::api_key` — Argon2id-hashed API keys
    (`AdrapiApiKeys key add/verify/remove`).
  - `dockerapp_adrapi::app_secret` — ChaCha20-Poly1305 encrypted app secrets
    (`AdrapiApiKeys secret set/get/remove`).
  - `dockerapp_adrapi::ldap_pin` — TOFU LDAPS certificate pinning
    (`AdrapiLdapCertPin <host:port> --yes`).
- Installs host-callable wrappers for the standalone in-container CLIs at
  `/usr/local/bin/adrapi-api-keys` and `/usr/local/bin/adrapi-ldap-cert-pin`,
  so operators can run them directly on the host (they forward to the container
  via `docker exec`).
- Runs the ADRAPI container through `dockerapp::run`.
- Mounts managed `appsettings.json` at both `/app/appsettings.json` and
  `/app/appsettings.Development.json` (read-only).

## Requirements

- Puppet `>= 7.24 < 9.0.0` *or* OpenVox `>= 8.0.0`
- `ffquintella/dockerapp` `>= 1.7.1 < 2.0.0`
- `puppetlabs/stdlib` `>= 9.0.3 < 10.0.0`
- `puppetlabs/concat` `>= 7.0.0 < 10.0.0`
- ADRAPI container image `>= 1.5.0` (older images do not support the SQLite
  key store or the encrypted-secrets configuration provider).

## Quick Start

```puppet
include dockerapp_adrapi
```

## Usage Examples

### 1) Basic deployment

```puppet
class { 'dockerapp_adrapi':
  service_name       => 'adrapi_prod',
  version            => '1.5.0',
  host_port          => 5501,
  container_port     => 5001,
  allowed_hosts      => '*',
  ldap_servers       => ['ldap01.example.com:389', 'ldap02.example.com:389'],
  ldap_use_ssl       => false,
  ldap_bind_dn       => 'CN=svc-adrapi,OU=Service,DC=example,DC=com',
  ldap_bind_password => 'super-secret',
  ldap_search_base   => 'DC=example,DC=com',
  ldap_search_filter => '(&(objectClass=user)(objectClass=person)(sAMAccountName={0}))',
  ldap_admin_cn      => 'CN=Admins,OU=Service,DC=example,DC=com',
}
```

`ldap_bind_dn`, `ldap_bind_password`, and `certificate_password` are no longer
written to `appsettings.json` — when non-empty they are pushed into the
encrypted `app_secrets` table via `AdrapiApiKeys secret set` and exposed back to
the app through `SqliteSecretsConfigurationProvider`.

### 1.1) Explicit docker port mapping

```puppet
class { 'dockerapp_adrapi':
  service_name => 'adrapi_prod',
  ports        => ['5501:5001'],
}
```

### 2) Declare API keys (Argon2id SQLite store)

```puppet
class { 'dockerapp_adrapi':
  service_name => 'adrapi_prod',
}

dockerapp_adrapi::api_key { 'monitoring':
  authorized_ip => '10.10.10.10',
  claims        => ['isMonitor'],
  secret        => Sensitive('monitor-secret-from-eyaml'),
  service_name  => 'adrapi_prod',
}

dockerapp_adrapi::api_key { 'admin':
  authorized_ip => '10.10.10.20',
  claims        => ['isAdministrator'],
  secret        => Sensitive('admin-secret-from-eyaml'),
  service_name  => 'adrapi_prod',
}
```

Keys are inserted into `cfg/api-keys.db` inside the running container via
`docker exec ... AdrapiApiKeys key add`, with `key verify` as the idempotency
guard. The container must be up for the first convergence.

### 3) Pin LDAPS certificates

```puppet
dockerapp_adrapi::ldap_pin { 'dc01.example.com:636':
  note         => 'primary DC',
  service_name => 'adrapi_prod',
}
```

### 4) Manage additional app secrets directly

```puppet
dockerapp_adrapi::app_secret { 'ldap:bindCredentials':
  value        => Sensitive('rotated-bind-password'),
  service_name => 'adrapi_prod',
}
```

### 6) Run the CLIs directly on the host

The module installs thin wrappers that forward to the standalone CLIs inside the
running container, so no `docker exec` boilerplate is needed:

```sh
adrapi-api-keys key list
adrapi-api-keys --help
adrapi-ldap-cert-pin --list
```

Both wrappers target the container named by `service_name` (default `adrapi`)
and exit non-zero if it is not running.

### 5) Provide the HTTPS certificate

The `.p12` Kestrel loads for the HTTPS listener (container port `6001`) can be
supplied two ways. In both cases it is mounted into the container at
`/app/${certificate_file}`, and `certificate_file` must match the name referenced
by `appsettings.json`.

**a) By base64 content** — the module writes the file under the config dir:

```puppet
class { 'dockerapp_adrapi':
  service_name              => 'adrapi_prod',
  certificate_file          => 'adrapi-prod.p12',
  certificate_password      => 'change-me',
  certificate_file_content  => '<base64-pkcs12-content>',
}
```

**b) By host path** — the file already exists on the host (managed out-of-band);
the module mounts it as-is (read-only):

```puppet
class { 'dockerapp_adrapi':
  service_name           => 'adrapi_prod',
  certificate_file       => 'adrapi-prod.p12',
  certificate_password   => 'change-me',
  certificate_file_path  => '/srv/application-config/adrapi_prod/adrapi-prod.p12',
}
```

`certificate_file_content` and `certificate_file_path` are mutually exclusive.
With neither set, the image's built-in `adrapi-dev.p12` is used.

## Important Parameters

- `version`: container image tag (`ffquintella/adrapi:<version>`). Must be
  `>= 1.5.0`.
- `ports`: Docker port mappings.
- `host_port` / `container_port`: used when `ports` is not explicitly set.
- `allowed_hosts`: rendered to `appsettings.json` `AllowedHosts`.
- LDAP settings:
  - `ldap_servers`, `ldap_use_ssl`, `ldap_pool_size`, `ldap_max_results`
  - `ldap_search_base`, `ldap_search_filter`, `ldap_admin_cn`
  - `ldap_bind_dn` / `ldap_bind_password` — pushed into the encrypted store as
    `ldap:bindDn` / `ldap:bindCredentials` when non-empty.
- Certificate settings:
  - `certificate_file`, `certificate_file_content`
  - `certificate_password` — pushed into the encrypted store as
    `certificate:password` when non-empty.
- Security store paths (defaults match upstream `appsettings.json`):
  - `database_file` (`cfg/api-keys.db`)
  - `seed_file` (`cfg/.seed`)
  - `legacy_json_file` (`security.json`)
  - `ldap_pin_store` (`cfg/ldap-trusted-certs.json`)
- Rate limiting on auth endpoints:
  - `rate_limit_permit`, `rate_limit_window_seconds`, `rate_limit_segments_per_window`
- `api_keys` / `app_secrets` / `ldap_pins`: optional hashes consumed by
  `create_resources`. **Prefer declaring the defined types directly** —
  see [Limitations](#limitations).

Full generated reference: `doc/REFERENCES.md`.

## Deprecated: `sec_keys` (legacy `security.json`)

> **`sec_keys` and the `dockerapp_adrapi::seckey` defined type are obsolete as
> of dockerapp_adrapi `2.0.0` / adrapi `1.5.0`.** They remain only for one-shot
> migration of existing deployments and will be removed in a future release.

ADRAPI 1.5.0 replaced the plaintext `security.json` file with an Argon2id-hashed
SQLite store. On the first start with a `security.json` present, ADRAPI imports
its entries into `cfg/api-keys.db` and renames the file to
`security.json.imported.<timestamp>`.

If you are upgrading from an older deployment, you can keep using `sec_keys`
for a single boot to seed the new store:

```puppet
class { 'dockerapp_adrapi':
  service_name => 'adrapi_prod',
  sec_keys     => {
    'monitoring' => {
      key           => 'monitor-secret-key',
      id            => 'monitoring',
      authorized_ip => '10.10.10.10',
      claims        => ['isMonitor'],
      service_name  => 'adrapi_prod',
    },
  },
}
```

After the next container start, switch your manifests to
`dockerapp_adrapi::api_key` resources and remove the `sec_keys` parameter; the
imported file no longer matches any Puppet-managed resource.

## Development / Release Workflow

### Test

```bash
make test
```

`make test` runs `regent test . --pattern <REGENT_TEST_PATTERN> --coverage`.
The HTML / JSON coverage report lands in `coverage/`.

### Validate

```bash
make validate
```

### Build package (Regent)

```bash
make build
```

### Publish to Puppet Forge

```bash
make publish
```

`make publish` will:

1. Build with `regent`.
2. Ask for the Puppet Forge API key if it is not already in the environment.
3. Publish using `puppet-blacksmith`.

Accepted credential env vars:

- `BLACKSMITH_FORGE_API_KEY`
- `BLACKSMITH_FORGE_TOKEN`
- `PUPPET_FORGE_API_KEY` (mapped automatically)

### Bump version

```bash
make bump-major
make bump-minor
make bump-patch
```

## Limitations

- Module behavior depends on the `dockerapp` base module defaults and structure.
- The bulk-iteration parameters (`api_keys`, `app_secrets`, `ldap_pins`) are
  routed through `create_resources`. Until the current `regent` compiler
  reliably autoloads in-module defined types invoked this way, prefer
  declaring `dockerapp_adrapi::api_key`, `::app_secret`, and `::ldap_pin`
  resources directly.
- `sec_keys` / `dockerapp_adrapi::seckey` are deprecated — see the
  [Deprecated](#deprecated-sec_keys-legacy-securityjson) section.
