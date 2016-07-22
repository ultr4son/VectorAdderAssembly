format PE console 4.0
entry start


include 'win32a.inc'

section '.code' code readable executable
start:

	mov eax, dword [conversionconstant + 4]
	push eax
	mov eax, dword [conversionconstant]
	push eax
	push tempformat

	call [printf]
	add esp, 12
	ccall [getchar]


	invoke ExitProcess, 0

section '.rdata' data readable
      tempformat db "%f",0
      conversionconstant = 45.5
section '.rwdata' data readable writable
	stringout rb 8
section '.idata' data readable import

library kernel32, 'kernel32.dll', \
	msvcrt,   'msvcrt.dll'

	import kernel32,\
	ExitProcess, 'ExitProcess'


	import msvcrt,\
	printf, 'printf',\
	gets, 'gets',\
	atof, 'atof',\
	getchar, 'getchar',\
	gcvt, 'gcvt'