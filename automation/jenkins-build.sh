#!/bin/bash

set -o errexit
set -o pipefail

version=$(cat compose/__init__.py| grep -Po "(?<=__version__ = ')[^']+")

for arch in $ARCHS; do
	dir=docker-compose-linux-$arch-$version

	mv Dockerfile.$arch Dockerfile
	./script/build/linux

	mkdir $dir
	cp dist/docker-compose-* $dir/docker-compose-linux-$arch
	tar -cvzf $dir.tar.gz $dir
	sha256sum $dir.tar.gz > $dir.tar.gz.sha256

	# Upload to S3 (using AWS CLI)
	printf "$ACCESS_KEY\n$SECRET_KEY\n$REGION_NAME\n\n" | aws configure
	aws s3 cp $dir.tar.gz s3://$BUCKET_NAME/docker-compose/$version/
	aws s3 cp $dir.tar.gz.sha256 s3://$BUCKET_NAME/docker-compose/$version/
	rm -rf $dir*
done
