#!/bin/bash
# set -e  # エラー時にスクリプトを停止（必要に応じて有効化）

# 1. システム更新と言語環境設定（必要なら）
apt update && apt upgrade -y

# 2. 必要パッケージのインストール（Docker, Docker Composeプラグイン, PostgreSQL, Git）
apt install -y docker.io docker-compose-plugin postgresql git

# 3. PostgreSQLユーザー・データベースの作成
sudo -u postgres psql -c "CREATE USER dify WITH PASSWORD 'dify-password';"
sudo -u postgres psql -c "CREATE DATABASE dify OWNER dify;"

# 4. PostgreSQL設定変更: 接続アドレスと認証方式の調整
# - postgresql.conf の listen_addresses を有効化し '*' に設定
sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
# - pg_hba.conf のローカル接続を md5 認証に変更
sed -i "s/^\(local\s\+all\s\+all\s\+\)peer/\1md5/" /etc/postgresql/*/main/pg_hba.conf
# - pg_hba.conf にホスト接続許可を追記（ユーザーdifyがどこからでもmd5認証で接続可）
echo "host    dify    dify    0.0.0.0/0    md5" >> /etc/postgresql/*/main/pg_hba.conf

# PostgreSQLサービス再起動
systemctl restart postgresql

# 5. Dify の入手と設定
git clone https://github.com/langgenius/dify.git /opt/dify
cd /opt/dify/docker
cp .env.example .env

# .envのデータベース接続設定を書き換え
# インスタンスの内部IPを取得（GCP環境の場合のみ有効。失敗したら127.0.0.1を代わりに使用）
GCE_INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip || echo "127.0.0.1")
sed -i -e "s/DB_HOST=.*/DB_HOST=${GCE_INTERNAL_IP}/" \
       -e "s/DB_USERNAME=.*/DB_USERNAME=dify/" \
       -e "s/DB_PASSWORD=.*/DB_PASSWORD=dify-password/" \
       -e "s/DB_DATABASE=.*/DB_DATABASE=dify/" .env

# （オプション）docker-compose.ymlからDBサービス定義を削除してPostgreSQLコンテナ起動を防止
sed -i '/services:/,/^[^ ]/ {/db:/,/^[^ ]/ d}' docker-compose.yml

# 6. Dockerコンテナ起動
docker compose up -d
