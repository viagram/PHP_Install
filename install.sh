#!/bin/sh
# By viagram <viagram.yang@gmail.com>

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

MY_SCRIPT="$(dirname $(readlink -f $0))/$(basename $0)"

echo -e "\033[33m"
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

####################################################################################################################

if [[ "$(Check_OS)" != "centos7" && "$(Check_OS)" != "centos6" && "$(Check_OS)" != "redhat7" && "$(Check_OS)" != "redhat6" ]]; then
    printnew -red "目前仅支持CentOS6,7及Redhat6,7系统."
    exit 1
else
    printnew -a -green "获取版本信息..."
    DOWNLOAD_URL="https://raw.githubusercontent.com/viagram/PHP_Install/master/"
    if [[ -n ${1} ]]; then
        PHP_NAME='php-'${1}
    else
        PHP_NAME=$(curl -sk https://secure.php.net/downloads.php | egrep -io '/get/php-([0-9]{1,2}.){3}tar.gz/from/a/mirror' | sort -Vu | awk 'END{print}' | egrep -io 'php-([0-9]{1,2}.){2}[0-9]{1,2}')
        #PHP_NAME=$(curl -sk https://github.com/php/php-src/releases | egrep -io '/tag/php-7.1[0-9.]*' | sort -Vu | awk 'END{print}' | egrep -io 'php-([0-9]{1,2}.){2}[0-9]{1,2}')
    fi
    if ! echo ${PHP_NAME} | egrep -io 'php-([0-9]{1,2}.){2}[0-9]{1,2}' >/dev/null 2>&1; then
        printnew -r -red "失败, 程序终止."
        exit 1
    fi
    PREFIX="/usr/local/${PHP_NAME}"
    IONCUBE_VER=$(echo ${PHP_NAME} | sed 's/php-//g' | egrep -io '^[0-9]{1,2}.[0-9]{1,2}')
    CPUSU=$(cat /proc/cpuinfo | grep processor | wc -l)

    if [[ -z ${IONCUBE_VER} ]]; then
        printnew -r -red "失败, 程序终止."
        exit 1
    else
        printnew -r -green "成功"
        if [[ -x "${PREFIX}/bin/php" ]]; then
            printnew -green "检测到 [${PHP_NAME}] 已安装, 是否再次安装?"
        else
            printnew -green "将进行 [${PHP_NAME}] 安装进程."
        fi
    fi

    read -p "输入[y/n]选择是否继续, 默认为y：" is_go
    [[ -z "${is_go}" ]] && is_go='y'
    if [[ ${is_go} != "y" && ${is_go} != "Y" ]]; then
        printnew -red "用户取消, 程序终止."
        exit 0
    fi

    if test $(arch) = "x86_64"; then
        LIB="lib64"
        ZEND_ARCH="x86-64"
    else
        LIB="lib"
        ZEND_ARCH="x86"
    fi
    
    printnew -green "更新和安装必备组件包..."
    yum groupinstall -y "Development Tools"
    if ! yum -y install bzip2-devel libxml2-devel curl-devel db4-devel libjpeg-devel libpng-devel \
    freetype-devel pcre-devel zlib-devel sqlite-devel unzip bzip2 mhash-devel openssl-devel php-mcrypt \
    libmcrypt libmcrypt-devel libtool-ltdl libtool-ltdl-devel wget; then
        printnew -red "更新和安装必备组件包失败, 程序终止."
        exit 1
    fi
    
    cur_dir=$(pwd)/php_install
    if [ ! -d "${cur_dir}" ]; then
        mkdir -p ${cur_dir}
    fi
    cd ${cur_dir}
    
    printnew -green "下载${PHP_NAME}源码包..."
    [[ -f ${PHP_NAME}.tar.gz ]] && rm -f ${PHP_NAME}.tar.gz
    if ! wget -O ${PHP_NAME}.tar.gz -c https://secure.php.net/distributions/${PHP_NAME}.tar.gz --no-check-certificate; then
    #if ! wget -O ${PHP_NAME}.tar.gz -c https://github.com/php/php-src/archive/${PHP_NAME}.tar.gz --no-check-certificate; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    
    printnew -green "下载ioncube扩展包..."
    [[ -f ioncube_loaders_lin_${ZEND_ARCH}.tar.gz ]] && rm -f ioncube_loaders_lin_${ZEND_ARCH}.tar.gz
    if ! wget -O ioncube_loaders_lin_${ZEND_ARCH}.tar.gz -c https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_${ZEND_ARCH}.tar.gz; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    
    printnew -green "下载apcu扩展包..."
    APCU_URL=$(curl -sk https://pecl.php.net/package/APCu | egrep -io '/get/apcu-([0-9]{1,2}.){3}tgz' | head -n 1 | awk '{print "https://pecl.php.net"$0}')
    APCU_FILE=$(basename ${APCU_URL})
    APCU_DIR=${APCU_FILE%.*}
    [[ -f ${APCU_FILE} ]] && rm -f ${APCU_FILE}
    if ! wget -O ${APCU_FILE} -c ${APCU_URL}; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    
    # 编译并安装php
    printnew -a -green "解压${PHP_NAME}源码包..."
    if ! tar zxf ${PHP_NAME}.tar.gz; then
        printnew -r -red "解压${PHP_NAME}失败, 程序终止."
        exit 1
    else
        printnew -r -green "成功"
    fi
    cd ${PHP_NAME}
    #cd php-src-${PHP_NAME}
    printnew -green "开始编译${PHP_NAME}..."
    CONFIG_CMD="./configure --prefix=${PREFIX} --with-config-file-scan-dir=${PREFIX}/etc/php.d --with-libdir=${LIB} --enable-fastcgi --enable-fpm --with-mysql --with-mysqli --with-pdo-mysql --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr/include/libxml2/libxml --enable-xml --disable-fileinfo --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-pear --with-gettext --enable-calendar --with-openssl"
    if [ -f /usr/include/mcrypt.h ]; then
        CONFIG_CMD+=" --with-mcrypt"
    fi
    if ! $CONFIG_CMD; then
        echo $CONFIG_CMD
        printnew -red "配置${PHP_NAME}失败, 程序终止."
        exit 1
    fi
    if ! make -j ${CPUSU}; then
        printnew -red "编译${PHP_NAME}失败, 程序终止."
        exit 1
    fi
    if ! make install; then
        printnew -red "安装${PHP_NAME}失败, 程序终止."
        exit 1
    fi
    mkdir -p ${PREFIX}/etc/php.d
    \cp ${PREFIX}/etc/php-fpm.conf.default ${PREFIX}/etc/php-fpm.conf
    \cp ${PREFIX}/etc/php-fpm.d/www.conf.default ${PREFIX}/etc/php-fpm.d/www.conf
    [[ -f ${PREFIX}/lib/php.ini ]] && rm -f ${PREFIX}/lib/php.ini
    if ! wget -O ${PREFIX}/lib/php.ini -c ${DOWNLOAD_URL}/php.ini; then
        printnew "下载php.ini失败, 程序终止."
        exit 1
    fi
    phpext_dir=$(${PREFIX}/bin/php-config --extension-dir)
    sed -i "s%This_php_extension_dir%${phpext_dir}%g" ${PREFIX}/lib/php.ini
    cd ..
    
    # 复制ioncube扩展
    printnew -green "安装 ioncube 扩展..."
    if ! tar zxf ioncube_loaders_lin_${ZEND_ARCH}.tar.gz; then
        printnew -red "解压ioncube_loaders_lin_${ZEND_ARCH}失败, 程序终止."
        exit 1
    fi
    if ! \cp -f ioncube/ioncube_loader_lin_${IONCUBE_VER}.so ${phpext_dir}/ioncube_loader_lin_${IONCUBE_VER}.so; then
        printnew -red "安装ioncube_loader_lin_${IONCUBE_VER}失败, 程序终止."
        exit 1
    fi
    chmod +x $phpext_dir/ioncube_loader_lin_${IONCUBE_VER}.so
    
    # 编译并安装apcu扩展
    printnew -green "安装 apcu 扩展..."
    if ! tar zxf ${APCU_FILE}; then
        printnew -red "解压${APCU_FILE}失败, 程序终止."
        exit 1
    fi
    cd ${APCU_DIR}
    ${PREFIX}/bin/phpize
    if ! ./configure --with-php-config=${PREFIX}/bin/php-config; then
        printnew -red "配置${APCU_FILE}失败, 程序终止."
        exit 1
    fi
    if ! make -j ${CPUSU}; then
        printnew -red "编译${APCU_FILE}失败, 程序终止."
        exit 1
    fi
    if ! make install; then
        printnew -red "安装${APCU_FILE}失败, 程序终止."
        exit 1
    fi
    cd ..
    
    # 安装php-fpm服务
    printnew -green "下载/安装php服务..."
    if [[ "$(Check_OS)" == "centos7" || "$(Check_OS)" == "redhat7" ]]; then
        [[ -f php-fpm.service ]] && rm -f php-fpm.service
        if ! wget -O php-fpm.service -c ${DOWNLOAD_URL}CentOS-7; then
            printnew -red "下载失败, 程序终止."
            exit 1
        else
            sed -i "s/PHP_VERSION/${PHP_NAME}/g" ./php-fpm.service
            if \cp ./php-fpm.service /usr/lib/systemd/system/php-fpm.service; then
                chmod 754 /usr/lib/systemd/system/php-fpm.service >/dev/null 2>&1
                systemctl enable php-fpm.service
                systemctl daemon-reload
                if ! systemctl status php-fpm.service; then
                    systemctl start php-fpm.service
                else
                    systemctl restart php-fpm.service
                fi
            else
                printnew -red "安装服务失败."
            fi
        fi
    fi
    if [[ "$(Check_OS)" == "centos6" || "$(Check_OS)" == "redhat6" ]]; then
        [[ -f php-fpm ]] && rm -f php-fpm
        if ! wget -O php-fpm -c ${DOWNLOAD_URL}CentOS-6; then
            printnew -red "下载失败, 程序终止."
            exit 1
        else
            sed -i "s/PHP_VERSION/${PHP_NAME}/g" ./php-fpm
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
    
    cd ${cur_dir}/.. && rm -rf ${cur_dir}
    rm -f ${MY_SCRIPT}
    printnew -green "${PHP_NAME} installed."
fi
