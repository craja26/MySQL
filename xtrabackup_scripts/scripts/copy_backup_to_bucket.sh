#!/bin/bash

BACKUPHOME="/backup/mysql_backup"
BUCKET="gs://<bucket name>"
HOST=$(hostname -s)

echo  gsutil -m rsync -r  "$BACKUPHOME"  "$BUCKET/$HOST"/
gsutil -m rsync -r "$BACKUPHOME"  "$BUCKET/$HOST"/
exit

