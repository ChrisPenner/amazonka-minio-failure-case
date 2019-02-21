#!/bin/sh

# Upload file.txt to dummybucket/out.txt via minio at localhost:4570
docker run quay.io/chris_wire/amazonka_failure:latest host localhost 4570 file.txt dummybucket out.txt

# Upload file.txt to s3://dummybucket/out.txt using provided credentials
# docker run quay.io/chris_wire/amazonka_failure:latest \
    # -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
#     -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
#     -e AWS_REGION="$AWS_REGION" \
#     aws file.txt dummybucket out.txt
