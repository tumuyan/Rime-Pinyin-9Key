# Rime袖珍简化字拼音·九宫

融合了[【袖珍简化字拼音】](https://github.com/rime/rime-pinyin-simp/)[【Rime 简体中文用户定制文件】](https://github.com/huaxianyan/Rime)的简体中文九宫拼音方案。目前处于早期开发阶段。

### 特色：
1. 纯简体中文词库，无需opencc转换
2. 支持数字小键盘九宫输入，同时也兼容26键输入；普通数字键和空格键完成选择
4. 依赖lua脚本，可以在输入数字后，输入`-`对拼音进行筛选。筛选使用原有拼音词库文件进行反查，不依赖额外文件（尚未全部实现）
5. 依赖lua脚本，可以在输入数字后，使用笔画筛选（尚未开发）


### 安裝

1. 复制仓库全部文件到rime的用户目录
2. 编辑用户目录的rime.lua文件，增加如下内容
```yaml
local PY9= require("pinyin_simp_9key")
pinyin_9key_processor = PY9.pinyin_9key__processor
pinyin_9key_filter = PY9.pinyin_9key__filter
```

3. 在设置界面应用`袖珍简化字拼音·九宫`

### 授权
見 [LICENSE](LICENSE)
