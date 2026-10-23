# Storage Service

## Purpose

`storage-service` is the app platform data and transport infrastructure
repository.

It is not a backend business service. It is the platform stack repository for
stateful infrastructure such as:

- PostgreSQL
- RabbitMQ
- Hazelcast
- MongoDB

It also contains production-oriented images and deployment logic for:

- CoreDNS
- OpenVPN Access Server

## Repository role

This repository currently serves two related roles:

1. local stack bootstrap through `docker-compose.yml`
2. production-oriented image build and remote deploy workflow through
   `.github/workflows/main.yml`

Because of that, some files describe local development and some describe
production runtime.

## Repository structure

```text
.env.example                            local environment template
.github/workflows/main.yml              CI/CD build and remote deploy workflow
Makefile                                local compose helpers
docker-compose.yml                      local infrastructure stack
docker/production/db/                   production PostgreSQL image and config
docker/production/dns/                  production CoreDNS image and host map
docker/production/hazelcast/            production Hazelcast image
docker/production/mongo/                production MongoDB image
docker/production/openvpn/              production OpenVPN image
docker/production/rabbitmq/             production RabbitMQ image
```

## Local development

Typical local bootstrap:

```bash
cp .env.example .env
make up
```

Available Make targets:

- `make up`
- `make down`
- `make restart`
- `make up_rebuild`

Important note:

- `up_rebuild` currently runs `docker system prune` and `docker builder prune`
  before `docker compose up --build`, so it is intentionally heavy and should be
  used carefully

### Local compose stack

The checked-in `docker-compose.yml` currently starts:

- `rabbitmq`
- `hazelcast`
- `postgres`
- `mongo`

Current container names:

- `fin_rabbitmq`
- `fin_hazelcast`
- `fin_postgres`
- `fin_mongo`

Current local port mappings come from `.env`.

## Local stack behavior

### PostgreSQL

Local PostgreSQL behavior:

- uses the official `postgres:17` image directly
- runs the multi-database init script
- stores data in the named volume `fin_postgres_data`
- starts with inline overrides for `max_connections=2000` and
  `shared_buffers=1GB`

The init script creates all databases listed in `POSTGRES_MULTIPLE_DATABASES`
on first initialization.

### RabbitMQ

Local RabbitMQ behavior:

- builds the custom image from `docker/production/rabbitmq/Dockerfile` (same
  artifact as production), based on `rabbitmq:4.1.8-management`
- bundles the `rabbitmq_delayed_message_exchange` community plugin, required by
  the platform queue retry pipeline (per-message `x-delay` exchange)
- exposes both AMQP and management ports
- stores data in `fin_rabbitmq_data`

The plugin version is pinned in the Dockerfile via `DELAYED_PLUGIN_VERSION` and
verified by `DELAYED_PLUGIN_SHA256`. Bump both together when upgrading.

To verify the plugin is enabled in a running container:

```bash
docker exec fin_rabbitmq rabbitmq-plugins list -e | grep delayed
# expected: [E*] rabbitmq_delayed_message_exchange ...
```

### Hazelcast

Local Hazelcast behavior:

- uses `hazelcast/hazelcast:5.5`
- exposes port `5701`
- reads cluster name and join flags from `.env`

### MongoDB

Local MongoDB behavior:

- uses `mongo:7.0.25`
- exposes `27017`
- initializes root credentials from `.env`

## Production deployment model

Production deployment source of truth is:

- `.github/workflows/main.yml`

Current production flow on push to `main`:

1. build Docker images for OpenVPN, DNS, PostgreSQL, RabbitMQ, Hazelcast, and
   MongoDB
2. export them into tar archives
3. copy them to the target server
4. recreate remote containers with explicit `docker run` commands

The workflow creates or reuses `fin_network` and assigns fixed IPs, including:

- `fin_openvpn` -> `172.28.0.2`
- `fin_dns` -> `172.28.0.3`
- `fin_postgres` -> `172.28.0.10`
- `fin_rabbitmq` -> `172.28.0.11`
- `fin_hazelcast` -> `172.28.0.12`
- `fin_mongo` -> `172.28.0.13`

## DNS and network conventions

Production DNS host mappings are defined in:

- `docker/production/dns/Corefile`

Current host entries include:

- `db.local`
- `rabbitmq.local`
- `hazelcast.local`
- `mongo.local`
- `jaeger.local`
- `kibana.local`
- `grafana.local`
- `admin-panel.vpn.local`

This means the repository is coupled to production IP assignments in both the
data stack and the observability stack.

## Important local vs production differences

The local stack and production stack are not identical.

Local `docker-compose.yml` currently includes:

- PostgreSQL
- RabbitMQ
- Hazelcast
- MongoDB

Production workflow additionally deploys:

- OpenVPN
- CoreDNS

Also:

- local PostgreSQL uses the official `postgres:17` image
- production PostgreSQL uses the custom image from `docker/production/db`
- local compose does not use the production CoreDNS configuration
- local compose does not use the production OpenVPN image

## Configuration caveats

`.env.example` is useful, but it is not a perfect reflection of the full
current app platform state.

Notable caveats:

- `POSTGRES_MULTIPLE_DATABASES` currently defaults to `user,wallet`, which is
  likely incomplete for the current backend workspace
- `.env.example` contains `JAEGER_*` variables, but the current local
  `docker-compose.yml` does not start Jaeger

Treat `.env.example` as a starting point, not as an exhaustive platform
contract.

## Relationship to root `infra/`

This repository is the reusable platform stack source for core stateful
infrastructure.

Root `infra/` in the app workspace should be used for workspace-local
assembly and scenario-specific developer orchestration.

In other words:

- `repos/platform/storage-service` is the reusable stack repo
- root `infra/` is where local app dev compositions and overrides should
  usually live

## Current repository caveats

- local and production stack definitions currently drift from each other
- `.env.example` likely does not cover the full current set of backend databases
- `up_rebuild` is destructive enough to require extra care
