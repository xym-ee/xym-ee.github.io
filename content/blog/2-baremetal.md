---
title:      "[post] 使用 gcc 开发 STM32"
date:       "2024-09-04T10:00:00+08:00"
lastmod:    "2024-09-04T10:00:00+08:00"
draft:      false
url:        /blog/baremetal.html
layout:     "post"
tags:       ["post","stm32","gcc","gdb","makefile","link"]
---

# 使用 gcc 开发 STM32

有 keil IAR 等 IDE，还要在 ubuntu 环境下使用 gcc 来开发 stm32 看起来似乎吃力不讨好。但是掌握这个技能的真正含义是：

拿到任意一块使用 arm cortex-m 内核的全新设计的芯片，只有芯片手册甚至还没有 IDE 可以使用的时候，使用 C 语言和一些 arm 汇编，以及交叉编译工具，是可以把这个芯片使用起来的。

更实际的情况是，一些大的裸机项目比如 u-boot，甚至 linux kernel 都是没有 IDE 用的，开发、调试这些项目的工具正是裸机开发 stm32 的这套工具。从一个简单的芯片开始去学习这一流程、练习相应工具的使用。

我的环境
- ubuntu 22.04
- STM32F103C8T6 64K flash 20K ram
- st-link v2
- 13.3.rel1-x86_64-arm-none-eabi


## 最简单的程序

```c
int main()
{
    return 0;
}
``

为了让这个函数能在 CPU 上执行，还需要做到芯片通电后跳转到 main 入口。

```c
__attribute__((naked, noreturn)) void _reset(void) {
  extern long _sbss, _ebss, _sdata, _edata, _sidata;

  for (long *dst = &_sbss; dst < &_ebss; dst++) 
    *dst = 0;

  for (long *dst = &_sdata, *src = &_sidata; dst < &_edata;) 
    *dst++ = *src++;

  main();             // Call main()

  for (;;) (void) 0;  // Infinite loop in the case if main() returns
}
```

想让这个函数通电就执行，需要准备好 C 语言的运行环境，以及指定这个函数的地址，即程序员和硬件的约定，查看 m3 权威指南

```c
extern void _estack(void);

__attribute__((section(".vectors"))) void (*const tab[16 + 60])(void) = {
    _estack,
    _reset
};
```

有好多变量都用了 extern ，这些变量在链接脚本内，链接时会计算然后填入。此外有好多修饰也是给连接器看的。


```c
ENTRY(_reset);
MEMORY {
  flash(rx)  : ORIGIN = 0x08000000, LENGTH = 64k
  sram(rwx) : ORIGIN = 0x20000000, LENGTH = 20k  /* remaining 64k in a separate address space */
}
_estack     = ORIGIN(sram) + LENGTH(sram);    /* stack points to end of SRAM */

SECTIONS {
  .vectors  : { KEEP(*(.vectors)) }   > flash
  .text     : { *(.text*) }           > flash
  .rodata   : { *(.rodata*) }         > flash

  .data : {
    _sdata = .;   /* .data section start */
    *(.first_data)
    *(.data SORT(.data.*))
    _edata = .;  /* .data section end */
  } > sram AT > flash
  _sidata = LOADADDR(.data);

  .bss : {
    _sbss = .;              /* .bss section start */
    *(.bss SORT(.bss.*) COMMON)
    _ebss = .;              /* .bss section end */
  } > sram

  . = ALIGN(8);
  _end = .;     /* for cmsis_gcc.h  */
}
```
链接脚本控制了代码存放的位置。

然后就可以变异了。写一个 makefile

```makefile
CFLAGS  ?=  -W -Wall -Wextra -Werror -Wundef -Wshadow -Wdouble-promotion \
            -Wformat-truncation -fno-common -Wconversion \
            -g3 -Os -ffunction-sections -fdata-sections -I. \
            -mcpu=cortex-m3 -mthumb $(EXTRA_CFLAGS)
LDFLAGS ?= -Tlink.ld -nostartfiles -nostdlib --specs nano.specs -lc -lgcc -Wl,--gc-sections -Wl,-Map=$@.map
SOURCES = main.c 

ifeq ($(OS),Windows_NT)
  RM = cmd /C del /Q /F
else
  RM = rm -f
endif

build: firmware.bin

firmware.elf: $(SOURCES)
	arm-none-eabi-gcc $(SOURCES) $(CFLAGS) $(LDFLAGS) -o $@

firmware.bin: firmware.elf
	arm-none-eabi-objcopy -O binary $< $@

flash: firmware.bin
	st-flash --reset write $< 0x8000000

clean:
	$(RM) firmware.*
```

gcc 参数中大部分是警告控制选项，此外指定了内核型号。所有标准 gcc 的工具都是可以用的，如 readelf、objdump，gdb 。


## 下载和调试

下载使用 st-link 工具包。这个工具包除了 st-flash 工具还有一个 st-util 工具，这个工具可以启动一个 gdb server 在 4242 端口。然后就可以使用 gdb 工具来调试 STM32 了。

上面的代码下载进去以后是没有任何现象的。想要看看代码是不是真的运行起来了，需要用到调试工具。

load 加载被调试的程序，然后剩下的操作就是 gdb 的操作。

## 点亮 LED

到了 C 语言的领域，那么几乎就可以做任何事情了。先点个灯

点灯要做的是开时钟，设置 GPIO 模式，然后控制引脚寄存器。对着手册去写

```c
struct rcc {
  volatile uint32_t CR, CFGR, CIR, APB2RSTR, APB1RSTR, AHBENR, 
                    APB2ENR, APB1ENR, BDCR, CSR;
};

struct gpio {
  volatile uint32_t CRL, CRH, IDR, ODR, BSRR, BRR, LCKR;
};

static inline void spin(volatile uint32_t count) {
  while (count--) asm("nop");
}

static inline void gpio_write(uint8_t val) {

    if (val == 1)
        GPIOC->BSRR = 0x20 << 8;
    else
        GPIOC->BSRR = 0x20 << 24;
}

int main(void) {

    struct rcc* rcc = (void *)0x40021000;

    struct gpioc* gpioc = (void *)0x40011000;

    rcc->APB2ENR |= (1<<4);

    gpioc->CRH &= ~(0x0fU << 20);         // Clear existing setting
    gpioc->CRH |= 0x20 << 16;       // Set new mode 

  for (;;) {
    gpio_write(1);
    spin(999999);
    gpio_write(0);
    spin(999999);
  }
  return 0;
}
```

功能是可以实现的，但是可读性也是几乎没有的。但是这里已经有一些官方库的影子了。

原理上是这些原理，真正的想用起来，还有非常多的细节要去考虑。





