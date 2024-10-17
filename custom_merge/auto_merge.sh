#!/bin/bash

# 确保工作目录为脚本所在目录
cd "$(cd "$(dirname "$0")";pwd)"

echo -e "\n正在自动合并 \"$(basename $PWD)\" 中的配置文件..."

# jq程序来自：https://github.com/jqlang/jq
# yq程序来自：https://github.com/mikefarah/yq

if [ $(uname -m) = aarch64 ]; then
	# 如果是ARM64平台，则调用ARM版本
	PCUBJQPATH="../tools/jq-linux-arm64"
	PCUBYQPATH="../tools/yq_linux_arm64"
else
	# 如果不是ARM64，则调用备用版本，服务端部署包中默认为AMD64版本，如果是特殊平台请自行替换文件
	PCUBJQPATH="../tools/jq"
	PCUBYQPATH="../tools/yq"
fi

# 优先使用环境变量中的，只要版本正确
# 否则使用部署包中自带的

[[ "$(jq --version 2> ./tmp)" =~ "jq-1." ]] && PCUBJQPATH="jq"
[ "$PCUBJQPATH" = "jq" ] && echo -n "使用系统中安装" || echo -n "使用部署包自带"
echo -n "的 yq: "
$PCUBJQPATH --version || exit

[[ "$(yq --version 2> ./tmp)" =~ "yq (https://github.com/mikefarah/yq/) version v4" ]] && PCUBYQPATH="yq"
[ "$PCUBYQPATH" = "yq" ] && echo -n "使用系统中安装" || echo -n "使用部署包自带"
echo -n "的 yq: "
$PCUBYQPATH --version || exit

# GeyserMC 自定义头颅
PCUBPATH=plugins/Geyser-Spigot/locales/overrides/zh_
for f in cn.json tw.json; do if [ -f "$PCUBPATH$f" ]; then
	echo -n "$PCUBPATH$f: "
	$PCUBJQPATH -s ".[0] * .[1]" "../$PCUBPATH$f" "$PCUBPATH$f" -c > ./tmp && mv ./tmp ../$PCUBPATH$f || exit
	echo "完成"
fi; done

# GeyserMC 自定义头颅
PCUBPATH=plugins/Geyser-Spigot/custom-skulls.yml
if [ -f "$PCUBPATH" ]; then
	echo -n "$PCUBPATH: "
	$PCUBYQPATH ".player-usernames += load(\"$PCUBPATH\").player-usernames" ../$PCUBPATH > ./tmp1 || exit
	$PCUBYQPATH ".player-uuids += load(\"$PCUBPATH\").player-uuids" tmp1 > ./tmp || exit
	$PCUBYQPATH ".player-profiles += load(\"$PCUBPATH\").player-profiles" tmp > ./tmp1 || exit
	$PCUBYQPATH ".skin-hashes += load(\"$PCUBPATH\").skin-hashes" tmp1 > ./tmp && mv ./tmp ../$PCUBPATH || exit
	rm tmp1
	echo "完成"
fi

# CrossplatForms 菜单
PCUBPATH=plugins/CrossplatForms/
for f in config.yml bedrock-forms.yml; do if [ -f "$PCUBPATH$f" ]; then
	echo -n "$PCUBPATH$f: "
	$PCUBYQPATH -n "load(\"../$PCUBPATH$f\")*load(\"$PCUBPATH$f\")" > ./tmp && mv ./tmp ../$PCUBPATH$f || exit
	echo "完成"
fi; done

echo "操作成功完成。"