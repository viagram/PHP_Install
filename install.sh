#!/bin/sh
# By viagram <viagram.yang@gmail.com>

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36'
my_path="$(dirname $(readlink -f $0))/$(basename $0)"
my_dir="$(dirname ${my_path})"

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
    Text=$(cat /etc/*-release)
    echo ${Text} | egrep -iq "(centos[a-z ]*5|red[a-z ]*hat[a-z ]*5)" && echo centos5 && return
    echo ${Text} | egrep -iq "(centos[a-z ]*6|red[a-z ]*hat[a-z ]*6)" && echo centos6 && return
    echo ${Text} | egrep -iq "(centos[a-z ]*7|red[a-z ]*hat[a-z ]*7)" && echo centos7 && return
    echo ${Text} | egrep -iq "(centos[a-z ]*8|red[a-z ]*hat[a-z ]*8)" && echo centos8 && return
    echo ${Text} | egrep -iq "(Rocky[a-z ]*8|red[a-z ]*hat[a-z ]*8)" && echo rockylinux8 && return
    echo ${Text} | egrep -iq "debian[a-z /]*[0-9]{1,2}" && echo debian && return
    echo ${Text} | egrep -iq "Fedora[a-z ]*[0-9]{1,2}" && echo fedora && return
    echo ${Text} | egrep -iq "OpenWRT[a-z ]*" && echo openwrt && return
    echo ${Text} | egrep -iq "ubuntu" && echo ubuntu && return
}

function printnew(){
    typeset -l CHK
    WENZHI=""
    COLOUR=""
    HUANHANG=0
    for PARSTR in "${@}"; do
        CHK="${PARSTR}"
        if echo "${CHK}" | egrep -io "^\-[[:graph:]]*" >/dev/null 2>&1; then
            case "${CHK}" in
                -black) COLOUR="\033[30m";;
                -red) COLOUR="\033[31m";;
                -green) COLOUR="\033[32m";;
                -yellow) COLOUR="\033[33m";;
                -blue) COLOUR="\033[34m";;
                -purple) COLOUR="\033[35m";;
                -cyan) COLOUR="\033[36m";;
                -white) COLOUR="\033[37m";;
                -a) HUANHANG=1 ;;
                *) COLOUR="\033[37m";;
            esac
        else
            WENZHI+="${PARSTR}"
        fi
    done
    if [[ ${HUANHANG} -eq 1 ]]; then
        printf "${COLOUR}%b%s\033[0m" "${WENZHI}"
    else
        printf "${COLOUR}%b%s\033[0m\n" "${WENZHI}"
    fi
}

function CheckCommand(){
    local name=""
    for name in $(echo "$1" | sed 's/,/\n/g' | sed '/^$/d' | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g'); do
        if ! which ${name} >/dev/null 2>&1; then
            [[ "${name}" == "pip" ]] && name="python-pip"
            [[ "${name}" == "setsid" ]] && name="util-linux"
            [[ "${name}" == "crontab" ]] && name="vixie-cron"
            printnew -a -green "    正在安装: "
            printnew -yellow ${name}
            [[ "$(Check_OS)" == "centos6" || "$(Check_OS)" == "centos7" ]] && yum install -y ${name} >/dev/null 2>&1
            [[ "$(Check_OS)" == "fedora" || "$(Check_OS)" == "centos8" || "$(Check_OS)" == "rockylinux8" ]] && dnf install -y ${name} >/dev/null 2>&1
            [[ "$(Check_OS)" == "ubuntu" ]] && apt install -y ${name} >/dev/null 2>&1
        fi
    done
}

function install_cmake(){
    printnew -green "安装CMake..."
    which cmake >/dev/null 2>&1 && yum remove -y cmake
    cmake_ver_1=$(curl -#kL https://cmake.org/files/ | egrep -io 'v[0-9]{1,2}\.[0-9]{1,2}' | sort -ruV | head -n1)
    cmake_ver_2=$(curl -#kL https://cmake.org/files/${cmake_ver_1}/ | egrep -io 'cmake-[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}(|-rc5)-linux-x86_64.sh' | sort -ruV | head -n1)
    cmake_down_url="https://cmake.org/files/${cmake_ver_1}/${cmake_ver_2}"
    curl -#kL "${cmake_down_url}" -o "${cmake_ver_2}"
    bash "${cmake_ver_2}" --prefix=/usr/ --exclude-subdir
    rm -f "${cmake_ver_2}"
    source /etc/profile
}

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1";} #大于
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1";} #大于或等于
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1";} #小于
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1";} #小于或等于

####################################################################################################################
cur_dir=${my_dir}
    
if [[  "$(Check_OS)" != "rockylinux8" && "$(Check_OS)" != "centos8" && "$(Check_OS)" != "centos7" && "$(Check_OS)" != "centos6" ]]; then
    printnew -red "目前仅支持CentOS6,7及Redhat6,7,8系统."
    exit 1
else
    printnew -a -green "获取版本信息..."
    if [[ -n ${1} ]]; then
        PHP_NAME='php-'${1}
    else
        PHP_NAME=$(curl -#kL https://www.php.net/downloads.php | egrep -io '/distributions/php-([0-9]{1,2}.){3}tar.gz' | sort -Vu | awk 'END{print}' | egrep -io 'php-([0-9]{1,2}.){2}[0-9]{1,2}')
    fi
    if ! echo ${PHP_NAME} | egrep -io 'php-([0-9]{1,2}.){2}[0-9]{1,2}' >/dev/null 2>&1; then
        printnew -red "失败, 程序终止."
        exit 1
    fi
    PREFIX="/usr/local/${PHP_NAME}"
    PHP_VER=$(echo ${PHP_NAME} | sed 's/php-//g' | egrep -io '^[0-9]{1,2}.[0-9]{1,2}')
    CPUSU=$(cat /proc/cpuinfo | grep processor | wc -l)

    if [[ -z ${PHP_VER} ]]; then
        printnew -red "失败, 程序终止."
        exit 1
    else
        printnew -green "成功"
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
        cd ${cur_dir}/.. && rm -rf ${cur_dir}
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
    if [[ "$(Check_OS)" == "centos8" ||  "$(Check_OS)" == "rockylinux8" ]]; then
        dnf -y install gcc gcc-c++ kernel-devel oniguruma bzip2-devel libxml2-devel curl-devel  libjpeg-devel libpng-devel \
            p7zip-plugins freetype-devel pcre-devel zlib-devel sqlite-devel unzip bzip2 mhash-devel openssl-devel  \
            libmcrypt libmcrypt-devel libtool-ltdl libtool-ltdl-devel wget
    else
        yum -y install gcc gcc-c++ kernel-devel kernel-ml-devel-$(uname -r) oniguruma oniguruma-devel bzip2-devel libxml2-devel curl-devel db4-devel libjpeg-devel libpng-devel \
            p7zip-plugins freetype-devel pcre-devel zlib-devel sqlite-devel unzip bzip2 mhash-devel openssl-devel php-mcrypt \
        libmcrypt libmcrypt-devel libtool-ltdl libtool-ltdl-devel wget
    fi
    ln -sf $(which 7z) /usr/bin/7zr
    cd ${cur_dir}
    printnew -green "下载${PHP_NAME}源码包..."
    [[ -f ${PHP_NAME}.tar.gz ]] && rm -f ${PHP_NAME}.tar.gz
    if ! curl -A "${UA}" -#kLo ${PHP_NAME}.tar.gz https://www.php.net/distributions/${PHP_NAME}.tar.gz; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    
    printnew -green "下载apcu扩展包..."
    APCU_URL=$(curl -#kL https://pecl.php.net/package/APCu | egrep -io '/get/apcu-([0-9]{1,2}.){3}tgz' | head -n 1 | awk '{print "https://pecl.php.net"$0}')
    [[ -z ${APCU_URL} ]] && APCU_URL=$(curl -#kL https://pecl.php.net/package/APCu | egrep -io '/get/apcu-([0-9]{1,2}.){3}tgz' | head -n 1 | awk '{print "https://pecl.php.net"$0}')
    [[ -z ${APCU_URL} ]] && {
        printnew -red "获取apcu信息失败, 程序终止."
        exit 1
    }
    APCU_FILE=$(basename ${APCU_URL})
    APCU_DIR=${APCU_FILE%.*}
    [[ -f ${APCU_FILE} ]] && rm -f ${APCU_FILE}
    if ! curl -A "${UA}" -#kLo ${APCU_FILE} ${APCU_URL}; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    
    CMAKE_VER=$(cmake --version 2>/dev/null | egrep -io '(([0-9]{1,2}\.){2}[0-9]{1,2}|([0-9]{1,2}\.){2}[0-9]{1,2}-[a-z0-9]{1,3})' | echo 0.0.0)
    if version_lt ${CMAKE_VER} '3.15.0'; then
        install_cmake

        printnew -green "下载libzip源码包..."
        LIBZIP_URL=$(curl -#kL https://libzip.org/download/ | egrep -io '/download/libzip-([0-9]{1,2}\.){3}tar.gz' | head -n 1 | awk '{print "https://libzip.org"$0}')
        LIBZIP_FILE=$(basename ${LIBZIP_URL})
        LIBZIP_DIR=${LIBZIP_FILE//'.tar.gz'/''}
        #LIBZIP_DIR=${LIBZIP_FILE/.tar.gz/}
        [[ -f ${LIBZIP_FILE} ]] && rm -f ${LIBZIP_FILE}
        if ! curl -A "${UA}" -#kLo ${LIBZIP_FILE} ${LIBZIP_URL}; then
            printnew -red "下载失败, 程序终止."
            exit 1
        fi
        printnew -a -green "解压${LIBZIP_FILE}..."
        if ! tar zxf ${LIBZIP_FILE}; then
            printnew -red "解压失败, 程序终止."
            exit 1
        else
            printnew -green "解压成功"
        fi
        cd ${LIBZIP_DIR}
        mkdir build
        cd build
        cmake ..
        printnew -green "开始编译${LIBZIP_DIR}..."
        if ! make; then
            printnew -red "编译${LIBZIP_DIR}失败, 程序终止."
            exit 1
        fi
        make install
        cd ../..
#        cat >> /etc/ld.so.conf<<-EOF
#/usr/local/lib64
#/usr/local/lib
#/usr/lib
#/usr/lib64 
#EOF
        ldconfig -v
    fi

    printnew -green "下载freetype源码包..."
    freetype_url=$(curl -sk https://download.savannah.gnu.org/releases/freetype/ | egrep -io 'freetype-[0-9]{1,2}.[0-9]{1,2}.([0-9]{1,2}|[0-9]{1,2}.[0-9]{1,2}).tar.gz' | sort -ruV | head -n1 | awk  '{print "https://download.savannah.gnu.org/releases/freetype/"$0}')
    freetype_file=$(basename ${freetype_url})
    freetype_dir=$(echo ${freetype_file} | sed 's/.tar.gz//g')
    if ! curl -A "${UA}" -#kLo ${freetype_file} ${freetype_url}; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    tar --overwrite -zxf ${freetype_file}
    rm -f ${freetype_file}
    cd ${freetype_dir}
    ./configure --prefix=/usr/local/freetype #同上,指定安装目录
    make && make install
    cd -
    rm -rf ${freetype_dir}

    [[ ! -x /usr/local/icu/bin/icu-config ]] && {
        printnew -green "下载icu4c源码包..."
        if ! curl -A "${UA}" -#kLo icu4c-52_2-src.tgz https://github.com/unicode-org/icu/releases/download/release-52-2/icu4c-52_2-src.tgz; then
            printnew -red "下载失败, 程序终止."
            exit 1
        fi
        tar zxvf icu4c-52_2-src.tgz
        rm -f icu4c-52_2-src.tgz
        cd icu/source
        mkdir /usr/local/icu
        ./configure --prefix=/usr/local/icu
        make && make install
        cd -
        rm -rf icu*
    }
    
    export PKG_CONFIG_PATH="/usr/local/icu/lib/pkgconfig"

    printnew -green "下载libjpeg源码包..."
    libjpeg_url=$(curl -#kL https://www.ijg.org/files/ | egrep -io 'jpegsrc.v([0-9]{1,2}|[0-9]{1,2}.[0-9]{1,2})[a-z]{1,2}.tar.gz' | sort -ruV | head -n1 | awk  '{print "https://www.ijg.org/files/"$0}')
    libjpeg_file=$(basename ${libjpeg_url})
    libjpeg_version=$(echo ${libjpeg_file} | egrep -io '([0-9]{1,2}|[0-9]{1,2}.[0-9]{1,2})[a-z]{1,2}')
    if ! curl -A "${UA}" -#kLo ${libjpeg_file} ${libjpeg_url}; then
        printnew -red "下载失败, 程序终止."
        exit 1
    fi
    tar --overwrite -zxf ${libjpeg_file}
    rm -f ${libjpeg_file}
    cd jpeg-${libjpeg_version}
    ./configure --prefix=/usr/local/libjpeg --enable-shared #libjpeg默认不会以共享方式安装,所以需要打开
    make && make install
    cd -
    rm -rf jpeg-${libjpeg_version}

    # 编译并安装php
    printnew -a -green "解压${PHP_NAME}源码包..."
    if ! tar zxf ${PHP_NAME}.tar.gz; then
        printnew -red "解压失败, 程序终止."
        exit 1
    else
        printnew -green "解压成功"
    fi
    cd ${PHP_NAME}
    printnew -green "开始编译${PHP_NAME}..."
    CONFIG_CMD="./configure --prefix=${PREFIX} --with-config-file-scan-dir=${PREFIX}/etc/php.d --with-libdir=${LIB} --enable-fastcgi --enable-fpm --with-mysql --with-mysqli --with-pdo-mysql --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr/include/libxml2/libxml --enable-xml --disable-fileinfo --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-pear --with-gettext --enable-calendar --with-openssl --enable-intl --with-icu-dir=/usr/local/icu"
    if [ -f /usr/include/mcrypt.h ]; then
        CONFIG_CMD+=" --with-mcrypt"
    fi
    if ! ${CONFIG_CMD}; then
        echo ${CONFIG_CMD}
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
    cd -
    
    mkdir -p ${PREFIX}/etc/php.d
    \cp -rf ${PREFIX}/etc/php-fpm.conf.default ${PREFIX}/etc/php-fpm.conf
    \cp -rf ${PREFIX}/etc/php-fpm.d/www.conf.default ${PREFIX}/etc/php-fpm.d/www.conf
    [[ ! -f php.ini ]] && curl -A "${UA}" -#kLo php.ini https://raw.githubusercontent.com/viagram/PHP_Install/master/php.ini
    \cp -rf php.ini ${PREFIX}/lib/php.ini

    phpext_dir=$(${PREFIX}/bin/php-config --extension-dir)
    sed -i "s%This_php_extension_dir%${phpext_dir}%g" ${PREFIX}/lib/php.ini

    # 编译并安装gd展
    printnew -green "安装 gd 扩展..."
    cd ${PHP_NAME}/ext/gd/
    ${PREFIX}/bin/phpize
    ./configure --with-php-config=${PREFIX}/bin/php-config --with-jpeg=/usr/local/libjpeg --with-freetype=/usr/local/freetype
    make && make install
    cd -

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
    cd -

    fpm_fixa=$(cat ${PREFIX}/etc/php-fpm.conf | egrep -io '(^;emergency_restart_threshold[[:print:]]*|^emergency_restart_threshold[[:print:]]*)')
    fpm_fixb=$(cat ${PREFIX}/etc/php-fpm.conf | egrep -io '(^;emergency_restart_interval[[:print:]]*|^emergency_restart_interval[[:print:]]*)')
    fpm_fixc=$(cat ${PREFIX}/etc/php-fpm.conf | egrep -io '(^;process_control_timeout[[:print:]]*|^process_control_timeout[[:print:]]*)')
    fpm_fixd=$(cat ${PREFIX}/etc/php-fpm.d/www.conf | egrep -io '(^;pm.max_requests[[:print:]]*|^pm.max_requests[[:print:]]*)')
    sed -i "s/${fpm_fixa}/emergency_restart_threshold = 4/g" ${PREFIX}/etc/php-fpm.conf
    sed -i "s/${fpm_fixb}/emergency_restart_interval = 30s/g" ${PREFIX}/etc/php-fpm.conf
    sed -i "s/${fpm_fixc}/process_control_timeout = 10s/g" ${PREFIX}/etc/php-fpm.conf
    sed -i "s/${fpm_fixd}/pm.max_requests = 100/g" ${PREFIX}/etc/php-fpm.d/www.conf
    # 安装php-fpm服务
    printnew -green "安装php-fpm服务..."
    if [[ "$(Check_OS)" == "centos7" ||  "$(Check_OS)" == "centos8" ||  "$(Check_OS)" == "rockylinux8" ]]; then
        [[ ! -f CentOS-7 ]] && curl -A "${UA}" -#kLo CentOS-7 https://raw.githubusercontent.com/viagram/PHP_Install/master/CentOS-7
        sed -i "s/PHP_VERSION/${PHP_NAME}/g" CentOS-7
        if \cp -rf CentOS-7 /usr/lib/systemd/system/php-fpm.service; then
            chmod 754 /usr/lib/systemd/system/php-fpm.service >/dev/null 2>&1
            systemctl enable php-fpm.service
            systemctl daemon-reload
            if systemctl status php-fpm.service >/dev/null 2>&1; then
                systemctl restart php-fpm.service
            else
                systemctl start php-fpm.service
            fi
        else
            printnew -red "安装服务失败."
        fi
    fi
    if [[ "$(Check_OS)" == "centos6" ]]; then
        [[ ! -f CentOS-6 ]] && curl -A "${UA}" -#kLo CentOS-6  https://raw.githubusercontent.com/viagram/PHP_Install/master/CentOS-6
        sed -i "s/PHP_VERSION/${PHP_NAME}/g" CentOS-6
        if \cp -rf CentOS-6 /etc/rc.d/init.d/php-fpm; then
            chmod 754 /etc/rc.d/init.d/php-fpm >/dev/null 2>&1
            chkconfig --add php-fpm
            chkconfig php-fpm on
            if /etc/rc.d/init.d/php-fpm status >/dev/null 2>&1; then
                /etc/rc.d/init.d/php-fpm restart
            else
                /etc/rc.d/init.d/php-fpm start
            fi
        else
            printnew -red "安装服务失败."
        fi
    fi
    
    cd ${cur_dir}/.. && rm -rf ${cur_dir}
    cd ${PREFIX}/..
    ls | egrep -io 'php-([0-9]{1,2}.){2}[0-9]{1,2}' | egrep -iv ${PHP_NAME} | xargs rm -rf
    cd - >/dev/null 2>&1
    sed -i '/php-/d' /etc/profile
    echo -e "PATH=\${PATH}:/usr/local/${PHP_NAME}/bin\nexport PATH">>/etc/profile
    source /etc/profile
    #curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/${PHP_NAME}/bin
    #composer.phar require gemorroj/archive7z
    pear install Archive_Tar
    rm -f ${my_path}
    printnew -green "${PHP_NAME} 安装完成"

fi
