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

LOCAL_PATH := $(call my-dir)

PRODUCT_UPGRADE_OUT := $(PRODUCT_OUT)/upgrade
PACKAGE_CONFIG_FILE := $(LOCAL_PATH)/platform.conf
AML_IMAGE_TOOL_PATH := prebuilts/tools/amlogic


define aml-symlink-file
	$(hide) ln -sf $(1) $(PRODUCT_UPGRADE_OUT)/$(if $(2), $(2), $(basename $(1)))
endef

INSTALLED_AML_UPGRADE_PACKAGE_TARGET := $(PRODUCT_OUT)/aml_upgrade_package.img
$(INSTALLED_AML_UPGRADE_PACKAGE_TARGET) : $(INTERNAL_OTA_PACKAGE_TARGET) | $(ACP)
	$(hide) mkdir -p $(PRODUCT_UPGRADE_OUT)
	ifeq ("$(wildcard $(LOCAL_PATH)/u-boot.bin)","")
		$(warning "no u-boot.bin found in $(LOCAL_PATH)")
	else
		$(hide) $(call aml-symlink-file, $(LOCAL_PATH)/u-boot.bin)
	endif
	ifeq ("$(wildcard $(LOCAL_PATH)/logo.img)","")
		$(warning "no logo.img found in $(LOCAL_PATH)")
	else
		$(hide) $(call aml-symlink-file, $(LOCAL_PATH)/logo.img)
	endif
	$(hide) $(call aml-symlink-file, $(LOCAL_PATH)/aml_sdc_burn.ini)
	$(hide) $(call aml-symlink-file, $(LOCAL_PATH)/image.cfg)
	$(hide) $(call aml-symlink-file, $(LOCAL_PATH)/platform.conf)
	$(hide) $(call aml-symlink-file, $(PRODUCT_OUT)/boot.img)
	$(hide) $(call aml-symlink-file, $(PRODUCT_OUT)/recovery.img)
	$(hide) $(call aml-symlink-file, $(INSTALLED_2NDBOOTLOADER_TARGET), dtb.img)
	$(hide) $(call aml-symlink-file, $(PRODUCT_OUT)/dtbo.img)
	$(hide) $(call aml-symlink-file, $(PRODUCT_OUT)/super.img)
	$(hide) $(AML_IMAGE_TOOL_PATH)/aml_image_v2_packer -r $(PACKAGE_CONFIG_FILE) $(PRODUCT_UPGRADE_OUT)/ $@
	@echo " $@ created"

.PHONY: aml_upgrade
aml_upgrade: $(INSTALLED_AML_UPGRADE_PACKAGE_TARGET)
