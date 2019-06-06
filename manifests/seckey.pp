# This defined type manages the security keys needed to use the adrapi API
#
# @summary This type creates a new security key needed to use the adrapi API
#
# @example
#   dockerapp_adrapi::seckey { 'xxx': }
define dockerapp_adrapi::seckey(
  $key,
  $id = $title,
  $authorized_ip,
  $claims,
  $service_name,
) {

  if!defined(Class['dockerapp_adrapi::seckey::base']){
    class{'dockerapp_adrapi::seckey::base':
      service_name => $service_name,
    }
  }

  $config_dir = $::dockerapp::params::config_dir
  $conf_configdir = "${config_dir}/${service_name}"
  $claims_str=to_json($claims)

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
