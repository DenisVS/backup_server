#!/bin/sh
# $Id$
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

# Сохраняем системную конфигурацию
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/backup_system.tar.${ARCH_EXT} /etc /usr/local/etc /boot/loader.conf /var/cron/tabs /var/db/mysql/my.cnf /root/.ssh
chmod 666 ${DIR}/${TIMENAME}/backup_system.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_system.tar.${ARCH_EXT}" >> ${LOG}
sleep ${PAUSE}


# Сохраняем пользовательские данные
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/backup_user.tar.${ARCH_EXT}  /root/.taskrc	/root/.task	/data/journal
chmod 666 ${DIR}/${TIMENAME}/backup_user.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_user.tar.${ARCH_EXT}" >> ${LOG}
sleep ${PAUSE}


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
    sleep ${PAUSE}
done
IFS=$SAVEIFS
LIST_OF_DIRS=`/bin/ls -l ${WWW2} | /usr/bin/awk '{if ($1 ~ /d.*/) print $9}' | /usr/bin/awk -F\/ '{print $1}'`
SAVEIFS=$IFS
IFS='
'
for CURRENT_DIR in ${LIST_OF_DIRS}; do
    echo Pack directory ${CURRENT_DIR}
    tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/www/${CURRENT_DIR}.tar.${ARCH_EXT} ${WWW2}/${CURRENT_DIR}
    chmod 666 ${DIR}/${TIMENAME}/www/${CURRENT_DIR}.tar.${ARCH_EXT}
    sleep ${PAUSE}
done
IFS=$SAVEIFS
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_www" >> ${LOG}
#######################################################################

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



# Закатываем базу Radicale
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/base/backup_radicale.tar.${ARCH_EXT} /data/radicale
chmod 666 ${DIR}/${TIMENAME}/base/backup_radicale.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_radicale.tar.${ARCH_EXT}" >> ${LOG}
sleep ${PAUSE}

# Закатываем SVN
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/base/backup_svn.tar.${ARCH_EXT} /data/svn
chmod 666 ${DIR}/${TIMENAME}/base/backup_svn.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_svn.tar.${ARCH_EXT}" >> ${LOG}
sleep ${PAUSE}

# Закатываем Taskwarrior
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/base/backup_taskd.tar.${ARCH_EXT} /data/taskd
chmod 666 ${DIR}/${TIMENAME}/base/backup_taskd.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_taskd.tar.${ARCH_EXT}" >> ${LOG}
sleep ${PAUSE}

# Закатываем TRAC
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/base/backup_trac.tar.${ARCH_EXT} /data/trac
chmod 666 ${DIR}/${TIMENAME}/base/backup_trac.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_trac.tar.${ARCH_EXT}" >> ${LOG}
sleep ${PAUSE}

# Закатываем JAIL (old)
#tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/base/backup_jails.tar.${ARCH_EXT} /data/jails/mariadb55/etc /data/jails/mariadb55/usr/local/etc /data/jails/php54/etc /data/jails/php54/usr/local/etc /data/jails/backtunnels/etc /data/jails/backtunnels/usr/local/etc /data/jails/backtunnels/home/sshtunnel/.ssh  /data/jails/myservices/etc /data/jails/myservices/usr/local/etc
#chmod 666 ${DIR}/${TIMENAME}/base/backup_jails.tar.${ARCH_EXT}
#TIMEDUMP=`date '+%T %x'`
#echo "backup has been done at $TIMEDUMP on backup_backtunnels.tar.${ARCH_EXT}" >> ${LOG}
#sleep ${PAUSE}

# Закатываем journal
tar cvf${TAR_OPT} ${DIR}/${TIMENAME}/base/journal.tar.${ARCH_EXT} /data/journal
chmod 666 ${DIR}/${TIMENAME}/base/journal.tar.${ARCH_EXT}
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on journal.tar.${ARCH_EXT}" >> ${LOG}
sleep ${PAUSE}




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
    sleep ${PAUSE}
done

##### Сохраняем GRANTS
USERS_HOSTS=`/usr/local/bin/mysql -u ${DBUSER} -h ${DBHOST} -B -N -p"${DBPASS}" -e "SELECT user, host FROM user" mysql`

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
		SQL_QUERIES=`/usr/local/bin/mysql -u "${DBUSER}" -h ${DBHOST} -p"${DBPASS}" -B -N -e"SHOW GRANTS FOR '${USER}'@'${HOST}'"`
		for SQL_QUERY in ${SQL_QUERIES}; do
			echo ${SQL_QUERY}\; >> ${DIR}/${TIMENAME}/base/mysql/users.sql
			#echo -----------------------------------------
		done
	fi
done
sleep ${PAUSE}
IFS=$SAVEIFS

##### Сохраняем информацию о приложениях
/usr/sbin/pkg info > ${DIR}/${TIMENAME}/pkg.txt
chmod 666 ${DIR}/${TIMENAME}/pkg.txt

