#
# Arduino Makefile
#
# Requires:
#  * Arduino SDK
#  * gcc-avr
#  * binutils-avr
#  * avr-libc
#  * avrdude
#
# 1. Install dependencies listed above
# 2. Make sure the variables ARDUINO_PATH, BOARD, and SERIAL_PORT are
#    configured correctly for your project.
# 3. Place your source files in the subdirectory 'src'. Don't use file
#    names that already exist in the Arduino sources -- like main.c(pp).
#    Check (arduino_path)/hardware/arduino/cores/arduino/.
# 4. List your C source files in the variables C_SRC, and C++ sources
#    in CPP_SRC.
# 5. Set the PROJECT variable to your project name.
# 6. Run 'make' to build your project.
# 7. Run 'make upload' to upload the code to your Arduino.
#

#########################################
# Configuration
#########################################

# Path to arduino software
ARDUINO_PATH = /usr/share/arduino
# Board name ('uno', 'atmega328','diecimila', etc)
# For a list run 'make boards'
BOARD = uno

# Serial port for uploading.
SERIAL_PORT = /dev/ttyUSB0

# Build tools
CC      = avr-gcc
CXX     = avr-g++
AR      = avr-ar
OBJCOPY = avr-objcopy
STRIP   = avr-strip
AVRDUDE = avrdude
SIZE	= avr-size

#########################################
# Project sources
#########################################

PROJECT := example
C_SRC := 
CPP_SRC := src/example.cpp
INC := 

# Directory containing source files
SRC_DIR = src
# Directory to place compiled .o files.
BUILD_DIR = build

#########################################
# Hardware variables
#########################################

# Arduino files
BOARDS.TXT=$(ARDUINO_PATH)/hardware/arduino/boards.txt

# Set arduino includes
VARIANT=$(shell grep "^$(BOARD).build.variant" $(BOARDS.TXT) 2> /dev/null | sed 's|.*=\(.*\)|\1|' 2> /dev/null)
ARDUINO_INC = $(ARDUINO_PATH)/hardware/arduino/cores/arduino
ARDUINO_VARIANT_INC = $(ARDUINO_PATH)/hardware/arduino/variants/$(VARIANT)

# Compilation hardware flags
MCU=$(shell grep "^$(BOARD).build.mcu" $(BOARDS.TXT) 2> /dev/null | sed 's|.*=\(.*\)|\1|')
F_CPU=$(shell grep "^$(BOARD).build.f_cpu" $(BOARDS.TXT) 2> /dev/null | sed 's|.*=\(.*\)|\1|')

CFLAGS_HW := -mmcu=$(MCU) -DF_CPU=$(F_CPU)

# Avrdude hardware flags
AVRDUDE.CONF = $(ARDUINO_PATH)/hardware/tools/avrdude.conf
# Grep avrdude protocol
AVRDUDE_PROTOCOL=$(shell grep "^$(BOARD).upload.protocol" $(BOARDS.TXT) 2> /dev/null | sed 's|.*=\(.*\)|\1|')
AVRDUDE_HW := -p$(MCU) -c$(AVRDUDE_PROTOCOL) -P$(SERIAL_PORT)

#########################################
# Compiler variables
#########################################

# Compiler includes
INC_DIRS := -I $(SRC_DIR)
INC_DIRS += -I $(ARDUINO_INC)
INC_DIRS += -I $(ARDUINO_VARIANT_INC)

# Compiler flags
CFLAGS := -Wall -Os $(CFLAGS_HW) $(INC_DIRS) 
CXXFLAGS := -Wall -Os $(CFLAGS_HW) $(INC_DIRS)
CFLAGS_ELF := $(CFLAGS_HW) -Wall -Os -L .

# Arduino sources
ARDUINO_C_SRC   = $(shell ls $(ARDUINO_INC)/*.c  2> /dev/null)
ARDUINO_CPP_SRC = $(shell ls $(ARDUINO_INC)/*.cpp  2> /dev/null)
ARDUINO_OBJ := $(addprefix $(BUILD_DIR)/,$(notdir $(ARDUINO_C_SRC:.c=.o))) 
ARDUINO_OBJ += $(addprefix $(BUILD_DIR)/,$(notdir $(ARDUINO_CPP_SRC:.cpp=.o)))

# Project sources
OBJ := $(addprefix $(BUILD_DIR)/,$(notdir $(C_SRC:.c=.o)))
OBJ += $(addprefix $(BUILD_DIR)/,$(notdir $(CPP_SRC:.cpp=.o)))


########################################
# Rules
########################################

.PHONY: all
all: requirements info $(PROJECT).hex

# List boards
.PHONY: boards
boards:
	grep -o "^[^.#]\+" $(BOARDS.TXT) | uniq

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

.PHONY: info
info:
	@echo "-----------------------------------------"
	@echo "Board:           $(BOARD) ($(VARIANT))"
	@echo "MCU:             $(MCU) (speed: $(F_CPU))"
	@echo "Serial port:     $(SERIAL_PORT)"
	@echo "Upload protocol: $(AVRDUDE_PROTOCOL)"
	@echo "-----------------------------------------"

.PHONY: size
size: $(PROJECT).elf
	$(SIZE) $<

.PHONY: clean
clean:
	@$(RM) -v $(PROJECT).elf
	@$(RM) -v $(PROJECT).hex
	@$(RM) -v libarduino.a
	@$(RM) -v $(BUILD_DIR)/*.o
	@rmdir -v $(BUILD_DIR)

# Check if the arduino sdk files exist.
# Check if boards.txt contains the needed settings. 
.PHONY: requirements
requirements:
ifeq ($(wildcard $(BOARDS.TXT)),)
	$(error "boards.txt not found.")
endif
ifeq ($(VARIANT),)
	$(error "$(BOARD).build.variant not found. Check the section \
for your board in $(BOARDS.TXT)")
endif
ifeq ($(MCU),)
	$(error "$(BOARD).build.mcu not found. Check the section \
for your board in $(BOARDS.TXT)")
endif
ifeq ($(F_CPU),)
	$(error "$(BOARD).build.f_cpu not found. Check the section \
for your board in $(BOARDS.TXT)")
endif
ifeq ($(AVRDUDE_PROTOCOL),)
	$(error "$(BOARD).upload.protocol not found. Check the section \
for your board in $(BOARDS.TXT)")
endif
ifeq ($(wildcard $(ARDUINO_INC)),)
	$(error "Arduino source files not found. Expected \
include path: $(ARDUINO_INC)")
endif
ifeq ($(wildcard $(ARDUINO_VARIANT_INC)),)
	$(error "Arduino $(VARIANT) source files not found. Expected \
include path: $(ARDUINO_VARIANT_INC)")
endif
ifeq ($(wildcard $(AVRDUDE.CONF)),)
	$(error "Avrdude conf $(AVRDUDE.CONF) not found.")
endif

########################################
# Libarduino rules
########################################
libarduino.a: $(BUILD_DIR) $(ARDUINO_OBJ)
	$(AR) rcs libarduino.a $(ARDUINO_OBJ)

$(BUILD_DIR)/%.o: $(ARDUINO_INC)/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(BUILD_DIR)/%.o: $(ARDUINO_INC)/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

########################################
# Project rules
########################################
$(PROJECT).hex: $(PROJECT).elf
	$(STRIP) -s $(PROJECT).elf
	$(OBJCOPY) -O ihex -R .eeprom $(PROJECT).elf $(PROJECT).hex

$(PROJECT).elf: libarduino.a $(OBJ) $(SRC) $(INC)
	$(CXX) $(CFLAGS_ELF) $(OBJ) -o $(PROJECT).elf -larduino

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

.PHONY: upload
upload: $(PROJECT).hex
	stty -F $(SERIAL_PORT) hupcl
	$(AVRDUDE) -C $(AVRDUDE.CONF) -q -q $(AVRDUDE_HW) -D -Uflash:w:$(PROJECT).hex:i


