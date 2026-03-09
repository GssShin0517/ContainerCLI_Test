source "$(dirname "$0")/config.conf"

./cx configure set --prop-name cx_base_uri --prop-value "${CX_BASE_URI}"
./cx configure set --prop-name cx_base_auth_uri --prop-value "${CX_BASE_AUTH_URI}"
./cx configure set --prop-name cx_tenant --prop-value "${CX_TENANT}"
./cx configure set --prop-name cx_apikey --prop-value "${CX_API_KEY}"

