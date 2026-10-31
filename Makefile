GAME_NAME := example

SRC_DIR := src
BUILD_DIR := build
GAME_BUILD_DIR = $(BUILD_DIR)/$(GAME_NAME)
LOVE_FILE = $(BUILD_DIR)/$(GAME_NAME).love

YUE_SRC := $(shell find $(SRC_DIR) -name '*.yue' 2>/dev/null)
OTHER_SRC := $(shell find $(SRC_DIR) -type f ! -name '*.yue' 2>/dev/null)
YUE_OBJ := $(patsubst $(SRC_DIR)/%.yue, $(GAME_BUILD_DIR)/%.lua, $(YUE_SRC))
OTHER_OBJ := $(patsubst $(SRC_DIR)/%, $(GAME_BUILD_DIR)/%, $(OTHER_SRC))

.PHONY: all clean

all: $(YUE_OBJ) $(OTHER_OBJ) love

love: $(LOVE_FILE)
$(LOVE_FILE): $(YUE_OBJ) $(OTHER_OBJ)
	@mkdir -p $(BUILD_DIR)
	@cd $(GAME_BUILD_DIR) && zip -9 -r ../$(GAME_NAME).love . -x ".*"
	@echo "Created $(LOVE_FILE)"

$(GAME_BUILD_DIR)/%.lua: $(SRC_DIR)/%.yue
	@mkdir -p $(dir $@)
	yue -m -o $@ $<

$(GAME_BUILD_DIR)/%: $(SRC_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

clean:
	rm -rf $(BUILD_DIR)/