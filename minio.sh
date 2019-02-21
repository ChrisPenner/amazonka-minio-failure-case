#!/bin/sh
docker run -p 127.0.0.1:4570:9000 -e MINIO_ACCESS_KEY=dummykey -e MINIO_SECRET_KEY=dummysecret minio/minio:RELEASE.2019-02-20T22-44-29Z server /tmp
