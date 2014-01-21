##
#
# Compiz plugin Makefile
#
# Copyright : (C) 2007 by Dennis Kasprzyk
# E-mail    : onestone@deltatauchi.de
#
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
##

# plugin.info file contents
# 
# PLUGIN = foo
# PKG_DEP = pango
# LDFLAGS_ADD = -lGLU
# CFLAGS_ADD = -I/usr/include/foo
# CHK_HEADERS = compiz-cube.h
#

#load config file

ECHO	  = `which echo`

# default color settings
color := $(shell if [ $$TERM = "dumb" ]; then $(ECHO) "no"; else $(ECHO) "yes"; fi)

ifeq ($(shell if [ -f plugin.info ]; then $(ECHO) -n "found"; fi ),found)
include plugin.info
else
$(error $(shell if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\033[1;31m[ERROR]\033[0m \"plugin.info\" file not found"; \
	else \
		$(ECHO) "[ERROR] \"plugin.info\" file not found"; \
	fi;))
endif

ifneq ($(shell if pkg-config --exists compiz; then $(ECHO) -n "found"; fi ),found)
$(error $(shell if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[1;31m[ERROR]\033[0m Compiz not installed"; \
	else \
		$(ECHO) -n "[ERROR] Compiz not installed"; \
	fi))
endif


ifneq ($(shell if [ -n "$(PKG_DEP)" ]; then if pkg-config --exists $(PKG_DEP); then $(ECHO) -n "found"; fi; \
       else $(ECHO) -n "found"; fi ),found)
$(error $(shell if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[1;31m[ERROR]\033[0m "; \
	else \
		$(ECHO) -n "[ERROR] "; \
	fi; \
	pkg-config --print-errors --short-errors --errors-to-stdout $(PKG_DEP); ))
endif


ifeq ($(BUILD_GLOBAL),true)
	PREFIX = $(shell pkg-config --variable=prefix compiz)
	CLIBDIR = $(shell pkg-config --variable=libdir compiz)
	CINCDIR = $(shell pkg-config --variable=includedir compiz)
	PKGDIR = $(CLIBDIR)/pkgconfig
	DESTDIR = $(shell pkg-config --variable=libdir compiz)/compiz
	XMLDIR = $(shell pkg-config --variable=prefix compiz)/share/compiz
	IMAGEDIR = $(shell pkg-config --variable=prefix compiz)/share/compiz
	DATADIR = $(shell pkg-config --variable=prefix compiz)/share/compiz
else
	DESTDIR = $(HOME)/.compiz/plugins
	XMLDIR = $(HOME)/.compiz/metadata
	IMAGEDIR = $(HOME)/.compiz/images
	DATADIR = $(HOME)/.compiz/data
endif

BUILDDIR = build

CC        = gcc
CPP       = g++
LIBTOOL   = libtool
INSTALL   = install

BCOP      = `pkg-config --variable=bin bcop`

CFLAGS    = -g -Wall -Wpointer-arith -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations -Wnested-externs -fno-strict-aliasing -std=c99 `pkg-config --cflags $(PKG_DEP) compiz ` $(CFLAGS_ADD)
LDFLAGS   = `pkg-config --libs $(PKG_DEP) compiz ` $(LDFLAGS_ADD)

DEFINES   = -DIMAGEDIR=\"$(IMAGEDIR)\" -DDATADIR=\"$(DATADIR)\"

POFILEDIR = $(shell if [ -n "$(PODIR)" ]; then $(ECHO) $(PODIR); else $(ECHO) ./po;fi )

COMPIZ_HEADERS = compiz.h compiz-core.h
COMPIZ_INC = $(shell pkg-config --variable=includedir compiz)/compiz/

is-bcop-target  := $(shell if [ -e $(PLUGIN).xml.in ]; then cat $(PLUGIN).xml.in | grep "useBcop=\"true\""; \
		     else if [ -e $(PLUGIN).xml ]; then cat $(PLUGIN).xml | grep "useBcop=\"true\""; fi; fi)

trans-target    := $(shell if [ -e $(PLUGIN).xml.in -o -e $(PLUGIN).xml ]; then $(ECHO) $(BUILDDIR)/$(PLUGIN).xml;fi )

bcop-target     := $(shell if [ -n "$(is-bcop-target)" ]; then $(ECHO) $(BUILDDIR)/$(PLUGIN).xml; fi )
bcop-target-src := $(shell if [ -n "$(is-bcop-target)" ]; then $(ECHO) $(BUILDDIR)/$(PLUGIN)_options.c; fi )
bcop-target-hdr := $(shell if [ -n "$(is-bcop-target)" ]; then $(ECHO) $(BUILDDIR)/$(PLUGIN)_options.h; fi )

gen-schemas     := $(shell if [ \( -e $(PLUGIN).xml.in -o -e $(PLUGIN).xml \) -a -n "`pkg-config --variable=xsltdir compiz-gconf`" ]; then $(ECHO) true; fi )
schema-target   := $(shell if [ -n "$(gen-schemas)" ]; then $(ECHO) $(BUILDDIR)/$(PLUGIN).xml; fi )
schema-output   := $(shell if [ -n "$(gen-schemas)" ]; then $(ECHO) $(BUILDDIR)/compiz-$(PLUGIN).schema; fi )

ifeq ($(BUILD_GLOBAL),true)
    pkg-target         := $(shell if [ -e compiz-$(PLUGIN).pc.in -a -n "$(PREFIX)" -a -d "$(PREFIX)" ]; then $(ECHO) "$(BUILDDIR)/compiz-$(PLUGIN).pc"; fi )
    hdr-install-target := $(shell if [ -e compiz-$(PLUGIN).pc.in -a -n "$(PREFIX)" -a -d "$(PREFIX)" -a -e compiz-$(PLUGIN).h ]; then $(ECHO) "compiz-$(PLUGIN).h"; fi )
endif

# find all the object files

c-objs     := $(patsubst %.c,%.lo,$(shell find -name '*.c' 2> /dev/null | grep -v "$(BUILDDIR)/" | sed -e 's/^.\///'))
c-objs     += $(patsubst %.cpp,%.lo,$(shell find -name '*.cpp' 2> /dev/null | grep -v "$(BUILDDIR)/" | sed -e 's/^.\///'))
c-objs     += $(patsubst %.cxx,%.lo,$(shell find -name '*.cxx' 2> /dev/null | grep -v "$(BUILDDIR)/" | sed -e 's/^.\///'))
c-objs     := $(filter-out $(bcop-target-src:.c=.lo),$(c-objs))

h-files    := $(shell find -name '*.h' 2> /dev/null | grep -v "$(BUILDDIR)/" | sed -e 's/^.\///')
h-files    += $(bcop-target-hdr)
h-files    += $(foreach file,$(COMPIZ_HEADERS) $(CHK_HEADERS),$(shell $(ECHO) -n "$(COMPIZ_INC)$(file)"))

all-c-objs := $(addprefix $(BUILDDIR)/,$(c-objs)) 
all-c-objs += $(bcop-target-src:.c=.lo)

# additional files

data-files  := $(shell find data/  -name '*' -type f 2> /dev/null | sed -e 's/data\///')
image-files := $(shell find images/ -name '*' -type f 2> /dev/null | sed -e 's/images\///')

# system include path parameter, -isystem doesn't work on old gcc's
inc-path-param = $(shell if [ -z "`gcc --version | head -n 1 | grep ' 3'`" ]; then $(ECHO) "-isystem"; else $(ECHO) "-I"; fi)

# Tests
ifeq ($(shell if [ -n "$(is-bcop-target)" -a -z "$(BCOP)" ]; then $(ECHO) -n "error"; fi ),error)
$(error $(shell if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[1;31m[ERROR]\033[0m BCOP not installed but is needed to build plugin"; \
	else \
		$(ECHO) -n "[ERROR] BCOP not installed but is needed to build plugin"; \
	fi))
endif

ifeq ($(shell if [ "x$(BUILD_GLOBAL)" != "xtrue" -a -e compiz-$(PLUGIN).pc.in ]; then $(ECHO) -n "warn"; fi ),warn)
$(warning $(shell if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[1;31m[WARNING]\033[0m This plugin might be needed by other plugins. Install it with \"BUILD_GLOBAL=true sudo make install\" "; \
	else \
		$(ECHO) -n "[WARNING]  This plugin might be needed by other plugins. Install it with \"BUILD_GLOBAL=true sudo make install\""; \
	fi))
endif

#
# Do it.
#

.PHONY: $(BUILDDIR) build-dir trans-target bcop-build pkg-creation schema-creation c-build-objs c-link-plugin

all: $(BUILDDIR) build-dir trans-target bcop-build pkg-creation schema-creation c-build-objs c-link-plugin

trans-build: $(trans-target)

bcop-build:   $(bcop-target-hdr) $(bcop-target-src)

schema-creation: $(schema-output)

c-build-objs: $(all-c-objs)

c-link-plugin: $(BUILDDIR)/lib$(PLUGIN).la

pkg-creation: $(pkg-target)

#
# Create build directory
#

$(BUILDDIR) :
	@mkdir -p $(BUILDDIR)

$(DESTDIR) :
	@mkdir -p $(DESTDIR)

#
# fallback if xml.in doesn't exists
#
$(BUILDDIR)/%.xml: %.xml
	@cp $< $@

#
# Translating
#
$(BUILDDIR)/%.xml: %.xml.in
	@if [ -d $(POFILEDIR) ]; then \
		if [ '$(color)' != 'no' ]; then \
			$(ECHO) -e -n "\033[0;1;5mtranslate \033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
		else \
			$(ECHO) "translate $<  ->  $@"; \
		fi; \
		intltool-merge -x -u $(POFILEDIR) $< $@ > /dev/null; \
		if [ '$(color)' != 'no' ]; then \
			$(ECHO) -e "\r\033[0mtranslate : \033[34m$< -> $@\033[0m"; \
		fi; \
	else \
		if [ '$(color)' != 'no' ]; then \
			$(ECHO) -e -n "\033[0;1;5mconvert   \033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
		else \
			$(ECHO) "convert   $<  ->  $@"; \
		fi; \
		cat $< | sed -e 's;<_;<;g' -e 's;</_;</;g' > $@; \
		if [ '$(color)' != 'no' ]; then \
			$(ECHO) -e "\r\033[0mconvert   : \033[34m$< -> $@\033[0m"; \
		fi; \
	fi

#
# BCOP'ing

$(BUILDDIR)/%_options.h: $(BUILDDIR)/%.xml
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[0;1;5mbcop'ing  \033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
	else \
		$(ECHO) "bcop'ing  $<  ->  $@"; \
	fi
	@$(BCOP) --header=$@ $<
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mbcop'ing  : \033[34m$< -> $@\033[0m"; \
	fi

$(BUILDDIR)/%_options.c: $(BUILDDIR)/%.xml
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[0;1;5mbcop'ing  \033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
	else \
		$(ECHO) "bcop'ing  $<  ->  $@"; \
	fi
	@$(BCOP) --source=$@ $< 
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mbcop'ing  : \033[34m$< -> $@\033[0m"; \
	fi

#
# Schema generation

$(BUILDDIR)/compiz-%.schema: $(BUILDDIR)/%.xml
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[0;1;5mschema'ing\033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
	else \
		$(ECHO) "schema'ing  $<  ->  $@"; \
	fi
	@xsltproc `pkg-config --variable=xsltdir compiz-gconf`/schemas.xslt $< > $@
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mschema    : \033[34m$< -> $@\033[0m"; \
	fi

#
# pkg config file generation

$(BUILDDIR)/compiz-%.pc: compiz-%.pc.in
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[0;1;5mpkgconfig \033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
	else \
		$(ECHO) "pkgconfig   $<  ->  $@"; \
	fi
	@COMPIZREQUIRES=`cat $(PKGDIR)/compiz.pc | grep Requires | sed -e 's;Requires: ;;g'`; \
    COMPIZCFLAGS=`cat $(PKGDIR)/compiz.pc | grep Cflags | sed -e 's;Cflags: ;;g'`; \
    sed -e 's;@prefix@;$(PREFIX);g' -e 's;\@libdir@;$(CLIBDIR);g' \
        -e 's;@includedir@;$(CINCDIR);g' -e 's;\@VERSION@;0.0.1;g' \
        -e "s;@COMPIZ_REQUIRES@;$$COMPIZREQUIRES;g" \
        -e "s;@COMPIZ_CFLAGS@;$$COMPIZCFLAGS;g" $< > $@;
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mpkgconfig : \033[34m$< -> $@\033[0m"; \
	fi

#
# Compiling
#

$(BUILDDIR)/%.lo: %.c $(h-files)
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5mcompiling \033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
	else \
		$(ECHO) "compiling $< -> $@"; \
	fi
	@$(LIBTOOL) --quiet --mode=compile $(CC) $(CFLAGS) $(DEFINES) -I$(BUILDDIR) -c -o $@ $<
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mcompiling : \033[34m$< -> $@\033[0m"; \
	fi

$(BUILDDIR)/%.lo: $(BUILDDIR)/%.c $(h-files)
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5mcompiling \033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
	else \
		$(ECHO) "compiling $< -> $@"; \
	fi
	@$(LIBTOOL) --quiet --mode=compile $(CC) $(CFLAGS) $(DEFINES) -I$(BUILDDIR) -c -o $@ $<
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mcompiling : \033[34m$< -> $@\033[0m"; \
	fi

$(BUILDDIR)/%.lo: %.cpp $(h-files)
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5mcompiling \033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
	else \
		$(ECHO) "compiling $< -> $@"; \
	fi
	@$(LIBTOOL) --quiet --mode=compile $(CPP) $(CFLAGS) $(DEFINES) -I$(BUILDDIR) -c -o $@ $<
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mcompiling : \033[34m$< -> $@\033[0m"; \
	fi

$(BUILDDIR)/%.lo: %.cxx $(h-files)
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5mcompiling \033[0m: \033[0;32m$< \033[0m-> \033[0;31m$@\033[0m"; \
	else \
		$(ECHO) "compiling $< -> $@"; \
	fi
	@$(LIBTOOL) --quiet --mode=compile $(CPP) $(CFLAGS) $(DEFINES) -I$(BUILDDIR) -c -o $@ $<
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mcompiling : \033[34m$< -> $@\033[0m"; \
	fi

#
# Linking
#

cxx-rpath-prefix := -Wl,-rpath,

$(BUILDDIR)/lib$(PLUGIN).la: $(all-c-objs)
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[0;1;5mlinking   \033[0m: \033[0;31m$@\033[0m"; \
	else \
		$(ECHO) "linking   : $@"; \
	fi
	@$(LIBTOOL) --quiet --mode=link $(CC) $(LDFLAGS) -rpath $(DESTDIR) -o $@ $(all-c-objs)
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mlinking   : \033[34m$@\033[0m"; \
	fi


clean:
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e -n "\033[0;1;5mremoving  \033[0m: \033[0;31m./$(BUILDDIR)\033[0m"; \
	else \
		$(ECHO) "removing  : ./$(BUILDDIR)"; \
	fi
	@rm -rf $(BUILDDIR)
	@if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0mremoving  : \033[34m./$(BUILDDIR)\033[0m"; \
	fi
	

install: $(DESTDIR) all
	@if [ '$(color)' != 'no' ]; then \
	    $(ECHO) -n -e "\033[0;1;5minstall   \033[0m: \033[0;31m$(DESTDIR)/lib$(PLUGIN).so\033[0m"; \
	else \
	    $(ECHO) "install   : $(DESTDIR)/lib$(PLUGIN).so"; \
	fi
	@mkdir -p $(DESTDIR)
	@$(INSTALL) $(BUILDDIR)/.libs/lib$(PLUGIN).so $(DESTDIR)/lib$(PLUGIN).so
	@if [ '$(color)' != 'no' ]; then \
	    $(ECHO) -e "\r\033[0minstall   : \033[34m$(DESTDIR)/lib$(PLUGIN).so\033[0m"; \
	fi
	@if [ -e $(BUILDDIR)/$(PLUGIN).xml ]; then \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5minstall   \033[0m: \033[0;31m$(XMLDIR)/$(PLUGIN).xml\033[0m"; \
	    else \
		$(ECHO) "install   : $(XMLDIR)/$(PLUGIN).xml"; \
	    fi; \
	    mkdir -p $(XMLDIR); \
	    $(INSTALL)  $(BUILDDIR)/$(PLUGIN).xml $(XMLDIR)/$(PLUGIN).xml; \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0minstall   : \033[34m$(XMLDIR)/$(PLUGIN).xml\033[0m"; \
	    fi; \
	fi
	@if [ -n "$(hdr-install-target)" ]; then \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5minstall   \033[0m: \033[0;31m$(CINCDIR)/compiz/$(hdr-install-target)\033[0m"; \
	    else \
		$(ECHO) "install   : $(CINCDIR)/compiz/$(hdr-install-target)"; \
	    fi; \
	    $(INSTALL) --mode=u=rw,go=r,a-s $(hdr-install-target) $(CINCDIR)/compiz/$(hdr-install-target); \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0minstall   : \033[34m$(CINCDIR)/compiz/$(hdr-install-target)\033[0m"; \
	    fi; \
	fi
	@if [ -n "$(pkg-target)" ]; then \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5minstall   \033[0m: \033[0;31m$(PKGDIR)/compiz-$(PLUGIN).pc\033[0m"; \
	    else \
		$(ECHO) "install   : $(PKGDIR)/compiz-$(PLUGIN).pc"; \
	    fi; \
	    $(INSTALL) --mode=u=rw,go=r,a-s $(pkg-target) $(PKGDIR)/compiz-$(PLUGIN).pc; \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0minstall   : \033[34m$(PKGDIR)/compiz-$(PLUGIN).pc\033[0m"; \
	    fi; \
	fi
	@if [ -n "$(schema-output)" -a -e "$(schema-output)" ]; then \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5minstall   \033[0m: \033[0;31m$(schema-output)\033[0m"; \
	    else \
		$(ECHO) "install   : $(schema-output)"; \
	    fi; \
	    if [ "x$(USER)" = "xroot" ]; then \
		GCONF_CONFIG_SOURCE=`gconftool-2 --get-default-source` \
		gconftool-2 --makefile-install-rule $(schema-output) > /dev/null; \
	    else \
		gconftool-2 --install-schema-file=$(schema-output) > /dev/null; \
	    fi; \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0minstall   : \033[34m$(schema-output)\033[0m"; \
	    fi; \
	fi
	@if [ -n "$(data-files)" ]; then \
	    mkdir -p $(DATADIR); \
	    for FILE in $(data-files); do \
		if [ '$(color)' != 'no' ]; then \
		    $(ECHO) -n -e "\033[0;1;5minstall   \033[0m: \033[0;31m$(DATADIR)/$$FILE\033[0m"; \
		else \
		    $(ECHO) "install   : $(DATADIR)/$$FILE"; \
		fi; \
	    	FILEDIR="$(DATADIR)/`dirname "$$FILE"`"; \
		mkdir -p "$$FILEDIR"; \
		$(INSTALL) --mode=u=rw,go=r,a-s data/$$FILE $(DATADIR)/$$FILE; \
		if [ '$(color)' != 'no' ]; then \
		    $(ECHO) -e "\r\033[0minstall   : \033[34m$(DATADIR)/$$FILE\033[0m"; \
		fi; \
	    done \
	fi
	@if [ -n "$(image-files)" ]; then \
	    mkdir -p $(IMAGEDIR); \
	    for FILE in $(image-files); do \
		if [ '$(color)' != 'no' ]; then \
		    $(ECHO) -n -e "\033[0;1;5minstall   \033[0m: \033[0;31m$(IMAGEDIR)/$$FILE\033[0m"; \
		else \
		    $(ECHO) "install   : $(IMAGEDIR)/$$FILE"; \
		fi; \
	    	FILEDIR="$(IMAGEDIR)/`dirname "$$FILE"`"; \
		mkdir -p "$$FILEDIR"; \
		$(INSTALL) --mode=u=rw,go=r,a-s images/$$FILE $(IMAGEDIR)/$$FILE; \
		if [ '$(color)' != 'no' ]; then \
		    $(ECHO) -e "\r\033[0minstall   : \033[34m$(IMAGEDIR)/$$FILE\033[0m"; \
		fi; \
	    done \
	fi

uninstall:	
	@if [ -e $(DESTDIR)/lib$(PLUGIN).so ]; then \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5muninstall \033[0m: \033[0;31m$(DESTDIR)/lib$(PLUGIN).so\033[0m"; \
	    else \
		$(ECHO) "uninstall : $(DESTDIR)/lib$(PLUGIN).so"; \
	    fi; \
	    rm -f $(DESTDIR)/lib$(PLUGIN).so; \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0muninstall : \033[34m$(DESTDIR)/lib$(PLUGIN).so\033[0m"; \
	    fi; \
	fi
	@if [ -e $(XMLDIR)/$(PLUGIN).xml ]; then \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5muninstall \033[0m: \033[0;31m$(XMLDIR)/$(PLUGIN).xml\033[0m"; \
	    else \
		$(ECHO) "uninstall : $(XMLDIR)/$(PLUGIN).xml"; \
	    fi; \
	    rm -f $(XMLDIR)/$(PLUGIN).xml; \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0muninstall : \033[34m$(XMLDIR)/$(PLUGIN).xml\033[0m"; \
	    fi; \
	fi
	@if [ -n "$(hdr-install-target)" -a -e $(CINCDIR)/compiz/$(hdr-install-target) ]; then \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5muninstall \033[0m: \033[0;31m$(CINCDIR)/compiz/$(hdr-install-target)\033[0m"; \
	    else \
		$(ECHO) "uninstall : $(CINCDIR)/compiz/$(hdr-install-target)"; \
	    fi; \
	    rm -f $(CINCDIR)/compiz/$(hdr-install-target); \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0muninstall : \033[34m$(CINCDIR)/compiz/$(hdr-install-target)\033[0m"; \
	    fi; \
	fi
	@if [ -n "$(pkg-target)" -a -e $(PKGDIR)/compiz-$(PLUGIN).pc ]; then \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5muninstall \033[0m: \033[0;31m$(PKGDIR)/compiz-$(PLUGIN).pc\033[0m"; \
	    else \
		$(ECHO) "uninstall : $(PKGDIR)/compiz-$(PLUGIN).pc"; \
	    fi; \
	    rm -f $(PKGDIR)/compiz-$(PLUGIN).pc; \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0muninstall : \033[34m$(PKGDIR)/compiz-$(PLUGIN).pc\033[0m"; \
	    fi; \
	fi
	@if [ -n "$(schema-output)" -a -e "$(schema-output)" -a 'x$(USER)' = 'xroot' ]; then \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -n -e "\033[0;1;5muninstall \033[0m: \033[0;31m$(schema-output)\033[0m"; \
	    else \
		$(ECHO) "uninstall : $(schema-output)"; \
	    fi; \
	    GCONF_CONFIG_SOURCE=`gconftool-2 --get-default-source` \
	    gconftool-2 --makefile-uninstall-rule $(schema-output) > /dev/null; \
	    if [ '$(color)' != 'no' ]; then \
		$(ECHO) -e "\r\033[0muninstall : \033[34m$(schema-output)\033[0m"; \
	    fi; \
	fi
	@if [ -n "$(data-files)" ]; then \
	    for FILE in $(data-files); do \
		if [ '$(color)' != 'no' ]; then \
		    $(ECHO) -n -e "\033[0;1;5muninstall \033[0m: \033[0;31m$(DATADIR)/$$FILE\033[0m"; \
		else \
		    $(ECHO) "uninstall : $(DATADIR)/$$FILE"; \
		fi; \
		rm -f $(DATADIR)/$$FILE; \
		if [ '$(color)' != 'no' ]; then \
		    $(ECHO) -e "\r\033[0muninstall : \033[34m$(DATADIR)/$$FILE\033[0m"; \
		fi; \
	    done \
	fi
	@if [ -n "$(image-files)" ]; then \
	    for FILE in $(image-files); do \
		if [ '$(color)' != 'no' ]; then \
		    $(ECHO) -n -e "\033[0;1;5muninstall \033[0m: \033[0;31m$(IMAGEDIR)/$$FILE\033[0m"; \
		else \
		    $(ECHO) "uninstall : $(IMAGEDIR)/$$FILE"; \
		fi; \
		rm -f $(IMAGEDIR)/$$FILE; \
		if [ '$(color)' != 'no' ]; then \
		    $(ECHO) -e "\r\033[0muninstall : \033[34m$(IMAGEDIR)/$$FILE\033[0m"; \
		fi; \
	    done \
	fi
