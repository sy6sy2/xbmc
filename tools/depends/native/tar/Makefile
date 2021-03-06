include ../../Makefile.include
PREFIX=$(NATIVEPREFIX)
PLATFORM=$(NATIVEPLATFORM)
DEPS= ../../Makefile.include Makefile

# app name, version
APPNAME=tar
VERSION=1.32
SOURCE=$(APPNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

ifeq ($(NATIVE_OS),osx)
# https://openradar.appspot.com/radar?id=6160634819379200
PLATFORM_CONFIGURE=gl_cv_func_getcwd_abort_bug=no ac_cv_func_futimens=no ac_cv_func_utimensat=no
endif

export LIBTOOL=builds/unix/libtool
export PATH:=$(PREFIX)/bin:$(PATH)
CONFIGURE=./configure --prefix=$(PREFIX) \
  --program-transform-name=s/tar/gtar/   \
  --disable-dependency-tracking ac_cv_func_fdopendir=no \
  $(PLATFORM_CONFIGURE)

APP=$(PLATFORM)/src/tar
APPBIN=$(PREFIX)/bin/tar

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	-rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); $(AUTORECONF)
	cd $(PLATFORM); $(CONFIGURE)

$(APP): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)

.installed-$(PLATFORM): $(APP)
	$(MAKE) -C $(PLATFORM) install
	rm -f $(PREFIX)/bin/tar $(PREFIX)/bin/gnutar
	cd $(PREFIX)/bin; ln -s gtar tar; ln -s gtar gnutar
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
