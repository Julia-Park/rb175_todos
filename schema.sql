CREATE TABLE lists (
  id serial PRIMARY KEY,
  name text UNIQUE NOT NULL
);

CREATE TABLE todos (
  id serial PRIMARY KEY,
  lists_id integer NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
  name text NOT NULL,
  completed boolean NOT NULL DEFAULT false
);