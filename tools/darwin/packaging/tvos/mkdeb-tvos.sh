#!/bin/sh

set -ex

# usage: ./mkdeb-tvos.sh release/debug (case insensitive)
# Allows us to run mkdeb-tvos.sh from anywhere in the three, rather than the tools/darwin/packaging/tvos folder only
NATIVEPREFIX=/Users/Shared/xbmc-depends/x86_64-darwin18.5.0-native
SWITCH=`echo $1 | tr [A-Z] [a-z]`
DIRNAME=`dirname $0`
DSYM_TARGET_DIR=/Users/Shared/xbmc-depends/dSyms
DSYM_FILENAME=Kodi.app.dSYM
ARM64=false

if [ "${SWITCH#*debug}" != "${SWITCH}" ]; then
  echo "Packaging Debug target for tvOS"
  APP="$DIRNAME/../../../../build/Debug-iphoneos/Kodi.app"
  DSYM="$DIRNAME/../../../../build/Debug-iphoneos/$DSYM_FILENAME"
elif [ "${SWITCH#*release}" != "${SWITCH}" ]; then
  echo "Packaging Release target for tvOS"
  APP="$DIRNAME/../../../../build/Release-iphoneos/Kodi.app"
  DSYM="$DIRNAME/../../../../build/Release-iphoneos/$DSYM_FILENAME"
else
  echo "You need to specify the build target"
  exit 1
fi

# check if build is 64-bit
if [[ "$(lipo -info "$APP/Kodi" | awk '{print $NF}')" == "arm64" ]]; then
  ARM64=true
fi

#copy bzip2 of dsym to xbmc-depends install dir
if [ -d $DSYM ]; then
  if [ -d $DSYM_TARGET_DIR ]; then
    tar -C $DSYM/.. -c $DSYM_FILENAME/ | bzip2 > $DSYM_TARGET_DIR/`$DIRNAME/../gitrev-posix`-${DSYM_FILENAME}.tar.bz2
  fi
fi


if [ ! -d $APP ]; then
  echo "Kodi.app not found! are you sure you built $1 target?"
  exit 1
fi

# also check for SIP (System Integrity Protection) here (via csrutil) - fakeroot et al are not working when it is enabled
# fall back to oldschool sudo in that case
if [ -f "${NATIVEPREFIX}/bin/fakeroot" -a "`csrutil status | grep enabled`"x == "x" ]; then
  SUDO="${NATIVEPREFIX}/bin/fakeroot"
elif [ -f "/usr/bin/sudo" ]; then
  SUDO="/usr/bin/sudo"
fi
if [ -f "${NATIVEPREFIX}/bin/dpkg-deb" ]; then
  # make sure we pickup our tar, gnutar will fail when dpkg -i
  bin_path=$(cd ${NATIVEPREFIX}/bin; pwd)
  export PATH=${bin_path}:${PATH}
fi

PACKAGE=org.xbmc.kodi-tvos
PACKAGE_ARM64="${PACKAGE}64"

VERSION=18.2
REVISION=0

if [ "rc1" != "" ]; then
  REVISION=$REVISION~rc1
fi
# customize revision string
[ ! -z "$2" ] && REVISION="$2"

ARCHIVE=${PACKAGE}_${VERSION}-${REVISION}_iphoneos-arm.deb

# package identifier for arm64
$ARM64 && ARCHIVE=${PACKAGE_ARM64}_${VERSION}-${REVISION}_iphoneos-arm.deb

SIZE="$(du -s -k ${APP} | awk '{print $1}')"

echo Creating $PACKAGE package version $VERSION revision $REVISION
${SUDO} rm -rf $DIRNAME/$PACKAGE
${SUDO} rm -rf $DIRNAME/$ARCHIVE

# create debian control file.
mkdir -p $DIRNAME/$PACKAGE/DEBIAN
if $ARM64; then
  echo "Package: $PACKAGE_ARM64"                  >  $DIRNAME/$PACKAGE/DEBIAN/control
  echo "Name: Kodi-tvOS (64-bit)"            >> $DIRNAME/$PACKAGE/DEBIAN/control
  echo "Depends: firmware (>= 7.0)"               >> $DIRNAME/$PACKAGE/DEBIAN/control
  echo "Pre-Depends: cy+cpu.arm64"                >> $DIRNAME/$PACKAGE/DEBIAN/control
  echo "Conflicts: $PACKAGE"                      >> $DIRNAME/$PACKAGE/DEBIAN/control
  echo "Replaces: $PACKAGE"                       >> $DIRNAME/$PACKAGE/DEBIAN/control
else
  echo "Package: $PACKAGE"                        >  $DIRNAME/$PACKAGE/DEBIAN/control
  echo "Name: Kodi-tvOS"                     >> $DIRNAME/$PACKAGE/DEBIAN/control
  echo "Depends: firmware (>= 5.1)"               >> $DIRNAME/$PACKAGE/DEBIAN/control
fi
echo "Priority: Extra"                            >> $DIRNAME/$PACKAGE/DEBIAN/control
echo "Version: $VERSION-$REVISION"                >> $DIRNAME/$PACKAGE/DEBIAN/control
echo "Architecture: iphoneos-arm"                 >> $DIRNAME/$PACKAGE/DEBIAN/control
echo "Installed-Size: $SIZE"                      >> $DIRNAME/$PACKAGE/DEBIAN/control
echo "Description: Kodi Entertainment Center for tvOS" >> $DIRNAME/$PACKAGE/DEBIAN/control
echo "Homepage: http://kodi.tv/"                 >> $DIRNAME/$PACKAGE/DEBIAN/control
echo "Maintainer: Memphiz"                        >> $DIRNAME/$PACKAGE/DEBIAN/control
echo "Author: Team-Kodi"                    >> $DIRNAME/$PACKAGE/DEBIAN/control
echo "Section: Multimedia"                        >> $DIRNAME/$PACKAGE/DEBIAN/control
echo "Icon: file:///Applications/Kodi.app/AppIcon57x57.png" >> $DIRNAME/$PACKAGE/DEBIAN/control

# prerm: called on remove and upgrade - get rid of existing bits.
echo "#!/bin/sh"                                  >  $DIRNAME/$PACKAGE/DEBIAN/prerm
echo "find /Applications/Kodi.app -delete"  >> $DIRNAME/$PACKAGE/DEBIAN/prerm
chmod +x $DIRNAME/$PACKAGE/DEBIAN/prerm

# postinst: nothing for now.
echo "#!/bin/sh"                                  >  $DIRNAME/$PACKAGE/DEBIAN/postinst
echo "chown -R mobile:mobile /Applications/Kodi.app" >> $DIRNAME/$PACKAGE/DEBIAN/postinst
cat $DIRNAME/../migrate_to_kodi_tvos.sh            >> $DIRNAME/$PACKAGE/DEBIAN/postinst
echo "/usr/bin/uicache"                           >>  $DIRNAME/$PACKAGE/DEBIAN/postinst
echo "echo 'finish:respringing ...'"              >>  $DIRNAME/$PACKAGE/DEBIAN/postinst
chmod +x $DIRNAME/$PACKAGE/DEBIAN/postinst

# prep Kodi.app
mkdir -p $DIRNAME/$PACKAGE/Applications
cp -r $APP $DIRNAME/$PACKAGE/Applications/
find $DIRNAME/$PACKAGE/Applications/ -name '.svn' -exec rm -rf {} \;
find $DIRNAME/$PACKAGE/Applications/ -name '.git*' -exec rm -rf {} \;
find $DIRNAME/$PACKAGE/Applications/ -name '.DS_Store'  -exec rm -rf {} \;
find $DIRNAME/$PACKAGE/Applications/ -name '*.xcent'  -exec rm -rf {} \;

# set ownership to root:root
${SUDO} chown -R 0:0 $DIRNAME/$PACKAGE

echo Packaging $PACKAGE
# Tell tar, pax, etc. on Mac OS X 10.4+ not to archive
# extended attributes (e.g. resource forks) to ._* archive members.
# Also allows archiving and extracting actual ._* files.
export COPYFILE_DISABLE=true
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
#
${SUDO} dpkg-deb -bZ lzma $DIRNAME/$PACKAGE $DIRNAME/$ARCHIVE
${SUDO} chown 501:20 $DIRNAME/$ARCHIVE
dpkg-deb --info $DIRNAME/$ARCHIVE
dpkg-deb --contents $DIRNAME/$ARCHIVE

# clean up by removing package dir
${SUDO} rm -rf $DIRNAME/$PACKAGE
