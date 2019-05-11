--
-- PostgreSQL database dump
--

-- Dumped from database version 11.2
-- Dumped by pg_dump version 11.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    persistence_token character varying(255),
    crypted_password character varying(255),
    password_salt character varying(255),
    login_count integer DEFAULT 0,
    failed_login_count integer DEFAULT 0,
    current_login_at timestamp without time zone,
    last_login_at timestamp without time zone,
    current_login_ip character varying(255),
    last_login_ip character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    role character varying(10) NOT NULL,
    force_password_reset boolean DEFAULT true,
    password_changed_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    last_request_at timestamp without time zone
);


--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- Name: archived_debate_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_debate_outcomes (
    id integer NOT NULL,
    petition_id integer NOT NULL,
    debated_on date,
    transcript_url character varying(500),
    video_url character varying(500),
    overview text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    debated boolean DEFAULT true NOT NULL,
    commons_image_file_name character varying,
    commons_image_content_type character varying,
    commons_image_file_size integer,
    commons_image_updated_at timestamp without time zone,
    debate_pack_url character varying(500)
);


--
-- Name: archived_debate_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_debate_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_debate_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_debate_outcomes_id_seq OWNED BY public.archived_debate_outcomes.id;


--
-- Name: archived_government_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_government_responses (
    id integer NOT NULL,
    petition_id integer,
    summary character varying(500) NOT NULL,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    responded_on date
);


--
-- Name: archived_government_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_government_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_government_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_government_responses_id_seq OWNED BY public.archived_government_responses.id;


--
-- Name: archived_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_notes (
    id integer NOT NULL,
    petition_id integer,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: archived_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_notes_id_seq OWNED BY public.archived_notes.id;


--
-- Name: archived_petition_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_petition_emails (
    id integer NOT NULL,
    petition_id integer,
    subject character varying NOT NULL,
    body text,
    sent_by character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: archived_petition_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_petition_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_petition_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_petition_emails_id_seq OWNED BY public.archived_petition_emails.id;


--
-- Name: archived_petitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_petitions (
    id integer NOT NULL,
    state character varying(10) DEFAULT 'closed'::character varying NOT NULL,
    opened_at timestamp without time zone,
    closed_at timestamp without time zone,
    signature_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    parliament_id integer,
    action character varying(255),
    background character varying(300),
    additional_details text,
    government_response_at timestamp without time zone,
    scheduled_debate_date date,
    last_signed_at timestamp without time zone,
    response_threshold_reached_at timestamp without time zone,
    debate_threshold_reached_at timestamp without time zone,
    rejected_at timestamp without time zone,
    debate_outcome_at timestamp without time zone,
    moderation_threshold_reached_at timestamp without time zone,
    debate_state character varying(30),
    stopped_at timestamp without time zone,
    special_consideration boolean,
    signatures_by_constituency jsonb,
    signatures_by_country jsonb,
    email_requested_for_government_response_at timestamp without time zone,
    email_requested_for_debate_scheduled_at timestamp without time zone,
    email_requested_for_debate_outcome_at timestamp without time zone,
    email_requested_for_petition_email_at timestamp without time zone,
    tags integer[] DEFAULT '{}'::integer[] NOT NULL,
    locked_at timestamp without time zone,
    locked_by_id integer,
    moderation_lag integer
);


--
-- Name: archived_petitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_petitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 199999
    CACHE 1;


--
-- Name: archived_petitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_petitions_id_seq OWNED BY public.archived_petitions.id;


--
-- Name: archived_rejections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_rejections (
    id integer NOT NULL,
    petition_id integer,
    code character varying(50) NOT NULL,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: archived_rejections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_rejections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_rejections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_rejections_id_seq OWNED BY public.archived_rejections.id;


--
-- Name: archived_signatures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_signatures (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    state character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    perishable_token character varying(255),
    postcode character varying(255),
    ip_address character varying(20),
    petition_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notify_by_email boolean DEFAULT false,
    email character varying(255),
    unsubscribe_token character varying,
    constituency_id character varying,
    validated_at timestamp without time zone,
    number integer,
    location_code character varying(30),
    invalidated_at timestamp without time zone,
    invalidation_id integer,
    government_response_email_at timestamp without time zone,
    debate_scheduled_email_at timestamp without time zone,
    debate_outcome_email_at timestamp without time zone,
    petition_email_at timestamp without time zone,
    uuid uuid,
    creator boolean DEFAULT false NOT NULL,
    sponsor boolean DEFAULT false NOT NULL
);


--
-- Name: archived_signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_signatures_id_seq OWNED BY public.archived_signatures.id;


--
-- Name: constituencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.constituencies (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL,
    external_id character varying(30) NOT NULL,
    ons_code character varying(10) NOT NULL,
    mp_id character varying(30),
    mp_name character varying(100),
    mp_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    example_postcode character varying(30),
    party character varying(100)
);


--
-- Name: constituencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.constituencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: constituencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.constituencies_id_seq OWNED BY public.constituencies.id;


--
-- Name: constituency_petition_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.constituency_petition_journals (
    id integer NOT NULL,
    constituency_id character varying NOT NULL,
    petition_id integer NOT NULL,
    signature_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_signed_at timestamp without time zone
);


--
-- Name: constituency_petition_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.constituency_petition_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: constituency_petition_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.constituency_petition_journals_id_seq OWNED BY public.constituency_petition_journals.id;


--
-- Name: country_petition_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.country_petition_journals (
    id integer NOT NULL,
    petition_id integer NOT NULL,
    signature_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    location_code character varying(30),
    last_signed_at timestamp without time zone
);


--
-- Name: country_petition_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.country_petition_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: country_petition_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.country_petition_journals_id_seq OWNED BY public.country_petition_journals.id;


--
-- Name: debate_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.debate_outcomes (
    id integer NOT NULL,
    petition_id integer NOT NULL,
    debated_on date,
    transcript_url character varying(500),
    video_url character varying(500),
    overview text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    debated boolean DEFAULT true NOT NULL,
    commons_image_file_name character varying,
    commons_image_content_type character varying,
    commons_image_file_size integer,
    commons_image_updated_at timestamp without time zone,
    debate_pack_url character varying(500)
);


--
-- Name: debate_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.debate_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: debate_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.debate_outcomes_id_seq OWNED BY public.debate_outcomes.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    queue character varying(255)
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domains (
    id integer NOT NULL,
    canonical_domain_id integer,
    name character varying(100) NOT NULL,
    strip_characters character varying(10),
    strip_extension character varying(10) DEFAULT '+'::character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.domains_id_seq OWNED BY public.domains.id;


--
-- Name: email_requested_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_requested_receipts (
    id integer NOT NULL,
    petition_id integer,
    government_response timestamp without time zone,
    debate_outcome timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    debate_scheduled timestamp without time zone,
    petition_email timestamp without time zone
);


--
-- Name: email_requested_receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_requested_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_requested_receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_requested_receipts_id_seq OWNED BY public.email_requested_receipts.id;


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback (
    id integer NOT NULL,
    comment character varying(32768) NOT NULL,
    petition_link_or_title character varying,
    email character varying,
    user_agent character varying
);


--
-- Name: feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_id_seq OWNED BY public.feedback.id;


--
-- Name: government_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.government_responses (
    id integer NOT NULL,
    petition_id integer,
    summary character varying(500) NOT NULL,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    responded_on date
);


--
-- Name: government_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.government_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: government_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.government_responses_id_seq OWNED BY public.government_responses.id;


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holidays (
    id integer NOT NULL,
    christmas_start date,
    christmas_end date,
    easter_start date,
    easter_end date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.holidays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.holidays_id_seq OWNED BY public.holidays.id;


--
-- Name: invalidations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invalidations (
    id integer NOT NULL,
    summary character varying(255) NOT NULL,
    details character varying(10000),
    petition_id integer,
    name character varying(255),
    postcode character varying(255),
    ip_address character varying(20),
    email character varying(255),
    created_after timestamp without time zone,
    created_before timestamp without time zone,
    constituency_id character varying(30),
    location_code character varying(30),
    matching_count integer DEFAULT 0 NOT NULL,
    invalidated_count integer DEFAULT 0 NOT NULL,
    enqueued_at timestamp without time zone,
    started_at timestamp without time zone,
    cancelled_at timestamp without time zone,
    completed_at timestamp without time zone,
    counted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    domain character varying(255)
);


--
-- Name: invalidations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invalidations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invalidations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invalidations_id_seq OWNED BY public.invalidations.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id integer NOT NULL,
    code character varying(30) NOT NULL,
    name character varying(100) NOT NULL,
    start_date date,
    end_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id integer NOT NULL,
    petition_id integer,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: parliaments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parliaments (
    id integer NOT NULL,
    dissolution_at timestamp without time zone,
    dissolution_message text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    dissolution_heading character varying(100),
    dissolution_faq_url character varying(500),
    dissolved_heading character varying(100),
    dissolved_message text,
    notification_cutoff_at timestamp without time zone,
    registration_closed_at timestamp without time zone,
    government character varying(100),
    opening_at timestamp without time zone,
    archived_at timestamp without time zone,
    threshold_for_response integer DEFAULT 10000 NOT NULL,
    threshold_for_debate integer DEFAULT 100000 NOT NULL,
    petition_duration integer DEFAULT 6,
    archiving_started_at timestamp without time zone
);


--
-- Name: parliaments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parliaments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parliaments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parliaments_id_seq OWNED BY public.parliaments.id;


--
-- Name: petition_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.petition_emails (
    id integer NOT NULL,
    petition_id integer,
    subject character varying NOT NULL,
    body text,
    sent_by character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: petition_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.petition_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: petition_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.petition_emails_id_seq OWNED BY public.petition_emails.id;


--
-- Name: petition_statistics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.petition_statistics (
    id integer NOT NULL,
    petition_id integer,
    refreshed_at timestamp without time zone,
    duplicate_emails integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: petition_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.petition_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: petition_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.petition_statistics_id_seq OWNED BY public.petition_statistics.id;


--
-- Name: petitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.petitions (
    id integer NOT NULL,
    action character varying(255) NOT NULL,
    additional_details text,
    state character varying(10) DEFAULT 'pending'::character varying NOT NULL,
    open_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    closed_at timestamp without time zone,
    signature_count integer DEFAULT 0,
    notified_by_email boolean DEFAULT false,
    background character varying(300),
    sponsor_token character varying(255),
    government_response_at timestamp without time zone,
    scheduled_debate_date date,
    last_signed_at timestamp without time zone,
    response_threshold_reached_at timestamp without time zone,
    debate_threshold_reached_at timestamp without time zone,
    rejected_at timestamp without time zone,
    debate_outcome_at timestamp without time zone,
    moderation_threshold_reached_at timestamp without time zone,
    debate_state character varying(30) DEFAULT 'pending'::character varying,
    stopped_at timestamp without time zone,
    special_consideration boolean,
    archived_at timestamp without time zone,
    archiving_started_at timestamp without time zone,
    tags integer[] DEFAULT '{}'::integer[] NOT NULL,
    locked_at timestamp without time zone,
    locked_by_id integer,
    moderation_lag integer,
    signature_count_reset_at timestamp without time zone
);


--
-- Name: petitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.petitions_id_seq
    START WITH 200000
    INCREMENT BY 1
    MINVALUE 200000
    NO MAXVALUE
    CACHE 1;


--
-- Name: petitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.petitions_id_seq OWNED BY public.petitions.id;


--
-- Name: rate_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_limits (
    id integer NOT NULL,
    burst_rate integer DEFAULT 1 NOT NULL,
    burst_period integer DEFAULT 60 NOT NULL,
    sustained_rate integer DEFAULT 5 NOT NULL,
    sustained_period integer DEFAULT 300 NOT NULL,
    allowed_domains character varying(10000) DEFAULT ''::character varying NOT NULL,
    allowed_ips character varying(10000) DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    blocked_domains character varying(50000) DEFAULT ''::character varying NOT NULL,
    blocked_ips character varying(50000) DEFAULT ''::character varying NOT NULL,
    geoblocking_enabled boolean DEFAULT false NOT NULL,
    countries character varying(2000) DEFAULT ''::character varying NOT NULL,
    country_burst_rate integer DEFAULT 1 NOT NULL,
    country_sustained_rate integer DEFAULT 60 NOT NULL,
    country_rate_limits_enabled boolean DEFAULT false NOT NULL,
    ignored_domains character varying(10000) DEFAULT ''::character varying NOT NULL,
    threshold_for_form_entry integer DEFAULT 0 NOT NULL,
    enable_logging_of_trending_items boolean DEFAULT false NOT NULL,
    threshold_for_logging_trending_items integer DEFAULT 100 NOT NULL,
    threshold_for_notifying_trending_items integer DEFAULT 200 NOT NULL,
    trending_items_notification_url character varying
);


--
-- Name: rate_limits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_limits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_limits_id_seq OWNED BY public.rate_limits.id;


--
-- Name: rejections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rejections (
    id integer NOT NULL,
    petition_id integer,
    code character varying(50) NOT NULL,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: rejections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rejections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rejections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rejections_id_seq OWNED BY public.rejections.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: signatures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.signatures (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    state character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    perishable_token character varying(255),
    postcode character varying(255),
    ip_address character varying(20),
    petition_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notify_by_email boolean DEFAULT false,
    email character varying(255),
    unsubscribe_token character varying,
    constituency_id character varying,
    validated_at timestamp without time zone,
    number integer,
    seen_signed_confirmation_page boolean DEFAULT false NOT NULL,
    location_code character varying(30),
    invalidated_at timestamp without time zone,
    invalidation_id integer,
    government_response_email_at timestamp without time zone,
    debate_scheduled_email_at timestamp without time zone,
    debate_outcome_email_at timestamp without time zone,
    petition_email_at timestamp without time zone,
    uuid uuid,
    archived_at timestamp without time zone,
    email_count integer DEFAULT 0 NOT NULL,
    sponsor boolean DEFAULT false NOT NULL,
    creator boolean DEFAULT false NOT NULL,
    signed_token character varying,
    validated_ip character varying,
    form_requested_at timestamp without time zone,
    image_loaded_at timestamp without time zone,
    form_token character varying,
    canonical_email character varying
);


--
-- Name: signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.signatures_id_seq OWNED BY public.signatures.id;


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sites (
    id integer NOT NULL,
    title character varying(50) DEFAULT 'Petition parliament'::character varying NOT NULL,
    url character varying(50) DEFAULT 'https://petition.parliament.uk'::character varying NOT NULL,
    email_from character varying(100) DEFAULT '"Petitions: UK Government and Parliament" <no-reply@petition.parliament.uk>'::character varying NOT NULL,
    username character varying(30),
    password_digest character varying(60),
    enabled boolean DEFAULT true NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    petition_duration integer DEFAULT 6 NOT NULL,
    minimum_number_of_sponsors integer DEFAULT 5 NOT NULL,
    maximum_number_of_sponsors integer DEFAULT 20 NOT NULL,
    threshold_for_moderation integer DEFAULT 5 NOT NULL,
    threshold_for_response integer DEFAULT 10000 NOT NULL,
    threshold_for_debate integer DEFAULT 100000 NOT NULL,
    last_checked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feedback_email character varying(100) DEFAULT '"Petitions: UK Government and Parliament" <petitionscommittee@parliament.uk>'::character varying NOT NULL,
    moderate_url character varying(50) DEFAULT 'https://moderate.petition.parliament.uk'::character varying NOT NULL,
    last_petition_created_at timestamp without time zone,
    login_timeout integer DEFAULT 1800 NOT NULL,
    feature_flags jsonb DEFAULT '{}'::jsonb NOT NULL,
    signature_count_updated_at timestamp without time zone,
    signature_count_interval integer DEFAULT 60 NOT NULL,
    update_signature_counts boolean DEFAULT false NOT NULL,
    threshold_for_moderation_delay integer DEFAULT 500 NOT NULL
);


--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sites_id_seq OWNED BY public.sites.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(200),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: trending_domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trending_domains (
    id integer NOT NULL,
    petition_id integer,
    domain character varying(100) NOT NULL,
    count integer NOT NULL,
    starts_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: trending_domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trending_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trending_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trending_domains_id_seq OWNED BY public.trending_domains.id;


--
-- Name: trending_ips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trending_ips (
    id integer NOT NULL,
    petition_id integer,
    ip_address inet NOT NULL,
    country_code character varying(30) NOT NULL,
    count integer NOT NULL,
    starts_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: trending_ips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trending_ips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trending_ips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trending_ips_id_seq OWNED BY public.trending_ips.id;


--
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- Name: archived_debate_outcomes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_debate_outcomes ALTER COLUMN id SET DEFAULT nextval('public.archived_debate_outcomes_id_seq'::regclass);


--
-- Name: archived_government_responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_government_responses ALTER COLUMN id SET DEFAULT nextval('public.archived_government_responses_id_seq'::regclass);


--
-- Name: archived_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_notes ALTER COLUMN id SET DEFAULT nextval('public.archived_notes_id_seq'::regclass);


--
-- Name: archived_petition_emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_petition_emails ALTER COLUMN id SET DEFAULT nextval('public.archived_petition_emails_id_seq'::regclass);


--
-- Name: archived_petitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_petitions ALTER COLUMN id SET DEFAULT nextval('public.archived_petitions_id_seq'::regclass);


--
-- Name: archived_rejections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_rejections ALTER COLUMN id SET DEFAULT nextval('public.archived_rejections_id_seq'::regclass);


--
-- Name: archived_signatures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_signatures ALTER COLUMN id SET DEFAULT nextval('public.archived_signatures_id_seq'::regclass);


--
-- Name: constituencies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constituencies ALTER COLUMN id SET DEFAULT nextval('public.constituencies_id_seq'::regclass);


--
-- Name: constituency_petition_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constituency_petition_journals ALTER COLUMN id SET DEFAULT nextval('public.constituency_petition_journals_id_seq'::regclass);


--
-- Name: country_petition_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.country_petition_journals ALTER COLUMN id SET DEFAULT nextval('public.country_petition_journals_id_seq'::regclass);


--
-- Name: debate_outcomes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debate_outcomes ALTER COLUMN id SET DEFAULT nextval('public.debate_outcomes_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: domains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domains ALTER COLUMN id SET DEFAULT nextval('public.domains_id_seq'::regclass);


--
-- Name: email_requested_receipts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_requested_receipts ALTER COLUMN id SET DEFAULT nextval('public.email_requested_receipts_id_seq'::regclass);


--
-- Name: feedback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback ALTER COLUMN id SET DEFAULT nextval('public.feedback_id_seq'::regclass);


--
-- Name: government_responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.government_responses ALTER COLUMN id SET DEFAULT nextval('public.government_responses_id_seq'::regclass);


--
-- Name: holidays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays ALTER COLUMN id SET DEFAULT nextval('public.holidays_id_seq'::regclass);


--
-- Name: invalidations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invalidations ALTER COLUMN id SET DEFAULT nextval('public.invalidations_id_seq'::regclass);


--
-- Name: locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations ALTER COLUMN id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: parliaments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parliaments ALTER COLUMN id SET DEFAULT nextval('public.parliaments_id_seq'::regclass);


--
-- Name: petition_emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petition_emails ALTER COLUMN id SET DEFAULT nextval('public.petition_emails_id_seq'::regclass);


--
-- Name: petition_statistics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petition_statistics ALTER COLUMN id SET DEFAULT nextval('public.petition_statistics_id_seq'::regclass);


--
-- Name: petitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petitions ALTER COLUMN id SET DEFAULT nextval('public.petitions_id_seq'::regclass);


--
-- Name: rate_limits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_limits ALTER COLUMN id SET DEFAULT nextval('public.rate_limits_id_seq'::regclass);


--
-- Name: rejections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejections ALTER COLUMN id SET DEFAULT nextval('public.rejections_id_seq'::regclass);


--
-- Name: signatures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signatures ALTER COLUMN id SET DEFAULT nextval('public.signatures_id_seq'::regclass);


--
-- Name: sites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites ALTER COLUMN id SET DEFAULT nextval('public.sites_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: trending_domains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trending_domains ALTER COLUMN id SET DEFAULT nextval('public.trending_domains_id_seq'::regclass);


--
-- Name: trending_ips id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trending_ips ALTER COLUMN id SET DEFAULT nextval('public.trending_ips_id_seq'::regclass);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: archived_debate_outcomes archived_debate_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_debate_outcomes
    ADD CONSTRAINT archived_debate_outcomes_pkey PRIMARY KEY (id);


--
-- Name: archived_government_responses archived_government_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_government_responses
    ADD CONSTRAINT archived_government_responses_pkey PRIMARY KEY (id);


--
-- Name: archived_notes archived_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_notes
    ADD CONSTRAINT archived_notes_pkey PRIMARY KEY (id);


--
-- Name: archived_petition_emails archived_petition_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_petition_emails
    ADD CONSTRAINT archived_petition_emails_pkey PRIMARY KEY (id);


--
-- Name: archived_petitions archived_petitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_petitions
    ADD CONSTRAINT archived_petitions_pkey PRIMARY KEY (id);


--
-- Name: archived_rejections archived_rejections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_rejections
    ADD CONSTRAINT archived_rejections_pkey PRIMARY KEY (id);


--
-- Name: archived_signatures archived_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_signatures
    ADD CONSTRAINT archived_signatures_pkey PRIMARY KEY (id);


--
-- Name: constituencies constituencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constituencies
    ADD CONSTRAINT constituencies_pkey PRIMARY KEY (id);


--
-- Name: constituency_petition_journals constituency_petition_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constituency_petition_journals
    ADD CONSTRAINT constituency_petition_journals_pkey PRIMARY KEY (id);


--
-- Name: country_petition_journals country_petition_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.country_petition_journals
    ADD CONSTRAINT country_petition_journals_pkey PRIMARY KEY (id);


--
-- Name: debate_outcomes debate_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debate_outcomes
    ADD CONSTRAINT debate_outcomes_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: domains domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (id);


--
-- Name: email_requested_receipts email_requested_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_requested_receipts
    ADD CONSTRAINT email_requested_receipts_pkey PRIMARY KEY (id);


--
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- Name: government_responses government_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.government_responses
    ADD CONSTRAINT government_responses_pkey PRIMARY KEY (id);


--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: invalidations invalidations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invalidations
    ADD CONSTRAINT invalidations_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: parliaments parliaments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parliaments
    ADD CONSTRAINT parliaments_pkey PRIMARY KEY (id);


--
-- Name: petition_emails petition_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petition_emails
    ADD CONSTRAINT petition_emails_pkey PRIMARY KEY (id);


--
-- Name: petition_statistics petition_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petition_statistics
    ADD CONSTRAINT petition_statistics_pkey PRIMARY KEY (id);


--
-- Name: petitions petitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petitions
    ADD CONSTRAINT petitions_pkey PRIMARY KEY (id);


--
-- Name: rate_limits rate_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_limits
    ADD CONSTRAINT rate_limits_pkey PRIMARY KEY (id);


--
-- Name: rejections rejections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejections
    ADD CONSTRAINT rejections_pkey PRIMARY KEY (id);


--
-- Name: signatures signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT signatures_pkey PRIMARY KEY (id);


--
-- Name: sites sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: trending_domains trending_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trending_domains
    ADD CONSTRAINT trending_domains_pkey PRIMARY KEY (id);


--
-- Name: trending_ips trending_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trending_ips
    ADD CONSTRAINT trending_ips_pkey PRIMARY KEY (id);


--
-- Name: ft_index_invalidations_on_details; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ft_index_invalidations_on_details ON public.invalidations USING gin (to_tsvector('english'::regconfig, (details)::text));


--
-- Name: ft_index_invalidations_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ft_index_invalidations_on_id ON public.invalidations USING gin (to_tsvector('english'::regconfig, (id)::text));


--
-- Name: ft_index_invalidations_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ft_index_invalidations_on_petition_id ON public.invalidations USING gin (to_tsvector('english'::regconfig, (petition_id)::text));


--
-- Name: ft_index_invalidations_on_summary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ft_index_invalidations_on_summary ON public.invalidations USING gin (to_tsvector('english'::regconfig, (summary)::text));


--
-- Name: idx_constituency_petition_journal_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_constituency_petition_journal_uniqueness ON public.constituency_petition_journals USING btree (petition_id, constituency_id);


--
-- Name: index_admin_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admin_users_on_email ON public.admin_users USING btree (email);


--
-- Name: index_admin_users_on_last_name_and_first_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_users_on_last_name_and_first_name ON public.admin_users USING btree (last_name, first_name);


--
-- Name: index_archived_debate_outcomes_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_archived_debate_outcomes_on_petition_id ON public.archived_debate_outcomes USING btree (petition_id);


--
-- Name: index_archived_debate_outcomes_on_petition_id_and_debated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_debate_outcomes_on_petition_id_and_debated_on ON public.archived_debate_outcomes USING btree (petition_id, debated_on);


--
-- Name: index_archived_debate_outcomes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_debate_outcomes_on_updated_at ON public.archived_debate_outcomes USING btree (updated_at);


--
-- Name: index_archived_government_responses_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_archived_government_responses_on_petition_id ON public.archived_government_responses USING btree (petition_id);


--
-- Name: index_archived_government_responses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_government_responses_on_updated_at ON public.archived_government_responses USING btree (updated_at);


--
-- Name: index_archived_notes_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_archived_notes_on_petition_id ON public.archived_notes USING btree (petition_id);


--
-- Name: index_archived_petition_emails_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petition_emails_on_petition_id ON public.archived_petition_emails USING btree (petition_id);


--
-- Name: index_archived_petitions_on_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petitions_on_action ON public.archived_petitions USING gin (to_tsvector('english'::regconfig, (action)::text));


--
-- Name: index_archived_petitions_on_additional_details; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petitions_on_additional_details ON public.archived_petitions USING gin (to_tsvector('english'::regconfig, additional_details));


--
-- Name: index_archived_petitions_on_background; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petitions_on_background ON public.archived_petitions USING gin (to_tsvector('english'::regconfig, (background)::text));


--
-- Name: index_archived_petitions_on_locked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petitions_on_locked_by_id ON public.archived_petitions USING btree (locked_by_id);


--
-- Name: index_archived_petitions_on_mt_reached_at_and_moderation_lag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petitions_on_mt_reached_at_and_moderation_lag ON public.archived_petitions USING btree (moderation_threshold_reached_at, moderation_lag);


--
-- Name: index_archived_petitions_on_parliament_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petitions_on_parliament_id ON public.archived_petitions USING btree (parliament_id);


--
-- Name: index_archived_petitions_on_signature_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petitions_on_signature_count ON public.archived_petitions USING btree (signature_count);


--
-- Name: index_archived_petitions_on_state_and_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petitions_on_state_and_closed_at ON public.archived_petitions USING btree (state, closed_at);


--
-- Name: index_archived_petitions_on_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_petitions_on_tags ON public.archived_petitions USING gin (tags public.gin__int_ops);


--
-- Name: index_archived_rejections_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_archived_rejections_on_petition_id ON public.archived_rejections USING btree (petition_id);


--
-- Name: index_archived_signatures_on_constituency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_constituency_id ON public.archived_signatures USING btree (constituency_id);


--
-- Name: index_archived_signatures_on_creation_ip_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_creation_ip_and_petition_id ON public.archived_signatures USING btree (created_at, ip_address, petition_id);


--
-- Name: index_archived_signatures_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_domain ON public.archived_signatures USING btree ("substring"((email)::text, ("position"((email)::text, '@'::text) + 1)));


--
-- Name: index_archived_signatures_on_email_and_petition_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_archived_signatures_on_email_and_petition_id_and_name ON public.archived_signatures USING btree (email, petition_id, name);


--
-- Name: index_archived_signatures_on_inet; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_inet ON public.archived_signatures USING btree (((ip_address)::inet));


--
-- Name: index_archived_signatures_on_invalidation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_invalidation_id ON public.archived_signatures USING btree (invalidation_id);


--
-- Name: index_archived_signatures_on_ip_address_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_ip_address_and_petition_id ON public.archived_signatures USING btree (ip_address, petition_id);


--
-- Name: index_archived_signatures_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_name ON public.archived_signatures USING btree (lower((name)::text));


--
-- Name: index_archived_signatures_on_normalized_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_normalized_email ON public.archived_signatures USING btree (((regexp_replace("left"((email)::text, ("position"((email)::text, '@'::text) - 1)), '\.|\+.+'::text, ''::text, 'g'::text) || "substring"((email)::text, "position"((email)::text, '@'::text)))));


--
-- Name: index_archived_signatures_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_petition_id ON public.archived_signatures USING btree (petition_id);


--
-- Name: index_archived_signatures_on_petition_id_and_location_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_petition_id_and_location_code ON public.archived_signatures USING btree (petition_id, location_code);


--
-- Name: index_archived_signatures_on_petition_id_where_creator_is_true; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_archived_signatures_on_petition_id_where_creator_is_true ON public.archived_signatures USING btree (petition_id) WHERE (creator = true);


--
-- Name: index_archived_signatures_on_petition_id_where_sponsor_is_true; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_petition_id_where_sponsor_is_true ON public.archived_signatures USING btree (petition_id) WHERE (sponsor = true);


--
-- Name: index_archived_signatures_on_postcode_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_postcode_and_petition_id ON public.archived_signatures USING btree (postcode, petition_id);


--
-- Name: index_archived_signatures_on_postcode_and_state_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_postcode_and_state_and_petition_id ON public.archived_signatures USING btree (postcode, state, petition_id);


--
-- Name: index_archived_signatures_on_sector_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_sector_and_petition_id ON public.archived_signatures USING btree ("left"((postcode)::text, '-3'::integer), petition_id);


--
-- Name: index_archived_signatures_on_sector_and_state_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_sector_and_state_and_petition_id ON public.archived_signatures USING btree ("left"((postcode)::text, '-3'::integer), state, petition_id);


--
-- Name: index_archived_signatures_on_state_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_state_and_petition_id ON public.archived_signatures USING btree (state, petition_id);


--
-- Name: index_archived_signatures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_updated_at ON public.archived_signatures USING btree (updated_at);


--
-- Name: index_archived_signatures_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_uuid ON public.archived_signatures USING btree (uuid);


--
-- Name: index_archived_signatures_on_validated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_archived_signatures_on_validated_at ON public.archived_signatures USING btree (validated_at);


--
-- Name: index_constituencies_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_constituencies_on_external_id ON public.constituencies USING btree (external_id);


--
-- Name: index_constituencies_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_constituencies_on_slug ON public.constituencies USING btree (slug);


--
-- Name: index_country_petition_journals_on_petition_and_location; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_country_petition_journals_on_petition_and_location ON public.country_petition_journals USING btree (petition_id, location_code);


--
-- Name: index_debate_outcomes_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_debate_outcomes_on_petition_id ON public.debate_outcomes USING btree (petition_id);


--
-- Name: index_debate_outcomes_on_petition_id_and_debated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debate_outcomes_on_petition_id_and_debated_on ON public.debate_outcomes USING btree (petition_id, debated_on);


--
-- Name: index_debate_outcomes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debate_outcomes_on_updated_at ON public.debate_outcomes USING btree (updated_at);


--
-- Name: index_delayed_jobs_on_priority_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_priority_and_run_at ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_domains_on_canonical_domain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_domains_on_canonical_domain_id ON public.domains USING btree (canonical_domain_id);


--
-- Name: index_domains_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_domains_on_name ON public.domains USING btree (name);


--
-- Name: index_email_requested_receipts_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_requested_receipts_on_petition_id ON public.email_requested_receipts USING btree (petition_id);


--
-- Name: index_ft_tags_on_description; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ft_tags_on_description ON public.tags USING gin (to_tsvector('english'::regconfig, (description)::text));


--
-- Name: index_ft_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ft_tags_on_name ON public.tags USING gin (to_tsvector('english'::regconfig, (name)::text));


--
-- Name: index_government_responses_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_government_responses_on_petition_id ON public.government_responses USING btree (petition_id);


--
-- Name: index_government_responses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_government_responses_on_updated_at ON public.government_responses USING btree (updated_at);


--
-- Name: index_invalidations_on_cancelled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invalidations_on_cancelled_at ON public.invalidations USING btree (cancelled_at);


--
-- Name: index_invalidations_on_completed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invalidations_on_completed_at ON public.invalidations USING btree (completed_at);


--
-- Name: index_invalidations_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invalidations_on_petition_id ON public.invalidations USING btree (petition_id);


--
-- Name: index_invalidations_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invalidations_on_started_at ON public.invalidations USING btree (started_at);


--
-- Name: index_locations_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_locations_on_code ON public.locations USING btree (code);


--
-- Name: index_locations_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_locations_on_name ON public.locations USING btree (name);


--
-- Name: index_locations_on_start_date_and_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_start_date_and_end_date ON public.locations USING btree (start_date, end_date);


--
-- Name: index_notes_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notes_on_petition_id ON public.notes USING btree (petition_id);


--
-- Name: index_petition_emails_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petition_emails_on_petition_id ON public.petition_emails USING btree (petition_id);


--
-- Name: index_petition_statistics_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_petition_statistics_on_petition_id ON public.petition_statistics USING btree (petition_id);


--
-- Name: index_petitions_on_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_action ON public.petitions USING gin (to_tsvector('english'::regconfig, (action)::text));


--
-- Name: index_petitions_on_additional_details; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_additional_details ON public.petitions USING gin (to_tsvector('english'::regconfig, additional_details));


--
-- Name: index_petitions_on_archived_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_archived_at ON public.petitions USING btree (archived_at);


--
-- Name: index_petitions_on_background; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_background ON public.petitions USING gin (to_tsvector('english'::regconfig, (background)::text));


--
-- Name: index_petitions_on_created_at_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_created_at_and_state ON public.petitions USING btree (created_at, state);


--
-- Name: index_petitions_on_debate_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_debate_state ON public.petitions USING btree (debate_state);


--
-- Name: index_petitions_on_debate_threshold_reached_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_debate_threshold_reached_at ON public.petitions USING btree (debate_threshold_reached_at);


--
-- Name: index_petitions_on_last_signed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_last_signed_at ON public.petitions USING btree (last_signed_at);


--
-- Name: index_petitions_on_locked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_locked_by_id ON public.petitions USING btree (locked_by_id);


--
-- Name: index_petitions_on_mt_reached_at_and_moderation_lag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_mt_reached_at_and_moderation_lag ON public.petitions USING btree (moderation_threshold_reached_at, moderation_lag);


--
-- Name: index_petitions_on_response_threshold_reached_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_response_threshold_reached_at ON public.petitions USING btree (response_threshold_reached_at);


--
-- Name: index_petitions_on_signature_count_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_signature_count_and_state ON public.petitions USING btree (signature_count, state);


--
-- Name: index_petitions_on_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_petitions_on_tags ON public.petitions USING gin (tags public.gin__int_ops);


--
-- Name: index_rejections_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rejections_on_petition_id ON public.rejections USING btree (petition_id);


--
-- Name: index_signatures_on_archived_at_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_archived_at_and_petition_id ON public.signatures USING btree (archived_at, petition_id);


--
-- Name: index_signatures_on_canonical_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_canonical_email ON public.signatures USING btree (canonical_email);


--
-- Name: index_signatures_on_constituency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_constituency_id ON public.signatures USING btree (constituency_id);


--
-- Name: index_signatures_on_created_at_and_ip_address_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_created_at_and_ip_address_and_petition_id ON public.signatures USING btree (created_at, ip_address, petition_id);


--
-- Name: index_signatures_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_domain ON public.signatures USING btree ("substring"((email)::text, ("position"((email)::text, '@'::text) + 1)));


--
-- Name: index_signatures_on_email_and_petition_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_signatures_on_email_and_petition_id_and_name ON public.signatures USING btree (email, petition_id, name);


--
-- Name: index_signatures_on_form_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_form_token ON public.signatures USING btree (form_token);


--
-- Name: index_signatures_on_inet; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_inet ON public.signatures USING btree (((ip_address)::inet));


--
-- Name: index_signatures_on_invalidation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_invalidation_id ON public.signatures USING btree (invalidation_id);


--
-- Name: index_signatures_on_ip_address_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_ip_address_and_petition_id ON public.signatures USING btree (ip_address, petition_id);


--
-- Name: index_signatures_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_name ON public.signatures USING btree (lower((name)::text));


--
-- Name: index_signatures_on_normalized_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_normalized_email ON public.signatures USING btree (((regexp_replace("left"((email)::text, ("position"((email)::text, '@'::text) - 1)), '\.|\+.+'::text, ''::text, 'g'::text) || "substring"((email)::text, "position"((email)::text, '@'::text)))));


--
-- Name: index_signatures_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_petition_id ON public.signatures USING btree (petition_id);


--
-- Name: index_signatures_on_petition_id_and_location_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_petition_id_and_location_code ON public.signatures USING btree (petition_id, location_code);


--
-- Name: index_signatures_on_petition_id_where_creator_is_true; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_signatures_on_petition_id_where_creator_is_true ON public.signatures USING btree (petition_id) WHERE (creator = true);


--
-- Name: index_signatures_on_petition_id_where_sponsor_is_true; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_petition_id_where_sponsor_is_true ON public.signatures USING btree (petition_id) WHERE (sponsor = true);


--
-- Name: index_signatures_on_postcode_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_postcode_and_petition_id ON public.signatures USING btree (postcode, petition_id);


--
-- Name: index_signatures_on_postcode_and_state_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_postcode_and_state_and_petition_id ON public.signatures USING btree (postcode, state, petition_id);


--
-- Name: index_signatures_on_sector_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_sector_and_petition_id ON public.signatures USING btree ("left"((postcode)::text, '-3'::integer), petition_id);


--
-- Name: index_signatures_on_sector_and_state_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_sector_and_state_and_petition_id ON public.signatures USING btree ("left"((postcode)::text, '-3'::integer), state, petition_id);


--
-- Name: index_signatures_on_state_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_state_and_petition_id ON public.signatures USING btree (state, petition_id);


--
-- Name: index_signatures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_updated_at ON public.signatures USING btree (updated_at);


--
-- Name: index_signatures_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_uuid ON public.signatures USING btree (uuid);


--
-- Name: index_signatures_on_validated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signatures_on_validated_at ON public.signatures USING btree (validated_at);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_tasks_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tasks_on_name ON public.tasks USING btree (name);


--
-- Name: index_trending_domains_on_created_at_and_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trending_domains_on_created_at_and_count ON public.trending_domains USING btree (created_at, count DESC);


--
-- Name: index_trending_domains_on_domain_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trending_domains_on_domain_and_petition_id ON public.trending_domains USING btree (domain, petition_id);


--
-- Name: index_trending_domains_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trending_domains_on_petition_id ON public.trending_domains USING btree (petition_id);


--
-- Name: index_trending_ips_on_created_at_and_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trending_ips_on_created_at_and_count ON public.trending_ips USING btree (created_at, count DESC);


--
-- Name: index_trending_ips_on_ip_address_and_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trending_ips_on_ip_address_and_petition_id ON public.trending_ips USING btree (ip_address, petition_id);


--
-- Name: index_trending_ips_on_petition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trending_ips_on_petition_id ON public.trending_ips USING btree (petition_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: government_responses fk_rails_0af6bc4d41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.government_responses
    ADD CONSTRAINT fk_rails_0af6bc4d41 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: trending_ips fk_rails_161c5b5e43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trending_ips
    ADD CONSTRAINT fk_rails_161c5b5e43 FOREIGN KEY (petition_id) REFERENCES public.petitions(id);


--
-- Name: trending_domains fk_rails_1f51885fb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trending_domains
    ADD CONSTRAINT fk_rails_1f51885fb0 FOREIGN KEY (petition_id) REFERENCES public.petitions(id);


--
-- Name: domains fk_rails_3112c9a009; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT fk_rails_3112c9a009 FOREIGN KEY (canonical_domain_id) REFERENCES public.domains(id);


--
-- Name: archived_petition_emails fk_rails_388e94fd73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_petition_emails
    ADD CONSTRAINT fk_rails_388e94fd73 FOREIGN KEY (petition_id) REFERENCES public.archived_petitions(id) ON DELETE CASCADE;


--
-- Name: archived_signatures fk_rails_39cbbc815d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_signatures
    ADD CONSTRAINT fk_rails_39cbbc815d FOREIGN KEY (petition_id) REFERENCES public.archived_petitions(id) ON DELETE CASCADE;


--
-- Name: signatures fk_rails_3e01179571; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT fk_rails_3e01179571 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: notes fk_rails_3e3a2f376e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_rails_3e3a2f376e FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: constituency_petition_journals fk_rails_5186723bbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constituency_petition_journals
    ADD CONSTRAINT fk_rails_5186723bbd FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: archived_government_responses fk_rails_696590b5b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_government_responses
    ADD CONSTRAINT fk_rails_696590b5b6 FOREIGN KEY (petition_id) REFERENCES public.archived_petitions(id) ON DELETE CASCADE;


--
-- Name: archived_debate_outcomes fk_rails_81c5c409a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_debate_outcomes
    ADD CONSTRAINT fk_rails_81c5c409a1 FOREIGN KEY (petition_id) REFERENCES public.archived_petitions(id) ON DELETE CASCADE;


--
-- Name: rejections fk_rails_82ffb00060; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejections
    ADD CONSTRAINT fk_rails_82ffb00060 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: email_requested_receipts fk_rails_898597541e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_requested_receipts
    ADD CONSTRAINT fk_rails_898597541e FOREIGN KEY (petition_id) REFERENCES public.petitions(id);


--
-- Name: archived_notes fk_rails_9621060128; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_notes
    ADD CONSTRAINT fk_rails_9621060128 FOREIGN KEY (petition_id) REFERENCES public.archived_petitions(id) ON DELETE CASCADE;


--
-- Name: archived_petitions fk_rails_978050318c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_petitions
    ADD CONSTRAINT fk_rails_978050318c FOREIGN KEY (parliament_id) REFERENCES public.parliaments(id);


--
-- Name: petition_emails fk_rails_9f55aacb99; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petition_emails
    ADD CONSTRAINT fk_rails_9f55aacb99 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- Name: petition_statistics fk_rails_a6de6b1362; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.petition_statistics
    ADD CONSTRAINT fk_rails_a6de6b1362 FOREIGN KEY (petition_id) REFERENCES public.petitions(id);


--
-- Name: archived_rejections fk_rails_b6266f73f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_rejections
    ADD CONSTRAINT fk_rails_b6266f73f1 FOREIGN KEY (petition_id) REFERENCES public.archived_petitions(id) ON DELETE CASCADE;


--
-- Name: debate_outcomes fk_rails_cb057e3dd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debate_outcomes
    ADD CONSTRAINT fk_rails_cb057e3dd1 FOREIGN KEY (petition_id) REFERENCES public.petitions(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20150602200239');

INSERT INTO schema_migrations (version) VALUES ('20150603033108');

INSERT INTO schema_migrations (version) VALUES ('20150603112821');

INSERT INTO schema_migrations (version) VALUES ('20150605100049');

INSERT INTO schema_migrations (version) VALUES ('20150609111042');

INSERT INTO schema_migrations (version) VALUES ('20150610091149');

INSERT INTO schema_migrations (version) VALUES ('20150612095611');

INSERT INTO schema_migrations (version) VALUES ('20150612103324');

INSERT INTO schema_migrations (version) VALUES ('20150612111204');

INSERT INTO schema_migrations (version) VALUES ('20150615131623');

INSERT INTO schema_migrations (version) VALUES ('20150615145953');

INSERT INTO schema_migrations (version) VALUES ('20150615151103');

INSERT INTO schema_migrations (version) VALUES ('20150617114935');

INSERT INTO schema_migrations (version) VALUES ('20150617135014');

INSERT INTO schema_migrations (version) VALUES ('20150617164310');

INSERT INTO schema_migrations (version) VALUES ('20150618134919');

INSERT INTO schema_migrations (version) VALUES ('20150618143114');

INSERT INTO schema_migrations (version) VALUES ('20150618144922');

INSERT INTO schema_migrations (version) VALUES ('20150618233548');

INSERT INTO schema_migrations (version) VALUES ('20150618233718');

INSERT INTO schema_migrations (version) VALUES ('20150619075903');

INSERT INTO schema_migrations (version) VALUES ('20150619090833');

INSERT INTO schema_migrations (version) VALUES ('20150619133502');

INSERT INTO schema_migrations (version) VALUES ('20150619134335');

INSERT INTO schema_migrations (version) VALUES ('20150621200307');

INSERT INTO schema_migrations (version) VALUES ('20150622083615');

INSERT INTO schema_migrations (version) VALUES ('20150622140322');

INSERT INTO schema_migrations (version) VALUES ('20150630105949');

INSERT INTO schema_migrations (version) VALUES ('20150701111544');

INSERT INTO schema_migrations (version) VALUES ('20150701145201');

INSERT INTO schema_migrations (version) VALUES ('20150701145202');

INSERT INTO schema_migrations (version) VALUES ('20150701151007');

INSERT INTO schema_migrations (version) VALUES ('20150701151008');

INSERT INTO schema_migrations (version) VALUES ('20150701165424');

INSERT INTO schema_migrations (version) VALUES ('20150701165425');

INSERT INTO schema_migrations (version) VALUES ('20150701174136');

INSERT INTO schema_migrations (version) VALUES ('20150703100716');

INSERT INTO schema_migrations (version) VALUES ('20150703165930');

INSERT INTO schema_migrations (version) VALUES ('20150705114811');

INSERT INTO schema_migrations (version) VALUES ('20150707094523');

INSERT INTO schema_migrations (version) VALUES ('20150709152530');

INSERT INTO schema_migrations (version) VALUES ('20150714140659');

INSERT INTO schema_migrations (version) VALUES ('20150730110838');

INSERT INTO schema_migrations (version) VALUES ('20150805142206');

INSERT INTO schema_migrations (version) VALUES ('20150805142254');

INSERT INTO schema_migrations (version) VALUES ('20150806140552');

INSERT INTO schema_migrations (version) VALUES ('20150814111100');

INSERT INTO schema_migrations (version) VALUES ('20150820152623');

INSERT INTO schema_migrations (version) VALUES ('20150820153515');

INSERT INTO schema_migrations (version) VALUES ('20150820155740');

INSERT INTO schema_migrations (version) VALUES ('20150820161504');

INSERT INTO schema_migrations (version) VALUES ('20150913073343');

INSERT INTO schema_migrations (version) VALUES ('20150913074747');

INSERT INTO schema_migrations (version) VALUES ('20150924082835');

INSERT INTO schema_migrations (version) VALUES ('20150924082944');

INSERT INTO schema_migrations (version) VALUES ('20150924090755');

INSERT INTO schema_migrations (version) VALUES ('20150924091057');

INSERT INTO schema_migrations (version) VALUES ('20150928162418');

INSERT INTO schema_migrations (version) VALUES ('20151014152915');

INSERT INTO schema_migrations (version) VALUES ('20151014152929');

INSERT INTO schema_migrations (version) VALUES ('20160104144458');

INSERT INTO schema_migrations (version) VALUES ('20160210001632');

INSERT INTO schema_migrations (version) VALUES ('20160210174624');

INSERT INTO schema_migrations (version) VALUES ('20160210195916');

INSERT INTO schema_migrations (version) VALUES ('20160211002731');

INSERT INTO schema_migrations (version) VALUES ('20160211003703');

INSERT INTO schema_migrations (version) VALUES ('20160214133749');

INSERT INTO schema_migrations (version) VALUES ('20160214233414');

INSERT INTO schema_migrations (version) VALUES ('20160217192016');

INSERT INTO schema_migrations (version) VALUES ('20160527112417');

INSERT INTO schema_migrations (version) VALUES ('20160704152204');

INSERT INTO schema_migrations (version) VALUES ('20160704162920');

INSERT INTO schema_migrations (version) VALUES ('20160704185825');

INSERT INTO schema_migrations (version) VALUES ('20160706060256');

INSERT INTO schema_migrations (version) VALUES ('20160713124623');

INSERT INTO schema_migrations (version) VALUES ('20160713130452');

INSERT INTO schema_migrations (version) VALUES ('20160715092819');

INSERT INTO schema_migrations (version) VALUES ('20160716164929');

INSERT INTO schema_migrations (version) VALUES ('20160819062044');

INSERT INTO schema_migrations (version) VALUES ('20160819062058');

INSERT INTO schema_migrations (version) VALUES ('20160820132056');

INSERT INTO schema_migrations (version) VALUES ('20160820162023');

INSERT INTO schema_migrations (version) VALUES ('20160820165029');

INSERT INTO schema_migrations (version) VALUES ('20160822064645');

INSERT INTO schema_migrations (version) VALUES ('20160910054223');

INSERT INTO schema_migrations (version) VALUES ('20161006095752');

INSERT INTO schema_migrations (version) VALUES ('20161006101123');

INSERT INTO schema_migrations (version) VALUES ('20170419165419');

INSERT INTO schema_migrations (version) VALUES ('20170422104143');

INSERT INTO schema_migrations (version) VALUES ('20170424145119');

INSERT INTO schema_migrations (version) VALUES ('20170428185435');

INSERT INTO schema_migrations (version) VALUES ('20170428211336');

INSERT INTO schema_migrations (version) VALUES ('20170429023722');

INSERT INTO schema_migrations (version) VALUES ('20170501093620');

INSERT INTO schema_migrations (version) VALUES ('20170502155040');

INSERT INTO schema_migrations (version) VALUES ('20170503192115');

INSERT INTO schema_migrations (version) VALUES ('20170610132850');

INSERT INTO schema_migrations (version) VALUES ('20170611115913');

INSERT INTO schema_migrations (version) VALUES ('20170611123348');

INSERT INTO schema_migrations (version) VALUES ('20170611131130');

INSERT INTO schema_migrations (version) VALUES ('20170611190354');

INSERT INTO schema_migrations (version) VALUES ('20170612120307');

INSERT INTO schema_migrations (version) VALUES ('20170612144648');

INSERT INTO schema_migrations (version) VALUES ('20170613113510');

INSERT INTO schema_migrations (version) VALUES ('20170614165953');

INSERT INTO schema_migrations (version) VALUES ('20170615133536');

INSERT INTO schema_migrations (version) VALUES ('20170622114605');

INSERT INTO schema_migrations (version) VALUES ('20170622114801');

INSERT INTO schema_migrations (version) VALUES ('20170622151936');

INSERT INTO schema_migrations (version) VALUES ('20170622152415');

INSERT INTO schema_migrations (version) VALUES ('20170622161343');

INSERT INTO schema_migrations (version) VALUES ('20170623144023');

INSERT INTO schema_migrations (version) VALUES ('20170626123257');

INSERT INTO schema_migrations (version) VALUES ('20170626130418');

INSERT INTO schema_migrations (version) VALUES ('20170627125046');

INSERT INTO schema_migrations (version) VALUES ('20170629144129');

INSERT INTO schema_migrations (version) VALUES ('20170703100952');

INSERT INTO schema_migrations (version) VALUES ('20170710090730');

INSERT INTO schema_migrations (version) VALUES ('20170711112737');

INSERT INTO schema_migrations (version) VALUES ('20170711134626');

INSERT INTO schema_migrations (version) VALUES ('20170711134758');

INSERT INTO schema_migrations (version) VALUES ('20170711153944');

INSERT INTO schema_migrations (version) VALUES ('20170711153945');

INSERT INTO schema_migrations (version) VALUES ('20170712070139');

INSERT INTO schema_migrations (version) VALUES ('20170713193039');

INSERT INTO schema_migrations (version) VALUES ('20170818110849');

INSERT INTO schema_migrations (version) VALUES ('20170821153056');

INSERT INTO schema_migrations (version) VALUES ('20170821153057');

INSERT INTO schema_migrations (version) VALUES ('20170903162156');

INSERT INTO schema_migrations (version) VALUES ('20170903181738');

INSERT INTO schema_migrations (version) VALUES ('20170906203439');

INSERT INTO schema_migrations (version) VALUES ('20170909092251');

INSERT INTO schema_migrations (version) VALUES ('20170909095357');

INSERT INTO schema_migrations (version) VALUES ('20170915102120');

INSERT INTO schema_migrations (version) VALUES ('20170918162913');

INSERT INTO schema_migrations (version) VALUES ('20171204113835');

INSERT INTO schema_migrations (version) VALUES ('20171204122339');

INSERT INTO schema_migrations (version) VALUES ('20180329062433');

INSERT INTO schema_migrations (version) VALUES ('20180510122656');

INSERT INTO schema_migrations (version) VALUES ('20180510131346');

INSERT INTO schema_migrations (version) VALUES ('20180623131406');

INSERT INTO schema_migrations (version) VALUES ('20181201073159');

INSERT INTO schema_migrations (version) VALUES ('20181202102751');

INSERT INTO schema_migrations (version) VALUES ('20181211115757');

INSERT INTO schema_migrations (version) VALUES ('20190323135704');

INSERT INTO schema_migrations (version) VALUES ('20190323155133');

INSERT INTO schema_migrations (version) VALUES ('20190323155704');

INSERT INTO schema_migrations (version) VALUES ('20190324113503');

INSERT INTO schema_migrations (version) VALUES ('20190325204926');

INSERT INTO schema_migrations (version) VALUES ('20190325205128');

INSERT INTO schema_migrations (version) VALUES ('20190325205137');

INSERT INTO schema_migrations (version) VALUES ('20190326144123');

INSERT INTO schema_migrations (version) VALUES ('20190327025958');

INSERT INTO schema_migrations (version) VALUES ('20190328191633');

INSERT INTO schema_migrations (version) VALUES ('20190330185021');

INSERT INTO schema_migrations (version) VALUES ('20190331160833');

INSERT INTO schema_migrations (version) VALUES ('20190401040652');

INSERT INTO schema_migrations (version) VALUES ('20190405110431');

INSERT INTO schema_migrations (version) VALUES ('20190405175143');

INSERT INTO schema_migrations (version) VALUES ('20190405201240');

INSERT INTO schema_migrations (version) VALUES ('20190411173349');

INSERT INTO schema_migrations (version) VALUES ('20190411174307');

INSERT INTO schema_migrations (version) VALUES ('20190412182125');

INSERT INTO schema_migrations (version) VALUES ('20190413170435');

INSERT INTO schema_migrations (version) VALUES ('20190413170618');

INSERT INTO schema_migrations (version) VALUES ('20190413174332');

INSERT INTO schema_migrations (version) VALUES ('20190414081712');

INSERT INTO schema_migrations (version) VALUES ('20190414083111');

INSERT INTO schema_migrations (version) VALUES ('20190414234613');

INSERT INTO schema_migrations (version) VALUES ('20190415015616');

INSERT INTO schema_migrations (version) VALUES ('20190419065717');

INSERT INTO schema_migrations (version) VALUES ('20190420112847');

INSERT INTO schema_migrations (version) VALUES ('20190420112856');

INSERT INTO schema_migrations (version) VALUES ('20190501120348');

INSERT INTO schema_migrations (version) VALUES ('20190502104930');

INSERT INTO schema_migrations (version) VALUES ('20190502105505');

INSERT INTO schema_migrations (version) VALUES ('20190502105750');

