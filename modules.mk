mod_archiveblock.la: mod_archiveblock.slo
	$(SH_LINK) -rpath $(libexecdir) -module -avoid-version  mod_archiveblock.lo
DISTCLEAN_TARGETS = modules.mk
shared =  mod_archiveblock.la
