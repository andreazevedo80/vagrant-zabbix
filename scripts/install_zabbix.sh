#!/bin/bash

# Variáveis
MYSQL_ROOT_PASSWORD="zabbix"
ZABBIX_DB="zabbix"
ZABBIX_USER="zabbix"
ZABBIX_PASSWORD="zabbix"

# Atualizar pacotes
sudo apt-get update -y && sudo apt-get upgrade -y

# Instalar o MySQL Server
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"
sudo apt-get install -y mysql-server

# Criar banco de dados e usuário Zabbix
sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE $ZABBIX_DB CHARACTER SET utf8 COLLATE utf8_bin;"
sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE USER '$ZABBIX_USER'@'localhost' IDENTIFIED BY '$ZABBIX_PASSWORD';"
sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $ZABBIX_DB.* TO '$ZABBIX_USER'@'localhost';"
sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

# Instalar dependências e baixar repositório do Zabbix
sudo apt-get install -y wget lsb-release
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_$(lsb_release -cs)_all.deb
sudo dpkg -i zabbix-release_$(lsb_release -cs)_all.deb
sudo apt-get update

# Instalar Zabbix Server com MySQL e frontend
sudo apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent

# Importar o esquema inicial do banco de dados para o Zabbix
sudo zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u$ZABBIX_USER -p$ZABBIX_PASSWORD $ZABBIX_DB

# Configurar o Zabbix Server para usar o banco de dados MySQL
sudo sed -i "s/# DBPassword=/DBPassword=$ZABBIX_PASSWORD/" /etc/zabbix/zabbix_server.conf

# Reiniciar e habilitar os serviços do Zabbix e do Apache
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
