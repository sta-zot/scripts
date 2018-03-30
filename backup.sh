#!/bin/bash
SRC="null"
DST="null"
INC="0"
TMP_DIR="/mnt/backupdir/"
LOG_FILE="$SRC/`date +%Y.%m.%d`.archive.lo"
OPT="-o ";

while [ -n "$1" ]; do
    case "$1" in
	-s) SRC="$2"
	    shift ;;
	-d) DST="$2"
	    shift ;;
	-i) INC="1"; shift;;
	-o) OPT=$OPT$2; shift;shift;;
    esac
done

ARCH_NAME="$SRC/`date +%Y.%m.%d`.archive.";

if [ ${DST:0:2} = '//' ]; then #Если папка назначения начинается с "//" то пытаемся смонтировать сетевую папку
    locate cifs; # Проверка на наличие пакета 
    if [ $? -ne 0 ]; then # Если пакета нет пишем лог и выходим с ошибкой 101;
	echo "`date +"%Y.%m.%d  %H:%M:%S"` ERROR: cifs_utils not installed   Exit with 101 code" >> $LOG_FILE;
	exit 101;
    fi



    if [ ` test -d $TMP_DIR; echo $?` -ne 0 ]; then # Проверяем есть ли папка для монтирования, если нет создаем;
    
	mkdir -p /mnt/backupdir
    fi

    SRV=`echo $DST | cut -d / -f 3`;
    ping $SVR -c1

    if [ $? -ne 0 ]; then # Проверяем доступноть сервера, если не доступен пишем лог и выходим с ошибкой 102;
	echo "`date +"%Y.%m.%d  %H:%M:%S"` ERROR: host $SRV not available   Exit with 102 code" >> $LOG_FILE;
	exit 102;
    fi

    RES=`mouunt.cifs $TMP_DIR $DST $OPT; $?`;
    if [ $RES -ne 0 ]
    then
	echo "`date +"%Y.%m.%d  %H:%M:%S"` ERROR: mounting remote SMBfs on $SRV unsuccessfull   Exit with 103 code" >> $LOG_FILE;
	exit 103;
    fi 
    DST =$TMP_DIR;
fi


if [ ! -d "$SRC" ]
then
    echo "`date +"%Y.%m.%d  %H:%M:%S"` ERROR: Source folder not exist   Exit with 104 code" >> $LOG_FILE;
    exit 104
fi
if [ $INC -eq 1 ]
then
    CMD="tar -cgLzf $ARCH_NAME $SRC";
else
    CMD="tar -cLzf $ARCH_NAME $SRCfull.gz";
fi
echo $CMD
