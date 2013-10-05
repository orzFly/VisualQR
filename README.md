VisualQR
========

a quick, dirty and simple clone of http://www.visualead.com/

Usage
-----
```
Usage: visualqr.rb [options] data bg out
Create QR Code with background image.

    data                             data to be embedded.
    bg                               file name of background image. must be PNG
    out                              file name of output image. will be PNG

Options: 
    -s, --size N                     size of the qrcode, 1~4 (default 4)
               1                       21 * 21,  72 code length
               2                       25 * 25, 128 code length
               3                       29 * 29, 208 code length
               4                       33 * 33, 288 code length
    -l, --level N                    error correction level, 1~4 (default 4)
                1 (:l in rqrcode)       7% of code can be restored
                2 (:m in rqrcode)      15% of code can be restored
                3 (:q in rqrcode)      25% of code can be restored
                4 (:h in rqrcode)      30% of code can be restored
    -m, --modified N                 modified coefficient to make dots more naturual, 0~0.1 (default 0.03 when level is 4, otherwise 0)
    -d, --dotpadding N               padding of dots for background (default 0.25)
    -h, --help                       show this message
        --version                    show version
```
