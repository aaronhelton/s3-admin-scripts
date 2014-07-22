#!/bin/sh

# process arguments
usage() { echo "Usage: $0 [-c <s3 credentials file>] [-v <volume id>]" 1>&2; exit 1; }

while getopts ":c:v:" o; do
  case "${o}" in
    c)
      CREDENTIALS=${OPTARG}
      ;;
    v)
      VOLUME=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "${CREDENTIALS}" ] || [ -z "${VOLUME}" ]; then
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
logger "$0 - Beginning snapshot creation for $VOLUME"

# create snapshot
#/usr/bin/s3put -a $ID -s $KEY -b $BUCKET -p $SRCDIR -k $DESTDIR $NOWDATE-backup.tar.gz | logger
/opt/aws/bin/ec2-create-snapshot -O $ID -W $KEY -d "Backup of $VOLUME for $NOWDATE" $VOLUME
[ "$?" != "0" ] && logger "$0 - Snapshot creation for $VOLUME FAILED" || logger "$0 - Snapshot creation for $VOLUME SUCCEEDED"
