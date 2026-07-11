SHELL := /bin/bash
COMPOSE := docker compose -f compose/compose.yaml

.PHONY: bootstrap validate deploy status logs update backup test stop

bootstrap:
	./scripts/bootstrap.sh

validate:
	./scripts/validate.sh

deploy: validate
	./scripts/deploy.sh

status:
	./scripts/status.sh

logs:
	$(COMPOSE) logs --tail=200 -f

update: validate
	./scripts/update.sh

backup:
	./scripts/backup.sh

test:
	./scripts/test-dns.sh
	./scripts/test-services.sh

stop:
	$(COMPOSE) down

