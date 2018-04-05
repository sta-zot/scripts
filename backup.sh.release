#!/bin/bash
SRC="null"
DST="null"
INC="0"
TMP_DIR="/mnt/backupdir/"
OPT="-o ";
STORE_TIME=60; #Время хранения резервной копии в днях
if [ ! -n "$1" ]
then
    echo "Использование скрипта:";
    echo "данный скрипт не производит тщательной проверки"
    echo "правильности ввода пользователя будте внимательны";
    echo "Все ошибки записываются в файл лога в папке";
    echo "предназначенной для резервирования";
    echo "формат файла дата.архивируемая папка.log";
    echo "-d путь к папке для хранения архива (поддерживает архивирование по протаколу smb убедитесь что установлен пакет cifs-utils для debian)";
    echo "Для копирования по протоколу smb необходимо дополнительно указать ключ -o";
    echo "-s путь к архивируемой папке без последнего слеша";
    echo "-i при наличии этого ключа будет создоваться инкрементная копия для её создания необходим файл метаданых в архивируемой папке";
    echo "без него будет создана полная копия";
    echo "-o передача данных для подключения к удаленному серверу. Формат: -o user='login',pass='password";
fi

while [ -n "$1" ]; do
    case "$1" in
	-s) SRC="$2"
	    shift ;;
	-d) DST="$2"
	    shift ;;
	-i) INC="1";; 
	-o) OPT="$OPT$2";shift;;
    esac
    shift;
done
#echo "src = $SRC; 
#dst=$DST;
#inc=$INC; 
#otions=$OPT" 

LOG_FILE="$SRC/`date +%Y.%m.%d`.archive.log"


#echo "creating log file $LOG_FILE"; echo;echo;
touch "$SRC/`date +%Y.%m.%d`.archive.log"

if [ ${DST:0:2} = '//' ]; then #Если папка назначения начинается с "//" то пытаемся смонтировать сетевую папку
#    echo "destination folder on remote server";echo;echo;
    locate cifs > /dev/null; # Проверка на наличие пакета

    
    if [ $? -ne 0 ]; then # Если пакета нет пишем лог и выходим с ошибкой 101;
	echo "`date +"%Y.%m.%d  %H:%M:%S"` ERROR: cifs_utils not installed   Exit with 101 code" >> $LOG_FILE;
	exit 101;
    fi

    if [ ` test -d $TMP_DIR; echo $?` -ne 0 ]; then # Проверяем есть ли папка для монтирования, если нет создаем;
    
	mkdir -p /mnt/backupdir
    fi

    SRV=`echo $DST | cut -d / -f 3`;
#   echo "$SRV";echo;echo;
    ping $SRV -c 1 > /dev/null;

    if [ $? -ne 0 ]; then # Проверяем доступноть сервера, если не доступен пишем лог и выходим с ошибкой 102;
	echo "`date +"%Y.%m.%d  %H:%M:%S"` ERROR: host $SRV not available   Exit with 102 code" >> $LOG_FILE;
	exit 102;
    fi

    RES=`mount.cifs $DST $TMP_DIR $OPT; echo $?`;
    if [ $RES -ne 0 ]
    then
	echo "`date +"%Y.%m.%d  %H:%M:%S"` ERROR: mounting remote SMBfs on $SRV unsuccessfull   Exit with 103 code" >> $LOG_FILE;
	exit 103;
    fi 
    DST=$TMP_DIR;
fi
ARCH_NAME="$DST`date +%Y.%m.%d`.archive";

if [ ! -d "$SRC" ]
then
    echo "`date +"%Y.%m.%d  %H:%M:%S"` ERROR: Source folder not exist   Exit with 104 code" >> $LOG_FILE;
    exit 104
fi
if [ $INC -eq 1 ]
then
    CMD="tar -czg $SRC/archive.snar -f $ARCH_NAME.inc.gz $SRC --backup=numbered";
else
    if [ -f "$SRC/archive.snar" ]
    then
	rm -f "$SRC/archive.snar";
    fi
    CMD="tar czf $ARCH_NAME.full.gz $SRC -g $SRC/archive.snar ";
fi
$CMD;
wait;
find "$TMP_DIR" -mtime +$STORE_TIME -iname "*full.gz" -exec rm -f {} \;
find "$TMP_DIR" -mtime +$((STORE_TIME-7)) -iname "*inc.gz" -exec rm -f {} \;

if [ "$DST" = "$TMP_DIR" ]
then
    umount $TMP_DIR;
fi
#echo "done";
