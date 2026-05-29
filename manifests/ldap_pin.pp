# Pins the LDAPS certificate of `host:port` into the trusted-certs store using
# `AdrapiLdapCertPin`. TOFU (trust-on-first-use): if a cert with a different
# SHA-256 thumbprint is later presented, the LDAPS handshake fails closed.
#
# Idempotency: the CLI itself is a no-op when the host's cert is already pinned,
# but Puppet additionally guards with `--list | grep` so we don't reach out to the
# directory server on every run.
#
# @summary Pin the certificate of an LDAPS server
#
# @example
#   dockerapp_adrapi::ldap_pin { 'dc01.example.com:636':
#     note => 'primary DC',
#   }
#
# @param target
#   `host:port` of the LDAPS endpoint. Defaults to the resource title.
#
# @param note
#   Optional human-readable note stored alongside the pin.
#
# @param service_name
#   Container name to `docker exec` into.
#
# @param ensure
#   `present` to pin, `absent` to remove the pin.
#
define dockerapp_adrapi::ldap_pin (
  String           $target       = $title,
  Optional[String] $note         = undef,
  String           $service_name = 'adrapi',
  Enum['present', 'absent'] $ensure = 'present',
) {
  include dockerapp_adrapi::cli

  $exec_base = "docker exec ${service_name} /app/adrapi-ldap-cert-pin"
  $host      = regsubst($target, ':[0-9]+$', '')

  # Skip (don't fail) when the container isn't running yet — see app_secret.pp for rationale.
  $container_running = "test \"$(docker inspect -f '{{.State.Running}}' ${service_name} 2>/dev/null)\" = 'true'"

  if $ensure == 'present' {
    $note_arg = $note ? {
      undef   => '',
      default => "--note '${note}' ",
    }
    exec { "adrapi-ldap-pin-${service_name}-${target}":
      command => "${exec_base} '${target}' ${note_arg}--yes",
      onlyif  => $container_running,
      unless  => "${exec_base} --list | grep -q '^${host}\\b'",
      path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
      require => Dockerapp::Run[$service_name],
    }
  } else {
    exec { "adrapi-ldap-pin-${service_name}-${target}-remove":
      # `--remove <host>` removes all pins for the host. If finer granularity is needed,
      # pass the sha through the title and split it here.
      command => "${exec_base} --remove '${host}'",
      onlyif  => "${container_running} && ${exec_base} --list | grep -q '^${host}\\b'",
      path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
      require => Dockerapp::Run[$service_name],
    }
  }
}
