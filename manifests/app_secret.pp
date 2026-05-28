# Manages an encrypted application secret (`app_secrets` table) via `AdrapiApiKeys secret`.
#
# Values are stored AEAD-encrypted (ChaCha20-Poly1305) in the SQLite DB and exposed to
# the running app through `SqliteSecretsConfigurationProvider` - consumers keep reading
# them as `IConfiguration["ldap:bindCredentials"]` etc.
#
# Idempotency: the `unless` guard compares the configured value against `secret get` output
# inside the container. If they match, no command runs and no plaintext touches the host.
#
# @summary Declare an encrypted application secret
#
# @example
#   dockerapp_adrapi::app_secret { 'ldap:bindCredentials':
#     value => Sensitive('password-from-eyaml'),
#   }
#
# @param key
#   Configuration key (`section:subkey`), e.g. `ldap:bindCredentials`. Defaults to title.
#
# @param value
#   Plaintext value to encrypt and store.
#
# @param service_name
#   Container name to `docker exec` into.
#
# @param ensure
#   `present` to set/update, `absent` to remove.
#
define dockerapp_adrapi::app_secret (
  String $value,
  String $key          = $title,
  String $service_name = 'adrapi',
  Enum['present', 'absent'] $ensure = 'present',
) {
  include dockerapp_adrapi::cli

  $exec_base = "docker exec ${service_name} dotnet /app/adrapi-api-keys.dll secret"
  # Strip "service_name:" prefix from titles like "adrapi:ldap:bindDn" so the CLI sees
  # only the configuration key.
  $resolved_key = regsubst($key, "^${service_name}:", '')

  # Resource title uses '__' for the key separator because some catalog matchers
  # don't handle ':' in resource titles cleanly.
  $title_key = regsubst($resolved_key, ':', '__', 'G')

  # Skip (don't fail) when the container isn't running yet. Dockerapp::Run sub-resources
  # can converge before the container is actually up on first run or after an external
  # `docker rm`; on the next puppet run the container will be live and secrets will sync.
  $container_running = "test \"$(docker inspect -f '{{.State.Running}}' ${service_name} 2>/dev/null)\" = 'true'"

  if $ensure == 'present' {
    exec { "adrapi-app-secret-${service_name}-${title_key}":
      command => "${exec_base} set --name '${resolved_key}' --value '${value}'",
      onlyif  => $container_running,
      unless  => "test \"$(${exec_base} get --name '${resolved_key}' 2>/dev/null)\" = '${value}'",
      path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
      require => Dockerapp::Run[$service_name],
    }
  } else {
    exec { "adrapi-app-secret-${service_name}-${title_key}-remove":
      command => "${exec_base} remove --name '${resolved_key}' --yes",
      onlyif  => "${container_running} && ${exec_base} get --name '${resolved_key}' >/dev/null 2>&1",
      path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
      require => Dockerapp::Run[$service_name],
    }
  }
}
