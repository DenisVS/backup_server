#!/bin/sh
# $Id$
DIR="/data/backup"
WWW="/data/sites"
TIMENAME=`date '+%Y-%m-%d-%H%M'`
TRUNCATE_CACHE="1"
ARCH_BASE="1"
DBUSER="root"
DBPASS="mypassword"
DBHOST="localhost"
LOG="/data/backup/backup.log"
ARCHIVER="bzip2"

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
#mkdir -p ${DIR}/${TIMENAME}
mkdir -p ${DIR}/${TIMENAME}/base/mysql
#chmod 777 ${TIMENAME}
#chmod 777 ${DIR}/${TIMENAME}/base
#chmod -R 777 ${DIR}/${TIMENAME}
touch ${LOG}
touch ${DIR}/${TIMENAME}/base/mysql/users.sql
#chmod 666 ${DIR}/${TIMENAME}/base/users.sql
#chmod 777 ${DIR}/${TIMENAME}/base
chmod -R 777 ${DIR}/${TIMENAME}

# Сохраняем системную конфигурацию
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/backup_system.tar.${ARCH_EXT} /etc /usr/local/etc /boot/loader.conf /var/cron/tabs /var/db/mysql/my.cnf /root/.ssh 
chmod 666 ${DIR}/${TIMENAME}/backup_system.tar.${ARCH_EXT}


TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_system.tar.${ARCH_EXT}" >> ${LOG}

#cp /usr/local/etc/apache22/httpd.conf.maintenance  /usr/local/etc/apache22/httpd.conf
#/usr/local/sbin/apachectl restart

##### Сохраняем WWW (Старая версия, все сайты в кучу)
#tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/backup_www.tar.${ARCH_EXT} ${WWW}
#chmod 666 ${DIR}/${TIMENAME}/backup_www.tar.${ARCH_EXT}
#TIMEDUMP=`date '+%T %x'`
#echo "backup has been done at $TIMEDUMP on backup_www.tar.${ARCH_EXT}" >> ${LOG}

##### Сохраняем WWW (Новая версия, каждый сайт в отдельной директории)
/bin/mkdir -p ${DIR}/${TIMENAME}/www
LIST_OF_DIRS=`/bin/ls -l ${WWW} | /usr/bin/awk '{if ($1 ~ /d.*/) print $9}' | /usr/bin/awk -F\/ '{print $1}'`
SAVEIFS=$IFS
IFS='
'
for CURRENT_DIR in ${LIST_OF_DIRS}; do
    echo Pack directory ${CURRENT_DIR}
    tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/www/${CURRENT_DIR}.tar.${ARCH_EXT} ${WWW}/${CURRENT_DIR}
    chmod 666 ${DIR}/${TIMENAME}/www/${CURRENT_DIR}.tar.${ARCH_EXT}
done
IFS=$SAVEIFS
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_www.tar.${ARCH_EXT}" >> ${LOG}

# Закатываем базу Radicale
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/base/backup_radicale.tar.${ARCH_EXT} /var/db/radicale
chmod 666 ${DIR}/${TIMENAME}/base/backup_radicale.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_radicale.tar.${ARCH_EXT}" >> ${LOG}

# Закатываем SVN
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/base/backup_svn.tar.${ARCH_EXT} /data/svn
chmod 666 ${DIR}/${TIMENAME}/base/backup_svn.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_svn.tar.${ARCH_EXT}" >> ${LOG}

# Закатываем TRAC
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/base/backup_trac.tar.${ARCH_EXT} /data/trac
chmod 666 ${DIR}/${TIMENAME}/base/backup_trac.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_trac.tar.${ARCH_EXT}" >> ${LOG}


#cp /usr/local/etc/apache22/httpd.conf.current  /usr/local/etc/apache22/httpd.conf
#/usr/local/sbin/apachectl restart

##### Сохраняем дампы базы MySQL

DBASES=`/usr/local/bin/mysql -u${DBUSER} -h ${DBHOST} -p${DBPASS} -Bse 'show databases' | grep -vE 'mysql|information_schema|performance_schema'`
for DBNAME in ${DBASES}; do
    if [ "${TRUNCATE_CACHE}" = "1" ]; then
	TRUNCATE_TABLES=`/usr/local/bin/mysql -u${DBUSER} -h ${DBHOST} -p${DBPASS} ${DBNAME} -Bse 'show tables;' | grep cache`
	for TABLENAME in ${TRUNCATE_TABLES}; do
		/usr/local/bin/mysql -u${DBUSER} -h ${DBHOST} -p${DBPASS} ${DBNAME} -Bse "truncate table ${TABLENAME};"
	done
    fi
    if [ "${ARCH_BASE}" = "1" ]; then
	/usr/local/bin/mysqldump -u${DBUSER} -h ${DBHOST} -p${DBPASS} ${DBNAME} | ${ARCH_APP} -c > "${DIR}/${TIMENAME}/base/mysql/${DBNAME}.sql.${ARCH_EXT}" 
	chmod 666 ${DIR}/${TIMENAME}/base/mysql/${DBNAME}.sql.${ARCH_EXT}
    else
	/usr/local/bin/mysqldump -u${DBUSER} -h ${DBHOST} -p${DBPASS} ${DBNAME} > "${DIR}/${TIMENAME}/base/mysql/${DBNAME}.sql" 
	chmod 666 ${DIR}/${TIMENAME}/base/mysql/${DBNAME}.sql
    fi
    TIMEDUMP=`date '+%T %x'`
    echo "backup has been done at $TIMEDUMP on db: ${DBNAME}" >> ${LOG}
done

##### Сохраняем GRANTS
USERS_HOSTS=`/usr/local/bin/mysql -u ${DBUSER} -B -N -p"${DBPASS}" -e "SELECT user, host FROM user" mysql`

SAVEIFS=$IFS
IFS='
'
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
			echo ${SQL_QUERY}\; >> ${DIR}/${TIMENAME}/base/mysql/users.sql 
			#echo -----------------------------------------
		done
	fi
done

IFS=$SAVEIFS

##### Сохраняем информацию о приложениях
/usr/sbin/pkg info > ${DIR}/${TIMENAME}/pkg.txt
chmod 666 ${DIR}/${TIMENAME}/pkg.txt

