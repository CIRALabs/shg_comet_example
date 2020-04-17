#!/bin/sh

# this script starts a stock postgres 11 database in a container, naming it "staging_db"
echo CHANGE THE DATABASE PASSWORD; exit 1

docker run --mount source=staging_data,target=/var/lib/postgresql --name staging_db -e POSTGRES_PASSWORD=xyz1234 -p 5432:5432 -d postgres:11.2
