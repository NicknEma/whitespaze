@echo off

if not exist build mkdir build
pushd build

del *.pdb > NUL 2> NUL

rc /nologo /foresources.res ../source/resources.rc
odin build ../source -out:whitespaze_debug.exe -debug -vet-shadowing -warnings-as-errors -extra-linker-flags:resources.res
del resources.res > NUL 2> NUL

popd
