#!/bin/sh
#
### Script to determine the state of an audited Drupal website
#
### Prerequisites: Unix operating system, Git
### This script should be at Drupal's root directory#

# Checkout Drush 5.x if needed.
if [ ! -d drush ]; then
  git clone git://git.drupal.org/project/drush --branch 7.x-5.x drush
fi
export PATH="$(pwd)/drush:$PATH"

DRUPAL_VERSION = `drush status | grep 'Drupal version' | cut -d: -f2 | sed -e s/[^0-9]//`

echo "Start Audit report" > drupal_audit_report.txt

echo "----------------------------------------" >> drupal_audit_report.txt
echo "Drush status" >> drupal_audit_report.txt
drush status >> drupal_audit_report.txt

echo "----------------------------------------" >> drupal_audit_report.txt
echo "Hacked status" >> drupal_audit_report.txt
drush dl -y hacked
drush en -y hacked
drush cc drush
drush hacked-list-projects >> drupal_audit_report.txt
drush dis -y hacked
drush pm-uninstall -y hacked

echo "----------------------------------------" >> drupal_audit_report.txt
echo "Custom installation profiles" >> drupal_audit_report.txt
ls profiles/ | grep -v minimal | grep -v standard | grep -v testing >> drupal_audit_report.txt

echo "----------------------------------------" >> drupal_audit_report.txt
echo "Makefile(s)" >> drupal_audit_report.txt
find profiles/ -name '*make*' >> drupal_audit_report.txt
find profiles/ -name '*make*' -exec cat '{}' \; >> drupal_audit_report.txt

echo "----------------------------------------" >> drupal_audit_report.txt
echo "Module status" >> drupal_audit_report.txt
drush pml >> drupal_audit_report.txt

#
### CAUTION: This step should only be performed on Drupal 7 websites.
#
echo "----------------------------------------" >> drupal_audit_report.txt
echo "Caches status" >> drupal_audit_report.txt
drush dl -y cacheaudit
drush en -y cacheaudit
drush cc drush
drush cacheaudit >> drupal_audit_report.txt
drush dis -y cacheaudit
drush pm-uninstall -y cacheaudit

echo "----------------------------------------" >> drupal_audit_report.txt
echo "PHP status" >> drupal_audit_report.txt
drush php-eval 'phpinfo();' >> drupal_audit_report.txt 

# Missing in the script (to do manually):
# Browser visit with WAppalyser and YSlow extensions
# curl -I homepage (give some informations about proxys, ...)
# https://www.ssllabs.com/ssltest/analyze.html
# Opquast.com
