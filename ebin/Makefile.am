## Makefile.am
##
## Process this file with automake to produce Makefile.in

appdir = $(beamdir)
app_DATA = m3ua.app
EXTRA_DIST = m3ua.app

beam_DATA = m3ua.beam m3ua_app.beam \
		m3ua_sup.beam \
		m3ua_server_sup.beam \
		m3ua_server_endpoint_sup.beam \
		m3ua_server_assoc_sup.beam \
		m3ua_server_endpoint_server.beam \
		m3ua_server_assoc_fsm.beam \
		m3ua_client_assoc_sup.beam \
		m3ua_client_assoc_fsm.beam \
		m3ua_lm_server.beam \
		m3ua_codec.beam

%.beam:$(top_srcdir)/src/%.erl
	$(ERLC) $(ERLCFLAGS) -I $(top_srcdir)/include $<

%.app:   %.app-in
	sed -e 's/%APP_NAME%/$(PACKAGE_NAME)/' \
			-e 's/%APP_VERSION%/$(PACKAGE_VERSION)/' < $< > $@

CLEANFILES = $(beam_DATA) $(app_DATA)

