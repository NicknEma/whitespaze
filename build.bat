@echo off
del *.pdb > NUL 2> NUL
if not exist build mkdir build
odin build source -out:build/whitespaze_debug.exe -debug -vet-shadowing
