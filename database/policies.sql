-- policies.sql
-- Plantilla idempotente y corregida de políticas RLS para Tienda de Videojuegos
-- Ejecutar después de schema.sql y después de functions.sql (las funciones auxiliares deben existir)
-- Recomendación: psql -U postgres -d tienda_db -f policies.sql

-- 0) Crear roles de aplicación si no existen (idempotente)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_admin') THEN
    CREATE ROLE app_admin NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user') THEN
    CREATE ROLE app_user NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOINHERIT;
  END IF;
END$$;

-- 1) Funciones auxiliares (deben existir en functions.sql)
-- session_user_email(), get_user_role_safe(p_email), is_admin_safe(), is_gerente_or_above_safe()
-- Si no existen, crea/ejecuta functions.sql antes de aplicar este archivo.

-- 2) GRANTS básicos (idempotente)
GRANT USAGE ON SCHEMA public TO app_admin, app_user, authenticated, anon;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_admin;

-- 3) Habilitar RLS y crear políticas por tabla (solo si la tabla existe)
-- Patrón: comprobar existencia de tabla, habilitar RLS, crear políticas si no existen.

-- 3.1 Catálogos públicos: lectura para todos (categoria, consola, proveedor, impuesto, metodo_pago)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='categoria') THEN
    EXECUTE 'ALTER TABLE public.categoria ENABLE ROW LEVEL SECURITY';
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='categoria' AND policyname='categoria_public_select') THEN
      EXECUTE $sql$
        CREATE POLICY categoria_public_select ON public.categoria FOR SELECT USING (true);
      $sql$;
    END IF;
  END IF;
END$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='consola') THEN
    EXECUTE 'ALTER TABLE public.consola ENABLE ROW LEVEL SECURITY';
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='consola' AND policyname='consola_public_select') THEN
      EXECUTE $sql$
        CREATE POLICY consola_public_select ON public.consola FOR SELECT USING (true);
      $sql$;
    END IF;
  END IF;
END$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='proveedor') THEN
    EXECUTE 'ALTER TABLE public.proveedor ENABLE ROW LEVEL SECURITY';
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='proveedor' AND policyname='proveedor_staff_select') THEN
      EXECUTE $sql$
        CREATE POLICY proveedor_staff_select ON public.proveedor FOR SELECT USING ( is_gerente_or_above_safe() );
      $sql$;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='proveedor' AND policyname='proveedor_admin_all') THEN
      EXECUTE $sql$
        CREATE POLICY proveedor_admin_all ON public.proveedor FOR ALL USING ( is_admin_safe() );
      $sql$;
    END IF;
  END IF;
END$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='impuesto') THEN
    EXECUTE 'ALTER TABLE public.impuesto ENABLE ROW LEVEL SECURITY';
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='impuesto' AND policyname='impuesto_public_select') THEN
      EXECUTE $sql$
        CREATE POLICY impuesto_public_select ON public.impuesto FOR SELECT USING (true);
      $sql$;
    END IF;
  END IF;
END$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='metodo_pago') THEN
    EXECUTE 'ALTER TABLE public.metodo_pago ENABLE ROW LEVEL SECURITY';
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='metodo_pago' AND policyname='metodopago_public_select') THEN
      EXECUTE $sql$
        CREATE POLICY metodopago_public_select ON public.metodo_pago FOR SELECT USING (true);
      $sql$;
    END IF;
  END IF;
END$$;

-- 3.2 Clientes y direcciones: cliente ve sus datos; staff puede gestionar
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='cliente') THEN
    EXECUTE 'ALTER TABLE public.cliente ENABLE ROW LEVEL SECURITY';

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='cliente' AND policyname='cliente_own_select') THEN
      EXECUTE $sql$
        CREATE POLICY cliente_own_select ON public.cliente FOR SELECT
        USING (
          (session_user_email() IS NOT NULL AND Cli_email = session_user_email())
          OR is_gerente_or_above_safe()
        );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='cliente' AND policyname='cliente_staff_insert') THEN
      EXECUTE $sql$
        CREATE POLICY cliente_staff_insert ON public.cliente FOR INSERT
        WITH CHECK ( is_gerente_or_above_safe() );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='cliente' AND policyname='cliente_staff_update') THEN
      EXECUTE $sql$
        CREATE POLICY cliente_staff_update ON public.cliente FOR UPDATE
        USING ( is_gerente_or_above_safe() );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='cliente' AND policyname='cliente_admin_delete') THEN
      EXECUTE $sql$
        CREATE POLICY cliente_admin_delete ON public.cliente FOR DELETE
        USING ( is_admin_safe() );
      $sql$;
    END IF;
  END IF;
END$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='direccion_cliente') THEN
    EXECUTE 'ALTER TABLE public.direccion_cliente ENABLE ROW LEVEL SECURITY';

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='direccion_cliente' AND policyname='direccion_own_or_staff_select') THEN
      EXECUTE $sql$
        CREATE POLICY direccion_own_or_staff_select ON public.direccion_cliente FOR SELECT
        USING (
          EXISTS (
            SELECT 1 FROM public.cliente c
            WHERE c.id_Cliente = direccion_cliente.id_Cliente_FK
            AND (c.Cli_email = session_user_email() OR is_gerente_or_above_safe())
          )
        );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='direccion_cliente' AND policyname='direccion_staff_modify') THEN
      EXECUTE $sql$
        CREATE POLICY direccion_staff_modify ON public.direccion_cliente FOR ALL
        USING ( is_gerente_or_above_safe() )
        WITH CHECK ( is_gerente_or_above_safe() );
      $sql$;
    END IF;
  END IF;
END$$;

-- 3.3 Pedidos y items: cliente ve sus pedidos; staff puede gestionar
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='pedido') THEN
    EXECUTE 'ALTER TABLE public.pedido ENABLE ROW LEVEL SECURITY';

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='pedido' AND policyname='pedido_own_select') THEN
      EXECUTE $sql$
        CREATE POLICY pedido_own_select ON public.pedido FOR SELECT
        USING (
          is_gerente_or_above_safe()
          OR (session_user_email() IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.cliente c WHERE c.id_Cliente = pedido.id_Cliente_FK AND c.Cli_email = session_user_email()
          ))
        );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='pedido' AND policyname='pedido_staff_modify') THEN
      EXECUTE $sql$
        CREATE POLICY pedido_staff_modify ON public.pedido FOR ALL
        USING ( is_gerente_or_above_safe() OR is_admin_safe() )
        WITH CHECK ( is_gerente_or_above_safe() OR is_admin_safe() );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='pedido' AND policyname='pedido_admin_delete') THEN
      EXECUTE $sql$
        CREATE POLICY pedido_admin_delete ON public.pedido FOR DELETE
        USING ( is_admin_safe() );
      $sql$;
    END IF;
  END IF;
END$$;

-- 3.4 Facturas y detalle_factura: cliente propietario o staff
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='factura') THEN
    EXECUTE 'ALTER TABLE public.factura ENABLE ROW LEVEL SECURITY';

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='factura' AND policyname='factura_own_or_staff_select') THEN
      EXECUTE $sql$
        CREATE POLICY factura_own_or_staff_select ON public.factura FOR SELECT
        USING (
          is_gerente_or_above_safe()
          OR EXISTS (
            SELECT 1 FROM public.cliente c WHERE c.id_Cliente = factura.id_Cliente_FK AND c.Cli_email = session_user_email()
          )
        );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='factura' AND policyname='factura_staff_modify') THEN
      EXECUTE $sql$
        CREATE POLICY factura_staff_modify ON public.factura FOR ALL
        USING ( is_gerente_or_above_safe() )
        WITH CHECK ( is_gerente_or_above_safe() );
      $sql$;
    END IF;
  END IF;
END$$;

-- 3.5 Carrito, carrito_item y lista_deseos: cliente propio y staff
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='carrito') THEN
    EXECUTE 'ALTER TABLE public.carrito ENABLE ROW LEVEL SECURITY';

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='carrito' AND policyname='carrito_own_select') THEN
      EXECUTE $sql$
        CREATE POLICY carrito_own_select ON public.carrito FOR SELECT
        USING (
          is_gerente_or_above_safe()
          OR EXISTS (SELECT 1 FROM public.cliente c WHERE c.id_Cliente = carrito.id_Cliente_FK AND c.Cli_email = session_user_email())
        );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='carrito' AND policyname='carrito_modify') THEN
      EXECUTE $sql$
        CREATE POLICY carrito_modify ON public.carrito FOR ALL
        USING (
          is_gerente_or_above_safe()
          OR EXISTS (SELECT 1 FROM public.cliente c WHERE c.id_Cliente = carrito.id_Cliente_FK AND c.Cli_email = session_user_email())
        )
        WITH CHECK (
          is_gerente_or_above_safe()
          OR EXISTS (SELECT 1 FROM public.cliente c WHERE c.id_Cliente = carrito.id_Cliente_FK AND c.Cli_email = session_user_email())
        );
      $sql$;
    END IF;
  END IF;
END$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='carrito_item') THEN
    EXECUTE 'ALTER TABLE public.carrito_item ENABLE ROW LEVEL SECURITY';

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='carrito_item' AND policyname='carrito_item_modify') THEN
      EXECUTE $sql$
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
      $sql$;
    END IF;
  END IF;
END$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='lista_deseos') THEN
    EXECUTE 'ALTER TABLE public.lista_deseos ENABLE ROW LEVEL SECURITY';

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='lista_deseos' AND policyname='lista_deseos_owner') THEN
      EXECUTE $sql$
        CREATE POLICY lista_deseos_owner ON public.lista_deseos FOR ALL
        USING (
          is_gerente_or_above_safe()
          OR EXISTS (SELECT 1 FROM public.cliente c WHERE c.id_Cliente = lista_deseos.id_Cliente_FK AND c.Cli_email = session_user_email())
        )
        WITH CHECK (
          is_gerente_or_above_safe()
          OR EXISTS (SELECT 1 FROM public.cliente c WHERE c.id_Cliente = lista_deseos.id_Cliente_FK AND c.Cli_email = session_user_email())
        );
      $sql$;
    END IF;
  END IF;
END$$;

-- 3.6 Usuarios y roles: protección estricta
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='rol') THEN
    EXECUTE 'ALTER TABLE public.rol ENABLE ROW LEVEL SECURITY';
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='rol' AND policyname='rol_admin_only') THEN
      EXECUTE $sql$
        CREATE POLICY rol_admin_only ON public.rol FOR ALL USING ( is_admin_safe() );
      $sql$;
    END IF;
  END IF;
END$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='usuario') THEN
    EXECUTE 'ALTER TABLE public.usuario ENABLE ROW LEVEL SECURITY';
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='usuario' AND policyname='usuario_admin_or_self') THEN
      EXECUTE $sql$
        CREATE POLICY usuario_admin_or_self ON public.usuario FOR SELECT
        USING (
          is_admin_safe()
          OR email = session_user_email()
        );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='usuario' AND policyname='usuario_admin_insert') THEN
      EXECUTE $sql$
        CREATE POLICY usuario_admin_insert ON public.usuario FOR INSERT WITH CHECK ( is_admin_safe() );
      $sql$;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='usuario' AND policyname='usuario_admin_update') THEN
      EXECUTE $sql$
        CREATE POLICY usuario_admin_update ON public.usuario FOR UPDATE USING ( is_admin_safe() OR email = session_user_email() );
      $sql$;
    END IF;
  END IF;
END$$;

-- 4) GRANTS finos (ejemplo, idempotente)
GRANT SELECT ON public.categoria, public.consola, public.impuesto, public.metodo_pago TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.carrito, public.carrito_item, public.lista_deseos TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pedido, public.pedido_item TO app_user, app_admin;

-- 5) Notas y recomendaciones
-- - Para pruebas en psql o desde la app:
--     SET LOCAL app.current_user_email = 'juan.perez@example.com';
-- - Si usas Supabase y prefieres auth.email(), reemplaza session_user_email() por auth.email() en las políticas.
-- - Para desactivar RLS rápidamente:
--     ALTER TABLE public.pedido DISABLE ROW LEVEL SECURITY;
-- - Para eliminar una política:
--     DROP POLICY IF EXISTS policy_name ON schema.table;

-- Fin de policies.sql