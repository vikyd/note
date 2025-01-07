<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [已经习惯用 UnoCSS 了](#%E5%B7%B2%E7%BB%8F%E4%B9%A0%E6%83%AF%E7%94%A8-unocss-%E4%BA%86)
- [原因](#%E5%8E%9F%E5%9B%A0)
- [优点](#%E4%BC%98%E7%82%B9)
- [缺点](#%E7%BC%BA%E7%82%B9)
- [为什么不使用 Tailwind CSS ？](#%E4%B8%BA%E4%BB%80%E4%B9%88%E4%B8%8D%E4%BD%BF%E7%94%A8-tailwind-css-)
- [其他担心](#%E5%85%B6%E4%BB%96%E6%8B%85%E5%BF%83)
- [小结](#%E5%B0%8F%E7%BB%93)
- [推荐看看](#%E6%8E%A8%E8%8D%90%E7%9C%8B%E7%9C%8B)
- [部分示例](#%E9%83%A8%E5%88%86%E7%A4%BA%E4%BE%8B)
  - [1. 使用 CSS 变量](#1-%E4%BD%BF%E7%94%A8-css-%E5%8F%98%E9%87%8F)
  - [2. `@apply` 与复用](#2-apply-%E4%B8%8E%E5%A4%8D%E7%94%A8)
  - [3. `@apply` + CSS 变量 + `variant-group`](#3-apply--css-%E5%8F%98%E9%87%8F--variant-group)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 已经习惯用 UnoCSS 了
2023-06 开始使用所谓 `原子 CSS` 库 [UnoCSS](https://unocss.dev/)，一年了，若不让用 UnoCSS，会觉得很不方便，因为有些优点回不去了。



# 原因
一句话：收益大于付出，让代码更易于维护。



# 优点

- 比新建 class 省事（最最重要）
  - 节省心智：无需额外去想一个新的 class 名称
  - 关注点集中：html 中就能一眼看到样式，无需跳到 style 标签或独立的样式文件看，删除元素同时删除了样式，无需担心忘删 style 对应的代码
- 比 style 简洁，如：
  - style：`display: flex; flex-direction: column; padding-left: 10px; padding-right: 10px;`
  - 原子 class：只需 `flex flex-col px-10px`（[缩写查询](https://tailwindcss.com/docs/installation)）
- 无兼容性问题
  - 依然可使用原 CSS 方式，可平滑使用
- 编辑器插件支持
  - [VSCode](https://unocss.dev/integrations/vscode)、[WebStorm](https://unocss.dev/integrations/jetbrains) 等都有 UnoCSS 插件，可自动补全、合规显示（虚线）
- 生态健全、持续维护
  - Github start [15.6k](https://github.com/unocss/unocss)
  - 依然持续更新 ing
- 等等



# 缺点
- 上手门槛还是有一点的
  - 刚上手需要经常查文档，才知道是什么缩写
  - 但常用的熟悉后已不是问题
- UnoCSS 官方文档只有英文版




# 为什么不使用 Tailwind CSS ？
推荐看下 UnoCSS 作者 [antfu](https://github.com/antfu) 的中文文章：[重新构想原子化CSS](https://zhuanlan.zhihu.com/p/425814828) 。

- UnoCSS 基本兼容 Tailwind CSS，速度、大小都能接受（查缩写，基本都在 [Tailwind CSS 官网](https://tailwindcss.com/docs/padding) Command+F 搜索）
- UnoCSS [官方说](https://unocss.dev/guide/why#tailwind-css)比 Tailwind CSS 更好、更快



# 其他担心
- 性能？
  - 暂未遇到性能问题
- 原子 class 名会与现有的 class 冲突？
  - 极少遇到
- 原子 class 太长？
  - 大部分情况不长，少数较长，能接受
- 不能使用自定义样式值？如 `font-size: 17px`
  - 可以的，如 `text-[17px]` 或 `text-17px`
- 不能复用样式组合？
  - [@apply](https://unocss.dev/transformers/directives) 了解下
- 不能使用 CSS 变量？
  - [variant group](https://unocss.dev/transformers/variant-group) 了解下
- 等等，大都有对应策略



# 小结
- 建议现在就开始使用 UnoCSS，步骤不难
- 坚持尽量不写自定义 class、坚持一个月以上，才会有更好的体会（很像当年学 Vim 的曲线）
- 关于原子 CSS，网上很多人说还不如原来的 style、css 好，但这一年来的实践告诉我，值得



# 推荐看看
- [重新构想原子化CSS](https://zhuanlan.zhihu.com/p/425814828)
- [聊聊纯 CSS 图标](https://zhuanlan.zhihu.com/p/430423521)


-------


# 部分示例
列举一些可能担心不支持的功能，实际都支持。



## 1. 使用 CSS 变量

```html
<span class="color-[var(--td-text-color-placeholder)]"> 变量示例 </span>
```



## 2. `@apply` 与复用
需插件： https://unocss.dev/transformers/directives


以 Vue 为例，相当于将多个 UnoCSS 的 class 放到 style 标签，用一个新的 class 组织起来，然后在 template 就可以使用 @apply 的新 class。

```html
<template>
  <div>
    <span class="my-class">复用示例</span>
    <span class="my-class">复用示例</span>
  </div>
</template>
<style lang="less" scoped>
.my-class {
  --at-apply: 'm-10 text-20px';
}
</style>
```



## 3. `@apply` + CSS 变量 + `variant-group`
需插件：

- https://unocss.dev/transformers/variant-group
- https://unocss.dev/transformers/directives

```html
<template>
  <span class="uno-border">综合示例</span>
</template>
<style lang="less" scoped>
.uno-border {
  --at-apply: 'b-(1px solid [var(--td-component-border)])';
}
</style>
```





