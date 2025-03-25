BUILD_DIR?= build/
ASM?= nasm
CC16 = /usr/bin/watcom/binl/wcc
LD16 = /usr/bin/watcom/binl/wlink

SOURCES = $(wildcard *.c)
SOURCES_ASM = $(wildcard *.c)
OBJECTS_C = 	$(patsusbt %.c, $(BUILD_DIR))


.PHONY: all stage2 clean

all: stage2

stage2: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin:
	$(ASM) main.asm -f bin -o $(BUILD_DIR)/stage2.bin

clean:
	rm -f $(BUILD_DIR)/stage2.bin