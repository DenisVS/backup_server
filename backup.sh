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
tar cvfz ${DIR}/${TIMENAME}/backup_system.tar.gz /etc /usr/local/etc /boot/loader.conf /var/cron/tabs /var/db/mysql/my.cnf /root/.ssh 
chmod 666 ${DIR}/${TIMENAME}/backup_system.tar.gz


TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_system.tgz" >> ${LOG}

#cp /usr/local/etc/apache22/httpd.conf.maintenance  /usr/local/etc/apache22/httpd.conf
#/usr/local/sbin/apachectl restart

##### Сохраняем WWW 
tar cvfz ${DIR}/${TIMENAME}/backup_www.tar.gz ${WWW}
chmod 666 ${DIR}/${TIMENAME}/backup_www.tar.gz
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_www.tgz" >> ${LOG}

# Закатываем базу Radicale
tar cvfz ${DIR}/${TIMENAME}/base/backup_radicale.tar.gz /var/db/radicale
chmod 666 ${DIR}/${TIMENAME}/base/backup_radicale.tar.gz
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_radicale.tar.gz" >> ${LOG}

# Закатываем SVN
tar cvfz ${DIR}/${TIMENAME}/base/backup_svn.tar.gz /data/svn
chmod 666 ${DIR}/${TIMENAME}/base/backup_svn.tar.gz
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_svn.tar.gz" >> ${LOG}

# Закатываем TRAC
tar cvfz ${DIR}/${TIMENAME}/base/backup_trac.tar.gz /data/trac
chmod 666 ${DIR}/${TIMENAME}/base/backup_trac.tar.gz
TIMEDUMP=`date '+%T %x'`
echo "backup has been done at $TIMEDUMP on backup_trac.tar.gz" >> ${LOG}


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
    if [ "${GZIP_BASE}" = "1" ]; then
	/usr/local/bin/mysqldump -u${DBUSER} -h ${DBHOST} -p${DBPASS} ${DBNAME} | /usr/bin/gzip -c > "${DIR}/${TIMENAME}/base/mysql/${DBNAME}.sql.gz" 
	chmod 666 ${DIR}/${TIMENAME}/base/mysql/${DBNAME}.sql.gz
    else
	/usr/local/bin/mysqldump -u${DBUSER} -h ${DBHOST} -p${DBPASS} ${DBNAME} > "${DIR}/${TIMENAME}/base/mysql/${DBNAME}.sql" 
	chmod 666 ${DIR}/${TIMENAME}/base/mysql/${DBNAME}.sql
    fi
    TIMEDUMP=`date '+%T %x'`
    echo "backup has been done at $TIMEDUMP on db: ${DBNAME}" >> ${LOG}
done

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
			echo ${SQL_QUERY}\; >> ${DIR}/${TIMENAME}/base/mysql/users.sql 
			#echo -----------------------------------------
		done
	fi
done

IFS=$SAVEIFS

##### Сохраняем информацию о приложениях
/usr/sbin/pkg info > ${DIR}/${TIMENAME}/pkg.txt
chmod 666 ${DIR}/${TIMENAME}/pkg.txt

