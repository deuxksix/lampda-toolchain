SRC_DIR = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
VENV_DIR = $(SRC_DIR)venv
PATCH_DIR = $(SRC_DIR)patches
BOARD_NAME = LampDa_nRF52_Arduino
BOARD_DIR = $(SRC_DIR)$(BOARD_NAME)
ROOT_URL = https://github.com/BaptisteHudyma
NRF_REPO = $(ROOT_URL)/$(BOARD_NAME)
LMBD_REPO = $(ROOT_URL)/Lamp-Da
LMBD_DIR = $(SRC_DIR)LampColorControler
ARDUINO_PATH = $(shell arduino-cli config get directories.data)
ARDUINO_BOARD = $(ARDUINO_PATH)/packages/adafruit/hardware/nrf52
ADAFRUIT_FQBN = adafruit:nrf52
ADAFRUIT_INDEX = https://adafruit.github.io/arduino-board-index/package_adafruit_index.json

all: install-board install-libs install-venv clone-repo

$(LMBD_DIR)/.git/HEAD:
	@echo -e "\n --- $@"
	# clone main repo if needed...
	git clone --recurse-submodules $(LMBD_REPO) $(LMBD_DIR)
	cd $(LMBD_DIR) && git checkout indexable_strip_base

clone-repo: $(LMBD_DIR)/.git/HEAD
	@echo -e " --- ok: $@"

$(BOARD_DIR)/.git/HEAD:
	@echo -e "\n --- $@"
	# clone board repo if needed...
	git clone --recurse-submodules $(NRF_REPO) $(BOARD_DIR)

clone-board: $(BOARD_DIR)/.git/HEAD
	@echo -e " --- ok: $@"

$(BOARD_DIR)/platform.local.txt: clone-board
	@echo -e "\n --- $@"
	# copy custom build flags...
	cp $(SRC_DIR)/platform.local.txt $(BOARD_DIR)/
	# copy patches...
	cp $(PATCH_DIR)/$(BOARD_NAME).patch $(BOARD_DIR)/
	cp $(PATCH_DIR)/Adafruit_TinyUSB_Arduino.patch $(BOARD_DIR)/libraries/Adafruit_TinyUSB_Arduino/
	# apply patches...
	cd $(BOARD_DIR) && git apply $(BOARD_NAME).patch
	cd $(BOARD_DIR)/libraries/Adafruit_TinyUSB_Arduino && git apply Adafruit_TinyUSB_Arduino.patch

clean-patches:
	@echo -e "\n --- $@"
	# reset repositories...
	@(test -d $(BOARD_DIR) && \
		cd $(BOARD_DIR) && git reset --hard) || echo '->' no repository to clean up
	@(test -d $(BOARD_DIR) && \
		cd $(BOARD_DIR)/libraries/Adafruit_TinyUSB_Arduino/ && git reset --hard) || true
	# removing patches...
	@rm -f $(BOARD_DIR)/platform.local.txt \
		   $(BOARD_DIR)/$(BOARD_NAME).patch \
		   $(BOARD_DIR)/libraries/Adafruit_TinyUSB_Arduino/Adafruit_TinyUSB_Arduino.patch

apply-patches: clean-patches $(BOARD_DIR)/platform.local.txt
	@echo -e " --- ok: $@"

$(ARDUINO_BOARD)/platform.local.txt: apply-patches
	@echo -e "\n --- $@"
	# checking if board is installed...
	@(test ! -d $(ARDUINO_BOARD) \
		&& arduino-cli core install '$(ADAFRUIT_FQBN)' --additional-urls '$(ADAFRUIT_INDEX)') \
		|| echo '->' board present
	# checking if board is a custom repository...
	@(test -e $(ARDUINO_BOARD)/1.*/README.md \
		&& mv $(ARDUINO_BOARD) $(ARDUINO_BOARD).$(shell date +%Y%m%d%H%M%S).backup) \
		|| echo '->' previous custom repository removed
	# remove previous repository if needed...
	@(test -e $(ARDUINO_BOARD)/.git/HEAD \
		&& rm -rf $(ARDUINO_BOARD)) || echo '->' default board install saved
	# replacing board with our custom repository...
	cp -r $(BOARD_DIR) $(ARDUINO_BOARD)

install-libs:
	@echo -e "\n --- $@"
	arduino-cli lib install "Adafruit NeoPixel"
	arduino-cli lib install "arduinoFFT"

install-board: $(ARDUINO_BOARD)/platform.local.txt
	@echo -e " --- ok: $@"

$(VENV_DIR)/bin/activate:
	@echo -e "\n --- $@"
	python -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate && pip install -r $(VENV_DIR)/../requirements.txt

install-venv: $(VENV_DIR)/bin/activate
	@echo -e " --- ok: $@"

clean: clean-patches
	@echo -e "\n --- $@"
	# restore original board directory...
	@(export BDIR="$(dir $(ARDUINO_BOARD))$$(ls $(dir $(ARDUINO_BOARD))|grep 'backup$$'|sort -rn|head -n 1)" \
		&& grep -q '.backup$$' <<<"$$BDIR" \
	    && test -d $$BDIR \
		&& rm -rf "$(ARDUINO_BOARD)" \
		&& mv $$BDIR "$(ARDUINO_BOARD)") || echo '->' nothing to clean up

mr_proper: clean
	@echo -e "\n --- $@"
	# removing repository...
	rm -rf $(BOARD_DIR)
