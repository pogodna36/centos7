#!/bin/bash

REMOTE_HOST=ovh2
REMOTE_DIR=/var/backup/binlog
MYSQL_DIR=/var/lib/mysql/binlogs

mysql=$(which mysql)
mysqladmin=$(which mysqladmin)
lzop=$(which lzop)
scp=$(which scp)
rm=$(which rm)
head=$(which head)
tail=$(which tail)
basename=$(which basename)
xargs=$(which xargs)




# flush the binary logs so a new log file is opened:
$mysqladmin flush-logs

# kompresujemy wszystkie binlogi za wyjątkiem ostatniego w pliku binlog.index,
# czyli dopiero co utworzonego nowego binloga. Opcja -n -1 znaczy: wszystkie poza ostatnim.
$lzop $($head -n -1 $MYSQL_DIR/binlog.index | $xargs)

# usuwamy w bezpieczny sposób niepotrzebne binlogi poza tym nowym, ostatnim w pliku binlog.index
# Wyjaśnienie: PURGE BINARY LOGS TO 'mysql-bin.000223';
# oznacza: this will erase all binary logs before 'mysql-bin.000223'.
# Nazwy tych binlogów znikną również z pliku binlog.index
$mysql -e "PURGE MASTER LOGS TO '$($basename $($tail -n 1 $MYSQL_DIR/binlog.index))'"

# kopiujemy w bezpieczne miejsce spakowane binlogi, a następnie usuwamy pliki *.lzo
$scp $MYSQL_DIR/*.lzo root@$REMOTE_HOST:$REMOTE_DIR
$rm -f $MYSQL_DIR/*.lzo
