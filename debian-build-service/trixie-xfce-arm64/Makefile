#!/bin/bash

# (C) 2025 OpenSEA <OpenSEA@allwinnertech.com>
# Calls all necessary live-build programs in the correct order to complete
# the bootstrap, chroot, installer, binary, and source stage.
# You need live-build qemu-aarch64-static package installed and superuser privileges.
# if creat failed, maybe you can upgrade: live-build,qemu-aarch64-static,debootstrap

BUILD_NUMBER?=1
OUTPUT?=out
BASEIMG=linaro-trixie
IMAGEPREFIX=$(BASEIMG)-`date +%Y%m%d`-$(BUILD_NUMBER)
LOGFILE=$(OUTPUT)/$(IMAGEPREFIX).build-log.txt
CONFIGFILE=$(OUTPUT)/$(IMAGEPREFIX).config.tar.bz2
LISTFILE=$(OUTPUT)/$(IMAGEPREFIX).contents
PKGSFILE=$(OUTPUT)/$(IMAGEPREFIX).packages
TARGZFILE=$(OUTPUT)/$(IMAGEPREFIX).tar.gz
MD5SUMSFILE=$(OUTPUT)/$(IMAGEPREFIX).md5sums.txt

all:
	mkdir -p $(OUTPUT)
	set -e; sudo lb build --debug 2>&1 | tee $(LOGFILE)

	tar -jcf $(CONFIGFILE) auto/ config/ configure;
	sudo mv chroot.files $(LISTFILE);
	sudo mv chroot.packages.live $(PKGSFILE);
	sudo mv live-image-arm64.tar.tar.gz $(TARGZFILE);
	md5sum $(LOGFILE) $(CONFIGFILE) $(LISTFILE) $(PKGSFILE) $(TARGZFILE) > $(MD5SUMSFILE);

clean:
	sudo lb clean --purge
	rm -f $(BASEIMG)-*
	rm -rf config
	rm -rf ${OUTPUT}
