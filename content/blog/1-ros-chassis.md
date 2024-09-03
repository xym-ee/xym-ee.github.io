---
title:      "[project] ROS 机器人底盘开发，差速底盘和阿克曼底盘"
date:       "2024-08-30T10:00:00+08:00"
lastmod:    "2024-08-30T10:00:00+08:00"
draft:      false
url:        /blog/ros-chassis.html
layout:     "post"
tags:       ["project","rt-thread","stm32"]
---

模拟联合收割机器人

<video controls style="margin: 0 auto;" width="240">
  <source src="./videos/ros-chassis-1.mp4" type="video/mp4">
</video>

模拟自动驾驶

<video controls style="margin: 0 auto;" width="240">
  <source src="./videos/ackerman-1.mp4" type="video/mp4">
</video>

## 0.介绍

自主移动机器人，导航，为了导航需要地图，还需要定位。

最后是运动，我主要做机器人的底盘开发和运动控制这块的内容。


## 1.ROS 差速底盘开发

这里主要介绍一下差速底盘的里程计计算

```c
        rt_mutex_take(status_mutex, RT_WAITING_FOREVER);
        
        status.chassis.motor_lf.v_feedback = v_lf;
        status.chassis.motor_lb.v_feedback = v_lb;
        status.chassis.motor_rf.v_feedback = v_rf;
        status.chassis.motor_rb.v_feedback = v_rb;
        
        /* 里程计数据解算 */
        #define     L   0.23f    /* 左右轮间距 */
        
        v_l = (v_lf + v_lb)/2.0f;
        v_r = (v_rf + v_rb)/2.0f; 

        status.info_send.speed_x = (v_l + v_r) / 2.0f;
        status.info_send.speed_y = 0.0f;
        status.info_send.speed_angular = -(v_l - v_r) / L / 2.0f;

        status.info_send.pose_angula += 0.93f * status.info_send.speed_angular*DELAY_TIME;
        status.info_send.pose_angula = angle_to_limit(status.info_send.pose_angula);
        status.info_send.position_x  += status.info_send.speed_x*cosf(status.info_send.pose_angula)*DELAY_TIME;
        status.info_send.position_y  += status.info_send.speed_x*sinf(status.info_send.pose_angula)*DELAY_TIME;

        rt_mutex_release(status_mutex);
```


## 2.阿克曼底盘

主要也是里程计计算以及运动控制方面。



