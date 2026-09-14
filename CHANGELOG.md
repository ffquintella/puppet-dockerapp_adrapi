# Changelog

All notable changes to this project will be documented in this file.

## Release 2.3.0

**Breaking changes**

- `appsettings.json` is now rendered in adrapi's backend-neutral `directories`
  layout (adrapi >= 1.10.0, `docs/DIRECTORIES_CONFIG.md`); the deprecated top-level
  `ldap` section is no longer written. **Requires an adrapi image >= 1.10.0** -
  older images ignore `directories` and fall back to their own defaults.
- Encrypted secrets moved to the matching config paths:
  `ldap:bindDn` / `ldap:bindCredentials` are now
  `directories:domains:<ldap_domain>:ldap:bindDn` / `:bindCredentials`, and
  `ldap:domains:<name>:entra:clientSecret` / `:certificatePassword` are now
  `directories:domains:<name>:entra:*`. Re-key existing stores with
  `adrapi-api-keys secret migrate-directories --domain <ldap_domain>` and delete the
  legacy entries with the same command plus `--yes` once adrapi restarts cleanly.
- Default image bumped to `ffquintella/adrapi:1.10.0`.

**Features**

- New `ldap_domain` parameter names the domain built from the `ldap_*` parameters
  (default: `default_domain`, or `default` when an Entra ID domain already uses that
  name).
- New `manage_ldap_domain` parameter (default `true`) drops the LDAP domain entirely,
  for deployments backed only by `entra_domains`.
- `default_domain` may now name a domain of any `kind`, so an Entra ID domain can serve
  the domain-less routes.
- Startup-time validation of the domain set: unknown `default_domain`, an `ldap_domain`
  colliding with an `entra_domains` entry, the reserved names `users`/`groups`/`ous`/
  `infos`, and a configuration with no domain at all all fail the catalog.

**Bugfixes**

- The LDAPS pin store path is rendered as `trustedCertificatesFile` (the key adrapi
  actually reads) instead of the never-read `ldap:pinStore`.

**Known Issues**

## Release 2.2.0

**Features**

- Microsoft Entra ID (Azure AD) directory support (adrapi >= 1.8.0). New
  `entra_domains` class parameter and `dockerapp_adrapi::entra_domain` defined type
  render an `ldap:domains:<name>:entra` block (`kind: entraid`) into
  `appsettings.json` and push the `client_secret` / `certificate_password` into the
  encrypted SQLite store under the verbatim config path
  (`ldap:domains:<name>:entra:clientSecret`), never into plaintext config.
- New `default_domain` parameter (`ldap:defaultDomain`).
- Default image bumped to `ffquintella/adrapi:1.9.0`.

**Bugfixes**

**Known Issues**

## Release 1.0.3

Fixes

**Features**

**Bugfixes**
Links parameter to docker 

**Known Issues**

## Release 1.0.2

Fixes

**Features**

**Bugfixes**
Network parameter to docker 

**Known Issues**

## Release 1.0.1 

Fist funcional release

**Features**

- Instalation
- Certificate adjustment
- User management
- Log dir creation

**Bugfixes**

**Known Issues**

## Release 0.1.0 - 0.1.X

Dev releases they are unstable DO NOT USE!

**Features**

**Bugfixes**

**Known Issues**
