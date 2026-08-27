#!/usr/bin/env python3
# fix_doom_build.py — fix duplicates, add stubs, prepare for link
import os

# 1. Remove duplicate strcasecmp/strncasecmp from ctype.c
ctype_path = '/mnt/c/Users/tosha/Downloads/RiscV/sw/platform/include/ctype.c'
s = open(ctype_path).read()
# remove strcasecmp and strncasecmp function bodies (keep declarations in .h)
import re
s = re.sub(r'int strcasecmp\(const char\*a,const char\*b\)\s*\{[^}]*\}\s*', '', s)
s = re.sub(r'int strncasecmp\(const char\*a,const char\*b,unsigned long n\)\s*\{[^}]*\}\s*', '', s)
open(ctype_path, 'w').write(s)
print("1. ctype.c dedup done")

# 2. Append net/joystick stubs to riscvsoc_stubs.c
stubs_path = '/mnt/c/Users/tosha/Downloads/RiscV/sw/platform/riscvsoc_stubs.c'
net_stubs = '''

// ---------------- network / joystick stubs (single-player) ----------------
int net_client_connected = 0;
int drone = 0;
int netcmds[BACKUPTICS];
void I_BindJoystickVariables(void) { }
void I_InitJoystick(void) { }
void D_ConnectNetGame(void) { }
void D_CheckNetGame(void) { }
int I_ConnectNetGame(void) { return 0; }
'''
with open(stubs_path, 'a') as f:
    f.write(net_stubs)
print("2. net/joystick stubs appended")

# 3. Check crt.S stack setup
crt_path = '/mnt/c/Users/tosha/Downloads/RiscV/sw/platform/crt.S'
crt = open(crt_path).read()
print("3. crt.S content:")
print(crt[:500])
