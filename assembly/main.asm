Include irvine16.inc

FileControlBlock struc
db 22 dup(?) ; header info 
fileTime dw ? ; time stamp of file
fileDate dw ? ; date stamp of file
fileSize dd ? ; size of file
fileName db 13 dup(0) ; name of file found by DOS
FileControlBlock ends

.data
filespec db "C:\N\*.txt",0
DTA FileControlBlock <>
filehandle dw ?
bufferSize = 64
namefile db 13 DUP(?),0
buffer db bufferSize dup(0),0
currsize dw 0
padnum db buffersize dup(0)
.code
main PROC

;-----------------------
;Intialize datasegment
;-----------------------
mov ax,@data       ; initialize DS
mov ds,ax
mov ah,1Ah           ; set transfer address
mov dx,offset DTA
int 21h


call Open_Read_all

quit::

mov ax , '#'
call writechar
call crlf
.EXIT 
main ENDP

;------------------------------------------------
;clear_str PROC
;intialize buffer by 0 
;
;-------------------------------------------------
clear_str PROC USES CX DI
mov cx , buffersize
mov di , 0
 do:
    
     mov buffer[di] , 0
	 inc di 
	 
 LOOP do
RET
clear_str ENDP
;------------------------------------------------
;get first matched file with the given path
;
;-------------------------------------------------

Find_first_file PROC

mov ah , 4Eh                            ;Dos function search for 1st matching file
mov cx , 1
mov dx , offset filespec                ;given path
int 21h                                 ; call Dos
RET
Find_first_file ENDP

;------------------------------------------------
; find next matched files
;-------------------------------------------------
Find_next_file PROC

mov ah, 4Fh
int 21h
jc quit

RET
Find_next_file ENDP
;------------------------------------------------
;append file name found to the path to open it
;-------------------------------------------------
get_filepath PROC

mov di,offset filespec
mov si,offset namefile

Copy:
cmp byte ptr [di],"*"            ;loop to copy path into namefile var
je break
mov ax,[di]
mov [si],ax
inc di
inc si
JMP Copy
break:

mov cx,lengthof DTA.fileName
mov di,offset DTA.fileName

Copy2:                          ;loop to append filename found to the path
mov ax,[di]
mov [si],ax
inc di
inc si
LOOP Copy2

RET
get_filepath ENDP
;------------------------------------------------
;take the path and open the file
;-------------------------------------------------
Openfile PROC

mov ah,3Dh                   ;  open file
mov al,2                     ; choose the input mode
mov dx,offset namefile
int 21h                      ; call DOS
jc quit
mov filehandle,ax  
mov bx , filehandle          ; no error: save the handle

RET
Openfile ENDP

;------------------------------------------------
; read the opened file
;------------------------------------------------

Readfile PROC

READ :

mov ah,3Fh                                      ; read from file or device
mov bx,filehandle                               ; BX = file handle
mov cx,  buffersize                             ; number of bytes to read 
mov dx,offset buffer                            ; point to buffer                                              
int 21h  
jc quit
cmp ax , 0
je Done 
mov currsize , ax 
; call encryption                                       
call writestring 
call clear_str                                     
jmp READ

Done:
call crlf 
call Padding
closeFile:
mov ah , 3Eh
int 21h


RET
Readfile ENDP

;------------------------------------------------
; main function that call other functions
;-------------------------------------------------
Open_Read_all PROC

CALL find_first_file
jmp Begin

NextFile:
CALL find_next_file

Begin:
CALL get_filepath
CALL Openfile
CALL Readfile
CALL Write_encrypted_msg
jmp NextFile

RET
Open_Read_all ENDP

;------------------------------------------------
;padding function
;------------------------------------------------

Padding PROC uses EBX

cmp currsize , 64
je pad_size

mov  DI , currsize
or   buffer[DI] , 80h

;call encryption

pad_size:

call clear_str

mov SI , 60
mov ECX , 4
mov DI , 0

DO:                                     ;loop to append size of the file in the last 4 bytes
mov bl , byte ptr [DTA.fileSize[DI]]
mov buffer[SI] , bl
inc SI
inc DI
LOOP DO

; call encryption
RET
Padding ENDP
;------------------------------------------------
;After encryption it clear the content of the 
;file and write the new encrypted msg
;------------------------------------------------

Write_encrypted_msg PROC

Repalce_file:
mov AH , 3Ch
mov CX , 0
mov DX , offset namefile
int 21h
jc quit

mov filehandle , AX


write_msg:
mov AH , 40h
mov CX , 16
mov DX , offset buffer
call crlf
mov BX , filehandle
int 21h
jc quit

closeFile:
mov AH , 3Eh
int 21h
RET
Write_encrypted_msg ENDP

END main