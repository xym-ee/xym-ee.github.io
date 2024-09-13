---
title:      "[project] 全向舵轮底盘运动控制软件开发"
date:       "2024-08-30T10:00:00+08:00"
lastmod:    "2024-08-30T10:00:00+08:00"
draft:      false
url:        /blog/omni-chassis.html
layout:     "post"
tags:       ["project","rt-thread","stm32"]
---


## 0.介绍

一种全向底盘的类型是麦克纳姆轮底盘，还有一种类似行李箱轮的结构，轮子本身可以 $ 360 \degree $ 受控的旋转，即舵轮。

项目来源



## 1.舵轮底盘控制原理

几种模式

$$
\left \\{
    \begin{array}{l}
        r_2 \cos \theta_2 - r_1 \cos \theta_1 = 2a \\\\
        r_1 - r_1 \cos \theta_1 + a = r \\\\
        r_2 \cos \theta_2 = r + a \\\\
        r_1 \sin \theta_1 = a \\\\
        r_2 \sin \theta_2 = a \\\\
    \end{array}
\right .
$$

先搞走三角函数，计算内外圆的半径

由后面四个式子

$$
\cos \theta_1 = \frac{r_1 + a - r}{r_1}
$$

$$
\cos \theta_2 = \frac{r + a }{r_2}
$$

带入第一个式子里有

$$
r + a - (r_1 + a -r) = 2a
$$

$$
r_1 = 2(r-a)
$$



$$
\sin \theta_1 = \frac{a}{r_1}
$$

$$
\sin \theta_1 = \frac{a}{r_2}
$$




## 2.webots 运动控制仿真





## 








