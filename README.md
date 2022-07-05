# HX1k-SDI
An SDI encoder/serializer on Lattice iCE40 FPGAs

The iCE40 series of FPGAs is low cost and is supported by an opensource toolchain (though not currently used for this project)
The devices are low density and low speed and lack advanced features like SerDes or true LVDS-IO, though.

## Abstract
This project implements an SD-SDI serializer (aka transmitter) completely in fabric, requiring nothing but an unused PLL
that is used to generate a 135MHz from an externally supplied 27MHz sample clock (27MWords/s with CbYCrY 4:2:2 encoding, 
13.5MHz pixel clock).
Most of the logic operates at 27MHz with just the final multiplexer and a DDR-out buffer running at the full 135MHz.

![board](board.jpg)

## Features of the test board
 * iCE40HX1k FPGA
 * 27MHz crystal oscillator
 * 10bit bt.656 video port
 * TVP5151 video decoder to test analog to sdi conversion
   * alternatively/additionally an LMH1881 can be fitted
 * 1MByte (512kx16) of SRAM taht can hold one complete frame of interlaced PAL/NTCS
 * ATSAMD21G18 MCU for programming the FPGA config flash and configuring the TVP, can be omitted
 * 4-pin header for I2C 128x32 OLED display
 * FPGA config pins on pinheader to allow flashing the config without a MCU
 * switchmode regulator for the 3.3V rail, allows input voltages of 5 to 12V
* Current functionality in the FPGA demo project
   * Color bars generator
   * SDI pathological pattern generator
   * Analog to SDI converter
   * About half the FPGA is still free for additional functionality

## Scope
This project contains a complete eval board for SDI video generation on
iCE40-HX FPGAs. UP-series might work, too, but it's unclear if the IOB and Fabric are fast enaugh
(might test it on iCEBreaker at some point in time).

## Contents
This project consists of the following subfolders:
 * fpga: the FPGA design (VHDL, iCECube2 project)
 * hardware: The board design (eagle 6), schematic diagrams as PDF
 * firmware: Firmware for the ATSAMD21 MCU that is on the board as well
 * release: synthesized FPGA config, firmware image, gerbers etc

