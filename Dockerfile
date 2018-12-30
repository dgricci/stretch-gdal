# Dockerfile for GDAL - Geospatial Data Abstraction Library 
FROM dgricci/proj:5.2.0
MAINTAINER Didier Richard <didier.richard@ign.fr>
LABEL       version="1.3.0" \
            gdal="v2.4.0" \
            os="Debian Stretch" \
            description="GDAL library and softwares"

ARG GDAL_VERSION
ENV GDAL_VERSION ${GDAL_VERSION:-2.4.0}
ARG GDAL_DOWNLOAD_URL
ENV GDAL_DOWNLOAD_URL ${GDAL_DOWNLOAD_URL:-http://download.osgeo.org/gdal/$GDAL_VERSION/gdal-$GDAL_VERSION.tar.gz}
ARG GDAL_AUTOTEST_DOWNLOAD_URL
ENV GDAL_AUTOTEST_DOWNLOAD_URL ${GDAL_AUTOTEST_DOWNLOAD_URL:-http://download.osgeo.org/gdal/$GDAL_VERSION/gdalautotest-$GDAL_VERSION.tar.gz}
# compilation/install is in GDAL_HOME, but everything is copied in /usr ...
ARG GDAL_HOME
ENV GDAL_HOME ${GDAL_HOME:-/opt/gdal-$GDAL_VERSION}
ENV GDAL_DATA /usr/share/gdal

COPY build.sh /tmp/build.sh
RUN /tmp/build.sh && rm -f /tmp/build.sh

# Externally accessible data is by default put in /geodata
# use -v at run time !
WORKDIR /geodata

# Output version and capabilities by default.
CMD gdalinfo --version && gdalinfo --formats && ogrinfo --formats

