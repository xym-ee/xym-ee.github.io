---
title:      "构建最小 Linux 系统"
date:       "2023-07-17T19:01:48+05:30"
lastmod:    "2023-07-17T19:01:48+05:30"
draft:      false
url:        /blog/minimal-linux.html
layout:     "post"
tags:       ["computer technology","embedded"]
---

- [Linux 世界中的应用程序 (从零开始构建 “最小” Linux) [南京大学2023操作系统-P16] (蒋炎岩)](https://www.bilibili.com/video/BV1gg4y1T71C)
- [16. Linux 操作系统](http://jyywiki.cn/OS/2023/build/lect16.ipynb)


为了努力的理解操作系统，学习过程中的一个想法：能不能控制电脑启动后加载的第一个程序。

事实上，电脑启动到出现桌面，这个过程并不简单。先不讨论 bootloader 阶段，只说 linux kernel，即一个想法：控制 kernel 启动后加载的第一个程序。kernel 启动后加载的程序都放在存储介质里，即存储介质里的东西不需要那么多，目录足够简单。

linux 一般仅指 kernel，根目录下的所有东西为根文件系统。构建最小 Linux 系统的完整说法：构建根文件系统最小的linux系统。

如果查看 pstree ，可以看到进程之间的关系


## QEMU 下模拟


希望在给定的 linux 内核初始化完成后，直接执行我自己编写的静态链接的 init 二进制文件，我该怎么做。

查看手册得知，kernel init 函数中，会尝试按顺序执行一些东西

```c
	if (!try_to_run_init_process("/sbin/init") ||
	    !try_to_run_init_process("/etc/init") ||
	    !try_to_run_init_process("/bin/init") ||
	    !try_to_run_init_process("/bin/sh"))
		return 0;
```

这便是启动的第一个进程，如果一个都没找到，那么就会 kernel panic。

QEMU 中可以用参数指定启动的系统镜像，从而不需要考虑 bootloader 的事情，因此先在 x86 平台做这个事情。为此我们需要准备 内核镜像与根文件系统里的东西。

内核镜像可拿一个现成的来用 `/boot/vmlinuz` ，

按照 linux 约定的方式，把我们自己的可执行文件放到 bin 里

准备好了所有东西，把这些东西打包起来

```
cd rootfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../rootfs.cpio.gz
```

在 QEMU 里启动，指定一些启动参数

```
qemu-system-x86_64 \
  -serial mon:stdio \
  -kernel ./vmlinuz \
  -initrd ./rootfs.cpio.gz \
  -machine accel=kvm:tcg \
  -append "console=ttyS0 rdinit=/bin/init"
```


## 嵌入式 linux

交叉编译 busybox，准备好 rootfs，通过 nfs 方式网络挂载文件系统。使用起来甚至比 QEMU 还要好用。

kernel 直接找到了 /bin/init，并运行起来。


