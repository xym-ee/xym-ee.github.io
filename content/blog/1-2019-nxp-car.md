---
title:      "[project] 2019 年恩智浦杯大学生智能汽车竞赛，代码 review"
date:       "2024-08-30T10:00:00+08:00"
lastmod:    "2024-08-30T10:00:00+08:00"
draft:      false
url:        /blog/2019-nxp-car.html
layout:     "post"
tags:       ["project","rt-thread","stm32"]
---


效果视频

## 0.介绍

2019 年 7 月分我参加了当年的恩智浦杯智能汽车竞赛，以前叫飞思卡尔杯，对于自动化专业来说，这个比赛还是挺重要的。当时我大三，这个比赛(项目)算是我的第一个完成度比较高的作品。我负责的内容，硬件开发，驱动开发，整个软件框架的开发。

这辆车也一直放在我身边，当时可能只是感兴趣觉得好玩，现在看起来这应该是我整个嵌入式开发生涯的起点。现在的我能给出更好地方案，更完整的设计，甚至更高效的代码结构。但是让我去评价当年的写这些代码的自己，我觉得做的已经不错了，这是一个项目总结，同时也是一个关于如何写出好代码的一些想法。

这个车的主控芯片为 NXP imx 的跨界处理器，使用 IAR 完成裸机开发。当时大量的参考了 NXP 官方的源码，虽然是裸机开发但是当时也通过 NXP 例程学习了不少东西，后面的内容我会详细写出来。

## 1.比赛要求，智能车工作原理

固定元素，实现智能车的自动运行。

- 赛道上出现的元素
  - 赛道对比度比较高，摄像头是一定需要的。此外赛道上还铺设了电磁引导线，通着交流电，也可以通过磁场定位。赛道上还有障碍物，是显眼的红色。
  - 需要摄像头，电磁传感器
  - 障碍物
- 底盘控制
  - 舵机
  - 两个直流电机

硬件上，要考虑电机、舵机驱动，电磁传感器模拟信号的处理，整车供电。

车辆控制上，需要考虑通过图像获得智能车相对于赛道的偏差，这部分内容由我的队友负责，通过偏差计算出舵机的控制量，这部分也由我的队友负责。相当于我搭建一个比较可靠的运动平台，并提供控制算法需要的原始数据，然后将控制算法的输出落实到执行机构如电机、舵机。


## 2.硬件方案设计

我已经有几年不做硬件不画板了，但是这个项目是我比较完整的软硬件都做的项目，这里一定要拿出来介绍一下。

使用 Altium Designer 来开发。考虑整车的电源设计，驱动板设计，电磁传感器设计，MCU 控制板的设计。



## 3.软件总体方案设计

这里由于软件设计上的不完善，只能通过 main 函数主循环的实现来猜测当时的设计想法了

```c
int main(void)
{
  /* ---------------------      硬件初始化         -------------------------- */
  system_init();/* MCU初始化 */
  //car_direction_barrier_test();/* 单个功能测试函数位置 */
  lpuart1_init(115200);         /* 蓝牙发送串口启动 */
  key.init();                   /* 按键启动 */
  led.init();                   /* 指示灯启动 */
  NVIC_SetPriorityGrouping(2);  /* 2: 4个抢占优先级 4个子优先级*/
  oled.init();                   /* LCD启动 */
  //ExInt_Init();                 /* 中断启动 */
  adc.init();
  motor.init();         /* 车速PID控制初始化.包含ENC,PWM,PID参数初始化 */       
  img.init();                   /* 相机接口初始化 */
  delayms(200);                 /* 必要的延时，等待相机感光元件稳定 */
  //UI_debugsetting();
  pit_init(kPIT_Chnl_0, 10000);
  
  while(1)
  {
	  /* 10ms中断置位？  */
	  while (status.interrupt_10ms == 0)
	  {
        adc.refresh();      /* 更新赛道电磁引导线信息，adc_roadtype数据包更新 */
        adc.circle_check(); /* 圆环检测、偏差检测，转换为电磁引导模式 */
	  }
    
    key.barrier_check(); /* 路障检查 */
    /* 如果图像就绪，图像刷新，道路类型判断 */
    if(kStatus_Success == CAMERA_RECEIVER_GetFullBuffer(&cameraReceiver, &CameraBufferAddr))
    {
      img.refresh();            /* 更新图像和偏差等控制信息 */
      adc.error_check();        /* 电磁引导线偏差检查 */
    }
    
    car.direction_control();  /* 舵机打角更新 */
    car_speed_calculate();      /* 更新一次左右电机目标速度 */    
    
    /* 两个电机转速控制 */
    motor.pidcontrol(&motor_speed);
    
    status_indicator.light_road();    /* 状态灯指示更新 */
    status_indicator.oled_circle();   /* 屏幕显示更新 */
    
    char txt[16];
    sprintf(txt,"ENC2: %6d ",(int16_t)ENC_GetPositionValue(ENC2));
    LCD_P6x8Str(0,5,(uint8_t*)txt);   

    /* 中断复位 */
    status.interrupt_10ms = 0;
  }
}
```

我现在看这段代码已经看不大明白了，好在函数名起的还可以，丢给 chatgpt，他给我的回答

>这个代码的控制逻辑通过一个定时中断来驱动，周期性地采集传感器数据、进行路障检测、图像处理和车辆控制。主循环确保每个任务在固定时间间隔内被执行，并根据传感器和相机的数据实时调整车辆的运动状态。

现在看来，主循环代码并没有做到不言自明，可以想到这个代码维护起来很困难，依靠四散在各处的全局变量来实现数据的传递。最主要的是在最上层的主函数并没有充分的体现出应用层的控制逻辑，一些函数的参数也莫名奇妙，比如 `motor.pidcontrol(&motor_speed);` 传入的参数没有前因后果。非常独立。

我现在评价这个代码：在形式上模仿了描述符(句柄 or 一个对象)控制一个对象的想法，但是只是参考了形式上的设计。并不知道为什么这么做。

## 4.关于一些驱动的讨论

摄像头的型号为 MT9V034，连接到芯片的 CSI 接口，这部分的代码使用了 nxp 官方的例程，里面大量的出现了类似的代码

```c
/*******************************************************************************
 * Variables
 ******************************************************************************/
const camera_receiver_operations_t csi_ops = {
    .init = CSI_ADAPTER_Init,
    .deinit = CSI_ADAPTER_Deinit,
    .start = CSI_ADAPTER_Start,
    .stop = CSI_ADAPTER_Stop,
    .submitEmptyBuffer = CSI_ADAPTER_SubmitEmptyBuffer,
    .getFullBuffer = CSI_ADAPTER_GetFullBuffer,
    .init_ext = CSI_ADAPTER_InitExt
};
```

不得不说，这些示例代码给了我对代码设计的良好启蒙。用我现在的理解来说，这些代码对设备对象和操作做了很好的封装，模块化的设计做的非常好，

我也做了形式上的模仿如 

```c
/* LED设备初始化 */
static void led_pin_init(void);

/* LED操作 */
static void led_on(led_name_t choose);
static void led_off(led_name_t choose);
static void led_reverse(led_name_t color);
static void led_flash_fast(led_name_t color);
static void led_flash_slow(led_name_t color);
static void led_off_all(void);

const led_operations_t led_ops = {
        .on = led_on,
        .off = led_off,
        .reverse = led_reverse,
        .flash_fast = led_flash_fast,
        .flash_slow = led_flash_slow,
        .off_a = led_off_all,
};

const led_device_t led = {
        .init = led_pin_init,
        .ops = &led_ops
};
```

具体的实现直接使用 nxp 的库。完整的源码 

当时只做了形式上的模仿，但是也确实通过这个了解到了一些程序设计上的东西。


这也是我第一次接触这类语法，这对我后面学习 rt-thread 甚至 linux 都很有帮助。linux 内核中这类的表达也很多。


## 5.关于程序的方法实现

目标是运动控制。那么有方法上的东西。

用编程去实现理论的东西，应用控制算法。

现在我觉得是我拖了队友的后腿。😂，因为方法都是用 matlab 仿真过的，现在的我看这些控制方法找不出一点毛病，但是看软件实现漏洞百出。事实上，从视频也可以看出来方法在当时就已经有了不错的控制效果。

通过图像找偏差的具体思路：


## 6.总结







