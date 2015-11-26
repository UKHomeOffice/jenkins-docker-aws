#!/bin/bash

: ${JENKINS_HOME_S3_BUCKET_NAME:-}

jenkins_home_restore() {
  if [[ -n ${JENKINS_HOME_S3_BUCKET_NAME} ]]; then
    # persist jenkins config backup bucket
    echo "export JENKINS_HOME_S3_BUCKET_NAME=${JENKINS_HOME_S3_BUCKET_NAME}" > /etc/jenkins-bucket-config
    [[ -n ${AWS_SECRET_ACCESS_KEY} ]] && echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> /etc/jenkins-bucket-config
    [[ -n ${AWS_ACCESS_KEY_ID} ]] && echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> /etc/jenkins-bucket-config
    # Add config options so the backup script is not jenkins specific
    echo "export TAR_FILE=jenkins_home" >> /etc/jenkins-bucket-config
    echo "export FOLDER=jenkins_home" >> /etc/jenkins-bucket-config

    aws s3 cp s3://${JENKINS_HOME_S3_BUCKET_NAME}/jenkins_home/jenkins_home.tar.gz /tmp

    if [[ -f /tmp/jenkins_home.tar.gz ]]; then
      cd ${JENKINS_HOME}
      tar -xzf /tmp/jenkins_home.tar.gz
      rm -f /tmp/jenkins_home.tar.gz
      # Did they have a backup of the jenkins war if so lets use that it will be closer to the version they used
      if [[ -f jenkins.war ]]; then
        cp jenkins.war /usr/lib/jenkins/jenkins.war
      fi
    fi
  else
    echo 'Unable to restore existing jenkins configuration. JENKINS_HOME_S3_BUCKET_NAME is unset.'
  fi
}

download_secrets() {
  echo "Downloading secrets"
  mkdir /root/.secrets
  /opt/bin/s3secrets --region eu-west-1 --bucket ${SECRETS_BUCKET} --output-dir /root/.secrets
  echo "Secrets downloaded"
}

set_kubeconfig() {
  echo "Creating kubeconfig"
  mkdir /root/.kube
  cp /root/.secrets/kubeconfig /root/.kube/config
  echo "Kubeconfig created successfully"
}

set_quay_login() {
  echo "Creating docker login for quay.io"
  mkdir /root/.docker
  cp /root/.secrets/dockercfg /root/.docker/config.json
  echo "Docker login for quay.io created successfully"
}

# Allow to pass in jenkins options after --
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  if [ -n "$SECRETS_BUCKET" ]; then
    download_secrets
    set_kubeconfig
    set_quay_login
  else
    echo "No secrets bucket specified, will use mapped volumes if present"
  fi
  jenkins_home_restore

  if [[ $? -eq 0 ]]; then
    exec java ${JAVA_OPTS} -jar /usr/lib/jenkins/jenkins.war ${JENKINS_OPTS} "$@"
  fi
fi

# If number of args is more than 1 and no jenkins options are given, start
# given command instead
exec "$@"
