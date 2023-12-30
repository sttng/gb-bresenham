ASM = rgbasm
LINK = rgblink
FIX = rgbfix

SRC_DIR = src
INC_DIR = inc
BUILD_DIR = build

ROM_NAME = game
OUTPUT = $(ROM_NAME).gb

ASM_FILES = $(wildcard $(SRC_DIR)/*.asm)
OBJ_INPUT = $(ASM_FILES:%.asm=%.o)
OBJ_OUTPUT = $(addprefix $(BUILD_DIR)/, $(notdir $(ASM_FILES:%.asm=%.o)))

ASM_FLAGS = -L -i $(INC_DIR)
LINK_FLAGS = 
FIX_FLAGS = -p 0x00 -v

%.o: %.asm
	$(ASM) -i $(INC_DIR) -o $(BUILD_DIR)/$(notdir $@) $<

$(OUTPUT): $(OBJ_INPUT)
	$(LINK) $(LINK_FLAGS) -o $@ $(OBJ_OUTPUT)
	$(FIX) $(FIX_FLAGS) $(OUTPUT)

prepare:
	mkdir $(BUILD_DIR)

all: $(OUTPUT)

clean:
	rmdir /S /Q $(BUILD_DIR)