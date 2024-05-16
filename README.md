# Veridian
Veridian is an GUI library for MS-DOS written in Turbo Pascal 7 using the Alaveri Pascal Library (APL).  It supports VGA/SVGA 256, proportional fonts, windows, menus, buttons and other GUI controls (early version under development).  Currently Veridian is very usable in 320x200 mode on 386+ class machines.  For SVGA 640x480 or higher, at least a 486DX-2 66 is recommended, and for higher resolutions a Pentium-class CPU is best (but not required).  I am currently developing using DOSBOX-Staging (![https://github.com/dosbox-staging/dosbox-staging](https://github.com/dosbox-staging/dosbox-staging)).  I am verifying functionality using 86Box (![https://86box.net/](https://86box.net)) and the CuteMouse driver (![https://cutemouse.sourceforge.net](https://cutemouse.sourceforge.net)).  Veridian supports mouse-wheel scrolling using either of these environments, although mouse wheels were non-existent in the time period I am targetting (early 90s DOS), as long as the mouse is configured as having buttons+wheel.  It also works in standard DOSBOX and DOSBOX-X, and should work with any period accurate machine.  A video card with VBE (Vesa Bios Extensions) is required for SVGA support, but any VGA card can run it at 320x200. Many cards supported this standard including S3 Vision and Trio cards, Tseng Labs ET-4000, and almost all newer cards like Matrox Millenium, 3DFX Voodoo 3, etc.  Only version 1 of VBE is required for SVGA, meaning even early VBE cards should work.

Veridian runs under MS-DOS in Real Mode, and can access XMS memory using the XMS 1-3 specification.  The TMemoryStream class from the APL allows data larger than 64k to be stored and swapped in and out of XMS as needed.  Below are some screenshots of early development of Veridian.  The program is a version of the code from the TileEdit repository, and both of these projects are being developed together.  Note that these screenshots are not meant to demonstrate a fully functional program, but only some of the early capabilities of Veridian.

Veridian in SVGA 640x480x256 color:

<img src="ScreenShots/Veridian1.png" style="width:300px" /> <img src="ScreenShots/Veridian2.png" style="width:300px" /> <img src="ScreenShots/Veridian3.png" style="width:300px" />

Veridian in VGA 320x200x256 color:

<img src="ScreenShots/Veridian4.png" style="width:300px" /> 

Veridian in SVGA 1024x768x256 color:

<img src="ScreenShots/Veridian5.png" style="width:300px" />
