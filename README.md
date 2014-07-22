s3-admin-scripts
================

Administration scripts for use with S3 in some specific conditions.

nightly-snapshot.sh is a script that makes EBS snapshots, especially for use with cron jobs.  If there was already a way to do this, I wasn't able to find it right off.  You need credentials that allow the creation of snapshots.

Usage: nightly-snapshot.sh -c < s3 credentials file > -v < volume id >

Example: nightly-snapshot.sh -c ~/.secret/.credentials -v vol-nnnnnnnn


pg-backup-to-s3.sh is more complicated.  It makes PostgreSQL database backups and pushes them to an S3 bucket.  It can be scheduled with cron as well.  You need two sets of credentials with this script: AWS credentials with permission to add objects to the specified bucket and the PostgreSQL database username and password for the database you want to backup.

Usage: pg-backup-to-s3.sh -c < s3 credentials file > -b < bucket > -s < source dir > -d < dest dir > -n < db name > -p < pgpass file >

Example: pg-backup-to-s3.sh -c ~/.secret/.credentials -b my-bucket -s /tmp/backups -d /database-backups -n my_database -p ~/.secret/.pgpass
