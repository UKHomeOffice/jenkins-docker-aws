#!/bin/bash

source /etc/jenkins-bucket-config

if [[ -n ${JENKINS_HOME_S3_BUCKET_NAME} ]]; then
  cd ${JENKINS_HOME}
  tar --exclude 'war/*' --exclude 'workspace/*' -czf /tmp/jenkins_home.tar.gz .

  if [[ -f /tmp/jenkins_home.tar.gz ]]; then
    aws s3 cp /tmp/jenkins_home.tar.gz s3://${JENKINS_HOME_S3_BUCKET_NAME}/jenkins_home/
  fi
else
  echo 'Unable to backup existing jenkins configuration. JENKINS_HOME_S3_BUCKET_NAME is unset.'
fi

