#!/bin/bash
cd "$(dirname "$0")"
xcodebuild build -scheme TasmotaApp -sdk iphonesimulator
