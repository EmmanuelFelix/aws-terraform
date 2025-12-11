Outputs:

connect_command = "psql -h my-terraform-rds.c2bmo8w843yh.us-east-1.rds.amazonaws.com -p 5432 -U dbadmin -d mydb"
rds_hostname = "my-terraform-rds.c2bmo8w843yh.us-east-1.rds.amazonaws.com"
rds_port = 5432
rds_username = "dbadmin"

ladmin@workstation-linux:~/aws/RDS$ psql -h my-terraform-rds.c2bmo8w843yh.us-east-1.rds.amazonaws.com -p 5432 -U dbadmin -d mydb
Password for user dbadmin: 
psql (16.10 (Ubuntu 16.10-0ubuntu0.24.04.1), server 16.3)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

mydb=>