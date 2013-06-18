# Directory to place compiled .o files.
BUILD_DIR = build

# Build tools
CC  = avr-gcc
CXX = avr-g++
AR  = avr-ar

# Arduino sources
C_SRC   = $(shell ls $(ARDUINO_INC)/*.c  2> /dev/null)
CPP_SRC = $(shell ls $(ARDUINO_INC)/*.cpp  2> /dev/null)
OBJ = $(addprefix $(BUILD_DIR)/, $(notdir $(C_SRC:.c=.o))) 
OBJ += $(addprefix $(BUILD_DIR)/, $(notdir $(CPP_SRC:.cpp=.o)))

.PHONY: all
all: libarduino.a

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

libarduino.a: $(BUILD_DIR) $(OBJ)
	$(AR) rcs libarduino.a $(OBJ)

# Compile arduino sources into BUILD_DIR
$(BUILD_DIR)/%.o: $(ARDUINO_INC)/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(BUILD_DIR)/%.o: $(ARDUINO_INC)/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

.PHONY: clean
clean: 
	@$(RM) -v libarduino.a
	@$(RM) -v $(BUILD_DIR)/*.o
	@rmdir -v $(BUILD_DIR)
