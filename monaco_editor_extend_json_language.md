<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [monaco editor 扩展 JSON 语法](#monaco-editor-%E6%89%A9%E5%B1%95-json-%E8%AF%AD%E6%B3%95)
- [目录](#%E7%9B%AE%E5%BD%95)
- [相关 js 库](#%E7%9B%B8%E5%85%B3-js-%E5%BA%93)
  - [列表](#%E5%88%97%E8%A1%A8)
  - [恰逢 monaco editor 相关 GitHub 仓库迁移](#%E6%81%B0%E9%80%A2-monaco-editor-%E7%9B%B8%E5%85%B3-github-%E4%BB%93%E5%BA%93%E8%BF%81%E7%A7%BB)
- [修改点](#%E4%BF%AE%E6%94%B9%E7%82%B9)
- [使用扩展后的 JSON 语言](#%E4%BD%BF%E7%94%A8%E6%89%A9%E5%B1%95%E5%90%8E%E7%9A%84-json-%E8%AF%AD%E8%A8%80)
- [踩过的坑](#%E8%B8%A9%E8%BF%87%E7%9A%84%E5%9D%91)
  - [Postman 中 monaco-editor 扩展新语言机制的摸索](#postman-%E4%B8%AD-monaco-editor-%E6%89%A9%E5%B1%95%E6%96%B0%E8%AF%AD%E8%A8%80%E6%9C%BA%E5%88%B6%E7%9A%84%E6%91%B8%E7%B4%A2)
  - [如何从 Postman js 代码适配到自定义语言？](#%E5%A6%82%E4%BD%95%E4%BB%8E-postman-js-%E4%BB%A3%E7%A0%81%E9%80%82%E9%85%8D%E5%88%B0%E8%87%AA%E5%AE%9A%E4%B9%89%E8%AF%AD%E8%A8%80)
  - [monaco-editor 的新语言如何创建、导入（含 web worker）？](#monaco-editor-%E7%9A%84%E6%96%B0%E8%AF%AD%E8%A8%80%E5%A6%82%E4%BD%95%E5%88%9B%E5%BB%BA%E5%AF%BC%E5%85%A5%E5%90%AB-web-worker)
- [遗留问题](#%E9%81%97%E7%95%99%E9%97%AE%E9%A2%98)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# monaco editor 扩展 JSON 语法
总体思路：基于 monaco 官方的 json 库 [monaco-json](https://github.com/microsoft/monaco-editor/tree/v0.30.1/monaco-json)，修改其中的部分源码，再作为新语言导入 monaco editor 。

涉及自定义功能点：高亮、格式化、语法错误检查。

> 本文不是详细教程，只是一种实践过的可行思路。



# 目录
[TOC]



# 相关 js 库
## 列表
- [monaco-json](https://github.com/microsoft/monaco-editor/tree/v0.30.1/monaco-json)
  - 用途：提供 JSON 语言的总入口
  - 包括：语法高亮、语法错误验证（波浪线错误提示）
  - 修改：下载、编译，得到 esm 形式的 js（也可先修改 ts 再编译出 js js），然后修改想扩展的代码
- [vscode-json-languageservice](https://github.com/microsoft/vscode-json-languageservice/tree/v4.1.10)
  - 用途：提供格式化等
  - 修改：下载、编译，得到 esm 形式的 js，然后修改想扩展的代码
  - monaco-json 会调用 vscode-json-languageservice，所以修改后合并为一个库
- [monaco-editor-webpack-plugin](https://github.com/microsoft/monaco-editor/tree/v0.30.1/monaco-editor-webpack-plugin)
  - 用途：webpack 引入 monaco-editor 的插件
  - 无需修改此库的源码，但需提供适当的参数配置，以引入新的语言
  - 需找到为 monaco-editor 添加完整新语言的机制
- Postman App
  - Postman 的接口请求 JSON Body 编辑器也是基于 monaco-editor
  - 用途：打开 Postman 的 DevTools，参考其对 monaco-editor JSON 的扩展方式
  - 但代码是混淆过的



## 恰逢 monaco editor 相关 GitHub 仓库迁移
以 2021-11-09 发布的 monaco-editor [v0.30.1](https://github.com/microsoft/monaco-editor/tree/v0.30.1) 为例：

- monaco-editor
  - 从：https://github.com/microsoft/monaco-json
  - 到：https://github.com/microsoft/monaco-editor/tree/v0.30.1/monaco-json
- Monaco Editor Webpack Loader Plugin
  - 从：https://github.com/microsoft/monaco-editor-webpack-plugin
  - 到：https://github.com/microsoft/monaco-editor/tree/v0.30.1/monaco-editor-webpack-plugin

> 相关目录可能还会继续变化



# 修改点
以下是本次修改涉及的功能点和文件：

- [monaco-json](https://github.com/microsoft/monaco-editor/tree/v0.30.1/monaco-json)
  - 编译
     - ts 编译为 esm js
  - 语言 ID：从 `json` 改为 `你的新语言 ID`
     - `monaco.contribution.js`
     - `workerManager.js`
  - Token 高亮扩展
     - `tokenization.js`
  - 语法检查扩展
     - `jsonWorker.js`
  - 依赖修改
     - `filters/monaco-editor-core.js`
        - 可不要此文件，改为指向 monaco-editor 本身即可
- [vscode-json-languageservice](https://github.com/microsoft/vscode-json-languageservice/tree/v4.1.10)
  - 编译
     - ts 编译为 esm js
  - 格式化：
     - `jsonLanguageService.js`
- 将上述 2 个库合并为 1 个库（目录平级），便于管理



> 也可修改 ts 文件，而非修改编译后的 js 文件



# 使用扩展后的 JSON 语言
- 若是 Vue CLI 的话，可在 `vue.config.js` 的 monaco-editor-webpack-plugin 的 [customLanguages](https://github.com/microsoft/monaco-editor/blob/v0.30.1/monaco-editor-webpack-plugin/src/index.ts#L81) 参数 [配置新语言](https://github.com/microsoft/monaco-editor/blob/v0.30.1/monaco-editor-webpack-plugin/src/languages.ts#L120-L127)
- monaco editor 创建实例时使用新语言的 id
- 可根据新语言增加的 Token 定义新高亮颜色的主题（且继承原 JSON 的高亮）
- vue.config.js 的示例配置：
```js
const path = require("path");
const MonacoWebpackPlugin = require("monaco-editor-webpack-plugin");

module.exports = {
  chainWebpack: (config) => {
    config.plugin("monaco-editor").use(MonacoWebpackPlugin, [
      {
	    // 此字段无关
        languages: ["json", "typescript", "javascript", "html", "xml"],
        // 若不加 hash，会报错（区别于前面 output.filename 配置）：
        // `Conflict: Multiple assets emit different content to the same filename json.worker.js`
        // 参考：https://github.com/microsoft/monaco-editor/tree/v0.30.1/monaco-editor-webpack-plugin#options
        filename: "[name].[hash].worker.js",
        customLanguages: [
          {
            label: "你的新语言 ID",
            entry: path.resolve(
              __dirname,
              // 使用相对路径，而不用 require("你的新语言库")
              // 是因为这些文件是 esm（es6 module），而非 nodejs 的
              "./node_modules/你的新语言库/monaco-json/out/esm/monaco.contribution"
            ),

            worker: {
              id: "你的新语言ID_jsonWorker",
              entry: path.resolve(
                __dirname,
                "./node_modules/你的新语言库/monaco-json/out/esm/json.worker"
              ),
            },
          },
        ],
      },
    ]);
  },
};
```


# 踩过的坑
## Postman 中 monaco-editor 扩展新语言机制的摸索
- 找出对应可能的 js 文件
  - `js/jsonMode.js`
  - `postman-json.worker.js`
     - 在 DevTools，Sources，左侧 Page 的 Web Worker `postman-json.worker.js` 
     - 点击格式化 `请求 Body` 后才会出现此 worker
- 找出对应的实现函数
- 格式化 js
- 反混淆 js
- Mac app.asar 文件内容的替换，以便使用格式化后的代码，更易断点
- 断点调试



## 如何从 Postman js 代码适配到自定义语言？
- 反混淆后的 js 依然需梳理代码逻辑
- Postman 基于 monaco-json 的较老版本，部分数据结构不一样，如从数组变为栈
- 有些变量依赖函数外的库或变量，需找出来替换
- 新语言的几个方面需要适配：高亮、格式化、语法错误检查



## monaco-editor 的新语言如何创建、导入（含 web worker）？
- 摸索 monaco-editor 引入完整新语言及 worker 的机制
  - 从 monaco-editor-webpack-plugin 源码中才知道有 [customLanguages](https://github.com/microsoft/monaco-editor/blob/v0.30.1/monaco-editor-webpack-plugin/src/index.ts#L81) 这个隐藏参数（官方 [README](https://github.com/microsoft/monaco-editor/tree/v0.30.1/monaco-editor-webpack-plugin#options) 没有这个参数）
- monaco-json、vscode-json-languageservice 编译出来是 esm 形式，如何在 `vue.config.js` 中使用？
  - 错误：`require("新语言库")`
  - 正确：在 monaco-editor-webpack-plugin 的参数中直接以相对路径引用，无需经过 require ，如 `              "./node_modules/新语言目录/monaco-json/out/esm/monaco.contribution"`
- 导入的文件 `json.worker.js` 编译时与原 json 语言的同名文件冲突，如何处理？
  - 在 monaco-editor-webpack-plugin 的参数设置 `filename: "[name].[hash].worker.js"` （而非 webpack 本身的 `output.filename`）



# 遗留问题
- monaco-json、vscode-json-languageservice 更新版本后，如何应用到刚创建的新语言？
- 应修改 ts 文件，而非编译后的 js 文件


