-- functions.sql
-- Funciones y triggers idempotentes para Tienda de Videojuegos
-- Ejecutar después de schema.sql y antes o después de seed.sql según prefieras

-- 1) Registrar historial de precio cuando cambia producto.Prod_precio
CREATE OR REPLACE FUNCTION fn_producto_precio_hist()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.Prod_precio IS DISTINCT FROM OLD.Prod_precio THEN
    INSERT INTO producto_precio_hist (id_Producto_FK, PPH_precio, PPH_fecha)
    VALUES (NEW.id_Producto, NEW.Prod_precio, now());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Trigger asociado a producto (idempotente)
DROP TRIGGER IF EXISTS trg_producto_precio_hist ON producto;
CREATE TRIGGER trg_producto_precio_hist
AFTER UPDATE ON producto
FOR EACH ROW
WHEN (OLD.Prod_precio IS DISTINCT FROM NEW.Prod_precio)
EXECUTE FUNCTION fn_producto_precio_hist();

-- 2) Registrar movimiento en movimiento_inventario cuando cambia inventario.Inv_cantidad
CREATE OR REPLACE FUNCTION fn_inventario_movimiento_on_update()
RETURNS TRIGGER AS $$
DECLARE
  delta INTEGER;
  mov_tipo TEXT;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.Inv_cantidad IS DISTINCT FROM OLD.Inv_cantidad THEN
    delta := NEW.Inv_cantidad - COALESCE(OLD.Inv_cantidad, 0);
    IF delta > 0 THEN
      mov_tipo := 'entrada';
    ELSE
      mov_tipo := 'salida';
      delta := ABS(delta);
    END IF;

    INSERT INTO movimiento_inventario (id_Inventario_FK, Mov_tipo, Mov_cantidad, Mov_descripcion, created_at)
    VALUES (NEW.id_Inventario, mov_tipo, delta, 'Cambio automático por trigger', now());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Trigger asociado a inventario
DROP TRIGGER IF EXISTS trg_inventario_movimiento ON inventario;
CREATE TRIGGER trg_inventario_movimiento
AFTER UPDATE ON inventario
FOR EACH ROW
WHEN (OLD.Inv_cantidad IS DISTINCT FROM NEW.Inv_cantidad)
EXECUTE FUNCTION fn_inventario_movimiento_on_update();

-- 3) Recalcular totales del pedido cuando cambian sus items
CREATE OR REPLACE FUNCTION fn_pedido_totales_update()
RETURNS TRIGGER AS $$
DECLARE
  target_pedido INTEGER;
BEGIN
  -- Determinar el pedido afectado (funciona para INSERT, UPDATE, DELETE)
  target_pedido := COALESCE(NEW.id_Pedido_FK, OLD.id_Pedido_FK);

  IF target_pedido IS NOT NULL THEN
    UPDATE pedido
    SET Ped_subtotal = COALESCE((
        SELECT SUM(pi.PIt_cantidad * pi.PIt_precio_unitario)
        FROM pedido_item pi
        WHERE pi.id_Pedido_FK = target_pedido
      ), 0),
      Ped_total = COALESCE((
        SELECT SUM(pi.PIt_cantidad * pi.PIt_precio_unitario)
        FROM pedido_item pi
        WHERE pi.id_Pedido_FK = target_pedido
      ), 0)
    WHERE id_Pedido = target_pedido;
  END IF;

  -- Para DELETE triggers RETURN OLD, para INSERT/UPDATE RETURN NEW
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Triggers asociados a pedido_item
DROP TRIGGER IF EXISTS trg_pedido_item_after_insert ON pedido_item;
CREATE TRIGGER trg_pedido_item_after_insert
AFTER INSERT ON pedido_item
FOR EACH ROW
EXECUTE FUNCTION fn_pedido_totales_update();

DROP TRIGGER IF EXISTS trg_pedido_item_after_update ON pedido_item;
CREATE TRIGGER trg_pedido_item_after_update
AFTER UPDATE ON pedido_item
FOR EACH ROW
EXECUTE FUNCTION fn_pedido_totales_update();

DROP TRIGGER IF EXISTS trg_pedido_item_after_delete ON pedido_item;
CREATE TRIGGER trg_pedido_item_after_delete
AFTER DELETE ON pedido_item
FOR EACH ROW
EXECUTE FUNCTION fn_pedido_totales_update();

-- 4) Calcular total de factura aplicando el primer impuesto disponible
CREATE OR REPLACE FUNCTION calcular_total_factura(p_subtotal NUMERIC)
RETURNS NUMERIC AS $$
DECLARE
  iva_porcentaje NUMERIC := 0;
  total NUMERIC;
BEGIN
  SELECT Imp_porcentaje INTO iva_porcentaje
  FROM impuesto
  ORDER BY id_Impuesto
  LIMIT 1;

  IF iva_porcentaje IS NULL THEN
    iva_porcentaje := 0;
  END IF;

  total := ROUND(p_subtotal + (p_subtotal * (iva_porcentaje / 100.0)), 2);
  RETURN total;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5) Función opcional para evitar inventario negativo (no activada por defecto)
CREATE OR REPLACE FUNCTION fn_inventario_no_negativo()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.Inv_cantidad < 0 THEN
    RAISE EXCEPTION 'Inventario no puede ser negativo (id_inventario=%).', NEW.id_Inventario;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;
-- Para activar el trigger que evita inventario negativo, descomenta y ejecuta:
-- DROP TRIGGER IF EXISTS trg_inventario_no_neg ON inventario;
-- CREATE TRIGGER trg_inventario_no_neg
-- BEFORE UPDATE ON inventario
-- FOR EACH ROW
-- EXECUTE FUNCTION fn_inventario_no_negativo();