# Домашнее задание к уроку №16

Подготовлен Dockerfile для сборки docker-образа приложения.

## Сборка docker-образа приложения

В директории `dockermonolith` выполнить

```shell
docker build -t reddit:latest .
docker tag reddit:latest ostin654/otus-reddit:1.0
```

Готовый образ был загружен в docker hub.

## Запуск контейнера из готового образа

```shell
docker run --name reddit -d -p 9292:9292 ostin654/otus-reddit:1.0
```

Приложение будет доступно по ссылке http://127.0.0.1:9292/

## Сборка образа с docker для yandex cloud

В директории `dockermonolith/infra` выполнить:

```shell
packer build --var-file=packer/variables.json packer/docker.json
```

## Создание инфраструктуры

В файле `dockermonolith/infra/terraform/terraform.tfvars` указать необходимые значения.

В директории `dockermonolith/infra/terraform` выполнить:

```shell
terraform apply
```

## Запуск контейнеров

В директории `dockermonolith/infra/ansible` выполнить:

```shell
ansible-playbook playbooks/docker_container.yml
```

# Домашнее задание к уроку №17

- Приложение разбито на микросервисы
- Под каждый микросервис создан docker-образ
- Создан общий bridge `reddit`
- Образы оптимизированы по размеру
- Выделен том для данных БД
- Возможно задавать сетевые алиасы микросервисов через переменные окружения

## Сборка

```shell
docker build -t ostin654/comment:2.0-alpine ./comment
docker build -t ostin654/ui:2.0-alpine ./ui
docker build -t ostin654/post:1.0 ./post-py
```

## Запуск микросервисов

Создать сети и том

```shell
docker network create reddit
docker volume create reddit_db
```

Запустить контейнеры

```shell
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post ostin654/post:1.0
docker run -d --network=reddit --network-alias=comment ostin654/comment:2.0-alpine
docker run -d --network=reddit -p 9292:9292 ostin654/ui:2.0-alpine
```

## Запуск с изменением сетевых алиасов

```shell
docker run -d --network=reddit --network-alias=post_db1 --network-alias=comment_db1 -v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post1 -e POST_DATABASE_HOST='post_db1' ostin654/post:1.0
docker run -d --network=reddit --network-alias=comment1 -e COMMENT_DATABASE_HOST='comment_db1' ostin654/comment:2.0-alpine
docker run -d --network=reddit -e POST_SERVICE_HOST='post1' -e COMMENT_SERVICE_HOST='comment1' -p 9292:9292 ostin654/ui:2.0-alpine
```
