create table if not exists users (
    id uuid primary key default pg_catalog.gen_random_uuid(),
    username varchar(32) not null,
    email varchar(128) not null,
    password text not null,
    org text not null,
    joinedAt timestamptz
);

create unique index users_idx on users (id);
create unique index user_username_uq on users (username);

create type device_type as enum ('web', 'client');

create table if not exists sessions (
    id uuid primary key default pg_catalog.gen_random_uuid(),
    owner uuid not null references users (id),
    device device_type not null default 'client',
    createdAt timestamptz not null default now(),
    expiresAt timestamptz not null default now() + 'interval 30 h'
);

create unique index sessions_idx on sessions (id);
create unique index sessions_owner_idx on sessions (owner);

