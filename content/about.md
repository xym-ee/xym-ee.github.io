---
title: "💬 About Me"
date: 2024-03-28T15:00:00+00:00
draft: false
layout: "terms"
description: "About - {{ .Site.Title }}"
url: "/about.html"
---

<!-- 单页 -->

&nbsp;

#### 教育与工作经历

| 📅 | 💼 | 🛠 |
|:-:|:-:|:-:|
| 2022.9 - 至今 | 硕士在读 | **导航、制导与控制**专业，毕业时间 2025.4 |
| 2021.2 - 2022.9 | 嵌入式软件工程师 | 移动机器人、运动控制、rt-thread、单板软硬件 |
| 2020.6 - 2021.1 | MCU 开发工程师 | 线控底盘，单板软硬件开发 |
| 2016.9 - 2020.6 | 本科在读 | 电气工程及其自动化专业，电力电子与电机方向 |


<style>
    /* 按钮样式 */
    .button {
        padding: 10px 20px;
        font-size: 16px;
        cursor: pointer;
        background-color: #007BFF;
        color: white;
        border: none;
        border-radius: 5px;
        position: relative;
    }

    /* 悬浮窗容器样式 */
    .tooltip {
        display: none;
        position: absolute;
        top: 100%; /* 显示在按钮下方 */
        left: 50%;
        transform: translateX(-50%);
        margin-top: 10px;
        padding: 10px;
        background-color: #333;
        border-radius: 5px;
        z-index: 1000;
    }

    /* 悬浮窗中的图片样式 */
    .tooltip img {
        max-width: 200px; /* 限制图片最大宽度 */
        border-radius: 5px;
    }

    /* 当鼠标悬停在按钮上时，显示悬浮窗 */
    .button:hover .tooltip {
        display: block;
    }
</style>


<button class="button">
    Hover over me
    <!-- 悬浮窗内容 -->
    <div class="tooltip">
        <img src="/images/wechat.png" alt="Description">
    </div>
</button>

<!--
熟练使用C语言开发，嵌入式系统设计，中低速PCB设计，运动控制。
熟悉控制理论与控制方法、计算机系统架构、计算机网络、操作系统原理，了解编译过程、编译原理
arm和x86和架构、系统镜像构建(uboot、linux kernel、根文件系统)与linux驱动开发(device tree)
熟悉RTOS(rt-thread)，基于rtt的应用开发(多线程、线程同步与通信)、bsp开发、I/O设备驱动框架、sensor对接
熟悉控制理论，pid、LQR、最优控制；熟悉永磁同步电机控制理论与伺服系统控制，了解FOC算法与C语言实现
了解移动机器人与机械臂控制、ROS，了解C++主要特性
gcc gdb makefile vscode keil IAR stm32 nxpi.mx git github webots shell socket AltiumDesigner

-->



---

