#!/bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check If You Are Root
if [[ $EUID -ne 0 ]]; then
    clear
    echo -e "\033[31m Error: You must be root to run this script! \033[0m"
    exit 1
fi

cur_dir=`pwd`/php_install
if [ ! -d "${cur_dir}" ]; then
    mkdir -p ${cur_dir}
fi
cd $cur_dir

yum -y install bzip2-devel libxml2-devel curl-devel db4-devel libjpeg-devel libpng-devel freetype-devel pcre-devel zlib-devel sqlite-devel unzip bzip2
yum -y install mhash-devel openssl-devel php-mcrypt libmcrypt libmcrypt-devel
yum -y install libtool-ltdl libtool-ltdl-devel

cpusu=$(cat /proc/cpuinfo | grep processor | wc -l)
PREFIX="/usr/local/php7100"
DOWNLOAD_PHP_URL="https://raw.githubusercontent.com/viagram"
fpmpath='/etc/rc.d/init.d/php-fpm'
ZEND_ARCH="i386"
LIB="lib"
if test `arch` = "x86_64"; then
        LIB="lib64"
        ZEND_ARCH="x86_64"
fi

function fpm_conf()
{
    echo "chkconfig $fpmpath"
    cat > $fpmpath<<-EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:          php-fpm
# Required-Start:    \$remote_fs \$network
# Required-Stop:     \$remote_fs \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts php-fpm
# Description:       starts the PHP FastCGI Process Manager daemon
### END INIT INFO
prefix="/usr/local/php7100"
php_fpm_BIN="\$prefix/sbin/php-fpm"
php_fpm_CONF="\$prefix/etc/php-fpm.conf"
php_fpm_PID="/var/run/php-fpm.pid"
php_opts="--fpm-config \$php_fpm_CONF --pid \$php_fpm_PID"

wait_for_pid () {
    try=0
    while test \$try -lt 35 ; do
        case "\$1" in
            'created')
            if [ -f "\$2" ] ; then
                try=''
                break
            fi
            ;;
            'removed')
            if [ ! -f "\$2" ] ; then
                try=''
                break
            fi
            ;;
        esac
        echo -n .
        try=\`expr \$try + 1\`
        sleep 1
    done
}
case "\$1" in
    start)
        echo -n "Starting php-fpm "
        \$php_fpm_BIN --daemonize \$php_opts
        if [ "\$?" != 0 ] ; then
            echo " failed"
            exit 1
        fi
        wait_for_pid created \$php_fpm_PID
        if [ -n "\$try" ] ; then
            echo " failed"
            exit 1
        else
            echo " done"
        fi
    ;;
    stop)
        echo -n "Gracefully shutting down php-fpm "
        if [ ! -r \$php_fpm_PID ] ; then
            echo "warning, no pid file found - php-fpm is not running ?"
            exit 1
        fi
        kill -QUIT \`cat \$php_fpm_PID\`
        wait_for_pid removed \$php_fpm_PID
        if [ -n "\$try" ] ; then
            echo " failed. Use force-quit"
            exit 1
        else
            echo " done"
        fi
    ;;
    status)
        if [ ! -r \$php_fpm_PID ] ; then
            echo "php-fpm is stopped"
            exit 0
        fi
        PID=\`cat \$php_fpm_PID\`
        if ps -p \$PID | grep -q \$PID; then
            echo "php-fpm (pid \$PID) is running..."
        else
            echo "php-fpm dead but pid file exists"
        fi
    ;;
    force-quit)
        echo -n "Terminating php-fpm "
        if [ ! -r \$php_fpm_PID ] ; then
            echo "warning, no pid file found - php-fpm is not running ?"
            exit 1
        fi
        kill -TERM \`cat \$php_fpm_PID\`
        wait_for_pid removed \$php_fpm_PID
        if [ -n "\$try" ] ; then
            echo " failed"
            exit 1
        else
            echo " done"
        fi
    ;;
    restart)
        \$0 stop
        \$0 start
    ;;
    reload)
        echo -n "Reload service php-fpm "
        if [ ! -r \$php_fpm_PID ] ; then
            echo "warning, no pid file found - php-fpm is not running ?"
            exit 1
        fi
        kill -USR2 \`cat \$php_fpm_PID\`
        echo " done"
    ;;
    configtest)
        \$php_fpm_BIN -t
    ;;
    *)
        echo "Usage: \$0 {start|stop|force-quit|restart|reload|status|configtest}"
        exit 1
    ;;
esac
EOF
    chmod 775 $fpmpath
    chkconfig --add php-fpm
    chkconfig php-fpm on
    $fpmpath start
}

function install_php(){
    wget -O php-7.1.0.tar.gz -c $DOWNLOAD_PHP_URL/kangle/master/php/7.1/7100/php-7.1.0.tar.gz
    tar zxf php-7.1.0.tar.gz
    cd php-7.1.0
    CONFIG_CMD="./configure --prefix=$PREFIX --with-config-file-scan-dir=$PREFIX/etc/php.d --with-libdir=$LIB --enable-fastcgi --enable-fpm --with-mysql --with-mysqli --with-pdo-mysql --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr/include/libxml2/libxml --enable-xml --disable-fileinfo --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-pear --with-gettext --enable-calendar --with-openssl"
    if [ -f /usr/include/mcrypt.h ]; then
        CONFIG_CMD="$CONFIG_CMD --with-mcrypt"
    fi
    #'./configure' --prefix=$PREFIX --with-config-file-scan-dir=$PREFIX/etc/php.d --with-libdir=$LIB '--enable-fastcgi' '--with-mysql' '--with-mysqli' --with-pdo-mysql '--with-iconv-dir' '--with-freetype-dir' '--with-jpeg-dir' '--with-png-dir' '--with-zlib' '--with-libxml-dir=/usr/include/libxml2/libxml' '--enable-xml' '--disable-fileinfo' '--enable-magic-quotes' '--enable-safe-mode' '--enable-bcmath' '--enable-shmop' '--enable-sysvsem' '--enable-inline-optimization' '--with-curl' '--with-curlwrappers' '--enable-mbregex' '--enable-mbstring' '--enable-ftp' '--with-gd' '--enable-gd-native-ttf' '--with-openssl' '--enable-pcntl' '--enable-sockets' '--with-xmlrpc' '--enable-zip' '--enable-soap' '--with-pear' '--with-gettext' '--enable-calendar'
    #'./configure' --prefix=$PREFIX --with-config-file-scan-dir=$PREFIX/etc/php.d --with-libdir=$LIB '--enable-fastcgi' '--with-mysql' '--with-mysqli' --with-pdo-mysql '--with-iconv-dir' '--with-freetype-dir' '--with-jpeg-dir' '--with-png-dir' '--with-zlib' '--with-libxml-dir=/usr/include/libxml2/libxml' '--enable-xml' '--disable-fileinfo' '--enable-magic-quotes' '--enable-safe-mode' '--enable-bcmath' '--enable-shmop' '--enable-sysvsem' '--enable-inline-optimization' '--with-curl' '--with-curlwrappers' '--enable-mbregex' '--enable-mbstring' '--with-mcrypt' '--enable-ftp' '--with-gd' '--enable-gd-native-ttf' '--with-openssl' '--with-mhash' '--enable-pcntl' '--enable-sockets' '--with-xmlrpc' '--enable-zip' '--enable-soap' '--with-pear' '--with-gettext' '--enable-calendar'
    $CONFIG_CMD
    if test $? != 0; then
        echo $CONFIG_CMD
        echo "configure php error";
        exit 1
    fi
    make -j $cpusu && make install
    mkdir -p $PREFIX/etc/php.d
    \cp $PREFIX/etc/php-fpm.conf.default $PREFIX/etc/php-fpm.conf
    \cp $PREFIX/etc/php-fpm.d/www.conf.default $PREFIX/etc/php-fpm.d/www.conf
    if [ ! -f $PREFIX/php-templete.ini ]; then
        cp php.ini-dist $PREFIX/php-templete.ini
    fi
    if [ ! -f $PREFIX/config.xml ]; then
        wget -O $PREFIX/lib/config.xml -c $DOWNLOAD_PHP_URL/kangle/master/php/7.1/7100/config.xml
    fi
    wget -O $PREFIX/lib/php.ini -c $DOWNLOAD_PHP_URL/kangle/master/php/7.1/7100/php.ini
    cd ..
}

function install_ioncube(){
    wget -O ioncube-$ZEND_ARCH-7.0.zip -c $DOWNLOAD_PHP_URL/kangle/master/php/7.1/7100/ioncube-$ZEND_ARCH-7.0.zip
    unzip ioncube-$ZEND_ARCH-7.0.zip
    phpext_dir=$($PREFIX/bin/php-config --extension-dir)
    \mv ioncube_loader_lin_7.0.so $phpext_dir/ioncube_loader_lin_7.0.so
    chmod 755 $phpext_dir/ioncube_loader_lin_7.0.so
}

function install_apcu(){
    wget -O apcu-5.1.7.tar.gz -c $DOWNLOAD_PHP_URL/kangle/master/php/7.1/7100/apcu-5.1.7.tar.gz
    tar zxf apcu-5.1.7.tar.gz
    cd apcu-5.1.7
    $PREFIX/bin/phpize
    ./configure --with-php-config=$PREFIX/bin/php-config
    make -j $cpusu && make install
    cd ..
}
install_php
#install_ioncube
install_apcu
fpm_conf
cd $cur_dir
rm -rf $cur_dir
rm -f $0
