# Reproducing Upload Failure

NOTE: you'll need `docker`

In one terminal run `./minio.sh` which spins up minio in a docker container attached to port `4570` with credentials:

- access key: dummykey
- secret key: dummysecret

Edit `app.sh` to run either the aws or localhost (minio) version. 

To run against real AWS you'll need to configure the bucket and credentials properly

In a separate terminal run `./app.sh` which runs a docker container containing a small haskell app which uploads a file to minio (or aws)

You should see that it succeeds to upload to your real s3 instance and hangs indefinitely on minio
