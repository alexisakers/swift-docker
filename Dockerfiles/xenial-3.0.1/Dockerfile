# Configuration
FROM ubuntu:16.04
MAINTAINER Alexis Aubry Radanovic <aleks@alexis-aubry-radanovic.me>
RUN mkdir /data
VOLUME /data

ARG SWIFT_VERSION=3.0.1-RELEASE
ARG SWIFT_VERSION_CODE=3.0.1
ARG SWIFT_TARBALL_PATH=swift-3.0.1-release/ubuntu1604
ARG SWIFT_PLATFORM=ubuntu16.04

ADD build_scripts/ /build_scripts

# 1- Installation
RUN sh /build_scripts/apt.sh
RUN sh /build_scripts/curl.sh
RUN sh /build_scripts/swift.sh
RUN rm -rf /build_scrips

# 2- Add the toolchain to the path
ENV PATH /swift/3.0.1/usr/bin:$PATH