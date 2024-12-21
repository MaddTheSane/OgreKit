ONIGURUMA_VERSION=Onigmo-Onigmo-6.2.0
OS_VERSION=$(shell uname -r)
BUILD_ARCH=$(shell uname -m)

UNIVERSAL_DIR=universal
INTEL_64_DIR=x86_64
ARM_64_DIR=arm64

export PATH := /opt/local/bin:$(PATH)

INTEL_64_CONFIGURE_FLAGS=--disable-dependency-tracking --host=x86_64-apple-darwin$(OS_VERSION) --build=$(BUILD_ARCH)-apple-darwin$(OS_VERSION)
ARM_64_CONFIGURE_FLAGS=--disable-dependency-tracking --host=arm64-apple-darwin$(OS_VERSION) --build=$(BUILD_ARCH)-apple-darwin$(OS_VERSION)

INTEL_64_SDK=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
INTEL_64_CC=/usr/bin/gcc -arch x86_64 -mmacosx-version-min=10.13

ARM_64_SDK=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
ARM_64_CC=/usr/bin/gcc -arch arm64 -mmacosx-version-min=11.0

ONIG_TARGET=libonigmo.la
LIBS_DIR=.libs
ONIGURUMA=libonigmo.a

install: $(UNIVERSAL_DIR)/$(ONIGURUMA)

all: $(UNIVERSAL_DIR)/$(ONIGURUMA)

$(UNIVERSAL_DIR)/$(ONIGURUMA): $(UNIVERSAL_DIR) $(ARM_64_DIR)/$(ONIG_TARGET) $(INTEL_64_DIR)/$(ONIG_TARGET)
	lipo -create $(ARM_64_DIR)/$(LIBS_DIR)/$(@F) $(INTEL_64_DIR)/$(LIBS_DIR)/$(@F) -output $(UNIVERSAL_DIR)/$(@F)

$(INTEL_64_DIR)/$(ONIG_TARGET): $(INTEL_64_DIR)
	cd $(@D);\
	./autogen.sh;\
	CC="$(INTEL_64_CC)" ./configure $(INTEL_64_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -g -O2@CFLAGS = -g -O2 -isysroot $(INTEL_64_SDK)@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch x86_64@g' libtool;\
	make $(@F)

$(ARM_64_DIR)/$(ONIG_TARGET): $(ARM_64_DIR)
	cd $(@D);\
	./autogen.sh;\
	CC="$(ARM_64_CC)" ./configure $(ARM_64_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -g -O2@CFLAGS = -g -O2 -isysroot $(ARM_64_SDK)@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch arm64@g' libtool;\
	make $(@F)

$(INTEL_64_DIR):
	unzip $(ONIGURUMA_VERSION).zip
	mv $(ONIGURUMA_VERSION) $@

$(ARM_64_DIR):
	unzip $(ONIGURUMA_VERSION).zip
	mv $(ONIGURUMA_VERSION) $@

$(UNIVERSAL_DIR):
	mkdir $@

exportloc:
	echo Nothing to do

clean:
	rm -rf $(INTEL_64_DIR)
	rm -rf $(ARM_64_DIR)
	rm -rf $(UNIVERSAL_DIR)
