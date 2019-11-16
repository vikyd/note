# What is Software Engineering?
原文：https://research.swtch.com/vgo-eng

作者：[Russ Cox](https://swtch.com/~rsc/)

翻译时间：2019-11-16

# 什么是软件工程？
（[Go 与版本](https://research.swtch.com/vgo)，第 9 部分）

发表时间：2018-03-30 周三 [PDF](https://research.swtch.com/vgo-eng.pdf)


# 正文
我们经常说，Go 语言几乎所有与众不同的设计都是为了使软件工程变得更简单、更容易。关于这点的权威参考可见 Rob Pike 在 2012 年发表的文章：[Google 中的 Go 语言：软件工程服务中的语言设计（Go at Google: Language Design in the Service of Software Engineering）](https://talks.golang.org/2012/splash.article)。但问题是，软件工程到底是什么？

软件工程是指当你增加更多时间、开发者时，编程中所需做的事情。

编程表示让程序可以运行。当你有一个问题需要解决时，你可以写一些 Go 语言代码，运行，得到结果，问题得到解决。这就是编程，编程本身不是容易的事。但如果代码必须持续运行，该怎么办？如果需要 5 个开发者协作写一份代码怎么办？这时你可以考虑以下办法：

- 使用版本控制系统（version control systems）（译注：如 Git）来跟踪代码随时间的变化情况，以及协调开发者之间的工作
- 添加单元测试来保证曾经修复过的 bug 不会再产生，保证即使是 6 个月后或不熟悉该代码的新人也不会重新引入该 bug
- 利用模块化、设计模式来将程序划分为多个部分，这样团队成员可以互不干扰地开发
- 使用一些工具来简化找 bug 的过程
- 找一些其他办法让开发者更清晰地编程，从而少犯一些错误，减少 bug
- 保证在大型项目中即使是微细的修改也能被快速测试

你之所以做这些，是因为你的编程正转变为软件工程问题。

（上述对软件工程的定义是我对 Google 同事 Titus Winters 的观点的理解，他喜欢的定义是： “软件工程是随着时间变化而整合的编程”。这是他在 CppCon 2017 上的其中 7 分钟（08:17 - 15:00）的 [演讲](https://www.youtube.com/watch?v=tISy7EJQPzI&t=8m17s)。）

正如我前面所说的，Go 语言的大部分独特的设计决策都是因为对软件工程的考虑，让时间与开发者在日常开发中融合的更好。

举例来说，可能大部分人会认为我们推出 `gofmt` 工具的目的是为了让代码更美观，并终止团队间的格式之战。但实际上，`gofmt` 的 [最重要动机](https://groups.google.com/forum/#!msg/golang-nuts/HC2sDhrZW5Y/7iuKxdbLExkJ) 在于：若有一个算法能规范好 Go 语言的源代码的格式化问题的话，那其他的程序如 `goimports`、`gorename`、`go fix` 等就可以更容易分析、修改代码，并在回写代码时不会引入奇奇怪怪的格式问题。随着时间推移，你的代码依然可以易于维护。

还有另一个例子，Go 的 `import` 路径与 URL 很相似。若一份代码使用了 `import "uuid"`，这时你可能会疑惑这个 `uuid` 到底对应哪个库，因为在 [godoc.org](https://godoc.org/) 搜索 `uuid` 可得到一大堆结果。若使用 `import "github.com/pborman/uuid"`，那就很清晰你用的是哪个包了。使用 URL 的形式可以避免歧义，还可利用现有的命名机制，使开发者之间的协作更方便。

继续上面这个例子，Go 的 `import` 路径是是直接写在 Go 的源码中的，而不是一个独立的配置文件中。这样做的好处是 Go 的源码自包含了对引用的描述，理解、修改、复制这些源码都会变得更简单。这些决策设计，都是源于对简化软件工程的追求。

在后面的文章中，我将会专门讲讲为什么版本对于软件工程至关重要，以及软件工程是如何影响了 Go 将版本管理工具从 `dep` 切换到了 `vgo`。


