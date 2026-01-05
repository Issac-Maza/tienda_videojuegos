-- ensure_catalogs_and_uniques.sql
BEGIN;

-- Asegurar UNIQUEs necesarios
ALTER TABLE IF EXISTS impuesto ADD CONSTRAINT IF NOT EXISTS impuesto_imp_nombre_key UNIQUE (Imp_nombre);
ALTER TABLE IF EXISTS metodo_pago ADD CONSTRAINT IF NOT EXISTS metodo_pago_mp_nombre_key UNIQUE (MP_nombre);
ALTER TABLE IF EXISTS proveedor ADD CONSTRAINT IF NOT EXISTS proveedor_email_key UNIQUE (Prov_email);
ALTER TABLE IF EXISTS categoria ADD CONSTRAINT IF NOT EXISTS categoria_nombre_key UNIQUE (Cat_nombre);
ALTER TABLE IF EXISTS consola ADD CONSTRAINT IF NOT EXISTS consola_nombre_key UNIQUE (Con_nombre);

-- Insertar catálogos mínimos si no existen
INSERT INTO proveedor (Prov_nombre, Prov_contacto, Prov_telefono, Prov_email, id_modulo)
VALUES ('Distribuciones Gamer S.A.', 'Carlos Pérez', '+593987654321', 'ventas@distribucionesgamer.ec', 'Proveedores')
ON CONFLICT (Prov_email) DO NOTHING;

INSERT INTO categoria (Cat_nombre, Cat_descripcion, id_modulo)
VALUES ('Acción', 'Juegos de acción y aventura', 'Productos')
ON CONFLICT (Cat_nombre) DO NOTHING;

INSERT INTO consola (Con_nombre, Con_fabricante, Con_generacion, id_modulo)
VALUES ('PlayStation 5', 'Sony', '9ª', 'Consolas')
ON CONFLICT (Con_nombre) DO NOTHING;

COMMIT;
