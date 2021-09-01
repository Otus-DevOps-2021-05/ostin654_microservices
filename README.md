# Домашнее задание к уроку №16

## Docker machine

```shell
yc compute instance create \
--name docker-host \
--zone ru-central1-a \
--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2004-lts,size=15 \
--ssh-key ~/.ssh/id_rsa.pub
```

```shell
docker-machine create \
--driver generic \
--generic-ip-address=PUBLIC_IP \
--generic-ssh-user yc-user \
--generic-ssh-key ~/.ssh/id_rsa \
docker-host
```

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

# Домашнее задание к уроку №18

Перейти в каталог `src`.

В каталог `src` необходимо добавить файл `.env`. Содержимое можно взять из примера `.env.example`.

Переменная `COMPOSE_PROJECT_NAME` задает уникальное имя проекта, которое используется при именовании контейнеров.
Если ее не указывать, то за имя проекта берется имя текущей директории.

## Запуск сервисов

```shell
docker-compose up
```

### Запуск в фоне

```shell
docker-compose up -d
```

## Запуск в режиме отладки

Позволяет менять код приложения без сборки образов и запускает puma в режиме debug в 2 потока.

```shell
docker-compose -f docker-compose.override.yml up
```

# Домашнее задание к уроку №20

## Ручное создание VM с Docker для Gitlab

Создание VM в yandex cloud

```shell
yc compute instance create --name gitlab-ci \
--zone ru-central1-a --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=60 \
--memory=8 --cores=2 --core-fraction=100 --ssh-key ~/.ssh/id_rsa.pub
```

Установка docker с помощью docker-machine

```shell
docker-machine create \
--driver generic \
--generic-ip-address=PUBLIC_IP \
--generic-ssh-user yc-user \
--generic-ssh-key ~/.ssh/id_rsa \
gitlab-ci
```

## Создание VM с помощью terraform и ansible

В файле `dockermonolith/infra/terraform/gitlab.tfvars` указать необходимые значения.

В директории `docker-monolith/infra/terraform` выполнить:

```shell
terraform apply
```

### Запуск контейнера c self-managed gitlab

В директории `dockermonolith/infra/ansible` выполнить:

```shell
ansible-playbook playbooks/docker_gitlab.yml
```

Если зайти на сервер по ssh, то можно наблюдать за развертыванием контейнера:

```shell
docker logs gitlab -f
```

## Установка пароля для root

После запуска и настройки контейнера gitlab необходимо поменять пароль root.
Для этого заходим в контейнер с gitlab и запускаем консоль ruby.

```shell
docker exec -it gitlab bash
gitlab-rails console -e production
```

После загрузки консоли можно поменять пароль следующими командами:

```
user = User.where(id: 1).first
user.password = 'secret_pass'
user.password_confirmation = 'secret_pass'
user.save!
```

## Создание проекта

Сначала нужно создать группу: `Menu -> Groups -> Create group`
Далее создается проект: `Menu -> Projects -> Create new project`

### Добавление remote в репозиторий

Посмотреть ссылку для клонирования репозитория можно, нажав в правом меню на `Repository` и далее `Clone`.
Добавим новый remote к нашему репозиторию и запушим изменения в gitlab:

```shell
git checkout -b gitlab-ci-1
git remote add gitlab <YOUR_GITLAB_REPO_URL>
git push gitlab gitlab-ci-1
```

Посмотреть список существующих remote:

```shell
git remote -v
```

## Запуск и регистрация gitlab-runner

### Запуск контейнера с gitlab-runner

Запуск контейнера с gitlab-runner уже предусмотрен в playbook `dockermonolith/infra/ansible/playbooks/docker_gitlab.yml`.

Чтобы вручную запустить контейнер с gitlab-runner:

```shell
docker run -d --name gitlab-runner --restart always \
-v /srv/gitlab- runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest
```

### Регистрация gitlab-runner

```shell
docker exec -it gitlab-runner gitlab-runner register \
--url http://<your-ip>/ \
--registration-token <your-token> \
--non-interactive \
--locked=false \
--name DockerRunner \
--executor docker \
--docker-image alpine:latest \
--docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
--tag-list "linux,xenial,ubuntu,docker" \
--run-untagged
```

`your-ip` и `your-token` можно посмотреть в админке gitlab в `Settings -> CI/CD -> Runners`.

`--docker-volumes` необходимо, чтобы в дальнейшем можно runner мог собирать docker-образы.

## Сборка образа на стадии build

Для стадии `build` определена задача `build_container`.
Для корректной работы выбран образ `docker:latest` (чтобы была доступна команда `docker build`) и изменена настройка `before_script`.

## Настройка оповещений в slack

Настройка произведена в `Settings -> Integrations -> Slack notifications`.
Настроены оповещения в канал #aleksey_kostin (https://devops-team-otus.slack.com/archives/C0254LBG291)

# Домашнее задание к уроку №22

## Сборка необходимых образов

```shell
export USER_NAME=yourname
```

В каталоге `monitoring/prometheus`:

```shell
docker build -t $USER_NAME/prometheus .
```

В каталоге `src/comment`:

```shell
bash docker_build.sh
```

В каталоге `src/post`:

```shell
bash docker_build.sh
```

В каталоге `src/ui`:

```shell
bash docker_build.sh
```

В файле `docker/.env` проверить теги сервисов `post`, `comment`, `ui` - должны быть `latest`.

## Запуск контейнеров

В каталоге `docker`:

```shell
docker-compose -f docker-compose.yml up -d
```

## Остановка контейнеров

```shell
docker-compose down
```

## Проверка мониторинга
