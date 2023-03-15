<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Backbone.js + Vue 3](#backbonejs--vue-3)
- [为什么会有本文？](#%E4%B8%BA%E4%BB%80%E4%B9%88%E4%BC%9A%E6%9C%89%E6%9C%AC%E6%96%87)
- [使用](#%E4%BD%BF%E7%94%A8)
- [VSCode 自动补全](#vscode-%E8%87%AA%E5%8A%A8%E8%A1%A5%E5%85%A8)
- [Chrome DevTools：打断点调试](#chrome-devtools%E6%89%93%E6%96%AD%E7%82%B9%E8%B0%83%E8%AF%95)
- [Chrome DevTools：Vue 插件](#chrome-devtoolsvue-%E6%8F%92%E4%BB%B6)
- [此 Demo 包括功能](#%E6%AD%A4-demo-%E5%8C%85%E6%8B%AC%E5%8A%9F%E8%83%BD)
- [遗留问题](#%E9%81%97%E7%95%99%E9%97%AE%E9%A2%98)
- [vue3-sfc-loader 的更多详情](#vue3-sfc-loader-%E7%9A%84%E6%9B%B4%E5%A4%9A%E8%AF%A6%E6%83%85)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Backbone.js、jQuery 老项目中整合 Vue 3 的一种姿势
主要基于 [vue3-sfc-loader](https://github.com/FranckFreiburger/vue3-sfc-loader) ，使得石器时代的 [Backbone,js](https://backbonejs.org/) + jQuery 老项目中可以相对无缝地用上 Vue 3.



# 为什么会有本文？
- 历史原因（人力、组织架构变化、用户量等），有些 Backbone.js 老项目依然在运行，并且有时可能还需往里面添加新功能
- Backbone 代码没有 Vue 那么容易维护，不想继续写 Backbone 风格的代码
- 如果保持原功能不变，新增的功能可以以 Vue 3 形式编写，以后移植到 Vue 框架项目，损耗更小一些

所以，这是不得不的一个折中方案，且不是最优方案。



# 使用
- 下载此项目： https://github.com/vikyd/backbonejs_vue3 
- 进入上述项目目录
- 启动一个简单的 HTTP Server：
  - py3: `python3 -m http.server 8686`
  - py2: `python -m SimpleHTTPServer 8686`
  - 或其他 HTTP Sever
- index.html
  - 打开： https://localhost:8686/index.html
  - 说明：依赖包引用 unpkg.com 的在线文件
- index-local.html
  - 先安装本地依赖：`npm install`
  - 打开： https://localhost:8686/index-local.html
  - 说明：依赖包引用本地的文件



# VSCode 自动补全
[VSCode](https://code.visualstudio.com/) 可对 backbone.js 老项目中的 Vue 3 的 `.vue` 文件内的代码进行自动补全。

- 使用 [Volar 插件](https://marketplace.visualstudio.com/items?itemName=Vue.volar)，不要使用 Vetur
- 项目目录需已安装 Vue 3



# Chrome DevTools：打断点调试
由于 `.vue` 文件是在浏览器中编译的，source map 貌似不生效，所以在 DevTools 的 Source 中搜索不到 `.vue` 文件，也就无法打断点。

但有折中办法：

- 添加一行打印到每个 vue 文件，例如 `console.log('vueFileName')` 
- 打开页面后，在 DevTools 的 Console 中找到对应的打印，点击右侧（形似 `VM1275:3`）可进入 `.vue` 文件中
- 此时，可以打断点调试了



# Chrome DevTools：Vue 插件

此时还可以使用 Chomre 的 [Vue 插件](https://chrome.google.com/webstore/detail/vuejs-devtools/nhdogjmejiglipccpnnnanhbledajbpd) 查看 Vue 组件的状态。

也存在一些不足：

- `.vue` 的组件名不会依据文件名自动命名，需手动在每个 vue 文件中手动添加类似 `export default` 进行设置组件名，参考 `hello-world.vue` 中的 `export default`。




# 此 Demo 包括功能

- Vue 3
  - setup 形式单文件 `.vue`
  -  import 其他 vue 子组件
  -  import 直接 js module
- 预处理器 [less](https://lesscss.org/)




# 遗留问题

- 难以方便 import 带有子依赖文件的 ES Module
  - 除非你能自行写好 `loadOptions` 中的的函数 `getFile`
  - 另一个办法是，若依赖包简单的话，尝试转换成本地文件
- 不支持 Typescript 
- 性能稍差，但也不是不可接受




# vue3-sfc-loader 的更多详情

[vue3-sfc-loader](https://github.com/FranckFreiburger/vue3-sfc-loader) 里面包含更多示例，详见：

- [示例列表](https://github.com/FranckFreiburger/vue3-sfc-loader/blob/main/docs/examples.md)
- [FAQ](https://github.com/FranckFreiburger/vue3-sfc-loader/blob/main/docs/faq.md)
- [API](https://github.com/FranckFreiburger/vue3-sfc-loader/blob/main/docs/api/README.md#loadmodule)



