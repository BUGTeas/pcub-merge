@echo off && goto begin
:launch
::	========================================
::	这是启动服务端的关键命令
	%JavaExec% -Xms1G -Xmx2G -Dfile.encoding=utf-8 -DGeyser.ShowResourcePackLengthWarning=false -jar .\leaves-1.20.1.jar nogui
::	========================================

	set PCUBErr=%errorLevel%
	echo.
	if %PCUBErr% equ 9009 (
		echo 系统找不到 Java ^(%JavaExec%^)。请检查其是否在环境变量中，或使用 JavaExec 变量指定 Java 程序路径。
	) else if %PCUBErr% gtr 0 (
		echo 服务端非正常关闭。错误码为：%PCUBErr%
	) else (
		echo 服务端已经安全关闭。
	)
	goto end
:begin
	chcp 65001
	if "%1" equ "" title 盘灵古域互通（梦回盘灵）专用服务端
	set PCUBLDA="%cd%"
	cd /d "%~dp0"

	:: 文件环境检测
	if "%1" equ "nocheck" ( rem 0
	) else if "%1" equ "noenvcheck" ( rem 0
	) else if "%2" equ "noenvcheck" ( rem 0
	) else if not exist "world\data\Temple.dat" (
		set PCUBEnvErr=未导入盘灵古域地图
		goto envCheckErr
	) else if not exist "world\datapacks\panling*" (
		set PCUBEnvErr=未导入梦回盘灵数据包
		goto envCheckErr
	) else if not exist "plugins\Geyser-Spigot\custom_mappings\pcub.json" (
		set PCUBEnvErr=未合并梦回盘灵专用 Java - 基岩双端互通套件
		goto envCheckErr
	)

	:: 遍历所有文件夹，生成或追加列表
	set PCUBErr=0
	if "%1" equ "nocheck" ( rem 0
	) else if "%1" equ "nomergecheck" ( rem 0
	) else if "%2" equ "nomergecheck" ( rem 0
	) else (
		set PCUBErr=1
		echo.
		echo 正在检测合并项...
		call auto_merge_all.bat check
	)
	if %PCUBErr% equ 1 goto mergeErr

	echo.
	echo 正在启动服务端...
	if "%JavaExec%" equ "" set JavaExec=java.exe

	goto launch
:envCheckErr
	echo.
	echo 检测到您%PCUBEnvErr%，无法启动服务端
	echo 若想跳过环境检测直接启动服务端，可以使用“noenvheck”参数。
	goto end
:mergeErr
	echo 若想跳过自动合并检测直接启动服务端，可以使用“nomergecheck”参数。 
:end
	cd /d %PCUBLDA%
	if "%1" equ "" pause