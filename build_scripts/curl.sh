# 1- Configuration
mkdir /staging && cd /staging
apt-get build-dep --assume-yes curl

# 2- Install libnghhtp2
git clone https://github.com/nghttp2/nghttp2
cd nghttp2
autoreconf -i
automake
autoconf
./configure --enable-lib-only --prefix=/usr/
make
make install

# 3- Install libcurl and curl
cd /staging
wget https://curl.haxx.se/download/curl-7.51.0.tar.gz
tar -zxf curl-7.51.0.tar.gz
cd curl-7.51.0
./configure --prefix=/usr --with-nghttp2=/usr --with-ssl
make
make install
ldconfig

# 4- Cleanup
cd / && rm -rf /staging