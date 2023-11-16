<pre>
# s3crude

List buckets in a namespace
================================
PS /home/kevin> $bucketsResponse = ./s3crude.ps1 -ecsHost ecs.cuntos.com -httpOrHttps https -ecsPort 9021 -requestUri / -requestType GET                    
PS /home/kevin> $bucketsResponse.ListAllMyBucketsResult.Buckets.Bucket                                                                  

Name    CreationDate             ServerSideEncryptionEnabled
....    ............             ...........................
bucket1 2023-11-15T21:51:01.062Z false
bucket2 2023-11-15T22:01:42.544Z false


List objects in a bucket
==============================
PS /home/kevin> $objectsResponse = ./s3crude.ps1 -ecsHost ecs.cuntos.com -httpOrHttps https -ecsPort 9021 -requestUri /bucket1 -requestType GET                            
PS /home/kevin> $objectsResponse.ListBucketResult.Contents                                                                                     

Key          : c8000v-universalk9.17.09.03a.ova
LastModified : 2023-11-15T21:58:44.564Z
ETag         : "61723976c302d4879551d4f750d2c30b"
Size         : 925788160
StorageClass : STANDARD
Owner        : Owner

Key          : paping_1.5.5_x86-64_linux.tar.gz
LastModified : 2023-11-15T21:56:58.430Z
ETag         : "951c5c76f5c94e5a7289f1064fada80a"
Size         : 8962
StorageClass : STANDARD
Owner        : Owner


Get bucket ACL
====================
PS /home/kevin> $bucketAclResponse = ./s3crude.ps1 -ecsHost ecs.cuntos.com -httpOrHttps https -ecsPort 9021 -requestUri /bucket1?acl -requestType GET
PS /home/kevin> $bucketAclResponse.AccessControlPolicy.AccessControlList.Grant.Grantee                                                               

xsi                                       type          ID         DisplayName
...                                       ....          ..         ...........
http://www.w3.org/2001/XMLSchema-instance CanonicalUser objectuser objectuser

PS /home/kevin> $bucketAclResponse.AccessControlPolicy.AccessControlList.Grant.Permission
FULL_CONTROL


Get object ACL
===================
PS /home/kevin> $objectAclResponse = ./s3crude.ps1 -ecsHost ecs.cuntos.com -httpOrHttps https -ecsPort 9021 -requestUri /bucket2/testfile?acl -requestType GET
PS /home/kevin> $objectAclResponse.AccessControlPolicy.AccessControlList.Grant.Grantee                                                                        

xsi                                       type          ID         DisplayName
...                                       ....          ..         ...........
http://www.w3.org/2001/XMLSchema-instance CanonicalUser objectuser objectuser

PS /home/kevin> $objectAclResponse.AccessControlPolicy.AccessControlList.Grant.Permission
FULL_CONTROL


Upload an object to a bucket
==================================
PS /home/kevin> ./s3crude.ps1 -ecsHost ecs.cuntos.com -httpOrHttps https -ecsPort 9021 -requestUri /bucket2/azcopy_linux_amd64_10.15.0.tar.gz -requestType PUT -uploadFile ./azcopy_linux_amd64_10.15.0.tar.gz   

PS /home/kevin>


Download an object from a bucket
===================================
PS /home/kevin> ./s3crude.ps1 -ecsHost ecs.cuntos.com -httpOrHttps https -ecsPort 9021 -requestUri /bucket2/testfile -requestType GET -downloadFile testfile    
PS /home/kevin>

</pre>
