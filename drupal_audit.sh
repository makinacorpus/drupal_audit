#!/bin/sh
#
### Script to determine the state of an audited Drupal website.
#
### Prerequisites: Unix operating system, eventually drush command tool.
### This script should be at Drupal website's root directory.
#
DRUPAL_VERSION=`drush status | grep 'Drupal version' | cut -d: -f2 | sed -e s/[^0-9]//`
#
### Prerequisite installation
#
if ! type "drush" > /dev/null; then
  git clone git://git.drupal.org/project/drush --branch 7.x-5.x drush
  export PATH="$(pwd)/drush:$PATH"
fi
#
### Report generation
#
echo "----------------------------------------" >> drupal_audit_report.txt
echo "  Drush status" >> drupal_audit_report.txt
echo "----------------------------------------" >> drupal_audit_report.txt
drush status >> drupal_audit_report.txt

echo "----------------------------------------" >> drupal_audit_report.txt
echo "  Hacked status" >> drupal_audit_report.txt
echo "----------------------------------------" >> drupal_audit_report.txt
drush dl -y hacked
drush en -y hacked
drush cc drush
drush hacked-list-projects >> drupal_audit_report.txt
drush dis -y hacked
drush pm-uninstall -y hacked

echo "----------------------------------------" >> drupal_audit_report.txt
echo "  Custom installation profiles" >> drupal_audit_report.txt
echo "----------------------------------------" >> drupal_audit_report.txt
ls profiles/ | grep -v minimal | grep -v standard | grep -v testing >> drupal_audit_report.txt

echo "----------------------------------------" >> drupal_audit_report.txt
echo "  Makefile(s)" >> drupal_audit_report.txt
echo "----------------------------------------" >> drupal_audit_report.txt
find profiles/ -name '*make*' >> drupal_audit_report.txt
find profiles/ -name '*make*' -exec cat '{}' \; >> drupal_audit_report.txt

echo "----------------------------------------" >> drupal_audit_report.txt
echo "  Modules status" >> drupal_audit_report.txt
echo "----------------------------------------" >> drupal_audit_report.txt
drush pml >> drupal_audit_report.txt

echo "----------------------------------------" >> drupal_audit_report.txt
echo "  Themes status" >> drupal_audit_report.txt
echo "----------------------------------------" >> drupal_audit_report.txt
for i in `drush pml | grep Theme | grep Enabled | cut -d\( -f2 | cut -d\) -f1`
do
  THEMENAME=$i
  THEMEPATH=`drush php-eval "echo drupal_get_path('theme', '$i');"`
  echo "# Theme: $THEMENAME" >> drupal_audit_report.txt
  COUNT=`find $THEMEPATH -name *.tpl.php | wc -l`
  echo "  Templates count: $COUNT" >> drupal_audit_report.txt
  COUNT=`grep -r function $THEMEPATH | wc -l`
  echo "  Functions count: $COUNT" >> drupal_audit_report.txt
  COUNT=`grep -r db_[a-z_]*\( $THEMEPATH | wc -l`
  echo "  Database access count: $COUNT" >> drupal_audit_report.txt
done

#
### CAUTION: This step should only be performed on Drupal 7 websites.
#
echo "----------------------------------------" >> drupal_audit_report.txt
echo "  Caches status" >> drupal_audit_report.txt
echo "----------------------------------------" >> drupal_audit_report.txt
drush dl -y cacheaudit
drush cc drush
drush cacheaudit >> drupal_audit_report.txt

echo "----------------------------------------" >> drupal_audit_report.txt
echo "  PHP status" >> drupal_audit_report.txt
echo "----------------------------------------" >> drupal_audit_report.txt
drush php-eval 'phpinfo(INFO_GENERAL | INFO_CONFIGURATION | INFO_MODULES | INFO_ENVIRONMENT | INFO_VARIABLES);' >> drupal_audit_report.txt

#
### Database audit
#
DB_VENDOR=`drush status | grep 'Database driver' | cut -d: -f2 | sed -e s/[^0-9]//`
DB_NAME=`drush status | grep 'Database name' | cut -d: -f2 | sed -e s/[^0-9]//`
if [ "mysql" = $DB_VENDOR ]; then
  echo "----------------------------------------" >> drupal_audit_report.txt
  echo "  MySQL informations" >> drupal_audit_report.txt
  echo "----------------------------------------" >> drupal_audit_report.txt
  drush sqlq "SELECT CONCAT(SUM(ROUND(data_length/(1024*1024),2)),'Mb') AS data_length, CONCAT(SUM(ROUND(index_length/(1024*1024),2)),'Mb') AS index_length FROM information_schema.TABLES WHERE table_schema = \"$DB_NAME\" GROUP BY table_schema;" >> drupal_audit_report.txt
  echo "Tables that are not using utf8_general_ci:" >> drupal_audit_report.txt
  drush sqlq "SELECT TABLE_NAME AS name, TABLE_COLLATION AS collation FROM information_schema.TABLES WHERE TABLES.table_schema = \"$DB_NAME\" AND TABLE_COLLATION != 'utf8_general_ci';" >> drupal_audit_report.txt
  echo "Tables with more than 1 000 rows:" >> drupal_audit_report.txt
  drush sqlq "SELECT TABLE_NAME AS table_name, TABLE_ROWS AS rows FROM information_schema.TABLES WHERE TABLES.TABLE_SCHEMA = \"$DB_NAME\" AND TABLE_ROWS >= 1000 ORDER BY TABLE_ROWS desc;" >> drupal_audit_report.txt
  echo "DB Fragmentation:" >> drupal_audit_report.txt
  drush sqlq "SHOW TABLE STATUS WHERE Data_free > 0;"  >> drupal_audit_report.txt
fi

# Missing in the script (to do manually):
# Browser visit with WAppalyser and YSlow extensions
# curl -I homepage (give some informations about proxys, ...)
# https://www.ssllabs.com/ssltest/analyze.html
# Opquast.com
