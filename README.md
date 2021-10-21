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

При переходе на страницу http://your-docker-host:9090/ откроется админка Prometheus. На вкладке Targets присутствует список endpoint'ов.
State должны быть в состоянии `UP`.
На главной странице можно искать метрики по имени или выбрать из списка.
Для мониторинга mongodb выбран `elarasu/mongodb_exporter`.
Для мониторинга mongodb выбран `prom/blackbox-exporter`.
Необходимые настройки сделаны в `prometheus.yml` и в `docker-compose.yml`.

## Упрощение сборки с помощью Makefile

Доступные задачи:

- build_prometheus
- build_post
- build_comment
- build_ui
- build_all
- push_prometheus
- push_post
- push_comment
- push_ui
- push_all

## Созданные образы

В работе созданы следующие образы:

- ostin654/prometheus
- ostin654/post
- ostin654/comment
- ostin654/ui

# Домашнее задание к уроку №25

## Сборка образов с поддержкой логирования

Обновить код приложения из ветки https://github.com/express42/reddit/tree/logging

Не забыть добавить тег `:logging` в скрипты сборки `docker_build.sh`.

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

Запушить образы в hub:

```shell
docker push $USER_NAME/ui:logging
docker push $USER_NAME/post:logging
docker push $USER_NAME/comment:logging
```

## Сборка образа fluentd

```shell
cd logging/fluentd
docker build -t $USER_NAME/fluentd .
```

## Запуск приложения

```shell
docker-compose -f docker-compose.yml up -d
```

## Запуск сборщика логов

```shell
docker-compose -f docker-compose-logging.yml up -d
```

## Просмотр логов и трейсинга

Kibana работает на порту 5601
Zipkin работает на порту 9411

## Траблшутинг UI-экспириенса

Контейнеры с баганным кодом собраны с тегом `bugged`.

Просмотр трейсов в zipkin показывает, что большую часть времени занимает ответ сервиса post.
Детальное изучение кода post показывает, что для имитации долгой работы в код был добавлена строка `time.sleep(3)`.


# Домашнее задание к уроку №27

## Создание кластера kubernetes

Потребуется 2 VM в yandex.cloud. В качестве ОС выбрана Ubuntu 20. На каждой выполнить:

```shell
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install docker-ce=5:19.03.15~3-0~ubuntu-focal docker-ce-cli=5:19.03.15~3-0~ubuntu-focal containerd.io kubelet=1.19.14-00 kubeadm=1.19.15-00 kubectl=1.19.15-00
```

На мастер-ноде выполнить команду создания кластера:

```shell
kubeadm init --apiserver-cert-extra-sans=<PUBLIC_IP> --apiserver-advertise-address=0.0.0.0 --control-plane-endpoint=<PUBLIC_IP> --pod-network-cidr=10.244.0.0/16
```

В результате выполнения мы получаем команду для добавления новых нод в кластер:

```shell
kubeadm join <MASTER_IP>:6443 --token <SOME_TOKEN> --discovery-token-ca-cert-hash <SOME_HASH>
```

Чтобы запускать `kubectl` без sudo, необходимо скопировать в домашнюю директорию конфиг:

```shell
mkdir ~/.kube/
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $USER ~/.kube/config
```

Также можно установить локально `kubectl` (например, отсюда https://www.downloadkubernetes.com) и скопировать конфиг с сервера в локальную домашнюю директорию.

## Установка кластера k8s с помощью terraform и ansible

В каталоге `kubernetes/terraform` расположены манифесты `terraform`.
В каталоге `kubernetes/ansible` расположены плейбуки `ansible`.

Для инициализации backend необходимо указать реквизиты при запуске `terraform init`.
Необходимый бакет должен быть создан.

```shell
terraform init -backend-config="access_key=YOUR_ACCESS_KEY" -backend-config="secret_key=YOUR_SECRET_KEY"
```

Поднимаем инфраструктуру:

```shell
terraform apply
```

В качестве ролей ansible выбраны:
- `geerlingguy.docker`
- `geerlingguy.kubernetes`

Полезные ссылки:
- Настройка параметров роли kubernetes https://github.com/geerlingguy/ansible-role-kubernetes/blob/master/defaults/main.yml
- Пример конфиг-файла с параметрами для kubeadm https://gist.github.com/nilesh93/c743205d34fedb5f48ae4d37d959ba4b

Установим зависимости:

```shell
ansible-galaxy install -r requirements.yml
```

Настраиваем мастер-ноду:

```shell
ansible-playbook playbooks/kubernetes.yml --limit kubernetes-0 -vv
```

На мастер-ноде можно получить команду для добавления нод в кластер:

```shell
kubeadm token create --print-join-command
```

Добавляем вторую ноду в кластер, при этом передаем команду добавления через `--extra-vars`:

```shell
ansible-playbook playbooks/kubernetes.yml --limit kubernetes-1 -vv --extra-vars '{"kubernetes_join_command":"<DROP_COMMAND_HERE>"}'
```

Устанавливаем локально `kubectl` (например, отсюда https://www.downloadkubernetes.com).
Далее копируем конфиг `kubectl` в домашнюю директорию с мастер-ноды `/etc/kubernetes/admin.conf` в `~/.kube/config`.

Пробуем посмотреть информацию о нодах:

```
% kubectl get nodes
NAME                   STATUS   ROLES    AGE     VERSION
fhmo5fnnl4v8m7iscu5r   Ready    <none>   2m52s   v1.19.15
fhmpgpivauls11v159c8   Ready    master   19m     v1.19.15
```

Если есть проблема с сертификатом, и надо добавить IP в разрешенные, можно воспользоваться инструкцией: https://blog.scottlowe.org/2019/07/30/adding-a-name-to-kubernetes-api-server-certificate/

## Запуск подов

```shell
cd kubernetes
kubectl apply -f reddit/post-deployment.yml
```

```
% kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
post-deployment-554b9bccf6-q76h4   1/1     Running   0          84s
```

# Домашнее задание к уроку №28

- Установка kubectl https://kubernetes.io/docs/tasks/tools/install-kubectl/
- Установка minikube https://kubernetes.io/docs/tasks/tools/install-minikube/

### Запуск кластера

```shell
minikube start --kubernetes-version 1.19.7
```

### Остановка кластера

```shell
minikube stop
```

### Проверка работы, просмотр нод

```shell
kubectl get nodes
```

### Переключение контекста вручную

```shell
kubectl config use-context context_name
```

### Запуск приложения

```shell
kubectl apply -f kubernetes/reddit/dev-namespace.yml
kubectl apply -f kubernetes/reddit -n dev
```

### Открытие приложения в браузере

```shell
minikube service ui -n dev
```

Откроется браузер со страницей приложения.

## Работа приложения в Yandex.cloud

Получение конфига кластера:

```shell
yc managed-kubernetes cluster get-credentials <cluster-name> --external
```

Приложение развернуто в кластере kubernetes в Яндекс.Облаке и доступно по ссылке http://62.84.119.119:32017/

# Домашнее задание к уроку №29

Посмотреть сервисы:

```shell
kubectl get services -n dev
```

```
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
comment      ClusterIP   10.96.241.68    <none>        9292/TCP         8h
comment-db   ClusterIP   10.96.182.49    <none>        27017/TCP        8h
mongodb      ClusterIP   10.96.214.127   <none>        27017/TCP        8h
post         ClusterIP   10.96.212.135   <none>        5000/TCP         8h
post-db      ClusterIP   10.96.235.55    <none>        27017/TCP        8h
ui           NodePort    10.96.250.121   <none>        9292:31421/TCP   8h
```

Отключение coredns и проверка доступности сервисов:

```shell
kubectl scale deployment --replicas 0 -n kube-system kube-dns-autoscaler
kubectl scale deployment --replicas 0 -n kube-system coredns
kubectl exec -ti -n dev ui-684f844f58-5z72s ping comment
```

```
ping: bad address 'comment'
command terminated with exit code 1
```

Для отката изменений:

```shell
kubectl scale deployment --replicas 1 -n kube-system kube-dns-autoscaler
```

Установка Ingress nginx controller:

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.34.1/deploy/static/provider/cloud/deploy.yaml
```

Применение правил ingress:

```shell
kubectl apply -f ui-ingress.yml -n dev
```

Просмотр созданного ingress:

```shell
kubectl get ingress -n dev
```

```
NAME   CLASS    HOSTS   ADDRESS         PORTS     AGE
ui     <none>   *       193.32.219.84   80, 443   14h
```

Генерация сертификатов:

```shell
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=193.32.219.84"
```

Добавление сертификатов в кластер:

```shell
kubectl create secret tls ui-ingress --key tls.key --cert tls.crt -n dev
```

Для работы сетевых политик в Я.облаке необходимо при создании кластера отметить чекбокс "Включить сетевые политики".
Примерение сетевых политик:

```shell
kubectl apply -f mongo-network-policy.yml -n dev
```

Создание диска в Я.облаке:

```shell
yc compute disk create --name k8s --size 4 --description "disk for k8s"
```

Применение правил для volume:

```shell
kubectl apply -f volume.yml -n dev
kubectl apply -f volume-claim.yml -n dev
kubectl apply -f mongodb-deployment.yml -n dev
```
