#!/bin/bash

# 更改for循环分割符
IFS=$'\r\n'

function PCUBAMWork(){
	echo -e "\n正在自动合并 \"$PCUBIndex\" 中的配置文件..."

	# GeyserMC 语言文件
	PCUBPATH=plugins/Geyser-Spigot/locales/overrides/zh_
	for f in cn.json tw.json; do if [ -f "$PCUBIndex/$PCUBPATH$f" ]; then
		echo -n "$PCUBPATH$f: "
		$PCUBJQPATH -s ".[0] * .[1]" "$PCUBPATH$f" "$PCUBIndex/$PCUBPATH$f" -c > ./tmp && mv ./tmp $PCUBPATH$f || PCUBErr
		echo "完成"
	fi; done

	# GeyserMC 自定义头颅
	PCUBPATH=plugins/Geyser-Spigot/custom-skulls.yml
	if [ -f "$PCUBIndex/$PCUBPATH" ]; then
		echo -n "$PCUBPATH: "
		$PCUBYQPATH ".player-usernames += load(\"$PCUBIndex/$PCUBPATH\").player-usernames" $PCUBPATH > ./tmp1 || PCUBErr
		$PCUBYQPATH ".player-uuids += load(\"$PCUBIndex/$PCUBPATH\").player-uuids" ./tmp1 > ./tmp || PCUBErr
		$PCUBYQPATH ".player-profiles += load(\"$PCUBIndex/$PCUBPATH\").player-profiles" ./tmp > ./tmp1 || PCUBErr
		$PCUBYQPATH ".skin-hashes += load(\"$PCUBIndex/$PCUBPATH\").skin-hashes" ./tmp1 > ./tmp && mv ./tmp $PCUBPATH || PCUBErr
		rm ./tmp1
		echo "完成"
	fi

	# CrossplatForms 菜单
	PCUBPATH=plugins/CrossplatForms/
	for f in config.yml bedrock-forms.yml; do if [ -f "$PCUBIndex/$PCUBPATH$f" ]; then
		echo -n "$PCUBPATH$f: "
		$PCUBYQPATH -n "load(\"$PCUBPATH$f\")*load(\"$PCUBIndex/$PCUBPATH$f\")" > ./tmp && mv ./tmp $PCUBPATH$f || PCUBErr
		echo "完成"
	fi; done
	
	# 附加可执行文件
	if [ -f "$PCUBIndex/attach-unix-exec" ]; then
		cd "$PCUBIndex"
		chmod +x attach-unix-exec
		./attach-unix-exec || PCUBErr
		cd ..
	fi
}

function PCUBLoadExec(){
	# jq程序来自：https://github.com/jqlang/jq
	# yq程序来自：https://github.com/mikefarah/yq

	if [ $(uname -m) = aarch64 ]; then
		# 如果是ARM64平台，则调用ARM版本
		PCUBJQPATH="./tools/jq-linux-arm64"
		PCUBYQPATH="./tools/yq_linux_arm64"
	else
		# 如果不是ARM64，则调用备用版本，服务端部署包中默认为AMD64版本，如果是特殊平台请自行替换文件
		PCUBJQPATH="./tools/jq"
		PCUBYQPATH="./tools/yq"
	fi

	# 优先使用环境变量中的，只要版本正确
	# 否则使用部署包中自带的

	[[ "$(jq --version 2> /dev/null)" =~ "jq-1." ]] && PCUBJQPATH="jq" || chmod +x ./tools/jq*
	[ "$PCUBJQPATH" = "jq" ] && echo -n "使用系统中安装" || echo -n "使用部署包自带"
	echo -n "的 jq: "
	$PCUBJQPATH --version || PCUBErr

	[[ "$(yq --version 2> /dev/null)" =~ "yq (https://github.com/mikefarah/yq/) version v4" ]] && PCUBYQPATH="yq" || chmod +x ./tools/yq*
	[ "$PCUBYQPATH" = "yq" ] && echo -n "使用系统中安装" || echo -n "使用部署包自带"
	echo -n "的 yq: "
	$PCUBYQPATH --version || PCUBErr
}

function PCUBErr(){
	echo -e "\n程序执行出错。"
	exit 1
}

if [ "$1" != "check" ]; then
	cd "$(cd "$(dirname "$0")";pwd)"
	echo
	PCUBLoadExec
fi

# 遍历所有文件夹，生成或追加列表

[ "$1" != "check" ] && echo -e "\n正在查找是否有新的合并项..."
PCUBAllAdded=0
PCUBDirAdded=2

# 检测目录
[ -f auto_merge_list.txt ] && currentList=$(cat auto_merge_list.txt) || currentList=
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

if [ "$1" = "check" ]; then
	# 对比修改参照文件
	[ -f .auto_merge_list_check ] && compareList=$(cat .auto_merge_list_check) || compareList=
	if [ "$currentList" != "$compareList" ]; then
		echo "检测到合并列表变更。"
		PCUBAllAdded=1
	fi

	# 检测套件更新
	if [[ $PCUBDirAdded != 2 && -f need_remerge ]]; then
		echo "检测到被更新的套件。"
		PCUBAllAdded=1
	fi

	if [ $PCUBAllAdded != 1 ]; then
		echo "暂不需要自动合并。"
		exit
	fi

	echo
	PCUBLoadExec
fi

# 遍历列表按顺序合并
echo -n > .auto_merge_list_temp
[ -f auto_merge_list.txt ] && for PCUBIndex in $(cat auto_merge_list.txt); do if [ -d "$PCUBIndex" ]; then
	echo -n -e "\r\n$PCUBIndex" >> .auto_merge_list_temp
	PCUBAMWork
else
	echo -e "\n找不到合并项 \"$PCUBIndex\"，它将被从列表上移除。这并不影响其他合并项的处理。"
fi; done

# 保存删减
mv .auto_merge_list_temp auto_merge_list.txt
# 生成修改参照文件
cat auto_merge_list.txt > .auto_merge_list_check
# 组件更新标识
[ -f need_remerge ] && rm need_remerge

echo -e "\n操作成功完成。"