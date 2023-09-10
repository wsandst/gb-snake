
SRC_DIR := src
OBJ_DIR := build/obj
BIN_DIR := build
HUGE_DRIVER_DIR := hUGEDriver

SRC := src/main.asm src/music.asm $(HUGE_DRIVER_DIR)/hUGEDriver.asm
INCLUDES := $(wildcard $(SRC_DIR)/*.inc)
HUGE_DRIVER_INCLUDES := $(wildcard $(HUGE_DRIVER_DIR)/include/*.inc)

ROM := $(BIN_DIR)/snake.gb

.PHONY: all clean

# Compile program
all: $(ROM)

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@
	
$(ROM): $(OBJ_DIR)/main.o $(OBJ_DIR)/music.o $(OBJ_DIR)/hUGEDriver.o | $(BIN_DIR) $(OBJ_DIR)
	rgblink -o $@ $^ && \
	rgbfix -v -p 0xFF $@

# Janky way of getting music.asm and hUGEDriver.asm to compile
$(OBJ_DIR)/music.o: src/music.asm $(HUGE_DRIVER_INCLUDES) | $(OBJ_DIR)
	cd $(HUGE_DRIVER_DIR) && rgbasm -i include -L -o ../$@ ../$<

$(OBJ_DIR)/hUGEDriver.o: $(HUGE_DRIVER_DIR)/hUGEDriver.asm $(HUGE_DRIVER_INCLUDES) | $(OBJ_DIR)
	cd $(HUGE_DRIVER_DIR) && rgbasm -i include -L -o ../$@ ../$<

$(OBJ_DIR)/main.o: src/main.asm $(INCLUDES) | $(OBJ_DIR)
	rgbasm -i $(SRC_DIR) -L -o $@ $<

clean:
	@$(RM) -rv $(BIN_DIR) $(OBJ_DIR)