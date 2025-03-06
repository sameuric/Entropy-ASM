comment *
    -------------------------------------------------------------------
    Entropy Computation Application v1.0
    -------------------------------------------------------------------

    This application has been written in assembly language and computes
    the Shannon entropy of any file selected by the user. It also
    includes a small "About" window providing some basic information.

    The goal of this personal project is to discover and learn how to
    write a small desktop application in assembly language with MASM32.

    Program written for learning purposes only.

    Microsoft Macro Assembler version: 6.14.8444
    й 2025 Sacha Meurice
ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл *

.486
.model flat, stdcall
option casemap: none

include \masm32\include\masm32rt.inc



;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;  Constant values using EQU directives
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

ID_ICON   equ   500
ID_ABOUT  equ   501
ID_EDIT   equ   502
ID_BWSE   equ   503
ID_CALC   equ   504
ID_TEXT   equ   505

; Buttons width and height
BTN_W     equ   40
BTN_H     equ   12

NOSTYLE   equ   0

; Text descriptions showed to the user
DLG_DESC1 equ <"This application computes the entropy of a given file.", 32, \
               "Please type a path file below or try to search one from your computer.">

ABT_DESC1 equ <"Entropy Computation Application ", 13, "Written in MASM32 Assembly">
ABT_DESC2 equ <"This application allows you to compute", 13, "the entropy value of a given file.">
ABT_DESC3 equ <"Made by Sacha Meurice", 13, "Copyright й 2025 ">



;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;  Macros and function prototypes
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

; Macro for nesting invoke calls in other statements
INVK MACRO params:VARARG
    invoke params
    exitm <eax>
ENDM


DlgProc    PROTO  :DWORD, :DWORD, :DWORD, :DWORD
DlgAbout   PROTO  :DWORD

SelectFile PROTO  :DWORD
ReadSFile  PROTO  :DWORD    ; Read Selected File

ComputeEntropy  PROTO  :DWORD, :DWORD



;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;  Memory data segments and uninitialized values
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

.const
    DEFAULT_LOC   BYTE    "C:\example.txt", 0
    FILENOTFOUND  BYTE    "The selected file does not exist!", 0
    FILEEMPTY     BYTE    "File's location is empty!", 0
    FILETOOBIG    BYTE    "File's size cannot exceed 1 Gb!", 0
    POPUPERROR    BYTE    "An error occurred!", 0

    ; Must end with two NULL characters
    ; https://learn.microsoft.com/en-us/windows/win32/api/commdlg/ns-commdlg-openfilenamea
    F_FILTER      BYTE    "All files", 0, "*.*", 0, 0


.data
    entText       BYTE      64 DUP(0)
    entFmt        BYTE      "Entropy:  %lf Sh", 0
    emptyFmt      BYTE      "Entropy:", 0
    entropy       REAL8     0.0
    histo         DWORD     256 DUP(0)


.data?
    filePath      TCHAR     MAX_PATH DUP(?)
    readSize      DWORD     ?
    hInstance     DWORD     ?
    hIcon         DWORD     ?

    ; Structure used by the browse dialog box
    ofn    OPENFILENAME     {?}

    ; Probability in entropy formula
    Px            REAL8     ?



;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;  Program's starting point
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

.code
start:

    ; Dialog creation
    mov hInstance, INVK(GetModuleHandle, NULL)
    mov hIcon,     INVK(LoadIcon, hInstance, ID_ICON)

    Dialog "Entropy computation", "MS Shell Dlg 2", 10, \
            WS_SYSMENU or WS_MINIMIZEBOX, \
            8, \                    ; Number of Dialog controls
            200, 120, 190, 100, \   ; X, Y, width and height
            2048                    ; Memory buffer size


    DlgIcon ID_ICON, 10, 7, 0

    DlgStatic DLG_DESC1, \
              NOSTYLE, 37, 8, 140, 30, 0

    DlgEdit WS_BORDER or ES_AUTOHSCROLL, 37, 40, 99, 11, ID_EDIT
    DlgButton "Browse...", BS_DEFPUSHBUTTON, 140, 40, BTN_W, BTN_H, ID_BWSE

    DlgStatic 'Entropy: ', \
              NOSTYLE, 37, 55, 120, 10, ID_TEXT


    ; Bottom buttons
    DlgButton "OK", BS_DEFPUSHBUTTON, 106, 70, 35, BTN_H, ID_CALC
    DlgButton "Quit", BS_DEFPUSHBUTTON, 145, 70, 35, BTN_H, IDCANCEL
    DlgButton "About...", BS_DEFPUSHBUTTON, 8, 70, 35, BTN_H, ID_ABOUT


    CallModalDialog hInstance, 0, DlgProc, hIcon
    invoke ExitProcess, 0



;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;  Build a histogram and compute the entropy from it
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

ComputeEntropy proc pData:DWORD, sData:DWORD

    ; Histogram computing
    ; -------------------

    xor ecx, ecx

    ; Reset entropy value
    finit
    fldz
    fstp entropy

    ; Reset previous histogram values
    push SIZEOF histo
    push 0
    push OFFSET histo

    call crt_memset
    add esp, 12     ; Clean stack

    ; Initialize address to file's bytes
    mov ebx, pData


_nextByte:
    ; Increase the histogram value corresponding to the byte
    movzx eax, BYTE PTR [ebx + ecx]
    inc DWORD PTR [histo + 4*eax]

    ; Check if all bytes have been processed
    inc ecx
    cmp ecx, sData
    jne _nextByte



    ; 2. Entropy computing
    ; --------------------

    xor ecx, ecx

_nextValue:
    ; Avoid division by zero
    cmp DWORD PTR [histo + ecx], 0
    jz _continue


    ; Compute the probability Px
    fild DWORD PTR [histo + ecx]
    fild sData
    fdiv
    fstp Px


    ; Compute Px*log(Px)
    fld1
    fld Px
    fyl2x
    fld Px
    fmul


    ; Update entropy value
    fld entropy
    fsub st(0), st(1)
    fstp entropy
    fstp st(0)  ; Clean stack


    ; Iterate over all histogram
_continue:
    add ecx, SIZEOF DWORD
    cmp ecx, SIZEOF histo
    jne _nextValue


    ; Format result in entText
    push DWORD PTR [entropy + 4]
    push DWORD PTR [entropy]
    push OFFSET entFmt
    push OFFSET entText

    call crt_sprintf
    add esp, 16     ; Clean stack

    xor eax, eax
    ret

ComputeEntropy endp






;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;  Common dialog procedure (used for both windows)
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

DlgProc proc hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD

    .if uMsg == WM_INITDIALOG
        invoke SendMessage, hWin, WM_SETICON, 1, lParam
        invoke SetDlgItemText, hWin, ID_EDIT, addr DEFAULT_LOC

    .elseif uMsg == WM_COMMAND
        .if wParam == ID_ABOUT
            invoke DlgAbout, hWin

        ; Browse computer files
        .elseif wParam == ID_BWSE
            invoke SelectFile, hWin

        ; Compute Shannon entropy
        .elseif wParam == ID_CALC
            ; Reset entropy value showed to the user
            invoke SetDlgItemText, hWin, ID_TEXT, addr emptyFmt

            ; Read selected file and show its entropy
            invoke ReadSFile, hWin

        .elseif wParam == IDCANCEL
            invoke EndDialog, hWin, 0
        .endif

    .elseif uMsg == WM_CLOSE
        invoke EndDialog, hWin, 0
    .endif

    xor eax, eax
    ret
DlgProc endp



;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;  Dialog for the "About..." window
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

DlgAbout proc hParent:DWORD

    Dialog "About this application...", "MS Shell Dlg 2", 10, \
            DS_CENTER, 5, \     ; Number of dialog items
            0, 0, 175, 90, \    ; X, Y, width and height
            1024                ; Memory buffer size

    DlgStatic ABT_DESC1, \
              NOSTYLE, 33, 7, 150, 20, 0

    DlgStatic ABT_DESC2, \
              NOSTYLE, 33, 27, 150, 20, 0

    DlgStatic ABT_DESC3, \
              NOSTYLE, 33, 47, 150, 20, 0


    DlgButton "OK", BS_DEFPUSHBUTTON, 122, 57, BTN_W, BTN_H, IDCANCEL
    DlgIcon ID_ICON, 8, 6, 0

    CallModalDialog hInstance, hParent, DlgProc, NULL

    xor eax, eax
    ret
DlgAbout endp





;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;  Procedure to select a file from the computer
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

SelectFile proc hWin:DWORD

    ; Set the window that owns the dialog box
    mov eax, hWin
    mov ofn.hwndOwner, eax

    ; Reset previous selected file
    push SIZEOF filePath
    push 0
    push OFFSET filePath

    call crt_memset
    add esp, 12     ; Clean stack

    ; Initialize the OPENFILENAME structure
    mov ofn.lStructSize, SIZEOF OPENFILENAME
    mov ofn.lpstrFile, OFFSET filePath
    mov ofn.nMaxFile, SIZEOF filePath
    mov ofn.lpstrFilter, OFFSET F_FILTER

    mov ofn.nFilterIndex, 1
    mov ofn.Flags, OFN_FILEMUSTEXIST

    ; Open browse dialog
    invoke GetOpenFileName, OFFSET ofn

    ; Set text on ID_EDIT
    invoke SetDlgItemText, hWin, ID_EDIT, addr filePath

    ; Reset entropy value showed to the user
    invoke SetDlgItemText, hWin, ID_TEXT, addr emptyFmt

    xor eax, eax
    ret
SelectFile endp





;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
;  Procedure to select a file from the computer
;лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

ReadSFile proc hWin:DWORD

    LOCAL hFile         :DWORD
    LOCAL pFileData     :DWORD
    LOCAL fileSize      :DWORD

    ; Get text value from EDIT control box
    invoke GetDlgItemText, hWin, ID_EDIT, addr filePath, SIZEOF filePath
    cmp eax, 0
    jnz @F

    invoke MessageBox, hWin, addr FILEEMPTY, addr POPUPERROR, MB_OK or MB_ICONERROR
    mov eax, 1
    ret

@@:
    ; Check if the file exists on the computer
    invoke GetFileAttributes, addr filePath
    cmp eax, INVALID_FILE_ATTRIBUTES
    jne @F

    invoke MessageBox, hWin, addr FILENOTFOUND, addr POPUPERROR, MB_OK or MB_ICONERROR
    mov eax, 2
    ret

@@:
    ; Open the file, get its size and allocate memory to store its content
    mov hFile, INVK(CreateFile, addr filePath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
    mov fileSize, INVK(GetFileSize, hFile, NULL)
    mov pFileData, INVK(GlobalAlloc, GPTR, fileSize)

    ; Check file's size and return if it exceeds 1 Gb
    cmp fileSize, 1073741824
    jbe @F

    invoke MessageBox, hWin, addr FILETOOBIG, addr POPUPERROR, MB_OK or MB_ICONERROR
    invoke GlobalFree, pFileData     ; Do not forget to free memory ressources
    invoke CloseHandle, hFile

    mov eax, 3
    ret

@@:
    ; Read file content and compute its entropy
    invoke ReadFile, hFile, pFileData, fileSize, addr readSize, NULL
    invoke ComputeEntropy, pFileData, readSize

    ; Show computed entropy value to the user
    invoke SetDlgItemText, hWin, ID_TEXT, addr entText

    ; Free memory ressources
    invoke GlobalFree, pFileData
    invoke CloseHandle, hFile

    xor eax, eax
    ret
ReadSFile endp
end start
