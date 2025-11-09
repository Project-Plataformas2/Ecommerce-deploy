#!/bin/bash

# Script de backup para las bases de datos PostgreSQL
# Uso: ./backup-databases.sh [namespace]

NAMESPACE="${1:-dev}"
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
DATABASES=("user-db" "product-db" "order-db" "payment-db" "shipping-db" "favourite-db")

echo "🔄 Iniciando backup de bases de datos..."
echo "📁 Directorio de backup: $BACKUP_DIR"
echo ""

mkdir -p "$BACKUP_DIR"

for db in "${DATABASES[@]}"; do
  echo "Backing up $db..."
  
  POD=$(kubectl get pod -n "$NAMESPACE" -l app="$db" -o jsonpath='{.items[0].metadata.name}')
  
  if [ -z "$POD" ]; then
    echo "❌ No se encontró pod para $db"
    continue
  fi
  
  DB_NAME="${db//-/_}_service_db"
  BACKUP_FILE="$BACKUP_DIR/${db}_backup.sql"
  
  kubectl exec -n "$NAMESPACE" "$POD" -- pg_dump -U ecommerce_user "$DB_NAME" > "$BACKUP_FILE"
  
  if [ $? -eq 0 ]; then
    echo "✅ Backup completado: $BACKUP_FILE"
  else
    echo "❌ Error en backup de $db"
  fi
  
  echo ""
done

echo " Proceso de backup completado!"
echo "Archivos guardados en: $BACKUP_DIR"
