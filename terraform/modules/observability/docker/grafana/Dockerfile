FROM grafana/grafana:11.1.0

# Copiamos provisioning (datasources y dashboards config)
COPY provisioning/ /etc/grafana/provisioning/

# Copiamos el dashboard en sí
COPY dashboards/ /var/lib/grafana/dashboards/
