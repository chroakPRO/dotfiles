#!/bin/bash
backup_location="/k8s_storage/db_backup"
user="backupuser"
pass="backauppmig"
db="iptables"
date=`date +%Y-%m-%d_%H:%M`
retention_days=30
function dobackup {

    mkdir -p $backup_location

    current_pod=`/snap/bin/kubectl get pods -n peelsense | grep 'peelsense-db' | awk '{print $1}'`

    /snap/bin/kubectl exec -it $current_pod -n peelsense -- mysqldump -u $user -p$pass $db > $backup_location/$db-$date.sql

    gzip -c $backup_location/$db-$date.sql > $backup_location/$db-$date.sql.gz

    rm $backup_location/$db-$date.sql
}

function cleanold {
       find $backup_location -type f -mtime +$retention_days -exec rm -f {} \;
}

dobackup
cleanold
