format PE console 4.0
entry start


include 'win32a.inc'



section '.code' code readable executable
start:
    ;
    Testloop:



	ccall [printf], InputMessage1
	ccall [gets], Vector1In

	push Vector1In
	push Vector1Solved
	call stringToVector

	;eax contains vector address
	 ;Special register shnenannigans to load qword in one go
	push Vector1Solved
	call solveVector

	push Vector1Solved
	call printVector

	ccall [printf], InputMessage1
	ccall [gets], Vector2In

	push Vector2In
	push Vector2Solved
	call stringToVector

	push Vector2Solved
	call solveVector

	push Vector2Solved
	call printVector

	push FinalVector
	push Vector1Solved
	push Vector2Solved
	call addVector

	push FinalVector
	call printVector


	;add esp, 14 ; c conventions mean that caller cleans stack
	ccall [getchar]


	invoke ExitProcess, 0
printVector:
	push ebp
	mov ebp, esp
	mov esi, [ebp + 8] ;load ebp
	sub esp, 8
	movsd xmm0, [esi + Triangle.VComponent]
	movsd [esp], xmm0

	sub esp, 8
	movsd xmm0, [esi + Triangle.HComponent]
	movsd [esp], xmm0

	sub eax, eax
	mov al, byte [esi + Triangle.EorW]
	push eax

	sub eax, eax
	mov al, byte [esi + Triangle.NorS]
	push eax

	mov eax, dword[esi + Triangle.angle]
	push eax

	mov eax, dword[esi]
	push eax

	push tempformat

	call [printf]  ; print struct
	add esp, 36

	pop ebp
	ret
stringToVector: ;void stringToVector(char* vectorin, Triangle* vectorout)
      ;LOCAL VARIABLES: [ebp-4]: stroffset [ebp-8]: state [ebp - 12] vectorpointer
      push ebp ;save the location of the base pointer
      mov ebp, esp ;ebp now points to the top of the stack

      sub esp, 12 ; Allocate variable space
      mov dword [ebp - 8],  3	  ; acts as selector for terminator, 0= '/0', 1 = ' ', 2 = ' '
      mov dword [ebp - 12], 0	; acts as vector selector ebx + [ebp - 8] = vector address
      mov esi, [ebp + 12] ; move string address to esi
      GetNextNumber:
	dec dword[ebp-8] 
	push esi
	
	; if ecx > 0 push ' ' else push 0
	cmp dword[ebp - 8], 0
	je nullterm
	push ' '
	jmp strlen
	nullterm:
	   push 0
	strlen:
	   call strLen
    
    
	mov [ebp - 4], eax; store length of string as variable
    
	add dword[ebp - 4], 2 ;offset to next part of string
    
	push esi
	push eax
    
	cmp dword[ebp - 8], 0;if [ebp-8] == 0, we have reached the end part of the vector, and expect letters
	jne ifnumbers
	call coordnateToNumbers
    
	;put Coordnate struct in Triangle struct
	;inc dword[ebp-12]
	mov cl, [eax];move location of Coordnate struct
	mov ebx, [ebp + 8];move the location of Triangle struct to ebx
	mov edx, [ebp - 12];move offset to edx
	mov [ebx + edx], cl
    
	inc dword[ebp-12]
	mov cl, [eax+1];move location of Coordnate struct
	mov ebx, [ebp + 8];move the location of Triangle struct to ebx
	mov edx, [ebp - 12];move offset to edx
	mov [ebx + edx], cl
    
	jmp Quit ;We're done!
    
	ifnumbers:
	call toNum
    
    
    
    
	;Load value of vector into slot in loaded struct
    
	mov ebx, [ebp + 8]
	mov edx, [ebp - 12]
	mov [ebx + edx], eax
    
	add dword [ebp - 12], 4;next slot in struct
	add esi, dword [ebp - 4]; esi points to next set of numbers or letters, past space

	jmp GetNextNumber

  Quit:

  mov eax, [ebp + 8]
  add esp, 12
  pop ebp ;base pointer is whatever it was before
  ret 8

;getCharInString: ; char getCharInString(int offset, int address)
       ; push ebp
       ; mov ebp, esp

       ; mov edx, [ebp + 8];edx containst offset
       ; mov ebx, [ebp + 12];ebx contains address
       ; mov ax, [ebx + edx]

       ; pop ebp
       ; ret 8
coordnateToNumbers: ;Coordnate* coordnateToNumbers(int strlen, &char straddress)
    push ebp
    mov ebp, esp
    mov edi, [ebp + 12] ;string address
    mov ecx, [ebp + 8] ; length of string
    ;mov bl, 0 ; ebx acts as pointer for struct
    sub esp, 2; make room for our struct
    coordnateLoop:
    
	mov al, byte[edi + ecx] ;al is at end of string
	
	;Big old switch statement
	cmp al, 'N'
	je caseN
	
	cmp al, 'S'
	je caseS
	
	cmp al, 'E' 
	je caseE
	
	cmp al, 'W'
	je caseW
	
	    caseN:
		mov byte[ebp - 1], 1
		jmp endcase
	    caseS:
		mov byte[ebp - 1], -1
		jmp endcase
	    caseE:
		mov byte[ebp - 2], 1
		jmp endcase
	    caseW:
		mov byte[ebp -2] , -1
		jmp endcase
	endcase:
	    dec ecx
	    cmp ecx, -1
	    jne coordnateLoop

    mov eax, esp
    add esp,2
    pop ebp
    ret 8
	

toNum: ;int toNum(int strlen, &char stradress)
      push ebp ;save the location of the base pointer
      mov ebp, esp ;ebp now points to the top of the stack
      mov ecx, [ebp + 8] ; length of string
      mov edi, [ebp + 12] ; string address
      sub edx, edx ; edx is zero
      sub eax, eax ; eax is zero
      mov ebx, 1;conversion factor

     ConvertToNum:

	mov al, byte[edi + ecx]
	cmp al, '0'
	jl NotANumber
	cmp al, '9'
	jg NotANumber
	sub al, '0'; char to byte
	push edx
	mul ebx
	pop edx

	add edx , eax; add al to result

	;mulitply conversion factor by 10, preserve result register
	push edx
	mov eax, ebx
	mov ebx, 10
	mul ebx
	mov ebx, eax
	pop edx

	dec ecx
	cmp ecx, -1
	jne ConvertToNum

      ;END OF LOOP
      mov eax, edx
      pop ebp
      ret 8;get ret bro

      NotANumber:
      mov eax, -1
      pop ebp
      ret 8

strLen:
      push ebp ;save the location of the base pointer
      mov ebp, esp ;ebp now points to the top of the stack
								     \
      mov edi, [ebp+12]; edi points to beginning of string
      sub ecx,ecx; ecx	= 0
      mov al, [ebp + 8]; al is the null terminator we're looking for
      not ecx; ecx = -1
      cld;direction forward
      repne scasb;magic string length finder
      not ecx; ecx is length of str
      dec ecx; remove null terminator
      dec ecx
      mov eax, ecx

      pop ebp
      ret 8
toRadians:
    push ebp
    mov ebp, esp

    fld qword [conversionconstant];double load from memory
    fild dword[ebp + 8];integer load from memory
    fmulp ; multiply constant and degrees, result is in st0
    pop ebp 
    ret 4
solveVector: 
    push ebp
    mov ebp, esp

    mov esi, [ebp+8];load starting address of struct

    ;VERTICAL COMPONENT
    lea edi, [esi+Triangle.angle] ;get address of angle
    push dword[edi];convert angle to radians
    call toRadians

    fsin;toRadians returns angle in radians to st0, compute sin and st0 contains sin of angle
    lea edi, [esi] ;get hypotenuse
    fild dword[edi] ;load it
    fmulp ;multiply sin and hypotenuse to get vertical component

    sub eax, eax ;zero out eax
    mov al, byte[esi+Triangle.NorS]
    cmp al, -1
    jne NotSouth

    fld [negativeone]; dword complete
    fmulp

    NotSouth:

    lea edi, [esi + Triangle.VComponent] ; go to VComponent
    fstp qword[edi] ;load result to VComponent

    ;HORIZONTAL COMPONENT
    lea edi, [esi+Triangle.angle] ;get address of angle
    push dword[edi];convert angle to radians
    call toRadians

    fcos;toRadians returns angle in radians to st0, compute sin and st0 contains sin of angle
    lea edi, [esi] ;get hypotenuse
    fild dword[edi] ;load it
    fmulp ;multiply sin and hypotenuse to get vertical component

    ; move NorS into 4 bits of eax

    sub eax, eax
    mov al, byte[esi+Triangle.EorW]
    cmp al, -1

    jne NotWest

    fld [negativeone] ; dword complete
    fmulp

    NotWest:
    ;fild dword[esp+8]
    ;fmul st0, st1

    lea edi, [esi + Triangle.HComponent] ; go to VComponent
    fstp qword[edi] ;load result to VComponent

    ;8add esp, 8 ;remove local variables

    pop ebp
    ret 4 ; 1 variable

addVector: ;Triangle addVector(Triangle Vector1, Triangle Vector2, Triangle* FinalVector)
    push ebp
    mov ebp, esp
    ;sub esp, 26; allocate space for new Triangle

    mov esi, [ebp + 8]; load address of first struct
    mov edi, [ebp + 12]; load address of second struct
    mov eax, [ebp + 16]; load address of final struct

    ;HORIZONTAL
    fld qword[esi + 10];load Hcomponent of first Triangle
    fld qword[edi + 10];load Hcomponent of second Triangle

    faddp ; add them, result is in st0
    fld [zero]
    fcomip st0, st1  ; compare st0 with 0

    jl horizontalNegative ;if st0 is less than zero we set EorW to -1
    mov byte[eax + Triangle.EorW], 1
    jmp endHorizontalNegative
    horizontalNegative:
	mov byte[eax + Triangle.EorW], -1

    endHorizontalNegative:

    fstp qword[eax + 10] ;load hcomponent into new struct
    ;END HORIZONTAL

    ;VERTICAL
    fld qword[esi + Triangle.VComponent]
    fld qword[edi + Triangle.VComponent]

    faddp
    fcomi st0, st1

    jl verticalNegative
    mov byte[eax + Triangle.NorS], 1
    jmp endVerticalNegative
    verticalNegative:
	mov byte[eax + Triangle.NorS], -1

    endVerticalNegative:

    fstp qword[eax + 18]
    ;END VERTICAL

    fld qword[eax+Triangle.HComponent]
    fld qword[eax+Triangle.VComponent]
    fdivp

    push eax
    push esi
    push edi

    ;push Opposite/Ajacent
    sub esp, 8
    fstp qword[esp]


    ;preserve registers before calling atan2


    call [atan]; find angle on final Triangle

    add esp, 8; clean stack

    pop edi
    pop esi
    pop eax



    sub esp, 8

    fst qword[esp]; save angle value for later

    ;h = o/sin(angle)
    ;fsin
    ;fld qword[eax + Triangle.VComponent]
    ;fdivp
    ;fistp dword[eax] ; load into hypotenuse

    ;convert angle to degrees
    fld qword[esp]
    fld [oneeighty]
    fmulp

    fld [pi]
    fdivp

    fistp dword [eax + Triangle.angle];copy angle into angle slot
    add esp , 8

    ;sqrt(a^2+b^2) = c
    fld qword [eax + Triangle.HComponent]
    fmul st0, st0
    fld qword [eax + Triangle.VComponent]
    fmul st0, st0
    faddp
    fsqrt
    fistp dword[eax]


    pop ebp
    ret 12

section '.rdata' data readable
	InputMessage1 db "Input vector in form of [magnitude][space][angle][space][N or S] [E or W]", 10, 0
	tempformat db "Hypotenuse: %d, Angle: %d, Vertical Direction: %d, Horizontal Direction: %d, Horizontal Component: %f, Vertical Component: %f",10,0
	conversionconstant dq 0.0174532925
	negativeone dq -1.0
	pi dq 3.14159265359
	oneeighty dq 180.0
	zero dq 0

section '.rwdata' data readable writeable
	;size of Triangle 26 bytes
	struct Triangle
	       hypotenuse rd 1	;+0
	       angle rd 1	;+4
	       ;Incremented an address where I shouldn't have
	       NorS rb 1	;+8
	       EorW rb 1	;+9



	       HComponent rq 1	;+10
	       VComponent rq 1	;+18
	ends


	Vector1In rb 7
	Vector2In rb 7

	Vector1Solved Triangle
	Vector2Solved Triangle

	FinalVector Triangle

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
	atan, 'atan'