SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admin_users (
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

CREATE SEQUENCE admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admin_users_id_seq OWNED BY admin_users.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: archived_debate_outcomes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_debate_outcomes (
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
    commons_image_updated_at timestamp without time zone
);


--
-- Name: archived_debate_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_debate_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_debate_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_debate_outcomes_id_seq OWNED BY archived_debate_outcomes.id;


--
-- Name: archived_government_responses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_government_responses (
    id integer NOT NULL,
    petition_id integer,
    summary character varying(500) NOT NULL,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: archived_government_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_government_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_government_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_government_responses_id_seq OWNED BY archived_government_responses.id;


--
-- Name: archived_notes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_notes (
    id integer NOT NULL,
    petition_id integer,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: archived_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_notes_id_seq OWNED BY archived_notes.id;


--
-- Name: archived_petition_emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_petition_emails (
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

CREATE SEQUENCE archived_petition_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_petition_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_petition_emails_id_seq OWNED BY archived_petition_emails.id;


--
-- Name: archived_petitions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_petitions (
    id integer NOT NULL,
    title character varying(255),
    description text,
    response text,
    state character varying(10) DEFAULT 'open'::character varying NOT NULL,
    reason_for_rejection text,
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
    special_consideration boolean
);


--
-- Name: archived_petitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_petitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999
    CACHE 1;


--
-- Name: archived_petitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_petitions_id_seq OWNED BY archived_petitions.id;


--
-- Name: archived_rejections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_rejections (
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

CREATE SEQUENCE archived_rejections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_rejections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_rejections_id_seq OWNED BY archived_rejections.id;


--
-- Name: archived_signatures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_signatures (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    state character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    perishable_token character varying(255),
    postcode character varying(255),
    ip_address character varying(20),
    petition_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notify_by_email boolean DEFAULT true,
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
    creator boolean DEFAULT false NOT NULL,
    sponsor boolean DEFAULT false NOT NULL
);


--
-- Name: archived_signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_signatures_id_seq OWNED BY archived_signatures.id;


--
-- Name: constituencies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE constituencies (
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
    example_postcode character varying(30)
);


--
-- Name: constituencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE constituencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: constituencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE constituencies_id_seq OWNED BY constituencies.id;


--
-- Name: constituency_petition_journals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE constituency_petition_journals (
    id integer NOT NULL,
    constituency_id character varying NOT NULL,
    petition_id integer NOT NULL,
    signature_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: constituency_petition_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE constituency_petition_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: constituency_petition_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE constituency_petition_journals_id_seq OWNED BY constituency_petition_journals.id;


--
-- Name: country_petition_journals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE country_petition_journals (
    id integer NOT NULL,
    petition_id integer NOT NULL,
    signature_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    location_code character varying(30)
);


--
-- Name: country_petition_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE country_petition_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: country_petition_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE country_petition_journals_id_seq OWNED BY country_petition_journals.id;


--
-- Name: debate_outcomes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE debate_outcomes (
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
    commons_image_updated_at timestamp without time zone
);


--
-- Name: debate_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE debate_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: debate_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE debate_outcomes_id_seq OWNED BY debate_outcomes.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
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

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: email_requested_receipts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE email_requested_receipts (
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

CREATE SEQUENCE email_requested_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_requested_receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE email_requested_receipts_id_seq OWNED BY email_requested_receipts.id;


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feedback (
    id integer NOT NULL,
    comment character varying(32768) NOT NULL,
    petition_link_or_title character varying,
    email character varying,
    user_agent character varying
);


--
-- Name: feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feedback_id_seq OWNED BY feedback.id;


--
-- Name: government_responses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE government_responses (
    id integer NOT NULL,
    petition_id integer,
    summary character varying(500) NOT NULL,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: government_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE government_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: government_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE government_responses_id_seq OWNED BY government_responses.id;


--
-- Name: invalidations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invalidations (
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
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: invalidations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invalidations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invalidations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invalidations_id_seq OWNED BY invalidations.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE locations (
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

CREATE SEQUENCE locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE locations_id_seq OWNED BY locations.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notes (
    id integer NOT NULL,
    petition_id integer,
    details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notes_id_seq OWNED BY notes.id;


--
-- Name: parliaments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE parliaments (
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
    petition_duration integer DEFAULT 6
);


--
-- Name: parliaments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE parliaments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parliaments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE parliaments_id_seq OWNED BY parliaments.id;


--
-- Name: petition_emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE petition_emails (
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

CREATE SEQUENCE petition_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: petition_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE petition_emails_id_seq OWNED BY petition_emails.id;


--
-- Name: petitions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE petitions (
    id integer NOT NULL,
    action character varying(255) NOT NULL,
    additional_details text,
    state character varying(10) DEFAULT 'pending'::character varying NOT NULL,
    open_at timestamp without time zone,
    creator_signature_id integer NOT NULL,
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
    special_consideration boolean
);


--
-- Name: petitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE petitions_id_seq
    START WITH 100000
    INCREMENT BY 1
    MINVALUE 100000
    NO MAXVALUE
    CACHE 1;


--
-- Name: petitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE petitions_id_seq OWNED BY petitions.id;


--
-- Name: rate_limits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE rate_limits (
    id integer NOT NULL,
    burst_rate integer DEFAULT 1 NOT NULL,
    burst_period integer DEFAULT 60 NOT NULL,
    sustained_rate integer DEFAULT 5 NOT NULL,
    sustained_period integer DEFAULT 300 NOT NULL,
    domain_whitelist character varying(10000) DEFAULT ''::character varying NOT NULL,
    ip_whitelist character varying(10000) DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    domain_blacklist character varying(50000) DEFAULT ''::character varying NOT NULL,
    ip_blacklist character varying(50000) DEFAULT ''::character varying NOT NULL,
    geoblocking_enabled boolean DEFAULT false NOT NULL,
    countries character varying(2000) DEFAULT ''::character varying NOT NULL
);


--
-- Name: rate_limits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rate_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_limits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rate_limits_id_seq OWNED BY rate_limits.id;


--
-- Name: rejections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE rejections (
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

CREATE SEQUENCE rejections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rejections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rejections_id_seq OWNED BY rejections.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: signatures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE signatures (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    state character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    perishable_token character varying(255),
    postcode character varying(255),
    ip_address character varying(20),
    petition_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notify_by_email boolean DEFAULT true,
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
    uuid uuid
);


--
-- Name: signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE signatures_id_seq OWNED BY signatures.id;


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sites (
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
    login_timeout integer DEFAULT 1800 NOT NULL
);


--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sites_id_seq OWNED BY sites.id;


--
-- Name: sponsors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sponsors (
    id integer NOT NULL,
    petition_id integer,
    signature_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sponsors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sponsors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sponsors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sponsors_id_seq OWNED BY sponsors.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tasks (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tasks_id_seq OWNED BY tasks.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY admin_users ALTER COLUMN id SET DEFAULT nextval('admin_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_debate_outcomes ALTER COLUMN id SET DEFAULT nextval('archived_debate_outcomes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_government_responses ALTER COLUMN id SET DEFAULT nextval('archived_government_responses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_notes ALTER COLUMN id SET DEFAULT nextval('archived_notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_petition_emails ALTER COLUMN id SET DEFAULT nextval('archived_petition_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_petitions ALTER COLUMN id SET DEFAULT nextval('archived_petitions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_rejections ALTER COLUMN id SET DEFAULT nextval('archived_rejections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_signatures ALTER COLUMN id SET DEFAULT nextval('archived_signatures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY constituencies ALTER COLUMN id SET DEFAULT nextval('constituencies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY constituency_petition_journals ALTER COLUMN id SET DEFAULT nextval('constituency_petition_journals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY country_petition_journals ALTER COLUMN id SET DEFAULT nextval('country_petition_journals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY debate_outcomes ALTER COLUMN id SET DEFAULT nextval('debate_outcomes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_requested_receipts ALTER COLUMN id SET DEFAULT nextval('email_requested_receipts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feedback ALTER COLUMN id SET DEFAULT nextval('feedback_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY government_responses ALTER COLUMN id SET DEFAULT nextval('government_responses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invalidations ALTER COLUMN id SET DEFAULT nextval('invalidations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY locations ALTER COLUMN id SET DEFAULT nextval('locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notes ALTER COLUMN id SET DEFAULT nextval('notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY parliaments ALTER COLUMN id SET DEFAULT nextval('parliaments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY petition_emails ALTER COLUMN id SET DEFAULT nextval('petition_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY petitions ALTER COLUMN id SET DEFAULT nextval('petitions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rate_limits ALTER COLUMN id SET DEFAULT nextval('rate_limits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rejections ALTER COLUMN id SET DEFAULT nextval('rejections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY signatures ALTER COLUMN id SET DEFAULT nextval('signatures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sites ALTER COLUMN id SET DEFAULT nextval('sites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sponsors ALTER COLUMN id SET DEFAULT nextval('sponsors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks ALTER COLUMN id SET DEFAULT nextval('tasks_id_seq'::regclass);


--
-- Name: admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: archived_debate_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_debate_outcomes
    ADD CONSTRAINT archived_debate_outcomes_pkey PRIMARY KEY (id);


--
-- Name: archived_government_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_government_responses
    ADD CONSTRAINT archived_government_responses_pkey PRIMARY KEY (id);


--
-- Name: archived_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_notes
    ADD CONSTRAINT archived_notes_pkey PRIMARY KEY (id);


--
-- Name: archived_petition_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_petition_emails
    ADD CONSTRAINT archived_petition_emails_pkey PRIMARY KEY (id);


--
-- Name: archived_petitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_petitions
    ADD CONSTRAINT archived_petitions_pkey PRIMARY KEY (id);


--
-- Name: archived_rejections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_rejections
    ADD CONSTRAINT archived_rejections_pkey PRIMARY KEY (id);


--
-- Name: archived_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_signatures
    ADD CONSTRAINT archived_signatures_pkey PRIMARY KEY (id);


--
-- Name: constituencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY constituencies
    ADD CONSTRAINT constituencies_pkey PRIMARY KEY (id);


--
-- Name: constituency_petition_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY constituency_petition_journals
    ADD CONSTRAINT constituency_petition_journals_pkey PRIMARY KEY (id);


--
-- Name: country_petition_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY country_petition_journals
    ADD CONSTRAINT country_petition_journals_pkey PRIMARY KEY (id);


--
-- Name: debate_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY debate_outcomes
    ADD CONSTRAINT debate_outcomes_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: email_requested_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY email_requested_receipts
    ADD CONSTRAINT email_requested_receipts_pkey PRIMARY KEY (id);


--
-- Name: feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- Name: government_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY government_responses
    ADD CONSTRAINT government_responses_pkey PRIMARY KEY (id);


--
-- Name: invalidations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invalidations
    ADD CONSTRAINT invalidations_pkey PRIMARY KEY (id);


--
-- Name: locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: parliaments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY parliaments
    ADD CONSTRAINT parliaments_pkey PRIMARY KEY (id);


--
-- Name: petition_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY petition_emails
    ADD CONSTRAINT petition_emails_pkey PRIMARY KEY (id);


--
-- Name: petitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY petitions
    ADD CONSTRAINT petitions_pkey PRIMARY KEY (id);


--
-- Name: rate_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY rate_limits
    ADD CONSTRAINT rate_limits_pkey PRIMARY KEY (id);


--
-- Name: rejections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY rejections
    ADD CONSTRAINT rejections_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY signatures
    ADD CONSTRAINT signatures_pkey PRIMARY KEY (id);


--
-- Name: sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- Name: sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sponsors
    ADD CONSTRAINT sponsors_pkey PRIMARY KEY (id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: ft_index_invalidations_on_details; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ft_index_invalidations_on_details ON invalidations USING gin (to_tsvector('english'::regconfig, (details)::text));


--
-- Name: ft_index_invalidations_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ft_index_invalidations_on_id ON invalidations USING gin (to_tsvector('english'::regconfig, (id)::text));


--
-- Name: ft_index_invalidations_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ft_index_invalidations_on_petition_id ON invalidations USING gin (to_tsvector('english'::regconfig, (petition_id)::text));


--
-- Name: ft_index_invalidations_on_summary; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ft_index_invalidations_on_summary ON invalidations USING gin (to_tsvector('english'::regconfig, (summary)::text));


--
-- Name: idx_constituency_petition_journal_uniqueness; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX idx_constituency_petition_journal_uniqueness ON constituency_petition_journals USING btree (petition_id, constituency_id);


--
-- Name: index_admin_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_admin_users_on_email ON admin_users USING btree (email);


--
-- Name: index_admin_users_on_last_name_and_first_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_admin_users_on_last_name_and_first_name ON admin_users USING btree (last_name, first_name);


--
-- Name: index_archived_debate_outcomes_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_archived_debate_outcomes_on_petition_id ON archived_debate_outcomes USING btree (petition_id);


--
-- Name: index_archived_debate_outcomes_on_petition_id_and_debated_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_debate_outcomes_on_petition_id_and_debated_on ON archived_debate_outcomes USING btree (petition_id, debated_on);


--
-- Name: index_archived_debate_outcomes_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_debate_outcomes_on_updated_at ON archived_debate_outcomes USING btree (updated_at);


--
-- Name: index_archived_government_responses_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_archived_government_responses_on_petition_id ON archived_government_responses USING btree (petition_id);


--
-- Name: index_archived_government_responses_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_government_responses_on_updated_at ON archived_government_responses USING btree (updated_at);


--
-- Name: index_archived_notes_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_archived_notes_on_petition_id ON archived_notes USING btree (petition_id);


--
-- Name: index_archived_petition_emails_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petition_emails_on_petition_id ON archived_petition_emails USING btree (petition_id);


--
-- Name: index_archived_petitions_on_action; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petitions_on_action ON archived_petitions USING gin (to_tsvector('english'::regconfig, (action)::text));


--
-- Name: index_archived_petitions_on_additional_details; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petitions_on_additional_details ON archived_petitions USING gin (to_tsvector('english'::regconfig, additional_details));


--
-- Name: index_archived_petitions_on_background; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petitions_on_background ON archived_petitions USING gin (to_tsvector('english'::regconfig, (background)::text));


--
-- Name: index_archived_petitions_on_description; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petitions_on_description ON archived_petitions USING gin (to_tsvector('english'::regconfig, description));


--
-- Name: index_archived_petitions_on_parliament_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petitions_on_parliament_id ON archived_petitions USING btree (parliament_id);


--
-- Name: index_archived_petitions_on_signature_count; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petitions_on_signature_count ON archived_petitions USING btree (signature_count);


--
-- Name: index_archived_petitions_on_state_and_closed_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petitions_on_state_and_closed_at ON archived_petitions USING btree (state, closed_at);


--
-- Name: index_archived_petitions_on_title; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petitions_on_title ON archived_petitions USING gin (to_tsvector('english'::regconfig, (title)::text));


--
-- Name: index_archived_rejections_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_archived_rejections_on_petition_id ON archived_rejections USING btree (petition_id);


--
-- Name: index_archived_signatures_on_constituency_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_constituency_id ON archived_signatures USING btree (constituency_id);


--
-- Name: index_archived_signatures_on_creation_ip_and_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_creation_ip_and_petition_id ON archived_signatures USING btree (created_at, ip_address, petition_id);


--
-- Name: index_archived_signatures_on_creator_and_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_creator_and_petition_id ON archived_signatures USING btree (creator, petition_id);


--
-- Name: index_archived_signatures_on_email_and_petition_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_archived_signatures_on_email_and_petition_id_and_name ON archived_signatures USING btree (email, petition_id, name);


--
-- Name: index_archived_signatures_on_invalidation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_invalidation_id ON archived_signatures USING btree (invalidation_id);


--
-- Name: index_archived_signatures_on_ip_address_and_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_ip_address_and_petition_id ON archived_signatures USING btree (ip_address, petition_id);


--
-- Name: index_archived_signatures_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_petition_id ON archived_signatures USING btree (petition_id);


--
-- Name: index_archived_signatures_on_petition_id_and_location_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_petition_id_and_location_code ON archived_signatures USING btree (petition_id, location_code);


--
-- Name: index_archived_signatures_on_sponsor_and_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_sponsor_and_petition_id ON archived_signatures USING btree (sponsor, petition_id);


--
-- Name: index_archived_signatures_on_state_and_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_state_and_petition_id ON archived_signatures USING btree (state, petition_id);


--
-- Name: index_archived_signatures_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_updated_at ON archived_signatures USING btree (updated_at);


--
-- Name: index_archived_signatures_on_uuid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_uuid ON archived_signatures USING btree (uuid);


--
-- Name: index_archived_signatures_on_validated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_signatures_on_validated_at ON archived_signatures USING btree (validated_at);


--
-- Name: index_constituencies_on_external_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_constituencies_on_external_id ON constituencies USING btree (external_id);


--
-- Name: index_constituencies_on_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_constituencies_on_slug ON constituencies USING btree (slug);


--
-- Name: index_country_petition_journals_on_petition_and_location; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_country_petition_journals_on_petition_and_location ON country_petition_journals USING btree (petition_id, location_code);


--
-- Name: index_debate_outcomes_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_debate_outcomes_on_petition_id ON debate_outcomes USING btree (petition_id);


--
-- Name: index_debate_outcomes_on_petition_id_and_debated_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_debate_outcomes_on_petition_id_and_debated_on ON debate_outcomes USING btree (petition_id, debated_on);


--
-- Name: index_debate_outcomes_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_debate_outcomes_on_updated_at ON debate_outcomes USING btree (updated_at);


--
-- Name: index_delayed_jobs_on_priority_and_run_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_delayed_jobs_on_priority_and_run_at ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_email_requested_receipts_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_email_requested_receipts_on_petition_id ON email_requested_receipts USING btree (petition_id);


--
-- Name: index_government_responses_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_government_responses_on_petition_id ON government_responses USING btree (petition_id);


--
-- Name: index_government_responses_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_government_responses_on_updated_at ON government_responses USING btree (updated_at);


--
-- Name: index_invalidations_on_cancelled_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invalidations_on_cancelled_at ON invalidations USING btree (cancelled_at);


--
-- Name: index_invalidations_on_completed_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invalidations_on_completed_at ON invalidations USING btree (completed_at);


--
-- Name: index_invalidations_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invalidations_on_petition_id ON invalidations USING btree (petition_id);


--
-- Name: index_invalidations_on_started_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invalidations_on_started_at ON invalidations USING btree (started_at);


--
-- Name: index_locations_on_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_locations_on_code ON locations USING btree (code);


--
-- Name: index_locations_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_locations_on_name ON locations USING btree (name);


--
-- Name: index_locations_on_start_date_and_end_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_locations_on_start_date_and_end_date ON locations USING btree (start_date, end_date);


--
-- Name: index_notes_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_notes_on_petition_id ON notes USING btree (petition_id);


--
-- Name: index_petition_emails_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petition_emails_on_petition_id ON petition_emails USING btree (petition_id);


--
-- Name: index_petitions_on_action; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_action ON petitions USING gin (to_tsvector('english'::regconfig, (action)::text));


--
-- Name: index_petitions_on_additional_details; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_additional_details ON petitions USING gin (to_tsvector('english'::regconfig, additional_details));


--
-- Name: index_petitions_on_background; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_background ON petitions USING gin (to_tsvector('english'::regconfig, (background)::text));


--
-- Name: index_petitions_on_created_at_and_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_created_at_and_state ON petitions USING btree (created_at, state);


--
-- Name: index_petitions_on_creator_signature_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_petitions_on_creator_signature_id ON petitions USING btree (creator_signature_id);


--
-- Name: index_petitions_on_debate_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_debate_state ON petitions USING btree (debate_state);


--
-- Name: index_petitions_on_debate_threshold_reached_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_debate_threshold_reached_at ON petitions USING btree (debate_threshold_reached_at);


--
-- Name: index_petitions_on_last_signed_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_last_signed_at ON petitions USING btree (last_signed_at);


--
-- Name: index_petitions_on_response_threshold_reached_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_response_threshold_reached_at ON petitions USING btree (response_threshold_reached_at);


--
-- Name: index_petitions_on_signature_count_and_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_signature_count_and_state ON petitions USING btree (signature_count, state);


--
-- Name: index_rejections_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_rejections_on_petition_id ON rejections USING btree (petition_id);


--
-- Name: index_signatures_on_constituency_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_constituency_id ON signatures USING btree (constituency_id);


--
-- Name: index_signatures_on_created_at_and_ip_address_and_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_created_at_and_ip_address_and_petition_id ON signatures USING btree (created_at, ip_address, petition_id);


--
-- Name: index_signatures_on_domain; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_domain ON signatures USING btree ("substring"((email)::text, ("position"((email)::text, '@'::text) + 1)));


--
-- Name: index_signatures_on_email_and_petition_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_signatures_on_email_and_petition_id_and_name ON signatures USING btree (email, petition_id, name);


--
-- Name: index_signatures_on_invalidation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_invalidation_id ON signatures USING btree (invalidation_id);


--
-- Name: index_signatures_on_ip_address_and_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_ip_address_and_petition_id ON signatures USING btree (ip_address, petition_id);


--
-- Name: index_signatures_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_name ON signatures USING btree (lower((name)::text));


--
-- Name: index_signatures_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_petition_id ON signatures USING btree (petition_id);


--
-- Name: index_signatures_on_petition_id_and_location_code; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_petition_id_and_location_code ON signatures USING btree (petition_id, location_code);


--
-- Name: index_signatures_on_state_and_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_state_and_petition_id ON signatures USING btree (state, petition_id);


--
-- Name: index_signatures_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_updated_at ON signatures USING btree (updated_at);


--
-- Name: index_signatures_on_uuid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_uuid ON signatures USING btree (uuid);


--
-- Name: index_signatures_on_validated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_validated_at ON signatures USING btree (validated_at);


--
-- Name: index_tasks_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_tasks_on_name ON tasks USING btree (name);


--
-- Name: fk_rails_0af6bc4d41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY government_responses
    ADD CONSTRAINT fk_rails_0af6bc4d41 FOREIGN KEY (petition_id) REFERENCES petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_388e94fd73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_petition_emails
    ADD CONSTRAINT fk_rails_388e94fd73 FOREIGN KEY (petition_id) REFERENCES archived_petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_38c9c83a88; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sponsors
    ADD CONSTRAINT fk_rails_38c9c83a88 FOREIGN KEY (signature_id) REFERENCES signatures(id) ON DELETE CASCADE;


--
-- Name: fk_rails_39cbbc815d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_signatures
    ADD CONSTRAINT fk_rails_39cbbc815d FOREIGN KEY (petition_id) REFERENCES archived_petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_3e01179571; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY signatures
    ADD CONSTRAINT fk_rails_3e01179571 FOREIGN KEY (petition_id) REFERENCES petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_3e3a2f376e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notes
    ADD CONSTRAINT fk_rails_3e3a2f376e FOREIGN KEY (petition_id) REFERENCES petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_5186723bbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY constituency_petition_journals
    ADD CONSTRAINT fk_rails_5186723bbd FOREIGN KEY (petition_id) REFERENCES petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_5451a341b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY petitions
    ADD CONSTRAINT fk_rails_5451a341b3 FOREIGN KEY (creator_signature_id) REFERENCES signatures(id) ON DELETE RESTRICT;


--
-- Name: fk_rails_696590b5b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_government_responses
    ADD CONSTRAINT fk_rails_696590b5b6 FOREIGN KEY (petition_id) REFERENCES archived_petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_81c5c409a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_debate_outcomes
    ADD CONSTRAINT fk_rails_81c5c409a1 FOREIGN KEY (petition_id) REFERENCES archived_petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_82ffb00060; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rejections
    ADD CONSTRAINT fk_rails_82ffb00060 FOREIGN KEY (petition_id) REFERENCES petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_898597541e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_requested_receipts
    ADD CONSTRAINT fk_rails_898597541e FOREIGN KEY (petition_id) REFERENCES petitions(id);


--
-- Name: fk_rails_9621060128; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_notes
    ADD CONSTRAINT fk_rails_9621060128 FOREIGN KEY (petition_id) REFERENCES archived_petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_978050318c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_petitions
    ADD CONSTRAINT fk_rails_978050318c FOREIGN KEY (parliament_id) REFERENCES parliaments(id);


--
-- Name: fk_rails_9f55aacb99; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY petition_emails
    ADD CONSTRAINT fk_rails_9f55aacb99 FOREIGN KEY (petition_id) REFERENCES petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_b6266f73f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_rejections
    ADD CONSTRAINT fk_rails_b6266f73f1 FOREIGN KEY (petition_id) REFERENCES archived_petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_bc381510eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sponsors
    ADD CONSTRAINT fk_rails_bc381510eb FOREIGN KEY (petition_id) REFERENCES petitions(id) ON DELETE CASCADE;


--
-- Name: fk_rails_cb057e3dd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY debate_outcomes
    ADD CONSTRAINT fk_rails_cb057e3dd1 FOREIGN KEY (petition_id) REFERENCES petitions(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO "schema_migrations" (version) VALUES
('20150602200239'),
('20150603033108'),
('20150603112821'),
('20150605100049'),
('20150609111042'),
('20150610091149'),
('20150612095611'),
('20150612103324'),
('20150612111204'),
('20150615131623'),
('20150615145953'),
('20150615151103'),
('20150617114935'),
('20150617135014'),
('20150617164310'),
('20150618134919'),
('20150618143114'),
('20150618144922'),
('20150618233548'),
('20150618233718'),
('20150619075903'),
('20150619090833'),
('20150619133502'),
('20150619134335'),
('20150621200307'),
('20150622083615'),
('20150622140322'),
('20150630105949'),
('20150701111544'),
('20150701145201'),
('20150701145202'),
('20150701151007'),
('20150701151008'),
('20150701165424'),
('20150701165425'),
('20150701174136'),
('20150703100716'),
('20150703165930'),
('20150705114811'),
('20150707094523'),
('20150709152530'),
('20150714140659'),
('20150730110838'),
('20150805142206'),
('20150805142254'),
('20150806140552'),
('20150814111100'),
('20150820152623'),
('20150820153515'),
('20150820155740'),
('20150820161504'),
('20150913073343'),
('20150913074747'),
('20150924082835'),
('20150924082944'),
('20150924090755'),
('20150924091057'),
('20150928162418'),
('20151014152915'),
('20151014152929'),
('20160104144458'),
('20160210001632'),
('20160210174624'),
('20160210195916'),
('20160211002731'),
('20160211003703'),
('20160214133749'),
('20160214233414'),
('20160217192016'),
('20160527112417'),
('20160704152204'),
('20160704162920'),
('20160704185825'),
('20160706060256'),
('20160713124623'),
('20160713130452'),
('20160715092819'),
('20160716164929'),
('20160819062044'),
('20160819062058'),
('20160820132056'),
('20160820162023'),
('20160820165029'),
('20160822064645'),
('20160910054223'),
('20161006095752'),
('20161006101123'),
('20170419165419'),
('20170422104143'),
('20170424145119'),
('20170428185435'),
('20170428211336'),
('20170429023722'),
('20170501093620'),
('20170502155040'),
('20170503192115'),
('20170610132850'),
('20170611115913'),
('20170611123348'),
('20170611131130'),
('20170611190354'),
('20170612120307'),
('20170612144648'),
('20170613113510'),
('20170614165953'),
('20170615133536');


