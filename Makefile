include .env
export

export PROJECT_ROOT=$(shell pwd)

env-up:
	@docker compose up -d tasks-postgres

env-down:
	@docker compose down tasks-postgres

env-cleanup:
	@read -p "Are you sure you want to remove the database volume? This will delete all data. (y/n): " confirm && \
	if [ "$$confirm" = "y" ]; then \
		docker compose down tasks-postgres && \
		rm -rf out/pgdata && \
		echo "Database volume removed."; \
	else \
		echo "Operation cancelled."; \
	fi

env-port-forward:
	@docker compose up -d port-forwarder

env-port-close:
	@docker compose down port-forwarder

migrate-create:
	@if [ -z "$(seq)" ]; then \
		echo "Error: Please provide a sequence number using the seq variable. Exmaple: migrate-create seq=001"; \
		exit 1; \
	fi
	docker compose run --rm tasks-postgres-migrate \
		create \
		-ext sql \
		-dir /migrations \
		-seq "$(seq)"

migrate-up:
	@make migrate-action action=up

migrate-down:
	@make migrate-action action=down

migrate-action:
	@if [ -z "$(action)" ]; then \
		echo "Error: Please provide an action (up or down) using the action variable. Example: migrate-action action=up"; \
		exit 1; \
	fi
	docker compose run --rm tasks-postgres-migrate \
		-path /migrations \
		-database postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@tasks-postgres:5432/${POSTGRES_DB}?sslmode=disable \
		"$(action)"
