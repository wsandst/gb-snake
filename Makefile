
SRC_DIR := src
OBJ_DIR := build/obj
BIN_DIR := build

SRC := $(wildcard $(SRC_DIR)/*.asm)
INCLUDES := $(wildcard $(SRC_DIR)/*.inc)
OBJ := $(SRC:$(SRC_DIR)/%.asm=$(OBJ_DIR)/%.o)


ROM := $(BIN_DIR)/snake.gb

.PHONY: all clean

# Compile program
all: $(ROM)

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@
	
$(ROM): $(OBJ) | $(BIN_DIR) $(OBJ_DIR)
	rgblink -o $@ $^ && \
	rgbfix -v -p 0xFF $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm $(INCLUDES) | $(OBJ_DIR)
	rgbasm -i $(SRC_DIR) -L -o $@ $<

clean:
	@$(RM) -rv $(BIN_DIR) $(OBJ_DIR)

-include $(OBJ:.o=.d)