# MySQLTeleporter

Base Image: debian:wheezy

Transfer an MySQL database from a Running Instance to an another, optimized for InnoDB transfer (re-create keys at end)

Todo: 

- Allow to run restoration from an existing DUMP
- Allow to only make a DUMP


Step 1: Build the Container

```
docker build -t="sogos/MySQLTeleporter" github.com/sogos/MySQLTeleporter
```

Step 2: Run the Container (you can use -d too if you don't have a current DUMP)

```
docker run  -t -i \
          -e MYSQL_SERVER_1_HOST=bdd_host_1 -e MYSQL_SERVER_2_HOST=bdd_host_2 \
          -e MYSQL_SERVER_1_USERNAME=root -e MYSQL_SERVER_2_USERNAME=root \
          -e MYSQL_SERVER_1_PASSWORD=XXXXX  -e MYSQL_SERVER_2_PASSWORD=YYYYY \
          -e MYSQL_DATABASE_SOURCE_NAME=blog -e MYSQL_DATABASE_TARGET_NAME=blog \
          sogos/mysqlteleporter
```

Optionally: Persist DUMP (
```
docker run  -t -i \
          -v /local_volumes/MySQLTeleporter:/tmp \
          -e MYSQL_SERVER_1_HOST=bdd_host_1 -e MYSQL_SERVER_2_HOST=bdd_host_2 \
          -e MYSQL_SERVER_1_USERNAME=root -e MYSQL_SERVER_2_USERNAME=root \
          -e MYSQL_SERVER_1_PASSWORD=XXXXX  -e MYSQL_SERVER_2_PASSWORD=YYYYY \
          -e MYSQL_DATABASE_SOURCE_NAME=blog -e MYSQL_DATABASE_TARGET_NAME=blog \
          sogos/mysqlteleporter
```

