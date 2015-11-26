#!/bin/bash

# these can be overridden in the jenkins-bucket-config
export NUM_BACKUPS=10
export TAR_FILE=jenkins_home
export FOLDER=jenkins_home

source /etc/jenkins-bucket-config

if [[ -n ${JENKINS_HOME_S3_BUCKET_NAME} ]]; then
  cd ${JENKINS_HOME}
  # Back up jenkins warfile
  cp /usr/lib/jenkins/jenkins.war .

  tar --exclude 'jobs/*/builds/*/archive' --exclude 'cache/*' --exclude '.gradle/*' --exclude 'war/*' --exclude 'workspace/*' -czf /tmp/${TAR_FILE}.tar.gz .

  if [[ -f /tmp/${TAR_FILE}.tar.gz ]]; then
    # move around the backups
    set +e
    for i in `seq ${NUM_BACKUPS} -1 2`; do
      PREV=`expr ${i} - 1`
      aws s3 mv --quiet s3://${JENKINS_HOME_S3_BUCKET_NAME}/${FOLDER}/${TAR_FILE}-${PREV}.tar.gz s3://${JENKINS_HOME_S3_BUCKET_NAME}/${FOLDER}/${TAR_FILE}-${i}.tar.gz
    done
    aws s3 mv s3://${JENKINS_HOME_S3_BUCKET_NAME}/${FOLDER}/${TAR_FILE}.tar.gz s3://${JENKINS_HOME_S3_BUCKET_NAME}/${FOLDER}/${TAR_FILE}-1.tar.gz
    set -e
    aws s3 cp /tmp/${TAR_FILE}.tar.gz s3://${JENKINS_HOME_S3_BUCKET_NAME}/${FOLDER}/${TAR_FILE}.tar.gz
  fi
else
  echo 'Unable to backup existing jenkins configuration. JENKINS_HOME_S3_BUCKET_NAME is unset.'
fi
