# @api private
#
# Anchor class that the `api_key`, `app_secret`, and `ldap_pin` defined types depend on.
# Lives separately so the defined types compose without circular references.
#
# @summary Internal anchor for the ADRAPI CLI defined types
#
class dockerapp_adrapi::cli {
  # Currently empty - the CLIs are shipped inside the adrapi image at /app/ as
  # `adrapi-api-keys.dll` and `adrapi-ldap-cert-pin.dll`.
  # This class exists so the defined types can `include` something stable and so
  # future host-side helpers (e.g. a `docker exec` wrapper script) have a home.
}
