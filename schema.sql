--
-- PostgreSQL database dump
--

\restrict 8kFh5hQDwmFNh8Ym5LVegD6aWa5D5TYbySTMXcWiphlNKb628N5ImIgsZ3qnKdy

-- Dumped from database version 18.1 (Debian 18.1-1.pgdg13+2)
-- Dumped by pg_dump version 18.1 (Debian 18.1-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: books; Type: TABLE; Schema: public; Owner: main
--

CREATE TABLE public.books (
    title text NOT NULL,
    chapter real NOT NULL,
    image_link text,
    id integer NOT NULL,
    last_modified bigint NOT NULL,
    kind text NOT NULL,
    on_hiatus boolean NOT NULL,
    is_finished boolean NOT NULL
);


ALTER TABLE public.books OWNER TO main;

--
-- Name: books_id_seq; Type: SEQUENCE; Schema: public; Owner: main
--

CREATE SEQUENCE public.books_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.books_id_seq OWNER TO main;

--
-- Name: books_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: main
--

ALTER SEQUENCE public.books_id_seq OWNED BY public.books.id;


--
-- Name: books id; Type: DEFAULT; Schema: public; Owner: main
--

ALTER TABLE ONLY public.books ALTER COLUMN id SET DEFAULT nextval('public.books_id_seq'::regclass);


--
-- Data for Name: books; Type: TABLE DATA; Schema: public; Owner: main
--

COPY public.books (title, chapter, image_link, id, last_modified, kind, on_hiatus, is_finished) FROM stdin;
\.


--
-- Name: books_id_seq; Type: SEQUENCE SET; Schema: public; Owner: main
--

SELECT pg_catalog.setval('public.books_id_seq', 1, true);


--
-- PostgreSQL database dump complete
--

\unrestrict 8kFh5hQDwmFNh8Ym5LVegD6aWa5D5TYbySTMXcWiphlNKb628N5ImIgsZ3qnKdy

