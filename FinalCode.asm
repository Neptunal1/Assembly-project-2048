IDEAL
MODEL small
STACK 100h
P386


DATASEG
;-------------
;bmp photos 

	imgFirstScreen db 'first.bmp',0         ;First screen (Home page)
    imgHowToPlay db 'howTplay.bmp',0        ;How To play Screen
    imgMenu db 'menu.bmp',0                 ;Menu Screen
    imgAboutMe db 'aboutme.bmp',0           ;Abot me Screen
    imgWin db 'won.bmp',0                   ;Won Screen
    imgLose db 'lose.bmp',0                 ;Lose Screen
    imgbackg db 'backg.bmp', 0            ;Back Screen during the game

;Cells Bmp

    Cell0 db '0pic.bmp',0 
    Cell2 db '2pic.bmp',0
    Cell4 db '4pic.bmp',0
    Cell8 db '8pic.bmp',0
    Cell16 db '16pic.bmp',0
    Cell32 db '32pic.bmp',0
    Cell64 db '64pic.bmp',0 
    Cell128 db '12pic.bmp',0
    Cell256 db '25pic.bmp',0
    Cell512 db '51pic.bmp',0
    Cell1024 db '10pic.bmp',0
    Cell2048 db '20pic.bmp',0 


;Vars For Yellow screen:
	ii dw 0
	xx dw 0
	yy dw 0
	colorr db 0

; bmp Vars --------------------------------

    original dw 0
    wentdown dw 0
    wentleft dw 0
    width1 dw 0
    height dw 0
    x dw 0
    y dw 0
    color db 6

	offsetimg dw ?
	imgwidth dw  ?
	imgHeight dw ?
	adjustCX dw ?
	filename db 20 dup (?)
	filehandle dw ?
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	Errormsg db 'Error', 13, 10, '$'
	printAdd dw ?
;------------------------------

;array 

	BlockArr dw 2,4,8,16 ,32,64,128,256 ,512,1024,2048,0 ,0,0,0,0 ; we Can put in this arr all cells as 0, it doesn't metter

	PassArray dw 0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,0,0,0,0

;variables 


    currentPlace dw 1           ;For menu Proc

	moveVar dw 0                ;For moves Proc

	randNum dw ?                    ;For random procs

	key db ?                    ;get A key 

	CheckLose dw 0              ;Counter to 8 and Check if The player cant move

	CheckWin dw 0               ;Check IF the player reach to 2048

    stor dw 0                   ;teder

    temp dw 1                   ;Delay Sound

;Code Starts:


CODESEG
;BMP ^^^^^^^^^^^^^^^^
PROC PrintBmp
    push bx
    push cx

    push di
    push si
    push cx
    push ax

    
    xor di, di
    mov di, ax
    mov si, offset filename
    
    mov cx, 20
copy:
    mov al, [di]
    mov [si], al
    inc di
    inc si
    loop copy
    

    pop ax
    pop cx
    pop si
    pop di
    
    call OpenFile
    call ReadHeader
    call ReadPalette
    call CopyPal
    call CopyBitMap
    call CloseFile
    
    pop cx
    pop bx
    
    ret
ENDP PrintBmp
PROC OpenFile
    mov ah,3Dh
    xor al,al ;for reading only
    mov dx, offset filename
    int 21h
    jc OpenError
    mov [filehandle],ax
    ret
OpenError:
    mov dx,offset Errormsg
    mov ah,9h
    int 21h
    ret
endp OpenFile
PROC ReadHeader
    ;Read BMP file header, 54 bytes
    mov ah,3Fh
    mov bx,[filehandle]
    mov cx,54
    mov dx,offset Header
    int 21h
    ret
endp ReadHeader
PROC ReadPalette
    ;Read BMP file color palette, 256 colors*4bytes for each (400h)
    mov ah,3Fh
    mov cx,400h
    mov dx,offset Palette
    int 21h
    ret
ENDP ReadPalette
PROC CopyPal
    ; Copy the colors palette to the video memory
    ; The number of the first color should be sent to port 3C8h
    ; The palette is sent to port 3C9h
    mov si,offset Palette
    mov cx,256
    mov dx,3C8h ;port of Graphics Card
    mov al,0 ;number of first color
    ;Copy starting color to port 3C8h
    out dx,al
    ;Copy palette itself to port 3C9h
    inc dx
PalLoop:
    ;Note: Colors in a BMP file are saved as BGR values rather than RGB.    
    mov al,[si+2] ;get red value
    shr al,2    ; Max. is 255, but video palette maximal value is 63. Therefore dividing by 4
    out dx,al ;send it to port
    mov al,[si +1];get green value
    shr al,2
    out dx,al   ;send it
    mov al,[si]
    shr al,2
    out dx,al   ;send it
    add si,4    ;Point to next color (There is a null chr. after every color)
    loop PalLoop
    ret
endp CopyPal
PROC CopyBitMap
    ; BMP graphics are saved upside-down.
    ; Read the graphic line by line ([height] lines in VGA format),
    ;displaying the lines from bottom to top.
    mov ax,0A000h ;value of start of video memory
    mov es,ax
    
    push ax
    push bx
    mov ax, [imgWidth]
    mov bx, 4
    div bl
    
    cmp ah, 0
    jne NotZero
Zero:
    mov [adjustCX], 0
    jmp Continue
NotZero:
    mov [adjustCX], 4
    xor bx, bx
    mov bl, ah
    sub [adjustCX], bx
Continue:
    pop bx
    pop ax
    
    mov cx, [imgHeight] ;reading the BMP data - upside down
    
PrintBMPLoop:
    push cx
    
    xor di, di
    push cx
    dec cx
    Multi:
        add di, 320
        loop Multi
    pop cx

    add di, [printAdd]

    mov ah, 3fh
    mov cx, [imgWidth]
    add cx, [adjustCX]
    mov dx, offset ScrLine
    int 21h
    ;Copy one line into video memory
    cld ;clear direction flag - due to the use of rep
    mov cx, [imgWidth]
    mov si, offset ScrLine
    rep movsb   ;do cx times:
                ;mov es:di,ds:si -- copy single value form ScrLine to video memory
                ;inc si --inc - because of cld
                ;inc di --inc - because of cld
    pop cx
    loop PrintBMPLoop
    ret
endp CopyBitMap
PROC CloseFile
    mov ah,3Eh
    mov bx,[filehandle]
    int 21h
    ret
endp CloseFile
PROC PrintCell
    push ax
    
    mov ax, [offsetimg]
    mov [imgWidth], 40
    mov [imgHeight], 40

    call PrintBmp
    
    pop ax
    ret
ENDP PrintCell
;BMP ^^^^^^^^^^^^^^^^


;-------------------------------------------------------------------------
PROC GraphicsMode ;Enter Graphics Mode: 
	push ax
	
	mov ax, 13h
	int 10h
		
	pop ax
	ret
endp GraphicsMode
PROC TextMode ;Enter Text Mode:
	push ax
	
	mov ax, 2h
	int 10h
	
	pop ax
	ret
endp TextMode
PROC clear_screen ;Clear screen to black screen

    push ax
    push bx
    push cx
    push dx

    mov ax,0600h
    mov bh,0
    mov cx,0h
    mov dx,184fh
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax

    ret

ENDP clear_screen
;-------------------------------------------------------------------------

;Sounder 
PROC move_sound
    mov [temp],1
    mov ax, 150
    mov [stor],ax
    call sounder

ret
ENDP move_sound
PROC Sounder

    mov al,10110110b         ;load control הכנה לטעון
    out 43h,al             ;send a new countdown value
    mov ax,[stor]              ;tone frequency
    out 42h,al    ;send LSB
    mov al,ah    ;move MSB to AL
    out 42h,al    ;save it
    in al,61h               ;get port 61 state
    or al,00000011b           ;turn on speaker
    out 61h,al    ;speaker on now
    call delay    ;pause
    and al,11111100b            ;clear speaker enable
    out 61h,al    ;speaker off now

ret
ENDP sounder
PROC Delay

    mov ah,00h    ;function 0 - get system timer tick
    int 01Ah             ;call ROM BIOS time-of-day services
    add dx,[temp]            ;add our delay value to DX
    mov bx,dx    ;store result in BX
    pozz:
		int 01Ah            ;call ROM BIOS time-of-day services
		cmp dx,bx    ;has the delay duration passed?
		jl pozz            ;no, so go check again

ret
ENDP Delay
PROC Win_sound

    mov ax, 5000
    mov [stor],ax
    mov [temp],5
    call sounder
    mov [temp],1
    call delay

    mov ax, 4000
    mov [stor],ax
    mov [temp],4
    call sounder
    mov [temp],1
    call delay
    mov ax, 3000
    mov [stor],ax
    mov [temp],3
    call sounder
    mov [temp],1
    call delay
    mov ax, 2000
    mov [stor],ax
    mov [temp],2
    call sounder



    ret
ENDP Win_sound
PROC Lose_sound

    mov ax, 4000
    mov [stor],ax
    mov [temp],4
    call sounder
    mov [temp],1
    call delay

    mov ax, 5000
    mov [stor],ax
    mov [temp],5
    call sounder
    mov [temp],1
    call delay
    mov ax, 6000
    mov [stor],ax
    mov [temp],6
    call sounder
    mov [temp],1
    call delay
    mov ax, 7000
    mov [stor],ax
    mov [temp],7
    call sounder
    ret
ENDP Lose_sound


;
PROC Random                         ;Make Random:
	push ax 
	push dx

	mov ah, 2ch
	int 21h ;
	mov ax, dx ; DL = houonders of seconds , Dh = seconds
	and ax, 0fh ;guard the last 4 bits of DL
	mov [randNum] ,ax

	pop dx
	pop ax
ret
ENDP Random
PROC RandomCells                    ;Set Random in the current cells
	push bx
    
PlaceRandom:
    mov bx, offset BlockArr
    call Random

    add bx, [randNum]
    add bx, [randNum]
    
    cmp [word ptr bx], 0 ;Check if there is nothing In this spot (Check if 0)
    jne PlaceRandom

    add[word ptr bx] , 2
    pop bx
    ret
ENDP RandomCells
PROC KeyWaiting                     ;Function that gets a key, check what arrow is it and put the information in key variable
WaitForData:
    mov ah, 1
    int 16h
    JE WaitForData

    mov ah,0              ;function 0 - wait for keypress
    int 16h              ;call ROM BIOS keyboard services

EscButtonCheck:
    cmp ah,1                   ;Check if Esc button pressed
    JE PlaceIn_Key

ArrowUpCheck:   
    cmp ah, 72                   ;Check if Up arrow pressed
    JE PlaceIn_Key 

ArrowDownCheck:
    cmp ah,80                   ;Check if Down arrow pressed 
    JE PlaceIn_Key

ArrowLeftCheck:
    cmp ah,75                   ;Check if Left arrow pressed
    JE PlaceIn_Key

ArrowRightCheck:
	cmp ah, 77                   ;Check if Right arrow pressed
	JE PlaceIn_Key

RKeyCheck:
    cmp [key], 19                ;Check if R - key Pressed
    je PlaceIn_Key

jmp waitfordata  ;if The user hasn't pressed non of those buttons he will loop until he press one of those buttons

PlaceIn_Key: 
    mov [key],ah
   
ret 
endp KeyWaiting
PROC PrintBoard                     ;Check What The Random Cells and Paste it, also check if the player won or lost
    push ax
	push bx
	push cx
	push dx
	push di

    mov[printAdd] ,20*320+80
    call RandomCells

    mov bx, offset BlockArr
    mov cx,4
    
LoopPrintBoard:
    push cx
    mov cx,4 ;כל פעם שם ב cx את הערך 4

LoopPrintRow:
;The command in Cell num 0 valid in the all cells to 2048
CellNum0:
    cmp [word ptr bx] , 0 ;Cmp if the cell in the arr == 0, if not jmp to check the next num (2)
    jne CellNum2

    push ax
    mov ax, offset Cell0  ;Printing The Cell
    mov [offsetimg], ax
    pop ax


    jmp PrintCell1 

CellNum2:
    cmp [word ptr bx] , 2
    jne CellNum4

    push ax
    mov ax, offset Cell2
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1
    
CellNum4:
    cmp [word ptr bx] , 4
    jne CellNum8

    push ax
    mov ax, offset cell4
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1

CellNum8:
    cmp [word ptr bx] , 8
    jne CellNum16

    push ax
    mov ax, offset Cell8
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1
    
CellNum16:
    cmp [word ptr bx] , 16
    jne CellNum32

    push ax
    mov ax, offset Cell16
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1

CellNum32:
    cmp [word ptr bx] , 32
    jne CellNum64

    push ax
    mov ax, offset Cell32
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1
    
CellNum64:
    cmp [word ptr bx] , 64
    jne CellNum128

    push ax
    mov ax, offset Cell64
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1
    
CellNum128:
    cmp [word ptr bx] , 128
    jne CellNum256

    push ax
    mov ax, offset Cell128
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1
    

CellNum256:
    cmp [word ptr bx] , 256
    jne CellNum512

    push ax
    mov ax, offset Cell256
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1
    
CellNum512:
    cmp [word ptr bx] , 512
    jne CellNum1024

    push ax
    mov ax, offset Cell512
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1
    
CellNum1024:
    cmp [word ptr bx] , 1024
    jne CellNum2048

    push ax
    mov ax, offset Cell1024
    mov [offsetimg], ax
    pop ax
    
    jmp PrintCell1
    
CellNum2048:
    cmp [word ptr bx] , 2048
    jne EndBoard

    push ax
    mov ax, offset Cell2048
    mov [offsetimg], ax
    pop ax
    
    mov [CheckWin] , 1
    jmp PrintCell1

JmpLoopPrintRow:
	jmp LoopPrintRow
	
JmpLoopPrintBoard:
	jmp LoopPrintBoard

PrintCell1:
    call PrintCell ;40*40
    add[printAdd], 40
    add bx, 2
    loop JmpLoopPrintRow
    pop cx
    add [printAdd], 40*320-160
    loop JmpLoopPrintBoard

EndBoard:
    pop di 
    pop dx 
    pop cx 
    pop bx 
    pop ax
    ret
ENDP PrintBoard
;


;Usful Procs:
;\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
PROC print_Square                    ; Print Square: 

    mov ax, [x]  ;saves the original x
    mov [original],ax ;saves the original x
    mov [wentdown], 0
    ;print

    SECONDAGAIN:
    inc [wentdown]
    inc [y]
    mov [wentLeft],0
    mov ax, [original] ;moves original x to current x
    mov [x],ax   ;moves original x to current x
    ;lowering the Y until its at the bottom (50 for example)

    AGAIN:
    inc [x]
    inc [wentLeft]
    mov bh,0h
    mov cx,[x]
    mov dx,[y]
    mov al,[color]
    mov ah,0ch
    int 10h
    mov ax, [width1]
    cmp [wentLeft] ,ax ;check if reached the wanted width1
    JL AGAIN
    mov ax, [height]
    cmp [wentdown],ax  ;check if reached the wanted height
    JL SECONDAGAIN
    ret

ENDP print_Square
PROC DrawBground                     ;Draw A yellow Background:
drawYellow:
 	mov [xx],3
    inc [ii]
    inc [yy]
    loopforLine:	
    inc [xx]
    mov bh,0h
    mov cx,[xx]
    mov dx,[yy]
    mov al,[colorr]
    mov ah,0ch
    int 10h
	cmp [xx], 318
	jl loopforline
    cmp [ii] , 198
    JL drawYellow
    ret
ENDP DrawBground
;/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/


;Proc That In menu Screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PROC ClearAll

    mov [x], 5        
    mov [y],33
    mov [height],4
    mov [width1],100
    mov [color], 54
    call print_Square


    mov [x], 189
    mov [y],33
    mov [height],4
    mov [width1],127
    mov [color], 54
    call print_Square

ret
ENDP ClearAll
PROC DrawUpMenu
   
    mov [x], 131
    mov [y],91
    mov [height],4
    mov [width1],57
    mov [color], 0
    call print_Square


ret
ENDP DrawUpMenu
PROC DrawMidMenu

    mov [x], 90
    mov [y],125
    mov [height],4
    mov [width1],125
    mov [color], 0
    call print_Square
ret    
ENDP DrawMidMenu
PROC DrawLowMenu
    mov [x], 87
    mov [y],162
    mov [height],4
    mov [width1],145
    mov [color], 0
    call print_Square

ret
ENDP DrawLowMenu
PROC DeleteAllMenu
    ;deletes all the menu places could be drawn 
    ;The Top in the nenu:
    mov [x], 131
    mov [y],91
    mov [height],4
    mov [width1],57
    mov [color], 251
    call print_Square

    ;printing The botton layer
   
    mov [x], 90
    mov [y],125
    mov [height],4
    mov [width1],125
    mov [color],251
    call print_Square
    
   
    ;printing lowest layer
    mov [x], 87
    mov [y],162
    mov [height],4
    mov [width1],145
    mov [color], 251
    call print_Square

mov [color], 22
ret
ENDP DeleteAllMenu
PROC CheckUnder1

    cmp [currentPlace] ,1
    jl mov_to_up
ret
    mov_to_up:
    mov [currentPlace],3
ret
ENDP checkunder1
PROC CheckAbove3

    cmp [currentPlace] ,3
    jg mov_to_down
ret
    mov_to_down:
    mov [currentPlace],1
ret

ENDP checkabove3
PROC DrawMenuPos
  
    cmp [currentPlace],1
    je DrawLowMenu
    cmp [currentPlace],2
    je DrawMidMenu
    cmp [currentPlace],3
    je DrawUpMenu
    
ret
ENDP drawMenuPos



;Proc Shows Screens: 
;******************************************
PROC aboutme_Screen                 ;The about me Screen:
    call clear_screen

    push ax
	
	mov ax, offset imgAboutMe
	mov [imgWidth], 320d
	mov [imgHeight], 200d
	mov [printAdd], 0
	call PrintBmp

	pop ax

loopfor1:
    mov ah,0              ;function 0 - wait for keypress
    int 16h              ;call ROM BIOS keyboard services

    cmp ah,1 ;Esc
    je screenMenu
jmp loopfor1

ret
ENDP aboutme_Screen
PROC screenMenu                     ;Menu Screen: 
startMeunu1:
    
    jmp resetMenu

ChoiceCheck:
    cmp [currentPlace],1
    je howToPlay_Screen
    cmp [currentPlace],2
    je aboutme_Screen
    cmp [currentPlace],3
    je EnterGame
;


UpMoveMenu:
    call DeleteAllMenu
    inc [currentPlace]    
    call checkabove3
    call DrawMenuPos
    jmp MenuStartHere
;

DownMoveMenu:
    call DeleteAllMenu
    dec [currentPlace]    
    call checkunder1
    call DrawMenuPos
    jmp MenuStartHere
;


resetMenu:
    mov[currentPlace],3
    mov [color],0
    call clear_screen
    
    push ax
	mov ax, offset imgMenu
	mov [imgWidth], 320
	mov [imgHeight], 200
	mov [printAdd], 0
	call PrintBmp
	pop ax


    call DrawUpMenu

MenuStartHere:
    mov ah,0              ;function 0 - wait for keypress
    int 16h              ;call ROM BIOS keyboard services

    cmp ah, 72 ;ArrowUp:
    JE UpMoveMenu
            
    cmp ah,80  ;ArrowDown:
    JE DownMoveMenu

    cmp ah,28 ;Enter key:
    je ChoiceCheck

    cmp ah,44
    je exit

    jmp MenuStartHere
ret
ENDP screenMenu
PROC howToPlay_Screen               ;How to play Screen:
StartHowPlay:
    call clear_screen
    
    push ax

	mov ax, offset	imgHowToPlay
	mov [imgWidth], 320d
	mov [imgHeight], 200d
	mov [printAdd], 0
	call PrintBmp

	pop ax

loopfor:
    mov ah,0              ;function 0 - wait for keypress
    int 16h              ;call ROM BIOS keyboard services

    cmp ah,1 ;Esc
    je screenMenu


jmp loopfor

ret
ENDP howToPlay_Screen
PROC FirstScreen                    ;Shows First Screen:

    call clear_screen

    push ax
	
	mov ax, offset imgFirstScreen
	mov [imgWidth], 320
	mov [imgHeight], 200
	mov [printAdd], 0
	call PrintBmp

	pop ax

    call Win_sound
PressXKey:
    mov ah,0              ;function 0 - wait for keypress
    int 16h              ;call ROM BIOS keyboard services
    Cmp ah,45
    je StartHowPlay


StartGame:
    mov ah,1            ;function 0 - wait for keypress
    int 16h              ;call ROM BIOS keyboard services
    jmp EnterGame
    pop ax
    
ret
ENDP FirstScreen
PROC WinScreen                      ;Show the Win Screen

    call clear_screen
    push ax
	mov ax, offset imgWin
	mov [imgWidth], 320
	mov [imgHeight], 200
	mov [printAdd], 0
	call PrintBmp

	pop ax

    call Win_sound
WaitForKeyInput:
    mov ah, 0
    int 16h

    cmp ah,19   
    je EnterGame

    cmp ah,1
    je startMeunu1
    

ret
ENDP WinScreen
PROC LoseScreen                     ;Show the Lose Screen

    call clear_screen

    push ax
	mov ax, offset imgLose
	mov [imgWidth], 320
	mov [imgHeight], 200
	mov [printAdd], 0
	call PrintBmp

	pop ax

    call Lose_sound

WaitForInput:
	
	
    mov ah, 0
    int 16h

    cmp ah,19
    je EnterGame

    cmp ah,1
    je startMeunu1
	
	jmp WaitForInput
    
ret
ENDP LoseScreen
PROC BackScreen                    ;Show the back Screen



    push ax
	mov ax, offset imgbackg
	mov [imgWidth], 320
	mov [imgHeight], 200
	mov [printAdd], 0
	call PrintBmp

	pop ax


ret
ENDP BackScreen
;******************************************

;All The moves Procs:
PROC UpMove
    push ax
    push bx
    push cx
    push dx
    push di

    mov [moveVar],1

    mov cx, 16
    mov di, offset PassArray
clearPassArrUP:
    mov [word ptr di],0
    add di, 2
    loop clearPassArrUP


    mov cx,3; loop 3 times
CheckFirstTop:
    push cx
    mov cx,3

CheckSecondTop:
    cmp cx,3
    jne UpCheckIFCx2 ;IF cx Not equal to 3
    mov dx,6 
    jmp UpChecIFCx

UpCheckIFCx2:
    cmp cx,2
    jne UpCheckIFCx1 ; If cx No equal to 2
    mov dx,14   
    jmp UpChecIFCx

UpCheckIFCx1:
    cmp cx,1
    jne UpChecIFCx
    mov dx,22

UpChecIFCx:
    push cx
    mov cx,4

CheckThirdTop:
    mov bx ,offset BlockArr
    add bx,dx ;bx = bx + dx

    mov ax,[word ptr bx+8]
    cmp [word ptr bx],0
    jne UpNotEqual
    mov [word ptr bx],ax
    mov [word ptr bx+8],0
    mov [moveVar],0
    jmp continueLoopUp3


UpNotEqual:
    cmp [word ptr bx],ax ;Compare Index bx == ax
    jne continueLoopUp3
    mov di, offset PassArray
    add di, dx ; Di = di + dx 

    cmp [word ptr di + 8],1
    je continueLoopUp3

    add [word ptr bx],ax
    mov [word ptr bx + 8],0
    mov [word ptr di],1

    mov [moveVar],0
    jmp continueLoopUp3

continueLoopUp3:
    sub dx, 2
    loop CheckThirdTop
    
    pop cx
    loop CheckSecondTop

    pop cx
    loop CheckFirstTop

EndProcUpMove:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax


ret
ENDP UPMove
PROC DownMove
    push ax
    push bx
    push cx
    push dx
    push di


    mov [moveVar],1

    mov cx,16
    mov di, offset PassArray
clearPassArrDown:
    mov [word ptr di],0
    add di,2
    loop clearPassArrDown

    mov cx,3   ;Loop 3 times
FirstCheckUnder:
    push cx
    mov cx,3
    
SecondCheckUnder:
    cmp cx,3 ;Loop 3 times ******
    jne DownCheckCx2
    mov dx,30   

DownCheckCx2:
    cmp cx,2
    jne DownCheckCx1
    mov dx,22   

DownCheckCx1:
    cmp cx,1 
    jne DownCheckCx
    mov dx,14

DownCheckCx:
    push cx
    mov cx,4

CheckThirdUnder:
    mov bx ,offset BlockArr
    add bx,dx ;bx = bx + Dx

    mov ax,[word ptr bx - 8]

    cmp [word ptr bx],0
    jne DownNotEqual
    mov [word ptr bx],ax
    mov [word ptr bx - 8],0

    mov [moveVar],0
    jmp CotnLoopDown3  ;Jmp to contuntue loop 3 in Proc down 

DownNotEqual:
    cmp [word ptr bx],ax ;Compare Index di == ax
    jne CotnLoopDown3
    mov di, offset PassArray
    add di, dx ; Di = di + dx 

    cmp [word ptr di - 8],1
    je CotnLoopDown3

    add [word ptr bx ],ax
    mov [word ptr bx - 8],0
    mov [word ptr di],1

    mov [moveVar],0
    jmp CotnLoopDown3

CotnLoopDown3: ; Contuntue loop 3 in Proc down 
    sub dx,2
    loop CheckThirdUnder     ;cx = cx-1 and looping the loop
    
    pop cx
    loop SecondCheckUnder    ;cx = cx-1 and looping the loop

    pop cx
    loop FirstCheckUnder     ;cx = cx-1 and looping the loop

EndProcDownMove:
    pop di
	pop dx
	pop cx
	pop bx
	pop ax
ret
ENDP DownMove
PROC LeftMove
    push ax
	push bx
	push cx
	push dx
	push di
	
    mov [moveVar],1; Infering That the player can move

    mov cx,16
    mov di, offset PassArray
clearPassArrLeft:
    mov [word ptr di],0
    add di,2
    loop clearPassArrLeft


    mov cx,3;Loop 3 times
FirstCheckLeft:
    push cx
    mov cx,3

SecondCheckLeft:
    cmp cx,3;Loop 3 times
    jne LeftCheckCx2
    mov dx,0

LeftCheckCx2:
    cmp cx,2
    jne LeftCheckCx1
    mov dx,2

LeftCheckCx1:
    cmp cx,1
    jne LeftCheckCx
    mov dx,4

LeftCheckCx:
    push cx
    mov cx,4

ThirdCheckLeft:
    mov bx, offset BlockArr
    add bx,dx ;Bx = bx + dx;
    
    mov ax,[word ptr bx +2]
    cmp [word ptr bx],0
    jne LeftNotEqual
    mov [word ptr bx],ax
    mov [word ptr bx + 2],0

    mov [moveVar],0
    jmp CotnLoopLeft3

    
LeftNotEqual:
    cmp [word ptr bx],ax
    jne CotnLoopLeft3
    mov di, offset PassArray
    add di, dx
    cmp [word ptr di+2],1
    je CotnLoopLeft3
    add [word ptr bx],ax 
    mov [word ptr bx +2], 0
    mov [word ptr di],1

    mov [moveVar],0
    jmp CotnLoopLeft3


CotnLoopLeft3:
    add dx,8
    loop ThirdCheckLeft

    pop cx
    loop SecondCheckLeft

    pop cx
    loop FirstCheckLeft

ExitProcLeft:
    pop di
	pop dx
	pop cx
	pop bx
	pop ax

ret
ENDP LeftMove
PROC RightMove

    push ax
    push bx
    push cx
    push dx
    push  di

    mov [movevar],1
    
    mov cx,16
    mov di, offset PassArray
clearPassArrRight:    
    mov [word ptr di],0
    add di,2
    loop clearPassArrRight

    mov cx,3
FirstCheckRight:    
    push cx
    mov cx,3

SecondCheckRight:
    mov dx, cx
    add dx, cx

    push cx 
    mov cx,4
ThirdCheckRight:

    mov bx, offset BlockArr
    add bx,dx ;Bx = bx + dx

    mov ax ,[word ptr bx -2]
    cmp [word ptr bx],0
    jne RightNotEqual
    mov [word ptr bx],ax
    mov [word ptr bx-2],0
    
    mov [movevar],0
    jmp CotnLoopRight3  

RightNotEqual:
    cmp [word ptr bx],ax
    jne CotnLoopRight3
    mov di, offset PassArray
    add di,dx ; di = di + dx
    cmp [word ptr di -2],1
    je CotnLoopRight3
    add [word ptr bx],ax
    mov [word ptr bx -2],0
    mov [word ptr di] ,1

    mov [moveVar],0
    jmp CotnLoopRight3



CotnLoopRight3:

    add dx ,8
    loop ThirdCheckRight

    pop cx
    loop SecondCheckRight

    pop cx
    loop FirstCheckRight

ExitProcRight:
    pop di 
    pop dx
    pop cx
    pop bx
    pop ax

ret
ENDP RightMove
PROC CheckEndGame                   ;Check if you can't move anymore

    push ax
    push bx
    push cx

;First Check by lines: (horizontally)
    mov cx,4 ; 4 lines

CheckCanConnect_1:
    mov bx, offset BlockArr

CheckCXIS3:
    cmp cx,3
    jne CheckCXis2  ;if cx isn't 3 jmp to check if is it 2
    add bx,8
    jmp CheckCX ; If it is equal to 3, index = index + 8 and jump to check cx   

CheckCXis2:
    cmp cx,2
    jne CheckCXis1 ;Check if cx is 2 if it is not jmp to check if cx is 1
    add bx ,16
    jmp CheckCx ; If cx is 2, index = index + 16 and jmp to check cx

CheckCXis1:
    cmp cx,1
    jne CheckCx ; Check if cx is 1, if it is not 1 jmp to check cx
    add bx,24

CheckCx:
    push cx
    mov cx,3

CheckCanConnect_2:
    mov ax,[word ptr bx +2]  ; ax = Num of index bx +2
    cmp [word ptr bx],ax ; Compare if index bx +2 == bx
    je Popregister ; if the are equal jmp to pop cx 
    add bx,2 
    loop CheckCanConnect_2
    ; If they are not equal add bx +2, and loop until they are bx = bx+2 (index always getting bigger)

    pop cx
    inc [CheckLose]
    loop CheckCanConnect_1

;Secondly Check by Columns: (Vertically)

    mov cx,4 ;loop 4 times
CheckCanConnect_3:
    mov bx,offset BLockArr
    
   	add bx, cx
	add bx, cx
	sub bx, 2

    push cx
    mov cx,3
    
CheckCanConnect_4:    
    mov ax,[word ptr bx +8]
  	cmp [word ptr bx], ax
    je Popregister
    add bx ,8
    loop CheckCanConnect_4

    pop cx
    
    inc [CheckLose]
    loop CheckCanConnect_3
    jmp EndProcCheckEnd


Popregister:
    pop cx

EndProcCheckEnd:
    pop cx
    pop bx
    pop ax
    ret
ENDP CheckEndGame



;Move and The game Procs:
PROC MoveProc  
    call BackScreen
    call PrintBoard


CheckFinish:
    cmp[CheckWin],1
    je EndEndProc

NofreeCells:
    push cx
    push bx

    mov cx, 16
    mov bx, offset BlockArr
CheckFreeCell: 
    cmp[word ptr bx], 0 ;Check if there is no free cells, if there is no then the player lose, Else put there 2 
    je POPBothRegisters
    add bx, 2 ;Add 2 to the index
    loop CheckFreeCell

    pop cx
    pop bx

    mov [CheckLose],0 
    call CheckEndGame ; Count and check if cant move if cant checklose += 1
    cmp [CheckLose],8 
    je EndEndProc ;IF CheckLose == 8, You lost.
    jmp MoveLoop

POPBothRegisters: 
    pop cx
    pop bx

MoveLoop:
    mov [moveVar], 0; Infering That the player can move For the First time:
    call KeyWaiting

    cmp [key] , 1 ;Check if pressed Esc to go to the Main BMP
    je GoMenu
    cmp [key] , 72 ;Check if pressed Arrow Up
    je ArrowUpMove
    cmp [key] , 80 ;Check if pressed Arrow Down
    je ArrowDownMove
    cmp [key] , 75 ;Check if pressed Arrow Left
    je ArrowLeftMove
    cmp [key] , 77 ;Check if pressed Arrow Right 
    je ArrowRightMove
    cmp [key] , 19 ;Check if pressed R for restart the game
    je EndEndProc

;Call moves Procs;

ArrowUpMove:
    call UpMove 
   
    jmp CheckCanMove

ArrowDownMove:
    call DownMove
   
    jmp CheckCanMove

ArrowLeftMove:
    Call LeftMove
   
    jmp CheckCanMove

ArrowRightMove:
    call RightMove
    
    jmp CheckCanMove

GoMenu:
    call clear_screen 
    je startMeunu1

CheckCanMove:
    cmp [moveVar] , 1 ; If The player cant move in the end jmp to check if can't move at all
    je NofreeCells
    call PrintBoard
    jmp CheckFinish

EndEndProc: ;End for Move Proc
    ret
ENDP MoveProc
PROC RealGame
;The Game Starts Here:
EnterGame:
    ;Reset all register when beginning the Game Because we want to make sure
    mov ax, 0
    mov bx,0
    mov cx,0
    mov dx,0
    mov di,0
    mov si,0

    mov cx, 16
	mov bx, offset BlockArr
ClearCells:
    mov [word ptr bx], 0
	add bx,2
	loop ClearCells
	xor cx,cx
	xor bx,bx

    mov [CheckWin],0 
    mov [CheckLose],0
    
    call GraphicsMode
    Call MoveProc

    cmp [CheckWin],1   ;Check if there is a 2048 block 
    je WinSituation
    cmp[CheckLose],8 
    je Losesituation
    jmp ExitOrStart


WinSituation:
    Call WinScreen
    jmp ExitOrStart
Losesituation:
	call delay
    Call LoseScreen 
    jmp ExitOrStart

CheckForLeave:
    mov ah,1
    int 16h

ExitOrStart:
    cmp ah,1; Check if Esc Key pressed 
    jmp startMeunu1
    cmp ah,19 ;Check if R Key pressed 
    je EnterGame

    jmp CheckForLeave

ENDGame:
    ret
ENDP RealGame




start:
	mov ax, @data
	mov ds, ax  

    call clear_screen
	call GraphicsMode
    ;call screenMenu
    ;call WinScreen
    ;call LoseScreen
    ;call BackScreen
	
    call FirstScreen
    
    ;call RealGame
    ;call screenMenu
    
    
    mov ah,0              ;function 0 - wait for keypress
    int 16h              ;call ROM BIOS keyboard services

exit:
    call clear_screen
	mov ax, 4c00h   
	int 21h
END start   