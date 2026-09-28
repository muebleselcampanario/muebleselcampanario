# Rústicos El Campanario — versión 4

Esta versión mantiene el sitio conectado a Supabase y preparada para publicarse en GitHub Pages.

## Cambios de esta versión
- Dos líneas de productos: **Línea Moderna** y **Línea Rústica**.
- Subcategorías en cada línea: **Salas, Comedores, Alcobas, Campanas y Decoración**.
- Un buscador independiente para toda la Línea Moderna y otro para toda la Línea Rústica.
- Búsqueda por nombre, subcategoría, descripción, medidas y acabados.
- Revit, SketchUp y ficha técnica se manejan únicamente como **enlaces URL**.
- Redes sociales mostradas mediante iconos de WhatsApp, Instagram, Facebook y TikTok.
- Los tres sellos/imágenes entregados por el cliente aparecen en la parte inferior, en tamaño discreto.
- Formulario de contacto conectado a Supabase con autorización obligatoria de tratamiento de datos.
- Autorización comercial separada y opcional para futuras comunicaciones publicitarias.
- Contactos visibles únicamente para el administrador y exportables a CSV cuando exista autorización comercial.
- RLS y Supabase Auth mantienen protegido el acceso administrativo.

## Antes de publicar
1. En Supabase, abre **SQL Editor**.
2. Ejecuta una sola vez `SUPABASE_MIGRACION_V4.sql`.
3. En GitHub, reemplaza el `index.html` de la raíz por el de esta carpeta.
4. Reemplaza/sube la carpeta `images`.
5. GitHub Pages debe continuar configurado como `main` + `/ (root)`.

## Seguridad
- El HTML usa únicamente la URL del proyecto y la clave publishable/anon de Supabase.
- **Nunca** agregues una clave `service_role` al HTML.
- La protección real de los datos y cambios depende de las políticas RLS de Supabase.
- Los contactos públicos pueden insertarse, pero no pueden leer, editar ni borrar contactos.
- Solo un usuario autenticado con `profiles.role = 'admin'` puede consultar o modificar contactos, productos, ambientes y opiniones.

## Imágenes principales
La fachada, logo, imagen de Sobre nosotros y silla gigante continúan siendo reemplazables desde el panel privado. Las imágenes se almacenan en el bucket de Supabase `catalog`.

## Nota legal
El texto de privacidad incluido es una base informativa para el sitio. Antes de publicarlo como política definitiva, conviene revisarlo con el responsable jurídico de la empresa para ajustarlo a su situación concreta bajo la normativa colombiana de protección de datos.
