-- 01_tables.sql
-- Создание таблиц для baza-stat-karat

-- Таблица orders
CREATE TABLE public.orders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    order_number text NOT NULL UNIQUE,
    calculator_type text NOT NULL,
    calculator_version text NOT NULL,
    hourly_rate numeric(10,2) NOT NULL,
    theoretical_time_calc_hours numeric(10,2) NOT NULL,
    additional_work_cost numeric(10,2),
    additional_work_time_hours numeric(10,2),
    theoretical_time_total_hours numeric(10,2) NOT NULL,
    complexity_level int,
    is_training_data boolean NOT NULL DEFAULT false,
    is_outlier boolean NOT NULL DEFAULT false
);

-- Таблица order_parameters
CREATE TABLE public.order_parameters (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    countertop_sqm numeric(10,2) NOT NULL DEFAULT 0,
    edge_radius_m numeric(10,2) NOT NULL DEFAULT 0,
    sink_round_pcs int NOT NULL DEFAULT 0,
    sink_rect_pcs int NOT NULL DEFAULT 0,
    thickness_mm int NOT NULL DEFAULT 0
);

-- Таблица operations_dictionary
CREATE TABLE public.operations_dictionary (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text NOT NULL UNIQUE,
    name text NOT NULL,
    description text,
    default_duration_min int NOT NULL,
    is_active boolean NOT NULL DEFAULT true
);

-- Таблица order_operations
CREATE TABLE public.order_operations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    operation_id uuid NOT NULL REFERENCES public.operations_dictionary(id),
    theoretical_duration_min int NOT NULL,
    source text NOT NULL
);

-- Таблица masters
CREATE TABLE public.masters (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    name text NOT NULL,
    qualification_level int NOT NULL,
    hourly_rate numeric(10,2),
    is_active boolean NOT NULL DEFAULT true
);

-- Таблица order_execution
CREATE TABLE public.order_execution (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid NOT NULL REFERENCES public.orders(id),
    master_id uuid NOT NULL REFERENCES public.masters(id),
    planned_start_at timestamptz,
    planned_end_at timestamptz,
    fact_start_at timestamptz NOT NULL,
    fact_end_at timestamptz,
    status text NOT NULL,
    comment text,
    sla_hours numeric(10,2)
);

-- Таблица pauses
CREATE TABLE public.pauses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_execution_id uuid NOT NULL REFERENCES public.order_execution(id) ON DELETE CASCADE,
    paused_at timestamptz NOT NULL,
    resumed_at timestamptz,
    reason text NOT NULL,
    duration_min int
);

-- Таблица qualification_history
CREATE TABLE public.qualification_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    master_id uuid NOT NULL REFERENCES public.masters(id) ON DELETE CASCADE,
    changed_at timestamptz NOT NULL,
    old_level int NOT NULL,
    new_level int NOT NULL,
    reason text,
    initiator text
);

-- Индексы
CREATE INDEX idx_order_parameters_order_id ON public.order_parameters(order_id);
CREATE INDEX idx_order_operations_order_id ON public.order_operations(order_id);
CREATE INDEX idx_order_operations_operation_id ON public.order_operations(operation_id);
CREATE INDEX idx_order_execution_order_id ON public.order_execution(order_id);
CREATE INDEX idx_order_execution_master_id ON public.order_execution(master_id);
CREATE INDEX idx_pauses_order_execution_id ON public.pauses(order_execution_id);
CREATE INDEX idx_qualification_history_master_id ON public.qualification_history(master_id);

-- Триггеры для updated_at
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER set_order_parameters_updated_at
    BEFORE UPDATE ON public.order_parameters
    FOR EACH ROW
    EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER set_order_operations_updated_at
    BEFORE UPDATE ON public.order_operations
    FOR EACH ROW
    EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER set_masters_updated_at
    BEFORE UPDATE ON public.masters
    FOR EACH ROW
    EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER set_order_execution_updated_at
    BEFORE UPDATE ON public.order_execution
    FOR EACH ROW
    EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER set_pauses_updated_at
    BEFORE UPDATE ON public.pauses
    FOR EACH ROW
    EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER set_qualification_history_updated_at
    BEFORE UPDATE ON public.qualification_history
    FOR EACH ROW
    EXECUTE FUNCTION public.set_current_timestamp_updated_at();