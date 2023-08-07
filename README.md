# opencdms-auth

We are investigating the potential of using Keycloak as a Single Sign-On (SSO) service for Identity and Access Management (IAM) purposes.

When using keycloak, the most common approach is to integrate the required libraries directly into the client application(s) allowing them to store tokens and include them in requests.

![](https://kevalnagda.github.io/assets/img/keycloak/2.png)

Although this may be as simple as adding middleware, it does require changes to the application(s).

An alternative approach is to implement edge authentication.

The example below shows nginx "at the edge" handling token introspection and making the decision whether to permit the request to proceed to the application.

![](https://kevalnagda.github.io/assets/img/keycloak/1.png)

Edge authentication could be especially useful for distributed systems that contain main different services that require common/centralised authentication and authorisation.

However, since the application(s) themselves do not manage sessions and tokens we will need some extra intelligence in the proxy server. Once a user authenticates this extra intelligence creates a session and sends a cookie back to the client with the response. This enables the token to accompany future requests without the client application being involved directly.

It's not clear whether the open source version of Nginx could be configured to implement cookie-based session persistence for the application(s). This, along with other capabilities like JWT validation, are available in Nginx Plus. Either way, we wouldn't want to implement this ourselves with the open source version of nginx because we could easily introduce vulnerabilities.

This [linked article](https://kevalnagda.github.io/configure-nginx-and-keycloak-to-enable-sso-for-proxied-applications) details the use of the `lua-resty-openidc` library in the open source version of nginx, however it suggests the use of [OpenResty](https://openresty.org/en/) - a modified version of nginx that enables the use of [Lua](https://en.wikipedia.org/wiki/Lua_(programming_language)) which allows interpreted Lua scripts to be executed within precompiled C software like Nginx.  Although it's possible to add ngx-lua yourself we wouldn't want to build out own version of nginx.

Note: OpenID Connect (openidc/OIDC) is an authentication layer built on top of OAuth 2.0 protocol making it usable through a REST API.

1. The user makes a request to the app.
2. Nginx, using OpenResty and lua-resty-openidc, checks if there's an existing Keycloak session cookie. If there isn't, it redirects the user to the Keycloak login page.
3. The user logs in on the Keycloak page, which sets a session cookie.
4. The user is redirected back to the app, this time with the session cookie (which will now be also present on future requests).
5. Nginx again checks the session cookie. If the JWT validation is successful, Nginx forwards the request to the backend service.

Since Nginx/OpenResty does the JWT validation the backend service(s) don't need to be aware of Keycloak at all.

Another common alternative is to use [OAuth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy) a popular alternative to the now discountined https://github.com/keycloak/keycloak-gatekeeper. Note gatekeeper was forked as Louketo Proxy (also discountinues) and [Oneconcern Keycloak Gatekeeper](https://github.com/oneconcern/keycloak-gatekeeper).

Similar to the OpenResty implementation above, Nginx forwards the request to OAuth2-proxy which interacts with Keycloak and returns http codes informing Nginx how to proceed.

So we either install OpenResty which includes Nginx, or we add another container in addition to standard nginx for the OAuth2-proxy service...

However, neither `lua-resty-openidc` nor `OAuth2-proxy` are adequate solutions for fine-grained Roll-Based Access Control (RBAC) - to control access to individual API end-points. If we pursue the edge authentication architecure then in addition we also need something like Open Policy Agent (OPA) to serve as our Policy Enforcement Point (PEP).

There are other alternatives... like replacing Nginx and oauth2-proxy/OpenResty with the open-source version of [Kong](https://konghq.com/) although, for RBAC it looks like we may again need the enterprise version. Kong is an API Gateway or Service Mesh.

### Conclusions

- Unless we think we need the ability to use Lua in nginx config, I'm not sure I'm comfortable with replacing nginx with OpenResty. The version of nginx bundled with OpenResty may be older, we would be relying on them for updates/security patches etc. and it feels like it increases the attack surface
- OAuth2-proxy looks like it may be an easier route than implementing OIDC in Flask middleware and would allow us to implement authentication 'on the edge'.
- Need to look into Edge Auth RBAC options in more depth. We could also confirm whether [Oso](https://docs.osohq.com) would be suitable for RBAC with keycloak as this has the potential to give us increased access control across the entire Python stack including down to the database access layer/ORM ([sqlalchemy-oso](https://docs.osohq.com/reference/frameworks/sqlalchemy.html)) but would be implemented in Flask middleware.
