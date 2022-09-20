THISDIR := $(shell pwd)

BIN_PREFIX := msd_lite

all: 
	@echo "msd_lite build ok!"

clean:
	@echo "msd_lite clean ok!"

romfs:
	$(ROMFSINST) -S -p +x $(THISDIR)/msd_lite /usr/bin/msd_lite
	$(ROMFSINST) $(THISDIR)/msd_lite.conf /etc_ro/msd_lite.conf
