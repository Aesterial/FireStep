-- name: CreateUser :one
insert into users (username, email, password, org, initials)
values ($1, $2, $3, $4, $5)
returning id, username, initials, email, org, admin_access, joinedat;

-- name: GetUser :one
select username, email, org, initials, admin_access, joinedat
from users
where id = $1;

-- name: GetUserByUsername :one
select id, username, email, org, initials, admin_access, joinedat
from users
where username = $1
limit 1;

-- name: IsUserExists :one
select exists (select 1 from users where id = $1);

-- name: IsUserAdmin :one
select admin_access
from users
where id = $1
limit 1;

-- name: IsUsernameOrEmailExists :one
select exists (select 1 from users where username = $1 OR email = $2);

-- name: GetPasswordByUsername :one
select password
from users
where username = $1
limit 1;

-- name: GetUsersByOrg :many
select id, email, username, initials, admin_access, joinedat
from users
where org = $1;

-- name: GetUsersCountByOrg :one
select count(*)
from users
where org = $1;

-- name: GetUserSeances :many
select id, owner, errors, actions, at, done
from seance
where owner = $1;

-- name: CreateUserSeance :one
insert into seance (owner, actions, at, done, errors)
values ($1, $2, $3, $4, $5)
returning id, owner, errors, actions, at, done;

-- name: GetSeanceStatsByOrg :one
SELECT COUNT(s.id)                              AS total_seances,
       COALESCE(SUM(s.errors), 0)               AS total_errors,
       AVG(s.done - s.at)                       AS avg_execution_time,
       AVG(EXTRACT(EPOCH FROM (s.done - s.at))) AS avg_execution_time_seconds
FROM seance s
         JOIN users u ON u.id = s.owner
WHERE u.org = $1;

-- name: CreateSession :one
insert into sessions (owner, device)
values ($1, $2)
returning id, owner, device, createdat, expiresat, lastSeenAt;

-- name: SessionList :many
select id, owner, device, createdat, expiresat, lastSeenAt
from sessions
where owner = $1;

-- name: GetSession :one
select id, owner, device, createdat, expiresat, lastseenat
from sessions
where id = $1;

-- name: IsSessionExists :one
select exists (select 1 from sessions where id = $1);

-- name: RevokeSession :exec
update sessions
set expiresat = now()
where id = $1;

-- name: SessionOwner :one
select owner
from sessions
where id = $1
limit 1;

-- name: SetSessionLastSeen :exec
update sessions
set lastseenat = $1
where id = $2;
