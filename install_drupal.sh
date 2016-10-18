#!/bin/bash
export DRUPAL_VERSION="7.51"
export MYSQL_VERSION="5.5"
export CIVICRM_VERSION="4.7.12"
export LC_ALL="en_US.UTF-8"
sudo apt-get update
#Install nested libraries and packages
sudo apt-get install -y nginx git php5-common php5-fpm php5-gd libapache2-mod-auth-mysql php5-mysql php5-cli php5-json php5-cgi
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
sudo apt-get install -y mysql-server-${MYSQL_VERSION}
mysql -u root --password=armenia -e "CREATE DATABASE pci_drupal CHARACTER SET utf8 COLLATE utf8_general_ci";
mysql -u root --password=armenia -e "CREATE DATABASE pci_civicrm CHARACTER SET utf8 COLLATE utf8_general_ci";
mysql -u root --password=armenia -D pci_drupal -e "CREATE USER drupal@localhost IDENTIFIED BY 'armenia'; GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON pci_drupal.* TO 'drupal'@'localhost' IDENTIFIED BY 'armenia';"
mysql -u root --password=armenia -D pci_civicrm -e "CREATE USER civicrm@localhost IDENTIFIED BY 'armenia'; GRANT ALL ON pci_civicrm.* TO 'civicrm'@'localhost' IDENTIFIED BY 'armenia';"
mysql -u root --password=armenia -D pci_civicrm -e "GRANT SELECT ON pci_civicrm.* TO 'drupal'@'localhost' IDENTIFIED BY 'armenia';"
#Install phpmyadmin
#sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'
#sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password armenia'
#sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password armenia'
#sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password armenia'
#sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2'
#sudo apt-get install -y phpmyadmin
#Configure settings.php
cp drupal-${DRUPAL_VERSION}/sites/default/default.settings.php drupal-${DRUPAL_VERSION}/sites/default/settings.php
#Create files folder
mkdir drupal-${DRUPAL_VERSION}/sites/default/files
chmod ugo+w drupal-${DRUPAL_VERSION}/sites/default/files
#Restart services
sudo service nginx restart
sudo service php5-fpm restart
#Install drupal
cd drupal-${DRUPAL_VERSION}
drush -y site-install standard --db-url='mysql://drupal:armenia@localhost/pci_drupal' --site-name=PciExample --account-name=admin --account-pass=armenia
cd -
#Setup private folder for drupal
mkdir drupal-${DRUPAL_VERSION}/sites/default/private
chmod ugo+w drupal-${DRUPAL_VERSION}/sites/default/private
chmod 555 drupal-${DRUPAL_VERSION}/sites/default
echo "\$conf['file_private_path'] = 'sites/default/private';" >> drupal-${DRUPAL_VERSION}/sites/default/settings.php
sudo service php5-fpm restart
chmod 444 drupal-${DRUPAL_VERSION}/sites/default/settings.php
#Update nginx and php5-fpm configurations
sudo cp -r nginx /etc/nginx
sudo cp -r php5-fpm /etc/php5/fpm
sudo ln -s /etc/php5/cli/conf.d/ /etc/php5/fpm/conf.d
#Download CiviCRM and extract it
curl -O https://download.civicrm.org/civicrm-${CIVICRM_VERSION}-drupal.tar.gz
tar -xvf civicrm-${CIVICRM_VERSION}-drupal.tar.gz -C drupal-${DRUPAL_VERSION}/sites/all/modules
mkdir $HOME/.config/composer/vendor/drush/commands/civicrm
cp /home/ubuntu/drupal-${DRUPAL_VERSION}/sites/all/modules/civicrm/drupal/drush/civicrm.drush.inc $HOME/.config/composer/vendor/drush/commands/civicrm
rm -r /home/ubuntu/drupal-${DRUPAL_VERSION}/sites/all/modules/civicrm
chmod ugo+w /home/ubuntu/drupal-${DRUPAL_VERSION}/sites/default
cd /home/ubuntu/drupal-${DRUPAL_VERSION}
drush civicrm-install --dbuser=civicrm --dbpass=armenia --dbhost=localhost --dbname=pci_civicrm --tarfile=/home/ubuntu/civicrm-${CIVICRM_VERSION}-drupal.tar.gz --destination=sites/all/modules/
drush pm-enable civicrm
cd -
chmod 555 drupal-${DRUPAL_VERSION}/sites/default
rm civicrm-${CIVICRM_VERSION}-drupal.tar.gz
