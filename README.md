# CentOS PHP7.x 安装脚本


注意: 

  脚本目前理论支持CentOS6,7和Redhat6,7, 由于Redhat是商业系统, 所以我仅在CentOS6,7上完美测试成功.
  
默认安装目前最新版本的PHP-7.x及APCu

安装方法A:

    git clone https://github.com/viagram/PHP_Install.git && cd PHP_Install && sh install.sh;cd ..

安装方法B:

    curl -sk https://codeload.github.com/viagram/PHP_Install/zip/master -o master.zip && unzip -f master.zip && rm -f master.zip && cd PHP_Install-master && sh install.sh

按提示操作, 基本按几下回车键即可.
