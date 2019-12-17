# Linux环境简易安装Oracle11gR2步骤

在某些古老又传统的项目中，还是会坚持使用Oracle数据库。其中Oracle11g官方并没有提供docker镜像，自己制作或者使用别人制作镜像都很难保证生产环境是否能正常稳定运行，所以还是只能老老实实直接安装在服务器上。

本教程是在Centos 7系统下 **<u>使用静默模式</u>** 安装Oracle11gR2，并提供封装脚本，让你可以以最快的速度安装完成

---

1. 安装准备工作   
   * 复制oracle_install_tools文件夹到安装服务器上

     ```shell
     cp -r oracle_install_tools/ /tmp/
     ```

   * 运行系统设置与准备脚本

     ```shell
     ./oracle_preinstall.sh
     ```

2. 开始安装

   * 创建安装目录 

     ```shell
     mkdir -p /opt/app/oracle && chown -R oracle:dba /opt/app
     ```

   * 数据库安装

     ```shell
     #解压安装文件
     unzip xxx.zip && cd xxx
     #
     su oracle
     #
     ./runInstaller -silent -responseFile /tmp/oracle_install_tools/response/db_install.rsp
     #忽略安装所需的系统要求
     ./runInstaller -silent -ignoreSysPrereqs -responseFile /tmp/oracle_install_tools/response/db_install.rsp
     #忽略安装所需的依赖包
     ./runInstaller -silent -ignoreSysPrereqs -ignorePrereq -responseFile /tmp/oracle_install_tools/response/db_install.rsp
     ```
     安装结束后，需要使用root用户手动执行以下文件

     ```shell
     /opt/app/oracle/oraInventory/orainstRoot.sh
     /opt/app/oracle/product/11.2.0.1/db_1/root.sh
     ```
   * 监听器安装
     ```shell
     netca /silent /responseFile /tmp/oracle_install_tools/response/netca.rsp
     ```

   * 建库

     ```shell
     dbca -silent -responseFile /tmp/oracle_install_tools/response/dbca.rsp
     ```

3. 设置数据库自启动

   ```shell
   #1.找到“orcl:/opt/app/oracle/product/11.2.0/db_1:N”， 
   #改为“orcl:/opt/app/oracle/product/11.2.0/db_1:Y”。修改完成后保存
   vi /etc/oratab
   #2.创建自启动所需的启动脚本
   mkdir /home/oracle/scripts && cp /tmp/oracle_install_tools/scripts/start_all.sh /home/oracle/scripts/ \
   && cp /tmp/oracle_install_tools/scripts/stop_all.sh /home/oracle/scripts/ && \
   chmod 750 /home/oracle/scripts/*
   #3.加入systemctl启动管理
   cp /tmp/oracle_install_tools/scripts/oracle.service /usr/lib/systemd/system
   systemctl enable oracle
   ```
---
#### 备注
**需要修改Oracle默认安装位置或者SID等其他设置时，需要修改所有脚本中Oracle基础变量与Oracle安装Response文件内的相关设置**
**默认设置：**
  * 安装位置：/opt/app/
  * SID: ORCL
  * GlobalDbName: ORCL
  * HostName: oracle



