@echo off && goto begin
:launch
::	========================================
::	这是启动服务器的关键命令
	%JavaExec% -Xms1G -Xmx2G -Dfile.encoding=utf-8 -DGeyser.ShowResourcePackLengthWarning=false -jar .\leaves-1.20.1.jar nogui
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
	if "%1" equ "" title 梦回盘灵互通服务端
	set PCUBLDA="%cd%"
	cd /d "%~dp0"

	if not exist "plugins\Geyser-Spigot\custom_mappings\pcub.json" (
		echo.
		echo 检测到您未安装梦回盘灵 Java - 基岩双端互通套件，无法启动服务器！
		goto end
	)

	:: 遍历所有文件夹，生成或追加列表
	set PCUBErr=1
	if "%1" neq "nocheck" (
		echo.
		echo 正在检测合并项...（可使用“nocheck”参数跳过）
		call auto_merge_all.bat check
	)
	if %PCUBErr% equ 1 goto err

	echo.
	echo 正在启动服务端...
	if "%JavaExec%" equ "" set JavaExec=java.exe

	goto launch
:err
	echo 若想跳过自动合并检测直接启动服务端，可以使用“nocheck”参数。 
:end
	cd /d %PCUBLDA%
	if "%1" equ "" pause