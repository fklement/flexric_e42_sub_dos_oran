DOS_PREV_ENABL ?= 0
.PHONY: baseline dos

baseline: 
	docker compose build --build-arg DOS_PREV_ENABL=$(DOS_PREV_ENABL)
	START_MODE="-b" docker compose up

dos:  
	docker compose build --build-arg DOS_PREV_ENABL=$(DOS_PREV_ENABL)
	START_MODE="-d" docker compose up

