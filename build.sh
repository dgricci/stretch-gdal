#!/bin/bash

# Dockerfile for GDAL - Geospatial Data Abstraction Library 

# Check over there : https://salsa.debian.org/debian-gis-team/gdal/blob/master/debian/rules

# Exit on any non-zero status.
trap 'exit' ERR
set -E

echo "Compiling GDAL ${GDAL_VERSION}..."

# get php5 as php7 is not yet supported by nor gdal, neither mapserver :
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php56.list
# thanks to @debsuryorg

01-install.sh
# default-jdk-headless provides, through openjdk-8-jre-headless, libjmv.so needed when using the flag with-java !
apt-get -qy --no-install-recommends install \
    libarmadillo-dev \
    libboost-regex1.62-dev \
    libboost-system1.62-dev \
    libboost-thread1.62-dev \
    libcfitsio-dev \
    libcharls-dev \
    libcurl4-gnutls-dev \
    libdap-dev \
    libepsilon-dev \
    libfreexl-dev \
    libgeos-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjson-c-dev \
    libkml-dev \
    liblcms2-dev \
    liblzma-dev \
    libmongoclient-dev \
    libnetcdf-dev \
    libopenjp2-7-dev \
    libpcre3-dev \
    libpodofo-dev \
    libpq-dev \
    libspatialite-dev \
    libsqlite3-dev \
    libtiff-dev \
    liburiparser-dev \
    libwebp-dev \
    libxerces-c-dev \
    libxml2-dev \
    libmdb2 \
    libtiff-tools \
    php5.6-dev \
    python-dev \
    unixodbc-dev \
    bash-completion \
    gpsbabel \
    hdf4-tools \
    netcdf-bin \
    default-jdk-headless \
    default-libmysqlclient-dev \
    pngtools \
    python-numpy \
    python-setuptools \
    zlib1g-dev
# configure does not found mongoclient as it is spreaded in /usr/include and
# /usr/lib/x86_64-linux-gnu :
( \
    cd /usr/lib && \
    ln -s x86_64-linux-gnu/libmongoclient.a && \
    ln -s x86_64-linux-gnu/libmongoclient.so && \
    ln -s x86_64-linux-gnu/libmongoclient.so.0 && \
    ln -s x86_64-linux-gnu/libmongoclient.so.0.0.0 \
)
# libjvm.so not found :
echo "/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64" >> /etc/ld.so.conf.d/java.conf
echo "/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server" >> /etc/ld.so.conf.d/java.conf
ldconfig

cd /tmp
wget --no-verbose "$GDAL_DOWNLOAD_URL"
wget --no-verbose "$GDAL_DOWNLOAD_URL.md5"
md5sum --strict -c gdal-$GDAL_VERSION.tar.gz.md5
tar xzf gdal-$GDAL_VERSION.tar.gz
rm -f gdal-$GDAL_VERSION.tar.gz*

# compiling php :
#gdal_wrap.cpp:935:41: error: invalid conversion from ‘const char*’ to ‘char*’ [-fpermissive]
#gdal_wrap.cpp:2064:18: warning: ‘CPLErr GDALGetRasterHistogram(GDALRasterBandH, double, double, int, int*, int, int, GDALProgressFunc, void*)’ is deprecated [-Wdeprecated-declarations] 
#...
#add -fpermissive and -Wdeprecated-declarations to swig/php/GNUmakefile
{ \
    cd gdal-$GDAL_VERSION ; \
    touch config.rpath ; \
    ./configure \
        --prefix=/usr \
        --with-armadillo=yes \
        --with-cfitsio=/usr/lib/x86_64-linux-gnu \
        --with-charls \
        --with-curl=/usr/bin \
        --with-ecw=no \
        --with-epsilon=yes \
        --with-freexl=yes \
        --with-geos=yes \
        --with-geotiff=internal \
        --with-gif=internal \
        --with-grass=no \
        --with-hdf4=/usr \
        --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial/ \
        --with-jpeg=internal \
        --with-jpeg12 \
        --with-libjson-c=/usr \
        --with-libkml=yes \
        --with-liblzma=yes \
        --with-libtiff=yes \
        --with-libz=/usr/lib/x86_64-linux-gnu \
        --with-mdb \
        --with-mrsid=no \
        --with-mysql=/usr/bin/mysql_config \
        --with-mongocxx=/usr \
        --with-netcdf=/usr \
        --with-odbc=/usr/lib/x86_64-linux-gnu \
        --with-ogdi=no \
        --with-openjpeg \
        --with-pcraster=internal \
        --with-pcre \
        --with-png=internal \
        --with-pg=/usr/bin/pg_config \
        --with-podofo=yes \
        --with-poppler=no \
        --with-proj \
        --with-proj5-api=yes \
        --with-qhull=internal \
        --with-sosi=no \
        --with-spatialite=yes \
        --with-sqlite3=yes \
        --with-threads \
        --with-webp=yes \
        --with-xerces=yes \
        --with-xml2=/usr/bin \
        --with-php \
        --with-python \
        --with-java=/usr/lib/jvm/java-8-openjdk-amd64 \
        && \
        sed -i -e 's/\(CFLAGS=-fpic\)/\1 -fpermissive -Wdeprecated-declarations/' swig/php/GNUmakefile && \
    NPROC=$(nproc) && \
    make -j$NPROC 2>&1 | tee ../../make.log && \
    make install ; \
    ldconfig ; \
    exit 0 ; \
    cd .. ; \
    rm -fr gdal-$GDAL_VERSION ; \
}

# FIXME: run autotest ...

# clean
# don't auto-remove otherwise all libs are gone (not only headers) :
apt-get purge -y \
    libarmadillo-dev \
    libboost-regex1.62-dev \
    libboost-system1.62-dev \
    libboost-thread1.62-dev \
    libblas-dev \
    libbison-dev \
    liblapack-dev \
    libcfitsio-dev \
    libcharls-dev \
    libcurl4-gnutls-dev \
    libdap-dev \
    libepsilon-dev \
    libfreexl-dev \
    libgeos-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjson-c-dev \
    libkml-dev \
    liblcms2-dev \
    libltdl-dev \
    liblzma-dev \
    libmariadbclient-dev \
    libmongoclient-dev \
    libnetcdf-dev \
    libopenjp2-7-dev \
    libpcre3-dev \
    libpodofo-dev \
    libpq-dev \
    libspatialite-dev \
    libsqlite3-dev \
    libtiff-dev \
    liburiparser-dev \
    libwebp-dev \
    libxerces-c-dev \
    libxml2-dev \
    libxml2-dev \
    linux-libc-dev \
    php5.6-dev \
    python-dev \
    unixodbc-dev \
    zlib1g-dev
01-uninstall.sh y

exit 0

