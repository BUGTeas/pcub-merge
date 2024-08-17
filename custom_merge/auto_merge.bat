@echo off
chcp 65001
title 盘灵无界自定义配置文件自动合并
echo.
echo 盘灵无界自定义配置文件自动合并
set PCUBLD="%cd%"
:: jq程序来自：https://github.com/jqlang/jq
:: yq程序来自：https://github.com/mikefarah/yq

:: 服务端部署包中默认为i386版本（支持X86/64），如果是特殊平台请自行替换文件
set PCUBJQPATH=..\tools\jq-windows-i386.exe
set PCUBYQPATH=..\tools\yq_windows_386.exe

echo | set /p d=使用部署包自带的 jq: 
%PCUBJQPATH% --version || goto end

echo | set /p d=使用部署包自带的 yq: 
%PCUBYQPATH% --version || goto end

cd /d "%~dp0"

set PCUBPATH=plugins\Geyser-Spigot\locales\overrides\zh_cn.json
if exist %PCUBPATH% (
	echo | set /p d=正在合并：%PCUBPATH% 
	%PCUBJQPATH% -s ".[0] * .[1]" "..\%PCUBPATH%" "%PCUBPATH%" -c > .\tmp && move .\tmp ..\%PCUBPATH% > nul || goto end
	echo 完成
)

set PCUBPATH=plugins\Geyser-Spigot\locales\overrides\zh_tw.json
if exist %PCUBPATH% (
	echo | set /p d=正在合并：%PCUBPATH% 
	%PCUBJQPATH% -s ".[0] * .[1]" "..\%PCUBPATH%" "%PCUBPATH%" -c > .\tmp && move .\tmp ..\%PCUBPATH% > nul || goto end
	echo 完成
)

set PCUBPATH=plugins\Geyser-Spigot\custom-skulls.yml
if exist %PCUBPATH% (
	echo | set /p d=正在合并：%PCUBPATH% 
	%PCUBYQPATH% ".player-usernames += load(\"%PCUBPATH%\").player-usernames" ..\%PCUBPATH% > .\tmp1 || goto end
	%PCUBYQPATH% ".player-uuids += load(\"%PCUBPATH%\").player-uuids" tmp1 > .\tmp || goto end
	%PCUBYQPATH% ".player-profiles += load(\"%PCUBPATH%\").player-profiles" tmp > .\tmp1 || goto end
	%PCUBYQPATH% ".skin-hashes += load(\"%PCUBPATH%\").skin-hashes" tmp1 > .\tmp && move .\tmp ..\%PCUBPATH% > nul || goto end
	del tmp1
	echo 完成
)

set PCUBPATH=plugins\CrossplatForms\config.yml
if exist %PCUBPATH% (
	echo | set /p d=正在合并：%PCUBPATH% 
	%PCUBYQPATH% -n "load(\"..\%PCUBPATH%\")*load(\"%PCUBPATH%\")" > .\tmp && move .\tmp ..\%PCUBPATH% > nul || goto end
	echo 完成
)

set PCUBPATH=plugins\CrossplatForms\bedrock-forms.yml
if exist %PCUBPATH% (
	echo | set /p d=正在合并：%PCUBPATH% 
	%PCUBYQPATH% -n "load(\"..\%PCUBPATH%\")*load(\"%PCUBPATH%\")" > .\tmp && move .\tmp ..\%PCUBPATH% > nul || goto end
	echo 完成
)

echo 操作成功完成。

:end
cd /d %PCUBLD%
if "%1" equ "" pause