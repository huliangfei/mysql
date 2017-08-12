mysql 5.7.17 主從複製架構

環境版本：
CentOS:7.3.1611
Docker:17.03.0
MySQL:5.7.17


1.先卸載mariadb-libs
2.安裝mysql-community-server
3.修改Master MySQL配置文件
vi /etc/mysql/my.conf
[mysqld]
log-bin=mysql-bin
server-id=1
gtid-mode=on
enforce-gtid-consistency=true

4.修改Slave MySQL配置文件
vi /etc/mysql/my.conf
在[mysqld]
log-bin=mysql-bin
server-id=2
replicate-ignore-db=mysql
gtid-mode=on
enforce-gtid-consistency=true

5.在主庫上創建一個複製賬戶
CREATE USER 'repl'@'%' IDENTIFIED BY 'qaz.00JK';       -- '%'意味着所有的终端都可以用这个用户登录
GRANT SELECT,REPLICATION SLAVE ON *.* TO 'repl'@'%'; -- SELECT权限是为了让repl可以读取到数据，生产环境建议创建另一个用户
复制账户为: rep1
复制密码为: qaz.00JK 

6.在slave用新创建的用户连接master（记得把MASTER_HOST改为自己的主机IP）
CHANGE MASTER TO MASTER_HOST='192.168.33.32', MASTER_USER='repl', MASTER_PASSWORD='qaz.00JK', MASTER_AUTO_POSITION=1;
START SLAVE;
SHOW SLAVE STATUS\G

7.最后，检验一下我们的成果。
mysql>show slave status\G
*************************** 1. row ***************************
Slave_IO_State: Waiting for master to send event
Master_Host: 192.168.2.222  //主服务器地址
Master_User: mysync   //授权帐户名，尽量避免使用root
Master_Port: 3306    //数据库端口，部分版本没有此行
Connect_Retry: 60
Master_Log_File: mysql-bin.000004
Read_Master_Log_Pos: 600     //#同步读取二进制日志的位置，大于等于Exec_Master_Log_Pos
Relay_Log_File: ddte-relay-bin.000003
Relay_Log_Pos: 251
Relay_Master_Log_File: mysql-bin.000004
Slave_IO_Running: Yes    //此状态必须YES
Slave_SQL_Running: Yes     //此状态必须YES
注：Slave_IO及Slave_SQL进程必须正常运行，即YES状态，否则都是错误的状态(如：其中一个NO均属错误)。
以上操作过程，主从服务器配置完成。


在5.7版本的MySQL启动时，因为数据目录是空的，所以会有以下操作：

服务器初始化
在数据目录生成一个SSL证书和key文件
validate_password插件安装并启用
创建一个超级管理帐号'root'@'localhost'。管理的密码会保存在错误日志文件中，可以通过以下命令查看：
$ sudo grep 'temporary password' /var/log/mysqld.log
可以通过以下命令并使用自动生成的临时密码登录，然后修改为一个自定义密码：

$ mysql -u root -p 
密码修改：

$ ALTER USER 'root'@'localhost' IDENTIFIED BY 'newPassword';
注意：MySQL的validate_password插件是默认安装的。这要求MySQL密码至少包含一个大写字母、一个小写字母、一个数字和一个特殊字符，并且总密码长度至少为8个字符。
