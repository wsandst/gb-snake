
SRC_DIR := src
OBJ_DIR := build/obj
BIN_DIR := build

SRC := $(wildcard $(SRC_DIR)/*.asm)
OBJ := $(SRC:$(SRC_DIR)/%.asm=$(OBJ_DIR)/%.o)

ROM := $(BIN_DIR)/snake.gb

.PHONY: all clean

# Compile program
all: $(ROM)

test: 
	$(info    OBJ is $(OBJ))

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@

$(OBJ_DIR)/hello-world.o: $(SRC_DIR)/hello-world.asm
	rgbasm -i $(SRC_DIR) -L -o $@ $<

$(ROM): $(OBJ) | $(BIN_DIR) $(OBJ_DIR)
	rgblink -o $(BIN_DIR)/snake.gb $(OBJ_DIR)/hello-world.o && \
	rgbfix -v -p 0xFF $(BIN_DIR)/snake.gb

clean:
	@$(RM) -rv $(BIN_DIR) $(OBJ_DIR)

-include $(OBJ:.o=.d)