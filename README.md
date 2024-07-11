# 盘灵无界自定义配置文件自动合并

## 简介

由于一些插件的配置文件不能像资源包/数据包一样叠加内容，需要通过合并配置文件的方式应用相关配置，通过 JSON 处理工具 `jq` 以及 YAML 处理工具 `yq` 可以快速地对文件进行合并操作。

为了方便用户操作，本互通方案在 `jq` 和 `yq` 的基础上设计了自动合并脚本，可以在原有 Geyser 自定义本地化文本及头颅信息以及菜单插件 CrossPlatForms 的配置文件的基础上叠加修改。

您只需要将配置文件**修改过的部分**单独保存，按照下方结构表存放到对应位置，然后执行脚本即可完成配置文件的修改合并：

```
PanGuContinentUnbounded-server (服务端根目录，名称不限)
	├─custom_merge (名称不限，但为了规范建议以“_merge”结尾)
	│  │  auto_merge.bat	(Windows 专用脚本)
	│  │  auto_merge.sh		(Linux/OSX Bash 通用脚本)
	│  │
	│  └─plugins (只有这些文件可以合并，不存在的文件会直接跳过)
	│      ├─CrossplatForms
	│      │      bedrock-forms.yml	(新增或覆盖基岩版 Forms 界面)
	│      │      config.yml		(增加一些自定义命令，支持 PAPI 和自定义权限)
	│      │
	│      └─Geyser-Spigot
	│          │  custom-skulls.yml	(增加需要在基岩版显示的自定义头颅信息)
	│          │
	│          └─locales
	│              └─overrides	(需要合并到 Geyser 自定义本地化的 Java 版语言文件)
	│                      zh_cn.json	(中文简体)
	│                      zh_tw.json	(中文台繁)
	│
	└─tools	(合并文件基础程序，服务端部署包已集成)
			jq					(Linux 版本 JSON 合并，x86 平台)
			jq-linux-arm64		(Linux 版本 JSON 合并，arm64 平台)
			jq-windows-i386.exe	(Windows 版本 JSON 合并，x86 平台)
			yq					(Linux 版本 YAML 合并，x86 平台)
			yq_linux_arm64		(Linux 版本 YAML 合并，arm64 平台)
			yq_windows_386.exe	(Windows 版本 YAML 合并，x86 平台)
```

## 文件修改教程

### .yml 类型

举例，这是某个配置文件的原状：
```yml
enabled: true
version: 3
debug: false
list:
  - 1
  - 2
  - 3
commands:
  name: mytest
  info: test2
```
如果我们需要将 `debug` 的值从 `false` 改成 `true`，并且在 `commands` 中将 `info` 的值从 `test2` 改成 `something`，然后新增加一个值为 `op` 的标签 `permission`，那么只需要根据结构表新建对应的合并文件并写入以下内容：
```yml
debug: true
commands:
  info: something
permission: op
```
经过脚本处理后，原配置文件就会变成这样：
```yml
enabled: true
version: 3
debug: true
list:
  - 1
  - 2
  - 3
commands:
  name: mytest
  info: something
permission: op
```
不过需要注意，对于数组列表类型，使用合并方法会覆盖掉原先的内容。比如合并文件中写有以下内容：
```yml
list:
  - 4
  - 5
```
那么经过处理后的原文件如下：
```yml
enabled: true
version: 3
debug: false
list:
  - 4
  - 5
commands:
  name: mytest
  info: test2
```
可见原先的 `1` `2` `3` 被新的 `4` `5` 覆盖掉了。

### 特别的个例文件

为了方便添加新的自定义头颅信息，本脚本对 `plugins/Geyser-Spigot/custom-skulls.yml` 做了特殊处理，此文件的数组列表更改不会被覆盖。比如原文件是这样：
```yml
player-usernames:
  - GeyserMC
player-uuids:
  - 8b8d8e8f-2759-47c6-acb5-5827de8a72b8
player-profiles:
  - eyJ0aW1lc3RhbXAiOjE0MTEyO...... (省略)
skin-hashes:
  - a90790c57e181ed13aded14c47ee2f7c8de3533e017ba957af7bdf9df1bde94f
```
在对应合并文件写入以下内容：
```yml
player-usernames:
  - yl_jiu_qiu
  - Creazeny
player-uuids:
  - fc809b93-5289-4dbf-80ae-b31d5726ce92
player-profiles:
  - eyJ0ZXh0dXJlcyI6eyJTS0lOI...... (省略)
skin-hashes:
  - 1234567890qwertyuiopasdfghjklzxcvbnm
```
那么经过处理后的原文件如下：
```yml
player-usernames:
  - GeyserMC
  - yl_jiu_qiu
  - Creazeny
player-uuids:
  - 8b8d8e8f-2759-47c6-acb5-5827de8a72b8
  - fc809b93-5289-4dbf-80ae-b31d5726ce92
player-profiles:
  - eyJ0aW1lc3RhbXAiOjE0MTEyO...... (省略)
  - eyJ0ZXh0dXJlcyI6eyJTS0lOI...... (省略)
skin-hashes:
  - a90790c57e181ed13aded14c47ee2f7c8de3533e017ba957af7bdf9df1bde94f
  - 1234567890qwertyuiopasdfghjklzxcvbnm
```

### .json 类型

举例，这是某个配置文件的原状：
```json
{
	"pl.npc.name.leading0":"§l神族引路人",
	"pl.npc.chat1a.leading0":"§7§o我们是继承了盘古意志的种族",
	"pl.npc.chat1b.leading0":"§7§o是世界的主宰和管理者",
	"pl.npc.chat2a.leading0":"§7§o我们与天地同寿",
	"pl.npc.chat2b.leading0":"§7§o快加入成为我们的一员吧！"
}
```
在合并文件中加入以下内容：
```json
{
	"pl.npc.name.leading0":"§l继承盘古意志的引路人",
	"dlc.adv.sins.start":"罪如歌",
	"dlc.adv.sins.start.lore":"§6一切的一切,开始于与旅行家的对话"
}
```
经过脚本处理后，原文件内容变化如下：
```json
{
	"pl.npc.name.leading0":"§l继承盘古意志的引路人",
	"pl.npc.chat1a.leading0":"§7§o我们是继承了盘古意志的种族",
	"pl.npc.chat1b.leading0":"§7§o是世界的主宰和管理者",
	"pl.npc.chat2a.leading0":"§7§o我们与天地同寿",
	"pl.npc.chat2b.leading0":"§7§o快加入成为我们的一员吧！",
	"dlc.adv.sins.start":"罪如歌",
	"dlc.adv.sins.start.lore":"§6一切的一切,开始于与旅行家的对话"
}
```
和 yml 一样，json 的数组修改也会直接覆盖原先的内容，不支持附加。