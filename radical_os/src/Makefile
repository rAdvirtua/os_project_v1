ASM=nasm

SRC_DIR = radical_os/src
BUILD_DIR = build

$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/main.bin
	cp $(BUILD_DIR)/main.bin $(BUILD_DIR)/main_floppy.img
	truncate -s 1440k $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main.bin: $(SRC_DIR)/bootloader/main.asm
	$(ASM) $(SRC_DIR)/bootloader/main.asm -f bin -o $(BUILD_DIR)/main.bin
