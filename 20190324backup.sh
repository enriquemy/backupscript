#!/bin/bash

##########################################################
#
# This script takes a backup of a filesystem in a S3 bucket
#
##########################################################

# nbr days to keep backup and log files
RETENTION_TIME=7

BACKUP_DATA_ROOT_FILENAME=S3backup_data
BACKUP_LOG_ROOT_FILENAME=backuplog
BACKUP_CHECKSUM_ROOT_FILENAME=sha1genresult

BACKUP_ROOT=/root/backup
BACKUP_LOGS=$BACKUP_ROOT/log

BACKUP_SRC_BUCKET=/s3-drive-source
BACKUP_DST_BUCKET=/s3-drive-destination
BACKUP_DST_ROOT_FOLDER=backups


####################################################################
#
# Current date and FQHN are used to generate file names
#
####################################################################

###### Get current date

DATE=`date  +"%Y_%m_%d_%T"`
DATE=${DATE//:/}
echo $DATE

BACKUP_DST_FILENAME=$BACKUP_DST_BUCKET/$BACKUP_DST_ROOT_FOLDER/$BACKUP_DATA_ROOT_FILENAME.$DATE.zip
echo $BACKUP_DST_FILENAME

BACKUP_LOG_FILENAME=$BACKUP_LOGS/$BACKUP_LOG_ROOT_FILENAME.$DATE.txt
echo $BACKUP_LOG_FILENAME

CHECKSUM_FILENAME=$BACKUP_LOGS/$BACKUP_CHECKSUM_ROOT_FILENAME.$DATE.txt
echo $CHECKSUM_FILENAME


############# CREATE BACKUP DIRECTORY STRUCTUE ###########################

# if the directory does not exist create it
if [ ! -d $BACKUP_LOGS ] ; then
        mkdir -p $BACKUP_LOGS
        echo `date` No backup log folder: creating one... >> $BACKUP_LOG_FILENAME
fi

echo $BACKUP_LOGS

# if the directory does not exist create it
if [ ! -d $BACKUP_DST_BUCKET/$BACKUP_DST_ROOT_FOLDER ] ; then
        mkdir -p $BACKUP_DST_BUCKET/$BACKUP_DST_ROOT_FOLDER
        echo `date` No backup data folder: creating one... >> $BACKUP_LOG_FILENAME
fi

echo $BACKUP_DST_BUCKET/$BACKUP_DST_ROOT_FOLDER


echo `date` Backup Start >> $BACKUP_LOG_FILENAME

##################################################################################
#
#  B A C K U P      S T A R T
#
##################################################################################

# 7za a $BACKUP_DST_FILENAME $BACKUP_SRC_BUCKET >> $BACKUP_LOG_FILENAME

/usr/src/7zip/p7zip_16.02/bin/7za a $BACKUP_DST_FILENAME $BACKUP_SRC_BUCKET >> $BACKUP_LOG_FILENAME


##################################################################################
#
#  C O N F I R M   A R C H I V E   E X I S T
#
##################################################################################
if [ -f "$BACKUP_DST_FILENAME" ];
then
   echo "File $FILE created."
   echo "File $FILE created." | mail -s "$DATE backup status" enriquevcfd@gmail.com
   echo `date` $FILE created >> $BACKUP_LOG_FILENAME
else
   echo "File $FILE creation FAILED."
   echo "File $FILE creation FAILED." | mail -s "$DATE backup status" enriquevcfd@gmail.com
   echo `date` $FILE creation FAILED >> $BACKUP_LOG_FILENAME
fi


###############################################################
#
#            Create checksum integrity check
#
###############################################################

echo `date` Start checksum integrity verifier >> $BACKUP_LOG_FILENAME

sha1sum $BACKUP_DST_FILENAME > $CHECKSUM_FILENAME

echo `date` End backup checksum integrity verifier >> $BACKUP_LOG_FILENAME

#################################################################
#
# PURGE FILES OKDER TAHAN 7 DAYS
#
#################################################################
echo 'PURGE'
echo `date` Start purge files >> $BACKUP_LOG_FILENAME

find $BACKUP_LOGS/$BACKUP_LOG_ROOT_FILENAME*.txt -mtime +$RETENTION_TIME -exec /usr/bin/rm '{}' \;

find $BACKUP_LOGS/$BACKUP_CHECKSUM_ROOT_FILENAME*.txt -mtime +$RETENTION_TIME -exec /usr/bin/rm '{}' \;

find $BACKUP_DST_BUCKET/$BACKUP_DST_ROOT_FOLDER/$BACKUP_DATA_ROOT_FILENAME*.zip -mtime +$RETENTION_TIME -exec /usr/bin/rm '{}' \;

echo `date` End purge files >> $BACKUP_LOG_FILENAME

echo `date` End backup  >> $BACKUP_LOG_FILENAME


