create table if not exists users (
    id uuid primary key default pg_catalog.gen_random_uuid(),
    username varchar(32) not null,
    initials     text not null,
    email varchar(128) not null,
    password text not null,
    org text not null,
    admin_access bool not null default false,
    joinedAt timestamptz
);

create unique index if not exists users_idx on users (id);
create unique index if not exists user_username_uq on users (username);

create type device_type as enum ('web', 'client');

create table if not exists sessions (
    id uuid primary key default pg_catalog.gen_random_uuid(),
    owner uuid not null references users (id),
    device device_type not null default 'client',
    createdAt timestamptz not null default now(),
    expiresAt  timestamptz not null default (now() + interval '30 hours'),
    lastSeenAt timestamptz not null default now()
);

create unique index if not exists sessions_idx on sessions (id);
drop index if exists sessions_owner_idx;
create index if not exists sessions_owner_idx on sessions (owner);

create table if not exists seance
(
    id      uuid primary key     default pg_catalog.gen_random_uuid(),
    owner   uuid        not null references users (id),
    errors  int         not null default 0,
    actions jsonb       not null,
    at      timestamptz not null,
    done    timestamptz not null
);

create unique index if not exists seance_idx on seance (id);
create index if not exists seance_owner_idx on seance (owner);
