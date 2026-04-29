--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Homebrew)
-- Dumped by pg_dump version 14.18 (Homebrew)

-- Started on 2026-04-19 21:25:01 +0530

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 876 (class 1247 OID 16491)
-- Name: userstatus; Type: TYPE; Schema: public; Owner: senithdamiru
--

CREATE TYPE public.userstatus AS ENUM (
    'Active',
    'On Leave',
    'Inactive'
);


ALTER TYPE public.userstatus OWNER TO senithdamiru;

--
-- TOC entry 260 (class 1255 OID 16722)
-- Name: update_pumps_updated_at(); Type: FUNCTION; Schema: public; Owner: senithdamiru
--

CREATE FUNCTION public.update_pumps_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;


ALTER FUNCTION public.update_pumps_updated_at() OWNER TO senithdamiru;

--
-- TOC entry 259 (class 1255 OID 16661)
-- Name: update_suppliers_updated_at(); Type: FUNCTION; Schema: public; Owner: senithdamiru
--

CREATE FUNCTION public.update_suppliers_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_suppliers_updated_at() OWNER TO senithdamiru;

--
-- TOC entry 258 (class 1255 OID 16592)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: senithdamiru
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO senithdamiru;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 242 (class 1259 OID 16783)
-- Name: credit_accounts; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.credit_accounts (
    account_id integer NOT NULL,
    account_name character varying(150) NOT NULL,
    contact_person character varying(100),
    contact_phone character varying(30),
    contact_email character varying(120),
    address text,
    credit_limit numeric(12,2) DEFAULT 0 NOT NULL,
    outstanding_balance numeric(12,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT credit_accounts_status_check CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Suspended'::character varying, 'Closed'::character varying])::text[])))
);


ALTER TABLE public.credit_accounts OWNER TO senithdamiru;

--
-- TOC entry 241 (class 1259 OID 16782)
-- Name: credit_accounts_account_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

ALTER TABLE public.credit_accounts ALTER COLUMN account_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.credit_accounts_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 246 (class 1259 OID 16840)
-- Name: credit_payments; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.credit_payments (
    payment_id integer NOT NULL,
    payment_date date NOT NULL,
    account_id integer NOT NULL,
    user_id integer,
    amount numeric(12,2) NOT NULL,
    payment_method character varying(30) DEFAULT 'Cash'::character varying NOT NULL,
    reference_number character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT credit_payments_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['Cash'::character varying, 'Cheque'::character varying, 'Bank Transfer'::character varying, 'Online'::character varying])::text[])))
);


ALTER TABLE public.credit_payments OWNER TO senithdamiru;

--
-- TOC entry 245 (class 1259 OID 16839)
-- Name: credit_payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

ALTER TABLE public.credit_payments ALTER COLUMN payment_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.credit_payments_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 244 (class 1259 OID 16811)
-- Name: credit_sales; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.credit_sales (
    credit_sale_id integer NOT NULL,
    sale_date date NOT NULL,
    account_id integer NOT NULL,
    pump_id integer NOT NULL,
    shift_id integer,
    user_id integer,
    vehicle_number character varying(30),
    litres_sold numeric(12,2) NOT NULL,
    price_per_litre numeric(10,2) NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    fuel_type character varying(50),
    reference character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.credit_sales OWNER TO senithdamiru;

--
-- TOC entry 243 (class 1259 OID 16810)
-- Name: credit_sales_credit_sale_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

ALTER TABLE public.credit_sales ALTER COLUMN credit_sale_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.credit_sales_credit_sale_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 240 (class 1259 OID 16753)
-- Name: daily_sales; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.daily_sales (
    sale_id integer NOT NULL,
    sale_date date NOT NULL,
    pump_id integer NOT NULL,
    shift_id integer,
    user_id integer,
    record_type character varying(20) DEFAULT 'shift'::character varying NOT NULL,
    opening_meter numeric(12,2),
    closing_meter numeric(12,2),
    litres_sold numeric(12,2) NOT NULL,
    price_per_litre numeric(10,2) NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    payment_method character varying(20) DEFAULT 'Cash'::character varying NOT NULL,
    shift_period character varying(20) DEFAULT 'Morning'::character varying NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT daily_sales_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['Cash'::character varying, 'Card'::character varying, 'Mobile'::character varying, 'Credit'::character varying])::text[]))),
    CONSTRAINT daily_sales_record_type_check CHECK (((record_type)::text = ANY ((ARRAY['shift'::character varying, 'transaction'::character varying])::text[]))),
    CONSTRAINT daily_sales_shift_period_check CHECK (((shift_period)::text = ANY ((ARRAY['Morning'::character varying, 'Evening'::character varying, 'Night'::character varying])::text[])))
);


ALTER TABLE public.daily_sales OWNER TO senithdamiru;

--
-- TOC entry 239 (class 1259 OID 16752)
-- Name: daily_sales_sale_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

ALTER TABLE public.daily_sales ALTER COLUMN sale_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.daily_sales_sale_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 216 (class 1259 OID 16537)
-- Name: expenses; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.expenses (
    expense_id integer NOT NULL,
    title character varying(100) NOT NULL,
    category character varying(50) NOT NULL,
    amount numeric(10,2) NOT NULL,
    payment_method character varying(50) NOT NULL,
    description text,
    expense_date date DEFAULT CURRENT_DATE NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT expenses_category_check CHECK (((category)::text = ANY ((ARRAY['Fuel'::character varying, 'Utilities'::character varying, 'Maintenance'::character varying, 'Salaries'::character varying, 'Other'::character varying])::text[])))
);


ALTER TABLE public.expenses OWNER TO senithdamiru;

--
-- TOC entry 215 (class 1259 OID 16536)
-- Name: expenses_expense_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.expenses_expense_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.expenses_expense_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4028 (class 0 OID 0)
-- Dependencies: 215
-- Name: expenses_expense_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.expenses_expense_id_seq OWNED BY public.expenses.expense_id;


--
-- TOC entry 256 (class 1259 OID 16911)
-- Name: fire_events; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.fire_events (
    id integer NOT NULL,
    device_id character varying(50) NOT NULL,
    fuel_level_pct double precision,
    fuel_level_l double precision,
    temperature double precision,
    pump_activated boolean DEFAULT false,
    status character varying(50),
    firebase_event_key character varying(100),
    firebase_timestamp integer,
    recorded_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.fire_events OWNER TO senithdamiru;

--
-- TOC entry 255 (class 1259 OID 16910)
-- Name: fire_events_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.fire_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fire_events_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4029 (class 0 OID 0)
-- Dependencies: 255
-- Name: fire_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.fire_events_id_seq OWNED BY public.fire_events.id;


--
-- TOC entry 248 (class 1259 OID 16861)
-- Name: fuel_deliveries; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.fuel_deliveries (
    delivery_id integer NOT NULL,
    delivery_date date NOT NULL,
    supplier_id integer,
    invoice_number character varying(100),
    fuel_type character varying(50) NOT NULL,
    litres_delivered numeric(12,2) NOT NULL,
    price_per_litre numeric(10,2) NOT NULL,
    total_cost numeric(12,2) NOT NULL,
    delivery_vehicle character varying(100),
    driver_name character varying(100),
    received_by character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fuel_deliveries OWNER TO senithdamiru;

--
-- TOC entry 247 (class 1259 OID 16860)
-- Name: fuel_deliveries_delivery_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

ALTER TABLE public.fuel_deliveries ALTER COLUMN delivery_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.fuel_deliveries_delivery_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 238 (class 1259 OID 16726)
-- Name: fuel_prices; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.fuel_prices (
    price_id integer NOT NULL,
    fuel_type character varying(50) NOT NULL,
    price_per_litre numeric(10,2) NOT NULL,
    effective_date date NOT NULL,
    updated_by character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fuel_prices OWNER TO senithdamiru;

--
-- TOC entry 237 (class 1259 OID 16725)
-- Name: fuel_prices_price_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

ALTER TABLE public.fuel_prices ALTER COLUMN price_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.fuel_prices_price_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 252 (class 1259 OID 16884)
-- Name: fuel_tanks; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.fuel_tanks (
    id integer NOT NULL,
    tank_id character varying(20) NOT NULL,
    fuel_type character varying(50) NOT NULL,
    capacity_l double precision NOT NULL,
    current_stock_l double precision DEFAULT 0.0 NOT NULL,
    low_stock_threshold_l double precision DEFAULT 0.0 NOT NULL,
    iot_device_id character varying(50),
    location character varying(100),
    notes text,
    last_updated timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.fuel_tanks OWNER TO senithdamiru;

--
-- TOC entry 251 (class 1259 OID 16883)
-- Name: fuel_tanks_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.fuel_tanks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fuel_tanks_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4030 (class 0 OID 0)
-- Dependencies: 251
-- Name: fuel_tanks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.fuel_tanks_id_seq OWNED BY public.fuel_tanks.id;


--
-- TOC entry 230 (class 1259 OID 16639)
-- Name: invoice_payment_links; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.invoice_payment_links (
    link_id integer NOT NULL,
    invoice_id integer NOT NULL,
    payment_id integer NOT NULL,
    allocated_amount double precision NOT NULL
);


ALTER TABLE public.invoice_payment_links OWNER TO senithdamiru;

--
-- TOC entry 229 (class 1259 OID 16638)
-- Name: invoice_payment_links_link_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.invoice_payment_links_link_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.invoice_payment_links_link_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4031 (class 0 OID 0)
-- Dependencies: 229
-- Name: invoice_payment_links_link_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.invoice_payment_links_link_id_seq OWNED BY public.invoice_payment_links.link_id;


--
-- TOC entry 254 (class 1259 OID 16899)
-- Name: iot_readings; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.iot_readings (
    id integer NOT NULL,
    device_id character varying(50) NOT NULL,
    fuel_level_pct double precision NOT NULL,
    fuel_level_l double precision NOT NULL,
    temperature double precision,
    distance double precision,
    fire_detected boolean DEFAULT false,
    pump_running boolean DEFAULT false,
    in_cooldown boolean DEFAULT false,
    alert_level character varying(20),
    recorded_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.iot_readings OWNER TO senithdamiru;

--
-- TOC entry 253 (class 1259 OID 16898)
-- Name: iot_readings_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.iot_readings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.iot_readings_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4032 (class 0 OID 0)
-- Dependencies: 253
-- Name: iot_readings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.iot_readings_id_seq OWNED BY public.iot_readings.id;


--
-- TOC entry 222 (class 1259 OID 16578)
-- Name: lubricant_purchases; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.lubricant_purchases (
    purchase_id integer NOT NULL,
    lubricant_id integer NOT NULL,
    supplier_name character varying(100) NOT NULL,
    quantity double precision NOT NULL,
    cost_per_unit double precision NOT NULL,
    total_cost double precision NOT NULL,
    invoice_ref character varying(100),
    notes text,
    purchase_date date NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.lubricant_purchases OWNER TO senithdamiru;

--
-- TOC entry 221 (class 1259 OID 16577)
-- Name: lubricant_purchases_purchase_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.lubricant_purchases_purchase_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lubricant_purchases_purchase_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4033 (class 0 OID 0)
-- Dependencies: 221
-- Name: lubricant_purchases_purchase_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.lubricant_purchases_purchase_id_seq OWNED BY public.lubricant_purchases.purchase_id;


--
-- TOC entry 220 (class 1259 OID 16563)
-- Name: lubricant_sales; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.lubricant_sales (
    sale_id integer NOT NULL,
    lubricant_id integer NOT NULL,
    customer_name character varying(100),
    quantity double precision NOT NULL,
    unit_price double precision NOT NULL,
    total_amount double precision NOT NULL,
    payment_method character varying(50) NOT NULL,
    notes text,
    sale_date date NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.lubricant_sales OWNER TO senithdamiru;

--
-- TOC entry 219 (class 1259 OID 16562)
-- Name: lubricant_sales_sale_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.lubricant_sales_sale_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lubricant_sales_sale_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4034 (class 0 OID 0)
-- Dependencies: 219
-- Name: lubricant_sales_sale_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.lubricant_sales_sale_id_seq OWNED BY public.lubricant_sales.sale_id;


--
-- TOC entry 218 (class 1259 OID 16550)
-- Name: lubricants; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.lubricants (
    lubricant_id integer NOT NULL,
    name character varying(100) NOT NULL,
    brand character varying(100) NOT NULL,
    grade character varying(50) NOT NULL,
    category character varying(50) NOT NULL,
    unit_type character varying(20) NOT NULL,
    selling_price double precision NOT NULL,
    cost_price double precision NOT NULL,
    stock_qty double precision DEFAULT 0 NOT NULL,
    low_stock_threshold double precision DEFAULT 10 NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.lubricants OWNER TO senithdamiru;

--
-- TOC entry 217 (class 1259 OID 16549)
-- Name: lubricants_lubricant_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.lubricants_lubricant_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lubricants_lubricant_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4035 (class 0 OID 0)
-- Dependencies: 217
-- Name: lubricants_lubricant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.lubricants_lubricant_id_seq OWNED BY public.lubricants.lubricant_id;


--
-- TOC entry 236 (class 1259 OID 16701)
-- Name: pump_faults; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.pump_faults (
    fault_id integer NOT NULL,
    pump_id integer NOT NULL,
    fault_date date NOT NULL,
    reported_by character varying(100) NOT NULL,
    description text NOT NULL,
    severity character varying(20) DEFAULT 'Medium'::character varying,
    status character varying(20) DEFAULT 'Open'::character varying,
    resolved_date date,
    notes text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.pump_faults OWNER TO senithdamiru;

--
-- TOC entry 235 (class 1259 OID 16700)
-- Name: pump_faults_fault_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.pump_faults_fault_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pump_faults_fault_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4036 (class 0 OID 0)
-- Dependencies: 235
-- Name: pump_faults_fault_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.pump_faults_fault_id_seq OWNED BY public.pump_faults.fault_id;


--
-- TOC entry 234 (class 1259 OID 16685)
-- Name: pump_maintenances; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.pump_maintenances (
    maintenance_id integer NOT NULL,
    pump_id integer NOT NULL,
    maintenance_date date NOT NULL,
    technician character varying(100) NOT NULL,
    work_done text NOT NULL,
    cost double precision DEFAULT 0,
    next_scheduled date,
    notes text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.pump_maintenances OWNER TO senithdamiru;

--
-- TOC entry 233 (class 1259 OID 16684)
-- Name: pump_maintenances_maintenance_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.pump_maintenances_maintenance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pump_maintenances_maintenance_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4037 (class 0 OID 0)
-- Dependencies: 233
-- Name: pump_maintenances_maintenance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.pump_maintenances_maintenance_id_seq OWNED BY public.pump_maintenances.maintenance_id;


--
-- TOC entry 232 (class 1259 OID 16664)
-- Name: pumps; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.pumps (
    pump_id integer NOT NULL,
    pump_number character varying(20) NOT NULL,
    pump_name character varying(100) NOT NULL,
    fuel_type character varying(50) NOT NULL,
    status character varying(30) DEFAULT 'Active'::character varying NOT NULL,
    total_dispensed_l double precision DEFAULT 0 NOT NULL,
    last_maintenance_date date,
    next_maintenance_date date,
    maintenance_warning_days integer DEFAULT 7,
    operator_id integer,
    notes text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.pumps OWNER TO senithdamiru;

--
-- TOC entry 231 (class 1259 OID 16663)
-- Name: pumps_pump_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.pumps_pump_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pumps_pump_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4038 (class 0 OID 0)
-- Dependencies: 231
-- Name: pumps_pump_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.pumps_pump_id_seq OWNED BY public.pumps.pump_id;


--
-- TOC entry 210 (class 1259 OID 16480)
-- Name: roles; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.roles (
    roleid integer NOT NULL,
    rolename character varying(50) NOT NULL,
    description text
);


ALTER TABLE public.roles OWNER TO senithdamiru;

--
-- TOC entry 209 (class 1259 OID 16479)
-- Name: roles_roleid_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.roles_roleid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_roleid_seq OWNER TO senithdamiru;

--
-- TOC entry 4039 (class 0 OID 0)
-- Dependencies: 209
-- Name: roles_roleid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.roles_roleid_seq OWNED BY public.roles.roleid;


--
-- TOC entry 214 (class 1259 OID 16518)
-- Name: staff_shifts; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.staff_shifts (
    id integer NOT NULL,
    user_id integer,
    role_id integer,
    shift_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    notes text
);


ALTER TABLE public.staff_shifts OWNER TO senithdamiru;

--
-- TOC entry 213 (class 1259 OID 16517)
-- Name: staff_shifts_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.staff_shifts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.staff_shifts_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4040 (class 0 OID 0)
-- Dependencies: 213
-- Name: staff_shifts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.staff_shifts_id_seq OWNED BY public.staff_shifts.id;


--
-- TOC entry 257 (class 1259 OID 16922)
-- Name: station_settings; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.station_settings (
    id integer DEFAULT 1 NOT NULL,
    name character varying(150) DEFAULT ''::character varying NOT NULL,
    address text,
    phone character varying(30),
    email character varying(120),
    license_number character varying(100),
    logo_path character varying(255),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.station_settings OWNER TO senithdamiru;

--
-- TOC entry 226 (class 1259 OID 16608)
-- Name: supplier_invoices; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.supplier_invoices (
    invoice_id integer NOT NULL,
    supplier_id integer NOT NULL,
    invoice_ref character varying(100) NOT NULL,
    category character varying(30) NOT NULL,
    description text,
    amount double precision NOT NULL,
    invoice_date date NOT NULL,
    due_date date,
    status character varying(20) DEFAULT 'Unpaid'::character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.supplier_invoices OWNER TO senithdamiru;

--
-- TOC entry 225 (class 1259 OID 16607)
-- Name: supplier_invoices_invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.supplier_invoices_invoice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.supplier_invoices_invoice_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4041 (class 0 OID 0)
-- Dependencies: 225
-- Name: supplier_invoices_invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.supplier_invoices_invoice_id_seq OWNED BY public.supplier_invoices.invoice_id;


--
-- TOC entry 228 (class 1259 OID 16624)
-- Name: supplier_payments; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.supplier_payments (
    payment_id integer NOT NULL,
    supplier_id integer NOT NULL,
    amount double precision NOT NULL,
    payment_method character varying(50) NOT NULL,
    reference character varying(100),
    notes text,
    payment_date date NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.supplier_payments OWNER TO senithdamiru;

--
-- TOC entry 227 (class 1259 OID 16623)
-- Name: supplier_payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.supplier_payments_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.supplier_payments_payment_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4042 (class 0 OID 0)
-- Dependencies: 227
-- Name: supplier_payments_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.supplier_payments_payment_id_seq OWNED BY public.supplier_payments.payment_id;


--
-- TOC entry 224 (class 1259 OID 16595)
-- Name: suppliers; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.suppliers (
    supplier_id integer NOT NULL,
    name character varying(120) NOT NULL,
    type character varying(30) NOT NULL,
    contact_person character varying(100),
    phone character varying(30),
    email character varying(120),
    address text,
    tax_id character varying(60),
    bank_details text,
    credit_days integer DEFAULT 30,
    notes text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.suppliers OWNER TO senithdamiru;

--
-- TOC entry 223 (class 1259 OID 16594)
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.suppliers_supplier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.suppliers_supplier_id_seq OWNER TO senithdamiru;

--
-- TOC entry 4043 (class 0 OID 0)
-- Dependencies: 223
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.suppliers_supplier_id_seq OWNED BY public.suppliers.supplier_id;


--
-- TOC entry 212 (class 1259 OID 16498)
-- Name: users; Type: TABLE; Schema: public; Owner: senithdamiru
--

CREATE TABLE public.users (
    userid integer NOT NULL,
    fullname character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    phonenumber character varying(20),
    passwordhash text NOT NULL,
    roleid integer NOT NULL,
    status public.userstatus DEFAULT 'Active'::public.userstatus,
    createdat timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    empno character varying(20),
    profileimage character varying(255)
);


ALTER TABLE public.users OWNER TO senithdamiru;

--
-- TOC entry 211 (class 1259 OID 16497)
-- Name: users_userid_seq; Type: SEQUENCE; Schema: public; Owner: senithdamiru
--

CREATE SEQUENCE public.users_userid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_userid_seq OWNER TO senithdamiru;

--
-- TOC entry 4044 (class 0 OID 0)
-- Dependencies: 211
-- Name: users_userid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: senithdamiru
--

ALTER SEQUENCE public.users_userid_seq OWNED BY public.users.userid;


--
-- TOC entry 250 (class 1259 OID 16878)
-- Name: v_credit_balances; Type: VIEW; Schema: public; Owner: senithdamiru
--

CREATE VIEW public.v_credit_balances AS
 SELECT ca.account_id,
    ca.account_name,
    ca.credit_limit,
    COALESCE(sum(cs.total_amount), (0)::numeric) AS totalsales,
    COALESCE(sum(cp.amount), (0)::numeric) AS totalpaid,
    (COALESCE(sum(cs.total_amount), (0)::numeric) - COALESCE(sum(cp.amount), (0)::numeric)) AS outstanding,
    ca.status
   FROM ((public.credit_accounts ca
     LEFT JOIN public.credit_sales cs ON ((cs.account_id = ca.account_id)))
     LEFT JOIN public.credit_payments cp ON ((cp.account_id = ca.account_id)))
  GROUP BY ca.account_id, ca.account_name, ca.credit_limit, ca.status;


ALTER TABLE public.v_credit_balances OWNER TO senithdamiru;

--
-- TOC entry 249 (class 1259 OID 16874)
-- Name: v_daily_revenue; Type: VIEW; Schema: public; Owner: senithdamiru
--

CREATE VIEW public.v_daily_revenue AS
 SELECT daily_sales.sale_date,
    sum(daily_sales.total_amount) AS cashrevenue,
    count(daily_sales.sale_id) AS transactions,
    sum(daily_sales.litres_sold) AS totallitres
   FROM public.daily_sales
  GROUP BY daily_sales.sale_date
  ORDER BY daily_sales.sale_date DESC;


ALTER TABLE public.v_daily_revenue OWNER TO senithdamiru;

--
-- TOC entry 3661 (class 2604 OID 16540)
-- Name: expenses expense_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.expenses ALTER COLUMN expense_id SET DEFAULT nextval('public.expenses_expense_id_seq'::regclass);


--
-- TOC entry 3729 (class 2604 OID 16914)
-- Name: fire_events id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fire_events ALTER COLUMN id SET DEFAULT nextval('public.fire_events_id_seq'::regclass);


--
-- TOC entry 3719 (class 2604 OID 16887)
-- Name: fuel_tanks id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fuel_tanks ALTER COLUMN id SET DEFAULT nextval('public.fuel_tanks_id_seq'::regclass);


--
-- TOC entry 3685 (class 2604 OID 16642)
-- Name: invoice_payment_links link_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.invoice_payment_links ALTER COLUMN link_id SET DEFAULT nextval('public.invoice_payment_links_link_id_seq'::regclass);


--
-- TOC entry 3724 (class 2604 OID 16902)
-- Name: iot_readings id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.iot_readings ALTER COLUMN id SET DEFAULT nextval('public.iot_readings_id_seq'::regclass);


--
-- TOC entry 3673 (class 2604 OID 16581)
-- Name: lubricant_purchases purchase_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.lubricant_purchases ALTER COLUMN purchase_id SET DEFAULT nextval('public.lubricant_purchases_purchase_id_seq'::regclass);


--
-- TOC entry 3671 (class 2604 OID 16566)
-- Name: lubricant_sales sale_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.lubricant_sales ALTER COLUMN sale_id SET DEFAULT nextval('public.lubricant_sales_sale_id_seq'::regclass);


--
-- TOC entry 3666 (class 2604 OID 16553)
-- Name: lubricants lubricant_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.lubricants ALTER COLUMN lubricant_id SET DEFAULT nextval('public.lubricants_lubricant_id_seq'::regclass);


--
-- TOC entry 3695 (class 2604 OID 16704)
-- Name: pump_faults fault_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pump_faults ALTER COLUMN fault_id SET DEFAULT nextval('public.pump_faults_fault_id_seq'::regclass);


--
-- TOC entry 3692 (class 2604 OID 16688)
-- Name: pump_maintenances maintenance_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pump_maintenances ALTER COLUMN maintenance_id SET DEFAULT nextval('public.pump_maintenances_maintenance_id_seq'::regclass);


--
-- TOC entry 3686 (class 2604 OID 16667)
-- Name: pumps pump_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pumps ALTER COLUMN pump_id SET DEFAULT nextval('public.pumps_pump_id_seq'::regclass);


--
-- TOC entry 3656 (class 2604 OID 16483)
-- Name: roles roleid; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.roles ALTER COLUMN roleid SET DEFAULT nextval('public.roles_roleid_seq'::regclass);


--
-- TOC entry 3660 (class 2604 OID 16521)
-- Name: staff_shifts id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.staff_shifts ALTER COLUMN id SET DEFAULT nextval('public.staff_shifts_id_seq'::regclass);


--
-- TOC entry 3680 (class 2604 OID 16611)
-- Name: supplier_invoices invoice_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.supplier_invoices ALTER COLUMN invoice_id SET DEFAULT nextval('public.supplier_invoices_invoice_id_seq'::regclass);


--
-- TOC entry 3683 (class 2604 OID 16627)
-- Name: supplier_payments payment_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.supplier_payments ALTER COLUMN payment_id SET DEFAULT nextval('public.supplier_payments_payment_id_seq'::regclass);


--
-- TOC entry 3675 (class 2604 OID 16598)
-- Name: suppliers supplier_id; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN supplier_id SET DEFAULT nextval('public.suppliers_supplier_id_seq'::regclass);


--
-- TOC entry 3657 (class 2604 OID 16501)
-- Name: users userid; Type: DEFAULT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.users ALTER COLUMN userid SET DEFAULT nextval('public.users_userid_seq'::regclass);


--
-- TOC entry 4009 (class 0 OID 16783)
-- Dependencies: 242
-- Data for Name: credit_accounts; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.credit_accounts OVERRIDING SYSTEM VALUE VALUES (1, 'Department of Health Services', 'Mr. Kamal Perera', '0112-345678', 'kamal@health.gov.lk', 'Colombo 10', 500000.00, 87500.00, 'Active', NULL, '2026-03-04 17:17:27.577022', '2026-03-04 17:17:27.577022');
INSERT INTO public.credit_accounts OVERRIDING SYSTEM VALUE VALUES (2, 'Sri Lanka Police - Negombo', 'IP Nimal Silva', '0312-222333', 'negombo@police.gov.lk', 'Negombo', 300000.00, 145200.00, 'Active', NULL, '2026-03-04 17:17:27.577022', '2026-03-04 17:17:27.577022');
INSERT INTO public.credit_accounts OVERRIDING SYSTEM VALUE VALUES (3, 'Provincial Road Development', 'Eng. Saman Wijeya', '0312-445566', 'prd@roads.gov.lk', 'Gampaha', 400000.00, 62000.00, 'Active', NULL, '2026-03-04 17:17:27.577022', '2026-03-04 17:17:27.577022');
INSERT INTO public.credit_accounts OVERRIDING SYSTEM VALUE VALUES (4, 'Negombo Municipal Council', 'Mr. Ranjith Dias', '0312-223344', 'info@negombomun.lk', 'Negombo', 250000.00, 0.00, 'Active', NULL, '2026-03-04 17:17:27.577022', '2026-03-04 17:17:27.577022');
INSERT INTO public.credit_accounts OVERRIDING SYSTEM VALUE VALUES (5, 'Sri Lanka Navy - Logistic Div', 'Lt. Cmdr. Bandara', '0112-987654', 'log@navy.lk', 'Colombo 01', 600000.00, 231000.00, 'Active', NULL, '2026-03-04 17:17:27.577022', '2026-03-04 17:17:27.577022');
INSERT INTO public.credit_accounts OVERRIDING SYSTEM VALUE VALUES (6, 'test', 'harin gayanrtha', '0706696269', 'email@gov.lk', 'ella
sri lanka', 10000.00, 0.00, 'Active', '', '2026-04-13 11:38:12.798461', '2026-04-13 16:13:55.114681');


--
-- TOC entry 4013 (class 0 OID 16840)
-- Dependencies: 246
-- Data for Name: credit_payments; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (1, '2026-01-10', 1, NULL, 100000.00, 'Cheque', 'CHQ-2026-001', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (2, '2026-01-15', 2, NULL, 150000.00, 'Bank Transfer', 'TRF-2026-001', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (3, '2026-01-20', 3, NULL, 80000.00, 'Bank Transfer', 'TRF-2026-002', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (4, '2026-01-25', 5, NULL, 200000.00, 'Cheque', 'CHQ-2026-002', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (5, '2026-02-05', 1, NULL, 120000.00, 'Bank Transfer', 'TRF-2026-003', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (6, '2026-02-10', 2, NULL, 180000.00, 'Cheque', 'CHQ-2026-003', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (7, '2026-02-15', 4, NULL, 50000.00, 'Cash', NULL, NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (8, '2026-02-20', 3, NULL, 100000.00, 'Bank Transfer', 'TRF-2026-004', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (9, '2026-02-25', 5, NULL, 250000.00, 'Bank Transfer', 'TRF-2026-005', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (10, '2026-03-05', 1, NULL, 150000.00, 'Cheque', 'CHQ-2026-004', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (11, '2026-03-10', 2, NULL, 200000.00, 'Bank Transfer', 'TRF-2026-006', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (12, '2026-03-15', 5, NULL, 300000.00, 'Cheque', 'CHQ-2026-005', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (13, '2026-03-20', 3, NULL, 120000.00, 'Bank Transfer', 'TRF-2026-007', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (14, '2026-04-13', 6, 3, 50000.00, 'Cash', '', '', '2026-04-13 11:42:26.500267');
INSERT INTO public.credit_payments OVERRIDING SYSTEM VALUE VALUES (15, '2026-04-13', 6, 1, 5000.00, 'Cash', '', '', '2026-04-13 11:44:30.131973');


--
-- TOC entry 4011 (class 0 OID 16811)
-- Dependencies: 244
-- Data for Name: credit_sales; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (1, '2026-01-03', 1, 1, NULL, NULL, 'NB-1234', 200.00, 322.00, 64400.00, '92 Octane', 'REQ-2026-001', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (2, '2026-01-06', 2, 1, NULL, NULL, 'NP-5678', 250.00, 322.00, 80500.00, '92 Octane', 'REQ-2026-002', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (3, '2026-01-08', 2, 2, NULL, NULL, 'NP-9012', 150.00, 375.00, 56250.00, '95 Octane', 'REQ-2026-003', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (4, '2026-01-10', 3, 5, NULL, NULL, 'WP-3456', 400.00, 298.00, 119200.00, 'Auto Diesel', 'REQ-2026-004', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (5, '2026-01-12', 5, 1, NULL, NULL, 'NC-7890', 300.00, 322.00, 96600.00, '92 Octane', 'REQ-2026-005', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (6, '2026-01-15', 1, 2, NULL, NULL, 'NB-2468', 220.00, 375.00, 82500.00, '95 Octane', 'REQ-2026-006', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (7, '2026-01-17', 4, 5, NULL, NULL, 'CP-1357', 180.00, 298.00, 53640.00, 'Auto Diesel', 'REQ-2026-007', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (8, '2026-01-20', 2, 1, NULL, NULL, 'NP-4680', 280.00, 322.00, 90160.00, '92 Octane', 'REQ-2026-008', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (9, '2026-01-22', 5, 5, NULL, NULL, 'NC-2468', 350.00, 298.00, 104300.00, 'Auto Diesel', 'REQ-2026-009', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (10, '2026-01-25', 3, 1, NULL, NULL, 'WP-7890', 200.00, 322.00, 64400.00, '92 Octane', 'REQ-2026-010', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (11, '2026-01-28', 1, 2, NULL, NULL, 'NB-3579', 240.00, 375.00, 90000.00, '95 Octane', 'REQ-2026-011', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (12, '2026-02-02', 2, 1, NULL, NULL, 'NP-6802', 300.00, 322.00, 96600.00, '92 Octane', 'REQ-2026-012', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (13, '2026-02-05', 5, 5, NULL, NULL, 'NC-9135', 400.00, 298.00, 119200.00, 'Auto Diesel', 'REQ-2026-013', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (14, '2026-02-08', 4, 1, NULL, NULL, 'CP-2468', 150.00, 322.00, 48300.00, '92 Octane', 'REQ-2026-014', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (15, '2026-02-12', 1, 2, NULL, NULL, 'NB-5791', 260.00, 375.00, 97500.00, '95 Octane', 'REQ-2026-015', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (16, '2026-02-15', 3, 5, NULL, NULL, 'WP-1357', 450.00, 305.00, 137250.00, 'Auto Diesel', 'REQ-2026-016', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (17, '2026-02-18', 2, 1, NULL, NULL, 'NP-8024', 320.00, 328.00, 104960.00, '92 Octane', 'REQ-2026-017', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (18, '2026-02-21', 5, 2, NULL, NULL, 'NC-3579', 280.00, 382.00, 106960.00, '95 Octane', 'REQ-2026-018', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (19, '2026-02-24', 1, 5, NULL, NULL, 'NB-6802', 500.00, 305.00, 152500.00, 'Auto Diesel', 'REQ-2026-019', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (20, '2026-02-27', 4, 1, NULL, NULL, 'CP-3691', 200.00, 328.00, 65600.00, '92 Octane', 'REQ-2026-020', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (21, '2026-03-02', 2, 1, NULL, NULL, 'NP-0246', 350.00, 328.00, 114800.00, '92 Octane', 'REQ-2026-021', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (22, '2026-03-05', 5, 5, NULL, NULL, 'NC-4682', 500.00, 305.00, 152500.00, 'Auto Diesel', 'REQ-2026-022', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (23, '2026-03-08', 3, 2, NULL, NULL, 'WP-2468', 300.00, 382.00, 114600.00, '95 Octane', 'REQ-2026-023', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (24, '2026-03-11', 1, 1, NULL, NULL, 'NB-8024', 280.00, 328.00, 91840.00, '92 Octane', 'REQ-2026-024', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (25, '2026-03-14', 2, 5, NULL, NULL, 'NP-2468', 400.00, 305.00, 122000.00, 'Auto Diesel', 'REQ-2026-025', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (26, '2026-03-17', 5, 1, NULL, NULL, 'NC-6802', 350.00, 328.00, 114800.00, '92 Octane', 'REQ-2026-026', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (27, '2026-03-20', 4, 2, NULL, NULL, 'CP-4802', 220.00, 382.00, 84040.00, '95 Octane', 'REQ-2026-027', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.credit_sales OVERRIDING SYSTEM VALUE VALUES (28, '2026-03-23', 1, 5, NULL, NULL, 'NB-9135', 600.00, 305.00, 183000.00, 'Auto Diesel', 'REQ-2026-028', NULL, '2026-03-24 16:14:27.127275');


--
-- TOC entry 4007 (class 0 OID 16753)
-- Dependencies: 240
-- Data for Name: daily_sales; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (1, '2026-01-01', 1, NULL, NULL, 'shift', 15380.10, 15760.40, 380.30, 322.00, 122456.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (2, '2026-01-01', 2, NULL, NULL, 'shift', 9500.00, 9840.20, 340.20, 375.00, 127575.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (3, '2026-01-01', 5, NULL, NULL, 'shift', 22000.00, 22480.50, 480.50, 298.00, 143189.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (4, '2026-01-01', 1, NULL, NULL, 'shift', 15760.40, 16050.10, 289.70, 322.00, 93283.40, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (5, '2026-01-02', 1, NULL, NULL, 'shift', 16050.10, 16440.30, 390.20, 322.00, 125644.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (6, '2026-01-02', 2, NULL, NULL, 'shift', 9840.20, 10180.60, 340.40, 375.00, 127650.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (7, '2026-01-02', 5, NULL, NULL, 'shift', 22480.50, 22980.80, 500.30, 298.00, 149089.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (8, '2026-01-02', 7, NULL, NULL, 'shift', 5200.00, 5530.10, 330.10, 358.00, 118195.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (9, '2026-01-03', 1, NULL, NULL, 'shift', 16440.30, 16830.70, 390.40, 322.00, 125708.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (10, '2026-01-03', 2, NULL, NULL, 'shift', 10180.60, 10510.20, 329.60, 375.00, 123600.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (11, '2026-01-03', 5, NULL, NULL, 'shift', 22980.80, 23500.10, 519.30, 298.00, 154751.40, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (12, '2026-01-03', 3, NULL, NULL, 'shift', 4800.00, 5090.40, 290.40, 375.00, 108900.00, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (13, '2026-01-04', 1, NULL, NULL, 'shift', 16830.70, 17200.50, 369.80, 322.00, 119075.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (14, '2026-01-04', 5, NULL, NULL, 'shift', 23500.10, 24020.30, 520.20, 298.00, 155019.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (15, '2026-01-04', 1, NULL, NULL, 'transaction', NULL, NULL, 120.00, 322.00, 38640.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (16, '2026-01-05', 1, NULL, NULL, 'shift', 17200.50, 17600.80, 400.30, 322.00, 128896.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (17, '2026-01-05', 2, NULL, NULL, 'shift', 10510.20, 10870.40, 360.20, 375.00, 135075.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (18, '2026-01-05', 5, NULL, NULL, 'shift', 24020.30, 24560.60, 540.30, 298.00, 161009.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (19, '2026-01-05', 7, NULL, NULL, 'shift', 5530.10, 5870.30, 340.20, 358.00, 121791.60, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (20, '2026-01-06', 1, NULL, NULL, 'shift', 17600.80, 18010.20, 409.40, 322.00, 131826.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (21, '2026-01-06', 2, NULL, NULL, 'shift', 10870.40, 11220.70, 350.30, 375.00, 131362.50, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (22, '2026-01-06', 5, NULL, NULL, 'shift', 24560.60, 25100.80, 540.20, 298.00, 160979.60, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (23, '2026-01-07', 1, NULL, NULL, 'shift', 18010.20, 18430.50, 420.30, 322.00, 135336.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (24, '2026-01-07', 2, NULL, NULL, 'shift', 11220.70, 11600.20, 379.50, 375.00, 142312.50, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (25, '2026-01-07', 5, NULL, NULL, 'shift', 25100.80, 25660.30, 559.50, 298.00, 166731.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (26, '2026-01-07', 3, NULL, NULL, 'shift', 5090.40, 5400.80, 310.40, 375.00, 116400.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (27, '2026-01-08', 1, NULL, NULL, 'shift', 18430.50, 18840.20, 409.70, 322.00, 131923.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (28, '2026-01-08', 5, NULL, NULL, 'shift', 25660.30, 26200.60, 540.30, 298.00, 161009.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (29, '2026-01-08', 7, NULL, NULL, 'shift', 5870.30, 6200.50, 330.20, 358.00, 118231.60, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (30, '2026-01-09', 1, NULL, NULL, 'shift', 18840.20, 19250.70, 410.50, 322.00, 132181.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (31, '2026-01-09', 2, NULL, NULL, 'shift', 11600.20, 11950.80, 350.60, 375.00, 131475.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (32, '2026-01-09', 5, NULL, NULL, 'shift', 26200.60, 26740.90, 540.30, 298.00, 161009.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (33, '2026-01-10', 1, NULL, NULL, 'shift', 19250.70, 19660.40, 409.70, 322.00, 131923.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (34, '2026-01-10', 2, NULL, NULL, 'shift', 11950.80, 12310.50, 359.70, 375.00, 134887.50, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (35, '2026-01-10', 5, NULL, NULL, 'shift', 26740.90, 27300.20, 559.30, 298.00, 166611.40, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (36, '2026-01-10', 3, NULL, NULL, 'shift', 5400.80, 5700.20, 299.40, 375.00, 112275.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (37, '2026-01-11', 1, NULL, NULL, 'shift', 19660.40, 20080.10, 419.70, 322.00, 135143.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (38, '2026-01-11', 5, NULL, NULL, 'shift', 27300.20, 27860.50, 560.30, 298.00, 166969.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (39, '2026-01-11', 1, NULL, NULL, 'transaction', NULL, NULL, 150.00, 322.00, 48300.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (40, '2026-01-12', 1, NULL, NULL, 'shift', 20080.10, 20510.40, 430.30, 322.00, 138556.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (41, '2026-01-12', 2, NULL, NULL, 'shift', 12310.50, 12680.30, 369.80, 375.00, 138675.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (42, '2026-01-12', 5, NULL, NULL, 'shift', 27860.50, 28430.70, 570.20, 298.00, 169919.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (43, '2026-01-12', 7, NULL, NULL, 'shift', 6200.50, 6550.80, 350.30, 358.00, 125407.40, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (44, '2026-01-13', 1, NULL, NULL, 'shift', 20510.40, 20950.60, 440.20, 322.00, 141744.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (45, '2026-01-13', 2, NULL, NULL, 'shift', 12680.30, 13060.50, 380.20, 375.00, 142575.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (46, '2026-01-13', 5, NULL, NULL, 'shift', 28430.70, 29010.40, 579.70, 298.00, 172750.60, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (47, '2026-01-14', 1, NULL, NULL, 'shift', 20950.60, 21380.80, 430.20, 322.00, 138524.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (48, '2026-01-14', 2, NULL, NULL, 'shift', 13060.50, 13420.80, 360.30, 375.00, 135112.50, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (49, '2026-01-14', 5, NULL, NULL, 'shift', 29010.40, 29580.60, 570.20, 298.00, 169919.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (50, '2026-01-14', 3, NULL, NULL, 'shift', 5700.20, 6010.50, 310.30, 375.00, 116362.50, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (51, '2026-01-15', 1, NULL, NULL, 'shift', 21380.80, 21810.30, 429.50, 322.00, 138299.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (52, '2026-01-15', 5, NULL, NULL, 'shift', 29580.60, 30150.80, 570.20, 298.00, 169919.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (53, '2026-01-15', 7, NULL, NULL, 'shift', 6550.80, 6900.40, 349.60, 358.00, 125156.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (54, '2026-01-16', 1, NULL, NULL, 'shift', 21810.30, 22250.60, 440.30, 322.00, 141776.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (55, '2026-01-16', 2, NULL, NULL, 'shift', 13420.80, 13800.20, 379.40, 375.00, 142275.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (56, '2026-01-16', 5, NULL, NULL, 'shift', 30150.80, 30730.50, 579.70, 298.00, 172750.60, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (57, '2026-01-17', 1, NULL, NULL, 'shift', 22250.60, 22680.90, 430.30, 322.00, 138556.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (58, '2026-01-17', 2, NULL, NULL, 'shift', 13800.20, 14180.50, 380.30, 375.00, 142612.50, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (59, '2026-01-17', 5, NULL, NULL, 'shift', 30730.50, 31310.70, 580.20, 298.00, 172899.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (60, '2026-01-17', 3, NULL, NULL, 'shift', 6010.50, 6320.80, 310.30, 375.00, 116362.50, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (61, '2026-01-18', 1, NULL, NULL, 'shift', 22680.90, 23110.20, 429.30, 322.00, 138434.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (62, '2026-01-18', 5, NULL, NULL, 'shift', 31310.70, 31890.40, 579.70, 298.00, 172750.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (63, '2026-01-18', 1, NULL, NULL, 'transaction', NULL, NULL, 200.00, 322.00, 64400.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (64, '2026-01-19', 1, NULL, NULL, 'shift', 23110.20, 23560.80, 450.60, 322.00, 145093.20, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (65, '2026-01-19', 2, NULL, NULL, 'shift', 14180.50, 14570.30, 389.80, 375.00, 146175.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (66, '2026-01-19', 5, NULL, NULL, 'shift', 31890.40, 32490.60, 600.20, 298.00, 178859.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (67, '2026-01-19', 7, NULL, NULL, 'shift', 6900.40, 7260.50, 360.10, 358.00, 128915.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (68, '2026-01-20', 1, NULL, NULL, 'shift', 23560.80, 24010.40, 449.60, 322.00, 144771.20, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (69, '2026-01-20', 2, NULL, NULL, 'shift', 14570.30, 14960.60, 390.30, 375.00, 146362.50, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (70, '2026-01-20', 5, NULL, NULL, 'shift', 32490.60, 33080.80, 590.20, 298.00, 175879.60, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (71, '2026-01-21', 1, NULL, NULL, 'shift', 24010.40, 24460.70, 450.30, 322.00, 144996.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (72, '2026-01-21', 2, NULL, NULL, 'shift', 14960.60, 15360.90, 400.30, 375.00, 150112.50, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (73, '2026-01-21', 5, NULL, NULL, 'shift', 33080.80, 33680.50, 599.70, 298.00, 178730.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (74, '2026-01-21', 3, NULL, NULL, 'shift', 6320.80, 6650.40, 329.60, 375.00, 123600.00, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (75, '2026-01-22', 1, NULL, NULL, 'shift', 24460.70, 24900.30, 439.60, 322.00, 141551.20, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (76, '2026-01-22', 5, NULL, NULL, 'shift', 33680.50, 34270.70, 590.20, 298.00, 175879.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (77, '2026-01-22', 7, NULL, NULL, 'shift', 7260.50, 7620.60, 360.10, 358.00, 128915.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (78, '2026-01-23', 1, NULL, NULL, 'shift', 24900.30, 25350.60, 450.30, 322.00, 144996.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (79, '2026-01-23', 2, NULL, NULL, 'shift', 15360.90, 15760.20, 399.30, 375.00, 149737.50, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (80, '2026-01-23', 5, NULL, NULL, 'shift', 34270.70, 34870.90, 600.20, 298.00, 178859.60, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (81, '2026-01-24', 1, NULL, NULL, 'shift', 25350.60, 25800.40, 449.80, 322.00, 144835.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (82, '2026-01-24', 2, NULL, NULL, 'shift', 15760.20, 16150.80, 390.60, 375.00, 146475.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (83, '2026-01-24', 5, NULL, NULL, 'shift', 34870.90, 35470.60, 599.70, 298.00, 178730.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (84, '2026-01-24', 3, NULL, NULL, 'shift', 6650.40, 6970.80, 320.40, 375.00, 120150.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (85, '2026-01-25', 1, NULL, NULL, 'shift', 25800.40, 26260.70, 460.30, 322.00, 148216.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (86, '2026-01-25', 5, NULL, NULL, 'shift', 35470.60, 36080.30, 609.70, 298.00, 181690.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (87, '2026-01-25', 1, NULL, NULL, 'transaction', NULL, NULL, 180.00, 322.00, 57960.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (88, '2026-01-26', 1, NULL, NULL, 'shift', 26260.70, 26720.40, 459.70, 322.00, 148023.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (89, '2026-01-26', 2, NULL, NULL, 'shift', 16150.80, 16560.30, 409.50, 375.00, 153562.50, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (90, '2026-01-26', 5, NULL, NULL, 'shift', 36080.30, 36690.50, 610.20, 298.00, 181839.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (91, '2026-01-26', 7, NULL, NULL, 'shift', 7620.60, 7990.80, 370.20, 358.00, 132531.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (92, '2026-01-27', 1, NULL, NULL, 'shift', 26720.40, 27190.60, 470.20, 322.00, 151404.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (93, '2026-01-27', 2, NULL, NULL, 'shift', 16560.30, 16960.80, 400.50, 375.00, 150187.50, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (94, '2026-01-27', 5, NULL, NULL, 'shift', 36690.50, 37300.70, 610.20, 298.00, 181839.60, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (95, '2026-01-28', 1, NULL, NULL, 'shift', 27190.60, 27660.40, 469.80, 322.00, 151275.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (96, '2026-01-28', 2, NULL, NULL, 'shift', 16960.80, 17370.40, 409.60, 375.00, 153600.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (97, '2026-01-28', 5, NULL, NULL, 'shift', 37300.70, 37910.40, 609.70, 298.00, 181690.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (98, '2026-01-28', 3, NULL, NULL, 'shift', 6970.80, 7290.60, 319.80, 375.00, 119925.00, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (99, '2026-01-29', 1, NULL, NULL, 'shift', 27660.40, 28130.60, 470.20, 322.00, 151404.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (100, '2026-01-29', 5, NULL, NULL, 'shift', 37910.40, 38530.60, 620.20, 298.00, 184819.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (101, '2026-01-29', 7, NULL, NULL, 'shift', 7990.80, 8360.40, 369.60, 358.00, 132316.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (102, '2026-01-30', 1, NULL, NULL, 'shift', 28130.60, 28610.40, 479.80, 322.00, 154495.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (103, '2026-01-30', 2, NULL, NULL, 'shift', 17370.40, 17790.80, 420.40, 375.00, 157650.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (104, '2026-01-30', 5, NULL, NULL, 'shift', 38530.60, 39160.80, 630.20, 298.00, 187799.60, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (105, '2026-01-31', 1, NULL, NULL, 'shift', 28610.40, 29090.60, 480.20, 322.00, 154624.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (106, '2026-01-31', 2, NULL, NULL, 'shift', 17790.80, 18210.40, 419.60, 375.00, 157350.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (107, '2026-01-31', 5, NULL, NULL, 'shift', 39160.80, 39800.50, 639.70, 298.00, 190530.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (108, '2026-01-31', 3, NULL, NULL, 'shift', 7290.60, 7620.40, 329.80, 375.00, 123675.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (109, '2026-02-01', 1, NULL, NULL, 'shift', 29090.60, 29570.40, 479.80, 322.00, 154495.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (110, '2026-02-01', 2, NULL, NULL, 'shift', 18210.40, 18620.80, 410.40, 375.00, 153900.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (111, '2026-02-01', 5, NULL, NULL, 'shift', 39800.50, 40440.20, 639.70, 298.00, 190530.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (112, '2026-02-01', 7, NULL, NULL, 'shift', 8360.40, 8730.60, 370.20, 358.00, 132531.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (113, '2026-02-03', 1, NULL, NULL, 'shift', 29570.40, 30060.80, 490.40, 322.00, 157908.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (114, '2026-02-03', 2, NULL, NULL, 'shift', 18620.80, 19040.60, 419.80, 375.00, 157425.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (115, '2026-02-03', 5, NULL, NULL, 'shift', 40440.20, 41090.40, 650.20, 298.00, 193759.60, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (116, '2026-02-04', 1, NULL, NULL, 'shift', 30060.80, 30560.40, 499.60, 322.00, 160871.20, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (117, '2026-02-04', 5, NULL, NULL, 'shift', 41090.40, 41750.60, 660.20, 298.00, 196739.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (118, '2026-02-04', 1, NULL, NULL, 'transaction', NULL, NULL, 200.00, 322.00, 64400.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (119, '2026-02-05', 1, NULL, NULL, 'shift', 30560.40, 31060.80, 500.40, 322.00, 161128.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (120, '2026-02-05', 2, NULL, NULL, 'shift', 19040.60, 19470.40, 429.80, 375.00, 161175.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (121, '2026-02-05', 5, NULL, NULL, 'shift', 41750.60, 42410.80, 660.20, 298.00, 196739.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (122, '2026-02-05', 3, NULL, NULL, 'shift', 7620.40, 7950.80, 330.40, 375.00, 123900.00, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (123, '2026-02-06', 1, NULL, NULL, 'shift', 31060.80, 31570.40, 509.60, 322.00, 164091.20, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (124, '2026-02-06', 5, NULL, NULL, 'shift', 42410.80, 43080.60, 669.80, 298.00, 199600.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (125, '2026-02-06', 7, NULL, NULL, 'shift', 8730.60, 9110.80, 380.20, 358.00, 136151.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (126, '2026-02-07', 1, NULL, NULL, 'shift', 31570.40, 32080.60, 510.20, 322.00, 164284.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (127, '2026-02-07', 2, NULL, NULL, 'shift', 19470.40, 19910.80, 440.40, 375.00, 165150.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (128, '2026-02-07', 5, NULL, NULL, 'shift', 43080.60, 43760.40, 679.80, 298.00, 202580.40, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (129, '2026-02-08', 1, NULL, NULL, 'shift', 32080.60, 32600.40, 519.80, 322.00, 167375.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (130, '2026-02-08', 2, NULL, NULL, 'shift', 19910.80, 20360.60, 449.80, 375.00, 168675.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (131, '2026-02-08', 5, NULL, NULL, 'shift', 43760.40, 44450.60, 690.20, 298.00, 205679.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (132, '2026-02-08', 3, NULL, NULL, 'shift', 7950.80, 8290.40, 339.60, 375.00, 127350.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (133, '2026-02-10', 1, NULL, NULL, 'shift', 32600.40, 33110.80, 510.40, 322.00, 164348.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (134, '2026-02-10', 5, NULL, NULL, 'shift', 44450.60, 45140.80, 690.20, 298.00, 205679.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (135, '2026-02-10', 1, NULL, NULL, 'transaction', NULL, NULL, 240.00, 322.00, 77280.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (136, '2026-02-11', 1, NULL, NULL, 'shift', 33110.80, 33630.60, 519.80, 322.00, 167375.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (137, '2026-02-11', 2, NULL, NULL, 'shift', 20360.60, 20810.40, 449.80, 375.00, 168675.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (138, '2026-02-11', 5, NULL, NULL, 'shift', 45140.80, 45840.60, 699.80, 298.00, 208560.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (139, '2026-02-11', 7, NULL, NULL, 'shift', 9110.80, 9500.40, 389.60, 358.00, 139476.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (140, '2026-02-12', 1, NULL, NULL, 'shift', 33630.60, 34160.40, 529.80, 322.00, 170595.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (141, '2026-02-12', 2, NULL, NULL, 'shift', 20810.40, 21270.60, 460.20, 375.00, 172575.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (142, '2026-02-12', 5, NULL, NULL, 'shift', 45840.60, 46550.80, 710.20, 298.00, 211639.60, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (143, '2026-02-13', 1, NULL, NULL, 'shift', 34160.40, 34700.80, 540.40, 322.00, 174008.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (144, '2026-02-13', 5, NULL, NULL, 'shift', 46550.80, 47260.60, 709.80, 298.00, 211520.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (145, '2026-02-13', 3, NULL, NULL, 'shift', 8290.40, 8640.60, 350.20, 375.00, 131325.00, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (146, '2026-02-14', 1, NULL, NULL, 'shift', 34700.80, 35250.60, 549.80, 322.00, 177015.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (147, '2026-02-14', 2, NULL, NULL, 'shift', 21270.60, 21750.40, 479.80, 375.00, 179925.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (148, '2026-02-14', 5, NULL, NULL, 'shift', 47260.60, 47980.80, 720.20, 298.00, 214619.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (149, '2026-02-14', 7, NULL, NULL, 'shift', 9500.40, 9890.60, 390.20, 358.00, 139691.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (150, '2026-02-15', 1, NULL, NULL, 'shift', 35250.60, 35800.40, 549.80, 328.00, 180334.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (151, '2026-02-15', 2, NULL, NULL, 'shift', 21750.40, 22240.60, 490.20, 382.00, 187256.40, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (152, '2026-02-15', 5, NULL, NULL, 'shift', 47980.80, 48710.60, 729.80, 305.00, 222589.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (153, '2026-02-16', 1, NULL, NULL, 'shift', 35800.40, 36360.80, 560.40, 328.00, 183811.20, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (154, '2026-02-16', 5, NULL, NULL, 'shift', 48710.60, 49460.40, 749.80, 305.00, 228689.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (155, '2026-02-16', 1, NULL, NULL, 'transaction', NULL, NULL, 220.00, 328.00, 72160.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (156, '2026-02-17', 1, NULL, NULL, 'shift', 36360.80, 36930.60, 569.80, 328.00, 186894.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (157, '2026-02-17', 2, NULL, NULL, 'shift', 22240.60, 22750.40, 509.80, 382.00, 194843.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (158, '2026-02-17', 5, NULL, NULL, 'shift', 49460.40, 50220.60, 760.20, 305.00, 231861.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (159, '2026-02-17', 3, NULL, NULL, 'shift', 8640.60, 9010.40, 369.80, 382.00, 141363.60, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (160, '2026-02-18', 1, NULL, NULL, 'shift', 36930.60, 37510.40, 579.80, 328.00, 190174.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (161, '2026-02-18', 5, NULL, NULL, 'shift', 50220.60, 50990.80, 770.20, 305.00, 234911.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (162, '2026-02-18', 7, NULL, NULL, 'shift', 9890.60, 10290.40, 399.80, 365.00, 145927.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (163, '2026-02-19', 1, NULL, NULL, 'shift', 37510.40, 38100.60, 590.20, 328.00, 193585.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (164, '2026-02-19', 2, NULL, NULL, 'shift', 22750.40, 23270.80, 520.40, 382.00, 198792.80, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (165, '2026-02-19', 5, NULL, NULL, 'shift', 50990.80, 51780.60, 789.80, 305.00, 240889.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (166, '2026-02-20', 1, NULL, NULL, 'shift', 38100.60, 38690.40, 589.80, 328.00, 193454.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (167, '2026-02-20', 2, NULL, NULL, 'shift', 23270.80, 23800.60, 529.80, 382.00, 202383.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (168, '2026-02-20', 5, NULL, NULL, 'shift', 51780.60, 52580.40, 799.80, 305.00, 243939.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (169, '2026-02-20', 3, NULL, NULL, 'shift', 9010.40, 9390.60, 380.20, 382.00, 145236.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (170, '2026-02-21', 1, NULL, NULL, 'shift', 38690.40, 39290.60, 600.20, 328.00, 196865.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (171, '2026-02-21', 5, NULL, NULL, 'shift', 52580.40, 53390.80, 810.40, 305.00, 247172.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (172, '2026-02-21', 1, NULL, NULL, 'transaction', NULL, NULL, 250.00, 328.00, 82000.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (173, '2026-02-22', 1, NULL, NULL, 'shift', 39290.60, 39900.40, 609.80, 328.00, 200014.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (174, '2026-02-22', 2, NULL, NULL, 'shift', 23800.60, 24350.80, 550.20, 382.00, 210176.40, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (175, '2026-02-22', 5, NULL, NULL, 'shift', 53390.80, 54210.60, 819.80, 305.00, 250039.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (176, '2026-02-22', 7, NULL, NULL, 'shift', 10290.40, 10710.60, 420.20, 365.00, 153373.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (177, '2026-02-23', 1, NULL, NULL, 'shift', 39900.40, 40520.60, 620.20, 328.00, 203425.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (178, '2026-02-23', 5, NULL, NULL, 'shift', 54210.60, 55050.40, 839.80, 305.00, 256139.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (179, '2026-02-24', 1, NULL, NULL, 'shift', 40520.60, 41150.40, 629.80, 328.00, 206574.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (180, '2026-02-24', 2, NULL, NULL, 'shift', 24350.80, 24910.60, 559.80, 382.00, 213843.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (181, '2026-02-24', 5, NULL, NULL, 'shift', 55050.40, 55910.80, 860.40, 305.00, 262422.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (182, '2026-02-24', 3, NULL, NULL, 'shift', 9390.60, 9790.40, 399.80, 382.00, 152723.60, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (183, '2026-02-25', 1, NULL, NULL, 'shift', 41150.40, 41790.60, 640.20, 328.00, 209985.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (184, '2026-02-25', 5, NULL, NULL, 'shift', 55910.80, 56780.60, 869.80, 305.00, 265289.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (185, '2026-02-25', 7, NULL, NULL, 'shift', 10710.60, 11140.80, 430.20, 365.00, 157023.00, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (186, '2026-02-26', 1, NULL, NULL, 'shift', 41790.60, 42440.40, 649.80, 328.00, 213134.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (187, '2026-02-26', 2, NULL, NULL, 'shift', 24910.60, 25490.80, 580.20, 382.00, 221716.40, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (188, '2026-02-26', 5, NULL, NULL, 'shift', 56780.60, 57670.80, 890.20, 305.00, 271511.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (189, '2026-02-27', 1, NULL, NULL, 'shift', 42440.40, 43110.60, 670.20, 328.00, 219825.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (190, '2026-02-27', 2, NULL, NULL, 'shift', 25490.80, 26080.60, 589.80, 382.00, 225303.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (191, '2026-02-27', 5, NULL, NULL, 'shift', 57670.80, 58580.40, 909.60, 305.00, 277428.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (192, '2026-02-27', 3, NULL, NULL, 'shift', 9790.40, 10220.60, 430.20, 382.00, 164236.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (193, '2026-02-28', 1, NULL, NULL, 'shift', 43110.60, 43800.40, 689.80, 328.00, 226254.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (194, '2026-02-28', 5, NULL, NULL, 'shift', 58580.40, 59510.60, 930.20, 305.00, 283711.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (195, '2026-02-28', 1, NULL, NULL, 'transaction', NULL, NULL, 280.00, 328.00, 91840.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (196, '2026-03-01', 1, NULL, NULL, 'shift', 43800.40, 44500.60, 700.20, 328.00, 229665.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (197, '2026-03-01', 2, NULL, NULL, 'shift', 26080.60, 26690.40, 609.80, 382.00, 232943.60, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (198, '2026-03-01', 5, NULL, NULL, 'shift', 59510.60, 60470.80, 960.20, 305.00, 292861.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (199, '2026-03-01', 7, NULL, NULL, 'shift', 11140.80, 11580.60, 439.80, 365.00, 160527.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (200, '2026-03-02', 1, NULL, NULL, 'shift', 44500.60, 45210.80, 710.20, 328.00, 232945.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (201, '2026-03-02', 2, NULL, NULL, 'shift', 26690.40, 27310.80, 620.40, 382.00, 237192.80, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (202, '2026-03-02', 5, NULL, NULL, 'shift', 60470.80, 61450.60, 979.80, 305.00, 298839.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (203, '2026-03-03', 1, NULL, NULL, 'shift', 45210.80, 45930.60, 719.80, 328.00, 236094.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (204, '2026-03-03', 5, NULL, NULL, 'shift', 61450.60, 62450.40, 999.80, 305.00, 304939.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (205, '2026-03-03', 3, NULL, NULL, 'shift', 10220.60, 10650.40, 429.80, 382.00, 164183.60, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (206, '2026-03-04', 1, NULL, NULL, 'shift', 45930.60, 46660.40, 729.80, 328.00, 239374.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (207, '2026-03-04', 2, NULL, NULL, 'shift', 27310.80, 27950.60, 639.80, 382.00, 244403.60, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (208, '2026-03-04', 5, NULL, NULL, 'shift', 62450.40, 63470.60, 1020.20, 305.00, 311161.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (209, '2026-03-04', 7, NULL, NULL, 'shift', 11580.60, 12040.80, 460.20, 365.00, 167973.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (210, '2026-03-05', 1, NULL, NULL, 'shift', 46660.40, 47400.60, 740.20, 328.00, 242785.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (211, '2026-03-05', 5, NULL, NULL, 'shift', 63470.60, 64510.80, 1040.20, 305.00, 312261.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (212, '2026-03-05', 1, NULL, NULL, 'transaction', NULL, NULL, 300.00, 328.00, 98400.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (213, '2026-03-06', 1, NULL, NULL, 'shift', 47400.60, 48150.40, 749.80, 328.00, 245934.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (214, '2026-03-06', 2, NULL, NULL, 'shift', 27950.60, 28610.80, 660.20, 382.00, 252236.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (215, '2026-03-06', 5, NULL, NULL, 'shift', 64510.80, 65570.60, 1059.80, 305.00, 323239.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (216, '2026-03-07', 1, NULL, NULL, 'shift', 48150.40, 48910.60, 760.20, 328.00, 249345.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (217, '2026-03-07', 2, NULL, NULL, 'shift', 28610.80, 29290.60, 679.80, 382.00, 259683.60, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (218, '2026-03-07', 5, NULL, NULL, 'shift', 65570.60, 66650.80, 1080.20, 305.00, 329461.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (219, '2026-03-07', 3, NULL, NULL, 'shift', 10650.40, 11100.60, 450.20, 382.00, 171976.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (220, '2026-03-08', 1, NULL, NULL, 'shift', 48910.60, 49680.40, 769.80, 328.00, 252494.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (221, '2026-03-08', 5, NULL, NULL, 'shift', 66650.80, 67750.60, 1099.80, 305.00, 335439.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (222, '2026-03-08', 7, NULL, NULL, 'shift', 12040.80, 12510.60, 469.80, 365.00, 171477.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (223, '2026-03-09', 1, NULL, NULL, 'shift', 49680.40, 50460.60, 780.20, 328.00, 255905.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (224, '2026-03-09', 2, NULL, NULL, 'shift', 29290.60, 29990.40, 699.80, 382.00, 267323.60, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (225, '2026-03-09', 5, NULL, NULL, 'shift', 67750.60, 68870.80, 1120.20, 305.00, 341661.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (226, '2026-03-10', 1, NULL, NULL, 'shift', 50460.60, 51260.40, 799.80, 328.00, 262334.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (227, '2026-03-10', 5, NULL, NULL, 'shift', 68870.80, 70010.60, 1139.80, 305.00, 347639.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (228, '2026-03-10', 1, NULL, NULL, 'transaction', NULL, NULL, 320.00, 328.00, 104960.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (229, '2026-03-11', 1, NULL, NULL, 'shift', 51260.40, 52080.60, 820.20, 328.00, 269025.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (230, '2026-03-11', 2, NULL, NULL, 'shift', 29990.40, 30720.80, 730.40, 382.00, 279012.80, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (231, '2026-03-11', 5, NULL, NULL, 'shift', 70010.60, 71190.40, 1179.80, 305.00, 359839.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (232, '2026-03-11', 3, NULL, NULL, 'shift', 11100.60, 11570.80, 470.20, 382.00, 179596.40, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (233, '2026-03-12', 1, NULL, NULL, 'shift', 52080.60, 52920.40, 839.80, 328.00, 275454.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (234, '2026-03-12', 5, NULL, NULL, 'shift', 71190.40, 72400.60, 1210.20, 305.00, 369111.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (235, '2026-03-12', 7, NULL, NULL, 'shift', 12510.60, 13010.40, 499.80, 365.00, 182427.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (236, '2026-03-13', 1, NULL, NULL, 'shift', 52920.40, 53780.60, 860.20, 328.00, 282145.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (237, '2026-03-13', 2, NULL, NULL, 'shift', 30720.80, 31480.60, 759.80, 382.00, 290343.60, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (238, '2026-03-13', 5, NULL, NULL, 'shift', 72400.60, 73640.80, 1240.20, 305.00, 378261.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (239, '2026-03-14', 1, NULL, NULL, 'shift', 53780.60, 54660.40, 879.80, 328.00, 288574.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (240, '2026-03-14', 5, NULL, NULL, 'shift', 73640.80, 74910.60, 1269.80, 305.00, 387289.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (241, '2026-03-14', 3, NULL, NULL, 'shift', 11570.80, 12060.60, 489.80, 382.00, 187103.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (242, '2026-03-15', 1, NULL, NULL, 'shift', 54660.40, 55560.60, 900.20, 328.00, 295265.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (243, '2026-03-15', 2, NULL, NULL, 'shift', 31480.60, 32270.40, 789.80, 382.00, 301703.60, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (244, '2026-03-15', 5, NULL, NULL, 'shift', 74910.60, 76210.80, 1300.20, 305.00, 396561.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (246, '2026-03-16', 1, NULL, NULL, 'shift', 55560.60, 56480.40, 919.80, 328.00, 301694.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (247, '2026-03-16', 5, NULL, NULL, 'shift', 76210.80, 77540.60, 1329.80, 305.00, 405589.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (249, '2026-03-17', 1, NULL, NULL, 'shift', 56480.40, 57420.60, 940.20, 328.00, 308385.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (250, '2026-03-17', 2, NULL, NULL, 'shift', 32270.40, 33090.80, 820.40, 382.00, 313392.80, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (251, '2026-03-17', 5, NULL, NULL, 'shift', 77540.60, 78900.40, 1359.80, 305.00, 414739.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (252, '2026-03-17', 3, NULL, NULL, 'shift', 12060.60, 12570.40, 509.80, 382.00, 194747.60, 'Mobile', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (254, '2026-03-18', 5, NULL, NULL, 'shift', 78900.40, 80290.60, 1390.20, 305.00, 423911.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (255, '2026-03-18', 7, NULL, NULL, 'shift', 13540.60, 14090.80, 550.20, 365.00, 200823.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (256, '2026-03-19', 1, NULL, NULL, 'shift', 58380.40, 59360.60, 980.20, 328.00, 321505.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (257, '2026-03-19', 2, NULL, NULL, 'shift', 33090.80, 33940.60, 849.80, 382.00, 324623.60, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (258, '2026-03-19', 5, NULL, NULL, 'shift', 80290.60, 81710.80, 1420.20, 305.00, 433161.00, 'Cash', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (259, '2026-03-20', 1, NULL, NULL, 'shift', 59360.60, 60360.40, 999.80, 328.00, 327934.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (260, '2026-03-20', 5, NULL, NULL, 'shift', 81710.80, 83160.60, 1449.80, 305.00, 442189.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (261, '2026-03-20', 1, NULL, NULL, 'transaction', NULL, NULL, 380.00, 328.00, 124640.00, 'Card', 'Evening', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (262, '2026-03-21', 1, NULL, NULL, 'shift', 60360.40, 61390.60, 1030.20, 328.00, 337905.60, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (263, '2026-03-21', 2, NULL, NULL, 'shift', 33940.60, 34820.40, 879.80, 382.00, 336103.60, 'Card', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (264, '2026-03-21', 5, NULL, NULL, 'shift', 83160.60, 84650.80, 1490.20, 305.00, 454511.00, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (265, '2026-03-21', 3, NULL, NULL, 'shift', 12570.40, 13100.60, 530.20, 382.00, 202636.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (266, '2026-03-22', 1, NULL, NULL, 'shift', 61390.60, 62440.40, 1049.80, 328.00, 344334.40, 'Cash', 'Morning', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (273, '2026-03-29', 5, NULL, 1, 'shift', 87750.40, 89360.60, 1610.20, 305.00, 491111.00, 'Cash', 'Morning', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (272, '2026-03-28', 8, NULL, 1, 'shift', 63510.60, 64590.40, 1079.80, 365.00, 394127.00, 'Cash', 'Morning', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (271, '2026-03-27', 5, NULL, 1, 'shift', 86180.60, 87750.40, 1569.80, 305.00, 478789.00, 'Cash', 'Evening', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (270, '2026-03-26', 2, NULL, 1, 'shift', 34820.40, 35730.80, 910.40, 382.00, 347772.80, 'Card', 'Morning', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (269, '2026-03-25', 1, NULL, 1, 'shift', 62440.40, 63510.60, 1070.20, 328.00, 351025.60, 'Cash', 'Morning', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (268, '2026-03-24', 5, NULL, 1, 'shift', 14090.80, 14660.60, 569.80, 305.00, 173789.00, 'Cash', 'Morning', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (267, '2026-03-23', 5, NULL, 1, 'shift', 84650.80, 86180.60, 1529.80, 305.00, 466589.00, 'Cash', 'Morning', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (253, '2026-03-30', 1, NULL, 1, 'shift', 57420.60, 58380.40, 959.80, 328.00, 314814.40, 'Cash', 'Morning', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (248, '2026-03-30', 1, NULL, 1, 'transaction', NULL, NULL, 350.00, 328.00, 114800.00, 'Card', 'Evening', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (245, '2026-03-30', 9, NULL, 1, 'shift', 13010.40, 13540.60, 530.20, 328.00, 173905.60, 'Cash', 'Morning', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (274, '2026-03-30', 2, 208, 1, 'transaction', NULL, NULL, 400.00, 328.00, 131200.00, 'Card', 'Evening', '', '2026-03-24 16:14:27.127275');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (318, '2026-04-09', 1, NULL, NULL, 'shift', 12000.00, 12350.00, 350.00, 365.00, 127750.00, 'Cash', 'Morning', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (319, '2026-04-09', 1, NULL, NULL, 'shift', 12350.00, 12720.00, 370.00, 365.00, 135050.00, 'Card', 'Evening', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (320, '2026-04-09', 1, NULL, NULL, 'shift', 12720.00, 13000.00, 280.00, 365.00, 102200.00, 'Cash', 'Night', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (321, '2026-04-09', 2, NULL, NULL, 'shift', 15000.00, 15380.00, 380.00, 420.00, 159600.00, 'Cash', 'Morning', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (322, '2026-04-09', 2, NULL, NULL, 'shift', 15380.00, 15820.00, 440.00, 420.00, 184800.00, 'Mobile', 'Evening', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (323, '2026-04-09', 2, NULL, NULL, 'shift', 15820.00, 16100.00, 280.00, 420.00, 117600.00, 'Cash', 'Night', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (324, '2026-04-10', 1, NULL, NULL, 'shift', 13000.00, 13360.00, 360.00, 365.00, 131400.00, 'Cash', 'Morning', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (325, '2026-04-10', 1, NULL, NULL, 'shift', 13360.00, 13750.00, 390.00, 365.00, 142350.00, 'Card', 'Evening', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (326, '2026-04-10', 1, NULL, NULL, 'shift', 13750.00, 14020.00, 270.00, 365.00, 98550.00, 'Cash', 'Night', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (327, '2026-04-10', 2, NULL, NULL, 'shift', 16100.00, 16500.00, 400.00, 420.00, 168000.00, 'Cash', 'Morning', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (328, '2026-04-10', 2, NULL, NULL, 'shift', 16500.00, 16960.00, 460.00, 420.00, 193200.00, 'Card', 'Evening', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (329, '2026-04-10', 2, NULL, NULL, 'shift', 16960.00, 17220.00, 260.00, 420.00, 109200.00, 'Cash', 'Night', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (330, '2026-04-11', 1, NULL, NULL, 'shift', 14020.00, 14400.00, 380.00, 365.00, 138700.00, 'Cash', 'Morning', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (331, '2026-04-11', 1, NULL, NULL, 'shift', 14400.00, 14850.00, 450.00, 365.00, 164250.00, 'Card', 'Evening', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (332, '2026-04-11', 1, NULL, NULL, 'shift', 14850.00, 15150.00, 300.00, 365.00, 109500.00, 'Cash', 'Night', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (333, '2026-04-12', 1, NULL, NULL, 'shift', 15150.00, 15520.00, 370.00, 365.00, 135050.00, 'Cash', 'Morning', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (334, '2026-04-12', 1, NULL, NULL, 'shift', 15520.00, 15960.00, 440.00, 365.00, 160600.00, 'Card', 'Evening', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (335, '2026-04-12', 1, NULL, NULL, 'shift', 15960.00, 16230.00, 270.00, 365.00, 98550.00, 'Cash', 'Night', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (336, '2026-04-13', 1, NULL, NULL, 'shift', 16230.00, 16580.00, 350.00, 365.00, 127750.00, 'Cash', 'Morning', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (337, '2026-04-13', 1, NULL, NULL, 'shift', 16580.00, 16980.00, 400.00, 365.00, 146000.00, 'Card', 'Evening', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (338, '2026-04-13', 1, NULL, NULL, 'shift', 16980.00, 17250.00, 270.00, 365.00, 98550.00, 'Cash', 'Night', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (339, '2026-04-14', 1, NULL, NULL, 'shift', 17250.00, 17620.00, 370.00, 365.00, 135050.00, 'Cash', 'Morning', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (340, '2026-04-14', 1, NULL, NULL, 'shift', 17620.00, 18040.00, 420.00, 365.00, 153300.00, 'Card', 'Evening', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (341, '2026-04-14', 1, NULL, NULL, 'shift', 18040.00, 18300.00, 260.00, 365.00, 94900.00, 'Cash', 'Night', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (342, '2026-04-15', 1, NULL, NULL, 'shift', 18300.00, 18680.00, 380.00, 365.00, 138700.00, 'Cash', 'Morning', NULL, '2026-04-15 23:17:12.069292');
INSERT INTO public.daily_sales OVERRIDING SYSTEM VALUE VALUES (343, '2026-04-15', 1, NULL, NULL, 'shift', 18680.00, 19050.00, 370.00, 365.00, 135050.00, 'Card', 'Evening', NULL, '2026-04-15 23:17:12.069292');


--
-- TOC entry 3983 (class 0 OID 16537)
-- Dependencies: 216
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.expenses VALUES (1, 'Electricity Bill — January', 'Utilities', 38500.00, 'Bank Transfer', 'CEB monthly payment', '2026-01-05', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (2, 'Staff Salaries — January', 'Salaries', 420000.00, 'Bank Transfer', 'Full staff payroll Jan 2026', '2026-01-10', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (3, 'Pump P-03 Service', 'Maintenance', 22000.00, 'Cash', 'Filter and nozzle replacement', '2026-01-12', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (4, 'Generator Fuel', 'Fuel', 8500.00, 'Cash', 'Monthly generator diesel', '2026-01-15', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (5, 'Office Supplies', 'Other', 4200.00, 'Cash', 'Stationery, printer ink', '2026-01-18', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (6, 'Water Bill — January', 'Utilities', 3200.00, 'Cash', 'NWS&DB monthly', '2026-01-20', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (7, 'Security Service — January', 'Other', 15000.00, 'Bank Transfer', 'Monthly security contract', '2026-01-25', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (8, 'Internet & Phone — January', 'Utilities', 5800.00, 'Bank Transfer', 'Dialog broadband + mobitel', '2026-01-28', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (9, 'Electricity Bill — February', 'Utilities', 41200.00, 'Bank Transfer', 'CEB monthly payment', '2026-02-05', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (10, 'Staff Salaries — February', 'Salaries', 420000.00, 'Bank Transfer', 'Full staff payroll Feb 2026', '2026-02-10', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (11, 'Pump P-01 Calibration', 'Maintenance', 18500.00, 'Cash', 'Flow meter recalibration', '2026-02-08', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (12, 'Forecourt Cleaning Equipment', 'Maintenance', 12000.00, 'Cash', 'Pressure washer purchase', '2026-02-12', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (13, 'Generator Fuel', 'Fuel', 9200.00, 'Cash', 'Monthly generator diesel', '2026-02-15', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (14, 'Water Bill — February', 'Utilities', 3400.00, 'Cash', 'NWS&DB monthly', '2026-02-18', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (15, 'Security Service — February', 'Other', 15000.00, 'Bank Transfer', 'Monthly security contract', '2026-02-25', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (16, 'Internet & Phone — February', 'Utilities', 5800.00, 'Bank Transfer', 'Dialog broadband + mobitel', '2026-02-28', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (17, 'Staff Training', 'Other', 25000.00, 'Bank Transfer', 'Fire safety & first aid training', '2026-02-20', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (18, 'Electricity Bill — March', 'Utilities', 43800.00, 'Bank Transfer', 'CEB monthly payment', '2026-03-05', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (19, 'Staff Salaries — March', 'Salaries', 420000.00, 'Bank Transfer', 'Full staff payroll Mar 2026', '2026-03-10', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (20, 'Pump P-05 Overhaul', 'Maintenance', 45000.00, 'Cash', 'Full pump overhaul high-vol diesel', '2026-03-08', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (21, 'CCTV System Upgrade', 'Maintenance', 68000.00, 'Bank Transfer', '6-camera HD upgrade', '2026-03-12', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (22, 'Generator Fuel', 'Fuel', 9800.00, 'Cash', 'Monthly generator diesel', '2026-03-15', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (23, 'Water Bill — March', 'Utilities', 3600.00, 'Cash', 'NWS&DB monthly', '2026-03-18', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (24, 'Security Service — March', 'Other', 15000.00, 'Bank Transfer', 'Monthly security contract', '2026-03-20', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (26, 'Fire Extinguisher Refill', 'Maintenance', 8500.00, 'Cash', 'Annual safety compliance', '2026-03-15', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (27, 'Promotional Banners', 'Other', 6500.00, 'Cash', 'New price board and banners', '2026-03-05', '2026-03-24 16:14:27.127275', '2026-03-24 16:14:27.127275');
INSERT INTO public.expenses VALUES (31, 'daily', 'Other', 500.00, 'Cash', '', '2026-04-06', '2026-04-13 22:39:08.364166', '2026-04-13 22:39:08.364166');
INSERT INTO public.expenses VALUES (32, 'daily', 'Other', 700.00, 'Cash', '', '2026-04-07', '2026-04-13 22:39:22.074728', '2026-04-13 22:39:22.074728');
INSERT INTO public.expenses VALUES (30, 'Salaries to employees', 'Other', 123456.00, 'Bank Transfer', '', '2026-04-13', '2026-04-13 15:13:18.729591', '2026-04-13 15:13:18.729591');


--
-- TOC entry 4021 (class 0 OID 16911)
-- Dependencies: 256
-- Data for Name: fire_events; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.fire_events VALUES (1, 'TANK_001', 0, 0, 25.6875, true, 'detected', 'event_1', 270440, '2026-03-23 09:30:48.387068');
INSERT INTO public.fire_events VALUES (2, 'TANK_001', 0, 0, 25.9375, true, 'detected', 'event_2', 108345, '2026-03-23 09:30:48.389541');


--
-- TOC entry 4015 (class 0 OID 16861)
-- Dependencies: 248
-- Data for Name: fuel_deliveries; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (1, '2026-01-05', 1, 'CPC-2026-001', '92 Octane', 12000.00, 293.00, 3516000.00, 'WP-LT-3421', 'Sunil Bandara', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (2, '2026-01-05', 1, 'CPC-2026-002', 'Auto Diesel', 18000.00, 268.00, 4824000.00, 'WP-LT-3421', 'Sunil Bandara', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (3, '2026-01-08', 2, 'IOC-2026-001', '95 Octane', 8000.00, 340.00, 2720000.00, 'NB-LT-5566', 'Roshan Kumara', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (4, '2026-01-12', 1, 'CPC-2026-003', 'Super Diesel', 6000.00, 322.00, 1932000.00, 'NB-LT-1122', 'Pradeep Silva', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (5, '2026-01-20', 1, 'CPC-2026-004', '92 Octane', 14000.00, 293.00, 4102000.00, 'WP-LT-7788', 'Nimal Fernando', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (6, '2026-01-20', 1, 'CPC-2026-005', 'Auto Diesel', 20000.00, 268.00, 5360000.00, 'WP-LT-7788', 'Nimal Fernando', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (7, '2026-02-03', 1, 'CPC-2026-006', '92 Octane', 12000.00, 296.00, 3552000.00, 'WP-LT-3421', 'Sunil Bandara', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (8, '2026-02-03', 5, 'TOT-2026-001', 'Auto Diesel', 15000.00, 271.00, 4065000.00, 'NB-LT-9900', 'Kamal Jayawardena', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (9, '2026-02-10', 2, 'IOC-2026-002', '95 Octane', 9000.00, 343.00, 3087000.00, 'NB-LT-5566', 'Roshan Kumara', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (10, '2026-02-18', 1, 'CPC-2026-007', '92 Octane', 15000.00, 299.00, 4485000.00, 'WP-LT-3421', 'Sunil Bandara', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (11, '2026-02-18', 1, 'CPC-2026-008', 'Auto Diesel', 22000.00, 274.00, 6028000.00, 'WP-LT-7788', 'Nimal Fernando', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (12, '2026-02-25', 1, 'CPC-2026-009', 'Super Diesel', 7000.00, 328.00, 2296000.00, 'NB-LT-1122', 'Pradeep Silva', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (13, '2026-03-05', 1, 'CPC-2026-010', '92 Octane', 16000.00, 299.00, 4784000.00, 'WP-LT-3421', 'Sunil Bandara', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (14, '2026-03-05', 5, 'TOT-2026-002', 'Auto Diesel', 24000.00, 274.00, 6576000.00, 'NB-LT-9900', 'Kamal Jayawardena', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (15, '2026-03-12', 2, 'IOC-2026-003', '95 Octane', 10000.00, 346.00, 3460000.00, 'NB-LT-5566', 'Roshan Kumara', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (16, '2026-03-18', 1, 'CPC-2026-011', '92 Octane', 18000.00, 299.00, 5382000.00, 'WP-LT-7788', 'Nimal Fernando', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (17, '2026-03-18', 1, 'CPC-2026-012', 'Auto Diesel', 25000.00, 274.00, 6850000.00, 'WP-LT-3421', 'Sunil Bandara', 'Admin', NULL, '2026-03-24 16:14:27.127275');
INSERT INTO public.fuel_deliveries OVERRIDING SYSTEM VALUE VALUES (18, '2026-03-22', 1, 'CPC-2026-013', 'Super Diesel', 8000.00, 330.00, 2640000.00, 'NB-LT-1122', 'Pradeep Silva', 'Admin', NULL, '2026-03-24 16:14:27.127275');


--
-- TOC entry 4005 (class 0 OID 16726)
-- Dependencies: 238
-- Data for Name: fuel_prices; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.fuel_prices OVERRIDING SYSTEM VALUE VALUES (2, '95 Octane', 382.00, '2026-02-15', 'Admin', 'CPC rate', '2026-03-04 17:17:27.577022', '2026-03-04 17:17:27.577022');
INSERT INTO public.fuel_prices OVERRIDING SYSTEM VALUE VALUES (3, 'Auto Diesel', 305.00, '2026-02-15', 'Admin', 'CPC rate', '2026-03-04 17:17:27.577022', '2026-03-04 17:17:27.577022');
INSERT INTO public.fuel_prices OVERRIDING SYSTEM VALUE VALUES (4, 'Super Diesel', 365.00, '2026-02-15', 'Admin', 'CPC rate', '2026-03-04 17:17:27.577022', '2026-03-04 17:17:27.577022');
INSERT INTO public.fuel_prices OVERRIDING SYSTEM VALUE VALUES (1, '92 Octane', 328.00, '2026-04-11', 'Bedde Damiru', '', '2026-03-04 17:17:27.577022', '2026-04-11 12:00:53.420827');


--
-- TOC entry 4017 (class 0 OID 16884)
-- Dependencies: 252
-- Data for Name: fuel_tanks; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.fuel_tanks VALUES (3, '3P', '95 Petrol', 9000, 5400, 1500, NULL, 'Underground — Bay B', NULL, '2026-03-23 14:39:37.372133', '2026-03-23 14:39:37.372133');
INSERT INTO public.fuel_tanks VALUES (5, '1SD', 'Super Diesel', 9000, 3200, 1500, NULL, 'Underground — Bay C', NULL, '2026-03-23 14:39:37.372133', '2026-03-23 14:39:37.372133');
INSERT INTO public.fuel_tanks VALUES (4, '1AD', 'Auto Diesel', 25000, 17000, 4000, NULL, 'Underground — Bay C', NULL, '2026-04-11 12:29:10.248111', '2026-03-23 14:39:37.372133');
INSERT INTO public.fuel_tanks VALUES (2, '2P', '92 Petrol', 9000, 1200, 1500, NULL, 'Underground — Bay A', NULL, '2026-04-12 16:42:13.136579', '2026-03-23 14:39:37.372133');
INSERT INTO public.fuel_tanks VALUES (1, '1P', '92 Petrol', 14490, 5000, 2000, 'TANK_001', 'Underground — Bay A', 'IoT monitored tank', '2026-04-13 12:15:17.999421', '2026-03-23 14:39:37.372133');


--
-- TOC entry 3997 (class 0 OID 16639)
-- Dependencies: 230
-- Data for Name: invoice_payment_links; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.invoice_payment_links VALUES (1, 1, 1, 3516000);
INSERT INTO public.invoice_payment_links VALUES (2, 2, 2, 4824000);
INSERT INTO public.invoice_payment_links VALUES (3, 3, 3, 2720000);
INSERT INTO public.invoice_payment_links VALUES (4, 4, 4, 1932000);
INSERT INTO public.invoice_payment_links VALUES (5, 5, 5, 4102000);
INSERT INTO public.invoice_payment_links VALUES (6, 6, 6, 2500000);
INSERT INTO public.invoice_payment_links VALUES (7, 7, 7, 68150);
INSERT INTO public.invoice_payment_links VALUES (8, 8, 8, 51000);
INSERT INTO public.invoice_payment_links VALUES (9, 9, 9, 3552000);
INSERT INTO public.invoice_payment_links VALUES (10, 10, 10, 2000000);
INSERT INTO public.invoice_payment_links VALUES (11, 12, 11, 4485000);
INSERT INTO public.invoice_payment_links VALUES (12, 13, 12, 3000000);
INSERT INTO public.invoice_payment_links VALUES (13, 14, 13, 54750);


--
-- TOC entry 4019 (class 0 OID 16899)
-- Dependencies: 254
-- Data for Name: iot_readings; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.iot_readings VALUES (1, 'TANK_001', 63.5, 9201.15, 26.2, 52.8, false, false, false, 'normal', '2026-01-01 08:00:00');
INSERT INTO public.iot_readings VALUES (2, 'TANK_001', 62.8, 9099.72, 26.5, 53.1, false, false, false, 'normal', '2026-01-01 13:00:00');
INSERT INTO public.iot_readings VALUES (3, 'TANK_001', 61.9, 8969.31, 27.1, 53.6, false, false, false, 'normal', '2026-01-01 18:00:00');
INSERT INTO public.iot_readings VALUES (4, 'TANK_001', 58.2, 8432.58, 26.8, 55.2, false, false, false, 'normal', '2026-01-05 08:00:00');
INSERT INTO public.iot_readings VALUES (5, 'TANK_001', 54.6, 7911.54, 27.3, 57, false, false, false, 'normal', '2026-01-10 08:00:00');
INSERT INTO public.iot_readings VALUES (6, 'TANK_001', 50.1, 7259.49, 27.8, 59.4, false, false, false, 'normal', '2026-01-15 08:00:00');
INSERT INTO public.iot_readings VALUES (7, 'TANK_001', 72.4, 10490.76, 26.1, 47.2, false, false, false, 'normal', '2026-01-20 10:00:00');
INSERT INTO public.iot_readings VALUES (8, 'TANK_001', 68.8, 9969.12, 26.4, 49.1, false, false, false, 'normal', '2026-01-25 08:00:00');
INSERT INTO public.iot_readings VALUES (9, 'TANK_001', 65.2, 9446.28, 26.9, 50.8, false, false, false, 'normal', '2026-01-31 08:00:00');
INSERT INTO public.iot_readings VALUES (10, 'TANK_001', 61.5, 8910.35, 27.2, 52.7, false, false, false, 'normal', '2026-02-05 08:00:00');
INSERT INTO public.iot_readings VALUES (11, 'TANK_001', 58, 8404.2, 27.6, 54.5, false, false, false, 'normal', '2026-02-10 08:00:00');
INSERT INTO public.iot_readings VALUES (12, 'TANK_001', 54.3, 7870.47, 28.1, 56.3, false, false, false, 'normal', '2026-02-15 08:00:00');
INSERT INTO public.iot_readings VALUES (13, 'TANK_001', 71.8, 10403.82, 26.3, 47.6, false, false, false, 'normal', '2026-02-20 10:00:00');
INSERT INTO public.iot_readings VALUES (14, 'TANK_001', 67.9, 9838.11, 26.7, 49.5, false, false, false, 'normal', '2026-02-25 08:00:00');
INSERT INTO public.iot_readings VALUES (15, 'TANK_001', 64.1, 9289.29, 27, 51.4, false, false, false, 'normal', '2026-03-01 08:00:00');
INSERT INTO public.iot_readings VALUES (16, 'TANK_001', 60.5, 8766.45, 27.4, 53.2, false, false, false, 'normal', '2026-03-05 08:00:00');
INSERT INTO public.iot_readings VALUES (17, 'TANK_001', 57.2, 8288.28, 27.9, 55, false, false, false, 'normal', '2026-03-10 08:00:00');
INSERT INTO public.iot_readings VALUES (18, 'TANK_001', 53.8, 7795.62, 28.3, 56.7, false, false, false, 'normal', '2026-03-15 08:00:00');
INSERT INTO public.iot_readings VALUES (19, 'TANK_001', 72.1, 10447.29, 26.2, 47.4, false, false, false, 'normal', '2026-03-18 10:00:00');
INSERT INTO public.iot_readings VALUES (20, 'TANK_001', 68.4, 9910.76, 26.5, 49.3, false, false, false, 'normal', '2026-03-22 08:00:00');
INSERT INTO public.iot_readings VALUES (21, 'TANK_001', 65.8, 9534.42, 26.8, 50.9, false, false, false, 'normal', '2026-03-24 08:00:00');
INSERT INTO public.iot_readings VALUES (22, 'TANK_001', 0, 0, 23.3125, 24.7303, false, false, false, 'warning', '2026-04-13 12:08:38.356483');


--
-- TOC entry 3989 (class 0 OID 16578)
-- Dependencies: 222
-- Data for Name: lubricant_purchases; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.lubricant_purchases VALUES (1, 1, 'Castrol Lanka Ltd.', 60, 620, 37200, 'CST-2026-001', 'GTX 5W-30 restock', '2026-01-05', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (2, 2, 'Shell Lanka (Pvt) Ltd.', 40, 680, 27200, 'SHL-2026-001', 'Helix Ultra restock', '2026-01-08', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (3, 3, 'Havoline Lanka', 20, 390, 7800, 'HAV-2026-001', 'ATF Dexron restock', '2026-01-10', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (4, 4, 'Total Energies Lanka', 80, 340, 27200, 'TOT-2026-001', 'Hydraulic 68 restock', '2026-01-12', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (5, 5, 'Mobil Lanka', 15, 210, 3150, 'MOB-2026-001', 'MP Grease restock', '2026-01-15', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (6, 6, 'Bosch Lanka', 30, 190, 5700, 'BSH-2026-001', 'DOT 4 Brake Fluid', '2026-01-18', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (7, 7, 'Prestone Lanka', 25, 280, 7000, 'PRE-2026-001', 'Coolant restock', '2026-01-20', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (8, 1, 'Castrol Lanka Ltd.', 50, 620, 31000, 'CST-2026-002', 'GTX 5W-30 Feb restock', '2026-02-10', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (9, 2, 'Shell Lanka (Pvt) Ltd.', 35, 680, 23800, 'SHL-2026-002', 'Helix Ultra Feb restock', '2026-02-12', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (10, 4, 'Total Energies Lanka', 60, 340, 20400, 'TOT-2026-002', 'Hydraulic 68 Feb restock', '2026-02-15', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (11, 1, 'Castrol Lanka Ltd.', 70, 625, 43750, 'CST-2026-003', 'GTX 5W-30 Mar restock', '2026-03-08', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (12, 2, 'Shell Lanka (Pvt) Ltd.', 45, 685, 30825, 'SHL-2026-003', 'Helix Ultra Mar restock', '2026-03-10', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (13, 3, 'Havoline Lanka', 25, 395, 9875, 'HAV-2026-002', 'ATF Dexron Mar restock', '2026-03-12', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_purchases VALUES (14, 6, 'Bosch Lanka', 40, 192, 7680, 'BSH-2026-002', 'DOT 4 Mar restock', '2026-03-15', '2026-03-24 16:14:27.127275');


--
-- TOC entry 3987 (class 0 OID 16563)
-- Dependencies: 220
-- Data for Name: lubricant_sales; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.lubricant_sales VALUES (1, 1, 'Walk-in', 4, 850, 3400, 'Cash', '', '2026-01-04', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (2, 2, 'Nimal Silva', 2, 920, 1840, 'Cash', '', '2026-01-05', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (3, 1, 'Walk-in', 6, 850, 5100, 'Cash', '', '2026-01-07', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (4, 4, 'Walk-in', 5, 480, 2400, 'Cash', '', '2026-01-08', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (5, 3, 'Kumara Motors', 4, 550, 2200, 'Cash', '', '2026-01-09', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (6, 1, 'Walk-in', 8, 850, 6800, 'Cash', '', '2026-01-11', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (7, 6, 'Walk-in', 6, 290, 1740, 'Cash', '', '2026-01-12', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (8, 2, 'Perera Garage', 4, 920, 3680, 'Card', '', '2026-01-14', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (9, 5, 'Walk-in', 3, 320, 960, 'Cash', '', '2026-01-15', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (10, 1, 'Walk-in', 5, 850, 4250, 'Cash', '', '2026-01-17', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (11, 7, 'Walk-in', 4, 410, 1640, 'Cash', '', '2026-01-18', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (12, 4, 'Industrial Ltd', 20, 480, 9600, 'Bank Transfer', 'Bulk order', '2026-01-20', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (13, 1, 'Walk-in', 7, 850, 5950, 'Cash', '', '2026-01-21', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (14, 2, 'Walk-in', 3, 920, 2760, 'Cash', '', '2026-01-23', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (15, 6, 'Walk-in', 8, 290, 2320, 'Cash', '', '2026-01-24', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (16, 1, 'Walk-in', 6, 850, 5100, 'Cash', '', '2026-01-26', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (17, 3, 'Walk-in', 3, 550, 1650, 'Cash', '', '2026-01-27', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (18, 1, 'Walk-in', 9, 850, 7650, 'Cash', '', '2026-01-29', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (19, 2, 'Silva Auto', 5, 920, 4600, 'Card', '', '2026-01-30', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (20, 1, 'Walk-in', 8, 850, 6800, 'Cash', '', '2026-02-02', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (21, 4, 'Walk-in', 6, 480, 2880, 'Cash', '', '2026-02-04', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (22, 2, 'Walk-in', 4, 920, 3680, 'Cash', '', '2026-02-05', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (23, 1, 'Walk-in', 10, 850, 8500, 'Cash', '', '2026-02-07', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (24, 6, 'Walk-in', 8, 290, 2320, 'Cash', '', '2026-02-08', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (25, 5, 'Walk-in', 4, 320, 1280, 'Cash', '', '2026-02-10', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (26, 4, 'Road Works Ltd', 25, 480, 12000, 'Bank Transfer', 'Bulk order', '2026-02-12', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (27, 1, 'Walk-in', 7, 850, 5950, 'Cash', '', '2026-02-13', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (28, 2, 'Walk-in', 5, 920, 4600, 'Cash', '', '2026-02-14', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (29, 3, 'Walk-in', 4, 550, 2200, 'Cash', '', '2026-02-17', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (30, 1, 'Walk-in', 9, 850, 7650, 'Cash', '', '2026-02-18', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (31, 7, 'Walk-in', 6, 410, 2460, 'Cash', '', '2026-02-19', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (32, 1, 'Walk-in', 11, 850, 9350, 'Cash', '', '2026-02-21', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (33, 2, 'Jayawardhana Motors', 6, 920, 5520, 'Card', '', '2026-02-22', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (34, 1, 'Walk-in', 8, 850, 6800, 'Cash', '', '2026-02-24', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (35, 6, 'Walk-in', 10, 290, 2900, 'Cash', '', '2026-02-25', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (36, 1, 'Walk-in', 12, 850, 10200, 'Cash', '', '2026-02-27', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (37, 1, 'Walk-in', 10, 850, 8500, 'Cash', '', '2026-03-02', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (38, 2, 'Walk-in', 6, 920, 5520, 'Cash', '', '2026-03-03', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (39, 4, 'Walk-in', 8, 480, 3840, 'Cash', '', '2026-03-04', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (40, 1, 'Walk-in', 12, 850, 10200, 'Cash', '', '2026-03-06', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (41, 6, 'Walk-in', 10, 290, 2900, 'Cash', '', '2026-03-07', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (42, 3, 'Walk-in', 5, 550, 2750, 'Cash', '', '2026-03-08', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (43, 4, 'Construction Co', 30, 480, 14400, 'Bank Transfer', 'Bulk order', '2026-03-10', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (44, 1, 'Walk-in', 11, 850, 9350, 'Cash', '', '2026-03-11', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (45, 2, 'Walk-in', 7, 920, 6440, 'Card', '', '2026-03-12', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (46, 5, 'Walk-in', 5, 320, 1600, 'Cash', '', '2026-03-13', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (47, 1, 'Walk-in', 13, 850, 11050, 'Cash', '', '2026-03-14', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (48, 7, 'Walk-in', 8, 410, 3280, 'Cash', '', '2026-03-15', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (49, 1, 'Walk-in', 14, 850, 11900, 'Cash', '', '2026-03-17', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (50, 2, 'Walk-in', 8, 920, 7360, 'Cash', '', '2026-03-18', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (51, 6, 'Walk-in', 12, 290, 3480, 'Cash', '', '2026-03-19', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (52, 1, 'Walk-in', 15, 850, 12750, 'Cash', '', '2026-03-20', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (53, 4, 'Walk-in', 10, 480, 4800, 'Cash', '', '2026-03-21', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (54, 1, 'Walk-in', 16, 850, 13600, 'Cash', '', '2026-03-22', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (55, 2, 'Walk-in', 9, 920, 8280, 'Card', '', '2026-03-23', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricant_sales VALUES (56, 1, 'Walk-in', 14, 850, 11900, 'Cash', '', '2026-03-24', '2026-03-24 16:14:27.127275');


--
-- TOC entry 3985 (class 0 OID 16550)
-- Dependencies: 218
-- Data for Name: lubricants; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.lubricants VALUES (2, 'Helix Ultra 5W-40', 'Shell', '5W-40', 'Engine Oil', 'Liters', 920, 680, 91, 10, 'Premium synthetic', '2026-02-24 22:47:36.727677', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricants VALUES (4, 'Hydraulic 68', 'Total', 'ISO 68', 'Hydraulic Oil', 'Liters', 480, 340, 96, 15, 'Industrial hydraulic oil', '2026-02-24 22:47:36.727677', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricants VALUES (6, 'DOT 4 Brake Fluid', 'Bosch', 'DOT 4', 'Brake Fluid', 'Bottles', 290, 190, 36, 5, '500ml bottles', '2026-02-24 22:47:36.727677', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricants VALUES (7, 'Coolant Green', 'Prestone', '-37C', 'Coolant', 'Liters', 410, 280, 7, 5, 'Pre-mixed coolant', '2026-02-24 22:47:36.727677', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricants VALUES (1, 'GTX 5W-30', 'Castrol', '5W-30', 'Engine Oil', 'Liters', 850, 620, 3, 10, 'Full synthetic engine oil', '2026-02-24 22:47:36.727677', '2026-03-24 16:14:27.127275');
INSERT INTO public.lubricants VALUES (5, 'MP Grease', 'Mobil', 'NLGI 2', 'Grease', 'Kg', 320, 210, 8, 8, 'Multi-purpose lithium grease', '2026-02-24 22:47:36.727677', '2026-04-13 21:40:51.20166');
INSERT INTO public.lubricants VALUES (3, 'ATF Dexron III', 'Havoline', 'DEX-III', 'Gear Oil', 'Liters', 550, 390, 37, 10, 'Automatic transmission fluid', '2026-02-24 22:47:36.727677', '2026-04-13 21:48:05.967076');


--
-- TOC entry 4003 (class 0 OID 16701)
-- Dependencies: 236
-- Data for Name: pump_faults; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.pump_faults VALUES (1, 9, '2026-04-13', 'senith', 'not operating', 'High', 'Open', NULL, '', '2026-04-13 21:28:28.264067');


--
-- TOC entry 4001 (class 0 OID 16685)
-- Dependencies: 234
-- Data for Name: pump_maintenances; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.pump_maintenances VALUES (1, 1, '2026-01-12', 'Kamal Silva', 'Quarterly service: filter, calibration, hose check', 9500, '2026-04-12', 'All systems normal', '2026-03-24 16:14:27.127275');
INSERT INTO public.pump_maintenances VALUES (2, 3, '2026-01-18', 'Nimal Perera', 'Nozzle replacement and flow test', 7200, '2026-04-18', 'New nozzle fitted', '2026-03-24 16:14:27.127275');
INSERT INTO public.pump_maintenances VALUES (3, 5, '2026-02-05', 'Kamal Silva', 'High-volume pump full service — 6-month interval', 14000, '2026-08-05', 'Flow meter recalibrated', '2026-03-24 16:14:27.127275');
INSERT INTO public.pump_maintenances VALUES (4, 2, '2026-02-14', 'External Tech', 'Filter replacement and pressure check', 6800, '2026-05-14', 'Normal wear', '2026-03-24 16:14:27.127275');
INSERT INTO public.pump_maintenances VALUES (5, 7, '2026-03-02', 'Nimal Perera', 'Super diesel pump — annual service', 11000, '2026-09-02', 'Vapour recovery checked', '2026-03-24 16:14:27.127275');
INSERT INTO public.pump_maintenances VALUES (6, 1, '2026-03-15', 'Kamal Silva', 'Meter drift correction and hose replacement', 8500, '2026-06-15', 'Meter was 0.3% off, corrected', '2026-03-24 16:14:27.127275');
INSERT INTO public.pump_maintenances VALUES (7, 6, '2026-03-20', 'External Tech', 'Post-overhaul inspection and sign-off', 18000, '2026-09-20', 'Pump back to full operation', '2026-03-24 16:14:27.127275');


--
-- TOC entry 3999 (class 0 OID 16664)
-- Dependencies: 232
-- Data for Name: pumps; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.pumps VALUES (6, 'P-06', 'Pump 6 — Island C', 'Auto Diesel', 'Under Maintenance', 198500, '2024-06-01', '2024-08-01', 7, NULL, 'Flow meter replacement in progress', '2026-03-04 14:27:40.613208', '2026-03-04 14:27:40.613208');
INSERT INTO public.pumps VALUES (4, 'P-04', 'Pump 4 — Island B', '95 Octane', 'Inactive', 76800, '2024-04-15', '2024-06-15', 7, NULL, 'Scheduled for service', '2026-03-04 14:27:40.613208', '2026-03-04 15:04:45.6351');
INSERT INTO public.pumps VALUES (3, 'P-03', 'Pump 3 — Island B', '95 Octane', 'Under Maintenance', 89400, '2024-05-20', '2024-07-20', 7, NULL, 'Forecourt B, left side', '2026-03-04 14:27:40.613208', '2026-03-04 15:07:05.438316');
INSERT INTO public.pumps VALUES (7, 'P-07', 'Pump 7 — Island D', 'Super Diesel', 'Inactive', 55200, '2024-05-25', '2024-07-25', 7, NULL, 'Premium diesel — forecourt D', '2026-03-04 14:27:40.613208', '2026-03-04 15:07:41.119851');
INSERT INTO public.pumps VALUES (8, 'P-08', 'Pump 8 — Island D', 'Super Diesel', 'Active', 52000, '2024-05-28', '2024-07-28', 7, 7, 'Premium diesel — forecourt D', '2026-03-04 14:27:40.613208', '2026-03-04 15:26:24.036766');
INSERT INTO public.pumps VALUES (1, 'P-01', 'Pump 1 — Island A', '92 Octane', 'Active', 142500, '2024-05-10', '2026-08-12', 7, NULL, 'Forecourt A, left side', '2026-03-04 14:27:40.613208', '2026-03-30 06:49:27.323354');
INSERT INTO public.pumps VALUES (9, 'P-09', 'Pump 9 — Island A', '92 Octane', 'Inactive', 500, '2026-03-03', '2027-03-03', 7, 7, 'New Pump', '2026-03-04 15:42:48.984221', '2026-04-13 21:28:28.264067');
INSERT INTO public.pumps VALUES (5, 'P-05', 'Pump 5 — Island C', 'Auto Diesel', 'Active', 210000, '2024-05-01', '2024-07-01', 7, NULL, 'High-volume diesel pump', '2026-03-04 14:27:40.613208', '2026-04-13 21:42:12.665346');
INSERT INTO public.pumps VALUES (2, 'P-02', 'Pump 2 — Island A', '92 Octane', 'Active', 138200, '2026-03-04', '2028-04-13', 7, NULL, 'Forecourt A, right side', '2026-03-04 14:27:40.613208', '2026-04-13 21:43:55.111839');


--
-- TOC entry 3977 (class 0 OID 16480)
-- Dependencies: 210
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.roles VALUES (1, 'Admin', 'Full system access');
INSERT INTO public.roles VALUES (2, 'Manager', 'Manage station operations');
INSERT INTO public.roles VALUES (3, 'Cashier', 'Handles sales and billing');
INSERT INTO public.roles VALUES (4, 'Pump Attendant', 'Handles fuel dispensing at pumps');
INSERT INTO public.roles VALUES (7, 'Station Owner', 'Owner of the Fuel Station');


--
-- TOC entry 3981 (class 0 OID 16518)
-- Dependencies: 214
-- Data for Name: staff_shifts; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.staff_shifts VALUES (207, 5, 4, '2026-03-27', '12:50:00', '17:56:00', 'Pump operation');
INSERT INTO public.staff_shifts VALUES (208, 8, 7, '2026-03-30', '07:10:00', '11:53:00', 'Pump operation');
INSERT INTO public.staff_shifts VALUES (209, 5, 4, '2026-03-30', '13:58:00', '19:55:00', 'Pump operation');
INSERT INTO public.staff_shifts VALUES (210, 8, 7, '2026-04-10', '16:11:00', '00:11:00', '');
INSERT INTO public.staff_shifts VALUES (211, 8, 7, '2026-04-11', '21:24:00', '00:24:00', '');
INSERT INTO public.staff_shifts VALUES (212, 7, 4, '2026-04-12', '22:19:00', '01:19:00', 'Pump operation');
INSERT INTO public.staff_shifts VALUES (213, 7, 4, '2026-04-13', '17:04:00', '23:04:00', 'Pump operation');
INSERT INTO public.staff_shifts VALUES (215, 5, 4, '2026-04-13', '17:10:00', '22:29:00', '');
INSERT INTO public.staff_shifts VALUES (216, 8, 7, '2026-04-13', '20:19:00', '00:19:00', '');
INSERT INTO public.staff_shifts VALUES (13, 1, 1, '2025-06-20', '08:00:00', '14:00:00', 'Admin shift day 2');
INSERT INTO public.staff_shifts VALUES (15, 3, 3, '2025-06-20', '20:00:00', '23:59:00', 'Cashier shift day 2');
INSERT INTO public.staff_shifts VALUES (18, 3, 1, '2025-06-21', '12:00:00', '20:00:00', 'Cashier temporarily promoted');
INSERT INTO public.staff_shifts VALUES (19, 3, 1, '2025-06-20', '12:30:00', '06:30:00', 'day');
INSERT INTO public.staff_shifts VALUES (20, 3, 1, '2025-06-20', '12:30:00', '06:30:00', 'day');
INSERT INTO public.staff_shifts VALUES (217, 3, 2, '2026-04-14', '04:30:00', '18:30:00', '');
INSERT INTO public.staff_shifts VALUES (11, 1, 1, '2025-06-18', '23:00:00', '09:00:00', 'Afternoon shift for Manager');
INSERT INTO public.staff_shifts VALUES (14, 1, 1, '2025-06-18', '01:00:00', '04:00:00', 'Manager shift day 2');
INSERT INTO public.staff_shifts VALUES (17, 4, 3, '2025-06-20', '02:30:00', '04:30:00', 'Manager acting as cashier');
INSERT INTO public.staff_shifts VALUES (21, 4, NULL, '2025-06-17', '12:12:00', '03:04:00', 'csvs');
INSERT INTO public.staff_shifts VALUES (22, 6, 4, '2025-06-24', '21:00:00', '01:00:00', 'wwww');
INSERT INTO public.staff_shifts VALUES (16, 1, 2, '2025-06-21', '02:30:00', '04:30:00', 'Special manager shift by admin');
INSERT INTO public.staff_shifts VALUES (23, 3, 2, '2025-06-24', '06:30:00', '08:30:00', 'manager');
INSERT INTO public.staff_shifts VALUES (24, 5, 4, '2025-06-23', '03:30:00', '07:30:00', 'pumper');
INSERT INTO public.staff_shifts VALUES (25, 1, 1, '2025-06-26', '12:30:00', '03:30:00', 'admin');
INSERT INTO public.staff_shifts VALUES (26, 1, 1, '2025-06-27', '05:30:00', '07:30:00', 'morning');
INSERT INTO public.staff_shifts VALUES (27, 4, 3, '2025-06-28', '20:30:00', '23:00:00', 'morning');
INSERT INTO public.staff_shifts VALUES (28, 7, 4, '2025-06-25', '12:30:00', '14:30:00', 'day');
INSERT INTO public.staff_shifts VALUES (30, 3, 2, '2026-03-19', '13:54:00', '19:54:00', 'Pump operation');


--
-- TOC entry 4022 (class 0 OID 16922)
-- Dependencies: 257
-- Data for Name: station_settings; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.station_settings VALUES (1, 'BKS Damiru Filling Station', 'Pore, Athurugiriya, Sri Lanka', '+94 706 696 269', 'senith@gmail.com', 'FS-2026-001', 'uploads/ft01.png', '2026-04-12 16:40:40.294452');


--
-- TOC entry 3993 (class 0 OID 16608)
-- Dependencies: 226
-- Data for Name: supplier_invoices; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.supplier_invoices VALUES (1, 1, 'CPC-INV-2026-001', 'Fuel', '92 Octane delivery 12,000L Jan 5', 3516000, '2026-01-05', '2026-02-05', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (2, 1, 'CPC-INV-2026-002', 'Fuel', 'Auto Diesel delivery 18,000L Jan 5', 4824000, '2026-01-05', '2026-02-05', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (3, 2, 'IOC-INV-2026-001', 'Fuel', '95 Octane delivery 8,000L Jan 8', 2720000, '2026-01-08', '2026-02-22', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (4, 1, 'CPC-INV-2026-003', 'Fuel', 'Super Diesel 6,000L Jan 12', 1932000, '2026-01-12', '2026-02-12', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (5, 1, 'CPC-INV-2026-004', 'Fuel', '92 Octane 14,000L Jan 20', 4102000, '2026-01-20', '2026-02-20', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (7, 3, 'CST-INV-2026-001', 'Lubricant', 'Castrol lubricant order Jan', 68150, '2026-01-05', '2026-02-05', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (8, 4, 'SHL-INV-2026-001', 'Lubricant', 'Shell lubricant order Jan', 51000, '2026-01-08', '2026-02-08', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (9, 1, 'CPC-INV-2026-006', 'Fuel', '92 Octane 12,000L Feb 3', 3552000, '2026-02-03', '2026-03-05', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (11, 2, 'IOC-INV-2026-002', 'Fuel', '95 Octane 9,000L Feb 10', 3087000, '2026-02-10', '2026-03-26', 'Unpaid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (12, 1, 'CPC-INV-2026-007', 'Fuel', '92 Octane 15,000L Feb 18', 4485000, '2026-02-18', '2026-03-20', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (14, 3, 'CST-INV-2026-002', 'Lubricant', 'Castrol lubricant Feb restock', 54750, '2026-02-10', '2026-03-10', 'Paid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (15, 1, 'CPC-INV-2026-009', 'Fuel', 'Super Diesel 7,000L Feb 25', 2296000, '2026-02-25', '2026-03-27', 'Unpaid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (16, 1, 'CPC-INV-2026-010', 'Fuel', '92 Octane 16,000L Mar 5', 4784000, '2026-03-05', '2026-04-05', 'Unpaid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (17, 5, 'TOT-INV-2026-002', 'Fuel', 'Auto Diesel 24,000L Mar 5', 6576000, '2026-03-05', '2026-05-03', 'Unpaid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (18, 2, 'IOC-INV-2026-003', 'Fuel', '95 Octane 10,000L Mar 12', 3460000, '2026-03-12', '2026-04-26', 'Unpaid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (19, 3, 'CST-INV-2026-003', 'Lubricant', 'Castrol lubricant Mar restock', 74575, '2026-03-08', '2026-04-08', 'Unpaid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (20, 4, 'SHL-INV-2026-002', 'Lubricant', 'Shell lubricant Mar restock', 30825, '2026-03-10', '2026-04-10', 'Unpaid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (21, 1, 'CPC-INV-2026-011', 'Fuel', '92 Octane 18,000L Mar 18', 5382000, '2026-03-18', '2026-04-18', 'Unpaid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (22, 1, 'CPC-INV-2026-012', 'Fuel', 'Auto Diesel 25,000L Mar 18', 6850000, '2026-03-18', '2026-04-18', 'Unpaid', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (6, 1, 'CPC-INV-2026-005', 'Fuel', 'Auto Diesel 20,000L Jan 20', 5360000, '2026-01-20', '2026-02-20', 'Partial', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (10, 5, 'TOT-INV-2026-001', 'Fuel', 'Auto Diesel 15,000L Feb 3', 4065000, '2026-02-03', '2026-04-03', 'Partial', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (13, 1, 'CPC-INV-2026-008', 'Fuel', 'Auto Diesel 22,000L Feb 18', 6028000, '2026-02-18', '2026-03-20', 'Partial', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_invoices VALUES (23, 3, 'INV-2026-200', 'Fuel', 'TEST INVOICE', 50000, '2026-04-13', '2026-04-15', 'Unpaid', '2026-04-13 16:37:38.732424');


--
-- TOC entry 3995 (class 0 OID 16624)
-- Dependencies: 228
-- Data for Name: supplier_payments; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.supplier_payments VALUES (1, 1, 3516000, 'Bank Transfer', 'TXN-2026-001', 'CPC Jan delivery 1', '2026-02-03', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (2, 1, 4824000, 'Bank Transfer', 'TXN-2026-002', 'CPC Jan delivery 2', '2026-02-03', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (3, 2, 2720000, 'Bank Transfer', 'TXN-2026-003', 'IOC Jan delivery', '2026-02-20', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (4, 1, 1932000, 'Bank Transfer', 'TXN-2026-004', 'CPC super diesel', '2026-02-10', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (5, 1, 4102000, 'Bank Transfer', 'TXN-2026-005', 'CPC Jan 20 delivery', '2026-02-18', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (6, 1, 2500000, 'Bank Transfer', 'TXN-2026-006', 'CPC partial payment', '2026-02-25', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (7, 3, 68150, 'Cheque', 'CHQ-2026-001', 'Castrol Jan', '2026-02-01', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (8, 4, 51000, 'Cheque', 'CHQ-2026-002', 'Shell Jan', '2026-02-05', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (9, 1, 3552000, 'Bank Transfer', 'TXN-2026-007', 'CPC Feb delivery 1', '2026-03-03', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (10, 5, 2000000, 'Bank Transfer', 'TXN-2026-008', 'Total partial pay', '2026-03-10', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (11, 1, 4485000, 'Bank Transfer', 'TXN-2026-009', 'CPC Feb 18 delivery', '2026-03-18', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (12, 1, 3000000, 'Bank Transfer', 'TXN-2026-010', 'CPC partial diesel', '2026-03-20', '2026-03-24 16:14:27.127275');
INSERT INTO public.supplier_payments VALUES (13, 3, 54750, 'Cheque', 'CHQ-2026-003', 'Castrol Feb', '2026-03-08', '2026-03-24 16:14:27.127275');


--
-- TOC entry 3991 (class 0 OID 16595)
-- Dependencies: 224
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.suppliers VALUES (1, 'Ceylon Petroleum Corp.', 'Fuel', 'Rohan Perera', '+94 11 234 5678', 'rohan@ceypetro.lk', 'No. 1, York St, Colombo 1', 'VAT-1122334', NULL, 30, 'Main fuel supplier', true, '2026-02-25 11:10:36.129195', '2026-02-25 11:10:36.129195');
INSERT INTO public.suppliers VALUES (2, 'Lanka IOC PLC', 'Fuel', 'Nimal Silva', '+94 11 987 6543', 'nimal@lankaioc.lk', 'P.O. Box 400, Colombo 10', 'VAT-9988776', NULL, 45, 'Secondary fuel supplier', true, '2026-02-25 11:10:36.129195', '2026-02-25 11:10:36.129195');
INSERT INTO public.suppliers VALUES (3, 'Castrol Lanka Ltd.', 'Lubricant', 'Priya Fernando', '+94 11 456 7890', 'priya@castrol.lk', '120 Norris Canal Rd, Col 10', 'VAT-5544332', NULL, 30, 'Premium lubricants', true, '2026-02-25 11:10:36.129195', '2026-02-25 11:10:36.129195');
INSERT INTO public.suppliers VALUES (4, 'Shell Lanka (Pvt) Ltd.', 'Lubricant', 'Ayesha Malik', '+94 11 222 3344', 'ayesha@shell.lk', 'Shell House, Colombo 3', 'VAT-6677889', NULL, 30, 'Shell product range', true, '2026-02-25 11:10:36.129195', '2026-02-25 11:10:36.129195');
INSERT INTO public.suppliers VALUES (5, 'Total Energies Lanka', 'Both', 'Kamal Jayawardena', '+94 77 123 4567', 'kamal@total.lk', 'Grandpass, Colombo 14', 'VAT-3344556', NULL, 60, 'Fuel + lubes supplier', true, '2026-02-25 11:10:36.129195', '2026-02-25 11:10:36.129195');


--
-- TOC entry 3979 (class 0 OID 16498)
-- Dependencies: 212
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: senithdamiru
--

INSERT INTO public.users VALUES (8, 'Senith Damiru', 'senith2005@gmail.com', '+94706696269', 'scrypt:32768:8:1$Pvk3pLYBfC5lc0ZF$07160795390e1fb99ef4b8171b0a9759ee4ce483c04f78c1b3004785823022fbc056a4629cc99a0defc0ad3356b566537cb0b0cb3719b8b799097f6fe84c9fb0', 7, 'Active', '2026-03-19 17:16:57.190469', 'EMP-2025-007', 'uploads/IMG_3905.jpg');
INSERT INTO public.users VALUES (1, 'Bedde Damiru', 'senith1234@gmail.com', '+94714443919', 'scrypt:32768:8:1$k6dg2DPYucAkYWCU$a2a1728f72b8c57a9dc6051de7a0d07a7a4a965dc6b35a0ac08c9b37e6e97859e5f38d5cf74fb8413cb59ea28c7970cef886238ed76ba54756b4bbf9f5fa2b83', 1, 'Active', '2025-06-19 21:33:33.479514', 'EMP-2025-001', 'uploads/IMG_6219.jpg');
INSERT INTO public.users VALUES (5, 'Pulindu Nadil', 'pulindu@gmail.com', '+94706686968', 'scrypt:32768:8:1$n6TCCwLczvyqA7du$8dfe217d52818c21b31788bfe73ad4066f691441e2ae5286b1855944c5b6c5122411076acc693246329dac0f191fddbc27c040bdc5e492a4ce7c99c274f8d704', 4, 'Active', '2025-06-20 14:06:28.7135', 'EMP-2025-004', 'uploads/man-3.png');
INSERT INTO public.users VALUES (3, 'Hesara Nelikumar', 'hesara1234@gmail.com', '+94706696267', 'scrypt:32768:8:1$PL73JL1TG01SFEmO$7bcb8732dfff1a057ea153531f9eab4a3e292a89f49b99e3c6ddbd4695cd94612ef52eaba42c46cbe8838562df2a52153f36169b29473379c65a450957e7772d', 2, 'Active', '2025-06-19 22:53:25.323605', 'EMP-2025-002', 'uploads/img123.jpeg');
INSERT INTO public.users VALUES (6, 'Rovindu Siyathmin', 'rovindu@gmail.com', '+94712334565', 'scrypt:32768:8:1$iGjgZGZhPgaPaS8d$58d5426db47c634af00152c0cd5b221b50a216229d9f9fa328416df02a1c33cb071d8f8e5a1893539be9c390e98978f4823525984bd3c68fcc5133dbdd3c25e4', 4, 'Active', '2025-06-20 14:10:24.765352', 'EMP-2025-005', 'uploads/gas-station-attendant.png');
INSERT INTO public.users VALUES (4, 'Methul Lakvindu', 'methul@gmail.com', '+94716663919', 'scrypt:32768:8:1$NSh9qe85XNRMqNof$78f6a7af795ed08f15e8e32297b5c4f04028af31fac7a2596836682a7d584030c9554279da8366e5ad92f45272b2cc29466d283c0485c5189ebaff84181c6b2c', 3, 'On Leave', '2025-06-20 13:46:45.849811', 'EMP-2025-003', 'uploads/gamer.png');
INSERT INTO public.users VALUES (7, 'Kamal Perera', 'kamal@gmail.com', '+94714443919', 'scrypt:32768:8:1$2SeFVgB3ey58mpM3$184b1ff3e0d91b8ace4f38b0458c9ef13f61fbd3c40d3acb8386a68d5b2dcb644d5e41ee6507056b0802f32683b02eba960e9d925e0b6abe63e3355964caa354', 4, 'On Leave', '2025-06-20 14:12:55.338654', 'EPM-2025-006', 'uploads/gas-station-attendant-2.png');


--
-- TOC entry 4045 (class 0 OID 0)
-- Dependencies: 241
-- Name: credit_accounts_account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.credit_accounts_account_id_seq', 7, true);


--
-- TOC entry 4046 (class 0 OID 0)
-- Dependencies: 245
-- Name: credit_payments_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.credit_payments_payment_id_seq', 15, true);


--
-- TOC entry 4047 (class 0 OID 0)
-- Dependencies: 243
-- Name: credit_sales_credit_sale_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.credit_sales_credit_sale_id_seq', 31, true);


--
-- TOC entry 4048 (class 0 OID 0)
-- Dependencies: 239
-- Name: daily_sales_sale_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.daily_sales_sale_id_seq', 343, true);


--
-- TOC entry 4049 (class 0 OID 0)
-- Dependencies: 215
-- Name: expenses_expense_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.expenses_expense_id_seq', 32, true);


--
-- TOC entry 4050 (class 0 OID 0)
-- Dependencies: 255
-- Name: fire_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.fire_events_id_seq', 2, true);


--
-- TOC entry 4051 (class 0 OID 0)
-- Dependencies: 247
-- Name: fuel_deliveries_delivery_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.fuel_deliveries_delivery_id_seq', 20, true);


--
-- TOC entry 4052 (class 0 OID 0)
-- Dependencies: 237
-- Name: fuel_prices_price_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.fuel_prices_price_id_seq', 4, true);


--
-- TOC entry 4053 (class 0 OID 0)
-- Dependencies: 251
-- Name: fuel_tanks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.fuel_tanks_id_seq', 5, true);


--
-- TOC entry 4054 (class 0 OID 0)
-- Dependencies: 229
-- Name: invoice_payment_links_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.invoice_payment_links_link_id_seq', 16, true);


--
-- TOC entry 4055 (class 0 OID 0)
-- Dependencies: 253
-- Name: iot_readings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.iot_readings_id_seq', 22, true);


--
-- TOC entry 4056 (class 0 OID 0)
-- Dependencies: 221
-- Name: lubricant_purchases_purchase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.lubricant_purchases_purchase_id_seq', 17, true);


--
-- TOC entry 4057 (class 0 OID 0)
-- Dependencies: 219
-- Name: lubricant_sales_sale_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.lubricant_sales_sale_id_seq', 58, true);


--
-- TOC entry 4058 (class 0 OID 0)
-- Dependencies: 217
-- Name: lubricants_lubricant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.lubricants_lubricant_id_seq', 9, true);


--
-- TOC entry 4059 (class 0 OID 0)
-- Dependencies: 235
-- Name: pump_faults_fault_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.pump_faults_fault_id_seq', 1, true);


--
-- TOC entry 4060 (class 0 OID 0)
-- Dependencies: 233
-- Name: pump_maintenances_maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.pump_maintenances_maintenance_id_seq', 7, true);


--
-- TOC entry 4061 (class 0 OID 0)
-- Dependencies: 231
-- Name: pumps_pump_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.pumps_pump_id_seq', 9, true);


--
-- TOC entry 4062 (class 0 OID 0)
-- Dependencies: 209
-- Name: roles_roleid_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.roles_roleid_seq', 7, true);


--
-- TOC entry 4063 (class 0 OID 0)
-- Dependencies: 213
-- Name: staff_shifts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.staff_shifts_id_seq', 217, true);


--
-- TOC entry 4064 (class 0 OID 0)
-- Dependencies: 225
-- Name: supplier_invoices_invoice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.supplier_invoices_invoice_id_seq', 26, true);


--
-- TOC entry 4065 (class 0 OID 0)
-- Dependencies: 227
-- Name: supplier_payments_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.supplier_payments_payment_id_seq', 18, true);


--
-- TOC entry 4066 (class 0 OID 0)
-- Dependencies: 223
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.suppliers_supplier_id_seq', 7, true);


--
-- TOC entry 4067 (class 0 OID 0)
-- Dependencies: 211
-- Name: users_userid_seq; Type: SEQUENCE SET; Schema: public; Owner: senithdamiru
--

SELECT pg_catalog.setval('public.users_userid_seq', 9, true);


--
-- TOC entry 3789 (class 2606 OID 16795)
-- Name: credit_accounts credit_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.credit_accounts
    ADD CONSTRAINT credit_accounts_pkey PRIMARY KEY (account_id);


--
-- TOC entry 3793 (class 2606 OID 16849)
-- Name: credit_payments credit_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.credit_payments
    ADD CONSTRAINT credit_payments_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 3791 (class 2606 OID 16818)
-- Name: credit_sales credit_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.credit_sales
    ADD CONSTRAINT credit_sales_pkey PRIMARY KEY (credit_sale_id);


--
-- TOC entry 3787 (class 2606 OID 16766)
-- Name: daily_sales daily_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.daily_sales
    ADD CONSTRAINT daily_sales_pkey PRIMARY KEY (sale_id);


--
-- TOC entry 3748 (class 2606 OID 16548)
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (expense_id);


--
-- TOC entry 3804 (class 2606 OID 16920)
-- Name: fire_events fire_events_firebase_event_key_key; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fire_events
    ADD CONSTRAINT fire_events_firebase_event_key_key UNIQUE (firebase_event_key);


--
-- TOC entry 3806 (class 2606 OID 16918)
-- Name: fire_events fire_events_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fire_events
    ADD CONSTRAINT fire_events_pkey PRIMARY KEY (id);


--
-- TOC entry 3795 (class 2606 OID 16868)
-- Name: fuel_deliveries fuel_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fuel_deliveries
    ADD CONSTRAINT fuel_deliveries_pkey PRIMARY KEY (delivery_id);


--
-- TOC entry 3783 (class 2606 OID 16736)
-- Name: fuel_prices fuel_prices_fuel_type_key; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fuel_prices
    ADD CONSTRAINT fuel_prices_fuel_type_key UNIQUE (fuel_type);


--
-- TOC entry 3785 (class 2606 OID 16734)
-- Name: fuel_prices fuel_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fuel_prices
    ADD CONSTRAINT fuel_prices_pkey PRIMARY KEY (price_id);


--
-- TOC entry 3797 (class 2606 OID 16895)
-- Name: fuel_tanks fuel_tanks_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fuel_tanks
    ADD CONSTRAINT fuel_tanks_pkey PRIMARY KEY (id);


--
-- TOC entry 3799 (class 2606 OID 16897)
-- Name: fuel_tanks fuel_tanks_tank_id_key; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fuel_tanks
    ADD CONSTRAINT fuel_tanks_tank_id_key UNIQUE (tank_id);


--
-- TOC entry 3768 (class 2606 OID 16644)
-- Name: invoice_payment_links invoice_payment_links_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.invoice_payment_links
    ADD CONSTRAINT invoice_payment_links_pkey PRIMARY KEY (link_id);


--
-- TOC entry 3802 (class 2606 OID 16908)
-- Name: iot_readings iot_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.iot_readings
    ADD CONSTRAINT iot_readings_pkey PRIMARY KEY (id);


--
-- TOC entry 3754 (class 2606 OID 16586)
-- Name: lubricant_purchases lubricant_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.lubricant_purchases
    ADD CONSTRAINT lubricant_purchases_pkey PRIMARY KEY (purchase_id);


--
-- TOC entry 3752 (class 2606 OID 16571)
-- Name: lubricant_sales lubricant_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.lubricant_sales
    ADD CONSTRAINT lubricant_sales_pkey PRIMARY KEY (sale_id);


--
-- TOC entry 3750 (class 2606 OID 16561)
-- Name: lubricants lubricants_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.lubricants
    ADD CONSTRAINT lubricants_pkey PRIMARY KEY (lubricant_id);


--
-- TOC entry 3781 (class 2606 OID 16711)
-- Name: pump_faults pump_faults_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pump_faults
    ADD CONSTRAINT pump_faults_pkey PRIMARY KEY (fault_id);


--
-- TOC entry 3777 (class 2606 OID 16694)
-- Name: pump_maintenances pump_maintenances_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pump_maintenances
    ADD CONSTRAINT pump_maintenances_pkey PRIMARY KEY (maintenance_id);


--
-- TOC entry 3772 (class 2606 OID 16676)
-- Name: pumps pumps_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pumps
    ADD CONSTRAINT pumps_pkey PRIMARY KEY (pump_id);


--
-- TOC entry 3774 (class 2606 OID 16678)
-- Name: pumps pumps_pump_number_key; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pumps
    ADD CONSTRAINT pumps_pump_number_key UNIQUE (pump_number);


--
-- TOC entry 3736 (class 2606 OID 16487)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (roleid);


--
-- TOC entry 3738 (class 2606 OID 16489)
-- Name: roles roles_rolename_key; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_rolename_key UNIQUE (rolename);


--
-- TOC entry 3746 (class 2606 OID 16525)
-- Name: staff_shifts staff_shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.staff_shifts
    ADD CONSTRAINT staff_shifts_pkey PRIMARY KEY (id);


--
-- TOC entry 3809 (class 2606 OID 16931)
-- Name: station_settings station_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.station_settings
    ADD CONSTRAINT station_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 3761 (class 2606 OID 16617)
-- Name: supplier_invoices supplier_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.supplier_invoices
    ADD CONSTRAINT supplier_invoices_pkey PRIMARY KEY (invoice_id);


--
-- TOC entry 3764 (class 2606 OID 16632)
-- Name: supplier_payments supplier_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.supplier_payments
    ADD CONSTRAINT supplier_payments_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 3756 (class 2606 OID 16606)
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (supplier_id);


--
-- TOC entry 3740 (class 2606 OID 16509)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3742 (class 2606 OID 16516)
-- Name: users users_empno_key; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_empno_key UNIQUE (empno);


--
-- TOC entry 3744 (class 2606 OID 16507)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (userid);


--
-- TOC entry 3807 (class 1259 OID 16921)
-- Name: idx_fire_events_device; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_fire_events_device ON public.fire_events USING btree (device_id, recorded_at DESC);


--
-- TOC entry 3757 (class 1259 OID 16657)
-- Name: idx_invoices_due_date; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_invoices_due_date ON public.supplier_invoices USING btree (due_date);


--
-- TOC entry 3758 (class 1259 OID 16656)
-- Name: idx_invoices_status; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_invoices_status ON public.supplier_invoices USING btree (status);


--
-- TOC entry 3759 (class 1259 OID 16655)
-- Name: idx_invoices_supplier; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_invoices_supplier ON public.supplier_invoices USING btree (supplier_id);


--
-- TOC entry 3800 (class 1259 OID 16909)
-- Name: idx_iot_readings_device_time; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_iot_readings_device_time ON public.iot_readings USING btree (device_id, recorded_at DESC);


--
-- TOC entry 3765 (class 1259 OID 16659)
-- Name: idx_links_invoice; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_links_invoice ON public.invoice_payment_links USING btree (invoice_id);


--
-- TOC entry 3766 (class 1259 OID 16660)
-- Name: idx_links_payment; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_links_payment ON public.invoice_payment_links USING btree (payment_id);


--
-- TOC entry 3762 (class 1259 OID 16658)
-- Name: idx_payments_supplier; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_payments_supplier ON public.supplier_payments USING btree (supplier_id);


--
-- TOC entry 3778 (class 1259 OID 16718)
-- Name: idx_pump_faults_pump; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_pump_faults_pump ON public.pump_faults USING btree (pump_id);


--
-- TOC entry 3779 (class 1259 OID 16719)
-- Name: idx_pump_faults_status; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_pump_faults_status ON public.pump_faults USING btree (status);


--
-- TOC entry 3775 (class 1259 OID 16717)
-- Name: idx_pump_maintenances_pump; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_pump_maintenances_pump ON public.pump_maintenances USING btree (pump_id);


--
-- TOC entry 3769 (class 1259 OID 16720)
-- Name: idx_pumps_fuel_type; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_pumps_fuel_type ON public.pumps USING btree (fuel_type);


--
-- TOC entry 3770 (class 1259 OID 16721)
-- Name: idx_pumps_status; Type: INDEX; Schema: public; Owner: senithdamiru
--

CREATE INDEX idx_pumps_status ON public.pumps USING btree (status);


--
-- TOC entry 3832 (class 2620 OID 16593)
-- Name: lubricants trg_lubricants_updated_at; Type: TRIGGER; Schema: public; Owner: senithdamiru
--

CREATE TRIGGER trg_lubricants_updated_at BEFORE UPDATE ON public.lubricants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3834 (class 2620 OID 16723)
-- Name: pumps trg_pumps_updated_at; Type: TRIGGER; Schema: public; Owner: senithdamiru
--

CREATE TRIGGER trg_pumps_updated_at BEFORE UPDATE ON public.pumps FOR EACH ROW EXECUTE FUNCTION public.update_pumps_updated_at();


--
-- TOC entry 3833 (class 2620 OID 16662)
-- Name: suppliers trg_suppliers_updated_at; Type: TRIGGER; Schema: public; Owner: senithdamiru
--

CREATE TRIGGER trg_suppliers_updated_at BEFORE UPDATE ON public.suppliers FOR EACH ROW EXECUTE FUNCTION public.update_suppliers_updated_at();


--
-- TOC entry 3829 (class 2606 OID 16850)
-- Name: credit_payments credit_payments_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.credit_payments
    ADD CONSTRAINT credit_payments_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.credit_accounts(account_id) ON DELETE RESTRICT;


--
-- TOC entry 3830 (class 2606 OID 16855)
-- Name: credit_payments credit_payments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.credit_payments
    ADD CONSTRAINT credit_payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(userid) ON DELETE SET NULL;


--
-- TOC entry 3825 (class 2606 OID 16819)
-- Name: credit_sales credit_sales_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.credit_sales
    ADD CONSTRAINT credit_sales_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.credit_accounts(account_id) ON DELETE RESTRICT;


--
-- TOC entry 3826 (class 2606 OID 16824)
-- Name: credit_sales credit_sales_pump_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.credit_sales
    ADD CONSTRAINT credit_sales_pump_id_fkey FOREIGN KEY (pump_id) REFERENCES public.pumps(pump_id) ON DELETE RESTRICT;


--
-- TOC entry 3827 (class 2606 OID 16829)
-- Name: credit_sales credit_sales_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.credit_sales
    ADD CONSTRAINT credit_sales_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.staff_shifts(id) ON DELETE SET NULL;


--
-- TOC entry 3828 (class 2606 OID 16834)
-- Name: credit_sales credit_sales_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.credit_sales
    ADD CONSTRAINT credit_sales_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(userid) ON DELETE SET NULL;


--
-- TOC entry 3822 (class 2606 OID 16767)
-- Name: daily_sales daily_sales_pump_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.daily_sales
    ADD CONSTRAINT daily_sales_pump_id_fkey FOREIGN KEY (pump_id) REFERENCES public.pumps(pump_id) ON DELETE RESTRICT;


--
-- TOC entry 3823 (class 2606 OID 16772)
-- Name: daily_sales daily_sales_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.daily_sales
    ADD CONSTRAINT daily_sales_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.staff_shifts(id) ON DELETE SET NULL;


--
-- TOC entry 3824 (class 2606 OID 16777)
-- Name: daily_sales daily_sales_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.daily_sales
    ADD CONSTRAINT daily_sales_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(userid) ON DELETE SET NULL;


--
-- TOC entry 3831 (class 2606 OID 16869)
-- Name: fuel_deliveries fuel_deliveries_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.fuel_deliveries
    ADD CONSTRAINT fuel_deliveries_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(supplier_id) ON DELETE SET NULL;


--
-- TOC entry 3817 (class 2606 OID 16645)
-- Name: invoice_payment_links invoice_payment_links_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.invoice_payment_links
    ADD CONSTRAINT invoice_payment_links_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.supplier_invoices(invoice_id) ON DELETE CASCADE;


--
-- TOC entry 3818 (class 2606 OID 16650)
-- Name: invoice_payment_links invoice_payment_links_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.invoice_payment_links
    ADD CONSTRAINT invoice_payment_links_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.supplier_payments(payment_id) ON DELETE CASCADE;


--
-- TOC entry 3814 (class 2606 OID 16587)
-- Name: lubricant_purchases lubricant_purchases_lubricant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.lubricant_purchases
    ADD CONSTRAINT lubricant_purchases_lubricant_id_fkey FOREIGN KEY (lubricant_id) REFERENCES public.lubricants(lubricant_id);


--
-- TOC entry 3813 (class 2606 OID 16572)
-- Name: lubricant_sales lubricant_sales_lubricant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.lubricant_sales
    ADD CONSTRAINT lubricant_sales_lubricant_id_fkey FOREIGN KEY (lubricant_id) REFERENCES public.lubricants(lubricant_id);


--
-- TOC entry 3821 (class 2606 OID 16712)
-- Name: pump_faults pump_faults_pump_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pump_faults
    ADD CONSTRAINT pump_faults_pump_id_fkey FOREIGN KEY (pump_id) REFERENCES public.pumps(pump_id) ON DELETE CASCADE;


--
-- TOC entry 3820 (class 2606 OID 16695)
-- Name: pump_maintenances pump_maintenances_pump_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pump_maintenances
    ADD CONSTRAINT pump_maintenances_pump_id_fkey FOREIGN KEY (pump_id) REFERENCES public.pumps(pump_id) ON DELETE CASCADE;


--
-- TOC entry 3819 (class 2606 OID 16679)
-- Name: pumps pumps_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.pumps
    ADD CONSTRAINT pumps_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.users(userid) ON DELETE SET NULL;


--
-- TOC entry 3811 (class 2606 OID 16531)
-- Name: staff_shifts staff_shifts_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.staff_shifts
    ADD CONSTRAINT staff_shifts_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(roleid) ON DELETE SET NULL;


--
-- TOC entry 3812 (class 2606 OID 16526)
-- Name: staff_shifts staff_shifts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.staff_shifts
    ADD CONSTRAINT staff_shifts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(userid) ON DELETE CASCADE;


--
-- TOC entry 3815 (class 2606 OID 16618)
-- Name: supplier_invoices supplier_invoices_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.supplier_invoices
    ADD CONSTRAINT supplier_invoices_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(supplier_id) ON DELETE CASCADE;


--
-- TOC entry 3816 (class 2606 OID 16633)
-- Name: supplier_payments supplier_payments_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.supplier_payments
    ADD CONSTRAINT supplier_payments_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(supplier_id) ON DELETE CASCADE;


--
-- TOC entry 3810 (class 2606 OID 16510)
-- Name: users users_roleid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: senithdamiru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_roleid_fkey FOREIGN KEY (roleid) REFERENCES public.roles(roleid) ON DELETE CASCADE;


-- Completed on 2026-04-19 21:25:02 +0530

--
-- PostgreSQL database dump complete
--

