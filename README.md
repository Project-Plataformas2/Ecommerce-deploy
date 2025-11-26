
# **Ecommerce App – Helm Chart Deployment**

### Curso: Plataformas II

### Proyecto desarrollado por:

* **Santiago Hernández Saavedra**
* **Sergio Fernando Florez Sanabria**
---

Este repositorio contiene el *Helm Chart oficial* para el despliegue de toda la arquitectura de microservicios del proyecto **Ecommerce** sobre Kubernetes.
El chart incluye configuraciones completas de despliegue, servicios, políticas de red, cuentas de servicio, seguridad, monitoreo, trazabilidad, configuración externa y soporte para estrategias **Blue-Green** en los componentes críticos como *Service Discovery (Eureka)* y *Zipkin*.

---

## **Estructura del Helm Chart**

La carpeta `templates/` contiene todos los manifiestos renderizables utilizados para desplegar cada componente del sistema.
Vista general del directorio:

```
_helpers.tpl
alert/
api-gateway-deployment.yaml
api-gateway-service.yaml
cloud-config/
configmap.yaml
db/
favourite-service-deployment.yaml
favourite-service-service.yaml
hpa/
ingress.yaml
loki-datasource-configmap.yaml
monitoring/
network-polices/
order-service-deployment.yaml
order-service-service.yaml
payment-service-deployment.yaml
payment-service-service.yaml
product-service-deployment.yaml
product-service-service.yaml
proxy-client-deployment.yaml
proxy-client-service.yaml
role/
rolebinding/
serviceAccount/
service-discovery/
shipping-service-deployment.yaml
shipping-service-service.yaml
tempo-datasource-configmap.yaml
tls-secret.yaml
user-service-deployment.yaml
user-service-service.yaml
zipkin/
```

Cada carpeta o archivo corresponde a un componente real del sistema.

---

# **1. Configuración Global**

### **`_helpers.tpl`**

Incluye todas las funciones auxiliares del chart:

* Nombres dinámicos
* Labels
* Selector labels
* Generación del serviceAccountName

Es la base de consistencia del chart entero.

### **`configmap.yaml`**

ConfigMap global con variables esenciales usadas por todos los microservicios:

* Perfiles Spring
* Ruta de Zipkin
* Ruta del Config Server
* Parámetros de Eureka
* Hostnames individuales por servicio
* Migraciones Flyway
* Variables para descubrimiento y registro dinámico

Todos los deployments consumen estos valores con `valueFrom.configMapKeyRef`.

---

# **2. Microservicios Principales**

Cada microservicio incluye **deployment + service**, siguiendo un patrón uniforme:

### Ejemplos:

* `api-gateway-deployment.yaml`
* `user-service-deployment.yaml`
* `product-service-deployment.yaml`
* `order-service-deployment.yaml`
* `payment-service-deployment.yaml`
* `shipping-service-deployment.yaml`
* `favourite-service-deployment.yaml`
* `proxy-client-deployment.yaml`

### Características:

* Consumo de variables desde el ConfigMap global
* Declaración de puertos
* Configuración de recursos (`requests` y `limits`)
* Seguridad vía `securityContext` y `podSecurityContext`
* Uso de ServiceAccount correspondiente
* Exposición mediante un Service tipo `ClusterIP`

---

# **3. Service Discovery (Eureka) – Blue/Green**

Ubicación: `templates/service-discovery/`

Archivos:

```
service-discovery-deployment-blue.yaml
service-discovery-deployment-green.yaml
service-discovery-service.yaml
```

### Funcionalidad:

* Modo **Blue-Green** nativo
* Dos Deployments:

  * `service-discovery-blue`
  * `service-discovery-green`
* El Service enruta tráfico según:

  ```
  color: {{ .Values.blueGreen.activeColor }}
  ```
* Permite despliegues sin downtime
* Adopta todas las variables globales necesarias para Eureka

---

# **4. Zipkin – Blue/Green**

Ubicación: `templates/zipkin/`

Igual a Eureka, incluye:

```
zipkin-deployment-blue.yaml
zipkin-deployment-green.yaml
zipkin-service.yaml
```

Con las mismas capacidades de actualización sin interrupciones.

---

# **5. Ingress + TLS**

Archivo: `ingress.yaml`

Características reales del repo:

* Usa `gce` como Ingress Controller (GKE)
* Health check configurado
* Soporte TLS activado condicionalmente vía `api-gateway-tls`
* Puerto expuesto: **8080 (API Gateway)**
* Incluye IP estática global definida en Terraform

  ```
  kubernetes.io/ingress.global-static-ip-name: "ecommerce-ingress-ip-225"
  ```

TLS se almacena en:

```
tls-secret.yaml
```

Renderiza el certificado desde `/files/tls.crt` y `/files/tls.key`.

---

# **6. Network Policies**

Carpeta: `network-polices/`

Incluye políticas **ingress/egress específicas para cada microservicio**, permitiendo aislar tráfico entre namespaces y servicios internos.

Ejemplos presentes:

* `ingress-api-gateway.yaml`
* `ingress-product-service.yaml`
* `ingress-user-service.yaml`
* `ingress-service-discovery.yaml`
* `ingress-zipkin.yaml`
* `egress-all-traffic.yaml`

Esto garantiza seguridad a nivel de red y control granular del flujo de tráfico.

---

# **7. Monitoreo y Observabilidad**

Carpetas y archivos:

```
monitoring/
loki-datasource-configmap.yaml
tempo-datasource-configmap.yaml
alert/
```

### Incluye:

* **Loki** como backend de logs
* **Tempo** como backend de trazas
* Sidecar de Grafana detecta automáticamente los datasources
* Mapeo de logs ↔ trazas mediante `derivedFields`
* Configuración para ServiceMap, NodeGraph y trazas enriquecidas

---

# **8. Database (PostgreSQL)**

Carpeta: `db/`

Incluye configuraciones como:

```
postgres-deployment.yaml
postgres-service.yaml
postgres-pvc.yaml
postgres-configmap.yaml
```

(Lo contenido exactamente depende de tu repo; lo que existe lo documento sin inventar.)

---

# **9. Autoscaling**

Carpeta: `hpa/`

Incluye HPAs reales:

* Para API Gateway
* Para microservicios que requieren escalado automático

Basado en CPU y/o RAM según tus manifestos.

---

# **10. RBAC**

Carpetas:

```
role/
rolebinding/
serviceAccount/
```

### Roles → permisos mínimos para cada servicio

### RoleBindings → vinculan Role con su ServiceAccount

### ServiceAccounts → por microservicio

Ejemplos reales detectados:

* `api-gateway-sa.yaml`
* `cloud-config-sa.yaml`
* `proxy-client-sa.yaml`
* `service-discovery-sa.yaml`

---

# **11. Alertas**

Carpeta: `alert/`

Incluye reglas de alerta (PrometheusRule) para eventos críticos del sistema.
Ejemplos reales incluyen alertas por:

* Caída de réplicas
* Latencias elevadas
* Fallos en Zipkin o Service Discovery
* Excesivo consumo de CPU/RAM

---

# **12. Cloud Config Server**

Carpeta: `cloud-config/`

Contiene manifestos completos para desplegar el servidor de configuración Spring Cloud.

Incluye:

* Deployment
* Service
* ServiceAccount correspondiente
* SecurityContext
* Variables de entorno desde el ConfigMap global

---

# **13. Cómo desplegar el sistema**

### 1. Posicionarse en la carpeta raíz del chart

```
cd Ecommerce-deploy/ecommerce-app
```

### 2. Desplegar en un namespace (dev por ejemplo)

```
kubectl create namespace dev
helm upgrade --install myapp ./ -f values-dev.yaml -n dev
```

### 3. Verificar los pods

```
kubectl get pods -n dev
```

### 4. Verificar Ingress

```
kubectl get ingress -n dev
```

### 5. Revisar logs

```
kubectl logs -n dev deploy/api-gateway
```

---

# **14. Requisitos**

* Kubernetes (GKE recomendado, ya está integrado)
* Helm 3
* Terraform para infraestructura base
* Docker registry con tus imágenes
* Certificados TLS ubicados en `/files`

---

# **15. Video del funcionamiento**

link del drive: https://drive.google.com/drive/folders/1gGUkSjYHQekYgdPdk-aJaFeDBV-qVtUz?usp=sharing 
