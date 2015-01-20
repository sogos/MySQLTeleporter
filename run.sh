#!/bin/bash


MYSQL_SERVER_1_HOST=${MYSQL_SERVER_1_HOST}
MYSQL_SERVER_2_HOST=${MYSQL_SERVER_2_HOST}
MYSQL_SERVER_1_USERNAME=${MYSQL_SERVER_1_USERNAME}
MYSQL_SERVER_2_USERNAME=${MYSQL_SERVER_2_USERNAME}
MYSQL_SERVER_1_PASSWORD=${MYSQL_SERVER_1_PASSWORD}
MYSQL_SERVER_2_PASSWORD=${MYSQL_SERVER_2_PASSWORD}
MYSQL_DATABASE_SOURCE_NAME=${MYSQL_DATABASE_SOURCE_NAME}
MYSQL_DATABASE_TARGET_NAME=${MYSQL_DATABASE_TARGET_NAME}


if [ $MYSQL_SERVER_1_HOST = "null" ] || [ $MYSQL_SERVER_2_HOST = "null" ] || [ $MYSQL_SERVER_1_USERNAME = "null" ] || [ $MYSQL_SERVER_1_USERNAME = "null" ] || [ $MYSQL_SERVER_1_PASSWORD = "null" ] || [ $MYSQL_SERVER_2_PASSWORD = "null" ]  || [ $MYSQL_DATABASE_SOURCE_NAME = "null" ] || [ $MYSQL_DATABASE_TARGET_NAME = "null" ]; then
	echo "USAGE: You must provide all required arguments: "
	echo "	 -e MYSQL_SERVER_1_HOST=hostname_server_1"
	echo "	 -e MYSQL_SERVER_2_HOST=hostname_server_2 "
	echo "	 -e MYSQL_SERVER_1_USERNAME=username_server_1 "
	echo "	 -e MYSQL_SERVER_2_USERNAME=username_server_2 "
	echo "	 -e MYSQL_SERVER_1_PASSWORD=password_server_1 "
	echo "	 -e MYSQL_SERVER_2_PASSWORD=password_server_2 "
	echo "	 -e MYSQL_DATABASE_SOURCE_NAME=database_name_source"
	echo "	 -e MYSQL_DATABASE_TARGET_NAME=database_name_target"
	exit 1;
fi

echo "Testing Connections";
echo "==================";

echo ">>> Connecting to source server";
{
	mysql -u $MYSQL_SERVER_1_USERNAME --password="$MYSQL_SERVER_1_PASSWORD" --host=$MYSQL_SERVER_1_HOST -e ";"
} || {
	echo "Can't connect to server $MYSQL_SERVER_1_HOST with provided credentials";
	exit 1;
}
	echo ">>> Success";
echo ">>> Connecting to destination server";
{
	mysql -u $MYSQL_SERVER_2_USERNAME --password="$MYSQL_SERVER_2_PASSWORD" --host=$MYSQL_SERVER_2_HOST -e ";"
} || {
	echo "Can't connect to server $MYSQL_SERVER_2_HOST with provided credentials";
	exit 1;
}
	echo ">>> Success";

echo ">>> Check if source database exist";
DBEXISTS=$(mysql -u $MYSQL_SERVER_1_USERNAME --password="$MYSQL_SERVER_1_PASSWORD" --host=$MYSQL_SERVER_1_HOST --batch --skip-column-names -e "SHOW DATABASES LIKE '"$MYSQL_DATABASE_SOURCE_NAME"';" | grep "$MYSQL_DATABASE_SOURCE_NAME" > /dev/null; echo "$?")
if [ $DBEXISTS -eq 0 ];then
    echo "The source database with the name $MYSQL_DATABASE_SOURCE_NAME exists."
else
    echo "Source database $MYSQL_DATABASE_SOURCE_NAME does not exist."
    exit 1;
fi
echo "Creating temp folder";

if [ -d "/tmp/$MYSQL_DATABASE_SOURCE_NAME/structure" ] && [ -d "/tmp/$MYSQL_DATABASE_SOURCE_NAME/data" ]; then
	read -p "Do you want to use existing dump ? (y/n) " RESP
else 
	RESP="n"
fi
	mkdir -p /tmp/$MYSQL_DATABASE_SOURCE_NAME/structure/create
	mkdir -p /tmp/$MYSQL_DATABASE_SOURCE_NAME/structure/keys
	mkdir -p /tmp/$MYSQL_DATABASE_SOURCE_NAME/data
	cd /tmp/$MYSQL_DATABASE_SOURCE_NAME/structure

if [ "$RESP" = "n" ]; then

	echo ">>> Dumping all table Structure";

	for I in $(mysql -u $MYSQL_SERVER_1_USERNAME --password="$MYSQL_SERVER_1_PASSWORD" --host=$MYSQL_SERVER_1_HOST $MYSQL_DATABASE_SOURCE_NAME -e 'show tables' -s --skip-column-names $1);
		do
			echo "Dumping table structure for $I"
			mysqldump -u $MYSQL_SERVER_1_USERNAME --password="$MYSQL_SERVER_1_PASSWORD" --host=$MYSQL_SERVER_1_HOST --no-data $MYSQL_DATABASE_SOURCE_NAME $I >> "$I.sql";
			php /opt/extract_keys.php /tmp/$MYSQL_DATABASE_SOURCE_NAME/structure/$I.sql $I
			rm -fr $I.sql
		done
	echo ">>> Dumping all table Data";
	cd /tmp/$MYSQL_DATABASE_SOURCE_NAME/data
	for I in $(mysql -u $MYSQL_SERVER_1_USERNAME --password="$MYSQL_SERVER_1_PASSWORD" --host=$MYSQL_SERVER_1_HOST $MYSQL_DATABASE_SOURCE_NAME -e 'show tables' -s --skip-column-names $1);
		do
			echo "Dumping table data for $I"
			mysqldump -u $MYSQL_SERVER_1_USERNAME --password="$MYSQL_SERVER_1_PASSWORD" --host=$MYSQL_SERVER_1_HOST --no-create-db --no-create-info --skip-comments --single-transaction $MYSQL_DATABASE_SOURCE_NAME $I >> "$I.sql";
			gzip "$I.sql"
		done
else 
	echo "Using existing dump";
fi

echo ">>> Re-creating Table structure in Target Server";


for f in /tmp/$MYSQL_DATABASE_SOURCE_NAME/structure/create/*.sql

do
    echo ">>> Creating table from: $f"

    mysql -h ${MYSQL_SERVER_2_HOST} -u ${MYSQL_SERVER_2_USERNAME}  --password=${MYSQL_SERVER_2_PASSWORD} ${MYSQL_DATABASE_TARGET_NAME} < $f
    (( file_count++ ))
done
echo ">>> Inserting Table Data in Target Server";

for f in /tmp/$MYSQL_DATABASE_SOURCE_NAME/structure/data/*.sql.gz
do
    echo ">>> Inserting data from file: $f"

    gunzip < $f | mysql -h ${MYSQL_SERVER_2_HOST} -u ${MYSQL_SERVER_2_USERNAME}  --password=${MYSQL_SERVER_2_PASSWORD} ${MYSQL_DATABASE_TARGET_NAME}
    (( file_count++ ))
done

