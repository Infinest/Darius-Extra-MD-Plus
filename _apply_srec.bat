copy ROMS\in.md OUTPUT\out_temp.md
TOOLS\srecpatch.exe "OUTPUT\out_temp.md" OUTPUT\out.md<srecfile.txt
del "OUTPUT\out_temp.md"
del srecfile.txt