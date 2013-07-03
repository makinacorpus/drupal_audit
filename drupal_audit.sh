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

# Missing in the script (to do manually):
# Browser visit with WAppalyser and YSlow extensions
# curl -I homepage (give some informations about proxys, ...)
# https://www.ssllabs.com/ssltest/analyze.html
# Opquast.com
