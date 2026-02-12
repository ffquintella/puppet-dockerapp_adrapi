# This defined type manages the security keys needed to use the adrapi API
#
# @summary This type creates a new security key needed to use the adrapi API
#
# @example
#   dockerapp_adrapi::seckey { 'xxx': }
#
# @param [String] service_name 
#   The name od the service (must be the same all over the use)
#
# @param [String] key 
#   The secret key part
#
# @param [String] id 
#   The secret key identification
#
# @param [String] authorized_ip 
#   The ip authorized to use this key
#
# @param [String] claims 
#   The claims authorized for this key
#
define dockerapp_adrapi::seckey(
  String $key,
  String $id = $title,
  String $authorized_ip,
  Array[String] $claims,
  String $service_name,
) {
  if !defined(Class['dockerapp_adrapi::seckey::base']) {
    class { 'dockerapp_adrapi::seckey::base':
      service_name => $service_name,
    }
  }

  $config_dir = $::dockerapp::params::config_dir
  $conf_configdir = "${config_dir}/${service_name}"
  $claims_str = to_json($claims)

  concat::fragment { "adrapi_security.json_${id}":
    target  => "${conf_configdir}/security.json",
    content => "{
    \"secretKey\": \"${key}\",
    \"keyID\": \"${id}\",
    \"authorizedIP\": \"${authorized_ip}\",
    \"claims\":  ${claims_str} 
  },",
    order   => '10',
  }

}
