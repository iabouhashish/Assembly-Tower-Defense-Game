#constants
.equ LEDS, 0xFF200000
.equ SWITCHES, 0xFF200040
.equ KEYBOARD, 0xFF200100 #controller 1
.equ JTAGUART, 0xFF201000
.equ TIMER, 0xFF202000
.equ ENTIMER, 0xFF202020 
.equ VGA_PIXEL, 0x08000000
.equ VGA_CHAR, 0x09000000
#.equ TIMERPERIOD, 62500000 #16 frames/sec
.equ TIMERPERIOD, 10000000 #16 frames/sec
.equ ENEMYTIME, 187500000
.equ BLACK,0x00
.equ WHITE,0xFF 
.equ VGA_PIXEL_MAX, 0x0803BE7E #max final sum of the adjusted xy-coords for the pixel buffer ( = 2*x + 1024*y)
.equ bmpOffset, 0x00000045 #ignore the header data in the bmp file by adding this to the base of the image file

.data

###byte data###
.align 0
keyLUT: .byte 0x16,0x1E,0x26,0x1D,0x1C,0x1B,0x23,0x5A,0x00 #1,2,3, W, A, S, D, Enter, 0
keyPressed: .byte 0 #last key user entered
shoot: .byte 0 #dont shoot yet!

###word data###
.align 2
charx: .word 0 #coords currently at for char iteration
chary: .word 0
x: .word 0 #coords currently at for vga char display iteration
y: .word 0 
bulletX: .word 0
bulletY: .word 0
#first tower's bullets
bOneOneX: .word 0
bOneOneY: .word 0
#second tower's bullets
bTwoOneX: .word 0
bTwoOneY: .word 0
#third tower's bullets
bThreeOneX: .word 0
bThreeOneY: .word 0
#hold the x and y coordinates of the towers here (for drawing bullets)
towerOneX: .word 50
towerOneY: .word 81
towerTwoX: .word 130
towerTwoY: .word 180
towerThreeX: .word 120
towerThreeY: .word 111
#hold the x and y coordinates of the enemies here.
enemyOneX: .word 100
enemyOneY: .word 250
enemyTwoX: .word 200
enemyTwoY: .word 239
enemyThreeX: .word 280
enemyThreeY: .word 260
startSimulation: .word 0
#how many towers
towersNumber: .word 0
pickedTower: .word 0
life: .word 0

myFile: .incbin "background.bmp"
tower: .incbin "tower.bmp"
enemy: .incbin "enemy.bmp"
wasted: .incbin "wasted.bmp"
info: .incbin "info.bmp"
################################# CODE #################################
##NEXT-THINGS-TO-DO LIST:
# Separate game into two states: setup, and 'simulation'
# logic for spawning enemy sprites
# implement the logic for 'bullet trajectory'
# test the VGA drawing in the lab (simulator was really inconsistent...)
.text
	.global _start
_start:
    movia r11, startSimulation
	stw r0, 0(r11)
	movia r11, life
	stw r0, 0(r11)
continue:
	movia r8, LEDS
	stwio r0, 0(r8)
	movia r4, info
	call drawBackground
    #enable timer interrupts
    #call InitTimer
	#enable interrupts on keyboard 
	movia r11,KEYBOARD
	movi r10, 0b01
	stwio r10,4(r11)
	startLoop: #wait for switch before doing anything
		movia r10,SWITCHES
		ldwio r10,0(r10)
		andi r10,r10,0x01
		movui r11,0x1
		bne r10,r11,startLoop
#Timer start routine
initKeyBoard:
	movia r4, myFile
	call drawBackground
	movi r5, 3
	movia r8, towersNumber
	ldw r9, 0(r8)
	towerLopp:
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		bne r5, r9, towerLopp
	stw r0, 0(r8)
    movia r10,0b010000000 #enable IRQ7(PS/2 controller 1) and IRQ0(timer)
    movi r11,0b01 #write 1 to enable PIE bit in status register
    wrctl ctl3,r10
    wrctl ctl0,r11
Loop: #game logic happens here, and push to VGA 
	#if game has started, draw the bullet
	br Loop

	
drawBackground:
    movia r16, VGA_PIXEL
    mov r17, r4
    movi r18, 0 #r18 will be the x coordinate while drawing
    movi r19, 0 #r19 will be the y coordinate
    #movia r17,0xffff
	movi r21, bmpOffset
    add r17,r17,r21 #add the bmp header offset to the bmp base address
    bgLoop:
        muli r20,r18,2
        muli r21,r19,1024
        add r22,r20,r21
        movia r21, VGA_PIXEL_MAX
        bgt r22,r21,doneDrawing #check if you're off-screen
        ldh r21,0(r17) #get current pixel
        #movi r21, WHITE
        add r23,r16,r22
        sthio r21,0(r23)
        movi r23, 319
        bgt r18,r23,nextRow
        #else, just move to next x-coord
        addi r18,r18,1
        addi r17,r17,2
        br bgLoop
    nextRow:
        movi r18,0
        addi r19,r19,1
        movi r23, 239
        bgt r19,r23,doneDrawing
        br bgLoop
    doneDrawing:
        ret
drawTower:
	movia r16, VGA_PIXEL
    movia r17, tower
	movia r15, towersNumber
	ldw r15, 0(r15)
	movi r19, 1
	movi r20, 2
	beq r15, r0, towerOne
	beq r15, r19, towerTwo
	beq r15, r20, towerThree
	br doneDrawing2
	towerOne:
		movia r18, towerOneX #r18 will be the x coordinate while drawing
		ldw r18, 0(r18)
		mov r15, r18
		movia r19, towerOneY #r19 will be the y coordinate
		ldw r19, 0(r19)
		br keepGoing
	towerTwo:
		movia r18, towerTwoX #r18 will be the x coordinate while drawing
		ldw r18, 0(r18)
		mov r15, r18
		movia r19, towerTwoY #r19 will be the y coordinate
		ldw r19, 0(r19)
		br keepGoing
	towerThree:
		movia r18, towerThreeX #r18 will be the x coordinate while drawing
		ldw r18, 0(r18)
		mov r15, r18
		movia r19, towerThreeY #r19 will be the y coordinate
		ldw r19, 0(r19)
		br keepGoing
    
	keepGoing:
    #movia r17,0xffff
	movi r21, bmpOffset
    add r17,r17,r21 #add the bmp header offset to the bmp base address
	mov r12, r18
	mov r13, r19
	addi r12, r12, 25
	addi r13, r13, 24
	bgLoop2:
        muli r20,r18,2
        muli r21,r19,1024
        add r22,r20,r21
        movia r21, VGA_PIXEL_MAX
        bgt r22,r21,doneDrawing2 #check if you're off-screen
        ldh r21,0(r17) #get current pixel
        #movi r21, WHITE
        add r23,r16,r22
        sthio r21,0(r23)
        bgt r18,r12,nextRow2
        #else, just move to next x-coord
        addi r18,r18,1
        addi r17,r17,2
        br bgLoop2
    nextRow2:
		mov r18, r15     
		addi r19,r19,1
        bgt r19,r13,doneDrawing2
        br bgLoop2
    doneDrawing2:
        ret

#takes in x-coord as argument and draws a bullet there
drawBullet:
	movia r16, VGA_PIXEL
    movia r17, 0xf800
    ldw r18,0(r4)
	ldw r19,0(r5)
	ldw r15, 0(r4)
	mov r12, r18
	mov r13, r19
	addi r12, r12, 1
	addi r13, r13, 1
	bgLoop3:
        muli r20,r18,2
        muli r21,r19,1024
        add r22,r20,r21
        movia r21, VGA_PIXEL_MAX
        bgt r22,r21,doneDrawing3 #check if you're off-screen
        mov r21,r17
		#ldh r21,0(r17) #get current pixel
        #movi r21, WHITE
        add r23,r16,r22
        sthio r21,0(r23)
        bgt r18,r12,nextRow3
        #else, just move to next x-coord
        addi r18,r18,1
        #addi r17,r17,2
        br bgLoop3
    nextRow3:
		mov r18, r15      
		addi r19,r19,1
        bgt r19,r13,doneDrawing3
        br bgLoop3
    doneDrawing3:
        ret


		
drawEnemy:
	movia r16, VGA_PIXEL
    movia r17, enemy
    ldw r18,0(r4)
	ldw r19,0(r5)
	ldw r15, 0(r4)
    movi r21, bmpOffset
    add r17,r17,r21 #add the bmp header offset to the bmp base address
	mov r12, r18
	mov r13, r19
	addi r12, r12, 25
	addi r13, r13, 24
	bgLoop4:
        muli r20,r18,2
        muli r21,r19,1024
        add r22,r20,r21
        movia r21, VGA_PIXEL_MAX
        bgt r22,r21,doneDrawing4 #check if you're off-screen
        ldh r21,0(r17) #get current pixel
        #movi r21, WHITE
        add r23,r16,r22
        sthio r21,0(r23)
        bgt r18,r12,nextRow4
        #else, just move to next x-coord
        addi r18,r18,1
        addi r17,r17,2
        br bgLoop4
    nextRow4:
		mov r18, r15       
		addi r19,r19,1
        bgt r19,r13,doneDrawing4
        br bgLoop4
    doneDrawing4:
        ret	

BulletResetF:
	ldw r18, 0(r4)
	ldw r19, 0(r5)
	movi r20, 6
	add r18, r18, r20
	stw r18, 0(r5)
	ret
	
initTimer:
    movia r10,TIMER #set base address 
    #set timer period
    movi r11,%hi(TIMERPERIOD) 
    stwio r11,12(r10)
    movi r11,%lo(TIMERPERIOD) 
    stwio r11,8(r10)
	
	
	movia r14, towerOneX
	movia r13, bOneOneX
	ldw r11, 0(r14)
	addi r11, r11, 6
	stw r11,0(r13)
	movia r14, towerOneY
	movia r13, bOneOneY
	ldw r11, 0(r14)
	addi r11, r11, 5
	stw r11,0(r13)

	movia r14, towerTwoX
	movia r13, bTwoOneX
	ldw r11, 0(r14)
	addi r11, r11, 6
	stw r11,0(r13)
	movia r14, towerTwoY
	movia r13, bTwoOneY
	ldw r11, 0(r14)
	addi r11, r11, 5
	stw r11,0(r13)

	movia r14, towerThreeX
	movia r13, bThreeOneX
	ldw r11, 0(r14)
	addi r11, r11, 6
	stw r11,0(r13)
	movia r14, towerThreeY
	movia r13, bThreeOneY
	ldw r11, 0(r14)
	addi r11, r11, 5
	stw r11,0(r13)
    
	
	stwio r0,0(r10) #clear timeout
    movi r11,0b111 #start timer w/ continuous and interrupt enabled
    stwio r11,4(r10)

    movia r10,0b000000001 #enable IRQ7(PS/2 controller 1) and IRQ0(timer)
    movi r11,0b01 #write 1 to enable PIE bit in status register
    wrctl ctl3,r10
    wrctl ctl0,r11
	ret

		
	something:
		#store it in memory and perform game logic in loop
		movia r14, pickedTower
		ldw r14, 0(r14)
		movi r19, 1
		movi r20, 2
		beq r14, r0, firstTower
		beq r14, r19, secondTower
		beq r14, r20, thirdTower
	firstTower:
		movia r19, towerOneX
		ldw r21, 0(r19)
		movia r20, towerOneY
		ldw r22, 0(r20)
		br keepKeepKeepGoing
	secondTower:
		movia r19, towerTwoX
		ldw r21, 0(r19)
		movia r20, towerTwoY
		ldw r22, 0(r20)
		br keepKeepKeepGoing
	thirdTower:
		movia r19, towerThreeX
		ldw r21, 0(r19)
		movia r20, towerThreeY
		ldw r22, 0(r20)

	keepKeepKeepGoing:
		movia r12, keyPressed
		movia r15, keyLUT
		stw et,0(r12)
        movia r12, VGA_CHAR
		ldb r14, 0(r15)
		beq et, r14, numberOne
		ldb r14, 1(r15)
		beq et, r14, numberTwo
		ldb r14, 2(r15)
		beq et, r14, numberThree
		ldb r14, 3(r15)
		beq et, r14, letterW
		ldb r14, 4(r15)
		beq et, r14, letterA
		ldb r14, 5(r15)
		beq et, r14, letterS
		ldb r14, 6(r15)
		beq et, r14, letterD
		ldb r14, 7(r15)
		beq et, r14, enterKey

	numberOne:
		movi r4, 1
		movia r14, pickedTower
		stw r4, 0(r14)
		br iexit
	numberTwo:
		movi r4, 2
		movia r14, pickedTower
		stw r4, 0(r14)
		br iexit
	numberThree:
		movi r4, 3
		movia r14, pickedTower
		stw r4, 0(r14)
    	br iexit
	letterW:
		addi r22, r22, -6
		stw r22, 0(r20)
		movia r4, myFile
		call drawBackground
		movi r5, 3
		movia r8, towersNumber
		ldw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		stw r0, 0(r8)
		br iexit
	letterA:
		addi r21, r21, -6
		stw r21, 0(r19)
		movia r4, myFile
		call drawBackground
		movi r5, 3
		movia r8, towersNumber
		ldw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		stw r0, 0(r8)
		br iexit
	letterS:
		addi r22, r22, 6
		stw r22, 0(r20)
		movia r4, myFile
		call drawBackground
		movi r5, 3
		movia r8, towersNumber
		ldw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		stw r0, 0(r8)
		br iexit
	letterD:
		addi r21, r21, 6
		stw r21, 0(r19)
		movia r4, myFile
		call drawBackground
		movi r5, 3
		movia r8, towersNumber
		ldw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		stw r0, 0(r8)
		br iexit
	enterKey:
		movia r14, startSimulation
		movi r15, 1
		stw r15, 0(r14)
		call initTimer
		br iexit

		
	printStuff:
		movia r4, myFile
		call drawBackground
		movi r5, 3
		movia r8, towersNumber
		ldw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		call drawTower
		addi r9, r9, 1
		stw r9, 0(r8)
		stw r0, 0(r8)
	enemyInt:
		movia r4,enemyOneX
		movia r5,enemyOneY
		call drawEnemy
		movia r14, enemyOneY
		ldw r13, 0(r14)
		movi r8, 81
		ble r13, r8, enemyResetOne
		addi r13, r13, -4
		stw r13, 0(r14)
		br enemyTwoInt
	enemyResetOne:
		movia r9, life
		ldw r10, 0(r9)
		addi r10, r10, 1
		stw r10, 0(r9)
		movi r8, 245
		stw r8, 0(r14)
		
	enemyTwoInt:
		movia r4,enemyTwoX
		movia r5,enemyTwoY
		call drawEnemy
		movia r14, enemyTwoY
		ldw r13, 0(r14)
		movi r8, 81
		ble r13, r8, enemyResetTwo
		addi r13, r13, -4
		stw r13, 0(r14)
		br enemyThreeInt
	enemyResetTwo:
		movia r9, life
		ldw r10, 0(r9)
		addi r10, r10, 1
		stw r10, 0(r9)
		
		movi r8, 245
		stw r8, 0(r14)
	enemyThreeInt:
		movia r4,enemyThreeX
		movia r5,enemyThreeY
		call drawEnemy
		movia r14, enemyThreeY
		ldw r13, 0(r14)
		movi r8, 81
		ble r13, r8, enemyResetThree
		addi r13, r13, -4
		stw r13, 0(r14)
		br bulletInt
	enemyResetThree:
		movia r9, life
		ldw r10, 0(r9)
		addi r10, r10, 1
		stw r10, 0(r9)
		movi r8, 245
		stw r8, 0(r14)
		
	bulletInt:
		movia r4,bOneOneX
		movia r5,bOneOneY
		call drawBullet
		movia r4,bTwoOneX
		movia r5,bTwoOneY
		call drawBullet
		movia r4,bThreeOneX
		movia r5,bThreeOneY
		call drawBullet
	enemyOneHit:
			#first enemy check
			movia r8,enemyOneX
			movia r9,enemyOneY
			ldw r8,0(r8)
			ldw r9,0(r9)
			#see if first tower's bullet hit it
			firstCheck:
				movia r10,bOneOneX
				movia r11,bOneOneY
				ldw r10,0(r10)
				ldw r11,0(r11)
				#check for collision - defined as bullet being within the coordinates of the enemy sprite
				#not a hit if bullet's x is less than enemy's x coord, or it's x + 25 (right bound)
				blt r10,r8,secondCheck
				addi r8,r8,25
				bgt r10,r8,secondCheck
				#same check for y coordinates
				blt r11,r9,secondCheck
				addi r9,r9,24
				bgt r11,r9,secondCheck
				#else, it was a hit
				movia r9,enemyOneY
				movi r8,290
				stw r8,0(r9)
				movia r4,towerOneX
				movia r5,bOneOneX
				br bulletReset
			secondCheck:
				movia r8,enemyOneX
				movia r9,enemyOneY
				ldw r8,0(r8)
				ldw r9,0(r9)
				movia r10,bTwoOneX
				movia r11,bTwoOneY
				ldw r10,0(r10)
				ldw r11,0(r11)
				#check for collision - defined as bullet being within the coordinates of the enemy sprite
				#not a hit if bullet's x is less than enemy's x coord, or it's x + 25 (right bound)
				blt r10,r8,thirdCheck
				addi r8,r8,25
				bgt r10,r8,thirdCheck
				#same check for y coordinates
				blt r11,r9,thirdCheck
				addi r9,r9,24
				bgt r11,r9,thirdCheck
				#else, it was a hit
				movia r9,enemyOneY
				movi r8,290
				stw r8,0(r9)
				movia r4,towerOneX
				movia r5,bTwoOneX
				br bulletReset
			thirdCheck:
				movia r8,enemyOneX
				movia r9,enemyOneY
				ldw r8,0(r8)
				ldw r9,0(r9)
				movia r10,bThreeOneX
				movia r11,bThreeOneY
				ldw r10,0(r10)
				ldw r11,0(r11)
				#check for collision - defined as bullet being within the coordinates of the enemy sprite
				#not a hit if bullet's x is less than enemy's x coord, or it's x + 25 (right bound)
				blt r10,r8,enemyTwoHit
				addi r8,r8,25
				bgt r10,r8,enemyTwoHit
				#same check for y coordinates
				blt r11,r9,enemyTwoHit
				addi r9,r9,24
				bgt r11,r9,enemyTwoHit
				#else, it was a hit
				movia r9,enemyOneY
				movi r8,290
				stw r8,0(r9)
				movia r4,towerOneX
				movia r5,bThreeOneX
				br bulletReset
		enemyTwoHit:
			#first enemy check
			movia r8,enemyTwoX
			movia r9,enemyTwoY
			ldw r8,0(r8)
			ldw r9,0(r9)
			#see if first tower's bullet hit it
			firstCheck2:
				movia r10,bOneOneX
				movia r11,bOneOneY
				ldw r10,0(r10)
				ldw r11,0(r11)
				#check for collision - defined as bullet being within the coordinates of the enemy sprite
				#not a hit if bullet's x is less than enemy's x coord, or it's x + 25 (right bound)
				blt r10,r8,secondCheck2
				addi r8,r8,25
				bgt r10,r8,secondCheck2
				#same check for y coordinates
				blt r11,r9,secondCheck2
				addi r9,r9,24
				bgt r11,r9,secondCheck2
				#else, it was a hit
				movia r9,enemyTwoY
				movi r8,290
				stw r8,0(r9)
				movia r4,towerTwoX
				movia r5,bOneOneX
				br bulletReset
			secondCheck2:
				movia r8,enemyTwoX
				movia r9,enemyTwoY
				ldw r8,0(r8)
				ldw r9,0(r9)
				movia r10,bTwoOneX
				movia r11,bTwoOneY
				ldw r10,0(r10)
				ldw r11,0(r11)
				#check for collision - defined as bullet being within the coordinates of the enemy sprite
				#not a hit if bullet's x is less than enemy's x coord, or it's x + 25 (right bound)
				blt r10,r8,thirdCheck2
				addi r8,r8,25
				bgt r10,r8,thirdCheck2
				#same check for y coordinates
				blt r11,r9,thirdCheck2
				addi r9,r9,24
				bgt r11,r9,thirdCheck2
				#else, it was a hit
				movia r9,enemyTwoY
				movi r8,290
				stw r8,0(r9)
				movia r4,towerTwoX
				movia r5,bTwoOneX
				br bulletReset
			thirdCheck2:
				movia r8,enemyTwoX
				movia r9,enemyTwoY
				ldw r8,0(r8)
				ldw r9,0(r9)
				movia r10,bThreeOneX
				movia r11,bThreeOneY
				ldw r10,0(r10)
				ldw r11,0(r11)
				#check for collision - defined as bullet being within the coordinates of the enemy sprite
				#not a hit if bullet's x is less than enemy's x coord, or it's x + 25 (right bound)
				blt r10,r8,enemyThreeHit
				addi r8,r8,25
				bgt r10,r8,enemyThreeHit
				#same check for y coordinates
				blt r11,r9,enemyThreeHit
				addi r9,r9,24
				bgt r11,r9,enemyThreeHit
				#else, it was a hit
				movia r9,enemyTwoY
				movi r8,290
				stw r8,0(r9)
				movia r4,towerTwoX
				movia r5,bThreeOneX
				br bulletReset
		enemyThreeHit:
			#first enemy check
			movia r8,enemyThreeX
			movia r9,enemyThreeY
			ldw r8,0(r8)
			ldw r9,0(r9)
			#see if first tower's bullet hit it
			firstCheck3:
				movia r10,bOneOneX
				movia r11,bOneOneY
				ldw r10,0(r10)
				ldw r11,0(r11)
				#check for collision - defined as bullet being within the coordinates of the enemy sprite
				#not a hit if bullet's x is less than enemy's x coord, or it's x + 25 (right bound)
				blt r10,r8,secondCheck3
				addi r8,r8,25
				bgt r10,r8,secondCheck3
				#same check for y coordinates
				blt r11,r9,secondCheck3
				addi r9,r9,24
				bgt r11,r9,secondCheck3
				#else, it was a hit
				movia r9,enemyThreeY
				movi r8,290
				stw r8,0(r9)
				movia r4,towerThreeX
				movia r5,bOneOneX
				br bulletReset
			secondCheck3:
				movia r8,enemyThreeX
				movia r9,enemyThreeY
				ldw r8,0(r8)
				ldw r9,0(r9)
				movia r10,bTwoOneX
				movia r11,bTwoOneY
				ldw r10,0(r10)
				ldw r11,0(r11)
				#check for collision - defined as bullet being within the coordinates of the enemy sprite
				#not a hit if bullet's x is less than enemy's x coord, or it's x + 25 (right bound)
				blt r10,r8,thirdCheck3
				addi r8,r8,25
				bgt r10,r8,thirdCheck3
				#same check for y coordinates
				blt r11,r9,thirdCheck3
				addi r9,r9,24
				bgt r11,r9,thirdCheck3
				#else, it was a hit
				movia r9,enemyThreeY
				movi r8,290
				stw r8,0(r9)
				movia r4,towerThreeX
				movia r5,bTwoOneX
				br bulletReset
			thirdCheck3:
				movia r8,enemyThreeX
				movia r9,enemyThreeY
				ldw r8,0(r8)
				ldw r9,0(r9)
				movia r10,bThreeOneX
				movia r11,bThreeOneY
				ldw r10,0(r10)
				ldw r11,0(r11)
				#check for collision - defined as bullet being within the coordinates of the enemy sprite
				#not a hit if bullet's x is less than enemy's x coord, or it's x + 25 (right bound)
				blt r10,r8,bulletCond
				addi r8,r8,25
				bgt r10,r8,bulletCond
				#same check for y coordinates
				blt r11,r9,bulletCond
				addi r9,r9,24
				bgt r11,r9,bulletCond
				#else, it was a hit
				movia r9,enemyThreeY
				movi r8,290
				stw r8,0(r9)
				movia r4,towerThreeX
				movia r5,bThreeOneX
				br bulletReset
	bulletCond:
		movia r14, bOneOneX
		ldw r13, 0(r14)
		movi r15, 319
		movia r4, towerOneX
		movia r5, bOneOneX
		bge r13, r15, bulletReset
		movia r14, bTwoOneX
		ldw r13, 0(r14)
		movi r15, 319
		movia r4, towerTwoX
		movia r5, bTwoOneX
		bge r13, r15, bulletReset
		movia r14, bThreeOneX
		ldw r13, 0(r14)
		movi r15, 319
		movia r4, towerThreeX
		movia r5, bThreeOneX
		bge r13, r15, bulletReset
		br cont
	bulletReset:
		call BulletResetF
	cont:
		movia r14, bOneOneX
		ldw r13, 0(r14)
		addi r13,r13,6
		stw r13, 0(r14)
		movia r14, bTwoOneX
		ldw r13, 0(r14)
		addi r13,r13,6
		stw r13, 0(r14)
		movia r14, bThreeOneX
		ldw r13, 0(r14)
		addi r13,r13,6
		stw r13, 0(r14)
		
		movia r10, life
		ldw r10, 0(r10)
		movi r9, 5
		bge r10, r9, gameover
		movia r11, LEDS
		movia r9, life
		ldw r3, 0(r9)
		stwio r3, 0(r11)
		movia r11,TIMER
		stw r0, 0(r8)
		stwio r0,0(r11)
		br iexit
	gameover:
		movia r11,TIMER
		stw r0, 0(r8)
		stwio r0,0(r11)
		movui r8, 0b1000
		stwio r8, 4(r11)
		movia r8, LEDS
		movi r3, 0xFFF
		stwio r3, 0(r8)
		movia r4, wasted
		call drawBackground
		br iexit
	#resetY:
	#    movi r21,0
	#    movia et, chary
	#    stw r21,0(et)
	#    ret

################################# INTERRUPT STUFF #################################
	.section .exceptions, "ax" #make sure address is 0x20 for handler
IHANDLER:
    rdctl et, ipending
    andi r13, et, 0b010000000 #if irq7 is one, go to keyboard handler
	movi r12, 0b010000000
    beq r13, r12, keyboard
    #else, it's probably a timer interrupt, but double-check to be safe
	andi et, et, 0b000000001 #if irq7 is one, go to keyboard handler
	movi r12, 0b000000001
    beq et, r12, timer

	br iexit
	keyboard:
		movia r13, startSimulation
		ldw r13, 0(r13)
		bne r13, r0, iexit
		movia r13,KEYBOARD
		ldwio et, 0(r13)
		srli et,et,15
		andi et,et,0x01
		beq et,r0,iexit #exit if read data not valid
		ldbio et,0(r13) #else, read data to acknowledge interrupt
		movi r12, -16
		beq et, r12, validData #if break code, go read the next byte
		br iexit
	validData:
		ldwio et, 0(r13)
		mov r17, et
		srli et,et,15
		andi et,et,0x01
		beq et,r0,validData #exit if read data not valid
	breakCode:
		mov et, r17
		andi et, et, 0x0FF
		movia r12,keyLUT
		#now check if a valid key was pressed
	LUTCheck:
		#beq r15, r19, iexit
		ldb r14, 0(r12)
		beq r14, r0, iexit
		beq et, r14, something
		addi r12,r12,1
		br LUTCheck
	
	
	#Timer Interrupt:
	timer:
		movia r11, startSimulation
		ldw r11, 0(r11)
		beq r0, r11, iexit
		br printStuff
    iexit: #exit the interrupt
		movia r11,TIMER
		stw r0, 0(r8)
		stwio r0,0(r11)
        addi ea,ea,-4 #shift the pc back on return
        eret

