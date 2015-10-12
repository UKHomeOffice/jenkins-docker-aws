#!/bin/bash

source /etc/jenkins-bucket-config

if [[ -n ${JENKINS_HOME_S3_BUCKET_NAME} ]]; then
  cd ${JENKINS_HOME}
  tar --exclude 'war/*' --exclude 'workspace/*' -czf /tmp/jenkins_home.tar.gz .

  if [[ -f /tmp/jenkins_home.tar.gz ]]; then
    # Do the copy to a new location so interruptions during copy don't corrupt existing backup
    aws s3 cp /tmp/jenkins_home.tar.gz s3://${JENKINS_HOME_S3_BUCKET_NAME}/jenkins_home_latest/
    aws s3 mv s3://${JENKINS_HOME_S3_BUCKET_NAME}/jenkins_home_latest s3://${JENKINS_HOME_S3_BUCKET_NAME}/jenkins_home --recursive
  fi
else
  echo 'Unable to backup existing jenkins configuration. JENKINS_HOME_S3_BUCKET_NAME is unset.'
fi
