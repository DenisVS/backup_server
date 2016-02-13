#!/bin/sh
DIR="/data/backup"
WWW="/data/sites"
TIMENAME=`date '+%Y-%m-%d-%H%M'`
TRUNCATE_CACHE="1"
GZIP_BASE="1"
DBUSER="root"
DBPASS="mypassword"
DBHOST="localhost"
LOG="/data/backup/backup.log"




##### Сохраняем WWW (Новая версия, каждый сайт в отдельной директории)
/bin/mkdir -p ${DIR}/${TIMENAME}/www
LIST_OF_DIRS=`/bin/ls -l ${WWW} | /usr/bin/awk '{if ($1 ~ /d.*/) print $9}' | /usr/bin/awk -F\/ '{print $1}'`
SAVEIFS=$IFS
IFS='
'
for CURRENT_DIR in ${LIST_OF_DIRS}; do
    echo Pack directory ${CURRENT_DIR}
    tar cvfz ${DIR}/${TIMENAME}/www/${CURRENT_DIR}.tar.gz ${WWW}/${CURRENT_DIR}
    chmod 666 ${DIR}/${TIMENAME}/www/${CURRENT_DIR}.tar.gz
done
IFS=$SAVEIFS
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_www.tgz" >> ${LOG}









