# LF - List Files

This is a simple command line program that lists files in the current directory prefixed with special characters
that matches the filetypes according to DevIcons patched fonts like those offered by NerdFonts.

It is written in Free Pascal compiled to native code.

Currently, this was only tested on Windows 10 machines, since newer Console hosts
allow to use colored and custom fonts.

## Setup

Just copy and paste the executable `lf.exe` into an accessible directory, like `c:\windows\system32\` or 
add any custom path to Global Variables `PATH`.

To see the `devicons` filetype, you need to install a console monotype font from 
NerdFonts website, and customize your Console window properties changing the default font
to the NerdFonts you chose to install.

## Usage

Type `lf` in your console prompt, and if installed correctly, you will see your files
listed similar to the following snapshot.

![image](https://lh3.googleusercontent.com/1LSS4iYFAKqBWTYJoA4WIO38w2Q9H0MCy1i4qHMGltVT-elyoiYvzarTdwm40IFYxgBfPeYLu_c8xo7cbdTD03eTbNOexjpk9dCMhoUICL05xBUB0-t9LS0pHg9hL1lwao_Bb1kFI3p84odZANj14aeCnzj_38xWjPzBFg56ufr1gPqiwa-IWk30Y9IuuO1M6gpKU_oS3Kze65j5BL00BnmO05NaojJPC-2AVNCOez6JUgnf0lwqDEqrFMq8dMP1voe4qR9dZ64kszlDF1CD8UzeuBEWRAbAxqOexoXLLfaCF9BTsVeqsGzO_PAL6h6aC6eUx3UJIyB0U8MHOiBcr1z_EMVEve3NGBAUqd1GxnlDJ6QfUx-cy_FiXQEKNJWJVINKDe5HR9CJRcROHFVz5pudqAL6_V9jw70UWVEAMzrPBPkVMPlPnTc5GNqBw2xrN0tDdWyZ1seZkEqIMuVLsTg3yWeLl4gt2CUsEX7sUwLX4tpKb7NJclvz6yD9a5dI2T5Bq8Qsbol3tgeLYV8o2tM1Iuzh3qwXMYOCW_YIqzV87hTGAMIcWZoYFHaZFIn3YNItIAsIV_wTKqzLwP-RZNRvB8VT_QdFYgZcnL5xgJqNfUk4HGn7XIZCSWy9Hh-LdO7VK3OPLyQFTGll3Oj4imi0=w625-h626-no)
> Snapshot of lf.exe executed from within CMD running inside VSCode

## Compile

Use Lazarus-ide to compile, the code is crossplatform, so it might work on Linux too, but 
it needs some fixes to correctly list some files.


