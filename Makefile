.DEFAULT_GOAL := help
.PHONY: help

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1\3/p' \
	| column -t  -s ' '

build_prometheus: ## Build Prometheus image
	docker build -t $(USER_NAME)/prometheus monitoring/prometheus

build_post: ## Build post image
	echo `git show --format="%h" HEAD | head -1` > src/post-py/build_info.txt
	echo `git rev-parse --abbrev-ref HEAD` >> src/post-py/build_info.txt
	docker build -t $(USER_NAME)/post src/post-py

build_comment: ## Build comment image
	echo `git show --format="%h" HEAD | head -1` > src/comment/build_info.txt
	echo `git rev-parse --abbrev-ref HEAD` >> src/comment/build_info.txt
	docker build -t $(USER_NAME)/comment src/comment

build_ui: ## Build ui image
	echo `git show --format="%h" HEAD | head -1` > src/ui/build_info.txt
	echo `git rev-parse --abbrev-ref HEAD` >> src/ui/build_info.txt
	docker build -t $(USER_NAME)/ui src/ui

build_all: build_ui build_comment build_post build_prometheus ## Build all


push_prometheus: ## Push Prometheus image
	docker push $(USER_NAME)/prometheus

push_post: ## Push post image
	docker push $(USER_NAME)/post

push_comment: ## Push comment image
	docker push $(USER_NAME)/comment

push_ui: ## Push ui image
	docker push $(USER_NAME)/ui

push_all: push_prometheus push_post push_comment push_ui ## Push all
