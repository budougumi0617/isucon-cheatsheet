#!/bin/bash -eu

# https://github.com/south37/isucon-settings/blob/f8b64a78b59c0fb1ba7cab39cd0a55862c6edb4a/scripts/check_mysql.sh

# DB_USER=root
# DB_PW=root
# DB_NAME=

if [ "$DB_PW" = "" ] || [ "$DB_USER" = "" ] || [ "$DB_NAME" = "" ] ; then
  echo "Fatal: DB_PW or DB_USER or DB_NAME is not set."
  echo ""
  echo "Usage: DB_USER=root DB_PW=root DB_NAME=isuketch check_mysql.sh"
  exit 1
fi

echo "\n\n## データベース一覧"
mysql -u$DB_USER -p$DB_PW -e "SHOW DATABASES";


echo "\n\n## テーブル一覧"
for i in $(mysql -u$DB_USER -p$DB_PW -D$DB_NAME -e 'SHOW TABLES' | grep -v "Tables_in" | awk '{print $1}')
do
  echo "\n\nTable: $i"
  mysql -u$DB_USER -p$DB_PW -D$DB_NAME -e "DESC $i"
done


echo "\n\n## 各テーブルの容量"
mysql -u $DB_USER -p$DB_PW $DB_NAME -e "SELECT table_name, engine, table_rows, avg_row_length, floor((data_length+index_length)/1024/1024) as allMB, floor((data_length)/1024/1024) as dMB, floor((index_length)/1024/1024) as iMB FROM information_schema.tables WHERE table_schema=database() ORDER BY (data_length+index_length) DESC;"


echo "\n\n## インデックス一覧"
for i in $(mysql -u$DB_USER -p$DB_PW -D$DB_NAME -e 'SHOW TABLES' | grep -v "Tables_in" | awk '{print $1}')
do
  echo "\n\nTable: $i"
  mysql -u$DB_USER -p$DB_PW -D$DB_NAME -e "SHOW INDEX FROM $i"
done