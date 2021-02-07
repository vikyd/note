# Maven 在代理环境下的使用方式

假设前提：

- 你所处网络需设置代理才能访问外网（如公司内网）
  - 假设代理为：http://yourProxyServer:port
- 你所在局域网有人搭建了 Maven 中央库镜像（如某些公司内）
  - 假设镜像地址为：http://yourMavenMirror.com

# 目录

<!-- START doctoc -->
<!-- END doctoc -->

# 使用方式 TL;DR

局域网使用 Maven 获取第三方 Java 依赖包，大致有以下方式（n 选 1）：

1.  设置 Maven 代理，再访问 Maven [中央仓库](http://repo1.maven.org/maven2)
2.  配置 仓库镜像，访问镜像仓库 http://yourMavenMirror.com
3.  混合：`设置代理` + `nonProxyHosts 不代理镜像仓库`

# 省事的使用方式

- 直接用 [settings.xml](https://github.com/vikyd/note-bigfile/blob/master/attachment/settings.xml) 替换你当前机器的配置（注意替换：镜像库、代理地址、用户名密码）
  > 注意：若你的 `settings.xml` 本身有其他额外设置，请注意备份
- 然后用附件的 [maven-test-project.zip](https://github.com/vikyd/note-bigfile/raw/master/attachment/maven-test-project.zip) 简单实例 Maven 项目来验证是否真能下载 Maven 依赖
  > 验证方式：在 `pom.xml` 所在目录运行命令 `mvn clean package`

# 方法 1：使用 repo1.maven.org/maven2 （中央仓库 + 代理）

因为 Maven 默认到 [中央仓库](http://repo1.maven.org/maven2) 下载 jar 包（[查找](http://mvnrepository.com/)），故只需设置代理，在 `maven安装目录/conf/settings.xml` 文件中填入：

```xml
  <proxies>
    <proxy>
      <id>yourProxyName</id>
      <active>true</active>
      <protocol>http</protocol>
      <username></username>
      <password></password>
      <host>yourProxyServer</host>
      <port>yourPorxyPort</port>
      <nonProxyHosts></nonProxyHosts>
    </proxy>
  </proxies>
```

优点：

- 中央仓库的包，都可使用
- 非中央仓库的包（如 https://repository.jboss.org/nexus/content/repositories/ ）也可在 `pom.xml` 中直接使用

缺点：

- 下载中央仓库的包略慢

注意：

- 此时不需要配置 mirror 到 http://yourMavenMirror:port

# 方法 2：使用镜像 yourMavenMirror.com（推荐！）

要点：

- mirror：即镜像外网 Maven 中央仓库
- `repositories`、`snapshots` 为 true 表示：允许找 SNAPSHOTS 中的 jar 包

在 `maven安装目录/conf/settings.xml` 文件中填入：

```xml
<mirrors>
  <mirror>
    <id>central_releases</id>
       <mirrorOf>central</mirrorOf>
       <name>internal repository</name>
       <url>http://yourMavenMirror.com/nexus/content/groups/public/</url>
    </mirror>
</mirrors>

<profiles>
    <profile>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <repositories>
            <repository>
              <id>central_releases</id>
              <name>internal repository</name>
              <url>http://yourMavenMirror.com/nexus/content/groups/public/</url>
              <releases>
                <enabled>true</enabled>
              </releases>
              <snapshots>
                <enabled>true</enabled>
              </snapshots>
            </repository>
        </repositories>
    </profile>
</profiles>
```

优点：

- 局域网速度快！！！
- 理论上，中央仓库的包，都可使用，但具体看实际使用

缺点：

- 若需使用部分非中央仓库的包，有两种处理方式：
- 局域网 http://yourMavenMirror.com 上有其他非中央仓库的镜像，则添加此镜像
- 局域网 http://yourMavenMirror.com 上没有镜像（如 https://repository.jboss.org/nexus/content/repositories ），则仍需使用代理，此时代理 `<proxies>` 中应设置仅不代理 yourMavenMirror.com：`<nonProxyHosts>yourMavenMirror.com</nonProxyHosts>`

注意：

- 此时可同时使用 yourMavenMirror.com 和 代理
- `central` 是 Maven 官方中央仓库的 ID

# 上传自己的包

若需发布自己编写的包到一个 Maven 仓库供他人使用，又不想发布到外网的中央仓库，你可发布到你所在局域网的第三方仓库： http://yourMavenMirror.com/nexus/content/repositories/thirdparty （区别于 http://yourMavenMirror.com/nexus/content/groups/public ）。

步骤：

1.  在 `maven安装目录/conf/settings.xml` 文件中填写仓库用户名和密码：

    ```xml
    <servers>
       <server>
           <id>your_thirdparty_releases</id>
           <username>yourName</username>
           <password>yourPassword</password>
       </server>
       <server>
           <id>your_thirdparty_snapshots</id>
           <username>yourName</username>
           <password>yourPassword</password>
       </server>
    </servers>
    ```

2.  在项目的 `pom.xml` 文件中填写需要上传的仓库（id 随便填，但需与 `settings.xml` 的一致）：

    ```xml
    <distributionManagement>
      <repository>
        <id>your_thirdparty_releases</id>
        <name>your repository for releases</name>
        <url>http://yourMavenMirror.com/nexus/content/repositories/thirdparty</url>
      </repository>
      <snapshotRepository>
        <id>your_thirdparty_snapshots</id>
        <name>your repository for snapshots</name>
        <url>http://yourMavenMirror.com/nexus/content/repositories/thirdparty-snapshots</url>
      </snapshotRepository>
    </distributionManagement>
    ```

3.  上传到 Release 或 Snapshots 仓库：

- 在项目的 `pom.xml`文件中：
- `<version>1.0</version>` ：则会上传到 Release 仓库
- `<version>1.0-SNAPSHOT</version>` ：则会上传到 Snapshots 仓库
- 上传命令：`mvn deploy`
- 注意：
  - Release：如 `1.0`，发布后通常不会再删除或更新，若更新，则直接递增版本号
  - Snapshots：如 `1.0-20170406.010459-1`、`1.0-20170406.062029-2`，通常自动生成，以 Release 版本号开头，以时间结尾，一个版本可有 n 个 Snapshots。
  - Release vs Snapshots：http://stackoverflow.com/a/14217041

4.  删除已发布的包：

- 在 (http://yourMavenMirror.com/nexus/#view-repositories 登录，上面选中对应的仓库，下面右键删除自己上传的包（目前貌似只有 SNAPSHOTS 仓库的可删除）。
  - 用户名：yourName
  - 密码：yourPassword

# 常见问题

### IntelliJ IDEA 中 settings.xml 不生效

若你使用 IntelliJ IDEA，原因可能是 `settings.xml` 文件不在对应的目录，分几种情况：

- IDEA 默认使用的是其自带的 Maven
  - 其默认的 `settings.xml` 文件路径是 `C:\Users\yourName\.m2\settings.xml`
  - 此文件默认不存在，可以手动新建填写
    > 注意：此时无需修改 IDEA 的 Maven 任何相关设置
- 若你想在 IDEA 中使用 Maven 官方的独立安装包：
  - 先修改 IDEA 中的 Maven 主目录：`File` -> `Settings` -> `Build, Execution, Deployment` -> `Build Tools` -> `Maven` -> 右侧 `Maven home directory` 填 你独立下载的 Maven 的根目录如 `C:/Program Files/apache-maven-3.3.9`
  - 修改的配置文件应是： `C:/Program Files/apache-maven-3.3.9/conf/settings.xml`

### 部分 jar 从 yourMavenMirror.com 下载，部分从外网下载

可能原因：

- 情况 01：

  - yourMavenMirror.com 设置了安全策略，存在安全 bug 的 jar 不允许下载
  - 解决：只采用代理，不使用局域网镜像（安全问题请自行负责）

- 情况 02：
  - 检查你项目的 pom.xml，看看是否有独立设置某些 jar 是只存在于某些第三方仓库（如 jboss 相关 jar）
  - 参考：https://maven.apache.org/guides/mini/guide-multiple-repositories.html

# 参考

- Maven 中央仓库：https://repo1.maven.org/maven2
- Maven 中央包搜索 01：https://mvnrepository.com
- Maven 中央包搜索 02：https://search.maven.org
- 外网第三方仓库举例：https://repository.jboss.org/nexus/content/repositories

# 文件

- [settings.xml](https://github.com/vikyd/note-bigfile/blob/master/attachment/settings.xml)
- [maven-test-project.zip](https://github.com/vikyd/note-bigfile/raw/master/attachment/maven-test-project.zip)
