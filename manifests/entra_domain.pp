# Declares the credentials for a Microsoft Entra ID (Azure AD) backed directory domain.
#
# The non-sensitive Entra config (`tenantId`, `clientId`, `grantedPermissions`, ...) is
# rendered into `appsettings.json` under `ldap:domains:<name>:entra` by the main class.
# This type owns only the *secret half*: the `client_secret` and/or `certificate_password`
# are pushed into the encrypted SQLite store (via `dockerapp_adrapi::app_secret`) under the
# verbatim config path adrapi reads them back from - `ldap:domains:<name>:entra:clientSecret`
# and `:certificatePassword` (see adrapi `EntraConfig` + `SqliteSecretsConfigurationSource`).
#
# It is normally declared for you by the `dockerapp_adrapi` class from its `entra_domains`
# hash, but can also be declared directly.
#
# @summary Store the encrypted credentials for an Entra ID directory domain
#
# @example
#   dockerapp_adrapi::entra_domain { 'cloud':
#     tenant_id     => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
#     client_id     => '11111111-2222-3333-4444-555555555555',
#     client_secret => Sensitive('secret-from-eyaml'),
#   }
#
# @param tenant_id
#   Entra tenant GUID or verified domain. Rendered into appsettings.json (not a secret).
#
# @param client_id
#   Application (client) ID. Rendered into appsettings.json (not a secret).
#
# @param client_secret
#   App-registration client secret. Stored encrypted; mutually exclusive with
#   `certificate_path` at the adrapi level. Empty/undef means "not managed here".
#
# @param certificate_path
#   Container path to a client-auth certificate (alternative to `client_secret`). Rendered
#   into appsettings.json (the path itself is not a secret).
#
# @param certificate_password
#   Password for the certificate at `certificate_path`. Stored encrypted.
#
# @param authority_host
#   Optional authority host override (sovereign clouds). Rendered into appsettings.json.
#
# @param graph_base_url
#   Optional Microsoft Graph base URL override. Rendered into appsettings.json.
#
# @param scopes
#   Optional Graph scopes. Rendered into appsettings.json.
#
# @param granted_permissions
#   Application permissions granted admin consent; drives adrapi's startup least-privilege
#   warning. Rendered into appsettings.json.
#
# @param service_name
#   Container name the secrets are stored in. Defaults to the parent class' service name.
#
# @param ensure
#   `present` to store the credentials, `absent` to remove them.
#
define dockerapp_adrapi::entra_domain (
  String                  $tenant_id,
  String                  $client_id,
  Optional[String]        $client_secret        = undef,
  Optional[String]        $certificate_path     = undef,
  Optional[String]        $certificate_password = undef,
  Optional[String]        $authority_host       = undef,
  Optional[String]        $graph_base_url       = undef,
  Optional[Array[String]] $scopes               = undef,
  Optional[Array[String]] $granted_permissions  = undef,
  String                  $service_name         = 'adrapi',
  Enum['present', 'absent'] $ensure = 'present',
) {
  $domain = $title

  # Each credential maps to the verbatim adrapi config path. The "${service_name}:" prefix
  # is stripped by app_secret, leaving the exact key adrapi looks up.
  if $client_secret != undef and $client_secret != '' {
    dockerapp_adrapi::app_secret { "${service_name}:ldap:domains:${domain}:entra:clientSecret":
      service_name => $service_name,
      key          => "ldap:domains:${domain}:entra:clientSecret",
      value        => $client_secret,
      ensure       => $ensure,
    }
  }

  if $certificate_password != undef and $certificate_password != '' {
    dockerapp_adrapi::app_secret { "${service_name}:ldap:domains:${domain}:entra:certificatePassword":
      service_name => $service_name,
      key          => "ldap:domains:${domain}:entra:certificatePassword",
      value        => $certificate_password,
      ensure       => $ensure,
    }
  }
}
