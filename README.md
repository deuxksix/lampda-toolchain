
# Lamp-Da toolchain

This repository automates the setup of
[Lamp-Da](https://github.com/BaptisteHudyma/Lamp-Da)
for indexable strip development:

```sh
git clone https://github.com/deuxksix/lampda-toolchain
cd lampda-toolchain
make
```

Your mileage may vary, but here is what to expect after setup:

```sh
% tree
├── LampColorControler
│   ├── LICENSE
│   ├── LampColorControler.ino
│   ├── Medias
│   ├── README.md
│   ├── electrical
│   ├── flashInfo
│   ├── venv
│   └── src
├── LampDa_nRF52_Arduino
├── Makefile
├── README.md
├── patches
├── platform.local.txt
├── requirements.txt
└── venv

% tree ~/Arduino/libraries
$HOME/Arduino/libraries
├── Adafruit_NeoPixel
└── arduinoFFT

% tree ~/.arduino*/packages/adafruit/hardware/
$HOME/.arduino*/packages/adafruit/hardware/
├── nrf52
│   ├── README.md
│   ├── boards.txt
│   ├── platform.txt
│   ├── platform.local.txt
│   ├── LampDa_nRF52_Arduino.patch
│   ├── cores
│   ├── libraries
    ...
│   ├── scripts
│   ├── tools
│   └── variants
└── nrf52.$(date +%Y%m%d%H%M%S).backup
    └── $VERSION
```

Restore your `nrf52` install with `make clean`.

**Note: using `make mr_proper` will remove cloned repositories without warning.**
