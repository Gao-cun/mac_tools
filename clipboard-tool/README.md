# 剪切板翻译助手

macOS 剪切板监控工具，复制文本后自动添加翻译 prompt 前缀和专业词汇后缀，方便粘贴到网页版 AI 进行翻译。

## 快速开始

```bash
python3 clipboard_tool.py
```

启动后自动打开浏览器前端页面，编辑前后缀配置即可使用。

## 工作原理

1. 监控系统剪切板，检测文本变化
2. 按配置在原文前后添加前缀和后缀
3. 转换后的文本写回剪切板
4. 直接粘贴到 AI 聊天框即可

## 配置文件

`~/.clipboard-translator-config.json`:

```json
{
    "prefix": "请将以下英文翻译成中文：\n\n",
    "suffix": "",
    "enabled": true,
    "port": 9876
}
```

## 使用场景

- **英文翻译**：prefix 设为翻译 prompt，suffix 可加上专业词汇表要求
- **代码解释**：prefix 设为 "请解释以下代码："
- **文本润色**：prefix 设为 "请润色以下文本使其更流畅："
