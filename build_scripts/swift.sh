# 1- Setup
mkdir /swift && cd /swift
mkdir /sta

SWIFT_FILE_BASE="swift-$SWIFT_VERSION-$SWIFT_PLATFORM"
SWIFT_BASE_URL="https://swift.org/builds/$SWIFT_TARBALL_PATH/swift-$SWIFT_VERSION/$SWIFT_FILE_BASE"

# 2- Download the binaries
curl -O $SWIFT_BASE_URL.tar.gz
curl -O $SWIFT_BASE_URL.tar.gz.sig

# 3- Import the PGP keys
wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -

# 4- Verify the PGP signature
gpg --keyserver hkp://pool.sks-keyservers.net --refresh-keys Swift
gpg --verify $SWIFT_FILE_BASE.tar.gz.sig

# 5- Extract the archive
mkdir $SWIFT_VERSION_CODE 
tar xzf $SWIFT_FILE_BASE.tar.gz -C $SWIFT_VERSION_CODE --strip-components=1

# 6- Cleanup
rm $SWIFT_FILE_BASE.tar.gz
rm $SWIFT_FILE_BASE.tar.gz.sig