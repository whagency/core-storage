FROM postgres:17

COPY ./docker/production/db/multiple-databases.sh /docker-entrypoint-initdb.d/
COPY ./docker/production/db/postgresql.conf /etc/postgresql/

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]