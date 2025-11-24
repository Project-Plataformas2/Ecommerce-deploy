from locust import HttpUser, task, between

# ¡HOST CONFIGURADO!
# Esta es la única variable que necesitas cambiar si la IP de tu Ingress cambia.
INGRESS_HOST = "http://136.110.221.98"

class EcommerceIngressUser(HttpUser):
    # Definimos el host principal como la IP/DNS de nuestro Ingress
    host = INGRESS_HOST 
    
    # Tiempo de espera entre peticiones (1 a 5 segundos)
    wait_time = between(1, 5) 

    # --- TAREAS COMUNES DE BROWSE/LECTURA ---

    @task(5) # La tarea más común: ver productos a través del API Gateway (8080)
    # Ruta completa de prueba: http://136.110.221.98/app/api/products
    def browse_products_via_app(self):
        # El cliente usa el path relativo, ya que 'host' ya es http://136.110.221.98
        self.client.get("/app/api/products", name="1. App Gateway - /app/api/products") 

    @task(3) # Ver productos directamente (Servicio de Productos: 8500)
    # Ruta completa de prueba: http://136.110.221.98/product-service/api/products
    def browse_products_direct(self):
        # El Ingress mapea /product-service/ a product-service:8500
        self.client.get("/product-service/api/products", name="2. Product Service - /products")

    @task(2) # Buscar información de usuarios (Servicio de Usuarios: 8700)
    # Ruta completa de prueba: http://136.110.221.98/user-service/api/users
    def fetch_users(self):
        # El Ingress mapea /user-service/ a user-service:8700
        self.client.get("/user-service/api/users", name="3. User Service - /users")

    # --- TAREAS MENOS COMUNES (Escritura/Otros) ---

    @task(1) # Ver los envíos disponibles (Servicio de Envíos: 8600)
    # Ruta completa de prueba: http://136.110.221.98/shipping-service/api/shippings
    def fetch_shippings(self):
        self.client.get("/shipping-service/api/shippings", name="4. Shipping Service - /shippings")
        
    @task(1) # Ver favoritos (Servicio de Favoritos: 8800)
    # Ruta completa de prueba: http://136.110.221.98/favourite-service/api/favourites
    def fetch_favourites(self):
        self.client.get("/favourite-service/api/favourites", name="5. Favourite Service - /favourites")

    # Tarea de Pagos (Servicio de Pagos: 8400) - Deshabilitada para esta prueba simple (peso 0)
    # Ruta completa de prueba: http://136.110.221.98/payment-service/api/payments
    @task(0) 
    def fetch_payments(self):
        self.client.get("/payment-service/api/payments", name="6. Payment Service - /payments")
