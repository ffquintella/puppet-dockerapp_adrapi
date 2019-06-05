# Installs ADRAPI using docker
#
# @summary This class installs the ADRAPI API using docker 
#
# @example
#   include dockerapp_adrapi
class dockerapp_adrapi (
  $service_name = 'adrapi',
  $version = '0.4.7',
  $ports = ['5001:5001'],
  $log_level = 'Warning',
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

  file {"${conf_configdir}/appsettings.json":
    content => epp('dockerapp_adrapi/appsettings.json.epp',
      { 'log_level' => $log_level }),
    require => File[$conf_configdir],
  }

  $volumes = [
    "${conf_logdir}:/var/log/adrapi",
    "${conf_configdir}/appsettings.json:/app/appsettings.json"
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
