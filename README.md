# sven-hammerdb-benchmark
Benchmark on AWS Amazon RDS databases with HammerDB (TPROC-C, not a full TPC-C)

Please check out the blog-post at here:
https://svenbayer.wordpress.com

For references, check out https://www.hammerdb.com/ and https://www.hammerdb.com/blog/

For PostgreSQL installation, check out https://techviewleo.com/install-postgresql-12-on-amazon-linux/

# Installation
This repository is optimized for Amazon Linux 2 machines for AWS Cloud9 instances. You can run your benchmark from your Cloud9 instance.

Execute the install_dependencies.sh script. It will download HammerDB and install all necessary dependencies. Then, create an Amazon RDS database and add the Security Group of your Cloud9 instance to the Inbound Rules of the RDS's Security Group.

Then, create in the config folder a file called dbpassword.config and set **PG_SUPER_PASSWORD=** to your database's password. In your benchmark.config, enter the url, port, and username of your Amazon RDS instance. You should choose one virtual user per core of your RDS instance and 10-times as much warehouses. In VIRTUAL_USERS, you can specify the iterations of benchmarks you want to run. The variables for cleanup delete the HammerDB TPCC role and database. Also make sure to review the ramp-up time and benchmark duration time.
