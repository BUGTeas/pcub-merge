#!/bin/bash
function launch(){
#	========================================
#	这是启动服务器的关键命令
	$JavaExec -Xms1G -Xmx2G -Dfile.encoding=utf-8 -DGeyser.ShowResourcePackLengthWarning=false -jar ./leaves-1.20.1.jar nogui
#	========================================

	PCUBErr=$?
	echo
	if [ $PCUBErr = 127 ]; then
		echo "系统找不到 Java ($JavaExec)。请检查其是否在环境变量中，或使用 JavaExec 变量指定 Java 程序路径。(注意区分大小写)"
	elif [ $PCUBErr != 0 ]; then
		echo "服务器非正常退出。错误码为：$PCUBErr"
	else
		echo "服务器已经安全退出。"
	fi
	exit $PCUBErr
}

cd "$(cd "$(dirname "$0")";pwd)"

if [ ! -f "plugins/Geyser-Spigot/custom_mappings/pcub.json" ]; then
	echo -e "\n检测到您未安装梦回盘灵 Java - 基岩双端互通套件，无法启动服务器！"
	exit 1
fi

# 遍历所有文件夹，生成或追加列表
if [ "$1" != "nocheck" ]; then
	echo -e "\n正在检测合并项...（可使用“nocheck”参数跳过）"
	bash auto_merge_all.sh check || {
		echo "若想跳过自动合并检测直接启动服务端，可以使用“nocheck”参数。"
		exit 1
	}
fi

echo -e "\n正在启动服务端..."
[ "$JavaExec" = "" ] && JavaExec=java
launch