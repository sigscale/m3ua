## Makefile.am
##
## Process this file with automake to produce Makefile.in

modhtml = m3ua.html m3ua_app.html \
		m3ua_sup.html \
		m3ua_sap_sup.html \
		m3ua_sap_server.html \
		m3ua_endpoint_sup_sup.html \
		m3ua_endpoint_sup.html \
		m3ua_endpoint_server.html \
		m3ua_sgp_sup.html \
		m3ua_sgp_fsm.html \
		m3ua_asp_sup.html \
		m3ua_asp_fsm.html \
		m3ua_lm_server.html \
		m3ua_codec.html

doc_DATA = overview.edoc $(modhtml) \
		modules-frame.html overview-summary.html \
		index.html stylesheet.css sigscale-logo.png

overview.edoc: overview.edoc-in
	sed -e 's!%VERSION%!$(VERSION)!' \
			-e 's!%DESCRIPTION%!$(PACKAGE)!' < $< > $@

%.html:$(top_srcdir)/src/%.erl   overview.edoc $(top_srcdir)/doc/supervision.edoc
	$(ERL) -noshell -run edoc_run application \
			"'$(PACKAGE_NAME)'" "'$(top_builddir)'" \
			'[{sort_functions,false},{private,true},{todo,true},{source_path,["$(top_srcdir)/src"]},{subpackages,false},{def,{docsrc,"$(top_srcdir)/doc/{@?}"}}]'
	for i in `ls *.html`; do \
			sed -e 's!erlang logo!sigscale logo!' \
					-e 's!href=\"http://www.erlang.org/\"!href=\"http://www.sigscale.org/\"!' \
					-e 's!erlang.png!sigscale-logo.png!' $$i > $$i.tmp; \
			mv $$i.tmp $$i; \
	done
	-cp -n $(top_srcdir)/doc/sigscale-logo.png .
	-cp -n $(top_srcdir)/doc/supervision.png .
	-cp -n $(top_srcdir)/doc/messaging-client.png .

CLEANFILES = overview.edoc edoc-info index.html \
		modules-frame.html overview-summary.html packages-frame.html \
		stylesheet.css erlang.png $(modhtml)

