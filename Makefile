include config.mk

override MAKEFLAGS=-rR

LIBSHARD_DIR := libshard

LIBFFI_VERSION ?= 3.4.5
LIBATOMIC_OPS_VERSION ?= 7.8.0
GCBOEHM_VERSION ?= 8.2.4

LIBFFI_TAR_LINK ?= https://github.com/libffi/libffi/releases/download/v$(LIBFFI_VERSION)/libffi-$(LIBFFI_VERSION).tar.gz
LIBFFI_TAR := $(shell basename $(LIBFFI_TAR_LINK))
LIBFFI_SRC_DIR := $(patsubst %.tar.gz, %, $(LIBFFI_TAR))
LIBFFI_LIB := $(BUILD_PREFIX)/libffi.a

LIBATOMIC_OPS_TAR_LINK ?= https://www.hboehm.info/gc/gc_source/libatomic_ops-$(LIBATOMIC_OPS_VERSION).tar.gz
LIBATOMIC_OPS_TAR := $(shell basename $(LIBATOMIC_OPS_TAR_LINK))
LIBATOMIC_OPS_SRC_DIR := $(patsubst %.tar.gz, %, $(LIBATOMIC_OPS_TAR))

GCBOEHM_TAR_LINK ?= https://www.hboehm.info/gc/gc_source/gc-$(GCBOEHM_VERSION).tar.gz
GCBOEHM_TAR := $(shell basename $(GCBOEHM_TAR_LINK))
GCBOEHM_SRC_DIR := $(patsubst %.tar.gz, %, $(GCBOEHM_TAR))
GCBOEHM_LIB := $(GCBOEHM_SRC_DIR)/.libs/libgc.a

SHARD_BIN := $(BUILD_PREFIX)/shard
LIBSHARD := $(BUILD_PREFIX)/libshard.a
LIBSHARD_OBJ := $(BUILD_PREFIX)/libshard.o

LIBSHARD_H := libshard/include/libshard.h

LIBSHARD_SOURCES := $(shell find $(LIBSHARD_DIR) -name '*.c')
LIBSHARD_OBJECTS := $(patsubst %.c, $(BUILD_PREFIX)/%.o, $(LIBSHARD_SOURCES))

SHARDBIN_SOURCES := $(wildcard *.c)
SHARDBIN_OBJECTS := $(patsubst %.c, $(BUILD_PREFIX)/%.o, $(SHARDBIN_SOURCES))

TEST_RUNNER_SOURCE := tests/runner.c
TEST_RUNNER_BIN := $(BUILD_PREFIX)/tests/runner

DRIVERS_DIR := drivers

LIBC_DRIVER := $(BUILD_PREFIX)/$(DRIVERS_DIR)/shard_libc_driver.o
LIBC_DRIVER_SOURCE := $(DRIVERS_DIR)/shard_libc_driver.c
LIBC_DRIVER_HEADER := $(DRIVERS_DIR)/shard_libc_driver.h

CC ?= cc
LD ?= ld
AR ?= ar
RANLIB ?= ranlib

define unique
	$(strip $(if $1,$(firstword $1) $(call unique,$(filter-out $(firstword $1),$1))))
endef

override LDFLAGS := $(call unique, $(LDFLAGS))

override CFLAGS += -Wall -Wextra -std=c2x -I$(LIBSHARD_DIR)/include
override CFLAGS := $(call unique, $(CFLAGS))

ifneq (,$(findstring SHARD_ENABLE_GCBOEHM, $(CFLAGS)))
	LIBSHARD_OBJECTS += $(GCBOEHM_LIB)
	GCBOEHM_INCLUDE_DIR := $(GCBOEHM_SRC_DIR)
	override CFLAGS += -I$(GCBOEHM_SRC_DIR)/include
endif

ifneq (,$(findstring SHARD_ENABLE_FFI, $(CFLAGS)))
	LIBSHARD_OBJECTS += $(LIBFFI_LIB)
	override CFLAGS += -I$(LIBFFI_SRC_DIR)/x86_64-pc-linux-gnu/include
endif

override BIN_LDFLAGS := 

ifneq (,$(findstring SHARD_ENABLE_LIBEDIT, $(CFLAGS)))
	override BIN_LDFLAGS += -ledit -lm
endif

.PHONY: all
all: $(LIBSHARD) $(SHARD_BIN) $(LIBC_DRIVER)

.PHONY: lib
lib: $(LIBSHARD)

.PHONY: bin
bin: $(SHARD_BIN)

.PHONY: debug
debug: CFLAGS += -fsanitize=address,undefined -g
debug: LDFLAGS += -lasan -lubsan
debug: all

$(BUILD_PREFIX):
	@echo "  MKDIR $(BUILD_PREFIX)"
	@mkdir -p $(BUILD_PREFIX)

$(SHARD_BIN): $(SHARDBIN_OBJECTS) $(LIBSHARD_OBJ) $(LIBC_DRIVER)
	@echo "  CCLD  $@"
	@$(CC) -o $@ $^ $(LDFLAGS) $(BIN_LDFLAGS) 

$(LIBSHARD): $(LIBSHARD_OBJ)
	@echo "  AR    $@"	
	@$(AR) -rcs $@ $<
	@echo " RANLIB	$@"
	@$(RANLIB) $@

.PHONY: libshard_obj
libshard_obj: $(LIBSHARD_OBJ)

$(LIBSHARD_OBJ): $(LIBSHARD_OBJECTS) | $(BUILD_PREFIX)	
	@echo "  LD    $@"
	@$(LD) -r $^ -o $@

$(BUILD_PREFIX)/%.o: %.c | $(BUILD_PREFIX) $(GCBOEHM_INCLUDE_DIR)
	@echo "  CC    $^"
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) -MMD -MP -MF "$(@:%.o=%.d)" -c $^ -o $@

.PHONY: libffi
libffi: $(LIBFFI_LIB)

$(LIBFFI_LIB): $(LIBFFI_SRC_DIR)/Makefile | $(BUILD_PREFIX)
	$(MAKE) -C $(LIBFFI_SRC_DIR)
	cp -rv $(shell find $(LIBFFI_SRC_DIR) -name 'libffi.a') $@

$(LIBFFI_SRC_DIR)/Makefile: $(LIBFFI_SRC_DIR)
	@echo "  PUSHD $(LIBFFI_SRC_DIR)"		&& \
		pushd $(LIBFFI_SRC_DIR)				&& \
		echo "Configuring libffi..."		&& \
		CC=$(CC) CXX=$(CXX)					&& \
		./configure --enable-static=yes --enable-shared=no --disable-docs	&& \
		echo "Configuring libffi done."

$(LIBFFI_SRC_DIR): $(LIBFFI_TAR)
	@echo "  TAR   $^"
	@tar xf $^ -C $(dir $(LIBFFI_SRC_DIR))

$(LIBFFI_TAR):
	@echo "  WGET  $@"
	@wget $(LIBFFI_TAR_LINK) -O $@

.PHONY: gcboehm
gcboehm: $(GCBOEHM_LIB)

$(GCBOEHM_LIB): $(GCBOEHM_SRC_DIR)/Makefile
	$(MAKE) -C $(GCBOEHM_SRC_DIR)

$(GCBOEHM_SRC_DIR)/Makefile: $(GCBOEHM_SRC_DIR)/libatomic_ops
	@echo "  PUSHD $(GCBOEHM_SRC_DIR)"		&& \
		pushd $(GCBOEHM_SRC_DIR) 			&& \
		echo "Configuring gcboehm..." 		&& \
		autoreconf -vif 					&& \
		automake --add-missing 				&& \
		CC=$(CC) CXX=$(CXX)					   \
		./configure --enable-static=yes --enable-shared=no		&& \
		echo "Configuring gcboehm done."

$(GCBOEHM_SRC_DIR)/libatomic_ops: $(LIBATOMIC_OPS_SRC_DIR) | $(GCBOEHM_SRC_DIR)
	@echo "  LN[S] $@"
	@ln -s $(shell realpath $^) $@

$(GCBOEHM_SRC_DIR): $(GCBOEHM_TAR)
	@echo "  TAR   $^"
	@tar xf $^ -C $(dir $(GCBOEHM_SRC_DIR))

$(GCBOEHM_TAR):
	@echo "  WGET  $@"
	@wget $(GCBOEHM_TAR_LINK) -O $@

$(LIBATOMIC_OPS_TAR):
	@echo "  WGET  $@"
	@wget $(LIBATOMIC_OPS_TAR_LINK) -O $@

$(LIBATOMIC_OPS_SRC_DIR): $(LIBATOMIC_OPS_TAR)
	@echo "  TAR   $^"
	@tar xf $^ -C $(dir $(LIBATOMIC_OPS_SRC_DIR))

.PHONY: libc-driver
libc-driver: $(LIBC_DRIVER)

.PHONY: test
test: $(TEST_RUNNER_BIN)
	$(realpath $<) -d tests

.PHONY: test-runner
test-runner: $(TEST_RUNNER_BIN)

$(TEST_RUNNER_BIN): $(TEST_RUNNER_SOURCE) $(LIBSHARD_OBJ) $(LIBC_DRIVER)
	@mkdir -p $(dir $@)
	@echo "  CC    $< -> $@"
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^	

.PHONY: install
install: install-lib

.PHONY: install-lib
install-lib: $(LIBSHARD)
	install -m "644" $(LIBSHARD) $(PREFIX)/lib/$(notdir $(LIBSHARD))
	install -m "644" $(LIBSHARD_H) $(PREFIX)/include/$(notdir $(LIBSHARD_H))

.PHONY: install-bin
install-bin: $(SHARD_BIN)
	install -m "777" $(SHARD_BIN) $(PREFIX)/bin/$(notdir $(SHARD_BIN))

.PHONY: install-libc-dirver
install-libc-driver: $(LIBC_DRIVER)
	install -m "644" $(LIBC_DRIVER) $(PREFIX)/lib/$(notdir $(LIBC_DIRVER))
	install -m "644" $(LIBC_DRIVER_HEADER) $(PREFIX)/include/$(notdir $(LIBC_DRIVER_HEADER))

.PHONY: clean-all
clean-all: clean clean-gcboehm clean-libffi

.PHONY: clean
clean:
	rm -rf $(BUILD_PREFIX)

.PHONY: clean-gcboehm
clean-gcboehm: clean
	rm -rf $(LIBATOMIC_OPS_SRC_DIR) $(LIBATOMIC_OPS_TAR)
	rm -rf $(GCBOEHM_SRC_DIR) $(GCBOEHM_TAR)

.PHONY: clean-libffi
clean-libffi: clean
	rm -rf $(LIBFFI_SRC_DIR) $(LIBFFI_TAR)

