--
-- PostgreSQL database dump
--

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
    updated_at timestamp without time zone
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
-- Name: archived_petitions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_petitions (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    response text,
    state character varying(10) DEFAULT 'open'::character varying NOT NULL,
    reason_for_rejection text,
    opened_at timestamp without time zone,
    closed_at timestamp without time zone,
    signature_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: debate_outcomes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE debate_outcomes (
    id integer NOT NULL,
    petition_id integer NOT NULL,
    debated_on date NOT NULL,
    transcript_url character varying(500),
    video_url character varying(500),
    overview text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: petitions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE petitions (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    additional_details text,
    response text,
    state character varying(10) DEFAULT 'pending'::character varying NOT NULL,
    open_at timestamp without time zone,
    creator_signature_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    rejection_text text,
    closed_at timestamp without time zone,
    signature_count integer DEFAULT 0,
    response_required boolean DEFAULT false,
    internal_response text,
    rejection_code character varying(50),
    notified_by_email boolean DEFAULT false,
    email_requested_at timestamp without time zone,
    background character varying(200),
    sponsor_token character varying(255),
    response_summary character varying(500),
    government_response_at timestamp without time zone,
    scheduled_debate_date date
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
    state character varying(10) DEFAULT 'pending'::character varying NOT NULL,
    perishable_token character varying(255),
    postcode character varying(255),
    country character varying(255),
    ip_address character varying(20),
    petition_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notify_by_email boolean DEFAULT true,
    last_emailed_at timestamp without time zone,
    email character varying(255),
    unsubscribe_token character varying,
    constituency_id character varying
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
    email_from character varying(50) DEFAULT 'no-reply@petition.parliament.uk'::character varying NOT NULL,
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
    feedback_email character varying(100) DEFAULT 'feedback@petition.parliament.uk'::character varying NOT NULL
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
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY admin_users ALTER COLUMN id SET DEFAULT nextval('admin_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archived_petitions ALTER COLUMN id SET DEFAULT nextval('archived_petitions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY constituency_petition_journals ALTER COLUMN id SET DEFAULT nextval('constituency_petition_journals_id_seq'::regclass);


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

ALTER TABLE ONLY petitions ALTER COLUMN id SET DEFAULT nextval('petitions_id_seq'::regclass);


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
-- Name: admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: archived_petitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_petitions
    ADD CONSTRAINT archived_petitions_pkey PRIMARY KEY (id);


--
-- Name: constituency_petition_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY constituency_petition_journals
    ADD CONSTRAINT constituency_petition_journals_pkey PRIMARY KEY (id);


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
-- Name: petitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY petitions
    ADD CONSTRAINT petitions_pkey PRIMARY KEY (id);


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
-- Name: index_archived_petitions_on_description; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_archived_petitions_on_description ON archived_petitions USING gin (to_tsvector('english'::regconfig, description));


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
-- Name: index_debate_outcomes_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_debate_outcomes_on_petition_id ON debate_outcomes USING btree (petition_id);


--
-- Name: index_debate_outcomes_on_petition_id_and_debated_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_debate_outcomes_on_petition_id_and_debated_on ON debate_outcomes USING btree (petition_id, debated_on);


--
-- Name: index_delayed_jobs_on_priority_and_run_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_delayed_jobs_on_priority_and_run_at ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_petitions_on_additional_details; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_additional_details ON petitions USING gin (to_tsvector('english'::regconfig, additional_details));


--
-- Name: index_petitions_on_background; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_background ON petitions USING gin (to_tsvector('english'::regconfig, (background)::text));


--
-- Name: index_petitions_on_creator_signature_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_petitions_on_creator_signature_id ON petitions USING btree (creator_signature_id);


--
-- Name: index_petitions_on_response_required_and_signature_count; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_response_required_and_signature_count ON petitions USING btree (response_required, signature_count);


--
-- Name: index_petitions_on_state_and_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_state_and_created_at ON petitions USING btree (state, created_at);


--
-- Name: index_petitions_on_state_and_signature_count; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_state_and_signature_count ON petitions USING btree (state, signature_count);


--
-- Name: index_petitions_on_title; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_petitions_on_title ON petitions USING gin (to_tsvector('english'::regconfig, (title)::text));


--
-- Name: index_signatures_on_email_and_petition_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_signatures_on_email_and_petition_id_and_name ON signatures USING btree (email, petition_id, name);


--
-- Name: index_signatures_on_petition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_petition_id ON signatures USING btree (petition_id);


--
-- Name: index_signatures_on_petition_id_and_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_petition_id_and_state ON signatures USING btree (petition_id, state);


--
-- Name: index_signatures_on_petition_id_and_state_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_petition_id_and_state_and_name ON signatures USING btree (petition_id, state, name);


--
-- Name: index_signatures_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_state ON signatures USING btree (state);


--
-- Name: index_signatures_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_signatures_on_updated_at ON signatures USING btree (updated_at);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

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

INSERT INTO schema_migrations (version) VALUES ('20150617164310');

INSERT INTO schema_migrations (version) VALUES ('20150618134919');

INSERT INTO schema_migrations (version) VALUES ('20150618143114');

INSERT INTO schema_migrations (version) VALUES ('20150619090833');

