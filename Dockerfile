FROM centos:centos7

MAINTAINER serverboujin

USER root

RUN yum -y update && yum -y reinstall glibc-common && \
localedef -v -c -i ja_JP -f UTF-8 ja_JP.UTF-8; echo "";

ENV LANG=ja_JP.UTF-8
ARG sql1="CREATE DATABASE intelligence_db;"
ARG sql2="CREATE USER 'exist'@'localhost' IDENTIFIED BY 'exist';"
ARG sql3="GRANT ALL PRIVILEGES ON intelligence_db.* TO 'exist'@'localhost';"

RUN yum -y install epel-release && \
yum -y groupinstall "Development Tools" && \
yum -y install https://centos7.iuscommunity.org/ius-release.rpm && \
yum -y install git openssl-devel python35u python35u-devel python35u-libs python35u-pip redis && \
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash && \
yum -y install mariadb-server mariadb-client && \
python3.5 -m ensurepip && \
pip3.5 install --upgrade pip && \
pip3.5 install --upgrade setuptools && \
git clone https://github.com/nict-csl/exist.git EXIST
WORKDIR /EXIST
RUN pip3.5 install -r requirements.txt && \
cp -p intelligence/settings.py.template intelligence/settings.py && \
echo $'# Name of nodes to start\n\
# here we have a single node\n\
  CELERYD_NODES="w1"\n\
# or we could have three nodes:\n\
#CELERYD_NODES="w1 w2 w3"\n\
\n\
# Absolute or relative path to the 'celery' command:\n\
  CELERY_BIN="/path/to/your/celery"\n\
\n\
# App instance to use\n\
# comment out this line if you don't use an app\n\
  CELERY_APP="intelligence"\n\
# or fully qualified:\n\
#CELERY_APP="proj.tasks:app"\n\
\n\
# How to call manage.py\n\
  CELERYD_MULTI="multi"\n\
\n\
# Extra command-line arguments to the worker\n\
  CELERYD_OPTS="--time-limit=300 --concurrency=8"\n\
\n\
# - %n will be replaced with the first part of the nodename.\n\
# - %I will be replaced with the current child process index\n\
# and is important when using the prefork pool to avoid race conditions.\n\
  CELERYD_PID_FILE="/var/run/celery/%n.pid"\n\
  CELERYD_LOG_FILE="/var/log/celery/%n%I.log"\n\
  CELERYD_LOG_LEVEL="INFO"' > /etc/sysconfig/celery && \
echo $'[Unit]\n\
Description=Celery Service\n\
After=network.target\n\
\n\
[Service]\n\
Type=forking\n\
User=root\n\
Group=root\n\
EnvironmentFile=/etc/sysconfig/celery\n\
WorkingDirectory=/opt/exist\n\
ExecStart=/bin/sh -c '${CELERY_BIN} multi start ${CELERYD_NODES} \\n\
-A ${CELERY_APP} --pidfile=${CELERYD_PID_FILE} \\n\
--logfile=${CELERYD_LOG_FILE} --loglevel=${CELERYD_LOG_LEVEL} ${CELERYD_OPTS}'\n\
ExecStop=/bin/sh -c '${CELERY_BIN} multi stopwait ${CELERYD_NODES} \\n\
--pidfile=${CELERYD_PID_FILE}'\n\
ExecReload=/bin/sh -c '${CELERY_BIN} multi restart ${CELERYD_NODES} \\n\
-A ${CELERY_APP} --pidfile=${CELERYD_PID_FILE} \\n\
--logfile=${CELERYD_LOG_FILE} --loglevel=${CELERYD_LOG_LEVEL} ${CELERYD_OPTS}'\n\
\n\
[Install]\n\
WantedBy=multi-user.target' > /etc/systemd/system/celery.service && \
mkdir -p /var/{run,log}/celery && \
chown root:root /var/{run,log}/celery && \
mysql_install_db --datadir=/var/lib/mysql --user=mysql && \
/usr/share/mysql/mysql.server start && \
echo ${sql1} | mysql -uroot -t && \
echo ${sql2} | mysql -uroot -t && \
echo ${sql3} | mysql -uroot -t && \
sed -i -e "s/\#\(.*\)'192.168.56.101',/\1'\*',/g" -e "s/YOUR_DB_USER/exist/g" -e "s/YOUR_DB_PASSWORD/exist/g" intelligence/settings.py
find /EXIST -type f | xargs -I {} sed -i -e "s/env python/env python3.5/g" {}

CMD ["systemctl start redis && systemctl enable redis && /usr/share/mysql/mysql.server start && systemctl start celery"]

