# HX1k-SDI
An SDI encoder/serializer on Lattice iCE40 FPGAs

## Abstract
This project contains a complete eval board for SDI video generation on
iCE40-HX FPGAs. UP-series might work, but unclear if the IOB and Fabric are fast enaugh
(might test it on iCEBReaker at some point in time).

## Contents
This project consists of the following subfolders:
 * FPGA: the FPGA design (VHDL, iCECube2 project)
 * Hardware: The board design (eagle 6), also schematics diagrams as PDF
 * Firmware: Firmware for the ATSAMD21 MCU that is on the board as well
 * Release: synthesized FPGA config, firmware image, gerbers etc

