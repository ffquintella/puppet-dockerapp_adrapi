# @api private
#
# Anchor class that the `api_key`, `app_secret`, and `ldap_pin` defined types depend on.
# Lives separately so the defined types compose without circular references.
#
# @summary Internal anchor for the ADRAPI CLI defined types
#
class dockerapp_adrapi::cli {
  # Currently empty - the CLIs are shipped inside the adrapi image at /app/ as the
  # standalone executables `adrapi-api-keys` and `adrapi-ldap-cert-pin`.
  # This class exists so the defined types can `include` something stable.
  # Host-callable `docker exec` wrappers for those CLIs are installed by the main
  # `dockerapp_adrapi` class (it owns `service_name`), at /usr/local/bin/.
}
