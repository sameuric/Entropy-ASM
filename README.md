   Entropy computation application (v1.0)
============================================

This directory contains a desktop application written in assembly language with MASM32. The application lets the user select a file and computes its Shannon entropy ([units: Sh](https://en.wikipedia.org/wiki/Shannon_(unit))).  Shannon entropy is a measure of the quantity of information of a given source. Although files cannot be considered as pure random sources of bytes, we will assume the bytes in the file are independent. Because most files have a specific format or syntax, the entropy computed with this application will be higher than the theoretical one.  

The main goal of this personal project is to discover assembly language, and build a small desktop application with it.

![screenshot1](https://github.com/user-attachments/assets/a2b8fe3b-e94b-4fa5-80f0-84b2b5f3c7f1)    ![screenshot2](https://github.com/user-attachments/assets/ddaa4009-57cb-4583-a3ed-25385daa51a7)

The screenshots above show the main application window (on the left) and the "About" popup (on the right).


Shannon entropy definition
--------------------------

The theoretical Shannon entropy definition of a random variable $X$ is given by:  
$$\mathrm {H} (X):=-\sum _{x\in {\mathcal {X}}}p(x)\log (p(x))$$

In our study, $x$ represents a byte value between 0 and 255, and $p: \mathcal {X}\to [0,1]$ is the probability of seeing the byte value $x$ in the file. Our program computes file's entropy value based on this definition.


Usage and installation
----------------------

First install MASM32 SDK Version 11 from the official [MASM32 website](https://masm32.com/download.htm). Although you are free to install MASM32 anywhere on your computer, we strongly advice you to install it at the following location:  
```
C:\masm32
```
If you have installed MASM32 on a different location, please make sure to update the MASM32 installation path in `run.bat` on line 27.

Once MASM32 is installed, clone this repository on your computer and click on `run.bat` to automatically build and run the program. You should now see the main window.


Entropy in cybersecurity
------------------------

In the cybersecurity field, entropy can be used to detect potential malware trying to hide themselves from antivirus solutions. Encrypted or obfuscated malware files have high entropy values due to their random looking-like code. Because high-entropy files are not necessarily malware, they might be flagged as suspicious until deeper investigation is conducted.

More information on this topic can be [found here](https://umbrella.cisco.com/blog/using-entropy-to-spot-the-malware-hiding-in-plain-sight).

Future work
-----------

A few ideas to improve this project:
- Add extra explanations on entropy's definition in a separate window.
- Make sure the program works with files bigger than 1 Gb.
- Benchmark the program against another implementation in a high-level language.

License
-------

This work is shared under the [MIT license](LICENSE).  
The program's icon has been taken from the examples codes installed with the MASM32 SDK.
