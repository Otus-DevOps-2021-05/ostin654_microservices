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
