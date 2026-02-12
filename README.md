# dockerapp_adrapi

This module installs and configures ADRAPI (Active Directory REST API) in Docker using the `ffquintella/dockerapp` base module.

## Description

The module:

- Creates the ADRAPI runtime/config/log directories under `/srv`
- Generates `appsettings.json` from Puppet parameters
- Generates `security.json` (empty list or from declared API keys)
- Runs the ADRAPI container through `dockerapp::run`

## Requirements

- Puppet `>= 7.24 < 9.0.0`
- `ffquintella/dockerapp` `>= 1.2.1 < 2.0.0`
- `puppetlabs/stdlib` `>= 9.0.3 < 10.0.0`
- `puppetlabs/concat` `>= 7.0.0 < 10.0.0`

## Quick Start

```puppet
include dockerapp_adrapi
```

## Usage Examples

### 1) Basic custom deployment

```puppet
class { 'dockerapp_adrapi':
  service_name      => 'adrapi_prod',
  version           => '1.4.1',
  host_port         => 5501,
  container_port    => 5001,
  allowed_hosts     => '*',
  ldap_servers      => ['ldap01.example.com:389', 'ldap02.example.com:389'],
  ldap_use_ssl      => false,
  ldap_bind_dn      => 'CN=svc-adrapi,OU=Service,DC=example,DC=com',
  ldap_bind_password=> 'super-secret',
  ldap_search_base  => 'DC=example,DC=com',
  ldap_search_filter=> '(&(objectClass=user)(objectClass=person)(sAMAccountName={0}))',
  ldap_admin_cn     => 'CN=Admins,OU=Service,DC=example,DC=com',
}
```

### 1.1) Explicit docker mapping (advanced)

```puppet
class { 'dockerapp_adrapi':
  service_name => 'adrapi_prod',
  ports        => ['5501:5001'],
}
```

### 2) Configure API keys (`security.json`) with `sec_keys`

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
    'admin' => {
      key           => 'admin-secret-key',
      id            => 'admin',
      authorized_ip => '10.10.10.20',
      claims        => ['isAdministrator'],
      service_name  => 'adrapi_prod',
    },
  },
}
```

### 3) Provide certificate file content (base64)

```puppet
class { 'dockerapp_adrapi':
  service_name              => 'adrapi_prod',
  certificate_file          => 'adrapi-prod.p12',
  certificate_password      => 'change-me',
  certificate_file_content  => '<base64-pkcs12-content>',
}
```

## Important Parameters

- `version`: container image tag (`ffquintella/adrapi:<version>`)
- `ports`: Docker port mappings
- `host_port` / `container_port`: simple port selection used when `ports` is not explicitly set
- `allowed_hosts`: rendered to `appsettings.json` `AllowedHosts`
- LDAP settings:
  - `ldap_servers`, `ldap_use_ssl`, `ldap_pool_size`, `ldap_max_results`
  - `ldap_bind_dn`, `ldap_bind_password`, `ldap_search_base`, `ldap_search_filter`, `ldap_admin_cn`
- Certificate settings:
  - `certificate_file`, `certificate_password`, `certificate_file_content`
- `sec_keys`: optional hash to build `security.json`; if omitted, `security.json` is `[]`

Full generated reference: `doc/REFERENCES.md`

## Development / Release Workflow

### Test

```bash
make test
```

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

1. Build with `regent`
2. Ask for Puppet Forge API key if not already set in env
3. Publish using `puppet-blacksmith`

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
- `security.json` is managed either as an empty list or via declared `sec_keys` entries.
