#!/bin/bash
function launch(){
#	========================================
#	这是启动服务器的关键命令
	$JavaExec -Djdk.util.jar.enableMultiRelease=force -Xms2G -Xmx2G -jar ./spigot-1.20.1.jar
#	参数 -Djdk.util.jar.enableMultiRelease=force 用于在未安装 Floodgate 插件的情况下使基岩版正常打开菜单书 
#	其他参数和常规服务端通用，如需自行修改或制作脚本，则只需要注意上述参数即可
#	========================================

	PCUBErr=$?
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
	echo -e "\n检测到您未安装盘灵无界基础必要组件，无法启动服务器！"
	exit
fi


# 遍历所有文件夹，生成或追加列表
if [ "$1" != "nocheck" ]; then
	echo -e "\n正在检测合并项...（可使用“nocheck”参数跳过）"
	
	PCUBAllAdded=0
	PCUBDirAdded=2
	[ -f auto_merge_list.txt ] && currentList=$(cat auto_merge_list.txt) || currentList=
	LastIFS="$IFS"
	IFS=$'\r\n'

	# 检测目录
	for PCUBDir in $(ls *_merge -d 2> /dev/null); do if [ -d $PCUBDir ]; then
		# 新增合并项
		PCUBDirAdded=0
		for j in $currentList; do 
			if [ $PCUBDir = $j ]; then
				PCUBDirAdded=1 && break
			fi
		done
		if [ $PCUBDirAdded = 0 ]; then
			PCUBAllAdded=1
			echo "发现新的合并项: \"$PCUBDir\""
			echo -n -e "\r\n$PCUBDir" >> auto_merge_list.txt
		fi
	fi; done

	# 对比修改参照文件
	[ -f .auto_merge_list_check ] && compareList=$(cat .auto_merge_list_check) || compareList=
	if [ "$currentList" != "$compareList" ]; then
		echo "检测到合并列表变更。"
		PCUBAllAdded=1
	fi

	# 检测组件更新
	if [[ $PCUBDirAdded != 2 && -f need_remerge ]]; then
		echo "检测到组件被更新。"
		PCUBAllAdded=1
	fi
	

	if [ $PCUBAllAdded = 1 ]; then
		echo -e "\n正在执行自动合并..."
		bash auto_merge_all.sh nocheck || {
			echo "若想跳过自动合并检测直接启动服务端，可以使用“nocheck”参数。"
			exit 1
		}
	else
		echo "暂不需要自动合并。"
	fi
	IFS="$LastIFS"
fi

echo -e "\n正在启动服务端..."
[ "$JavaExec" = "" ] && JavaExec=java
launch