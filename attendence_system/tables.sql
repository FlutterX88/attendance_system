-- Table: public.attendance

-- DROP TABLE IF EXISTS public.attendance;

CREATE TABLE IF NOT EXISTS public.attendance
(
    id integer NOT NULL DEFAULT nextval('attendance_id_seq'::regclass),
    employee_name text COLLATE pg_catalog."default" NOT NULL,
    date date NOT NULL,
    in_time text COLLATE pg_catalog."default",
    out_time text COLLATE pg_catalog."default",
    status text COLLATE pg_catalog."default" NOT NULL,
    employee_id integer,
    CONSTRAINT attendance_pkey PRIMARY KEY (id),
    CONSTRAINT attendance_employee_id_fkey FOREIGN KEY (employee_id)
        REFERENCES public.employees (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;


-- Table: public.employee_leave_summary

-- DROP TABLE IF EXISTS public.employee_leave_summary;

CREATE TABLE IF NOT EXISTS public.employee_leave_summary
(
    id integer NOT NULL DEFAULT nextval('employee_leave_summary_id_seq'::regclass),
    employee_id integer NOT NULL,
    leave_type character varying(50) COLLATE pg_catalog."default" NOT NULL,
    total_entitlement numeric(5,2) DEFAULT 0,
    leave_taken numeric(5,2) DEFAULT 0,
    carry_forward numeric(5,2) DEFAULT 0,
    year integer NOT NULL DEFAULT EXTRACT(year FROM CURRENT_DATE),
    CONSTRAINT employee_leave_summary_pkey PRIMARY KEY (id),
    CONSTRAINT employee_leave_summary_employee_id_fkey FOREIGN KEY (employee_id)
        REFERENCES public.employees (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

-- Table: public.employee_less_hours

-- DROP TABLE IF EXISTS public.employee_less_hours;

CREATE TABLE IF NOT EXISTS public.employee_less_hours
(
    id integer NOT NULL DEFAULT nextval('employee_less_hours_id_seq'::regclass),
    employee_id integer,
    date date NOT NULL,
    required_hours numeric(5,2) NOT NULL,
    worked_hours numeric(5,2) NOT NULL,
    less_hours numeric(5,2) NOT NULL,
    CONSTRAINT employee_less_hours_pkey PRIMARY KEY (id),
    CONSTRAINT employee_less_hours_employee_id_fkey FOREIGN KEY (employee_id)
        REFERENCES public.employees (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;



-- Table: public.employee_overtime

-- DROP TABLE IF EXISTS public.employee_overtime;

CREATE TABLE IF NOT EXISTS public.employee_overtime
(
    id integer NOT NULL DEFAULT nextval('employee_overtime_id_seq'::regclass),
    employee_id integer,
    date date NOT NULL,
    extra_hours numeric(5,2) NOT NULL,
    CONSTRAINT employee_overtime_pkey PRIMARY KEY (id),
    CONSTRAINT employee_overtime_employee_id_fkey FOREIGN KEY (employee_id)
        REFERENCES public.employees (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;


-- Table: public.employee_requests

-- DROP TABLE IF EXISTS public.employee_requests;

CREATE TABLE IF NOT EXISTS public.employee_requests
(
    id integer NOT NULL DEFAULT nextval('employee_requests_id_seq'::regclass),
    employee_id integer,
    request_type text COLLATE pg_catalog."default",
    reason text COLLATE pg_catalog."default",
    date date,
    status character varying(20) COLLATE pg_catalog."default" DEFAULT 'Pending'::character varying,
    from_date date,
    to_date date,
    requested_date date DEFAULT CURRENT_DATE,
    leave_type character varying(50) COLLATE pg_catalog."default",
    how_many_days numeric(5,2),
    CONSTRAINT employee_requests_pkey PRIMARY KEY (id),
    CONSTRAINT employee_requests_employee_id_fkey FOREIGN KEY (employee_id)
        REFERENCES public.employees (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;


-- Table: public.employee_salary_reports

-- DROP TABLE IF EXISTS public.employee_salary_reports;

CREATE TABLE IF NOT EXISTS public.employee_salary_reports
(
    id integer NOT NULL DEFAULT nextval('employee_salary_reports_id_seq'::regclass),
    employee_id integer,
    year integer NOT NULL,
    month integer NOT NULL,
    basic_salary numeric(12,2) NOT NULL,
    gross_salary numeric(12,2) NOT NULL,
    net_salary numeric(12,2) NOT NULL,
    total_allowances numeric(12,2) DEFAULT 0,
    total_deductions numeric(12,2) DEFAULT 0,
    absent_deduction numeric(12,2) DEFAULT 0,
    leave_deduction numeric(12,2) DEFAULT 0,
    late_deduction numeric(12,2) DEFAULT 0,
    overtime_addition numeric(12,2) DEFAULT 0,
    total_advance numeric(12,2) DEFAULT 0,
    paid boolean DEFAULT false,
    paid_date timestamp without time zone,
    CONSTRAINT employee_salary_reports_pkey PRIMARY KEY (id),
    CONSTRAINT employee_salary_reports_employee_id_fkey FOREIGN KEY (employee_id)
        REFERENCES public.employees (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;


-- Table: public.employee_shifts

-- DROP TABLE IF EXISTS public.employee_shifts;

CREATE TABLE IF NOT EXISTS public.employee_shifts
(
    id integer NOT NULL DEFAULT nextval('employee_shifts_id_seq'::regclass),
    employee_id integer,
    shift_name character varying(50) COLLATE pg_catalog."default",
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    shift_type character varying(20) COLLATE pg_catalog."default" DEFAULT 'Day'::character varying,
    CONSTRAINT employee_shifts_pkey PRIMARY KEY (id),
    CONSTRAINT employee_shifts_employee_id_fkey FOREIGN KEY (employee_id)
        REFERENCES public.employees (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

-- Table: public.employee_work_summary

-- DROP TABLE IF EXISTS public.employee_work_summary;

CREATE TABLE IF NOT EXISTS public.employee_work_summary
(
    id integer NOT NULL DEFAULT nextval('employee_work_summary_id_seq'::regclass),
    employee_id integer NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL,
    required_hours numeric(7,2) DEFAULT 0,
    worked_hours numeric(7,2) DEFAULT 0,
    CONSTRAINT employee_work_summary_pkey PRIMARY KEY (id),
    CONSTRAINT employee_work_summary_employee_id_fkey FOREIGN KEY (employee_id)
        REFERENCES public.employees (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;


-- Table: public.employees

-- DROP TABLE IF EXISTS public.employees;

CREATE TABLE IF NOT EXISTS public.employees
(
    id integer NOT NULL DEFAULT nextval('employees_id_seq'::regclass),
    full_name text COLLATE pg_catalog."default",
    email text COLLATE pg_catalog."default",
    phone text COLLATE pg_catalog."default",
    password text COLLATE pg_catalog."default",
    dob date,
    gender text COLLATE pg_catalog."default",
    blood_group text COLLATE pg_catalog."default",
    join_date date,
    department text COLLATE pg_catalog."default",
    designation text COLLATE pg_catalog."default",
    experience text COLLATE pg_catalog."default",
    basic_salary numeric(12,2),
    work_type text COLLATE pg_catalog."default",
    address text COLLATE pg_catalog."default",
    city text COLLATE pg_catalog."default",
    state text COLLATE pg_catalog."default",
    zip text COLLATE pg_catalog."default",
    emergency_contact_name text COLLATE pg_catalog."default",
    emergency_contact_number text COLLATE pg_catalog."default",
    annual_leave_entitlement numeric(5,2) DEFAULT 0,
    required_work_hours_daily numeric(5,2) DEFAULT 0,
    required_work_hours_monthly numeric(7,2) DEFAULT 0,
    CONSTRAINT employees_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;


-- Table: public.salary_advances

-- DROP TABLE IF EXISTS public.salary_advances;

CREATE TABLE IF NOT EXISTS public.salary_advances
(
    id integer NOT NULL DEFAULT nextval('salary_advances_id_seq'::regclass),
    employee_name text COLLATE pg_catalog."default" NOT NULL,
    date date NOT NULL,
    amount numeric(12,2) NOT NULL,
    payment_mode text COLLATE pg_catalog."default" NOT NULL,
    remarks text COLLATE pg_catalog."default",
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) COLLATE pg_catalog."default" DEFAULT 'Pending'::character varying,
    employee_id integer,
    CONSTRAINT salary_advances_pkey PRIMARY KEY (id),
    CONSTRAINT salary_advances_employee_id_fkey FOREIGN KEY (employee_id)
        REFERENCES public.employees (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

-- Table: public.salary_components

-- DROP TABLE IF EXISTS public.salary_components;

CREATE TABLE IF NOT EXISTS public.salary_components
(
    id integer NOT NULL DEFAULT nextval('salary_components_id_seq'::regclass),
    name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    component_type character varying(50) COLLATE pg_catalog."default" NOT NULL,
    employee_percentage numeric(5,2) DEFAULT 0.00,
    employer_percentage numeric(5,2) DEFAULT 0.00,
    remarks text COLLATE pg_catalog."default",
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT salary_components_pkey PRIMARY KEY (id),
    CONSTRAINT salary_components_component_type_check CHECK (component_type::text = ANY (ARRAY['Deduction'::character varying, 'Allowance'::character varying]::text[]))
)

TABLESPACE pg_default;



-- Table: public.users

-- DROP TABLE IF EXISTS public.users;

CREATE TABLE IF NOT EXISTS public.users
(
    id integer NOT NULL DEFAULT nextval('users_id_seq'::regclass),
    full_name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    email character varying(150) COLLATE pg_catalog."default" NOT NULL,
    password_hash text COLLATE pg_catalog."default" NOT NULL,
    role character varying(20) COLLATE pg_catalog."default" NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT users_pkey PRIMARY KEY (id),
    CONSTRAINT users_email_key UNIQUE (email),
    CONSTRAINT users_role_check CHECK (role::text = ANY (ARRAY['employee'::character varying, 'owner'::character varying, 'hr'::character varying, 'accounts'::character varying]::text[]))
)

TABLESPACE pg_default;


