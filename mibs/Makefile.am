## Makefile.am
## vim: ts=3
##
## Process this file with automake to produce Makefile.in

mibs_DATA = SIGSCALE-M3UA-MIB.mib

check_DATA = .tree_ok

.tree_ok:
	@if snmptranslate -V > /dev/null 2>&1; then \
		snmptranslate -M +$(ERLANG_LIB_DIR_sigscale_mibs)/mibs:$(top_srcdir)/mibs \
			-m +SIGSCALE-M3UA-MIB -Lo -Tp -IR m3uaMIB; \
	fi

