# Dependencies for LuaSrcDiet
PKG_BUILD_DEPENDS += luci-base/host lua/host

include $(INCLUDE_DIR)/package.mk

# Annoyingly, make's shell function replaces all newlines with spaces, so we have to do some escaping work. Yuck.
define GluonCheckSite
[ -z "$$IPKG_INSTROOT" ] || sed -e 's/-@/\n/g' -e 's/+@/@/g' <<'END__GLUON__CHECK__SITE' | "${TOPDIR}/staging_dir/hostpkg/bin/lua" -e 'dofile()'
local f = assert(io.open(os.getenv('IPKG_INSTROOT') .. '/lib/gluon/site.json'))
local site_json = f:read('*a')
f:close()

site = require('cjson').decode(site_json)
$(shell cat '$(TOPDIR)/../scripts/check_site_lib.lua' '$(1)' | sed -ne '1h; 1!H; $$ {g; s/@/+@/g; s/\n/-@/g; p}')
END__GLUON__CHECK__SITE
endef

# Languages supported by LuCi
GLUON_SUPPORTED_LANGS := ca cs de el en es fr he hu it ja ms no pl pt-br pt ro ru sk sv tr uk vi zh-cn zh-tw

GLUON_I18N_PACKAGES := $(foreach lang,$(GLUON_SUPPORTED_LANGS),+LUCI_LANG_$(lang):luci-i18n-base-$(lang))
GLUON_I18N_CONFIG := $(foreach lang,$(GLUON_SUPPORTED_LANGS),CONFIG_LUCI_LANG_$(lang))
GLUON_ENABLED_LANGS := $(foreach lang,$(GLUON_SUPPORTED_LANGS),$(if $(CONFIG_LUCI_LANG_$(lang)),$(lang)))


define GluonBuildI18N
	mkdir -p $$(PKG_BUILD_DIR)/i18n
	for lang in $$(GLUON_ENABLED_LANGS); do \
		if [ -e $(2)/$$$$lang.po ]; then \
			rm -f $$(PKG_BUILD_DIR)/i18n/$(1).$$$$lang.lmo; \
			po2lmo $(2)/$$$$lang.po $$(PKG_BUILD_DIR)/i18n/$(1).$$$$lang.lmo; \
		fi; \
	done
endef

define GluonInstallI18N
	$$(INSTALL_DIR) $(2)/usr/lib/lua/luci/i18n
	for lang in $$(GLUON_ENABLED_LANGS); do \
		if [ -e $$(PKG_BUILD_DIR)/i18n/$(1).$$$$lang.lmo ]; then \
			$$(INSTALL_DATA) $$(PKG_BUILD_DIR)/i18n/$(1).$$$$lang.lmo $(2)/usr/lib/lua/luci/i18n/$(1).$$$$lang.lmo; \
		fi; \
	done
endef

define GluonSrcDiet
	rm -rf $(2)
	$(CP) $(1) $(2)
	$(FIND) $(2) -type f | while read src; do \
		if LuaSrcDiet --noopt-binequiv -o "$$$$src.o" "$$$$src"; then \
			chmod $$$$(stat -c%a "$$$$src") "$$$$src.o"; \
			mv "$$$$src.o" "$$$$src"; \
		fi; \
	done
endef
