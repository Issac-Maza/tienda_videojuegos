-- policies_fix_email.sql
-- Corrige referencias a columna email -> Cli_email en políticas que fallaron

-- 1) Eliminar políticas problemáticas si existen
DROP POLICY IF EXISTS cliente_own_select ON public.cliente;
DROP POLICY IF EXISTS direccion_own_or_staff_select ON public.direccion_cliente;
DROP POLICY IF EXISTS pedido_own_select ON public.pedido;
DROP POLICY IF EXISTS factura_own_or_staff_select ON public.factura;
DROP POLICY IF EXISTS carrito_own_select ON public.carrito;
DROP POLICY IF EXISTS carrito_item_modify ON public.carrito_item;
DROP POLICY IF EXISTS lista_deseos_owner ON public.lista_deseos;

-- 2) Recrear políticas corregidas (usando Cli_email y nombres reales)
-- cliente: cliente ve su propio registro o staff
CREATE POLICY cliente_own_select ON public.cliente FOR SELECT
USING (
  (session_user_email() IS NOT NULL AND Cli_email = session_user_email())
  OR is_gerente_or_above_safe()
);

CREATE POLICY cliente_staff_insert ON public.cliente FOR INSERT
WITH CHECK ( is_gerente_or_above_safe() );

CREATE POLICY cliente_staff_update ON public.cliente FOR UPDATE
USING ( is_gerente_or_above_safe() );

CREATE POLICY cliente_admin_delete ON public.cliente FOR DELETE
USING ( is_admin_safe() );

-- direccion_cliente: ver direcciones propias o staff
CREATE POLICY direccion_own_or_staff_select ON public.direccion_cliente FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.cliente c
    WHERE c.id_Cliente = direccion_cliente.id_Cliente_FK
      AND (c.Cli_email = session_user_email() OR is_gerente_or_above_safe())
  )
);

CREATE POLICY direccion_staff_modify ON public.direccion_cliente FOR ALL
USING ( is_gerente_or_above_safe() )
WITH CHECK ( is_gerente_or_above_safe() );

-- pedido: cliente ve sus pedidos o staff
CREATE POLICY pedido_own_select ON public.pedido FOR SELECT
USING (
  is_gerente_or_above_safe()
  OR (session_user_email() IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.cliente c WHERE c.id_Cliente = pedido.id_Cliente_FK AND c.Cli_email = session_user_email()
  ))
);

CREATE POLICY pedido_staff_modify ON public.pedido FOR INSERT, UPDATE
WITH CHECK ( is_gerente_or_above_safe() OR is_admin_safe() );

CREATE POLICY pedido_admin_delete ON public.pedido FOR DELETE
USING ( is_admin_safe() );

-- factura: cliente propietario o staff
CREATE POLICY factura_own_or_staff_select ON public.factura FOR SELECT
USING (
  is_gerente_or_above_safe()
  OR EXISTS (
    SELECT 1 FROM public.cliente c WHERE c.id_Cliente = factura.id_Cliente_FK AND c.Cli_email = session_user_email()
  )
);

CREATE POLICY factura_staff_modify ON public.factura FOR INSERT, UPDATE
WITH CHECK ( is_gerente_or_above_safe() );

-- carrito: cliente propio y staff
CREATE POLICY carrito_own_select ON public.carrito FOR SELECT
USING (
  is_gerente_or_above_safe()
  OR EXISTS (SELECT 1 FROM public.cliente c WHERE c.id_Cliente = carrito.id_Cliente_FK AND c.Cli_email = session_user_email())
);

CREATE POLICY carrito_modify ON public.carrito FOR INSERT, UPDATE, DELETE
WITH CHECK (
  is_gerente_or_above_safe()
  OR EXISTS (SELECT 1 FROM public.cliente c WHERE c.id_Cliente = carrito.id_Cliente_FK AND c.Cli_email = session_user_email())
);

-- carrito_item: propietario por relación carrito->cliente
CREATE POLICY carrito_item_modify ON public.carrito_item FOR ALL
USING (
  is_gerente_or_above_safe()
  OR EXISTS (
    SELECT 1 FROM public.carrito c JOIN public.cliente cl ON c.id_Cliente_FK = cl.id_Cliente
    WHERE c.id_Carrito = carrito_item.id_Carrito_FK AND cl.Cli_email = session_user_email()
  )
)
WITH CHECK (
  is_gerente_or_above_safe()
  OR EXISTS (
    SELECT 1 FROM public.carrito c JOIN public.cliente cl ON c.id_Cliente_FK = cl.id_Cliente
    WHERE c.id_Carrito = carrito_item.id_Carrito_FK AND cl.Cli_email = session_user_email()
  )
);

-- lista_deseos: propietario por cliente
CREATE POLICY lista_deseos_owner ON public.lista_deseos FOR ALL
USING (
  is_gerente_or_above_safe()
  OR EXISTS (SELECT 1 FROM public.cliente c WHERE c.id_Cliente = lista_deseos.id_Cliente_FK AND c.Cli_email = session_user_email())
)
WITH CHECK (
  is_gerente_or_above_safe()
  OR EXISTS (SELECT 1 FROM public.cliente c WHERE c.id_Cliente = lista_deseos.id_Cliente_FK AND c.Cli_email = session_user_email())
);

-- 3) Mensaje final (no ejecutable): las políticas han sido recreadas con nombres de columna correctos.