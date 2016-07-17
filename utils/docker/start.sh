#!/bin/bash

# Prepare proper amount of shared memory
umount /dev/shm
mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime,size=4096M tmpfs /dev/shm

# Start MySQL
/usr/bin/mysqld_safe &

# Give MySQL time to wake up
SECONDS_LEFT=120
while true; do
  sleep 1
  mysqladmin ping
  if [ $? -eq 0 ];then
    break; # Success
  fi
  let SECONDS_LEFT=SECONDS_LEFT-1

  # If we have waited >120 seconds, give up
  # ZM should never have a database that large!
  # if $COUNTER -lt 120
  if [ $SECONDS_LEFT -eq 0 ];then
    return -1;
  fi
done

service apache2 start

# Start ZoneMinder
/usr/local/bin/zmpkg.pl start

tail -f /var/log/apache2/*
