#参数设定
#hostname
export SERVER_NAME_THIS=oracle
#SID
export ORACLE_SID_DB=ORCL
export ORACLE_SID_DB_THIS=ORCL
#安装目录
export INSTALL_ROOT=/opt
export OS_LANG='en_US.UTF-8'
export ORACLE_LANG='AMERICAN_AMERICA.AL32UTF8'
export LANG=$OS_LANG
export LC_ALL=$OS_LANG

write_config_file_line (){
local CONFIG_FILENAME=$1
local CONFIG_LINE_NEW=$2
#替换传入参数中的所有 特殊符号 号为 \特殊符号 ，生成sed命令用字符串
local CONFIG_LINE_NEW_FIX="${CONFIG_LINE_NEW//\*/\*}"
local CONFIG_LINE_NEW_FIX="${CONFIG_LINE_NEW_FIX//\*/\*}"
local CONFIG_LINE_NEW_FIX="${CONFIG_LINE_NEW_FIX//\//\/}"
local CONFIG_LINE_NEW_FIX="${CONFIG_LINE_NEW_FIX//\./\.}"
local CONFIG_LINE_NEW_FIX="${CONFIG_LINE_NEW_FIX//\&/\&}"

local CONFIG_LINE_KEYNAME=''
CONFIG_LINE_KEYNAME=${3:-$CONFIG_LINE_NEW}
CONFIG_LINE_KEYNAME_FIX="${CONFIG_LINE_KEYNAME//\*/\*}"
CONFIG_LINE_KEYNAME_FIX="${CONFIG_LINE_KEYNAME_FIX//\//\/}"
CONFIG_LINE_KEYNAME_FIX="${CONFIG_LINE_KEYNAME_FIX//\"/\\\"}"
CONFIG_LINE_KEYNAME_FIX="${CONFIG_LINE_KEYNAME_FIX//\./\.}"
CONFIG_LINE_KEYNAME_FIX="${CONFIG_LINE_KEYNAME_FIX//\&/\&}"


sed -i "/${CONFIG_LINE_NEW_FIX}/d;s/^${CONFIG_LINE_KEYNAME_FIX}\|^\s*${CONFIG_LINE_KEYNAME_FIX}/#&/g" $CONFIG_FILENAME
echo "$CONFIG_LINE_NEW" >> $CONFIG_FILENAME

}

echo ------------------------------------------------------------
echo 配置主机名...
hostname $SERVER_NAME_THIS
export HOSTNAME=$SERVER_NAME_THIS
write_config_file_line '/etc/sysconfig/network' "HOSTNAME=$HOSTNAME" 'HOSTNAME'

echo ------------------------------------------------------------
echo 关闭selinux...
setenforce 0
write_config_file_line '/etc/selinux/config' 'SELINUX=disabled' 'SELINUX'

echo ------------------------------------------------------------
echo 修改内核参数...
#vim /etc/sysctl.conf
#kernel.shmmax 定义单个共享内存段的最大值，设置应该足够大，能在一个共享内存段下容纳下整个的SGA
#4TB shmmax
#write_config_file_line '/etc/sysctl.conf' 'kernel.shmmax = 4398046511104' 'kernel.shmmax'
#64GB shmmax
write_config_file_line '/etc/sysctl.conf' 'kernel.shmmax = 68719476736' 'kernel.shmmax'
write_config_file_line '/etc/sysctl.conf' 'kernel.shmall = 4294967296' 'kernel.shmall'
write_config_file_line '/etc/sysctl.conf' 'kernel.shmmni = 4096' 'kernel.shmmni'
write_config_file_line '/etc/sysctl.conf' 'kernel.sem = 250 32000 100 128' 'kernel.sem'
write_config_file_line '/etc/sysctl.conf' 'fs.file-max = 6815744' 'fs.aio-max'
write_config_file_line '/etc/sysctl.conf' 'fs.aio-max-nr = 1048576' 'fs.aio-max-nr'
write_config_file_line '/etc/sysctl.conf' 'net.core.rmem_default = 262144' 'net.core.rmem_default'
write_config_file_line '/etc/sysctl.conf' 'net.core.rmem_max = 4194304' 'net.core.rmem_max'
write_config_file_line '/etc/sysctl.conf' 'net.core.wmem_default = 262144' 'net.core.wmem_default'
write_config_file_line '/etc/sysctl.conf' 'net.core.wmem_max = 1048586' 'net.core.wmem_max'
write_config_file_line '/etc/sysctl.conf' 'net.ipv4.ip_local_port_range = 9000 65500' 'net.ipv4.ip_local_port_range'
sysctl -p

echo ------------------------------------------------------------
echo 修改 limits.conf 配置文件...
#vim /etc/security/limits.conf
write_config_file_line '/etc/security/limits.conf' 'oracle soft nproc 2047' 'oracle soft nproc'
write_config_file_line '/etc/security/limits.conf' 'oracle hard nproc 16384' 'oracle hard nproc'
write_config_file_line '/etc/security/limits.conf' 'oracle soft nofile 1024' 'oracle soft nofile'
write_config_file_line '/etc/security/limits.conf' 'oracle hard nofile 65536' 'oracle hard nofile'
write_config_file_line '/etc/security/limits.conf' 'oracle soft stack 10240' 'oracle soft stack'
write_config_file_line '/etc/security/limits.conf' 'oracle hard stack 32768' 'oracle hard stack'

echo ------------------------------------------------------------
echo 修改/etc/pam.d/login...
write_config_file_line '/etc/pam.d/login' 'session    required     pam_limits.so'

echo ------------------------------------------------------------
echo 创建用户和组...
groupadd -g 700 oinstall
groupadd -g 701 dba

useradd -g oinstall -G dba -u 601 oracle
#echo后的oracle为密码，stdin 后的oracle为用户名
echo -n oracle | passwd --stdin oracle
echo user: oracle password: oracle

echo ------------------------------------------------------------
echo 配置Oracle用户环境变量...
echo "export ORACLE_UNQNAME=$ORACLE_SID_DB" > /home/oracle/oracle.env
echo "export ORACLE_SID=$ORACLE_SID_DB_THIS" >> /home/oracle/oracle.env
echo "export ORACLE_HOSTNAME=\$HOSTNAME" >> /home/oracle/oracle.env

echo "export ORACLE_BASE=$INSTALL_ROOT/app/oracle" >> /home/oracle/oracle.env
echo "export DB_HOME=\$ORACLE_BASE/product/11.2.0/db_1" >> /home/oracle/oracle.env

echo "ulimit -u 16384 -n 65536" >> /home/oracle/oracle.env
echo "export NLS_LANG=$ORACLE_LANG" >> /home/oracle/oracle.env
echo "export NLS_DATE_FORMAT=\"yy-mm-dd HH24:MI:SS\"" >> /home/oracle/oracle.env
echo "export ORACLE_HOME=\$DB_HOME" >> /home/oracle/oracle.env
echo "export TEMP=/tmp" >> /home/oracle/oracle.env
echo "export TMPDIR=\$TEMP" >> /home/oracle/oracle.env
echo "export BASE_PATH=\$PATH" >> /home/oracle/oracle.env
echo "export PATH=\$ORACLE_HOME/bin:\$ORACLE_HOME/OPatch:\$BASE_PATH" >> /home/oracle/oracle.env
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib:/usr/local/lib" >> /home/oracle/oracle.env
echo "export CLASSPATH=\$ORACLE_HOME/JRE:\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib:\$ORACLE_HOME/network/jlib" >> /home/oracle/oracle.env
#Oracle 11g R2 11.2.0.4 不能设置ORA_NLS10，否则在安装Oracle DB软件时报PRCT-1011 : Failed to run "oifcfg" (Doc ID 1380183.1)。
#echo "export ORA_NLS10=\$ORACLE_HOME/nls/data" >> /home/oracle/oracle.env

echo "export THREADS_FLAG=native" >> /home/oracle/oracle.env
echo "umask 022" >> /home/oracle/oracle.env
echo "export TMOUT=0" >> /home/oracle/oracle.env

chown oracle.oinstall /home/oracle/oracle.env
chmod 755 /home/oracle/oracle.env

write_config_file_line '/home/oracle/.bash_profile' 'source /home/oracle/oracle.env'

echo ------------------------------------------------------------
echo 安装Oracle软件依赖包
yum install -y binutils compat-libcap1 compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel libgcc libstdc++ libstdc++-devel libaio libaio-devel make sysstat compat-libstdc++-33.i686 glibc.i686 glibc-devel.i686 libgcc.i686 libstdc++.i686 libstdc++-devel.i686 libaio.i686 libaio-devel.i686 unixODBC unixODBC.i686 unixODBC-devel unixODBC-devel.i686 elfutils-libelf elfutils-libelf-devel rlwrap
yum install -y unzip

echo ------------------------------------------------------------
echo 配置/etc/profile 环境变量...

write_config_file_line '/etc/profile' "export LANG=$OS_LANG" 'LANG'
write_config_file_line '/etc/profile' "export LC_ALL=$OS_LANG" 'LC_ALL'
