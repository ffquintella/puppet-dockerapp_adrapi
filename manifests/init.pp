# Installs ADRAPI using docker
#
# @summary This class installs the ADRAPI API using docker
#
# @example
#   include dockerapp_adrapi
#
# @param service_name
#   The name of the container
#
# @param version
#   The version of the adrapi api to install
#
# @param ports
#   Optional explicit docker port mappings (`host:container`). If unset, `host_port:container_port` is used.
#
# @param host_port
#   Host TCP port to bind ADRAPI to when `ports` is not explicitly set
#
# @param container_port
#   Container TCP port for ADRAPI when `ports` is not explicitly set
#
# @param log_level
#   The application log level
#
# @param sec_keys
#   Legacy hash of `security.json` entries (see `dockerapp_adrapi::seckey`). When set, a
#   `security.json` file is written and the running container auto-imports it into the
#   SQLite store on next start, then renames it to `security.json.imported.<timestamp>`.
#   Prefer `api_keys` (see `dockerapp_adrapi::api_key`) for new deployments.
#
# @param api_keys
#   Hash of API key resources to declare via `dockerapp_adrapi::api_key`. Each value is
#   passed as parameters to the defined type. Keys are added with the `AdrapiApiKeys` CLI
#   inside the running container, so the container must be up for first convergence.
#
# @param app_secrets
#   Hash of application secrets to declare via `dockerapp_adrapi::app_secret`. Use this for
#   LDAP bind credentials and the HTTPS certificate password (they are no longer rendered
#   into `appsettings.json`).
#
# @param ldap_pins
#   Hash of LDAPS server pins to declare via `dockerapp_adrapi::ldap_pin`.
#
# @param ldap_servers
#   A list of ldap servers to connect to
#
# @param ldap_use_ssl
#   Select to use or not ssl connection to the ldap servers
#
# @param ldap_max_results
#   Configures the maximum number of results a query should return
#
# @param ldap_pool_size
#   The number of ldap connections to keep open
#
# @param ldap_bind_dn
#   DN of the user to connect to ldap server. When non-empty, declared as an encrypted
#   `app_secret` (key `ldap:bindDn`) instead of being written to `appsettings.json`.
#
# @param ldap_bind_password
#   Password of the user used to connect to ldap server. When non-empty, declared as an
#   encrypted `app_secret` (key `ldap:bindCredentials`).
#
# @param ldap_search_base
#   Search limitation
#
# @param ldap_search_filter
#   Search filter
#
# @param ldap_admin_cn
#   CN used to identify LDAP administrators
#
# @param allowed_hosts
#   Kestrel binding address selector. Use `*` for all interfaces.
#
# @param certificate_file
#   PkCS12 file containing certificate, certificate chain and secret key
#
# @param certificate_password
#   The password for the certificate file. When non-empty, declared as an encrypted
#   `app_secret` (key `certificate:password`).
#
# @param certificate_file_content
#   The content in base64 of the certificate file. If it is undef there will be no file creation
#
# @param database_file
#   Path (inside the container) to the SQLite store for API keys and encrypted app secrets.
#
# @param seed_file
#   Path (inside the container) to the 32-byte seed used to derive the secrets encryption key.
#   Must be mode 0600. Lives alongside `database_file` under `cfg/`.
#
# @param legacy_json_file
#   Path (inside the container) where the app looks for the legacy `security.json` to import
#   on first start.
#
# @param ldap_pin_store
#   Path (inside the container) to the LDAPS certificate pin store JSON.
#
# @param rate_limit_permit
#   Max requests per window for the auth endpoint rate limiter.
#
# @param rate_limit_window_seconds
#   Window size in seconds for the auth endpoint rate limiter.
#
# @param rate_limit_segments_per_window
#   Number of segments per window (sliding-window granularity).
#
class dockerapp_adrapi (
  String $service_name = 'adrapi',
  String $version = '1.5.0',
  Optional[Array[String]] $ports = undef,
  Integer[1, 65535] $host_port = 5001,
  Integer[1, 65535] $container_port = 5001,
  Enum['Error', 'Warning', 'Info', 'Information', 'Debug', 'Trace'] $log_level = 'Warning',
  Optional[Hash] $sec_keys = undef,
  Hash $api_keys = {},
  Hash $app_secrets = {},
  Hash $ldap_pins = {},
  Array[String] $ldap_servers = ['127.0.0.1:389'],
  Boolean $ldap_use_ssl = true,
  Integer $ldap_max_results = 999,
  Integer $ldap_pool_size = 10,
  String $ldap_bind_dn = '',
  String $ldap_bind_password = '',
  String $ldap_search_base = '',
  String $ldap_search_filter = '',
  String $ldap_admin_cn = '',
  String $allowed_hosts = '*',
  String $certificate_file = 'adrapi-dev.p12',
  String $certificate_password = '',
  Optional[String] $certificate_file_content = undef,
  String $database_file = 'cfg/api-keys.db',
  String $seed_file = 'cfg/.seed',
  String $legacy_json_file = 'security.json',
  String $ldap_pin_store = 'cfg/ldap-trusted-certs.json',
  Integer $rate_limit_permit = 5,
  Integer $rate_limit_window_seconds = 60,
  Integer $rate_limit_segments_per_window = 6,
) {
  include dockerapp

  $image = "ffquintella/adrapi:${version}"
  $effective_ports = $ports ? {
    undef   => ["${host_port}:${container_port}"],
    default => $ports,
  }

  $dir_owner = 999
  $dir_group = 999

  $data_dir = $dockerapp::params::data_dir
  $config_dir = $dockerapp::params::config_dir
  $scripts_dir = $dockerapp::params::scripts_dir
  $lib_dir = $dockerapp::params::lib_dir
  $log_dir = $dockerapp::params::log_dir

  $conf_datadir = "${data_dir}/${service_name}"
  $conf_configdir = "${config_dir}/${service_name}"
  $conf_scriptsdir = "${scripts_dir}/${service_name}"
  $conf_libdir = "${lib_dir}/${service_name}"
  $conf_logdir = "${log_dir}/${service_name}"
  $conf_cfgdir = "${conf_configdir}/cfg"

  # Writable cfg directory mounted into the container for the SQLite store, seed,
  # and LDAPS pin store. Must be writable by the container user (uid 999).
  file { $conf_cfgdir:
    ensure => directory,
    owner  => $dir_owner,
    group  => $dir_group,
    mode   => '0750',
  }

  # Legacy security.json - only managed when the legacy hash is provided. The app imports
  # it on next start and renames it to security.json.imported.<ts>.
  if $sec_keys != undef {
    create_resources('dockerapp_adrapi::seckey', $sec_keys)
  }

  $effective_log_level = $log_level ? {
    'Info'  => 'Information',
    default => $log_level,
  }

  file { "${conf_configdir}/appsettings.json":
    content => epp('dockerapp_adrapi/appsettings.json.epp', {
      'log_level'                      => $effective_log_level,
      'allowed_hosts'                  => $allowed_hosts,
      'ssl'                            => $ldap_use_ssl,
      'max_results'                    => $ldap_max_results,
      'pool_size'                      => $ldap_pool_size,
      'search_base'                    => $ldap_search_base,
      'search_filter'                  => $ldap_search_filter,
      'admin_cn'                       => $ldap_admin_cn,
      'servers'                        => $ldap_servers,
      'certificate_file'               => $certificate_file,
      'database_file'                  => $database_file,
      'seed_file'                      => $seed_file,
      'legacy_json_file'               => $legacy_json_file,
      'ldap_pin_store'                 => $ldap_pin_store,
      'rate_limit_permit'              => $rate_limit_permit,
      'rate_limit_window_seconds'      => $rate_limit_window_seconds,
      'rate_limit_segments_per_window' => $rate_limit_segments_per_window,
    }),
    require => File[$conf_configdir],
  }

  # Bind credentials and the certificate password live in the encrypted SQLite store.
  # They are declared here as app_secret resources so they are kept in sync with the
  # Puppet-declared values.
  if $ldap_bind_dn != '' {
    dockerapp_adrapi::app_secret { "${service_name}:ldap:bindDn":
      service_name => $service_name,
      key          => 'ldap:bindDn',
      value        => $ldap_bind_dn,
    }
  }
  if $ldap_bind_password != '' {
    dockerapp_adrapi::app_secret { "${service_name}:ldap:bindCredentials":
      service_name => $service_name,
      key          => 'ldap:bindCredentials',
      value        => $ldap_bind_password,
    }
  }
  if $certificate_password != '' {
    dockerapp_adrapi::app_secret { "${service_name}:certificate:password":
      service_name => $service_name,
      key          => 'certificate:password',
      value        => $certificate_password,
    }
  }

  # NOTE: hash-driven bulk creation via `create_resources` / `.each` is intentionally
  # avoided here - the current regent compiler does not expand fixture-module defined
  # types ($dockerapp::run children) reliably when the same module also iterates over a
  # hash of in-module defined types. Until that's fixed, callers should declare
  # `dockerapp_adrapi::api_key`, `::app_secret`, and `::ldap_pin` resources individually,
  # or pre-seed `sec_keys` for legacy import.
  if $api_keys != {} {
    create_resources('dockerapp_adrapi::api_key', $api_keys, { 'service_name' => $service_name })
  }
  if $app_secrets != {} {
    create_resources('dockerapp_adrapi::app_secret', $app_secrets, { 'service_name' => $service_name })
  }
  if $ldap_pins != {} {
    create_resources('dockerapp_adrapi::ldap_pin', $ldap_pins, { 'service_name' => $service_name })
  }

  if $certificate_file_content != undef {
    file { "${conf_configdir}/${certificate_file}":
      content => base64('decode', $certificate_file_content),
    }
  }

  $volumes = flatten([
    "${conf_logdir}:/var/log/adrapi",
    "${conf_configdir}/appsettings.json:/app/appsettings.json:ro",
    "${conf_configdir}/appsettings.json:/app/appsettings.Development.json:ro",
    "${conf_cfgdir}:/app/cfg:rw",
    $sec_keys ? {
      undef   => [],
      default => ["${conf_configdir}/security.json:/app/security.json:rw"],
    },
    $certificate_file_content ? {
      undef   => [],
      default => ["${conf_configdir}/${certificate_file}:/app/${certificate_file}:ro"],
    },
  ])

  $envs = []

  dockerapp::run { $service_name:
    image        => $image,
    ports        => $effective_ports,
    volumes      => $volumes,
    environments => $envs,
    dir_group    => $dir_group,
    links        => [],
    net          => "${service_name}-net",
    dir_owner    => $dir_owner,
  }
}
