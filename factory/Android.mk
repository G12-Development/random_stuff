#
# Copyright (C) 2021 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FACTORY_PATH := device/askey/g12a-common/factory

PRODUCT_UPGRADE_OUT := $(PRODUCT_OUT)/upgrade
PACKAGE_CONFIG_FILE := $(PRODUCT_UPGRADE_OUT)/image.cfg
AML_IMAGE_TOOL := $(HOST_OUT_EXECUTABLES)/aml_image_packer$(HOST_EXECUTABLE_SUFFIX)
IMGPACK := $(HOST_OUT_EXECUTABLES)/res_packer$(HOST_EXECUTABLE_SUFFIX)


INSTALLED_AML_LOGO := $(PRODUCT_OUT)/logo.img
INSTALLED_AML_UPGRADE_PACKAGE_TARGET := $(PRODUCT_OUT)/aml_upgrade_package.img

define aml-symlink-file
	$(hide) ln -f $(1) $(PRODUCT_UPGRADE_OUT)/$(strip $(if $(2), $(2), $(notdir $(1))))
endef

define aml-logo-img
	@echo "generate $(INSTALLED_AML_LOGO)"
	$(hide) mkdir -p $(PRODUCT_UPGRADE_OUT)/logo
	$(foreach bmpf, $(filter %.bmp, $(wildcard $(TARGET_LOGO_FILES)/*)), \
		if [ -n "$(shell find $(bmpf) -type f -size +256k)" ]; then \
			echo "logo pic $(bmpf) >256k gziped"; \
			$(MINIGZIP) -c $(bmpf) > $(PRODUCT_UPGRADE_OUT)/logo/$(notdir $(bmpf)); \
		else \
			$(ACP) $(bmpf) $(PRODUCT_UPGRADE_OUT)/logo; \
		fi;)
	$(hide) $(IMGPACK) -r $(PRODUCT_UPGRADE_OUT)/logo $(INSTALLED_AML_LOGO)
	$(hide) rm -rf $(PRODUCT_UPGRADE_OUT)/logo
endef

$(INSTALLED_AML_UPGRADE_PACKAGE_TARGET) : $(INTERNAL_OTA_PACKAGE_TARGET) | $(ACP)
	$(hide) mkdir -p $(PRODUCT_UPGRADE_OUT)
ifeq ("$(wildcard $(FACTORY_PATH)/u-boot.bin)","")
	$(error "no u-boot.bin found in $(FACTORY_PATH)")
else
	$(hide) $(call aml-symlink-file, $(FACTORY_PATH)/u-boot.bin)
endif
ifeq ($(TARGET_LOGO_FILES),)
	$(error "please set TARGET_LOGO_FILES")
else
	$(hide) $(call aml-logo-img)
	$(hide) $(call aml-symlink-file, $(PRODUCT_OUT)/logo.img)
endif
	$(hide) $(call aml-symlink-file, $(FACTORY_PATH)/aml_sdc_burn.ini)
	$(hide) $(call aml-symlink-file, $(FACTORY_PATH)/image.cfg)
	$(hide) $(call aml-symlink-file, $(FACTORY_PATH)/platform.conf)
	$(hide) $(call aml-symlink-file, $(PRODUCT_OUT)/boot.img)
	$(hide) $(call aml-symlink-file, $(PRODUCT_OUT)/recovery.img)
	$(hide) $(call aml-symlink-file, $(INSTALLED_2NDBOOTLOADER_TARGET), dtb.img)
	$(hide) $(call aml-symlink-file, $(PRODUCT_OUT)/dtbo.img)
	$(hide) $(call aml-symlink-file, $(PRODUCT_OUT)/super.img)
	$(hide) $(AML_IMAGE_TOOL) -r $(PACKAGE_CONFIG_FILE) $(PRODUCT_UPGRADE_OUT)/ $@
	$(hide) rm -rf $(PRODUCT_UPGRADE_OUT)
	@echo " $@ created"

.PHONY: aml_upgrade
aml_upgrade: $(INSTALLED_AML_UPGRADE_PACKAGE_TARGET)
