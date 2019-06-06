# Installs ADRAPI using docker
#
# @summary This class installs the ADRAPI API using docker 
#
# @example
#   include dockerapp_adrapi
#
# @param [String] service_name 
#   The name of the container
#
# @param [String] version 
#   The version of the adrapi api to install
#
# @param [Array] ports 
#   The tcp ports to be used on docker format.
#
# @param [String] ports 
#   The tcp ports to be used.
#
# @param [String] log_level 
#   The application log level.
# @option log_level [String] Error
#   Only log errors
# @option log_level [String] Warning
#   Log errors and warnings
# @option log_level [String] Info
#   Log errors, warnings and informations
# @option log_level [String] Debug
#   Log errors, warnings and informations
#
# @param [Hash] sec_keys 
#   Hash of the security authorization. (see the seckey class)
#   If it is left undefined the file won't be managed
#
# @param [Array] ldap_servers 
#   A list of ldap servers to connect to
#
# @param [Boolean] ldap_use_ssl 
#   Select to use or not ssl connection to the ldap servers
#
# @param [String] ldap_max_results 
#   Configures the maximum number of results a query should return
#
# @param [String] ldap_pool_size 
#   The number of ldap connections to keep open
#
# @param [String] ldap_bind_dn 
#   DN of the user to connecto to ldap server
#
# @param [String] ldap_bind_password 
#   DN of the password of the user to connecto to ldap server
#
# @param [String] ldap_search_base 
#   Search limitation
#
# @param [String] ldap_search_filter 
#   Search filter
#
# @param [String] certificate_file 
#   PkCS12 file containing certificate, certificate chain and secret key
#
# @param [String] certificate_password 
#   The password for the certificate file
#
class dockerapp_adrapi (
  $service_name = 'adrapi',
  $version = '0.4.7',
  $ports = ['5001:5001'],
  $log_level = 'Warning',
  $sec_keys = undef,
  $ldap_servers = [ 'xxx:636', 'xxx:636' ],
  $ldap_use_ssl = true,
  $ldap_max_results = 1000,
  $ldap_pool_size = 1,
  $ldap_bind_dn = 'CN=adrapi,DC=a,DC=b',
  $ldap_bind_password = 'pwd',
  $ldap_search_base = 'DC=a,DC=b',
  $ldap_search_filter = '(&(objectClass=user)(objectClass=person)(sAMAccountName={0}))',
  $certificate_file = 'adrapi-dev.p12',
  $certificate_password = 'adrapi-dev',
){

include 'dockerapp'

  $image = "ffquintella/adrapi:${version}"

  $dir_owner = 999
  $dir_group = 999

  $data_dir = $::dockerapp::params::data_dir
  $config_dir = $::dockerapp::params::config_dir
  $scripts_dir = $::dockerapp::params::scripts_dir
  $lib_dir = $::dockerapp::params::lib_dir
  $log_dir = $::dockerapp::params::log_dir

  $conf_datadir = "${data_dir}/${service_name}"
  $conf_configdir = "${config_dir}/${service_name}"
  $conf_scriptsdir = "${scripts_dir}/${service_name}"
  $conf_libdir = "${lib_dir}/${service_name}"
  $conf_logdir = "${log_dir}/${service_name}"

  if $sec_keys != undef {
    create_resources('dockerapp_adrapi::seckey', $sec_keys)
  }else{
    file{"${conf_configdir}/security.json":
      content => '',
    }
  }

  file {"${conf_configdir}/appsettings.json":
    content => epp('dockerapp_adrapi/appsettings.json.epp',
      { 'log_level'           => $log_level,
        'ssl'                 => $ldap_use_ssl,
        'maxResults'          => $ldap_max_results,
        'poolSize'            => $ldap_pool_size,
        'bindDn'              => $ldap_bind_dn,
        'bindCredentials'     => $ldap_bind_password,
        'searchBase'          => $ldap_search_base,
        'searchFilter'        => $ldap_search_filter,
        'servers'             => $ldap_servers,
        'certificateFile'     => $certificate_file,
        'certificatePassword' => $certificate_password, }),
    require => File[$conf_configdir],
  }

  $volumes = [
    "${conf_logdir}:/var/log/adrapi",
    "${conf_configdir}/appsettings.json:/app/appsettings.json",
    "${conf_configdir}/security.json:/app/security.json",
  ]

  $envs = []

  dockerapp::run {$service_name:
    image        => $image,
    ports        => $ports,
    volumes      => $volumes,
    environments => $envs,
    dir_group    => $dir_group,
    dir_owner    => $dir_owner,
  }

}
