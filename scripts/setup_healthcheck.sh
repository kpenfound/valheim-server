yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y nginx
systemctl enable nginx
systemctl start nginx
