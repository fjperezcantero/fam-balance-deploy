#!/bin/sh

# Esperar a que MySQL esté disponible
echo "Esperando a que MySQL esté disponible..."
until php artisan migrate:status > /dev/null 2>&1; do
    echo "MySQL no está listo aún, esperando..."
    sleep 2
done
echo "MySQL está disponible."

# Ejecutar migraciones pendientes
echo "Ejecutando migraciones pendientes..."
php artisan migrate --force

# Crear el enlace simbólico de storage si no existe
if [ ! -L /var/www/html/public/storage ]; then
    echo "Creando enlace simbólico de storage..."
    php artisan storage:link
fi

echo "Inicialización completada. Iniciando PHP-FPM..."

# Ejecutar el comando principal del contenedor
exec "$@"
