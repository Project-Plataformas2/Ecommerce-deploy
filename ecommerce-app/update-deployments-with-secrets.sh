#!/bin/bash

echo "🔧 Actualizando deployments con Secrets..."
echo ""

# Servicios que usan base de datos (los 6 microservicios de negocio)
DB_SERVICES=("user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service")

# 1. Agregar secrets de DB a servicios que lo necesitan
for service in "${DB_SERVICES[@]}"; do
  deployment_file="${service}-deployment.yaml"
  
  if [ -f "$deployment_file" ]; then
    echo "📝 Actualizando $deployment_file con database secrets..."
    
    # Verificar si ya tiene los secrets (para no duplicar)
    if grep -q "SPRING_DATASOURCE_USERNAME" "$deployment_file"; then
      echo "⚠️  $deployment_file ya tiene database secrets, saltando..."
    else
      # Determinar el key de DB_URL según el servicio
      db_key=$(echo "$service" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
      
      # Agregar después de la última variable de ConfigMap
      sed -i "/EUREKA_CLIENT_SERVICEURL_DEFAULTZONE/a\\
          # Database credentials from Secrets\\
          - name: SPRING_DATASOURCE_USERNAME\\
            valueFrom:\\
              secretKeyRef:\\
                name: database-secrets\\
                key: DB_USERNAME\\
          - name: SPRING_DATASOURCE_PASSWORD\\
            valueFrom:\\
              secretKeyRef:\\
                name: database-secrets\\
                key: DB_PASSWORD\\
          - name: SPRING_DATASOURCE_URL\\
            valueFrom:\\
              secretKeyRef:\\
                name: database-secrets\\
                key: ${db_key}_DB_URL" "$deployment_file"
      
      echo "✅ $deployment_file actualizado con database secrets"
    fi
  else
    echo "❌ $deployment_file no existe"
  fi
done

echo ""

# 2. Agregar JWT secrets a API Gateway
echo "📝 Actualizando api-gateway-deployment.yaml con JWT secrets..."
if grep -q "JWT_SECRET_KEY" "api-gateway-deployment.yaml"; then
  echo "⚠️  api-gateway ya tiene JWT secrets, saltando..."
else
  sed -i "/EUREKA_CLIENT_SERVICEURL_DEFAULTZONE/a\\
          # JWT configuration from Secrets\\
          - name: JWT_SECRET_KEY\\
            valueFrom:\\
              secretKeyRef:\\
                name: jwt-secrets\\
                key: JWT_SECRET_KEY\\
          - name: JWT_EXPIRATION\\
            valueFrom:\\
              secretKeyRef:\\
                name: jwt-secrets\\
                key: JWT_EXPIRATION\\
          - name: JWT_REFRESH_EXPIRATION\\
            valueFrom:\\
              secretKeyRef:\\
                name: jwt-secrets\\
                key: JWT_REFRESH_EXPIRATION" "api-gateway-deployment.yaml"
  
  echo "✅ api-gateway-deployment.yaml actualizado con JWT secrets"
fi

echo ""

# 3. Agregar external API secrets a payment service
echo "📝 Actualizando payment-service-deployment.yaml con Payment API secrets..."
if grep -q "PAYMENT_API_KEY" "payment-service-deployment.yaml"; then
  echo "⚠️  payment-service ya tiene Payment API secrets, saltando..."
else
  sed -i "/SPRING_DATASOURCE_URL/a\\
          # Payment API credentials from Secrets\\
          - name: PAYMENT_API_KEY\\
            valueFrom:\\
              secretKeyRef:\\
                name: external-api-secrets\\
                key: PAYMENT_API_KEY\\
          - name: PAYMENT_API_SECRET\\
            valueFrom:\\
              secretKeyRef:\\
                name: external-api-secrets\\
                key: PAYMENT_API_SECRET" "payment-service-deployment.yaml"
  
  echo "✅ payment-service-deployment.yaml actualizado con Payment API secrets"
fi

echo ""

# 4. Agregar external API secrets a shipping service
echo "📝 Actualizando shipping-service-deployment.yaml con Shipping API secrets..."
if grep -q "SHIPPING_API_KEY" "shipping-service-deployment.yaml"; then
  echo "⚠️  shipping-service ya tiene Shipping API secrets, saltando..."
else
  sed -i "/SPRING_DATASOURCE_URL/a\\
          # Shipping API credentials from Secrets\\
          - name: SHIPPING_API_KEY\\
            valueFrom:\\
              secretKeyRef:\\
                name: external-api-secrets\\
                key: SHIPPING_API_KEY\\
          - name: SHIPPING_API_SECRET\\
            valueFrom:\\
              secretKeyRef:\\
                name: external-api-secrets\\
                key: SHIPPING_API_SECRET" "shipping-service-deployment.yaml"
  
  echo "✅ shipping-service-deployment.yaml actualizado con Shipping API secrets"
fi

echo ""
echo "🎉 ¡Todos los deployments han sido actualizados con Secrets!"
echo ""
echo "📋 Resumen:"
echo "  - 6 servicios con database secrets"
echo "  - 1 servicio con JWT secrets (api-gateway)"
echo "  - 2 servicios con external API secrets (payment, shipping)"
