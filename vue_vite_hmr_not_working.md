<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Vite、Vue 热更新失效的一次解决过程：被依赖包覆盖了全局变量 `__VUE_HMR_RUNTIME__`](#vitevue-%E7%83%AD%E6%9B%B4%E6%96%B0%E5%A4%B1%E6%95%88%E7%9A%84%E4%B8%80%E6%AC%A1%E8%A7%A3%E5%86%B3%E8%BF%87%E7%A8%8B%E8%A2%AB%E4%BE%9D%E8%B5%96%E5%8C%85%E8%A6%86%E7%9B%96%E4%BA%86%E5%85%A8%E5%B1%80%E5%8F%98%E9%87%8F-__vue_hmr_runtime__)
- [起因](#%E8%B5%B7%E5%9B%A0)
- [原因](#%E5%8E%9F%E5%9B%A0)
- [解决](#%E8%A7%A3%E5%86%B3)
- [验证](#%E9%AA%8C%E8%AF%81)
- [其他的可能原因](#%E5%85%B6%E4%BB%96%E7%9A%84%E5%8F%AF%E8%83%BD%E5%8E%9F%E5%9B%A0)
- [这一天的经历](#%E8%BF%99%E4%B8%80%E5%A4%A9%E7%9A%84%E7%BB%8F%E5%8E%86)
- [事后（细节，不重要）](#%E4%BA%8B%E5%90%8E%E7%BB%86%E8%8A%82%E4%B8%8D%E9%87%8D%E8%A6%81)
- [小结](#%E5%B0%8F%E7%BB%93)
- [辅助](#%E8%BE%85%E5%8A%A9)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Vite、Vue 热更新失效的一次解决过程：被依赖包覆盖了全局变量 `__VUE_HMR_RUNTIME__`


# 起因
有个项目（Vue3 + Vite）的 HMR（模块热替换 或 热更新）经常失效，大部分页面不生效，少部分页面生效，很影响效率。

时间关系一直没去定位具体原因，现耗时一天（太漫长了）终于解决，备忘记录。



# 原因
使用了基于 umd 打包的库 [monaco-editor-vue3 的 0.1.10 版本](https://www.npmjs.com/package/monaco-editor-vue3/v/0.1.10)，其中代码覆盖了全局变量 `__VUE_HMR_RUNTIME__`（`window.__VUE_HMR_RUNTIME__`），导致打开与此依赖包相关的页面时，热更新失效。



# 解决
不再使用 monaco-editor-vue3，暂改为本地新建一个组件 `MonacoEditor.vue`：https://gist.github.com/vikyd/06b52c5c63ee93b57738ef2e74179148 ，即可。



# 验证
根据 [此 Vue issue](https://github.com/vuejs/core/issues/9523#issue-1971065318) 实验了一下，在 Chrome Network 中，对其中的文件 `node_modules/.vite/deps/monaco-editor-vue3.js` 的 `__VUE_HMR_RUNTIME__` 相关几行 [注释掉](https://developer.chrome.com/docs/devtools/overrides?hl=zh-cn)，刷新页面，热更新恢复正常。




# 其他的可能原因
根据 Vite 规范文档：https://cn.vite.dev/guide/troubleshooting.html#hmr ，可能还会有其他因素导致 HMR 失效：

- 循环依赖，通过 [dpdm](https://github.com/acrazing/dpdm) 查看循环依赖文件
- import 文件大小写不对应？build 时自动能发现，所以没有大小写问题



# 这一天的经历
1. 情况：有两个项目，一个热更新一直有问题，另一个一直没问题，但依赖项都差不多。
1. 先想到，把 Vue、Vite 及相关插件均升级到相同版本，无果。
1. 搜索到 Vite 官网 [相关网页](https://cn.vite.dev/guide/troubleshooting.html#hmr)，是否有 import 文件大小写问题，无，因为故意修改为大小写不匹配时，build 和 lint 能立即发现。
1. 是否有循环依赖，有，解决之，刚开始用 [madge](https://github.com/pahen/madge) 因 typescript 版本不适合报错，改用 [dpdm](https://github.com/acrazing/dpdm)，可用，发现十几个循环依赖，甚至还有跨越六七个文件的循环依赖，解决之。无果，HMR 依然失效。
1. 根据 [vite3+vue3 HMR热更新无效 页面无法局部自动更新（需手动刷新页面）的问题解决](https://blog.csdn.net/m0_49280365/article/details/140347908)，更新 Vite、Vue 相关的全部依赖包到最新版，无果。奇怪的事同样 Vite、Vue 依赖包版本的另一个项目则没问题。
1. 最后，想到终极神器：排除法。
1. 尝试禁用 Vue Route 大部分路由定义，逐步放开看是是不是全部路由都有 HMR 问题，一步步，最终定位到一个与 monaco editor 相关的路由。
1. monaco-editor-vue3 的源码不算复杂，尝试将 monaco-editor-vue3 改为本地组件，不是有对应依赖库，发现问题消失！
1. 到此问题算是解决，好奇的继续往下探索一下 ↓
1. 为什么依赖库 monaco-editor-vue3 会导致 HMR 失败？
1. 看了下 monaco-editor-vue3 仓库的 [issue](https://github.com/bazingaedward/monaco-editor-vue3/issues/32)，发现 HMR 关键字，于是根据 Vite HMR UMD 关键字搜索，发现 [issue: Importing umd module breaks HMR](https://github.com/vitejs/vite/issues/14807)，在里面发现 [`issue: Imported Vue 3 module overwrites global __VUE_HMR_RUNTIME__ which breaks HMR`](https://github.com/vuejs/core/issues/9523)
1. 建立极简示例项目尝试将依赖库 monaco-editor-vue3 中的与 `__VUE_HMR_RUNTIME__` 相关的代码注释掉，但不生效，原因未明。
1. 最后在 Chrome Network 对相关 js 资源右键进行 Override，确认问题确：`__VUE_HMR_RUNTIME__` 变量没被覆盖后 HMR 恢复正常。



# 事后（细节，不重要）
过了几天，再想，为什么依赖库 monaco-editor-vue3 会出现 `__VUE_HMR_RUNTIME__` 变量？

实验继续：

- clone https://github.com/bazingaedward/monaco-editor-vue3 最新源码（[当前最新 commit](https://github.com/bazingaedward/monaco-editor-vue3/tree/0d2b6ca726ba2d500ad4925e855af1349cacb35f)）
- 安装依赖包失败，改用腾讯云源继续，build 失败，package.json 里的 `vite build && pnpm type` 改为 `vite build`，build 通过，得 `dist/monaco-editor-vue3.umd.js`，明显与从 npm 下载的不一致：更大、没压缩、也没 `__VUE_HMR_RUNTIME__`。
- 修改 vite.config.js，在 `external` 数组增加 `'monaco-editor/esm/vs/editor/editor.api'`（因 `src/MonacoEditor.vue` import），build 完毕，依然不一致：没压缩、也没 `__VUE_HMR_RUNTIME__`。
- 修改 vite.config.js，在 `external` 数组删除 `'vue'`，将 `minify: false` 改为 `minify: true`，build 完毕，发现：与 npm 的基本一致了，`__VUE_HMR_RUNTIME__` 也出现了。
- 所以 01：依赖库 monaco-editor-vue3 的 Github main 最新源码（2024-12-30）build 得不到 npm 对应的内容。
- 所以 02：正是因为 build 包含了 Vue 源码，所以包含了 [`__VUE_HMR_RUNTIME__`](https://github.com/vuejs/core/blob/5a6e98ca323ff0e50450580412694961dce5e312/packages/runtime-core/src/hmr.ts#L34) 的覆盖。

实验再继续（js 之间出现循环依赖的情况）：

a.js:
```js
import { v2 } from './b.js'

export const v1 = 111

export const f1 = () => {
    console.log(v2)
}
```

b.js:
```js
import { v1 } from './a.js'

export const v2 = 222

export const f2 = () => {
    console.log(v1)
}
```

再将 f2 引入到某 .vue 组件执行，发现 HMR 依然正常，所以貌似 js 的循环依赖不会导致 HMR 问题。



# 小结
- 若 Vite 官方应将 `__VUE_HMR_RUNTIME__` 变量覆盖的情况写入到官方文档该多好。
- 回想再来一次，同样的未知条件，能更快解决问题吗？好像也不会，但早点用路由排除法，估计能快些。



# 辅助
```sh
# 查找有可更新版本的依赖包
pnpm outdated
```


