@echo off
lazygit-custom-pager-wrapper %* | delta --features="default-feature lazygit" --width=%LAZYGIT_COLUMNS%
