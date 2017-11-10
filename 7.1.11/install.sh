#!/bin/sh
# By viagram <viagram.yang@gmail.com>

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

MY_SCRIPT="$(dirname $(readlink -f $0))/$(basename $0)"

echo -e "\033[33m"
clear
cat <<'EOF'

###################################################################
#                     _                                           #
#              __   _(_) __ _  __ _ _ __ __ _ _ __ ___            #
#              \ \ / / |/ _` |/ _` | '__/ _` | '_ ` _ \           #
#               \ V /| | (_| | (_| | | | (_| | | | | | |          #
#                \_/ |_|\__,_|\__, |_|  \__,_|_| |_| |_|          #
#                             |___/                               #
#                                                                 #
###################################################################
EOF
echo -e "\033[0m"

# Check If You Are Root
if [[ $EUID -ne 0 ]]; then
    clear
    printnew -red "错误: 必须以root权限运行此脚本! "
    exit 1
fi

function Check_OS(){
    if [[ -f /etc/redhat-release ]];then
        if egrep -i "centos.*6\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'centos6'
        elif egrep -i "centos.*7\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'centos7'
        elif egrep -i "Red.*Hat.*6\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'redhat6'
        elif egrep -i "Red.*Hat.*7\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'redhat7'
        fi
    elif [[ -f /etc/issue ]];then
        if egrep -i "debian" /etc/issue >/dev/null 2>&1;then
            echo 'debian'
        elif egrep -i "ubuntu" /etc/issue >/dev/null 2>&1;then
            echo 'ubuntu'
        fi
    else
        echo 'unknown'
    fi
}

function printnew(){
    typeset -l CHK
    WENZHI=""
    RIGHT=0
    HUANHANG=0
    for PARSTR in "${@}";do
        CHK="${PARSTR}"
        if echo "${CHK}" | egrep -io "^\-[[:graph:]]*" >/dev/null 2>&1; then
            if [[ "${CHK}" == "-black" ]]; then
                COLOUR="\033[30m"
            elif [[ "${CHK}" == "-red" ]]; then
                COLOUR="\033[31m"
            elif [[ "${CHK}" == "-green" ]]; then
                COLOUR="\033[32m"
            elif [[ "${CHK}" == "-yellow" ]]; then
                COLOUR="\033[33m"
            elif [[ "${CHK}" == "-blue" ]]; then
                COLOUR="\033[34m"
            elif [[ "${CHK}" == "-purple" ]]; then
                COLOUR="\033[35m"
            elif [[ "${CHK}" == "-cyan" ]]; then
                COLOUR="\033[36m"
            elif [[ "${CHK}" == "-white" ]]; then
                COLOUR="\033[37m"
            elif [[ "${CHK}" == "-a" ]]; then
                HUANHANG=1
            elif [[ "${CHK}" == "-r" ]]; then
                RIGHT=1
            fi
        else
            WENZHI+="${PARSTR}"
        fi
    done
    COUNT=$(echo -n "${WENZHI}" | wc -L)
    if [[ ${RIGHT} -eq 1 ]];then
        tput cup $(tput lines) $[$(tput cols)-${COUNT}]
        printf "${COLOUR}%b%-${COUNT}s\033[0m" "${WENZHI}"
        tput cup $(tput lines) 0
    else
        tput cup $(tput lines) 0
        if [[ ${HUANHANG} -eq 1 ]];then
            printf "${COLOUR}%b%-${COUNT}s\033[0m" "${WENZHI}"
            tput cup $(tput lines) ${COUNT}
        else
            printf "${COLOUR}%b%-${COUNT}s\033[0m\n" "${WENZHI}"
        fi
    fi
}

function fpm_conf(){
    if [ "$(Check_OS)" == "centos6" ];then
        cat > /etc/rc.d/init.d/php-fpm<<-EOF

EOF
        chmod 775 /etc/rc.d/init.d/php-fpm
        chkconfig --add php-fpm
        chkconfig php-fpm on
        /etc/rc.d/init.d/php-fpm start
    fi
    if [ "$(Check_OS)" == "centos7" ];then
        cat > /usr/lib/systemd/system/php-fpm.service<<-EOF
[Unit]
Description=php-7.1.11 fpm server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/php-fpm.pid
ExecStart=/usr/local/php-7.1.11/sbin/php-fpm --daemonize --fpm-config /usr/local/php-7.1.11/etc/php-fpm.conf --pid /var/run/php-fpm.pid
Restart=on-failure
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
        chmod 754 /usr/lib/systemd/system/php-fpm.service >/dev/null 2>&1
        systemctl enable php-fpm.service
        systemctl daemon-reload
        systemctl restart php-fpm.service
    fi
}

####################################################################################################################
if [[ "$(Check_OS)" != "centos7" && "$(Check_OS)" != "centos6" && "$(Check_OS)" != "redhat7" && "$(Check_OS)" != "redhat6" ]]; then
    printnew -red "目前仅支持CentOS6,7及Redhat6,7系统."
    exit 1
else
    printnew -green "更新和安装必备组件包..."
    if ! yum -y install bzip2-devel libxml2-devel curl-devel db4-devel libjpeg-devel libpng-devel \
    freetype-devel pcre-devel zlib-devel sqlite-devel unzip bzip2 mhash-devel openssl-devel php-mcrypt \
    libmcrypt libmcrypt-devel libtool-ltdl libtool-ltdl-devel; then
        printnew -red "更新和安装必备组件包失败, 程序终止."
        exit 1
    fi
    
    cur_dir=$(pwd)/php_install
    if [ ! -d "${cur_dir}" ]; then
        mkdir -p ${cur_dir}
    fi
    cd ${cur_dir}

    PHP_VER="7.1.11"
    APCU_VER="5.1.8"
    IONCUBE_VER="7.1"
    PREFIX="/usr/local/php-${PHP_VER}"
    CPUSU=$(cat /proc/cpuinfo | grep processor | wc -l)
    DOWNLOAD_URL="https://raw.githubusercontent.com/viagram/PHP_Install/master/${PHP_VER}"
    
    if test $(arch) = "x86_64"; then
        LIB="lib64"
        ZEND_ARCH="x86_64"
    else
        LIB="lib"
        ZEND_ARCH="x86"
    fi
    
    printnew -green "下载php-${PHP_VER}源码包..."
    if ! wget -O php-${PHP_VER}.tar.gz -c ${DOWNLOAD_URL}/php-${PHP_VER}.tar.gz; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    
    printnew -green "下载ioncube扩展包..."
    if ! wget -O ioncube-$ZEND_ARCH-${IONCUBE_VER}.zip -c ${DOWNLOAD_URL}/ioncube-$ZEND_ARCH-${IONCUBE_VER}.zip; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    
    printnew -green "下载apcu扩展包..."
    if ! wget -O apcu-${APCU_VER}.tar.gz -c ${DOWNLOAD_URL}/apcu-${APCU_VER}.tar.gz; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    
    # 编译并安装php
    printnew -green "解压php-${PHP_VER}源码包..."
    if ! tar zxf php-${PHP_VER}.tar.gz; then
        printnew -red "解压php-${PHP_VER}失败, 程序终止."
        exit 1
    fi
    cd php-${PHP_VER}
    printnew -green "开始编译php-${PHP_VER}..."
    CONFIG_CMD="./configure --prefix=${PREFIX} --with-config-file-scan-dir=${PREFIX}/etc/php.d --with-libdir=${LIB} --enable-fastcgi --enable-fpm --with-mysql --with-mysqli --with-pdo-mysql --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr/include/libxml2/libxml --enable-xml --disable-fileinfo --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-pear --with-gettext --enable-calendar --with-openssl"
    if [ -f /usr/include/mcrypt.h ]; then
        CONFIG_CMD+=" --with-mcrypt"
    fi
    if ! $CONFIG_CMD; then
        echo $CONFIG_CMD
        printnew -red "配置php-${PHP_VER}失败, 程序终止."
        exit 1
    fi
    if ! make -j ${CPUSU}; then
        printnew -red "编译php-${PHP_VER}失败, 程序终止."
        exit 1
    fi
    if ! make install; then
        printnew -red "安装php-${PHP_VER}失败, 程序终止."
        exit 1
    fi
    mkdir -p ${PREFIX}/etc/php.d
    \cp ${PREFIX}/etc/php-fpm.conf.default ${PREFIX}/etc/php-fpm.conf
    \cp ${PREFIX}/etc/php-fpm.d/www.conf.default ${PREFIX}/etc/php-fpm.d/www.conf
    if [ ! -f ${PREFIX}/lib/php.ini ]; then
        if ! wget -O ${PREFIX}/lib/php.ini -c ${DOWNLOAD_URL}/php.ini; then
            printnew "下载php.ini失败, 程序终止."
            exit 1
        fi
    fi
    
    phpext_dir=$(${PREFIX}/bin/php-config --extension-dir)
    sed -i "s%This_php_extension_dir%${phpext_dir}%g" ${PREFIX}/lib/php.ini
    
    printnew -green "下载php服务配置文件..."
    if [[ "$(Check_OS)" == "centos7" || "$(Check_OS)" == "redhat7" ]]; then
        if ! wget -O php-fpm.service -c ${DOWNLOAD_URL}/CentOS-7; then
            printnew -red "下载失败, 程序终止."
            exit 1
        else
            sed -i "s/PHP_VERSION/php-${PHP_VER}/g" ./php-fpm.service
            if \cp ./php-fpm.service /usr/lib/systemd/system/php-fpm.service; then
                chmod 754 /usr/lib/systemd/system/php-fpm.service >/dev/null 2>&1
                systemctl enable php-fpm.service
                systemctl daemon-reload
                systemctl start php-fpm.service
            else
                printnew -red "安装服务失败."
            fi
        fi
    fi
    if [[ "$(Check_OS)" == "centos6" || "$(Check_OS)" == "redhat6" ]]; then
        if ! wget -O php-fpm -c ${DOWNLOAD_URL}/CentOS-6; then
            printnew -red "下载失败, 程序终止."
            exit 1
        else
            sed -i "s/PHP_VERSION/php-${PHP_VER}/g" ./php-fpm
            if \cp ./php-fpm.service /usr/lib/systemd/system/php-fpm.service; then
                chmod 754 /etc/rc.d/init.d/php-fpm >/dev/null 2>&1
                chkconfig --add php-fpm
                chkconfig php-fpm on
                /etc/rc.d/init.d/php-fpm start
            else
                printnew -red "安装服务失败."
            fi
        fi
    fi
    cd ..
    
    # 复制ioncube扩展
    printnew -green "安装 ioncube 扩展..."
    if ! unzip -o ioncube-$ZEND_ARCH-${IONCUBE_VER}.zip; then
        printnew -red "解压ioncube-$ZEND_ARCH-${IONCUBE_VER}失败, 程序终止."
        exit 1
    fi
    if ! \cp -f ioncube_loader_lin_${IONCUBE_VER}.so ${phpext_dir}/ioncube_loader_lin_${IONCUBE_VER}.so; then
        printnew -red "安装ioncube-$ZEND_ARCH-${IONCUBE_VER}失败, 程序终止."
        exit 1
    fi
    chmod +x $phpext_dir/ioncube_loader_lin_${IONCUBE_VER}.so
    
    # 编译并安装apcu扩展
    printnew -green "安装 apcu 扩展..."
    if ! tar zxf apcu-${APCU_VER}.tar.gz; then
        printnew -red "解压ioncube-$ZEND_ARCH-${IONCUBE_VER}失败, 程序终止."
        exit 1
    fi
    cd apcu-${APCU_VER}
    ${PREFIX}/bin/phpize
    if ! ./configure --with-php-config=${PREFIX}/bin/php-config; then
        printnew -red "配置apcu-${APCU_VER}失败, 程序终止."
        exit 1
    fi
    if ! make -j ${CPUSU}; then
        printnew -red "编译apcu-${APCU_VER}失败, 程序终止."
        exit 1
    fi
    if ! make install; then
        printnew -red "安装apcu-${APCU_VER}失败, 程序终止."
        exit 1
    fi
    cd ..
    
    # 安装php-fpm服务
    printnew -green "安装php-fpm服务..."
    
    cd ${cur_dir}/.. && rm -rf ${cur_dir}
    rm -f ${MY_SCRIPT}
    printnew -green "PHP ${PHP_VER} Installed."
fi