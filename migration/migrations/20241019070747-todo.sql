
-- +migrate Up
create table todos (
    id integer primary key autoincrement not null,
    content text not null,
    completed integer not null,
    created_at text not null default current_timestamp
) strict;

-- +migrate Down
drop table todos;
