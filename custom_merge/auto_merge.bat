@echo off
chcp 65001

:: 确保工作目录为脚本所在目录
set PCUBLD="%cd%"
cd /d "%~dp0"

title 盘灵无界配置文件自动合并
echo.
echo 正在自动合并 "%~dp0" 中的配置文件...

:: jq程序来自：https://github.com/jqlang/jq
:: yq程序来自：https://github.com/mikefarah/yq

:: 服务端部署包中默认为i386版本（支持X86/64），如果是特殊平台请自行替换文件
set PCUBJQPATH=..\tools\jq-windows-i386.exe
set PCUBYQPATH=..\tools\yq_windows_386.exe

echo | set /p d=使用部署包自带的 jq: 
%PCUBJQPATH% --version || goto end

echo | set /p d=使用部署包自带的 yq: 
%PCUBYQPATH% --version || goto end

:: GeyserMC 语言文件
set PCUBPATH=plugins\Geyser-Spigot\locales\overrides\zh_
for %%f in (cn.json tw.json) do if exist %PCUBPATH%%%f (
	echo | set /p d=%PCUBPATH%%%f: 
	%PCUBJQPATH% -s ".[0] * .[1]" "..\%PCUBPATH%%%f" "%PCUBPATH%%%f" -c > .\tmp && move .\tmp ..\%PCUBPATH%%%f > nul || goto end
	echo 完成
)

:: GeyserMC 自定义头颅
set PCUBPATH=plugins\Geyser-Spigot\custom-skulls.yml
if exist %PCUBPATH% (
	echo | set /p d=%PCUBPATH%: 
	%PCUBYQPATH% ".player-usernames += load(\"%PCUBPATH%\").player-usernames" ..\%PCUBPATH% > .\tmp1 || goto end
	%PCUBYQPATH% ".player-uuids += load(\"%PCUBPATH%\").player-uuids" tmp1 > .\tmp || goto end
	%PCUBYQPATH% ".player-profiles += load(\"%PCUBPATH%\").player-profiles" tmp > .\tmp1 || goto end
	%PCUBYQPATH% ".skin-hashes += load(\"%PCUBPATH%\").skin-hashes" tmp1 > .\tmp && move .\tmp ..\%PCUBPATH% > nul || goto end
	del tmp1
	echo 完成
)

:: CrossplatForms 菜单
set PCUBPATH=plugins\CrossplatForms\
for %%f in (config.yml bedrock-forms.yml) do if exist %PCUBPATH% (
	echo | set /p d=%PCUBPATH%%%f: 
	%PCUBYQPATH% -n "load(\"..\%PCUBPATH%%%f\")*load(\"%PCUBPATH%%%f\")" > .\tmp && move .\tmp ..\%PCUBPATH%%%f > nul || goto end
	echo 完成
)

echo 操作成功完成。

:end
cd /d %PCUBLD%
if "%1" equ "" pause