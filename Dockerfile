FROM quay.io/keycloak/keycloak:20.0.3
WORKDIR /opt/keycloak/
RUN ./bin/kc.sh build --db=postgres
