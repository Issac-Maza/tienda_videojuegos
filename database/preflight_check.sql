-- 1. Tablas y columnas críticas existen
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema='public' AND table_name IN ('producto','inventario','cliente','carrito','carrito_item','pedido','pedido_item','factura');

-- 2. UNIQUE constraints usados por ON CONFLICT
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE contype = 'u' AND conrelid::regclass::text IN ('producto','usuario','rol','cupon','descuento');

-- 3. NOT NULL columns (para ver si seed omite campos obligatorios)
SELECT table_name, column_name
FROM information_schema.columns
WHERE is_nullable = 'NO' AND table_schema='public' AND table_name IN ('producto','cliente','usuario','pedido');

-- 4. Triggers definidos (para revisar efectos secundarios)
SELECT tgname, tgrelid::regclass::text, pg_get_triggerdef(oid)
FROM pg_trigger
WHERE NOT tgisinternal AND tgrelid::regclass::text IN ('carrito_item'::regclass::text, 'pedido_item'::regclass::text, 'inventario'::regclass::text);

-- 5. Comprobar que las subconsultas del seed devuelven filas (ejemplo: proveedor, categoria, consola)
SELECT (SELECT id_Proveedor FROM proveedor WHERE Prov_nombre='Distribuciones Gamer S.A.' LIMIT 1) AS prov_id;
SELECT (SELECT id_Categoria FROM categoria WHERE Cat_nombre='Acción' LIMIT 1) AS cat_id;
SELECT (SELECT id_Consola FROM consola WHERE Con_nombre='PlayStation 5' LIMIT 1) AS con_id;
