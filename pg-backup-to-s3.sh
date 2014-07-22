#!/bin/sh

# process arguments
usage() { echo "Usage: $0 [-c <s3 credentials file>] [-b <bucket>] [-s <source dir>] [-d <dest dir>] [-n <db name>] [-p <pgpass file>]" 1>&2; exit 1; }

while getopts ":c:b:s:d:n:p:" o; do
  case "${o}" in
    c)
      CREDENTIALS=${OPTARG}
      ;;
    b)
      BUCKET=${OPTARG}
      ;;
    s)
      SRCDIR=${OPTARG}
      ;;
    d)
      DESTDIR=${OPTARG}
      ;;
    n)
      DBNAME=${OPTARG}
      ;;
    p)
      PGPASS=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "${CREDENTIALS}" ] || [ -z "${BUCKET}" ] || [ -z "${SRCDIR}" ] || [ -z "${DESTDIR}" ] || [ -z "${DBNAME}" ] || [ -z "${PGPASS}" ]; then
  echo "Missing arguments"
  usage
fi

# set dates for backup rotation
NOWDATE=`date +%Y-%m-%d`

# check $CREDENTIALS for existence, non-emptiness, and permissions = 600
if ! [[ -e $CREDENTIALS ]] || ! [[ -s $CREDENTIALS ]] || [[ `find $CREDENTIALS -perm -004` ]]; then
  echo "Credentials file was either not found, found to be empty, or set with improper (i.e., world-readable) permissions.  Please make sure the file exists, contains information, and is set to rw-------.  Run chmod 600 $CREDENTIALS to set the permissions properly."
  echo " "
  usage
fi

# same thing with $PGPASS, even though the pg_dump command below will also anticipate this
if ! [[ -e $PGPASS ]] || ! [[ -s $PGPASS ]] || [[ `find $PGPASS -perm -004` ]]; then
  echo "File $PGPASS was either not found, found to be empty, or set with improper (i.e., world-readable) permissions.  Please make sure the file exists,
 contains information, and is set to rw-------.  Run chmod 600 $PGPASS to set the permissions properly."
  echo " "
  usage
fi

source $CREDENTIALS
if ! [[ $ID ]] && [[ $KEY ]]; then
  echo "Couldn't read credentials from $CREDENTIALS"
  usage
fi

# log the fact that we're starting
logger "Beginning daily backup of database"

# make the temp directory if it doesn't exist
mkdir -p $SRCDIR

pg_dump dspace -f $SRCDIR/$DBNAME.sql

# tar and zip all the databases into #NOWDATE-backups.tar.gz
cd $SRCDIR
tar czPf $NOWDATE-backup.tar.gz *.sql

# upload backup to S3
/usr/bin/s3put -a $ID -s $KEY -b $BUCKET -p $SRCDIR -k $DESTDIR $NOWDATE-backup.tar.gz | logger
[ "$?" != "0" ] && logger "$0 - Postgres database backup FAILED" || logger "$0 - Postgres database backup SUCCEEDED"

# remove temporary files
rm *.sql *.tar.gz
