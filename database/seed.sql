-- seed.sql (versión corregida)
-- Ejecutar después de schema.sql
-- Recomendación: psql -U postgres -d tienda_db -f seed.sql
-- Nota: este script usa ON CONFLICT DO NOTHING para evitar errores si faltan UNIQUE.

-- 1) Impuestos y métodos de pago
INSERT INTO impuesto (Imp_nombre, Imp_porcentaje, id_modulo)
VALUES
  ('IVA', 12.00, 'Fiscal'),
  ('Impuesto Reducido', 5.00, 'Fiscal')
ON CONFLICT DO NOTHING;

INSERT INTO metodo_pago (MP_nombre, MP_descripcion, id_modulo)
VALUES
  ('Tarjeta de Crédito', 'Pago con tarjeta', 'Pagos'),
  ('PayPal', 'Pago vía PayPal', 'Pagos'),
  ('Transferencia Bancaria', 'Transferencia bancaria', 'Pagos')
ON CONFLICT DO NOTHING;

-- 2) Proveedores
INSERT INTO proveedor (Prov_nombre, Prov_contacto, Prov_telefono, Prov_email, Prov_direccion, id_modulo)
VALUES
  ('Distribuciones Gamer S.A.', 'Carlos Pérez', '+593987654321', 'ventas@distribucionesgamer.ec', 'Av. Comercio 100', 'Proveedores'),
  ('Importadora Juegos Ltda', 'María López', '+593998877665', 'contacto@importadorajuegos.ec', 'Calle Central 45', 'Proveedores')
ON CONFLICT DO NOTHING;

-- 3) Categorías y consolas
INSERT INTO categoria (Cat_nombre, Cat_descripcion, id_modulo)
VALUES
  ('Acción', 'Juegos de acción y aventura', 'Productos'),
  ('Deportes', 'Juegos deportivos', 'Productos'),
  ('RPG', 'Juegos de rol', 'Productos')
ON CONFLICT DO NOTHING;

INSERT INTO consola (Con_nombre, Con_fabricante, Con_generacion, id_modulo)
VALUES
  ('PlayStation 5', 'Sony', '9ª', 'Consolas'),
  ('Xbox Series X', 'Microsoft', '9ª', 'Consolas'),
  ('Nintendo Switch', 'Nintendo', '8ª', 'Consolas'),
  ('PC', 'Varios', 'PC', 'Consolas')
ON CONFLICT DO NOTHING;

-- 4) Roles y usuarios
INSERT INTO rol (Rol_nombre, Rol_descripcion, id_modulo)
VALUES
  ('Administrador', 'Acceso total', 'Seguridad'),
  ('Gerente', 'Gestión y reportes', 'Seguridad'),
  ('Cliente', 'Cliente final', 'Seguridad')
ON CONFLICT DO NOTHING;

INSERT INTO usuario (username, email, password, is_active, id_modulo)
VALUES
  ('admin', 'admin@tienda.local', 'pbkdf2_sha256$example_admin_hash', TRUE, 'Usuarios'),
  ('manager', 'manager@tienda.local', 'pbkdf2_sha256$example_manager_hash', TRUE, 'Usuarios'),
  ('cliente1', 'cliente1@example.com', 'pbkdf2_sha256$example_cliente_hash', TRUE, 'Usuarios')
ON CONFLICT DO NOTHING;

-- Asignar roles a usuarios (usa UNIQUE en usuario_rol)
INSERT INTO usuario_rol (id_Usuario_FK, id_Rol_FK)
SELECT u.id_Usuario, r.id_Rol
FROM usuario u
JOIN rol r ON (
     (u.username = 'admin' AND r.Rol_nombre = 'Administrador')
  OR (u.username = 'manager' AND r.Rol_nombre = 'Gerente')
  OR (u.username = 'cliente1' AND r.Rol_nombre = 'Cliente')
)
ON CONFLICT (id_Usuario_FK, id_Rol_FK) DO NOTHING;

-- 5) Clientes y direcciones
INSERT INTO cliente (Cli_tipo, Cli_nombre, Cli_apellido, Cli_email, Cli_telefono, Cli_estado, id_modulo)
VALUES
  ('Natural', 'Juan', 'Pérez', 'juan.perez@example.com', '+593999111222', 'Activo', 'Clientes'),
  ('Natural', 'Ana', 'Gómez', 'ana.gomez@example.com', '+593999333444', 'Activo', 'Clientes')
ON CONFLICT DO NOTHING;

INSERT INTO direccion_cliente (id_Cliente_FK, Dir_calle, Dir_ciudad, Dir_provincia, Dir_pais, Dir_codigo_postal)
SELECT c.id_Cliente, 'Av. Principal 123', 'Guayaquil', 'Guayas', 'Ecuador', '090150'
FROM cliente c WHERE c.Cli_email = 'juan.perez@example.com'
ON CONFLICT DO NOTHING;

INSERT INTO direccion_cliente (id_Cliente_FK, Dir_calle, Dir_ciudad, Dir_provincia, Dir_pais, Dir_codigo_postal)
SELECT c.id_Cliente, 'Calle Secundaria 45', 'Guayaquil', 'Guayas', 'Ecuador', '090160'
FROM cliente c WHERE c.Cli_email = 'ana.gomez@example.com'
ON CONFLICT DO NOTHING;

-- 6) Productos y precios históricos
-- (Los catálogos ya se insertaron arriba; si faltan, los inserts previos los crearon)
INSERT INTO producto (Prod_nombre, Prod_descripcion, Prod_precio, Prod_sku, Prod_tipo, Prod_estado, Prod_es_digital, id_Categoria_FK, id_Consola_FK, id_Proveedor_FK, id_modulo)
VALUES
  ('CyberStrike', 'Shooter futurista en primera persona', 59.99, 'CS-PS5-001', 'Fisico', 'Activo', FALSE,
    (SELECT id_Categoria FROM categoria WHERE Cat_nombre='Acción' LIMIT 1),
    (SELECT id_Consola FROM consola WHERE Con_nombre='PlayStation 5' LIMIT 1),
    (SELECT id_Proveedor FROM proveedor WHERE Prov_nombre='Distribuciones Gamer S.A.' LIMIT 1),
    'Productos'),
  ('Futbol Pro 2025', 'Simulador de fútbol realista', 49.99, 'FP-PS5-001', 'Fisico', 'Activo', FALSE,
    (SELECT id_Categoria FROM categoria WHERE Cat_nombre='Deportes' LIMIT 1),
    (SELECT id_Consola FROM consola WHERE Con_nombre='PlayStation 5' LIMIT 1),
    (SELECT id_Proveedor FROM proveedor WHERE Prov_nombre='Importadora Juegos Ltda' LIMIT 1),
    'Productos'),
  ('Mystic Quest', 'RPG épico con mundo abierto', 39.99, 'MQ-PC-001', 'Digital', 'Activo', TRUE,
    (SELECT id_Categoria FROM categoria WHERE Cat_nombre='RPG' LIMIT 1),
    (SELECT id_Consola FROM consola WHERE Con_nombre='PC' LIMIT 1),
    (SELECT id_Proveedor FROM proveedor WHERE Prov_nombre='Distribuciones Gamer S.A.' LIMIT 1),
    'Productos')
ON CONFLICT DO NOTHING;

INSERT INTO producto_precio_hist (id_Producto_FK, PPH_precio, PPH_fecha)
SELECT p.id_Producto, p.Prod_precio, now()
FROM producto p
WHERE p.Prod_sku IN ('CS-PS5-001','FP-PS5-001','MQ-PC-001')
ON CONFLICT DO NOTHING;

-- 7) Inventario y movimientos iniciales
INSERT INTO inventario (id_Producto_FK, Inv_cantidad, Inv_ubicacion, Inv_ultimo_movimiento, id_modulo)
SELECT p.id_Producto, CASE WHEN p.Prod_es_digital = FALSE THEN 20 ELSE 0 END, 'Almacén Central', now(), 'Inventario'
FROM producto p
WHERE p.Prod_sku IN ('CS-PS5-001','FP-PS5-001')
ON CONFLICT DO NOTHING;

INSERT INTO movimiento_inventario (id_Inventario_FK, Mov_tipo, Mov_cantidad, Mov_descripcion)
SELECT i.id_Inventario, 'entrada', i.Inv_cantidad, 'Stock inicial'
FROM inventario i
WHERE i.id_Inventario IS NOT NULL
ON CONFLICT DO NOTHING;

-- 8) Descuentos y cupones
-- Usar ON CONFLICT DO NOTHING para evitar errores si no hay UNIQUE en Des_nombre
INSERT INTO descuento (Des_nombre, Des_tipo, Des_valor, Des_activo, id_modulo)
VALUES
  ('OFERTA10', 'porcentaje', 10.00, TRUE, 'Promociones'),
  ('BLACKFRIDAY', 'porcentaje', 25.00, TRUE, 'Promociones')
ON CONFLICT DO NOTHING;

INSERT INTO cupon (Cup_codigo, Cup_descuento_porcentaje, Cup_activo, id_modulo)
VALUES
  ('WELCOME5', 5.00, TRUE, 'Promociones')
ON CONFLICT DO NOTHING;

-- 9) Plantillas y notificaciones de ejemplo
INSERT INTO plantilla_notificacion (PN_nombre, PN_asunto, PN_cuerpo, id_modulo)
VALUES
  ('PrecioBajo', '¡Producto en oferta!', 'El producto {{nombre}} ha bajado de precio a {{precio}}', 'Notificaciones')
ON CONFLICT DO NOTHING;

INSERT INTO notificacion (Not_tipo, Not_mensaje, Not_fecha_envio, Not_estado, id_modulo)
VALUES
  ('email', 'Bienvenido a la Tienda de Videojuegos', now(), 'Pendiente', 'Notificaciones')
ON CONFLICT DO NOTHING;

-- 10) Carritos, items y lista de deseos (ejemplos)
INSERT INTO carrito (id_Cliente_FK, creado_en, actualizado_en)
SELECT c.id_Cliente, now(), now()
FROM cliente c WHERE c.Cli_email = 'juan.perez@example.com'
ON CONFLICT DO NOTHING;

INSERT INTO carrito_item (id_Carrito_FK, id_Producto_FK, CI_cantidad, CI_precio_unitario, creado_en)
SELECT car.id_Carrito, p.id_Producto, 1, p.Prod_precio, now()
FROM carrito car
JOIN cliente c ON car.id_Cliente_FK = c.id_Cliente
JOIN producto p ON p.Prod_sku = 'CS-PS5-001'
WHERE c.Cli_email = 'juan.perez@example.com'
ON CONFLICT DO NOTHING;

INSERT INTO lista_deseos (id_Cliente_FK, id_Producto_FK, fecha_agregado, activo)
SELECT c.id_Cliente, p.id_Producto, now(), TRUE
FROM cliente c JOIN producto p ON p.Prod_sku = 'MQ-PC-001'
WHERE c.Cli_email = 'ana.gomez@example.com'
ON CONFLICT (id_Cliente_FK, id_Producto_FK) DO NOTHING;

-- 11) Pedidos de ejemplo (crear pedido y items)
WITH cliente_sel AS (
  SELECT id_Cliente FROM cliente WHERE Cli_email = 'juan.perez@example.com' LIMIT 1
),
pedido_ins AS (
  INSERT INTO pedido (Ped_numero, Ped_fecha, Ped_subtotal, Ped_total, Ped_estado, id_Cliente_FK, id_modulo)
  VALUES (
    'PED-' || to_char(now(), 'YYYYMMDDHH24MISS'),
    now(),
    0,
    0,
    'Pendiente',
    (SELECT id_Cliente FROM cliente_sel),
    'Pedidos'
  )
  RETURNING id_Pedido
)
INSERT INTO pedido_item (id_Pedido_FK, id_Producto_FK, PIt_cantidad, PIt_precio_unitario)
SELECT (SELECT id_Pedido FROM pedido_ins), p.id_Producto, 1, p.Prod_precio
FROM producto p
WHERE p.Prod_sku = 'CS-PS5-001';

UPDATE pedido
SET Ped_subtotal = COALESCE((
    SELECT SUM(pi.PIt_cantidad * pi.PIt_precio_unitario) FROM pedido_item pi WHERE pi.id_Pedido_FK = pedido.id_Pedido
  ),0),
  Ped_total = COALESCE((
    SELECT SUM(pi.PIt_cantidad * pi.PIt_precio_unitario) FROM pedido_item pi WHERE pi.id_Pedido_FK = pedido.id_Pedido
  ),0)
WHERE Ped_estado = 'Pendiente';

-- 12) Factura de ejemplo (opcional)
INSERT INTO factura (Fac_numero, Fac_fecha, Fac_subtotal, Fac_total_impuesto, Fac_total, Fac_estado, id_Pedido_FK, id_Cliente_FK, id_Impuesto_FK, created_at)
SELECT
  'FAC-' || to_char(now(), 'YYYYMMDDHH24MISS'),
  now(),
  p.Ped_subtotal,
  ROUND(p.Ped_subtotal * (COALESCE((SELECT Imp_porcentaje FROM impuesto ORDER BY id_Impuesto LIMIT 1),0) / 100.0), 2),
  ROUND(p.Ped_subtotal + (p.Ped_subtotal * (COALESCE((SELECT Imp_porcentaje FROM impuesto ORDER BY id_Impuesto LIMIT 1),0) / 100.0)), 2),
  'Emitida',
  p.id_Pedido,
  p.id_Cliente_FK,
  (SELECT id_Impuesto FROM impuesto ORDER BY id_Impuesto LIMIT 1),
  now()
FROM pedido p
WHERE p.Ped_estado = 'Pendiente'
LIMIT 1
ON CONFLICT DO NOTHING;

-- 13) Logs de evento
INSERT INTO log_evento (Log_tipo, Log_mensaje, Log_fecha, id_modulo)
VALUES
  ('INFO', 'Seed inicial ejecutada', now(), 'Logs')
ON CONFLICT DO NOTHING;