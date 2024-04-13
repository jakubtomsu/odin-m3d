cl /c m3d.c /Z7 /D_DEBUG
lib /OUT:m3d_windows_debug.lib m3d.obj

cl /c m3d.c /Os
lib /OUT:m3d_windows_release.lib m3d.obj

del m3d.obj