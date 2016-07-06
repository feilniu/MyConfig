# vim:fdm=marker:
import mysql.connector
import sys
import os

def Help():#{{{
    print('''
NAME
    {0} - 生成MySQL数据库的数字字典

    生成结果为Confluence Wiki Markup，输出到stdout

USAGE
    {0} server database user password

EXAMPLE
    {0} localhost testdb dev devtest
    {0} localhost testdb dev devtest > testdb.cwiki
    {0} localhost testdb dev devtest | putclip
'''.format(os.path.basename(sys.argv[0])))
    sys.exit()
#}}}

if len(sys.argv) != 5:
    Help()

config = {
        'host': sys.argv[1],
        'database': sys.argv[2],
        'user': sys.argv[3],
        'password': sys.argv[4],
        'raise_on_warnings': True }
# 更多参数详见：http://dev.mysql.com/doc/connector-python/en/connector-python-connectargs.html

print('''h1. 说明
----
{excerpt}摘要{excerpt}
其它说明

h1. 数据库对象列表
----
{toc:minLevel=2}

h2. 表
----''')

cnx = mysql.connector.connect(**config)
cursor = cnx.cursor()

sql_GetAllTableNames = '''
SELECT TABLE_NAME, TABLE_COMMENT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;'''
sql_GetColumnInfoByTableName = '''
SELECT COLUMN_NAME, ORDINAL_POSITION, COLUMN_DEFAULT, IS_NULLABLE, COLUMN_TYPE, COLUMN_KEY, EXTRA, COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = %(TableName)s
ORDER BY ORDINAL_POSITION;'''

cursor.execute(sql_GetAllTableNames)

TableNames = cursor.fetchall()

for item in TableNames:
    print('\nh3. {} - {}'.format(*item))
    cursor.execute(sql_GetColumnInfoByTableName, {'TableName' : item[0]})
    print('|| 字段名 || 类型 || 可空 || 默认值 || KEY || EXTRA || 备注 ||')
    for row in cursor:
        print('| {} | {} | {} | {} | {} | {} | {} |'.format(
            row[0],
            row[4],
            '' if row[3] == 'NO' else '(/)',
            '' if row[2] == None else "'{}'".format(row[2]) if row[4].find('char') > -1 else row[2],
            row[5],
            row[6],
            row[7]))

cursor.close()
cnx.close()
