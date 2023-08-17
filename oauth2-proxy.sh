export OAUTH2_PROXY_REVERSE_PROXY=true
export OAUTH2_PROXY_PROVIDER=keycloak-oidc
export OAUTH2_PROXY_CLIENT_ID=geo
export OAUTH2_PROXY_CLIENT_SECRET=NxmO0JWOhh28I9JsQc22xcgiF1qOdHFo
export OAUTH2_PROXY_REDIRECT_URL=https://geo.opencdms.org/oauth2/callback
export OAUTH2_PROXY_OIDC_ISSUER_URL=https://auth.opencdms.org/realms/opencdms
export OAUTH2_PROXY_COOKIE_SECRET=SjX7u0ut9xXMJqS1fNrll-jbM-ntiZ-R2-_rVW1N8jM=
export OAUTH2_PROXY_CODE_CHALLENGE_METHOD=S256

oauth2-proxy \
  --email-domain=* \
  --insecure-oidc-allow-unverified-email \
  --skip-provider-button \
  --set-xauthrequest \
  --pass-access-token \
  --set-authorization-header \
  --whitelist-domain auth.opencdms.org

