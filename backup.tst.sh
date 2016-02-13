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


killall php
mkdir -p ${DIR}
chmod 777 ${DIR}
cd ${DIR}
mkdir -p ${DIR}/${TIMENAME}
mkdir -p ${DIR}/${TIMENAME}/base
chmod 777 ${TIMENAME}
chmod 777 ${DIR}/${TIMENAME}/base
touch ${LOG}
touch ${DIR}/${TIMENAME}/base/users.sql
chmod 777 ${DIR}/${TIMENAME}/base/users.sql


##### Сохраняем GRANTS
SAVEIFS=$IFS
IFS='
'

USERS_HOSTS=`/usr/local/bin/mysql -u ${DBUSER} -B -N -p"${DBPASS}" -e "SELECT user, host FROM user" mysql`


for USER_HOST in ${USERS_HOSTS}; do
	NULL_STRING=0	#индикатор пустой строки
	#echo ${USER_HOST}
	USER=`echo ${USER_HOST} | /usr/bin/awk '{print $1}'`
	#echo user: ${USER}
	HOST=`echo ${USER_HOST} | /usr/bin/awk '{print $2}'`
	#echo host: ${HOST}
	if [ "${USER}" = "" ]; then
		NULL_STRING=1
	fi
	if [ "${HOST}" = "" ]; then
		NULL_STRING=1
	fi
	if [ "${NULL_STRING}" = "0" ]; then
		SQL_QUERIES=`/usr/local/bin/mysql -u "${DBUSER}" -p"${DBPASS}" -B -N -e"SHOW GRANTS FOR '${USER}'@'${HOST}'"`
		for SQL_QUERY in ${SQL_QUERIES}; do
			echo ${SQL_QUERY}\; >> ${DIR}/${TIMENAME}/base/users.sql 
			#echo -----------------------------------------
		done
	fi
done

IFS=$SAVEIFS

