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
tmp db "C:\N\hg.txt",0
tmphandle dw ?
DTA FileControlBlock <>
filehandle dw ?
bufferSize = 512
namefile db 13 DUP(?),0
buffer db bufferSize dup(0),0
currsize dd 0
padChar db ?
padnum dd 512

.code
main PROC

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
;
;-------------------------------------------------
clear_str PROC USES CX DI
mov cx , buffersize
mov di , 0
 do:
    
     mov buffer[di] , ' '
	 inc di 
	 
 LOOP do
RET
clear_str ENDP
;------------------------------------------------
;
;-------------------------------------------------
find_first_file PROC
mov ah,4Eh ; find first matching file
mov cx,1
mov dx,offset filespec
int 21h
RET
find_first_file ENDP
;------------------------------------------------
;
;-------------------------------------------------
find_next_file PROC

mov ah, 4Fh
int 21h
jc quit
RET
find_next_file ENDP
;------------------------------------------------
;
;-------------------------------------------------
get_filepath PROC

mov di,offset filespec
mov si,offset namefile

Copy:
cmp byte ptr [di],"*"
je break
mov ax,[di]
mov [si],ax
inc di
inc si
JMP Copy
break:

mov cx,lengthof DTA.fileName
mov di,offset DTA.fileName

Copy2:
mov ax,[di]
mov [si],ax
inc di
inc si
LOOP Copy2

mov ecx , DTA.fileSize
mov currsize , ecx

RET
get_filepath ENDP
;------------------------------------------------
;
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
;
;------------------------------------------------
Padding PROC uses eax edx


mov padChar ,'1'
call pad_bits
inc currsize
mov eax , currsize
mov edx , 0
div padnum
cmp edx , 448
je pad_size
mov ecx , 512
sub ecx , edx
add ecx , 448
add currsize , ecx
;-------------------
Notequal_pad:
	 mov padChar ,'0'
	 call pad_bits
LOOP Notequal_pad 

;--------------------
pad_size:
mov cx , 32
L:
   call dumpregs
  call pad_bits
LOOP L
;-------------------

mov ah , 40h
mov cx , 32
mov bx , filehandle
mov dx ,offset DTA.fileSize
int 21h

add currsize , 64
close : 
mov ah , 3Eh
int 21h

RET
Padding ENDP

;------------------------------------------------
;
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
je close                                          ; read the data  
call writestring 
call clear_str 
                                      
jmp READ

call crlf
call clear_str

close : 
mov ah , 3Eh
int 21h


RET
Readfile ENDP

;------------------------------------------------
;
;-------------------------------------------------
Open_Read_all PROC

CALL find_first_file
jmp Begin

NextFile:
CALL find_next_file

Begin:
CALL get_filepath
CALL Padding
CALL Openfile
CALL Readfile
jmp NextFile

RET
Open_Read_all ENDP

;------------------------------------------------
;
;------------------------------------------------
MoveFile_pointer PROC uses ax

mov ah , 42h
mov al , 2
mov cx , 0
mov dx , 0
int 21h

RET
MoveFile_pointer ENDP
;------------------------------------------------
;
;------------------------------------------------
pad_bits PROC uses EAX EDX

   CALL Openfile
	CALL MoveFile_pointer

     mov ah , 40h
	 mov cx , 1
	 mov dx ,offset padChar
	 int 21h

	 close:
	 mov ah , 3Eh
	 int 21h

RET
pad_bits  ENDP

END main