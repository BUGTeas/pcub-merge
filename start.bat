@echo off && goto begin
:launch
::	========================================
::	这是启动服务器的关键命令
	%JavaExec% -Djdk.util.jar.enableMultiRelease=force -Xms2G -Xmx2G -jar .\spigot-1.20.1.jar
::	参数 -Djdk.util.jar.enableMultiRelease=force 用于在未安装 Floodgate 插件的情况下使基岩版正常打开菜单书 
::	其他参数和常规服务端通用，如需自行修改或制作脚本，则只需要注意上述参数即可
::	========================================

	set PCUBErr=%errorLevel%
	echo.
	if %PCUBErr% equ 9009 (
		echo 系统找不到 Java ^(%JavaExec%^)。请检查其是否在环境变量中，或使用 JavaExec 变量指定 Java 程序路径。
	) else if %PCUBErr% gtr 0 (
		echo 服务器非正常退出。错误码为：%PCUBErr%
	) else (
		echo 服务器已经安全退出。
	)
	goto end
:begin
	chcp 65001
	if "%1" equ "" title 盘灵无界·互通服务端
	set PCUBLDA="%cd%"
	cd /d "%~dp0"

	if not exist "plugins\Geyser-Spigot\custom_mappings\pcub.json" (
		echo.
		echo 检测到您未安装盘灵无界基础必要组件，无法启动服务器！
		goto end
	)

	:: 遍历所有文件夹，生成或追加列表
	set PCUBErr=0
	if "%1" neq "nocheck" call :chkall
	if %PCUBErr% equ 1 goto err

	echo.
	echo 正在启动服务端...
	if "%JavaExec%" equ "" set JavaExec=java.exe

	goto launch
:chkall
	echo.
	echo 正在检测合并项...（可使用“nocheck”参数跳过）

	set PCUBAllAdded=0
	set PCUBDirAdded=2

	:: 检测目录
	if exist "*_merge" for /f "delims=" %%i in ('dir /b "*_merge"') do if exist "%%i\" (
		set PCUBDir=%%i
		call :chkdir
	)

	:: 对比修改参照文件
	if exist auto_merge_list.txt fc auto_merge_list.txt .auto_merge_list_check > nul 2> nul || if %PCUBAllAdded% equ 0 (
		echo 检测到合并列表变更。
		set PCUBAllAdded=1
	)

	:: 检测组件更新
	if %PCUBDirAdded% neq 2 if exist need_remerge (
		echo 检测到组件被更新。
		set PCUBAllAdded=1
	)

	if %PCUBAllAdded% equ 1 (
		echo.
		echo 正在执行自动合并...
		call auto_merge_all.bat nocheck
	) else (
		echo 暂不需要自动合并。
	)
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
:err
	echo 若想跳过自动合并检测直接启动服务端，可以使用“nocheck”参数。 
:end
	cd /d %PCUBLDA%
	if "%1" equ "" pause