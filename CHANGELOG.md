# Changelog

All notable changes to this project will be documented in this file.

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
