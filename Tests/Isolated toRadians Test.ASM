format PE console 4.0
entry start


include 'win32a.inc'

section '.code' code readable executable
start:
	ccall  [gets], inputstring
	ccall  [atoi], inputstring

	push eax
	call toRadians

	fstp [result]

	sub esp, 8

	;Special register shnenannigans to load qword in one go
	movsd xmm0, [result]
	movsd [esp], xmm0

	push formatstring

	call [printf]


	ccall [getchar]


	invoke ExitProcess, 0
toRadians:
    push ebp
    mov ebp, esp

    fld qword [conversionconstant];double load from memory
    fild dword[ebp + 8];integer load from memory
    fmul st0, st1; multiply constant and degrees, result is in st0
    pop ebp 
    ret 4

section '.rdata' data readable
	conversionconstant dq 0.0174532925
	formatstring db "%f",0

section '.rwdata' data readable writeable
	inputstring rb 8
	result rq 1
section '.idata' data readable import

library kernel32, 'kernel32.dll', \
	msvcrt,   'msvcrt.dll'

	import kernel32,\
	ExitProcess, 'ExitProcess'

	import msvcrt,\
	printf, 'printf',\
	gets, 'gets',\
	atoi, 'atoi',\
	getchar, 'getchar'