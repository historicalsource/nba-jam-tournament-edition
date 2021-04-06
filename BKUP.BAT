@echo Backing up DOC directory...
c:
cd \video\doc
i:
cd \video\doc
xcopy c:*.doc /m /v
@echo Backing up basketball...
c:
cd \video\bball
i:
cd \video\bball
xcopy c:*.asm /m /v
xcopy c:*.equ /m /v
xcopy c:*.hdr /m /v
xcopy c:makefile /m /v
xcopy c:make.ini /m /v
xcopy c:*.cmd /m /v
xcopy c:*.bat /m /v
c:
cd img
i:
cd img
xcopy c:*.lod /m /v
xcopy c:*.bdb /m /v
xcopy c:*.bdd /m /v
xcopy c:*.img /m /v
bb

