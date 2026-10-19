null :=
space := $(null) $(null)
WEBOTS_HOME_PATH?=$(subst $(space),\ ,$(strip $(subst \,/,$(WEBOTS_HOME))))
CXX_SOURCES = comparison_smoke_test.cpp
LIBRARIES = -lws2_32
include $(WEBOTS_HOME_PATH)/resources/Makefile.include
