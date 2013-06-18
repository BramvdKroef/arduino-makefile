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
# 
# 2. Place your source files(.c, .cpp, .pde) in the subdirectory
#    'src'. 
#
# 3. Set the PROJECT variable to your project name.
# 
# 4. Make sure the variables ARDUINO_PATH, BOARD, and SERIAL_PORT are
#    configured correctly for your project.
#
#    You can also set these manually when you run make. For example
#    'make BOARD=nano' or 'make upload SERIAL_PORT=/dev/ttyACM0'
#    
# 5. Run 'make' to build your project.
# 
# 6. Run 'make upload' to upload the code to your Arduino.
#
# Extra:
# - make boards  gives a list of boards.
# - make info    outputs the values of the settings.
# - make size    gives the size of the compiled binary.

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

#########################################
# Project sources
#########################################

PROJECT := example
INC := 

# Directory containing source files
SRC_DIR = src
# Directory to place compiled .o files.
BUILD_DIR = build

#########################################
# Build tools
#########################################

CC      = avr-gcc
CXX     = avr-g++
OBJCOPY = avr-objcopy
STRIP   = avr-strip
AVRDUDE = avrdude
SIZE	= avr-size

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

COMPILER_FLAGS = -Wall -Os -funsigned-char -funsigned-bitfields -fpack-struct -fno-exceptions

# Compiler includes
INC_DIRS := -I $(SRC_DIR)
INC_DIRS += -I $(ARDUINO_INC)
INC_DIRS += -I $(ARDUINO_VARIANT_INC)

# Compiler flags
CFLAGS := $(COMPILER_FLAGS) $(CFLAGS_HW) $(INC_DIRS) 
CXXFLAGS := $(COMPILER_FLAGS) $(CFLAGS_HW) $(INC_DIRS)
CFLAGS_ELF := $(CFLAGS_HW) -Wall -Os 

# Project sources
C_SRC   = $(shell ls $(SRC_DIR)/*.c 2> /dev/null)
CPP_SRC = $(shell ls $(SRC_DIR)/*.cpp 2> /dev/null)
PDE_SRC = $(shell ls $(SRC_DIR)/*.pde 2> /dev/null)

OBJ := $(addprefix $(BUILD_DIR)/,$(notdir $(C_SRC:.c=.o)))
OBJ += $(addprefix $(BUILD_DIR)/,$(notdir $(CPP_SRC:.cpp=.o)))
OBJ += $(addprefix $(BUILD_DIR)/,$(notdir $(PDE_SRC:.pde=.o)))

LIBARDUINO_DIR=libarduino
LIBARDUINO=$(LIBARDUINO_DIR)/libarduino.a
export ARDUINO_INC
export INC_DIRS
export CFLAGS
export CXXFLAGS
########################################
# Rules
########################################

.PHONY: all
all: requirements info $(PROJECT).hex

# List boards
.PHONY: boards
boards:
	@grep -o "^[^.#]\+.name=.\+" $(BOARDS.TXT) | \
sed 's|\(.*\).name=\(.*\)|\1 (\2)|g'

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

$(LIBARDUINO):
	$(MAKE) -C $(LIBARDUINO_DIR)

########################################
# Project rules
########################################
$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(PROJECT).hex: $(PROJECT).elf
	$(STRIP) -s $(PROJECT).elf
	$(OBJCOPY) -O ihex -R .eeprom $(PROJECT).elf $(PROJECT).hex

$(PROJECT).elf: $(BUILD_DIR) $(LIBARDUINO) $(OBJ) $(SRC) $(INC)
	$(CXX) $(CFLAGS_ELF) $(OBJ) -o $(PROJECT).elf \
	-L$(LIBARDUINO_DIR) -larduino

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

# Convert pde files to cpp files.
# Make automatically figures out it needs to convert .pde to .cpp to
# create the .o file.
$(BUILD_DIR)/%.cpp: $(SRC_DIR)/%.pde
	echo '#include <Arduino.h>' > $@
	cat $< >> $@
	echo 'extern "C" void __cxa_pure_virtual() { while(1); }' >> $@

.PHONY: upload
upload: $(PROJECT).hex
	stty -F $(SERIAL_PORT) hupcl
	$(AVRDUDE) -C $(AVRDUDE.CONF) $(AVRDUDE_HW) -D -Uflash:w:$(PROJECT).hex:i

.PHONY: monitor
monitor:
	cat $(SERIAL_PORT)
