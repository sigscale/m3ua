## Makefile.am
## vim: ts=3
##
## Process this file with automake to produce Makefile.in

testmods = m3ua_api_SUITE \
			m3ua_codec_SUITE \
			m3ua_snmp_SUITE

check_DATA = .dialyzer_ok .common_test_ok

DIA_ARGS =
CT_ARGS = -spec test.spec

.dialyzer_ok:	$(addsuffix .beam, $(testmods))
	dialyzer ${DIA_ARGS} --src $(top_srcdir)/src

%.beam:$(top_srcdir)/test/%.erl $(top_srcdir)/include/m3ua.hrl
	$(ERLC) -pa $(top_builddir)/ebin $(ERLCFLAGS) -I $(top_srcdir)/include $<

.common_test_ok:	$(addsuffix .beam, $(testmods))
	@if [ ! -d log ]; then mkdir log; fi
	@if [ ! -f ct.cfg ]; then cp $(top_srcdir)/test/ct.cfg .; fi
	@if [ ! -f test.spec ]; then cp $(top_srcdir)/test/test.spec .; fi
	ct_run -no_auto_compile -pa $(top_builddir)/ebin -logdir log -config ct.cfg \
			${CT_ARGS} -dir . -erl_args -noshell -sname $(LOGNAME)-ct

clean-local:
	-rm -r log/*

