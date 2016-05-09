#!/bin/bash

: ${JENKINS_HOME_S3_BUCKET_NAME:-}

jenkins_home_restore() {
  if [[ -n ${JENKINS_HOME_S3_BUCKET_NAME} ]]; then
    # persist jenkins config backup bucket
    echo "export JENKINS_HOME_S3_BUCKET_NAME=${JENKINS_HOME_S3_BUCKET_NAME}" > /etc/jenkins-bucket-config
    [[ -n ${AWS_SECRET_ACCESS_KEY} ]] && echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> /etc/jenkins-bucket-config
    [[ -n ${AWS_ACCESS_KEY_ID} ]] && echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> /etc/jenkins-bucket-config

    aws s3 cp s3://${JENKINS_HOME_S3_BUCKET_NAME}/jenkins_home/jenkins_home.tar.gz /tmp

    if [[ -f /tmp/jenkins_home.tar.gz ]]; then
      cd ${JENKINS_HOME}
      tar -xzf /tmp/jenkins_home.tar.gz
      rm -f /tmp/jenkins_home.tar.gz
    fi
  else
    echo 'Unable to restore existing jenkins configuration. JENKINS_HOME_S3_BUCKET_NAME is unset.'
  fi
}

download_secrets() {
  echo "Downloading secrets"
  mkdir /root/.secrets
  /opt/bin/s3secrets --region eu-west-1 s3 get -b ${SECRETS_BUCKET} -d /root/.secrets /
  echo "Secrets downloaded"
}

set_kubeconfig() {
  if [[ -f /root/.secrets/kubeconfig ]]; then
    echo "Creating kubeconfig"
    mkdir /root/.kube
    cp /root/.secrets/kubeconfig /root/.kube/config
    echo "Kubeconfig created successfully"
  fi
}

set_docker_login() {
  if [[ -f /root/.secrets/config.json ]]; then
    echo "Creating docker login"
    mkdir /root/.docker
    cp /root/.secrets/config.json /root/.docker/config.json
    echo "Docker login created successfully"
  fi
}

# Allow to pass in jenkins options after --
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  if [ -n "$SECRETS_BUCKET" ]; then
    download_secrets
    set_kubeconfig
    set_docker_login
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
