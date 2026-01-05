-- fix_view.sql
DROP VIEW IF EXISTS vw_stock_bajo;
CREATE VIEW vw_stock_bajo AS
SELECT p.id_Producto, p.Prod_nombre, i.Inv_cantidad
FROM producto p
JOIN inventario i ON i.id_Producto_FK = p.id_Producto
WHERE i.Inv_cantidad <= 5;

COMMENT ON VIEW vw_stock_bajo IS 'Vista de productos con stock bajo (<=5)';
