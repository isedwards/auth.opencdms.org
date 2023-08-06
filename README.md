# opencdms-auth

We are investigating the potential of using Keycloak as a Single Sign-On (SSO) service for Identity and Access Management (IAM) purposes.

When using keycloak, the most common approach is to integrate the required libraries directly into the application as illustrated below.

![](https://kevalnagda.github.io/assets/img/keycloak/2.png)

Although this may be as simple as adding middleware, it does require changes to the application(s).

An alternative approach is to implement edge authentication.

The example below shows nginx handling token introspection and making the decission whether to permit the request to proceed to the application.

![](https://kevalnagda.github.io/assets/img/keycloak/1.png)

Unfortunately the open source version of Nginx does not have built-in support for cookie-based session persistence or JWT validation (both would require Nginx Plus).

The [linked article](https://kevalnagda.github.io/configure-nginx-and-keycloak-to-enable-sso-for-proxied-applications) details the use of the `lua-resty-openidc` library in the open source version of nginx, however it requires the use of [OpenResty](https://openresty.org/en/) - an extension to nginx that enables the use of [Lua](https://en.wikipedia.org/wiki/Lua_(programming_language)) which allows interpreted Lua scripts to be executed within precompiled C software like Nginx.

Note: OpenID Connect (openidc/OIDC) is an authentication layer built on top of OAuth 2.0 protocol making it usable through a REST API.

1. The user makes a request to the app.
2. Nginx, using OpenResty and lua-resty-openidc, checks if there's an existing Keycloak session cookie. If there isn't, it redirects the user to the Keycloak login page.
3. The user logs in on the Keycloak page, which sets a session cookie.
4. The user is redirected back to the app, this time with the session cookie.
5. Nginx again checks the session cookie. If the JWT validation is successful, Nginx forwards the request to the backend service.

Since Nginx/OpenResty does the JWT validation the backend service(s) don't need to be aware of Keycloak at all.

Another common alternative is to use [OAuth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy) - which appears to have previously been called Louketo Proxy (and then "Keycloak Gateway" before being discontinued by the Keycloak team in November 2020?) and is now forked/maintained by the community.

Similar to the OpenResty implementation above, Nginx forwards the request to OAuth2-proxy which interacts with Keycloak and returns http codes informing Nginx how to proceed.

So we either install OpenResty which includes Nginx, or we add another container in addition to standard nginx for the OAuth2-proxy service...

However, neither `lua-resty-openidc` nor `OAuth2-proxy` are adequate solutions for fine-grained Roll-Based Access Control (RBAC) - to control acccess to individual API end-points. If we pursue the edge authentication architecure then in addition we also need something like Open Policy Agent (OPA) to serve as our Policy Enforcement Point (PEP) which would usually be implemented in the application (e.g. as middleware).

There are other alternatives... like replacing Nginx and oauth2-proxy/OpenResty with the open-source version of [Kong](https://konghq.com/) although, for RBAC it looks like we may again need the enterprise version.

### Conclusions

- I'm not sure I'm comfortable with replacing nginx with OpenResty. It feels like it increases the attack surface. Also, the version of nginx bundled with OpenResty may be older and we would be relying on them for updates/security patches etc.
- OAuth2-proxy looks like it may be an easier route than implementing OIDC in Flask middleware and would allow us to implement authentication 'on the edge'. The community appear to have agreed on a version that they are maintaining.
- Need to look into Edge Auth RBAC options in more depth. We also need to confirm whether [OSO](https://docs.osohq.com) would be suitable for RBAC with keycloak as this has the potential to give us increased access control across the entire Python stack including down to the database access layer/ORM ([sqlalchemy-oso](https://docs.osohq.com/reference/frameworks/sqlalchemy.html)) but would be implemented in Flask middleware.
