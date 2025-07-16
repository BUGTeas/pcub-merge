#!/bin/bash
function launch(){
#	========================================
#	这是启动服务端的关键命令
	$JavaExec -Xms1G -Xmx2G -Dfile.encoding=utf-8 -DGeyser.ShowResourcePackLengthWarning=false -jar ./leaves-1.20.1.jar nogui
#	========================================

	PCUBErr=$?
	echo
	if [ $PCUBErr = 127 ]; then
		echo "系统找不到 Java ($JavaExec)。请检查其是否在环境变量中，或使用 JavaExec 变量指定 Java 程序路径。(注意区分大小写)"
	elif [ $PCUBErr != 0 ]; then
		echo "服务端非正常关闭。错误码为：$PCUBErr"
	else
		echo "服务端已经安全关闭。"
	fi
	exit $PCUBErr
}

function envCheckErr {
	echo -e "\n检测到您$1，无法启动服务端"
	echo "若想跳过环境检测直接启动服务端，可以使用“noenvheck”参数。"
	exit 1
}

if [ "$1" = "cd" ]; then cd "$(cd "$(dirname "$0")";pwd)"

# 文件环境检测
if [ "$1" = "nocheck" ] ||
   [ "$1" = "noenvcheck" ] ||
   [ "$2" = "noenvcheck" ] ||
   [ "$3" = "noenvcheck" ]; then :
elif [ ! -f "world/data/Temple.dat" ]; then
	envCheckErr "未导入盘灵古域地图"
elif [ ! -e world/datapacks/panling* ]; then
	envCheckErr "未导入梦回盘灵数据包"
elif [ ! -f "plugins/Geyser-Spigot/custom_mappings/pcub.json" ]; then
	envCheckErr "未合并梦回盘灵专用 Java - 基岩双端互通套件"
fi

# 遍历所有文件夹，生成或追加列表
if [ "$1" = "nocheck" ] ||
   [ "$1" = "nomergecheck" ] ||
   [ "$2" = "nomergecheck" ] ||
   [ "$3" = "nomergecheck" ]; then :
else
	echo -e "\n正在检测合并项..."
	bash auto_merge_all.sh check || {
		echo "若想跳过自动合并检测直接启动服务端，可以使用“nomergecheck”参数。"
		exit 1
	}
fi

echo -e "\n正在启动服务端..."
[ "$JavaExec" = "" ] && JavaExec=java
launch