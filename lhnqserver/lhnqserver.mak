# Microsoft Developer Studio Generated NMAKE File, Format Version 40001
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

!IF "$(CFG)" == ""
CFG=lhnqserver - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to lhnqserver - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "lhnqserver - Win32 Release" && "$(CFG)" !=\
 "lhnqserver - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "lhnqserver.mak" CFG="lhnqserver - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "lhnqserver - Win32 Release" (based on\
 "Win32 (x86) Console Application")
!MESSAGE "lhnqserver - Win32 Debug" (based on\
 "Win32 (x86) Console Application")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 
################################################################################
# Begin Project
# PROP Target_Last_Scanned "lhnqserver - Win32 Debug"
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(OUTDIR)\lhnqserver.exe"

CLEAN : 
	-@erase ".\Release\lhnqserver.exe"
	-@erase ".\Release\pr_edict.obj"
	-@erase ".\Release\world.obj"
	-@erase ".\Release\pr_cmds.obj"
	-@erase ".\Release\sv_move.obj"
	-@erase ".\Release\pr_exec.obj"
	-@erase ".\Release\model_alias.obj"
	-@erase ".\Release\net_wipx.obj"
	-@erase ".\Release\mathlib.obj"
	-@erase ".\Release\model_shared.obj"
	-@erase ".\Release\model_sprite.obj"
	-@erase ".\Release\sv_main.obj"
	-@erase ".\Release\console.obj"
	-@erase ".\Release\sv_user.obj"
	-@erase ".\Release\common.obj"
	-@erase ".\Release\cvar.obj"
	-@erase ".\Release\net_main.obj"
	-@erase ".\Release\crc.obj"
	-@erase ".\Release\host.obj"
	-@erase ".\Release\model_brush.obj"
	-@erase ".\Release\cpu_noasm.obj"
	-@erase ".\Release\host_cmd.obj"
	-@erase ".\Release\net_dgrm.obj"
	-@erase ".\Release\sv_phys.obj"
	-@erase ".\Release\cmd.obj"
	-@erase ".\Release\zone.obj"
	-@erase ".\Release\net_win.obj"
	-@erase ".\Release\net_wins.obj"
	-@erase ".\Release\sys.obj"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /YX /c
# ADD CPP /nologo /G5 /W3 /GX /Ox /Ot /Oa /Og /Oi /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /YX /c
CPP_PROJ=/nologo /G5 /ML /W3 /GX /Ox /Ot /Oa /Og /Oi /D "WIN32" /D "NDEBUG" /D\
 "_CONSOLE" /Fp"$(INTDIR)/lhnqserver.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/lhnqserver.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 wsock32.lib winmm.lib /nologo /subsystem:console /machine:I386
LINK32_FLAGS=wsock32.lib winmm.lib /nologo /subsystem:console /incremental:no\
 /pdb:"$(OUTDIR)/lhnqserver.pdb" /machine:I386 /out:"$(OUTDIR)/lhnqserver.exe" 
LINK32_OBJS= \
	"$(INTDIR)/pr_edict.obj" \
	"$(INTDIR)/world.obj" \
	"$(INTDIR)/pr_cmds.obj" \
	"$(INTDIR)/sv_move.obj" \
	"$(INTDIR)/pr_exec.obj" \
	"$(INTDIR)/model_alias.obj" \
	"$(INTDIR)/net_wipx.obj" \
	"$(INTDIR)/mathlib.obj" \
	"$(INTDIR)/model_shared.obj" \
	"$(INTDIR)/model_sprite.obj" \
	"$(INTDIR)/sv_main.obj" \
	"$(INTDIR)/console.obj" \
	"$(INTDIR)/sv_user.obj" \
	"$(INTDIR)/common.obj" \
	"$(INTDIR)/cvar.obj" \
	"$(INTDIR)/net_main.obj" \
	"$(INTDIR)/crc.obj" \
	"$(INTDIR)/host.obj" \
	"$(INTDIR)/model_brush.obj" \
	"$(INTDIR)/cpu_noasm.obj" \
	"$(INTDIR)/host_cmd.obj" \
	"$(INTDIR)/net_dgrm.obj" \
	"$(INTDIR)/sv_phys.obj" \
	"$(INTDIR)/cmd.obj" \
	"$(INTDIR)/zone.obj" \
	"$(INTDIR)/net_win.obj" \
	"$(INTDIR)/net_wins.obj" \
	"$(INTDIR)/sys.obj"

"$(OUTDIR)\lhnqserver.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(OUTDIR)\lhnqserver.exe"

CLEAN : 
	-@erase ".\Debug\vc40.pdb"
	-@erase ".\Debug\vc40.idb"
	-@erase ".\Debug\lhnqserver.exe"
	-@erase ".\Debug\sv_main.obj"
	-@erase ".\Debug\zone.obj"
	-@erase ".\Debug\model_shared.obj"
	-@erase ".\Debug\net_dgrm.obj"
	-@erase ".\Debug\sv_phys.obj"
	-@erase ".\Debug\pr_cmds.obj"
	-@erase ".\Debug\sv_move.obj"
	-@erase ".\Debug\pr_exec.obj"
	-@erase ".\Debug\world.obj"
	-@erase ".\Debug\net_wins.obj"
	-@erase ".\Debug\net_main.obj"
	-@erase ".\Debug\mathlib.obj"
	-@erase ".\Debug\pr_edict.obj"
	-@erase ".\Debug\host_cmd.obj"
	-@erase ".\Debug\model_alias.obj"
	-@erase ".\Debug\model_sprite.obj"
	-@erase ".\Debug\console.obj"
	-@erase ".\Debug\sv_user.obj"
	-@erase ".\Debug\common.obj"
	-@erase ".\Debug\net_wipx.obj"
	-@erase ".\Debug\crc.obj"
	-@erase ".\Debug\cvar.obj"
	-@erase ".\Debug\model_brush.obj"
	-@erase ".\Debug\host.obj"
	-@erase ".\Debug\cpu_noasm.obj"
	-@erase ".\Debug\net_win.obj"
	-@erase ".\Debug\cmd.obj"
	-@erase ".\Debug\sys.obj"
	-@erase ".\Debug\lhnqserver.ilk"
	-@erase ".\Debug\lhnqserver.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /YX /c
# ADD CPP /nologo /G5 /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /YX /c
CPP_PROJ=/nologo /G5 /MLd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D\
 "_CONSOLE" /Fp"$(INTDIR)/lhnqserver.pch" /YX /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c\
 
CPP_OBJS=.\Debug/
CPP_SBRS=
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/lhnqserver.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /debug /machine:I386
# ADD LINK32 wsock32.lib winmm.lib /nologo /subsystem:console /debug /machine:I386
LINK32_FLAGS=wsock32.lib winmm.lib /nologo /subsystem:console /incremental:yes\
 /pdb:"$(OUTDIR)/lhnqserver.pdb" /debug /machine:I386\
 /out:"$(OUTDIR)/lhnqserver.exe" 
LINK32_OBJS= \
	"$(INTDIR)/sv_main.obj" \
	"$(INTDIR)/zone.obj" \
	"$(INTDIR)/model_shared.obj" \
	"$(INTDIR)/net_dgrm.obj" \
	"$(INTDIR)/sv_phys.obj" \
	"$(INTDIR)/pr_cmds.obj" \
	"$(INTDIR)/sv_move.obj" \
	"$(INTDIR)/pr_exec.obj" \
	"$(INTDIR)/world.obj" \
	"$(INTDIR)/net_wins.obj" \
	"$(INTDIR)/net_main.obj" \
	"$(INTDIR)/mathlib.obj" \
	"$(INTDIR)/pr_edict.obj" \
	"$(INTDIR)/host_cmd.obj" \
	"$(INTDIR)/model_alias.obj" \
	"$(INTDIR)/model_sprite.obj" \
	"$(INTDIR)/console.obj" \
	"$(INTDIR)/sv_user.obj" \
	"$(INTDIR)/common.obj" \
	"$(INTDIR)/net_wipx.obj" \
	"$(INTDIR)/crc.obj" \
	"$(INTDIR)/cvar.obj" \
	"$(INTDIR)/model_brush.obj" \
	"$(INTDIR)/host.obj" \
	"$(INTDIR)/cpu_noasm.obj" \
	"$(INTDIR)/net_win.obj" \
	"$(INTDIR)/cmd.obj" \
	"$(INTDIR)/sys.obj"

"$(OUTDIR)\lhnqserver.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 

.c{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.c{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

################################################################################
# Begin Target

# Name "lhnqserver - Win32 Release"
# Name "lhnqserver - Win32 Debug"

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\zone.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_ZONE_=\
	".\quakedef.h"\
	

"$(INTDIR)\zone.obj" : $(SOURCE) $(DEP_CPP_ZONE_) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_ZONE_=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\zone.obj" : $(SOURCE) $(DEP_CPP_ZONE_) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\cmd.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_CMD_C=\
	".\quakedef.h"\
	

"$(INTDIR)\cmd.obj" : $(SOURCE) $(DEP_CPP_CMD_C) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_CMD_C=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\cmd.obj" : $(SOURCE) $(DEP_CPP_CMD_C) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\common.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_COMMO=\
	".\quakedef.h"\
	

"$(INTDIR)\common.obj" : $(SOURCE) $(DEP_CPP_COMMO) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_COMMO=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\common.obj" : $(SOURCE) $(DEP_CPP_COMMO) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\console.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_CONSO=\
	".\quakedef.h"\
	

"$(INTDIR)\console.obj" : $(SOURCE) $(DEP_CPP_CONSO) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_CONSO=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\console.obj" : $(SOURCE) $(DEP_CPP_CONSO) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\cpu_noasm.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_CPU_N=\
	".\quakedef.h"\
	

"$(INTDIR)\cpu_noasm.obj" : $(SOURCE) $(DEP_CPP_CPU_N) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_CPU_N=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\cpu_noasm.obj" : $(SOURCE) $(DEP_CPP_CPU_N) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\crc.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_CRC_C=\
	".\quakedef.h"\
	".\crc.h"\
	

"$(INTDIR)\crc.obj" : $(SOURCE) $(DEP_CPP_CRC_C) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_CRC_C=\
	".\quakedef.h"\
	".\crc.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\crc.obj" : $(SOURCE) $(DEP_CPP_CRC_C) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\cvar.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_CVAR_=\
	".\quakedef.h"\
	

"$(INTDIR)\cvar.obj" : $(SOURCE) $(DEP_CPP_CVAR_) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_CVAR_=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\cvar.obj" : $(SOURCE) $(DEP_CPP_CVAR_) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\host.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_HOST_=\
	".\quakedef.h"\
	

"$(INTDIR)\host.obj" : $(SOURCE) $(DEP_CPP_HOST_) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_HOST_=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\host.obj" : $(SOURCE) $(DEP_CPP_HOST_) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\host_cmd.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_HOST_C=\
	".\quakedef.h"\
	

"$(INTDIR)\host_cmd.obj" : $(SOURCE) $(DEP_CPP_HOST_C) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_HOST_C=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\host_cmd.obj" : $(SOURCE) $(DEP_CPP_HOST_C) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\mathlib.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_MATHL=\
	".\quakedef.h"\
	

"$(INTDIR)\mathlib.obj" : $(SOURCE) $(DEP_CPP_MATHL) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_MATHL=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\mathlib.obj" : $(SOURCE) $(DEP_CPP_MATHL) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\model_alias.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_MODEL=\
	".\quakedef.h"\
	".\modelgen.h"\
	

"$(INTDIR)\model_alias.obj" : $(SOURCE) $(DEP_CPP_MODEL) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_MODEL=\
	".\quakedef.h"\
	".\modelgen.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\model_alias.obj" : $(SOURCE) $(DEP_CPP_MODEL) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\model_brush.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_MODEL_=\
	".\quakedef.h"\
	

"$(INTDIR)\model_brush.obj" : $(SOURCE) $(DEP_CPP_MODEL_) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_MODEL_=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\model_brush.obj" : $(SOURCE) $(DEP_CPP_MODEL_) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\model_shared.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_MODEL_S=\
	".\quakedef.h"\
	".\modelgen.h"\
	".\spritegn.h"\
	

"$(INTDIR)\model_shared.obj" : $(SOURCE) $(DEP_CPP_MODEL_S) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_MODEL_S=\
	".\quakedef.h"\
	".\modelgen.h"\
	".\spritegn.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\model_shared.obj" : $(SOURCE) $(DEP_CPP_MODEL_S) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\model_sprite.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_MODEL_SP=\
	".\quakedef.h"\
	".\spritegn.h"\
	

"$(INTDIR)\model_sprite.obj" : $(SOURCE) $(DEP_CPP_MODEL_SP) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_MODEL_SP=\
	".\quakedef.h"\
	".\spritegn.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\model_sprite.obj" : $(SOURCE) $(DEP_CPP_MODEL_SP) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\net_dgrm.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_NET_D=\
	".\quakedef.h"\
	".\net_dgrm.h"\
	

"$(INTDIR)\net_dgrm.obj" : $(SOURCE) $(DEP_CPP_NET_D) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_NET_D=\
	".\quakedef.h"\
	".\net_dgrm.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\net_dgrm.obj" : $(SOURCE) $(DEP_CPP_NET_D) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\net_main.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_NET_M=\
	".\quakedef.h"\
	

"$(INTDIR)\net_main.obj" : $(SOURCE) $(DEP_CPP_NET_M) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_NET_M=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\net_main.obj" : $(SOURCE) $(DEP_CPP_NET_M) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\net_win.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_NET_W=\
	".\quakedef.h"\
	".\net_dgrm.h"\
	".\net_wins.h"\
	".\net_wipx.h"\
	

"$(INTDIR)\net_win.obj" : $(SOURCE) $(DEP_CPP_NET_W) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_NET_W=\
	".\quakedef.h"\
	".\net_dgrm.h"\
	".\net_wins.h"\
	".\net_wipx.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\net_win.obj" : $(SOURCE) $(DEP_CPP_NET_W) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\net_wins.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_NET_WI=\
	".\quakedef.h"\
	".\net_wins.h"\
	

"$(INTDIR)\net_wins.obj" : $(SOURCE) $(DEP_CPP_NET_WI) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_NET_WI=\
	".\quakedef.h"\
	".\net_wins.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\net_wins.obj" : $(SOURCE) $(DEP_CPP_NET_WI) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\net_wipx.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_NET_WIP=\
	".\quakedef.h"\
	".\net_wipx.h"\
	

"$(INTDIR)\net_wipx.obj" : $(SOURCE) $(DEP_CPP_NET_WIP) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_NET_WIP=\
	".\quakedef.h"\
	".\net_wipx.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\net_wipx.obj" : $(SOURCE) $(DEP_CPP_NET_WIP) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\pr_cmds.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_PR_CM=\
	".\quakedef.h"\
	

"$(INTDIR)\pr_cmds.obj" : $(SOURCE) $(DEP_CPP_PR_CM) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_PR_CM=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\pr_cmds.obj" : $(SOURCE) $(DEP_CPP_PR_CM) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\pr_edict.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_PR_ED=\
	".\quakedef.h"\
	

"$(INTDIR)\pr_edict.obj" : $(SOURCE) $(DEP_CPP_PR_ED) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_PR_ED=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\pr_edict.obj" : $(SOURCE) $(DEP_CPP_PR_ED) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\pr_exec.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_PR_EX=\
	".\quakedef.h"\
	

"$(INTDIR)\pr_exec.obj" : $(SOURCE) $(DEP_CPP_PR_EX) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_PR_EX=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\pr_exec.obj" : $(SOURCE) $(DEP_CPP_PR_EX) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\sv_main.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_SV_MA=\
	".\quakedef.h"\
	

"$(INTDIR)\sv_main.obj" : $(SOURCE) $(DEP_CPP_SV_MA) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_SV_MA=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\sv_main.obj" : $(SOURCE) $(DEP_CPP_SV_MA) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\sv_move.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_SV_MO=\
	".\quakedef.h"\
	

"$(INTDIR)\sv_move.obj" : $(SOURCE) $(DEP_CPP_SV_MO) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_SV_MO=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\sv_move.obj" : $(SOURCE) $(DEP_CPP_SV_MO) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\sv_phys.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_SV_PH=\
	".\quakedef.h"\
	

"$(INTDIR)\sv_phys.obj" : $(SOURCE) $(DEP_CPP_SV_PH) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_SV_PH=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\sv_phys.obj" : $(SOURCE) $(DEP_CPP_SV_PH) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\sv_user.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_SV_US=\
	".\quakedef.h"\
	

"$(INTDIR)\sv_user.obj" : $(SOURCE) $(DEP_CPP_SV_US) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_SV_US=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\sv_user.obj" : $(SOURCE) $(DEP_CPP_SV_US) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\world.c

!IF  "$(CFG)" == "lhnqserver - Win32 Release"

DEP_CPP_WORLD=\
	".\quakedef.h"\
	

"$(INTDIR)\world.obj" : $(SOURCE) $(DEP_CPP_WORLD) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "lhnqserver - Win32 Debug"

DEP_CPP_WORLD=\
	".\quakedef.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\world.obj" : $(SOURCE) $(DEP_CPP_WORLD) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\sys.c
DEP_CPP_SYS_C=\
	".\quakedef.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	".\common.h"\
	".\bspfile.h"\
	".\sys.h"\
	".\zone.h"\
	".\mathlib.h"\
	".\winquake.h"\
	".\cvar.h"\
	".\net.h"\
	".\protocol.h"\
	".\cmd.h"\
	".\client.h"\
	".\progs.h"\
	".\server.h"\
	".\model_shared.h"\
	".\world.h"\
	".\console.h"\
	".\crc.h"\
	".\pr_comp.h"\
	".\progdefs.h"\
	".\model_brush.h"\
	

"$(INTDIR)\sys.obj" : $(SOURCE) $(DEP_CPP_SYS_C) "$(INTDIR)"


# End Source File
# End Target
# End Project
################################################################################
