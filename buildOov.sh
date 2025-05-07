#!/bin/bash
swift build -c release
sudo cp .build/release/Oov /usr/local/bin/oov

