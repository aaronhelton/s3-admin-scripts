#!/bin/sh

# process arguments
usage() { echo "Usage: $0 [-c <s3 credentials file>] [-b <bucket>] [-s <source dir>] [-d <dest dir>]" 1>&2; exit 1; }

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
    *)
      usage
      ;;
  esac
done

if [ -z "${CREDENTIALS}" ] || [ -z "${BUCKET}" ] || [ -z "${SRCDIR}" ] || [ -z "${DESTDIR}" ]; then
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

source $CREDENTIALS
if ! [[ $ID ]] && [[ $KEY ]]; then
  echo "Couldn't read credentials from $CREDENTIALS"
  usage
fi

# log the fact that we're starting
logger "Beginning daily backup of $SRCDIR"

SRCNAME=`sed 's/\//_/g' <<< $SRCDIR`
TMPDIR="/dspace-ext/tmp/fs-backup-$SRCNAME"

# make the temp directory if it doesn't exist
mkdir -p $TMPDIR

# tar and zip all the databases into #NOWDATE-backups.tar.gz
cd $SRCDIR
FNAME=$TMPDIR/$NOWDATE-backup.tar.gz
tar czPf $FNAME $SRCDIR

# upload backup to S3
/usr/bin/s3put -a $ID -s $KEY -b $BUCKET -p $TMPDIR -k $DESTDIR $FNAME | logger
[ "$?" != "0" ] && logger "$0 - Backup of $SRCDIR FAILED" || logger "$0 - Backup of $SRCDIR SUCCEEDED"

