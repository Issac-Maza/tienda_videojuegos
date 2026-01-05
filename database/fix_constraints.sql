-- Añadir chk_prod_precio_nonneg si no existe
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
-- Añadir chk_inv_cantidad_nonneg si no existe
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
