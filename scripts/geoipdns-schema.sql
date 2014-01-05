--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: records; Type: TABLE; Schema: public; Owner: geoipdns; Tablespace: 
--

CREATE TABLE records (
    id integer NOT NULL,
    zid integer NOT NULL,
    loq integer DEFAULT 0 NOT NULL,
    loc character varying(255),
    mapname character varying(255),
    rrtype character varying(64) NOT NULL,
    name character varying(255),
    data text,
    aux text[],
    ttl character varying(32) DEFAULT '3600'::character varying,
    rid character(1)
);


ALTER TABLE public.records OWNER TO geoipdns;

--
-- Name: records_id_seq; Type: SEQUENCE; Schema: public; Owner: geoipdns
--

CREATE SEQUENCE records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.records_id_seq OWNER TO geoipdns;

--
-- Name: records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geoipdns
--

ALTER SEQUENCE records_id_seq OWNED BY records.id;


--
-- Name: servermap; Type: TABLE; Schema: public; Owner: geoipdns; Tablespace: 
--

CREATE TABLE servermap (
    id integer NOT NULL,
    uid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.servermap OWNER TO geoipdns;

--
-- Name: servermap_id_seq; Type: SEQUENCE; Schema: public; Owner: geoipdns
--

CREATE SEQUENCE servermap_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.servermap_id_seq OWNER TO geoipdns;

--
-- Name: servermap_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geoipdns
--

ALTER SEQUENCE servermap_id_seq OWNED BY servermap.id;


--
-- Name: servers; Type: TABLE; Schema: public; Owner: geoipdns; Tablespace: 
--

CREATE TABLE servers (
    id integer NOT NULL,
    isp character varying(255) NOT NULL,
    nickname character varying(255) NOT NULL,
    hostname character varying(255) NOT NULL,
    enabled integer DEFAULT 0 NOT NULL,
    ipv4addr inet NOT NULL,
    location text,
    active integer DEFAULT 0,
    tld character(16),
    ssh_port integer DEFAULT 22 NOT NULL,
    ssh_key_file character(512) DEFAULT '/sysami/.ssh/id_rsa'::bpchar NOT NULL
);


ALTER TABLE public.servers OWNER TO geoipdns;

--
-- Name: servers_id_seq; Type: SEQUENCE; Schema: public; Owner: geoipdns
--

CREATE SEQUENCE servers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.servers_id_seq OWNER TO geoipdns;

--
-- Name: servers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geoipdns
--

ALTER SEQUENCE servers_id_seq OWNED BY servers.id;


--
-- Name: services; Type: TABLE; Schema: public; Owner: geoipdns; Tablespace: 
--

CREATE TABLE services (
    id integer NOT NULL,
    service_type character varying(64) NOT NULL,
    server_id integer NOT NULL,
    service_group character(16) DEFAULT 'STANDALONE'::bpchar NOT NULL,
    service_collection character(64)
);


ALTER TABLE public.services OWNER TO geoipdns;

--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: geoipdns
--

CREATE SEQUENCE services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.services_id_seq OWNER TO geoipdns;

--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geoipdns
--

ALTER SEQUENCE services_id_seq OWNED BY services.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: geoipdns; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    username character varying(128) NOT NULL,
    password character varying(256) NOT NULL,
    active integer DEFAULT 1 NOT NULL,
    realm character varying(32) DEFAULT 'geoipdns'::character varying,
    cleartextpass character varying(64),
    ip inet,
    ctime integer,
    key character(64),
    dbname character varying(64)
);


ALTER TABLE public.users OWNER TO geoipdns;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: geoipdns
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO geoipdns;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geoipdns
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: zones; Type: TABLE; Schema: public; Owner: geoipdns; Tablespace: 
--

CREATE TABLE zones (
    id integer NOT NULL,
    origin character varying(255),
    uid integer NOT NULL,
    utime integer DEFAULT 0 NOT NULL,
    lastupdate integer
);


ALTER TABLE public.zones OWNER TO geoipdns;

--
-- Name: zones_id_seq; Type: SEQUENCE; Schema: public; Owner: geoipdns
--

CREATE SEQUENCE zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.zones_id_seq OWNER TO geoipdns;

--
-- Name: zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geoipdns
--

ALTER SEQUENCE zones_id_seq OWNED BY zones.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY records ALTER COLUMN id SET DEFAULT nextval('records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY servermap ALTER COLUMN id SET DEFAULT nextval('servermap_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY servers ALTER COLUMN id SET DEFAULT nextval('servers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY services ALTER COLUMN id SET DEFAULT nextval('services_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY zones ALTER COLUMN id SET DEFAULT nextval('zones_id_seq'::regclass);


--
-- Name: records_pkey; Type: CONSTRAINT; Schema: public; Owner: geoipdns; Tablespace: 
--

ALTER TABLE ONLY records
    ADD CONSTRAINT records_pkey PRIMARY KEY (id);


--
-- Name: servermap_pkey; Type: CONSTRAINT; Schema: public; Owner: geoipdns; Tablespace: 
--

ALTER TABLE ONLY servermap
    ADD CONSTRAINT servermap_pkey PRIMARY KEY (id);


--
-- Name: servers_pkey; Type: CONSTRAINT; Schema: public; Owner: geoipdns; Tablespace: 
--

ALTER TABLE ONLY servers
    ADD CONSTRAINT servers_pkey PRIMARY KEY (id);


--
-- Name: services_pkey; Type: CONSTRAINT; Schema: public; Owner: geoipdns; Tablespace: 
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: users_password_key; Type: CONSTRAINT; Schema: public; Owner: geoipdns; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_password_key UNIQUE (password);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: geoipdns; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_username_key; Type: CONSTRAINT; Schema: public; Owner: geoipdns; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: zones_pkey; Type: CONSTRAINT; Schema: public; Owner: geoipdns; Tablespace: 
--

ALTER TABLE ONLY zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: records_zid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY records
    ADD CONSTRAINT records_zid_fkey FOREIGN KEY (zid) REFERENCES zones(id);


--
-- Name: servermap_sid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY servermap
    ADD CONSTRAINT servermap_sid_fkey FOREIGN KEY (sid) REFERENCES servers(id);


--
-- Name: servermap_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY servermap
    ADD CONSTRAINT servermap_uid_fkey FOREIGN KEY (uid) REFERENCES users(id);


--
-- Name: services_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_server_id_fkey FOREIGN KEY (server_id) REFERENCES servers(id);


--
-- Name: zones_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: geoipdns
--

ALTER TABLE ONLY zones
    ADD CONSTRAINT zones_uid_fkey FOREIGN KEY (uid) REFERENCES users(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: users; Type: ACL; Schema: public; Owner: geoipdns
--

REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE users FROM geoipdns;
GRANT ALL ON TABLE users TO geoipdns;


--
-- PostgreSQL database dump complete
--

