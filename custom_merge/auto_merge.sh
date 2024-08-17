#!/bin/bash
echo -e "\n盘灵无界自定义配置文件自动合并"
# jq程序来自：https://github.com/jqlang/jq
# yq程序来自：https://github.com/mikefarah/yq

if [ $(uname -m) = aarch64 ]; then
	# 如果是ARM64平台，则调用ARM版本
	PCUBJQPATH="../tools/jq-linux-arm64"
	PCUBYQPATH="../tools/yq_linux_arm64"
else
	# 如果不是ARM64，则调用备用版本，服务端部署包中默认为i386版本（支持X86/64），如果是特殊平台请自行替换文件
	PCUBJQPATH="../tools/jq"
	PCUBYQPATH="../tools/yq"
fi

# 优先使用环境变量中的，只要版本正确
cd "$(cd "$(dirname "$0")";pwd)"

[[ "$(jq --version 2> ./tmp)" =~ "jq-1." ]] && PCUBJQPATH="jq"
[ "$PCUBJQPATH" = "jq" ] && echo -n "使用系统中安装" || echo -n "使用部署包自带"
echo -n "的 yq: "
$PCUBJQPATH --version || exit

[[ "$(yq --version 2> ./tmp)" =~ "yq (https://github.com/mikefarah/yq/) version v4" ]] && PCUBYQPATH="yq"
[ "$PCUBYQPATH" = "yq" ] && echo -n "使用系统中安装" || echo -n "使用部署包自带"
echo -n "的 yq: "
$PCUBYQPATH --version || exit

PCUBPATH=plugins/Geyser-Spigot/locales/overrides/zh_cn.json
if [ -f "$PCUBPATH" ]; then
	echo -n "正在合并：$PCUBPATH "
	$PCUBJQPATH -s ".[0] * .[1]" "../$PCUBPATH" "$PCUBPATH" -c > ./tmp && mv ./tmp ../$PCUBPATH || exit
	echo "完成"
fi

PCUBPATH=plugins/Geyser-Spigot/locales/overrides/zh_tw.json
if [ -f "$PCUBPATH" ]; then
	echo -n "正在合并：$PCUBPATH "
	$PCUBJQPATH -s ".[0] * .[1]" "../$PCUBPATH" "$PCUBPATH" -c > ./tmp && mv ./tmp ../$PCUBPATH || exit
	echo "完成"
fi

PCUBPATH=plugins/Geyser-Spigot/custom-skulls.yml
if [ -f "$PCUBPATH" ]; then
	echo -n "正在合并：$PCUBPATH "
	$PCUBYQPATH ".player-usernames += load(\"$PCUBPATH\").player-usernames" ../$PCUBPATH > ./tmp1 || exit
	$PCUBYQPATH ".player-uuids += load(\"$PCUBPATH\").player-uuids" tmp1 > ./tmp || exit
	$PCUBYQPATH ".player-profiles += load(\"$PCUBPATH\").player-profiles" tmp > ./tmp1 || exit
	$PCUBYQPATH ".skin-hashes += load(\"$PCUBPATH\").skin-hashes" tmp1 > ./tmp && mv ./tmp ../$PCUBPATH || exit
	rm tmp1
	echo "完成"
fi

PCUBPATH=plugins/CrossplatForms/config.yml
if [ -f "$PCUBPATH" ]; then
	echo -n "正在合并：$PCUBPATH "
	$PCUBYQPATH -n "load(\"../$PCUBPATH\")*load(\"$PCUBPATH\")" > ./tmp && mv ./tmp ../$PCUBPATH || exit
	echo "完成"
fi

PCUBPATH=plugins/CrossplatForms/bedrock-forms.yml
if [ -f "$PCUBPATH" ]; then
	echo -n "正在合并：$PCUBPATH "
	$PCUBYQPATH -n "load(\"../$PCUBPATH\")*load(\"$PCUBPATH\")" > ./tmp && mv ./tmp ../$PCUBPATH || exit
	echo "完成"
fi

echo "操作成功完成。"