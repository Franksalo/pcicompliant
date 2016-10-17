#!/bin/bash
export DRUPAL_VERSION = "7.51"
export MYSQL_VERSION = "5.6"
export CIVICRM_VERSION = "4.7.12"
sudo apt-get update
#Install nested libraries and packages
sudo apt-get install -y nginx git php5-common php5-fpm php5-gd libapache2-mod-auth-mysql php5-mysql phpmyadmin
#Install composer and drush
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer global require drush/drush:7.*
export PATH="$HOME/.config/composer/vendor/bin:$PATH"
#Download drupal
drush dl drupal-${DRUPAL_VERSION}
#Install mysql and configure the databases
sudo debconf-set-selections <<< 'mysql-server-${MYSQL_VERSION} mysql-server/root_password password armenia'
sudo debconf-set-selections <<< 'mysql-server-${MYSQL_VERSION} mysql-server/root_password_again password armenia'
sudo apt-get -y install mysql-server-${MYSQL_VERSION}
mysql -u root --password=armenia -e "CREATE DATABASE pci_drupal CHARACTER SET utf8 COLLATE utf8_general_ci";
mysql -u root --password=armenia -e "CREATE DATABASE pci_civicrm CHARACTER SET utf8 COLLATE utf8_general_ci";
mysql -u root --password=armenia -D pci_drupal -e "CREATE USER drupal@localhost IDENTIFIED BY 'armenia'; GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON pci_drupal.* TO 'franco'@'localhost' IDENTIFIED BY 'armenia';"
mysql -u root --password=armenia -D pci_civicrm -e "CREATE USER civicrm@localhost IDENTIFIED BY 'armenia'; GRANT ALL ON pci_civicrm.* TO 'civicrm'@'localhost' IDENTIFIED BY 'armenia';"
mysql -u root --password=armenia -D pci_civicrm -e "GRANT SELECT TABLES ON pci_civicrm.* TO 'drupal'@'localhost' IDENTIFIED BY 'armenia';"
#Update nginx file
sudo mv nginx_configuration /etc/nginx/sites-available/default
#Configure settings.php
cp drupal-${DRUPAL_VERSION}/sites/default/default.settings.php drupal-${DRUPAL_VERSION}/sites/default/settings.php
#Create files folder
mkdir drupal-${DRUPAL_VERSION}/sites/default/files
chmod ugo+w drupal-${DRUPAL_VERSION}/sites/default/files
#Restart services
sudo service nginx restart
sudo service php-fpm restart
#Install drupal
cd drupal-${DRUPAL_VERSION}
drush site-install standard --db-url='mysql://drupal:armenia@localhost/pci_drupal' --site-name=PciExample --account-name=admin --account-pass=armenia
cd -
#Back to permissions
chmod 555 drupal-${DRUPAL_VERSION}/sites/default && chmod 444 drupal-${DRUPAL_VERSION}/sites/settings.php
#Setup private folder for drupal
echo "$conf['file_private_path'] = 'sites/default/private';" >> drupal-${DRUPAL_VERSION}/sites/default/settings.php
sudo service php5-fpm restart
#Download CiviCRM and extract it
curl -O https://download.civicrm.org/civicrm-${CIVICRM_VERSION}-drupal.tar.gz
tar -xvf civicrm-${CIVICRM_VERSION}-drupal.tar.gz -C drupal-${DRUPAL_VERSION}/sites/all/modules
rm civicrm-${CIVICRM_VERSION}-drupal.tar.gz
#Set up requirements
chmod ugo+w drupal-${DRUPAL_VERSION}/sites/default
