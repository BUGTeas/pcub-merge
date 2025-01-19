@echo off
set PCUBErr=0
if "%1" neq "check" call :begin %1
if %PCUBErr% equ 1 goto :eof

:: 遍历所有文件夹，生成或追加列表

if "%1" neq "check" (
	echo.
	echo 正在查找是否有新的合并项...
)
set PCUBAllAdded=0
set PCUBDirAdded=2

:: 检测目录
if exist "*_merge" for /f "delims=" %%i in ('dir /b "*_merge"') do if exist "%%i\" (
	set PCUBDir=%%i
	call :chkdir
)

if "%1" neq "check" goto work

:: 对比修改参照文件
if %PCUBAllAdded% equ 0 if exist auto_merge_list.txt fc auto_merge_list.txt .auto_merge_list_check > nul 2> nul || (
	echo 检测到合并列表变更。
	set PCUBAllAdded=1
)

:: 检测套件更新
if %PCUBDirAdded% neq 2 if exist need_remerge (
	echo 检测到被更新的套件。
	set PCUBAllAdded=1
)

if %PCUBAllAdded% neq 1 (
	echo 暂不需要自动合并。
	goto :eof
)

echo.
call :loadExec %1
if %PCUBErr% equ 1 goto :eof

:work
	:: 遍历列表按顺序合并
	set /p="" < nul > .auto_merge_list_temp
	if exist auto_merge_list.txt for /f "delims=" %%i in (auto_merge_list.txt) do if exist "%%i\" (
		echo.>>.auto_merge_list_temp
		set /p="%%i" < nul >> .auto_merge_list_temp
		set PCUBIndex=%%i
		call :workMerge
	) else if %PCUBErr% neq 1 (
		echo.
		echo 找不到合并项 "%%i"，它将被从列表上移除。这并不影响其他合并项的处理。
	)
	if %PCUBErr% equ 1 goto allerr

	:: 保存删减
	move .auto_merge_list_temp auto_merge_list.txt > nul
	:: 生成修改参照文件
	if exist .auto_merge_list_check attrib -h .auto_merge_list_check
	type auto_merge_list.txt > .auto_merge_list_check
	attrib +h .auto_merge_list_check
	:: 套件更新标识
	if exist need_remerge del need_remerge

	echo.
	echo 操作成功完成。

	if "%1" equ "check" goto :eof
	goto end
:begin
	chcp 65001
	set PCUBLD="%cd%"
	cd /d "%~dp0"

	title 配置文件一键自动合并
	echo.
:loadExec
	:: jq程序来自：https://github.com/jqlang/jq
	:: yq程序来自：https://github.com/mikefarah/yq

	:: 服务端部署包中默认为i386版本（支持X86/64），如果是特殊平台请自行替换文件
	set PCUBJQPATH=.\tools\jq-windows-i386.exe
	set PCUBYQPATH=.\tools\yq_windows_386.exe

	echo | set /p=使用部署包自带的 jq: 
	%PCUBJQPATH% --version || goto allerr

	echo | set /p=使用部署包自带的 yq: 
	%PCUBYQPATH% --version || goto allerr

	goto :eof
:chkdir
	:: 新增合并项
	set PCUBDirAdded=0
	if exist auto_merge_list.txt for /f "delims=" %%j in (auto_merge_list.txt) do if "%PCUBDir%" equ "%%j" set PCUBDirAdded=1
	if %PCUBDirAdded% equ 0 (
		set PCUBAllAdded=1
		echo 发现新的合并项: "%PCUBDir%"
		echo.>>auto_merge_list.txt
		set /p="%PCUBDir%" < nul >> auto_merge_list.txt
	)

	goto :eof
:workMerge
	if %PCUBErr% equ 1 goto :eof
	echo.
	echo 正在自动合并 "%PCUBIndex%" 中的配置文件...

	:: GeyserMC 语言文件
	set PCUBPATH=plugins\Geyser-Spigot\locales\overrides\zh_
	for %%f in (cn.json tw.json) do if exist "%PCUBIndex%\%PCUBPATH%%%f" (
		echo | set /p=%PCUBPATH%%%f: 
		%PCUBJQPATH% -s ".[0] * .[1]" "%PCUBPATH%%%f" "%PCUBIndex%\%PCUBPATH%%%f" -c > .\tmp && move .\tmp %PCUBPATH%%%f > nul || goto err
		echo 完成
	)

	:: GeyserMC 自定义头颅
	set PCUBPATH=plugins\Geyser-Spigot\custom-skulls.yml
	if exist "%PCUBIndex%\%PCUBPATH%" (
		echo | set /p=%PCUBPATH%: 
		%PCUBYQPATH% ".player-usernames += load(\"%PCUBIndex%\%PCUBPATH%\").player-usernames" %PCUBPATH% > .\tmp1 || goto err
		%PCUBYQPATH% ".player-uuids += load(\"%PCUBIndex%\%PCUBPATH%\").player-uuids" .\tmp1 > .\tmp || goto err
		%PCUBYQPATH% ".player-profiles += load(\"%PCUBIndex%\%PCUBPATH%\").player-profiles" .\tmp > .\tmp1 || goto err
		%PCUBYQPATH% ".skin-hashes += load(\"%PCUBIndex%\%PCUBPATH%\").skin-hashes" .\tmp1 > .\tmp && move .\tmp %PCUBPATH% > nul || goto err
		del .\tmp1
		echo 完成
	)
	
	:: CrossplatForms 菜单
	set PCUBPATH=plugins\CrossplatForms\
	for %%f in (config.yml bedrock-forms.yml) do if exist "%PCUBIndex%\%PCUBPATH%%%f" (
		echo | set /p=%PCUBPATH%%%f: 
		%PCUBYQPATH% -n "load(\"%PCUBPATH%%%f\")*load(\"%PCUBIndex%\%PCUBPATH%%%f\")" > .\tmp && move .\tmp %PCUBPATH%%%f > nul || goto err
		echo 完成
	)

	:: 附加脚本
	if exist "%PCUBIndex%\attach-windows.bat" (
		cd %PCUBIndex%
		cmd /c attach-windows.bat || goto err
		cd ..
	)

	goto :eof
:err
	set PCUBErr=1
	goto :eof
:allerr
	set PCUBErr=1
	echo.
	echo 程序执行出错。 
	if "%1" equ "check" goto :eof
:end
	cd /d %PCUBLD%
	if "%1" equ "" pause