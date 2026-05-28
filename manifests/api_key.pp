# Manages an ADRAPI API key in the SQLite store via the `AdrapiApiKeys` CLI.
#
# Idempotency is achieved by running the CLI inside the running container with
# `docker exec` and using the `verify` subcommand as the `unless` guard: the
# resource is converged only when no key with the given `key_id` exists yet, or
# when its stored hash does not match `secret`.
#
# @summary Declare an API key in the encrypted SQLite store
#
# @example
#   dockerapp_adrapi::api_key { 'prod-admin':
#     authorized_ip => '10.0.0.0/8',
#     claims        => ['isAdministrator'],
#     secret        => Sensitive('s3cret-from-eyaml'),
#   }
#
# @param key_id
#   Stable identifier for the key. Defaults to the resource title.
#
# @param authorized_ip
#   IP or CIDR allowed to authenticate with this key.
#
# @param claims
#   List of claims granted to this key, e.g. `['isAdministrator']` or `['isMonitor']`.
#
# @param secret
#   Plaintext secret. Stored as an Argon2id hash inside the container; not persisted to
#   the catalog by Puppet (`Sensitive` is recommended at the call site).
#
# @param service_name
#   Container name to `docker exec` into. Defaults to the parent class' service name.
#
# @param ensure
#   `present` to create or rotate, `absent` to remove.
#
define dockerapp_adrapi::api_key (
  String           $authorized_ip,
  Array[String]    $claims,
  String           $secret,
  String           $key_id       = $title,
  String           $service_name = 'adrapi',
  Enum['present', 'absent'] $ensure = 'present',
) {
  include dockerapp_adrapi::cli

  $claims_arg = join($claims, ',')
  $exec_base  = "docker exec ${service_name} dotnet /app/tools/AdrapiApiKeys.dll"

  # Skip (don't fail) when the container isn't running yet — see app_secret.pp for rationale.
  $container_running = "test \"$(docker inspect -f '{{.State.Running}}' ${service_name} 2>/dev/null)\" = 'true'"

  if $ensure == 'present' {
    exec { "adrapi-api-key-${service_name}-${key_id}":
      command => "${exec_base} key add --keyid '${key_id}' --ip '${authorized_ip}' --claims '${claims_arg}' --secret '${secret}'",
      onlyif  => $container_running,
      unless  => "${exec_base} key verify --keyid '${key_id}' --secret '${secret}'",
      path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
      require => Dockerapp::Run[$service_name],
    }
  } else {
    exec { "adrapi-api-key-${service_name}-${key_id}-remove":
      command => "${exec_base} key remove --keyid '${key_id}' --yes",
      onlyif  => "${container_running} && ${exec_base} key list | grep -q '^${key_id}\\b'",
      path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
      require => Dockerapp::Run[$service_name],
    }
  }
}
