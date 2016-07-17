#!/bin/bash

#go into the site directory and run the setup

a2enmod cgi

# Activate modrewrite
a2enmod rewrite

if [ -f /var/lib/mysql/ibdata1 ]; then
sed -i "/bind-address/a sql_mode = NO_ENGINE_SUBSTITUTION" /etc/mysql/my.cnf
service mysql start
sleep 10s

mysqladmin -uroot create zm
echo 'GRANT ALL ON *.* TO `zmuser`@"%" IDENTIFIED BY "zmpass" WITH GRANT OPTION; FLUSH PRIVILEGES;' | mysql
mysql --user=zmuser -pzmpass zm < db/zm_create.sql
killall mysqld
sleep 10s
fi

echo "Database Installation Complete ..."
