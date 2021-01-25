#!/bin/bash
SRC="null"
DST="null"
INC="0"
TMP_DIR="/mnt/backupdir/"
OPT="-o ";
STORE_TIME=60; #Время хранения резервной копии в днях
if [ -z "$1" ]
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
    exit 0;
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
done;

LOG_FILE="$(echo $SRC | sed -e 's/^\(.*\)\/$/\1/')/$(date +%Y.%m.%d).$(basename $SRC).log" 
###################################################################################################################
#"creating log file $LOG_FILE"; echo;echo;
touch "$LOG_FILE"
#Если папка назначения начинается с "//" то пытаемся смонтировать сетевую папку
if [ "${dst:0:2}" = '//' ]; then 
    # Проверка на наличие пакета
    #locate cifs > /dev/null;     
    if [ ! "$(locate pirates > /dev/null && echo $?)" ]; then 
        # Если пакета нет пишем лог и выходим с ошибкой 101;
        printf "%s ERROR: cifs_utils not installed   Exit with 101 code
        if you get code after install packeges update locate's database /n"  "$(date +"%Y.%m.%d  %H:%M:%S")" >> $LOG_FILE;
        exit 101;
    fi
    # Проверяем есть ли папка для монтирования, если нет создаем;
    if [ ! -d "$TMP_DIR" ]; then 
        
        mkdir -p "$TMP_DIR";
    fi
    
    SRV="$(echo $DST | cut -d / -f 3)";
    #ping "$SRV" -c 1 > /dev/null;
    # Проверяем доступноть сервера, если не доступен пишем лог и выходим с ошибкой 102;
    if [ ! "$(ping "$SRV" -c 1 > /dev/null && echo $?)" ]; then 
        echo "$(date +"%Y.%m.%d  %H:%M:%S") ERROR: host $SRV not available   Exit with 102 code" >> $LOG_FILE;
        exit 102;
    fi
    #MOUNT="mount.cifs $DST $TMP_DIR $OPT; echo $?";
    mount.cifs "$DST" "$TMP_DIR" "$OPT"
    RES=$?;
    echo "$RES"
    if [ "$RES" -ne 0 ]; then
        echo "$(date +"%Y.%m.%d  %H:%M:%S") ERROR: mounting remote SMB FS on $SRV unsuccessfull(error code $RES) Exit with 103 code" >> $LOG_FILE;
        exit 103;
    fi
    DST=$TMP_DIR;
fi
ARCH_NAME="$DST/$(date +%Y.%m.%d).$(basename $SRC).tar.gz";
#echo "$ARCH_NAME"
if [ ! -d "$SRC" ]; then
    echo "$(date +"%Y.%m.%d  %H:%M:%S") ERROR: Source folder not exist   Exit with 104 code" >> "$LOG_FILE";
    exit 104
fi
export LOG_FILE;
if [ $INC -eq 1 ]; then
    CMD="tar -czv -f $ARCH_NAME.inc.gz --backup=numbered -g $SRC/archive.snar --exclude '*.log'  --exclude '*.snar' $SRC";
else
    if [ -f "$SRC/archive.snar" ]; then
        rm -f "$SRC/archive.snar";
    fi
    CMD="tar czfv $ARCH_NAME.full.gz -g $SRC/archive.snar --exclude '*.log' --exclude '*.snar'  $SRC ";
fi
"$CMD" >> "$LOG_FILE";
wait;
find "$TMP_DIR" -mtime + "$STORE_TIME" -iname "*full.gz" -exec rm -f {} \;
find "$TMP_DIR" -mtime +$((STORE_TIME-7)) -iname "*inc.gz" -exec rm -f {} \;
find "$SRC" -mtime +$((STORE_TIME-7)) -iname "*.log" -exec rm -f {} \;

if [ "$DST" = "$TMP_DIR" ]
then
    umount "$TMP_DIR";
fi
echo "done" >> "$LOG_FILE";
