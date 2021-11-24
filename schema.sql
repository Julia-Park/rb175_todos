CREATE TABLE list (
  id serial PRIMARY KEY,
  name text UNIQUE NOT NULL
);

CREATE TABLE todo (
  id serial PRIMARY KEY,
  list_id integer NOT NULL REFERENCES list(id),
  name text NOT NULL,
  completed boolean NOT NULL DEFAULT false
);