#!/bin/sh
#
WanIf="rl0"

ip_gw_ping() {
    WanIp=`/sbin/ifconfig ${WanIf} | /usr/bin/grep 'inet ' | /usr/bin/awk '{print $2}'` # Определим IP
    GW=`netstat -rn | awk '$1=="default"{print $2}'`                                    # Определим гейт
#    /sbin/ping  -t 5 -c 3  ${GW} >/dev/null 2>/dev/null                                 # Пингуем гейт 3 раза, ждё
    /sbin/ping  -t 5 -c 3  127.0.0.1 >/dev/null 2>/dev/null                                 # Пингуем гейт 3 раза, ждё
}

ip_gw_ping

if [ "${WanIp}" = "" -o "${WanIp}" = "0.0.0.0" -o  "${GW}" = "" ]; then
    echo "ЖОПА"
    
  
fi

#echo ${WanIp}
#echo $?
#if [ $? -ne 0 -o "${WanIp}" = ""  -o  "${GW}" = "" ]; then
    CONNECT=`cat /tmp/connect.pid`
    echo ${CONNECT}
    if [ "${CONNECT}" != "loss" ]; then
        (/sbin/kldload speaker && /bin/echo -e "lby.iudg.fyib8.7hiug6.8ghjgh" > /dev/speaker && /sbin/kldunload speaker)&
        echo "loss" > /tmp/connect.pid
    else
	        rm -f /tmp/connect.pid                                  # Удаляем пид
(/sbin/kldload speaker && /bin/echo -e "l.p" > /dev/speaker && /sbin/kldunload speaker)&
    fi
    
#fi
