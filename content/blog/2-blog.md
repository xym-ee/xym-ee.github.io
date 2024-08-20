---
title:      "[post]静态网站搭建中有关计算机网络相关的内容"
date:       "2024-08-20T13:00:00+05:30"
lastmod:    "2024-08-20T13:00:00+05:30"
draft:      false
url:        /blog/hugo-website.html
layout:     "post"
tags:       ["post","computer technology","network","hugo","NAT","frp","nginx"，"git","shell","openwrt"]
---

## 0. 介绍

- 需求 1：我需要有个个人网站
  - hugo 、github pages
- 需求 2：我需要在局域网中开发和调试
  - 端口转发，NAT
- 需求 3：我想要更快的访问速度
  - 云服务器部署网页，nginx
- 需求 4：我想在外网访问内网的机器开发和调试
  - 内网穿透，frp
- 需求 5: 我还想要更好的体验
  - 软路由、定时任务。问问 chatgpt 

## 1. hogo 生成静态页面

在 ubuntu 环境下开发，ubuntu 安装于虚拟机中，采用桥接网卡方式上网。IP 10.0.0.22

使用了 [terminal-hugo-theme](https://github.com/techbarrack/terminal-hugo-theme) 主题，按照 README 中的说明，在本地生成静态页面并启动一个本地的网页服务器，

```bash
hugo server --buildDrafts --disableFastRender --gc --ignoreCache --noHTTPCache --forceSyncStatic --verbose -w
```

指令的参数

- **`--buildDrafts`**: 生成静态页面时为草稿的内容
- **`--disableFastRender`**: 禁用快速渲染(只会重新生成发生变化的部分)，确保在每次更改时全部重新生成
- **`--gc`**: 垃圾回收，清理未使用的文件
- **`--ignoreCache`**: 强制忽略缓存并重新构建所有文件，确保生成的时最新的
- **`--noHTTPCache`**: 禁用 HTTP 缓存，强制浏览器从服务器加载站点，确保从浏览器看的到是最新的
- **`--forceSyncStatic`**: 强制同步静态文件（例如图片、CSS、JS），即使 Hugo 认为它们没有更改。确保所有静态资源都是最新的
- **`--verbose`**: 输出更多信息
- **`-w`**: 是 `--watch` 的缩写，监视文件系统的更改，并在文件修改时自动重新构建站点

hugo 的本地网页服务器监听 1313 端口，生成后，在 ubuntu 的浏览器中访问 `http://127.0.0.1:1313` 可以看到网页内容。

## 2. GitHub pages 网页部署

生成最终要发布的网页的指令

```bash
hugo --baseURL="https://xym.work"
```

在 public 文件夹里就生成了网站所有的内容。将里面的内容 push 到 github 上去，在仓库设置里选择将根目录作为要发布的网站，即可在 `https://xxxx.github.io` 看到内容。我使用了自己的域名，在域名控制台添加了一个 CNAME 解析到了 xxxx.github.io。然后再 github 中设置一下即可。

## 3. 调试需求：内网中访问网站

我通常使用 windows 下的 vscode ssh 到虚拟机的 ubuntu 来编辑文字。windows 主机和虚拟机 ubuntu 在同一个子网。windows ip 为 `10.0.0.10/24` ，ubuntu ip 为  `10.0.0.22/24`，在 windows 终端中 `ssh user@10.0.0.22` 即可。

为了能直接在 windows 的浏览器中访问到网页的内容，hugo 启动命令还需要增加一个参数

```bash
hugo server --bind=0.0.0.0 --baseURL=http://10.0.0.22:1313 --buildDrafts --disableFastRender --gc --ignoreCache --noHTTPCache --forceSyncStatic -w
```

- **`--bind=0.0.0.0`**: 默认情况下，Hugo 的开发服务器只在 localhost 上可用，外部设备无法访问。如果设置为 0.0.0.0，服务器将监听所有网络接口上的请求。允许从局域网内的其他设备访问开发服务器
- **`--baseURL=http://10.0.0.22:1313`**: 设置站点的根 URL，Hugo 会基于这个 URL 生成相对链接和绝对链接。确保在正确的地址获得网站资源

此时就不需要操作虚拟机了，在 windows 就可以完成修改和预览。在另一台主机上安装 ubuntu 也是一样的。

新的需求：**网站的源码等都在教研室的电脑上，宿舍里有一台笔记本，有时候回宿舍也想写点东西**。

一个能用的方案，网站源码同步到 github，在宿舍的电脑上配一模一样的环境，实现单人异地合作开发。

但是校园网是个大些的局域网，本质上和连接在同一个路由器下的几台设备组成的局域网没有区别，因此也可以用 ssh 远程到教研室电脑，也可以用一个 ip + port 的方式访问教研室启动着的 hugo 服务器。

只需要设置一下端口转发。

网络结构 
- 教研室：校园网->教研室软路由->教研室无线路由->ubuntu
- 宿舍：校园网->宿舍无线路由器->windows

网络参数
- 教研室软路由
  - 拨号上网，WAN 口 **219.230.65.32/32**
  - 软路由子网号 192.168.2.0/24
  - 软路由网关 219.230.64.1
- 教研室无线路由器
  - DHCP 上网，通过软路由获得的 IP 192.168.2.2/24
  - 教研室无线路由器子网号 10.0.0.0/24
- 教研室 ubuntu - hugo 和 ssh 服务器
  - IP 10.0.0.22/24
  - hugo 端口 1313； ssh 端口 22
- 宿舍无线路由器
  - 拨号上网，IP 219.230.83.73/32 (不重要)
  - 宿舍无线路由器子网号 192.168.1.0/24 (不重要)
  - 宿舍路由器网关 219.230.80.1
- 宿舍电脑
  - IP 192.168.1.110/24

首先教研室和宿舍拨号上网这两个 ip 是教育网 ip，且，在 ip138 可以查到，至于是不是公网 ip 不清楚，不过不重要，具体的学校网络拓扑结构不清楚，但是这也不重要，重要的是在宿舍可以 ping 通教研室软路由。

>宿舍和教研室电脑可以互通，但是在不同的子网，并且网关不同，可以判断这两台电脑不是二层连接，即不是使用 MAC 完成的通信。由于网关都不同，那么这两个设备可能在三层网络上进行连接，两个网关之间是有有效的路由设置的。

教研室软路由设置端口转发规则
- 219.230.65.32:1313 -> 192.168.2.2:1313 (hugo server) 
- 219.230.65.32:2222 -> 192.168.2.2:2222 (ssh)

教研室无线路由器设置端口转发规则
- 192.168.2.2:1313 -> 10.0.0.22:1313 (hugo server)
- 192.168.2.2:2222 -> 10.0.0.22:22 (ssh)

软路由的 22 端口是软路由自己的 ssh 端口，所以用了 2222。

此时在宿舍电脑上 `ssh -p 2222 user@219.230.65.32` 即可远程上去了。在 vscode 中远程可以编辑文档了，启动 hugo server 后，要想流浪网页，还需要设置权限。linux 用户和用户组里有一个 www-data，用于运行 Web 服务器进程的默认用户和用户组。需要把网页资源给此用户需要的权限。

```bash
# 给予目录适当的读取和执行权限
sudo chmod 755 /home/m
sudo chmod -R 755 /home/m/xxxx/public

# 给 网络用户 权限，直接换用户
sudo chown -R www-data:www-data /home/m/public
```

确保网站资源的权限可读可执行。然后在宿舍电脑的浏览器访问 `http://219.230.65.32:1313` 即可看到网页内容。

## 4. 访问速度：云服务器网页部署

使用 GitHub pages 的作为 web 服务器的问题是国内访问比较慢，最大的优点是免费。在内网中访问就很快，如果说有一台电脑不论什么网络都能方便的 ssh 上去，不用配置端口转发也能访问 hugo server ，那应该会比 github pages 快很多。

云服务器就是干这个事情的，云服务器有固定的公网 ip，在使用上和个人电脑没太多区别。如果赶上活动的话，腾讯云或者阿里云的轻量云服务器一年的价格不到 100，也是可以接受的。我购买的服务器为 2 核 2GB 内存，50GB SSD，每个月 300GB 流量，带宽 4Mbps，对于个人网页来说足够了。

云服务器安装了 Ubuntu 22.04 系统。如果把 hugo 那个开发环境安装到云服务器上，然后在云服务器上启动 hugo server，云服务器防火墙开放 1313 端口。那么在浏览器访问 `http://ip:1313` 也是可以看到网页内容的，而且，任何人用任何设备访问这个地址都能看到。此处 ip 为服务器的公网 ip。如果说家里的宽带运营商可以给一个公网 ip 的话，家里的电脑和买的云服务器没有区别。

但是一般会使用功能更多、性能更好的专用的 **web 服务器**，这里的 web 服务器指的是软件如 Nginx、Apache。在浏览网页时需要一套软件来接受浏览器发出的 http 请求并返回请求的资源。更细节的内容可以参考我的笔记[计算机网络-从浏览器开始](https://embedded.xym.work/4_network/1_web_overview)。在前面 hugo server 做了这个事情。在云服务器上使用更强大的 Nginx 。如果只是用作一个网页服务器，那么配置也没有特别复杂。

云服务器安装 nginx
```bash
sudo apt install nginx
```

将 hugo 生成的静态内容上传到云服务器如 `/home/ubuntu/xym-ee.github.io`，然后来配置 nginx ，新建一个配置文件 `sudo vim /etc/nginx/sites-available/xym-ee.github.io`
```
server {
    listen 80;
    server_name [ip];

    root /home/ubuntu/xym-ee.github.io;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    # Optional: Additional security or performance settings can be added here
}
```

然后应用配置
```bash
# 配置文件连接到目录
sudo ln -s /etc/nginx/sites-available/xym-ee.github.io /etc/nginx/sites-enabled/

# 测试配置是否正确
sudo nginx -t

# 重启应用
sudo systemctl restart nginx
```

这里也要给相应的权限。

然后就可以在 `http://ip` 直接看到网页内容了。

有域名的话，可以将域名解析到服务器 ip，但是需要完成备案。

## 5. 强行创造的调试需求：在公网访问内网的 hugo server

新的需求：如果回家了以后，还想像在学校一样 ssh 到教研室电脑，然后直接用教育网的 ip 访问网页，该怎么办呢？

这时候其实源码放在 github ，搭另一套环境可能是比较好的选择。但是买了云服务器，强行创造这个需求：公网 ssh 内网的机器。

解决方法是内网穿透。使用的工具是一台有公网 ip 的电脑和 [frp](https://github.com/fatedier/frp) 。内网穿透的前提要有一个有公网 ip 的设备，前面装 Nginx 的云服务器正好就用上了，或者找宽带运营商客服看看能不能要个公网 ip。

内网穿透的原理：一台内网设备和一台有公网 ip 的服务器保持连接，公网设备连接服务器，公网设备向服务器发送指令，服务器转发到内网设备上执行后，返回服务器，然后服务器返回公网设备。即两台电脑都连接到有公网 ip 的服务器上，然后有服务器做转发。

去 frp github 仓库下载最新的 release 版本，服务器配置 frp 服务端口，客户端配置服务器ip、本地端口、映射端口即可。


## 6. 更好的使用体验：软路由

有时候需要 git clone 一些东西，但是有时候网络不一定顺畅。因此可以使用一台软路由，安装 open clash 实现代理。

此外校园网 pppoe 拨号上网每 24 小时会强制断开一次，因此指定在凌晨定时自动重拨，重拨后的 ip 会变，每天回宿舍之前还需要记下来。

在软路由上写一个自动化的脚本，获得 wan 口的 ip，并保存为文本文件上传到我的 github 仓库。

```bash
#!/bin/bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# 切换到仓库目录
cd /root/ipaddr

# 获得 ip
ifconfig pppoe-wan | grep 'inet addr:' | awk -F: '{print $2}' | awk '{print $1}' > ip.md

# 提交到 github 
git add .
git commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
git push
```

此外，软路由设置定时任务，每天凌晨 5 点自动重新拨号，5 点 10 分获取执行上传 ip 的脚本。
```bash
0 5 * * * /sbin/ifdown wan && /sbin/ifup wan
10 5 * * * /root/ipaddr/upload.sh
```

然后可以在宿舍电脑也写个脚本，在电脑启动以后自动从仓库同步 ip，并提取 ip，重写 vscode 的 ssh 配置文件。

请求 chatgpt 协助完成 powershell 脚本，给的描述

```
我想用powershell写一段脚本，完成以下功能：D盘下有个 ipaddr 文件夹，这是个 git 仓库，拉取 github 最新内容，然后读取里面 ip.md 的内容，这里是一个 ipv4 地址，读到地址后，替换C:/users/m/.ssh/config 文件里 Host 名为 ubuntu22 下的 ip。config 文件格式
Host ubuntu22
    HostName 10.0.0.22
    User m
```
gpt 给的代码
```shell
# 定义变量
$ipaddrDir = "D:\ipaddr"
$ipFilePath = "$ipaddrDir\ip.md"
$sshConfigPath = "C:\Users\m\.ssh\config"
$hostNameToUpdate = "ubuntu22"

# 进入 Git 仓库目录
Set-Location $ipaddrDir

# 拉取 GitHub 上的最新内容
git pull origin main

# 读取 ip.md 文件中的 IP 地址
$ipAddress = Get-Content $ipFilePath | Select-String -Pattern '^\d{1,3}(\.\d{1,3}){3}$'

if ($ipAddress) {
    # 读取 SSH 配置文件内容
    $configLines = Get-Content $sshConfigPath

    # 初始化新的配置内容
    $newConfigLines = @()

    # 标识是否在需要更新的 Host 块中
    $inTargetHostBlock = $false

    # 遍历每一行配置文件内容
    foreach ($line in $configLines) {
        if ($line -match "^Host\s+$hostNameToUpdate\s*$") {
            $inTargetHostBlock = $true
        }

        if ($inTargetHostBlock -and $line -match "^\s*HostName\s+\d{1,3}(\.\d{1,3}){3}$") {
            # 替换 HostName 为新的 IP 地址
            $newConfigLines += "    HostName $ipAddress"
            $inTargetHostBlock = $false  # 停止处理目标块
        } else {
            # 保留其他行不变
            $newConfigLines += $line
        }
    }

    # 将新的配置内容写回 config 文件
    $newConfigLines | Set-Content $sshConfigPath

    Write-Host "IP 地址已更新为：$ipAddress"
} else {
    Write-Host "未找到有效的 IP 地址，请检查 ip.md 文件内容。"
}
```

我也没有测试是否能用，一般我回宿舍就自己看一下然后手动修改配置文件了。但是这件事一定是可以做的，即使 gpt 的代码不对，但也已经给了个大概的方向，虽然我不会 windows powershell 脚本，但是 gpt 已经给了指令上和逻辑上足够多的提示，做出来这件事也没那么困难。

## 7. 总结

计算机网络实践，《网络是怎样连接的》这本书完全覆盖这里的所有的理论上的内容。

gpt 可以提高工作效率。在 nginx 配置时，遇到了问题，服务器启动后访问页面一直出现 nginx 的 404。再三检查配置文件没问题，给出现象，根据 gpt 提示查看 nginx 的 log，发现没有给 www-data 权限，顺利解决。如果没有 gpt 那么这个问题估计也得在网上找好几天。

还有自动上传 ip 的 shell 脚本，我只是了解一些 shell 指令，知道这个事情可以做，自己去查 shell 指令一点点写也可以写出来，但是给 gpt 提出要求，他很快就给出结果了。

向 gpt 提出合适的问题，会大大提高工作效率。

好像南京联通宽带能免费给个公网 ip，看来明年的宽带要换联通了。

黑神话悟空今天上线了，国产之光，下载的时候再去刷刷视频。



