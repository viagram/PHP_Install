#!/bin/sh
# By viagram <viagram.yang@gmail.com>

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

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
	if echo ${Text} | egrep -io "(centos[a-z ]*5|red[a-z ]*hat[a-z ]*5)" >/dev/null 2>&1; then echo centos5
	elif echo ${Text} | egrep -io "(centos[a-z ]*6|red[a-z ]*hat[a-z ]*6)" >/dev/null 2>&1; then echo centos6
	elif echo ${Text} | egrep -io "(centos[a-z ]*7|red[a-z ]*hat[a-z ]*7)" >/dev/null 2>&1; then echo centos7
	elif echo ${Text} | egrep -io "Fedora[a-z ]*[0-9]{1,2}" >/dev/null 2>&1; then echo fedora
	elif echo ${Text} | egrep -io "debian[a-z /]*[0-9]{1,2}" >/dev/null 2>&1; then echo debian
	elif echo ${Text} | egrep -io "ubuntu" >/dev/null 2>&1; then echo ubuntu
	fi
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
		if ! command -v ${name} >/dev/null 2>&1; then
			[[ "${name}" == "pip" ]] && name="python-pip"
			[[ "${name}" == "setsid" ]] && name="util-linux"
			[[ "${name}" == "crontab" ]] && name="vixie-cron"
			printnew -a -green "	正在安装: "
			printnew -yellow ${name}
			[[ "$(Check_OS)" == "centos6" || "$(Check_OS)" == "centos7" ]] && yum install -y ${name} >/dev/null 2>&1
			[[ "$(Check_OS)" == "fedora" ]] && dnf install -y ${name} >/dev/null 2>&1
			[[ "$(Check_OS)" == "ubuntu" ]] && apt install -y ${name} >/dev/null 2>&1
		fi
	done
}

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1";} #大于
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1";} #大于或等于
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1";} #小于
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1";} #小于或等于

####################################################################################################################
cur_dir=${my_dir}
	
if [[ "$(Check_OS)" != "centos7" && "$(Check_OS)" != "centos6" ]]; then
	printnew -red "目前仅支持CentOS6,7及Redhat6,7系统."
	exit 1
else
	printnew -a -green "获取版本信息..."
	if [[ -n ${1} ]]; then
		PHP_NAME='php-'${1}
	else
		PHP_NAME=$(curl -sk --retry 3 --speed-time 10 --speed-limit 1 --connect-timeout 10 https://www.php.net/downloads.php | egrep -io '/distributions/php-([0-9]{1,2}.){3}tar.gz' | sort -Vu | awk 'END{print}' | egrep -io 'php-([0-9]{1,2}.){2}[0-9]{1,2}')
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
	if ! yum -y install gcc gcc-c++ kernel-devel kernel-ml-devel-$(uname -r) bzip2-devel libxml2-devel curl-devel db4-devel libjpeg-devel libpng-devel \
	freetype-devel pcre-devel zlib-devel sqlite-devel unzip bzip2 mhash-devel openssl-devel php-mcrypt \
	libmcrypt libmcrypt-devel libtool-ltdl libtool-ltdl-devel wget cmake; then
		printnew -red "更新和安装必备组件包失败, 程序终止."
		exit 1
	fi
	
	printnew -green "下载${PHP_NAME}源码包..."
	[[ -f ${PHP_NAME}.tar.gz ]] && rm -f ${PHP_NAME}.tar.gz
	if ! wget -O ${PHP_NAME}.tar.gz -c https://www.php.net/distributions/${PHP_NAME}.tar.gz --no-check-certificate --tries=5 --timeout=10; then
		printnew -red "下载失败, 程序终止."
		exit 1
	fi
	
	printnew -green "下载apcu扩展包..."
	APCU_URL=$(curl -sk --retry 3 --speed-time 10 --speed-limit 1 --connect-timeout 10 https://pecl.php.net/package/APCu | egrep -io '/get/apcu-([0-9]{1,2}.){3}tgz' | head -n 1 | awk '{print "https://pecl.php.net"$0}')
	APCU_FILE=$(basename ${APCU_URL})
	APCU_DIR=${APCU_FILE%.*}
	[[ -f ${APCU_FILE} ]] && rm -f ${APCU_FILE}
	if ! wget -O ${APCU_FILE} -c ${APCU_URL} --tries=5 --timeout=10; then
		printnew -red "下载失败, 程序终止."
		exit 1
	fi
	
	CMAKE_VER=$(cmake --version | egrep -io '([0-9]{1,2}\.){2}[0-9]{1,2}')
	if version_lt ${CMAKE_VER} '3.15.0'; then
		printnew -green "下载CMake源码包..."
		CMAKE_URL=$(curl -sk --retry 3 --speed-time 10 --speed-limit 1 --connect-timeout 10 'https://github.com/Kitware/CMake/releases/latest' | egrep -io '([0-9]{1,2}\.){2}[0-9]{1,2}' | awk '{print "https://github.com/Kitware/CMake/releases/download/v"$0"/cmake-"$0".tar.gz"}')
		CMAKE_FILE=$(basename ${CMAKE_URL})
		CMAKE_DIR=${CMAKE_FILE//'.tar.gz'/''}
		#CMAKE_DIR=${CMAKE_FILE/.tar.gz/}
		[[ -f ${CMAKE_FILE} ]] && rm -f ${CMAKE_FILE}
		if ! wget -O ${CMAKE_FILE} -c ${CMAKE_URL} --tries=5 --timeout=10; then
			printnew -red "下载失败, 程序终止."
			exit 1
		fi
		printnew -a -green "解压${CMAKE_FILE}..."
		if ! tar zxf ${CMAKE_FILE}; then
			printnew -red "解压失败, 程序终止."
			exit 1
		else
			printnew -green "解压成功"
		fi
		CMAKE_CMD=$(command -v cmake)
		[[ -z ${MAKE_CMD} ]] && CMAKE_CMD=/usr/bin/cmake || yum remove -y cmake
		cd ${CMAKE_DIR}
		./bootstrap
		printnew -green "开始编译${CMAKE_DIR}..."
		if ! make; then
			printnew -red "编译${CMAKE_DIR}失败, 程序终止."
			exit 1
		fi
		make install
		cd -
		\cp -f ${MAKE_CMD} ${MAKE_CMD}.bak
		ln -sf /usr/local/bin/cmake ${MAKE_CMD}
		source /etc/profile

		printnew -green "下载libzip源码包..."
		LIBZIP_URL=$(curl -sk --retry 3 --speed-time 10 --speed-limit 1 --connect-timeout 10 https://libzip.org/download/ | egrep -io '/download/libzip-([0-9]{1,2}\.){3}tar.gz' | head -n 1 | awk '{print "https://libzip.org"$0}')
		LIBZIP_FILE=$(basename ${LIBZIP_URL})
		LIBZIP_DIR=${LIBZIP_FILE//'.tar.gz'/''}
		#LIBZIP_DIR=${LIBZIP_FILE/.tar.gz/}
		[[ -f ${LIBZIP_FILE} ]] && rm -f ${LIBZIP_FILE}
		if ! wget -O ${LIBZIP_FILE} -c ${LIBZIP_URL} --tries=5 --timeout=10; then
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
#		cat >> /etc/ld.so.conf<<-EOF
#/usr/local/lib64
#/usr/local/lib
#/usr/lib
#/usr/lib64 
#EOF
		ldconfig -v
	fi
	
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
	CONFIG_CMD="./configure --prefix=${PREFIX} --with-config-file-scan-dir=${PREFIX}/etc/php.d --with-libdir=${LIB} --enable-fastcgi --enable-fpm --with-mysql --with-mysqli --with-pdo-mysql --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr/include/libxml2/libxml --enable-xml --disable-fileinfo --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-pear --with-gettext --enable-calendar --with-openssl"
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
	\cp -rf php.ini ${PREFIX}/lib/php.ini

	phpext_dir=$(${PREFIX}/bin/php-config --extension-dir)
	sed -i "s%This_php_extension_dir%${phpext_dir}%g" ${PREFIX}/lib/php.ini

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
	
	# 安装php-fpm服务
	printnew -green "安装php-fpm服务..."
	if [[ "$(Check_OS)" == "centos7" ]]; then
		sed -i "s/PHP_VERSION/${PHP_NAME}/g" CentOS-7
		if \cp -rf CentOS-7 /usr/lib/systemd/system/php-fpm.service; then
			chmod 754 /usr/lib/systemd/system/php-fpm.service >/dev/null 2>&1
			systemctl enable php-fpm.service
			systemctl daemon-reload
			if systemctl status php-fpm.service; then
				systemctl restart php-fpm.service
			else
				systemctl start php-fpm.service
			fi
		else
			printnew -red "安装服务失败."
		fi
	fi
	if [[ "$(Check_OS)" == "centos6" ]]; then
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
	rm -f ${my_path}
	printnew -green "${PHP_NAME} installed."
fi
