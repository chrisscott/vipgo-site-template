#!/usr/bin/env bash
# Provision WordPress Stable for VIP
 
VIP_REPO=`get_config_value 'vip-repo'`

# Check to make sure there's a VIP repo set in the config. We need this since 
# it is the wp-content directory and we need to add mu-plugins after cloning it.
if [ -z "$VIP_REPO" ]; then
  echo "VIP: vip-repo must be set in vvv-custom.yml. See https://github.com/chrisscott/vipgo-site-template/blob/master/README.md for details." > /dev/stderr
  echo "Skipping provisioning for ${VVV_SITE_NAME}" > /dev/stderr
  exit 1
fi

DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`
DOMAINS=`get_hosts "${DOMAIN}"`
SITE_TITLE=`get_config_value 'site_title' "${DOMAIN}"`
WP_VERSION=`get_config_value 'wp_version' 'latest'`
WP_TYPE=`get_config_value 'wp_type' "single"`
DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}

# Make a database, if we don't already have one
echo -e "\nCreating database '${DB_NAME}' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log

# Install and configure the latest stable version of WordPress
if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-load.php" ]]; then
    echo "Downloading WordPress..."
	noroot wp core download --version="${WP_VERSION}"
fi

if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-config.php" ]]; then
  echo "Configuring WordPress Stable..."
  noroot wp core config --dbname="${DB_NAME}" --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
define( 'WP_DEBUG', true );
PHP
fi

if ! $(noroot wp core is-installed); then
  echo "Installing WordPress Stable..."

  if [ "${WP_TYPE}" = "subdomain" ]; then
    INSTALL_COMMAND="multisite-install --subdomains"
  elif [ "${WP_TYPE}" = "subdirectory" ]; then
    INSTALL_COMMAND="multisite-install"
  else
    INSTALL_COMMAND="install"
  fi

  echo "VIP: Installing WordPress with Administrator user 'wp' with password 'wp'... "
  noroot wp core ${INSTALL_COMMAND} --url="${DOMAIN}" --quiet --title="${SITE_TITLE}" --admin_name=wp --admin_email="wp@local.test" --admin_password="wp"
  
  echo "VIP: Removing wp-content directory"
  noroot rm -rf ${VVV_PATH_TO_SITE}/public_html/wp-content/

  echo "VIP: Cloning VIP site repo..."
  noroot git clone ${VIP_REPO} ${VVV_PATH_TO_SITE}/public_html/wp-content

  echo "VIP: Installing VIP Go mu-plugins..."
  noroot git clone git@github.com:Automattic/vip-go-mu-plugins.git --recursive ${VVV_PATH_TO_SITE}/public_html/wp-content/mu-plugins/

	echo "VIP: Including VIP config..."
	cat << EOF >> ${VVV_PATH_TO_SITE}/public_html/wp-config.php

// Include VIP Config
if ( file_exists( __DIR__ . '/wp-content/vip-config/vip-config.php' ) ) {
    require_once( __DIR__ . '/wp-content/vip-config/vip-config.php' );
}
EOF

  echo "VIP: Symlinking object-cache.php..."
  noroot ln -s ${VVV_PATH_TO_SITE}/public_html/wp-content/mu-plugins/drop-ins/object-cache/object-cache.php ${VVV_PATH_TO_SITE}/public_html/wp-content/object-cache.php

  # noroot wp option update permalink_structure '/%postname%/'
else
  echo "Updating WordPress Stable..."
  cd ${VVV_PATH_TO_SITE}/public_html
  noroot wp core update --version="${WP_VERSION}"
  
  echo "VIP: Updating VIP Go mu-plugins..."
  cd ${VVV_PATH_TO_SITE}/public_html/wp-content/mu-plugins/
  noroot git pull origin master
  noroot git submodule update --init --recursive
fi

cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
sed -i "s#{{DOMAINS_HERE}}#${DOMAINS}#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"

if [ -n "$(type -t is_utility_installed)" ] && [ "$(type -t is_utility_installed)" = function ] && `is_utility_installed core tls-ca`; then
    sed -i "s#{{TLS_CERT}}#ssl_certificate /vagrant/certificates/${VVV_SITE_NAME}/dev.crt;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{TLS_KEY}}#ssl_certificate_key /vagrant/certificates/${VVV_SITE_NAME}/dev.key;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
else
    sed -i "s#{{TLS_CERT}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{TLS_KEY}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
fi

