## Quick cheat sheet for using s3curl
# Read below for more information including credential setup
# https://github.com/rtdp/s3curl/blob/master/README
# README seemingly leaves this out but any non-AWS S3 custom endpoints also need to be added to the 'endpoints' array in 's3curl.pl' itself.
# Perhaps script was mainly developed for AWS S3 users not for ECS.

# List buckets
([xml](./s3curl.pl --id=srozanc_svc -- https://mcs-ecs.intellicentre.net.au:9021/ -s | xmllint --format -)).ListAllMyBucketsResult.Buckets.Bucket

# Create bucket
./s3curl.pl --id=srozanc_svc --createBucket -- https://mcs-ecs.intellicentre.net.au:9021/kdogs -s

# Upload object
./s3curl.pl --id=srozanc_svc --put ../paping_1.5.5_x86-64_linux.tar.gz -- https://mcs-ecs.intellicentre.net.au:9021/kdogs/paping_1.5.5_x86-64_linux.tar.gz -s

# List bucket contents
([xml](./s3curl.pl --id=srozanc_svc -- https://mcs-ecs.intellicentre.net.au:9021/kdogs -s)).ListBucketResult.Contents

# Download object
./s3curl.pl --id=srozanc_svc -- https://mcs-ecs.intellicentre.net.au:9021/kdogs/paping_1.5.5_x86-64_linux.tar.gz -o ./paping_1.5.5_x86-64_linux.tar.gz -s

# Output object to stdout (don't run on binary file, text file only).
./s3curl.pl --id=srozanc_svc -- https://mcs-ecs.intellicentre.net.au:9021/kdogs/testfile -s

# Output bucket or object ACL

# In pretty XML format
./s3curl.pl --id=srozanc_svc -- https://mcs-ecs.intellicentre.net.au:9021/kdogs?acl -s | xmllint --format -
./s3curl.pl --id=srozanc_svc -- https://mcs-ecs.intellicentre.net.au:9021/kdogs/testfile?acl -s | xmllint --format -

# Or if you want to get more fancy
([xml](./s3curl.pl --id=srozanc_svc -- https://mcs-ecs.intellicentre.net.au:9021/chump?acl -s)).AccessControlPolicy.AccessControlList.Grant | Select-Object `
@{Name="ACL Assignee"; Expression={$_.Grantee.ID}},`
@{Name="Permission Granted"; Expression={$_.Permission}}

# Retrieve ACL owner
([xml](./s3curl.pl --id=srozanc_svc -- https://mcs-ecs.intellicentre.net.au:9021/chump?acl -s)).AccessControlPolicy.Owner

# Update bucket or object ACL. In this example we take the ACL of the 'chump' bucket and use it to update the ACL for the 'kdogs' bucket
$chumpAcl = ./s3curl.pl --id=srozanc_svc -- https://mcs-ecs.intellicentre.net.au:9021/chump?acl -s
$chumpAcl | Out-File chumpAcl.txt
./s3curl.pl --id=srozanc_svc --put=chumpAcl.txt -- https://mcs-ecs.intellicentre.net.au:9021/kdogs?acl -s