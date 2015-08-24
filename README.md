# DOCKER JENKINS
This folder contains the build for a docker image of jenkins with given plugins. Features include:
- Backing up and restoring of config from Amazon S3
- Includes docker, git, awscli
- Includes kubectl and restoration of corresponding config from encrypted file in Amazon S3
- Includes restoration of encrypted config for docker logins from encrypted file in Amazon S3

To automatically build and push a new version to your chosen docker repository from this folder run:
$ ./build_and_push.sh <repositoryname>/<username>/<reponame>:<tag>
e.g.
./build_and_push.sh quay.io/timgent/aws-jenkins:v0.5

# Syncing config from S3 bucket
Jenkins docker image. Jenkins configuration can be synced from AWS S3 bucket at
startup.

By default there is only one-way configuration sync, but you can set up a jenkins
job which syncs `${JENKINS_HOME}` to the same S3 bucket, so next time you start
this container you will have all your config loaded at startup time.

If `JENKINS_HOME_S3_BUCKET_NAME` is set, bucket config will be written out to
`/etc/jenkins-bucket-config`, which is used by
`/srv/jenkins/jenkins_backup.sh`. So you can just simply create a jenkins job
which runs the backup script.

Configuration is done using environment variables.

Authentication to S3 bucket can be passed in via `AWS_SECRET_ACCESS_KEY` and
`AWS_ACCESS_KEY_ID` or EC2 instance IAM role.

- `JENKINS_HOME` Default: `/var/lib/jenkins`. If you decide to change this,
  make sure you run docker container with `-v <new_jenkins_home>` set
- `JENKINS_HOME_S3_BUCKET_NAME` Default: unset. If unset, config sync will not run
- `JAVA_OPTS` Default: unset.
- `JENKINS_OPTS` Default: unset. Any valid jenkins parameter is supported

# Secrets
kubeconfig and docker login config syncing to S3 bucket are supported. You will need to encrypt and upload dockercfg and kubeconfig files to your chosen S3 buckets to enable this. For example to encrypt:

`aws kms encrypt --key-id xxxxxxx --plaintext "$(cat dockercfg)" --query CiphertextBlob --output text | base64 -d > dockercfg.encrypted`

Then upload to s3. The bucket name will need to be set as an environment variable SECRETS_BUCKET when the container is run.

# Enabling docker in docker
This container containers docker which enables it to execute docker commands using the host machines docker daemon. To enable this the docker socket will need to be mapped in as a volume to the container like:
-v /var/run/docker.sock:/var/run/docker.sock

# Running

```bash
docker run \
  -e AWS_SECRET_ACCESS_KEY=xxx \
  -e AWS_ACCESS_KEY_ID=xxx \
  -e JENKINS_HOME_S3_BUCKET_NAME=example-jenkinsconfig-us-east-1 \
  -e SECRETS_BUCKET=my_secrets_bucket \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 8080:8080 state/jenkins
```
