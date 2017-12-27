# 目的
这里只说一个点：在 PhpStorm 中进行 PHP 断点调试时，Xdebug 与 PhpStorm、PHP 之间的大致协作方式。



# 名称解释
- 后面 `PhpStorm` 也可理解为其他 `IDE`


# 主要流程
![Image of Yaktocat](https://github.com/Viky-zhang/note/blob/master/img/xdebug_php_phpstorm.png)



# 准备工作（可跳过直接看后面）
- 安装：PHP、PhpStorm、Xdebug、Wireshark
- 打开 2 个 PhpStorm 项目：项目A、项目B
- 用 PHP 内置 Server 在 A、B 中分别以不同端口启动 Web 服务，如：
  - Win：
    - A：`php -S 127.0.0.1:6666`
    - B：`php -S 127.0.0.2:7777`
  - Mac：
    - A：`php -S localhost:6666`
    - B：`php -S localhost:7777`
- 在 A、B 中分别新建 PHP Web Application 调试项
- Wireshark 准备监控 Xdebug 相关包
  - Wireshark 中选择本地回环网卡（我这里是 Npcap 开头的）
  - Mac 中可能是 `Lookback: lo0`
  - 过滤框填：`tcp.port == 9000`
- A、B 分别启动调试（会自动打开浏览器）



# 调试过程的细节可跳过直接看后面结论



# Xdebug 简单调试过程描述（无断点）
```php
<?php

$a = 1235;
echo $a;

$b = 456;
echo $b;

```

- 假设有上述 8 行代码，不打任何断点，仅用 WireShark 看看 Xdebug 与 PhpStorm 之间发送了什么通信
- 以下开始：

- 开始：TCP 3 次握手建立连接

- 请求 Xdebug -- XML --> PhpStorm：
  - ```xml
    512
    <?xml version="1.0" encoding="iso-8859-1"?>
    <init xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" fileuri="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" language="PHP" xdebug:language_version="5.6.19" protocol_version="1.0" appid="4002" idekey="18923">
        <engine version="2.4.0"><![CDATA[Xdebug]]></engine>
        <author><![CDATA[Derick Rethans]]></author>
        <url><![CDATA[http://xdebug.org]]></url>
        <copyright><![CDATA[Copyright (c) 2002-2016 by Derick Rethans]]></copyright>
    </init>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `feature_set -i 1 -n show_hidden -v 1`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    218
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_set" transaction_id="1" feature="show_hidden" success="1"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `feature_set -i 2 -n max_depth -v 1`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    216
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_set" transaction_id="2" feature="max_depth" success="1"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `feature_set -i 3 -n max_children -v 100`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    219
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_set" transaction_id="3" feature="max_children" success="1"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `feature_set -i 4 -n extended_properties -v 1`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    295
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_set" transaction_id="4" status="starting" reason="ok"><error code="3"><message><![CDATA[invalid or missing options]]></message></error></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `status -i 5`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    209
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="status" transaction_id="5" status="starting" reason="ok"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `step_into -i 6`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    322
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="step_into" transaction_id="6" status="break" reason="ok">
        <xdebug:message filename="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" lineno="3"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `stack_get -i 7`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    314
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="stack_get" transaction_id="7">
        <stack where="{main}" level="0" type="file" filename="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" lineno="3"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `run -i 8`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    206
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="run" transaction_id="8" status="stopping" reason="ok"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `run -i 9`
- 响应 无

- 结束：TCP 4 次分手，结束连接





# Xdebug 简单调试过程描述（含断点）
```php
<?php

$a = 1235;
echo $a;  // 此处打 1 断点

$b = 456;
echo $b;

```

调试过程：
- 同样的代码，在第 4 行打个断点
- 运行到第 6 行（按 1 次 F8），恢复运行（按 1 次 F9）




- 假设有上述 8 行代码，不打任何断点，仅用 WireShark 看看 Xdebug 与 PhpStorm 之间发送了什么通信
- 以下开始：

- 开始：TCP 3 次握手建立连接

- 请求 Xdebug -- XML --> PhpStorm：
  - ```xml
    512
    <?xml version="1.0" encoding="iso-8859-1"?>
    <init xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" fileuri="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" language="PHP" xdebug:language_version="5.6.19" protocol_version="1.0" appid="4002" idekey="18923">
        <engine version="2.4.0"><![CDATA[Xdebug]]></engine>
        <author><![CDATA[Derick Rethans]]></author>
        <url><![CDATA[http://xdebug.org]]></url>
        <copyright><![CDATA[Copyright (c) 2002-2016 by Derick Rethans]]></copyright>
    </init>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `feature_set -i 1 -n show_hidden -v 1`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    77218
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_set" transaction_id="1" feature="show_hidden" success="1"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `feature_set -i 2 -n max_depth -v 1`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_set" transaction_id="2" feature="max_depth" success="1"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `feature_set -i 3 -n max_children -v 100`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_set" transaction_id="3" feature="max_children" success="1"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `feature_set -i 4 -n extended_properties -v 1`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="feature_set" transaction_id="4" status="starting" reason="ok">
        <error code="3">
            <message><![CDATA[invalid or missing options]]></message>
        </error>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `status -i 5`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    209
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="status" transaction_id="5" status="starting" reason="ok"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `step_into -i 6`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    322
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="step_into" transaction_id="6" status="break" reason="ok">
        <xdebug:message filename="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" lineno="3"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `breakpoint_set -i 7 -t line -f file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php -n 4`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    201
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="breakpoint_set" transaction_id="7" id="40020006"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `stack_get -i 8`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    314
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="stack_get" transaction_id="8">
        <stack where="{main}" level="0" type="file" filename="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" lineno="3"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `run -i 9`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    316
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="run" transaction_id="9" status="break" reason="ok">
        <xdebug:message filename="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" lineno="4"/>
    </response>
    ```


- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `stack_get -i 10`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    315
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="stack_get" transaction_id="10">
        <stack where="{main}" level="0" type="file" filename="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" lineno="4"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `context_names -i 11`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    329
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="context_names" transaction_id="11">
        <context name="Locals" id="0"/>
        <context name="Superglobals" id="1"/>
        <context name="User defined constants" id="2"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `context_get -i 12 -d 0 -c 0`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    335
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="context_get" transaction_id="12" context="0">
        <property name="$a" fullname="$a" type="int"><![CDATA[1235]]></property>
        <property name="$b" fullname="$b" type="uninitialized"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `context_get -i 13 -d 0 -c 1`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    5809
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="context_get" transaction_id="13" context="1">
        <property name="$_COOKIE" fullname="$_COOKIE" type="array" children="1" numchildren="1" page="0" pagesize="100">
            <property name="XDEBUG_SESSION" fullname="$_COOKIE['XDEBUG_SESSION']" type="string" size="5" encoding="base64"><![CDATA[MTg5MjM=]]></property>
        </property>
        <property name="$_ENV" fullname="$_ENV" type="array" children="0" numchildren="0" page="0" pagesize="100"/>
        <property name="$_FILES" fullname="$_FILES" type="array" children="0" numchildren="0" page="0" pagesize="100"/>
        <property name="$_GET" fullname="$_GET" type="array" children="1" numchildren="1" page="0" pagesize="100">
            <property name="XDEBUG_SESSION_START" fullname="$_GET['XDEBUG_SESSION_START']" type="string" size="5" encoding="base64"><![CDATA[MTg5MjM=]]></property>
        </property>
        <property name="$_POST" fullname="$_POST" type="array" children="0" numchildren="0" page="0" pagesize="100"/>
        <property name="$_REQUEST" fullname="$_REQUEST" type="array" children="1" numchildren="1" page="0" pagesize="100">
            <property name="XDEBUG_SESSION_START" fullname="$_REQUEST['XDEBUG_SESSION_START']" type="string" size="5" encoding="base64"><![CDATA[MTg5MjM=]]></property>
        </property>
        <property name="$_SERVER" fullname="$_SERVER" type="array" children="1" numchildren="25" page="0" pagesize="100">
            <property name="DOCUMENT_ROOT" fullname="$_SERVER['DOCUMENT_ROOT']" type="string" size="37" encoding="base64"><![CDATA[L1VzZXJzL3Zpa3kvUGhwc3Rvcm1Qcm9qZWN0cy90ZXN0LXBocA==]]></property>
            <property name="REMOTE_ADDR" fullname="$_SERVER['REMOTE_ADDR']" type="string" size="3" encoding="base64"><![CDATA[Ojox]]></property>
            <property name="REMOTE_PORT" fullname="$_SERVER['REMOTE_PORT']" type="string" size="5" encoding="base64"><![CDATA[NjA3MTU=]]></property>
            <property name="SERVER_SOFTWARE" fullname="$_SERVER['SERVER_SOFTWARE']" type="string" size="29" encoding="base64"><![CDATA[UEhQIDUuNi4xOSBEZXZlbG9wbWVudCBTZXJ2ZXI=]]></property>
            <property name="SERVER_PROTOCOL" fullname="$_SERVER['SERVER_PROTOCOL']" type="string" size="8" encoding="base64"><![CDATA[SFRUUC8xLjE=]]></property>
            <property name="SERVER_NAME" fullname="$_SERVER['SERVER_NAME']" type="string" size="9" encoding="base64"><![CDATA[bG9jYWxob3N0]]></property>
            <property name="SERVER_PORT" fullname="$_SERVER['SERVER_PORT']" type="string" size="4" encoding="base64"><![CDATA[ODA4MA==]]></property>
            <property name="REQUEST_URI" fullname="$_SERVER['REQUEST_URI']" type="string" size="40" encoding="base64"><![CDATA[L3hkZWJ1Zy94LnBocD9YREVCVUdfU0VTU0lPTl9TVEFSVD0xODkyMw==]]></property>
            <property name="REQUEST_METHOD" fullname="$_SERVER['REQUEST_METHOD']" type="string" size="3" encoding="base64"><![CDATA[R0VU]]></property>
            <property name="SCRIPT_NAME" fullname="$_SERVER['SCRIPT_NAME']" type="string" size="13" encoding="base64"><![CDATA[L3hkZWJ1Zy94LnBocA==]]></property>
            <property name="SCRIPT_FILENAME" fullname="$_SERVER['SCRIPT_FILENAME']" type="string" size="50" encoding="base64"><![CDATA[L1VzZXJzL3Zpa3kvUGhwc3Rvcm1Qcm9qZWN0cy90ZXN0LXBocC94ZGVidWcveC5waHA=]]></property>
            <property name="PHP_SELF" fullname="$_SERVER['PHP_SELF']" type="string" size="13" encoding="base64"><![CDATA[L3hkZWJ1Zy94LnBocA==]]></property>
            <property name="QUERY_STRING" fullname="$_SERVER['QUERY_STRING']" type="string" size="26" encoding="base64"><![CDATA[WERFQlVHX1NFU1NJT05fU1RBUlQ9MTg5MjM=]]></property>
            <property name="HTTP_HOST" fullname="$_SERVER['HTTP_HOST']" type="string" size="14" encoding="base64"><![CDATA[bG9jYWxob3N0OjgwODA=]]></property>
            <property name="HTTP_CONNECTION" fullname="$_SERVER['HTTP_CONNECTION']" type="string" size="10" encoding="base64"><![CDATA[a2VlcC1hbGl2ZQ==]]></property>
            <property name="HTTP_CACHE_CONTROL" fullname="$_SERVER['HTTP_CACHE_CONTROL']" type="string" size="9" encoding="base64"><![CDATA[bWF4LWFnZT0w]]></property>
            <property name="HTTP_USER_AGENT" fullname="$_SERVER['HTTP_USER_AGENT']" type="string" size="120" encoding="base64"><![CDATA[TW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTNfMSkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzYzLjAuMzIzOS44NCBTYWZhcmkvNTM3LjM2]]></property>
            <property name="HTTP_UPGRADE_INSECURE_REQUESTS" fullname="$_SERVER['HTTP_UPGRADE_INSECURE_REQUESTS']" type="string" size="1" encoding="base64"><![CDATA[MQ==]]></property>
            <property name="HTTP_ACCEPT" fullname="$_SERVER['HTTP_ACCEPT']" type="string" size="85" encoding="base64"><![CDATA[dGV4dC9odG1sLGFwcGxpY2F0aW9uL3hodG1sK3htbCxhcHBsaWNhdGlvbi94bWw7cT0wLjksaW1hZ2Uvd2VicCxpbWFnZS9hcG5nLCovKjtxPTAuOA==]]></property>
            <property name="HTTP_DNT" fullname="$_SERVER['HTTP_DNT']" type="string" size="1" encoding="base64"><![CDATA[MQ==]]></property>
            <property name="HTTP_ACCEPT_ENCODING" fullname="$_SERVER['HTTP_ACCEPT_ENCODING']" type="string" size="17" encoding="base64"><![CDATA[Z3ppcCwgZGVmbGF0ZSwgYnI=]]></property>
            <property name="HTTP_ACCEPT_LANGUAGE" fullname="$_SERVER['HTTP_ACCEPT_LANGUAGE']" type="string" size="35" encoding="base64"><![CDATA[ZW4tVVMsZW47cT0wLjksemgtQ047cT0wLjgsemg7cT0wLjc=]]></property>
            <property name="HTTP_COOKIE" fullname="$_SERVER['HTTP_COOKIE']" type="string" size="20" encoding="base64"><![CDATA[WERFQlVHX1NFU1NJT049MTg5MjM=]]></property>
            <property name="REQUEST_TIME_FLOAT" fullname="$_SERVER['REQUEST_TIME_FLOAT']" type="float"><![CDATA[1514341321.2936]]></property>
            <property name="REQUEST_TIME" fullname="$_SERVER['REQUEST_TIME']" type="int"><![CDATA[1514341321]]></property>
        </property>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `context_get -i 14 -d 0 -c 2`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    197
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="context_get" transaction_id="14" context="2"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `step_over -i 15`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    323
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="step_over" transaction_id="15" status="break" reason="ok">
        <xdebug:message filename="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" lineno="6"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `stack_get -i 16`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    315
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="stack_get" transaction_id="16">
        <stack where="{main}" level="0" type="file" filename="file:///Users/viky/PhpstormProjects/test-php/xdebug/x.php" lineno="6"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `context_get -i 17 -d 0 -c 0`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    335
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="context_get" transaction_id="17" context="0">
        <property name="$a" fullname="$a" type="int"><![CDATA[1235]]></property>
        <property name="$b" fullname="$b" type="uninitialized"/>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `context_get -i 18 -d 0 -c 1`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    5809
    <?xml version="1.0" encoding="iso-8859-1"?>

    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="context_get" transaction_id="18" context="1">
        <property name="$_COOKIE" fullname="$_COOKIE" type="array" children="1" numchildren="1" page="0" pagesize="100">
            <property name="XDEBUG_SESSION" fullname="$_COOKIE['XDEBUG_SESSION']" type="string" size="5" encoding="base64"><![CDATA[MTg5MjM=]]></property>
        </property>
        <property name="$_ENV" fullname="$_ENV" type="array" children="0" numchildren="0" page="0" pagesize="100"/>
        <property name="$_FILES" fullname="$_FILES" type="array" children="0" numchildren="0" page="0" pagesize="100"/>
        <property name="$_GET" fullname="$_GET" type="array" children="1" numchildren="1" page="0" pagesize="100">
            <property name="XDEBUG_SESSION_START" fullname="$_GET['XDEBUG_SESSION_START']" type="string" size="5" encoding="base64"><![CDATA[MTg5MjM=]]></property>
        </property>
        <property name="$_POST" fullname="$_POST" type="array" children="0" numchildren="0" page="0" pagesize="100"/>
        <property name="$_REQUEST" fullname="$_REQUEST" type="array" children="1" numchildren="1" page="0" pagesize="100">
            <property name="XDEBUG_SESSION_START" fullname="$_REQUEST['XDEBUG_SESSION_START']" type="string" size="5" encoding="base64"><![CDATA[MTg5MjM=]]></property>
        </property>
        <property name="$_SERVER" fullname="$_SERVER" type="array" children="1" numchildren="25" page="0" pagesize="100">
            <property name="DOCUMENT_ROOT" fullname="$_SERVER['DOCUMENT_ROOT']" type="string" size="37" encoding="base64"><![CDATA[L1VzZXJzL3Zpa3kvUGhwc3Rvcm1Qcm9qZWN0cy90ZXN0LXBocA==]]></property>
            <property name="REMOTE_ADDR" fullname="$_SERVER['REMOTE_ADDR']" type="string" size="3" encoding="base64"><![CDATA[Ojox]]></property>
            <property name="REMOTE_PORT" fullname="$_SERVER['REMOTE_PORT']" type="string" size="5" encoding="base64"><![CDATA[NjA3MTU=]]></property>
            <property name="SERVER_SOFTWARE" fullname="$_SERVER['SERVER_SOFTWARE']" type="string" size="29" encoding="base64"><![CDATA[UEhQIDUuNi4xOSBEZXZlbG9wbWVudCBTZXJ2ZXI=]]></property>
            <property name="SERVER_PROTOCOL" fullname="$_SERVER['SERVER_PROTOCOL']" type="string" size="8" encoding="base64"><![CDATA[SFRUUC8xLjE=]]></property>
            <property name="SERVER_NAME" fullname="$_SERVER['SERVER_NAME']" type="string" size="9" encoding="base64"><![CDATA[bG9jYWxob3N0]]></property>
            <property name="SERVER_PORT" fullname="$_SERVER['SERVER_PORT']" type="string" size="4" encoding="base64"><![CDATA[ODA4MA==]]></property>
            <property name="REQUEST_URI" fullname="$_SERVER['REQUEST_URI']" type="string" size="40" encoding="base64"><![CDATA[L3hkZWJ1Zy94LnBocD9YREVCVUdfU0VTU0lPTl9TVEFSVD0xODkyMw==]]></property>
            <property name="REQUEST_METHOD" fullname="$_SERVER['REQUEST_METHOD']" type="string" size="3" encoding="base64"><![CDATA[R0VU]]></property>
            <property name="SCRIPT_NAME" fullname="$_SERVER['SCRIPT_NAME']" type="string" size="13" encoding="base64"><![CDATA[L3hkZWJ1Zy94LnBocA==]]></property>
            <property name="SCRIPT_FILENAME" fullname="$_SERVER['SCRIPT_FILENAME']" type="string" size="50" encoding="base64"><![CDATA[L1VzZXJzL3Zpa3kvUGhwc3Rvcm1Qcm9qZWN0cy90ZXN0LXBocC94ZGVidWcveC5waHA=]]></property>
            <property name="PHP_SELF" fullname="$_SERVER['PHP_SELF']" type="string" size="13" encoding="base64"><![CDATA[L3hkZWJ1Zy94LnBocA==]]></property>
            <property name="QUERY_STRING" fullname="$_SERVER['QUERY_STRING']" type="string" size="26" encoding="base64"><![CDATA[WERFQlVHX1NFU1NJT05fU1RBUlQ9MTg5MjM=]]></property>
            <property name="HTTP_HOST" fullname="$_SERVER['HTTP_HOST']" type="string" size="14" encoding="base64"><![CDATA[bG9jYWxob3N0OjgwODA=]]></property>
            <property name="HTTP_CONNECTION" fullname="$_SERVER['HTTP_CONNECTION']" type="string" size="10" encoding="base64"><![CDATA[a2VlcC1hbGl2ZQ==]]></property>
            <property name="HTTP_CACHE_CONTROL" fullname="$_SERVER['HTTP_CACHE_CONTROL']" type="string" size="9" encoding="base64"><![CDATA[bWF4LWFnZT0w]]></property>
            <property name="HTTP_USER_AGENT" fullname="$_SERVER['HTTP_USER_AGENT']" type="string" size="120" encoding="base64"><![CDATA[TW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTNfMSkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzYzLjAuMzIzOS44NCBTYWZhcmkvNTM3LjM2]]></property>
            <property name="HTTP_UPGRADE_INSECURE_REQUESTS" fullname="$_SERVER['HTTP_UPGRADE_INSECURE_REQUESTS']" type="string" size="1" encoding="base64"><![CDATA[MQ==]]></property>
            <property name="HTTP_ACCEPT" fullname="$_SERVER['HTTP_ACCEPT']" type="string" size="85" encoding="base64"><![CDATA[dGV4dC9odG1sLGFwcGxpY2F0aW9uL3hodG1sK3htbCxhcHBsaWNhdGlvbi94bWw7cT0wLjksaW1hZ2Uvd2VicCxpbWFnZS9hcG5nLCovKjtxPTAuOA==]]></property>
            <property name="HTTP_DNT" fullname="$_SERVER['HTTP_DNT']" type="string" size="1" encoding="base64"><![CDATA[MQ==]]></property>
            <property name="HTTP_ACCEPT_ENCODING" fullname="$_SERVER['HTTP_ACCEPT_ENCODING']" type="string" size="17" encoding="base64"><![CDATA[Z3ppcCwgZGVmbGF0ZSwgYnI=]]></property>
            <property name="HTTP_ACCEPT_LANGUAGE" fullname="$_SERVER['HTTP_ACCEPT_LANGUAGE']" type="string" size="35" encoding="base64"><![CDATA[ZW4tVVMsZW47cT0wLjksemgtQ047cT0wLjgsemg7cT0wLjc=]]></property>
            <property name="HTTP_COOKIE" fullname="$_SERVER['HTTP_COOKIE']" type="string" size="20" encoding="base64"><![CDATA[WERFQlVHX1NFU1NJT049MTg5MjM=]]></property>
            <property name="REQUEST_TIME_FLOAT" fullname="$_SERVER['REQUEST_TIME_FLOAT']" type="float"><![CDATA[1514341321.2936]]></property>
            <property name="REQUEST_TIME" fullname="$_SERVER['REQUEST_TIME']" type="int"><![CDATA[1514341321]]></property>
        </property>
    </response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `context_get -i 19 -d 0 -c 2`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    197
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="context_get" transaction_id="19" context="2"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `run -i 20`
- 响应 Xdebug -- XML --> PhpStorm：
  - ```xml
    207
    <?xml version="1.0" encoding="iso-8859-1"?>
    <response xmlns="urn:debugger_protocol_v1" xmlns:xdebug="http://xdebug.org/dbgp/xdebug" command="run" transaction_id="20" status="stopping" reason="ok"></response>
    ```

- 请求 PhpStorm -- 字符串命令 --> Xdebug：
  - `run -i 21`
- 响应 无

- 结束：TCP 4 次分手，结束连接




# Xdebug 调试流程解释
- PhpStorm 在启动调试后会监听 `9000` 端口

- 浏览器请求到 Web 服务器，最终到达 PHP

- PHP 启用 Xdebug 后，每个浏览器的请求都会告诉 Xdebug

- Xdebug 默认会向本地的 `9000` 端口（php.ini 中配置）询问：有没有谁需要进行 PHP 调试？
  - 若有 IDE 监听，则建立 TCP 连接
  - 若无 IDE 监听，则 TCP 连接建立失败，当作什么事都没发生

- 以上，PhpStorm 相当于 [DBGP](https://xdebug.org/docs-dbgp.php) 协议的服务端，Xdebug 相当于 DBGP 的客户端
  - DBGP 每次与 PhpStorm 建立连接都会采用新的随机端口

- PhpStorm 与 Xdebug 之间的通信是基于 TCP 之上的 DBGP 协议
  - DBGP 与 HTTP 无关，共同点：都在 TCP 之上的协议
  - DBGP 协议的 TCP 连接建立后会一直维持，所以期间：
    - Xdebug 可发消息给 PhpStorm，
    - PhpStorm 也可发消息给 Xdebug
  - Xdebug 发送到 PhpStorm 的都是 XML
    - 每个 XML 之前还包含一个描述了 XML 数据有多长的数字（这里格式化了 XML，可能字数统计略有不同）
  - PhpStorm 发送到 Xdebug 的都是简单命令字符串
  - Xdebug 官方解释是构建 XML 容易，解释 XML 难，故 Xdebug 内部不解释 XML

- PhpStorm 如何支持多个项目同时分别调试？
  - 浏览器的 HTTP 请求中带以下任一东西：
    - QueryString 中含：`XDEBUG_SESSION_START=someVal`
    - Cookie 中含：`XDEBUG_SESSION=someVal`
  - PhpStorm 收到 Xdebug 的初始化 XML 属性 `idekey` 中包含对应不同的 `someVal`
    - 由于 PhpStorm 内部机制，多个项目使用同一个进程，
      故 PhpStorm 在进程内部按不同的 `someVal` 来区分不同 Xdebug 命令对应到不同项目
    - 即使 PhpStorm 同时调试多个项目，也没看到任何进程在监听 `9001` 端口（DBGP 的默认代理端口），
      可能是因为 PhpStorm 没使用 DBGP 推荐的代理机制

- PhpStorm 与 Xdebug 的 TCP 连接是每次浏览器请求时才建立，并结束的
  - PhpStorm 中的断点是 TCP 建立后才告诉 Xdebug 的

- 虽然是 Xdebug 发起的 TCP 连接，但建立连接后大部分情况下都是 PhpStorm 主动向 Xdebug 发送请求




# 个人曾经的误解
- 误以为 Xdebug 与 PhpStorm 间是 HTTP 通信
  - 解答：不是 HTTP，而是基于 TCP 的 DBGP 协议

- 误以为 PhpStorm 多个项目同时调试是采用了 DBGP 的远程模式
  - 解答：不是 DBGP 的远程模式，而是 PhpStorm 内部的区分机制

- 误以为 Xdebug 本身也监听一个固定端口
  - 解答：Xdebug 不监听任何端口。
    - 监听端口的是 PhpStorm，即 DBGP 协议的服务端
    - Xdebug 本身是 DBGP 协议的客户端

- 误以为 PHP 代码断点位置是 PhpStorm 在某个未知特殊时期主动告诉 Xdebug 的
  - 解答：实际 Xdebug 主动向 PhpStorm 建立 TCP 连接，在此 TCP 连接中 PhpStorm 才向 Xdebug 报告自己有哪些断点。
    - 第一个断点：
      - 任何 PHP 第一句代码运行前，PhpStorm 都会告诉 Xdebug 进行 `step_into`，并紧接着向 Xdebug 报告自己的断点
      - 每个断点一次报告（即 1 次 TCP 数据发送）
    - 中断时，PhpStorm 中若继续新增断点，则 PhpStorm 立即告诉 Xdebug：`我这的断点有变化啦`

- 误以为官方的解释 DBGP 通讯过程的两个动图的 `DBGP` 连接是如何突然建立的
  - 图来源：https://xdebug.org/docs/all
  - 解答：见上一解答




# 简单总结
## 为什么 PHP 的调试器（如 Xdebug）需要额外安装？其他语言（如 Python、Java、NodeJs）就自带调试器
未知，求解答

## PHP debugger 列举
PhpStorm、Eclipse 都支持 Xdebug、Zend Debugger

- Xdebug（常用）
- Zend Debugger
- phpdbg（PHP 5.6 开始自带）
  - [参考](https://github.com/php/php-src/search?utf8=%E2%9C%93&q=phpdbg&type=)
- 其他：http://php.net/manual/en/debugger-about.php
  - DBG（不再更新）
  - APD（不再更新）