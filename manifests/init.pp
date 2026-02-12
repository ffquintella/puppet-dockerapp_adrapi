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
#   The tcp ports to be used on docker format
#
# @param log_level
#   The application log level
#
# @param sec_keys
#   Hash of the security authorization. (see the seckey class)
#   If it is left undefined the file will be managed as an empty list
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
#   DN of the user to connect to ldap server
#
# @param ldap_bind_password
#   Password of the user used to connect to ldap server
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
#   The password for the certificate file
#
# @param certificate_file_content
#   The content in base64 of the certificate file. If it is undef there will be no file creation
#
class dockerapp_adrapi (
  String $service_name = 'adrapi',
  String $version = '0.4.7',
  Array[String] $ports = ['5001:5001'],
  Enum['Error', 'Warning', 'Info', 'Information', 'Debug', 'Trace'] $log_level = 'Warning',
  Optional[Hash] $sec_keys = undef,
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
  String $certificate_password = 'adrapi-dev',
  Optional[String] $certificate_file_content = undef,
) {
  include dockerapp

  $image = "ffquintella/adrapi:${version}"

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

  if $sec_keys != undef {
    create_resources('dockerapp_adrapi::seckey', $sec_keys)
  } else {
    file { "${conf_configdir}/security.json":
      content => '[]',
    }
  }

  $effective_log_level = $log_level ? {
    'Info'  => 'Information',
    default => $log_level,
  }

  file { "${conf_configdir}/appsettings.json":
    content => epp('dockerapp_adrapi/appsettings.json.epp', {
      'log_level'           => $effective_log_level,
      'allowed_hosts'       => $allowed_hosts,
      'ssl'                 => $ldap_use_ssl,
      'max_results'         => $ldap_max_results,
      'pool_size'           => $ldap_pool_size,
      'bind_dn'             => $ldap_bind_dn,
      'bind_credentials'    => $ldap_bind_password,
      'search_base'         => $ldap_search_base,
      'search_filter'       => $ldap_search_filter,
      'admin_cn'            => $ldap_admin_cn,
      'servers'             => $ldap_servers,
      'certificate_file'    => $certificate_file,
      'certificate_password'=> $certificate_password,
    }),
    require => File[$conf_configdir],
  }

  if $certificate_file_content != undef {
    file { "${conf_configdir}/${certificate_file}":
      content => base64('decode', $certificate_file_content),
    }

    $volumes = [
      "${conf_configdir}/${certificate_file}:/app/${certificate_file}",
      "${conf_logdir}:/var/log/adrapi",
      "${conf_configdir}/appsettings.json:/app/appsettings.json",
      "${conf_configdir}/security.json:/app/security.json",
    ]
  } else {
    $volumes = [
      "${conf_logdir}:/var/log/adrapi",
      "${conf_configdir}/appsettings.json:/app/appsettings.json",
      "${conf_configdir}/security.json:/app/security.json",
    ]
  }

  $envs = []

  dockerapp::run { $service_name:
    image        => $image,
    ports        => $ports,
    volumes      => $volumes,
    environments => $envs,
    dir_group    => $dir_group,
    links        => [],
    net          => "${service_name}-net",
    dir_owner    => $dir_owner,
  }
}
