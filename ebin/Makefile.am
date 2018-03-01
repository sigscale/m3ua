## Makefile.am
##
## Process this file with automake to produce Makefile.in

appdir = $(beamdir)
app_DATA = m3ua.app
EXTRA_DIST = m3ua.app

beam_DATA = m3ua.beam m3ua_app.beam \
		m3ua_sup.beam \
		m3ua_sap_sup.beam \
		m3ua_sap_server.beam \
		m3ua_endpoint_sup_sup.beam \
		m3ua_endpoint_sup.beam \
		m3ua_endpoint_server.beam \
		m3ua_sgp_sup.beam \
		m3ua_sgp_fsm.beam \
		m3ua_asp_sup.beam \
		m3ua_asp_fsm.beam \
		m3ua_lm_server.beam \
		m3ua_codec.beam \
		m3ua_callback.beam

%.beam:$(top_srcdir)/src/%.erl
	$(ERLC) $(ERLCFLAGS) -I $(top_srcdir)/include $<

%.app:   %.app-in
	sed -e 's/%APP_NAME%/$(PACKAGE_NAME)/' \
			-e 's/%APP_VERSION%/$(PACKAGE_VERSION)/' < $< > $@

CLEANFILES = $(beam_DATA) $(app_DATA)

