# This is an internal class do not use it direcly
#
# @summary Internal class used by type seckey
#
class dockerapp_adrapi::seckey::base (
  $service_name = 'adrapi',
) {
  if!defined(Class['stdlib']){
    include stdlib
  }
  if!defined(Class['::dockerapp::params']){
    include ::dockerapp::params
  }

  $config_dir = $::dockerapp::params::config_dir
  $conf_configdir = "${config_dir}/${service_name}"

  if !defined(File[$conf_configdir]){
    file{ $conf_configdir:
      ensure  => directory,
    }
  }

  concat { "${conf_configdir}/security.json" :
    require => File[$conf_configdir],
  }

  concat::fragment { 'adrapi_security.json_init':
    target  => "${conf_configdir}/security.json",
    content => '[',
    order   => '01',
  }
  concat::fragment { 'adrapi_security.json_end':
    target  => "${conf_configdir}/security.json",
    content => ']',
    order   => '99',
  }
}
