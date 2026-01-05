-- schema.sql
-- Esquema base para Tienda de Videojuegos (versión corregida)
-- Ejecutar como superusuario para crear extensiones y objetos iniciales

-- 0) Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1) Tablas maestras y catálogos
CREATE TABLE IF NOT EXISTS categoria (
  id_Categoria SERIAL PRIMARY KEY,
  Cat_nombre VARCHAR(150) NOT NULL UNIQUE,
  Cat_descripcion TEXT,
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Productos',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS consola (
  id_Consola SERIAL PRIMARY KEY,
  Con_nombre VARCHAR(150) NOT NULL UNIQUE,
  Con_fabricante VARCHAR(150),
  Con_generacion VARCHAR(100),
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Consolas',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS proveedor (
  id_Proveedor SERIAL PRIMARY KEY,
  Prov_nombre VARCHAR(250) NOT NULL,
  Prov_contacto VARCHAR(150),
  Prov_telefono VARCHAR(50),
  Prov_email VARCHAR(200) UNIQUE,
  Prov_direccion VARCHAR(300),
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Proveedores',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS impuesto (
  id_Impuesto SERIAL PRIMARY KEY,
  Imp_nombre VARCHAR(150) NOT NULL UNIQUE,
  Imp_porcentaje NUMERIC(5,2) NOT NULL CHECK (Imp_porcentaje >= 0),
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Fiscal',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS metodo_pago (
  id_MetodoPago SERIAL PRIMARY KEY,
  MP_nombre VARCHAR(150) NOT NULL UNIQUE,
  MP_descripcion TEXT,
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Pagos',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2) Usuarios, roles y seguridad
CREATE TABLE IF NOT EXISTS rol (
  id_Rol SERIAL PRIMARY KEY,
  Rol_nombre VARCHAR(100) NOT NULL UNIQUE,
  Rol_descripcion TEXT,
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Seguridad',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS usuario (
  id_Usuario SERIAL PRIMARY KEY,
  username VARCHAR(150) NOT NULL UNIQUE,
  email VARCHAR(200) UNIQUE,
  password VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Usuarios'
);

CREATE TABLE IF NOT EXISTS usuario_rol (
  id_Usuario_Rol SERIAL PRIMARY KEY,
  id_Usuario_FK INTEGER NOT NULL REFERENCES usuario(id_Usuario) ON DELETE CASCADE,
  id_Rol_FK INTEGER NOT NULL REFERENCES rol(id_Rol) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (id_Usuario_FK, id_Rol_FK)
);

-- 3) Clientes y direcciones
CREATE TABLE IF NOT EXISTS cliente (
  id_Cliente SERIAL PRIMARY KEY,
  Cli_tipo VARCHAR(20) DEFAULT 'Natural' CHECK (Cli_tipo IN ('Natural','Empresa')),
  Cli_nombre VARCHAR(150),
  Cli_apellido VARCHAR(150),
  Cli_razon_social VARCHAR(250),
  Cli_email VARCHAR(200) UNIQUE,
  Cli_telefono VARCHAR(50),
  Cli_documento_tipo VARCHAR(50),
  Cli_documento_numero VARCHAR(100),
  Cli_estado VARCHAR(20) DEFAULT 'Activo' CHECK (Cli_estado IN ('Activo','Inactivo','Bloqueado')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Clientes'
);

CREATE TABLE IF NOT EXISTS direccion_cliente (
  id_Direccion SERIAL PRIMARY KEY,
  id_Cliente_FK INTEGER NOT NULL REFERENCES cliente(id_Cliente) ON DELETE CASCADE,
  Dir_calle VARCHAR(300),
  Dir_ciudad VARCHAR(150),
  Dir_provincia VARCHAR(150),
  Dir_pais VARCHAR(100),
  Dir_codigo_postal VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4) Productos, precios e imágenes
CREATE TABLE IF NOT EXISTS producto (
  id_Producto SERIAL PRIMARY KEY,
  Prod_nombre VARCHAR(250) NOT NULL,
  Prod_descripcion TEXT,
  Prod_precio NUMERIC(12,2) NOT NULL CHECK (Prod_precio >= 0),
  Prod_sku VARCHAR(100) UNIQUE,
  Prod_tipo VARCHAR(20),
  Prod_estado VARCHAR(20) DEFAULT 'Activo',
  Prod_es_digital BOOLEAN DEFAULT FALSE,
  id_Categoria_FK INTEGER REFERENCES categoria(id_Categoria) ON DELETE SET NULL,
  id_Consola_FK INTEGER REFERENCES consola(id_Consola) ON DELETE SET NULL,
  id_Proveedor_FK INTEGER REFERENCES proveedor(id_Proveedor) ON DELETE SET NULL,
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Productos',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS producto_precio_hist (
  id_PrecioHist SERIAL PRIMARY KEY,
  id_Producto_FK INTEGER NOT NULL REFERENCES producto(id_Producto) ON DELETE CASCADE,
  PPH_precio NUMERIC(12,2) NOT NULL CHECK (PPH_precio >= 0),
  PPH_fecha TIMESTAMP WITH TIME ZONE DEFAULT now(),
  PPH_fecha_fin TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS imagen_producto (
  id_Imagen SERIAL PRIMARY KEY,
  id_Producto_FK INTEGER NOT NULL REFERENCES producto(id_Producto) ON DELETE CASCADE,
  Img_url TEXT NOT NULL,
  Img_orden INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5) Inventario y movimientos
CREATE TABLE IF NOT EXISTS inventario (
  id_Inventario SERIAL PRIMARY KEY,
  id_Producto_FK INTEGER NOT NULL REFERENCES producto(id_Producto) ON DELETE CASCADE,
  Inv_cantidad INTEGER NOT NULL DEFAULT 0 CHECK (Inv_cantidad >= 0),
  Inv_ubicacion VARCHAR(200),
  Inv_ultimo_movimiento TIMESTAMP WITH TIME ZONE,
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Inventario',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS movimiento_inventario (
  id_Movimiento SERIAL PRIMARY KEY,
  id_Inventario_FK INTEGER NOT NULL REFERENCES inventario(id_Inventario) ON DELETE CASCADE,
  Mov_tipo VARCHAR(20) NOT NULL CHECK (Mov_tipo IN ('entrada','salida','ajuste')),
  Mov_cantidad INTEGER NOT NULL,
  Mov_descripcion TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6) Carrito, lista de deseos, pedidos y facturación
CREATE TABLE IF NOT EXISTS carrito (
  id_Carrito SERIAL PRIMARY KEY,
  id_Cliente_FK INTEGER REFERENCES cliente(id_Cliente) ON DELETE CASCADE,
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT now(),
  actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS carrito_item (
  id_CarritoItem SERIAL PRIMARY KEY,
  id_Carrito_FK INTEGER NOT NULL REFERENCES carrito(id_Carrito) ON DELETE CASCADE,
  id_Producto_FK INTEGER NOT NULL REFERENCES producto(id_Producto) ON DELETE RESTRICT,
  CI_cantidad INTEGER NOT NULL CHECK (CI_cantidad > 0),
  CI_precio_unitario NUMERIC(12,2) NOT NULL,
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS lista_deseos (
  id_Lista SERIAL PRIMARY KEY,
  id_Cliente_FK INTEGER NOT NULL REFERENCES cliente(id_Cliente) ON DELETE CASCADE,
  id_Producto_FK INTEGER NOT NULL REFERENCES producto(id_Producto) ON DELETE CASCADE,
  fecha_agregado TIMESTAMP WITH TIME ZONE DEFAULT now(),
  activo BOOLEAN DEFAULT TRUE,
  UNIQUE (id_Cliente_FK, id_Producto_FK)
);

CREATE TABLE IF NOT EXISTS pedido (
  id_Pedido SERIAL PRIMARY KEY,
  Ped_numero VARCHAR(100) NOT NULL UNIQUE,
  Ped_fecha TIMESTAMP WITH TIME ZONE DEFAULT now(),
  Ped_subtotal NUMERIC(14,2) DEFAULT 0,
  Ped_total NUMERIC(14,2) DEFAULT 0,
  Ped_estado VARCHAR(30) DEFAULT 'Pendiente',
  id_Cliente_FK INTEGER REFERENCES cliente(id_Cliente) ON DELETE SET NULL,
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Pedidos',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pedido_item (
  id_PedidoItem SERIAL PRIMARY KEY,
  id_Pedido_FK INTEGER NOT NULL REFERENCES pedido(id_Pedido) ON DELETE CASCADE,
  id_Producto_FK INTEGER NOT NULL REFERENCES producto(id_Producto) ON DELETE RESTRICT,
  PIt_cantidad INTEGER NOT NULL CHECK (PIt_cantidad > 0),
  PIt_precio_unitario NUMERIC(12,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS factura (
  id_Factura SERIAL PRIMARY KEY,
  Fac_numero VARCHAR(100) NOT NULL UNIQUE,
  Fac_fecha TIMESTAMP WITH TIME ZONE DEFAULT now(),
  Fac_subtotal NUMERIC(14,2),
  Fac_total_impuesto NUMERIC(14,2),
  Fac_total NUMERIC(14,2),
  Fac_estado VARCHAR(30) DEFAULT 'Emitida',
  id_Pedido_FK INTEGER REFERENCES pedido(id_Pedido) ON DELETE SET NULL,
  id_Cliente_FK INTEGER REFERENCES cliente(id_Cliente) ON DELETE SET NULL,
  id_Impuesto_FK INTEGER REFERENCES impuesto(id_Impuesto) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS detalle_factura (
  id_Detalle SERIAL PRIMARY KEY,
  id_Factura_FK INTEGER NOT NULL REFERENCES factura(id_Factura) ON DELETE CASCADE,
  id_Producto_FK INTEGER NOT NULL REFERENCES producto(id_Producto) ON DELETE RESTRICT,
  DF_cantidad INTEGER NOT NULL,
  DF_precio_unitario NUMERIC(12,2) NOT NULL
);

-- 7) Promociones, cupones y descuentos
CREATE TABLE IF NOT EXISTS descuento (
  id_Descuento SERIAL PRIMARY KEY,
  Des_nombre VARCHAR(150) NOT NULL,
  Des_tipo VARCHAR(20) NOT NULL CHECK (Des_tipo IN ('porcentaje','monto')),
  Des_valor NUMERIC(12,2) NOT NULL CHECK (Des_valor >= 0),
  Des_activo BOOLEAN DEFAULT TRUE,
  fecha_inicio TIMESTAMP WITH TIME ZONE,
  fecha_fin TIMESTAMP WITH TIME ZONE,
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Promociones'
);

CREATE TABLE IF NOT EXISTS cupon (
  id_Cupon SERIAL PRIMARY KEY,
  Cup_codigo VARCHAR(100) NOT NULL UNIQUE,
  Cup_descuento_porcentaje NUMERIC(5,2),
  Cup_activo BOOLEAN DEFAULT TRUE,
  fecha_inicio TIMESTAMP WITH TIME ZONE,
  fecha_fin TIMESTAMP WITH TIME ZONE,
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Promociones'
);

-- 8) Notificaciones y logs
CREATE TABLE IF NOT EXISTS plantilla_notificacion (
  id_Plantilla SERIAL PRIMARY KEY,
  PN_nombre VARCHAR(150) NOT NULL,
  PN_asunto VARCHAR(250),
  PN_cuerpo TEXT,
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Notificaciones',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notificacion (
  id_Notificacion SERIAL PRIMARY KEY,
  Not_tipo VARCHAR(50),
  Not_mensaje TEXT,
  Not_fecha_envio TIMESTAMP WITH TIME ZONE,
  Not_estado VARCHAR(50),
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Notificaciones',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS log_evento (
  id_Log SERIAL PRIMARY KEY,
  Log_tipo VARCHAR(50),
  Log_mensaje TEXT,
  Log_fecha TIMESTAMP WITH TIME ZONE DEFAULT now(),
  id_modulo VARCHAR(50) NOT NULL DEFAULT 'Logs'
);

-- 9) Índices recomendados para rendimiento
CREATE INDEX IF NOT EXISTS idx_producto_categoria ON public.producto (id_Categoria_FK);
CREATE INDEX IF NOT EXISTS idx_producto_proveedor ON public.producto (id_Proveedor_FK);
CREATE INDEX IF NOT EXISTS idx_inventario_producto ON public.inventario (id_Producto_FK);
CREATE INDEX IF NOT EXISTS idx_pedido_estado ON public.pedido (Ped_estado);
CREATE INDEX IF NOT EXISTS idx_factura_cliente ON public.factura (id_Cliente_FK);

-- 10) Vistas y objetos derivados
CREATE OR REPLACE VIEW public.vw_stock_bajo AS
SELECT p.id_Producto, p.Prod_nombre, i.Inv_cantidad
FROM public.producto p
JOIN public.inventario i ON i.id_Producto_FK = p.id_Producto
WHERE i.Inv_cantidad <= 5;

COMMENT ON VIEW public.vw_stock_bajo IS 'Vista de productos con stock bajo (<=5)';


-- 11) Restricciones y checks adicionales (idempotentes)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_prod_precio_nonneg'
  ) THEN
    ALTER TABLE producto
      ADD CONSTRAINT chk_prod_precio_nonneg CHECK (Prod_precio >= 0);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_inv_cantidad_nonneg'
  ) THEN
    ALTER TABLE inventario
      ADD CONSTRAINT chk_inv_cantidad_nonneg CHECK (Inv_cantidad >= 0);
  END IF;
END
$$;

-- 12) Comentarios útiles
COMMENT ON COLUMN producto.Prod_sku IS 'SKU único del producto';
COMMENT ON COLUMN pedido.Ped_numero IS 'Número único de pedido (ej. PED-0001)';
COMMENT ON COLUMN factura.Fac_numero IS 'Número único de factura (ej. FAC-0001)';

-- Fin de schema.sql
