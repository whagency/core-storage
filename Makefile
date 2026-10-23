SHELL := /bin/bash

# Local development

up:
	docker compose up

down:
	docker compose down

up_rebuild:
	docker system prune
	docker builder prune
	docker compose up --build

restart: down up