#!/bin/sh
# $Id: backup.sh 9 2016-02-17 09:39:06Z denis $
DIR="/data/backup"
WWW="/data/sites_php72"
WWW2="/data/sites_php71"
JAILS="/data/jails"
TIMENAME=`date '+%Y-%m-%d-%H%M'`
TRUNCATE_CACHE="1"
ARCH_BASE="1"
DBUSER="root"
DBPASS="mypassword"
DBHOST="192.168.1.64"
LOG="/data/backup/backup.log"
ARCHIVER="bzip2"
PAUSE=10

#######################################################
if [ "${ARCHIVER}" = "gzip" ]; then
    ARCH_EXT="gz"
    TAR_OPT="z"
    ARCH_APP="/usr/bin/gzip"
fi
if [ "${ARCHIVER}" = "bzip2" ]; then
    ARCH_EXT="bz2"
    TAR_OPT="j"
    ARCH_APP="/usr/bin/bzip2"
fi

killall php
mkdir -p ${DIR}
chmod 777 ${DIR}
cd ${DIR}
mkdir -p ${DIR}/${TIMENAME}/base/mysql
touch ${LOG}
touch ${DIR}/${TIMENAME}/base/mysql/users.sql
chmod -R 777 ${DIR}/${TIMENAME}



##### Сохраняем Jails config (Новая версия, каждая клетка в отдельной директории)
/bin/mkdir -p ${DIR}/${TIMENAME}/jails

LIST_OF_DIRS=`/bin/ls -l ${JAILS} | /usr/bin/awk '{if ($1 ~ /d.*/) print $9}' | /usr/bin/awk -F\/ '{print $1}'`
SAVEIFS=$IFS
IFS='
'
for CURRENT_DIR in ${LIST_OF_DIRS}; do
    echo Pack jail ${CURRENT_DIR}
    cd ${JAILS}/${CURRENT_DIR}
    tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/jails/${CURRENT_DIR}.tar.${ARCH_EXT} etc usr/local/etc root usr/home
    #tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/jails/${CURRENT_DIR}.tar.${ARCH_EXT} ${JAILS}/${CURRENT_DIR}/etc ${JAILS}/${CURRENT_DIR}/usr/local/etc ${JAILS}/${CURRENT_DIR}/root ${JAILS}/${CURRENT_DIR}/usr/home
    chmod 666 ${DIR}/${TIMENAME}/jails/${CURRENT_DIR}.tar.${ARCH_EXT}
    sleep ${PAUSE}
done
IFS=$SAVEIFS
cd ${DIR}
echo "backup has been done at $TIMEDUMP on ${DIR}/${TIMENAME}/jails" >> ${LOG}
sleep ${PAUSE}
#######################################################################

