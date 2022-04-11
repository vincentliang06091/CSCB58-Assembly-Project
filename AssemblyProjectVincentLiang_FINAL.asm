############################################################
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Vincent Liang, 1007374707, liangmu, vince.liang@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission? 
# (See the assignment handout for descriptions of the milestones) 
# - Milestone 1/2/3 (choose the one the applies) 
# 
# Which approved features have been implemented for milestone 3? 
# (See the assignment handout for the list of additional features) 
# 1. (fill in the feature, if any) 
# 2. (fill in the feature, if any) 
# 3. (fill in the feature, if any) 
# ... (add more if necessary) 
# 
# Link to video demonstration for final submission: 
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it! 
# 
# Are you OK with us sharing the video with people outside course staff? 
# - yes / no / yes, and please share this project github link as well! 
# 
# Any additional information that the TA needs to know: 
# - (write here, if any) 
# 
##################################################################### 

.eqv  BASE_ADDRESS  0x10008000 
.eqv INPUT 0xffff0000


.eqv HEIGHT 512
.eqv WIDTH 512
.eqv PIXEL_HEIGHT 4
.eqv PIXEL_WIDTH 4

.eqv NUM_PILLAR 8

.eqv nextline 512
.eqv COLOUR_PLAYER 0xA9A9A9
.eqv COLOUR_PLAYER2  0x808080
.eqv COLOUR_PLAYER3  0xD3D3D3
.eqv WHITE 0xFFFFFF
.eqv BLACK 0x000000
.eqv COIN_COLOUR 0xFFD700



.data

FACE_LEFT: .byte 0
JUMP: .byte 0
JUMP_HEIGHT: .word 25
DASH_DISTANCE: .word 5

PlayerHeight: .word 8
PlayerWidth: .word 7
PillarX: .word 100, 46, 98, 75, 61, 80, 30, 0 
PillarY: .word 63, 92, 96, 118, 25, 75, 45, 0
PillarHeight: .word 8, 8, 8, 5, 3, 5, 7, 15
PillarWidth: .word 10, 27, 10, 27, 30, 13, 35, 128

CoinX: .word 110, 80, 25
CoinY: .word 123, 40, 45
Num_Coins: .word 3
CoinFound: .byte 0, 0, 0
Scoreboard_Coin: .word 0

COLLISION: .byte 0
buffer: .space 5


#1,0,1,0,0,1,0,
#1,0,1,1,1,1,0,
#1,0,1,1,1,1,0,
#1,0,1,1,1,1,0,
#1,1,1,1,1,1,1,
#0,0,1,1,1,1,1,
#0,0,1,1,1,1,1,
#0,0,1,0,0,1,0,
.text 
setup:
 	addi $s0, $0, 0 #characterx
 	addi $s1, $0, 120 #charactery
 	addi $s2, $0, 0 #jumping count
 	add $t0, $0, $0
 	sb $t0, FACE_LEFT
 	sb $t0, JUMP
 	sb $t0, COLLISION
 	sw $t0, Scoreboard_Coin
 	li $t2, 0
 	sb $t0, CoinFound($t2)
 	addi $t2, $t2, 1
 	sb $t0, CoinFound($t2)
 	addi $t2, $t2, 1
 	sb $t0, CoinFound($t2)
 	addi $t2, $0, 25
 	sw $t2, JUMP_HEIGHT
 	jal drawplayer
 	jal draw_level
 	jal draw_coins
	
	
gameloop:
	#check input
	li $t9, INPUT
	lw $t8, 0($t9)
	bne $t8, 1, after_input
	lw $a0, 4($t9)
	jal input
after_input:
	#jump and gravity mechanics
	lb $t1, JUMP
	bne $t1, $0, jumping
after_jump:
	j falling
after_gravity:
	jal check_coincollision
	j gameloop
	
	
jumping:
	addi $t2, $0, 15
	slt $t3, $t2, $s1
	beq $t3, $zero, finish_jump
	jal delay
	addi $s1, $s1, -1
	jal check_collision
	addi $s1, $s1, 1
	lb $t2, COLLISION
	beq $t2, $0, check_jump
	add $t2, $0, $0
	sb $t2, COLLISION
	j finish_jump
check_jump:
	jal undrawplayer
	addi $s1, $s1, -1
	addi $s2, $s2, 1
	jal drawplayer	
	lw $t5, JUMP_HEIGHT
	bne $t5, $s2, still_jumping
finish_jump:
	add $s2, $0, $0
	sb $s2, JUMP
still_jumping:
	j after_jump
	
falling:
	lb $t2, JUMP
	bne $t2, $0, exit_fall
	bge $s1, 120, exit_fall
	jal delay
	addi $s1, $s1, 1
	jal check_collision
	addi $s1, $s1, -1
	lb $t2, COLLISION
	beq $t2, $0, cont_fall
	add $t2, $0, $0
	sb $t2, COLLISION
	j exit_fall
cont_fall:
	jal undrawplayer
	addi $s1, $s1, 1
	jal drawplayer
exit_fall:
	j after_gravity

delay:
	li $v0, 32
	li $a0, 10
	syscall
	jr $ra
	

input:
	#the ascii code for w, a, d respectively
	beq $a0, 0x61, left			
	beq $a0, 0x77, up		
	beq $a0, 0x64, right		
	beq $a0, 0x71, dash		
	beq $a0, 0x70, exit			# ASCII code of 'p'
	jr $ra					# Else, ignore input

dash:	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	lb $t4, FACE_LEFT
	beq $0, $t4, dash_right
	
	
dash_left:
	lw $t4, DASH_DISTANCE
	addi $t5, $0, 0

dash_left_loop:
	blez $s0, dash_exit
	beq $t5, $t4, dash_exit
	subi $s0, $s0, 1
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	addi $sp, $sp, -4
	sw $t4, 0($sp)
	jal check_collision
	lw $t4, 0($sp)
	addi $sp, $sp, 4
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	addi $s0, $s0, 1
	lb $t2, COLLISION
	beq $t2, $0, keep_left_dash
	add $t2, $0, $0
	sb $t2, COLLISION
	j dash_exit
	
	keep_left_dash:
		jal undrawplayer
		subi $s0, $s0, 1
		jal drawplayer
		addi $t5, $t5, 1
		jal delay
		j dash_left_loop
	
dash_right:
	lw $t4, DASH_DISTANCE
	addi $t5, $0, 0

dash_right_loop:
	bge $s0, 121, dash_exit
	beq $t5, $t4, dash_exit
	addi $s0, $s0, 1
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	addi $sp, $sp, -4
	sw $t4, 0($sp)
	jal check_collision
	lw $t4, 0($sp)
	addi $sp, $sp, 4
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	subi $s0, $s0, 1
	lb $t2, COLLISION
	beq $t2, $0, keep_right_dash
	add $t2, $0, $0
	sb $t2, COLLISION
	j dash_exit
	
	keep_right_dash:
		jal undrawplayer
		addi $s0, $s0, 1
		jal drawplayer
		addi $t5, $t5, 1
		jal delay
		j dash_right_loop
dash_exit:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

left:
	blez $s0, move_return
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	subi $s0, $s0, 1
	jal check_collision
	addi $s0, $s0, 1
	lb $t2, COLLISION
	beq $t2, $0, skip_left
	add $t2, $0, $0
	sb $t2, COLLISION
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j move_return
	
skip_left:
	jal undrawplayer
	add $t3, $0, 1
	sb $t3, FACE_LEFT
	subi $s0, $s0, 1
	jal drawplayer	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
down:
	bge $s1, 120, move_return
	lb $t4, JUMP
	bne $t4, $0, move_return
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $s1, $s1, 1
	jal check_collision
	lb $t2, COLLISION
	beq $t2, $0, skip_down
	add $t2, $0, $0
	sb $t2, COLLISION
	subi $s1, $s1, 1
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j move_return
skip_down:
	jal undrawplayer
	add $t3, $0, $0
	sb $t3, JUMP
	addi $s1, $s1, 1
	jal drawplayer	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

up:
	addi $t2, $0, 15
	slt $t3, $t2, $s1
	beq $t3, $zero, move_return
	lb $t4, JUMP
	bne $t4, $0, move_return
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	subi $s1, $s1, 1
	jal check_collision
	addi $s1, $s1, 1
	lb $t2, COLLISION
	beq $t2, $0, skip_up
	add $t2, $0, $0
	sb $t2, COLLISION
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j move_return
skip_up:
	jal undrawplayer
	addi $t3, $0, 1
	sb $t3, JUMP
	subi $s1, $s1, 1
	jal drawplayer	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

right:
	bge $s0, 121 move_return
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $s0, $s0, 1
	jal check_collision
	subi $s0, $s0, 1	
	lb $t2, COLLISION
	beq $t2, $0, skip_right
	add $t2, $0, $0
	sb $t2, COLLISION
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j move_return
skip_right:
	jal undrawplayer
	add $t3, $0, $0
	sb $t3, FACE_LEFT
	addi $s0, $s0, 1
	jal drawplayer	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

move_return:
	jr $ra
	

check_collision:
	addi $t6, $0, NUM_PILLAR
	add $t7, $0, $0
	add $t8, $0, $0
collision_loop:
	beq $t6, $t7, after_collision
	lw $t3, PillarX($t8)
	lw $t4, PillarY($t8)
	lw $t5, PillarHeight($t8)
	lw $t6, PillarWidth($t8)
	add $s6, $t3, $t6 #object right x
	add $s7, $t4, $t5 #object bottom y
	lw $t5, PlayerHeight
	lw $t6, PlayerWidth
	add $s5, $s0, $t6 #player right x
	add $s4, $s1, $t5 #player bottom y
	ble $s5, $t3, collision_false
	bge $s0, $s6, collision_false
	bge $s1, $s7, collision_false
	ble $s4, $t4, collision_false
	addi $t5, $0, 1
	sb $t5, COLLISION
	jr $ra
collision_false:
	addi $t7, $t7, 1
	addi $t8, $t8, 4	
	j collision_loop
after_collision:
	jr $ra

undrawplayer:
	li $t1, BLACK
	li $t2, BLACK
	li $t3, BLACK
	lb $t4, FACE_LEFT
	beq $0, $t4, player_right
	j player_left

drawplayer:
	li $t1, COLOUR_PLAYER   # $t1 stores the red colour code 
	li $t2, COLOUR_PLAYER2   # $t2 stores the green colour code 
	li $t3, COLOUR_PLAYER3   # $t2 stores the green colour code 
	lb $t4, FACE_LEFT
	beq $0, $t4, player_right
	j player_left

player_left:
	li $t0, BASE_ADDRESS # $t0 stores the base address for display 
	addi $t5, $0, HEIGHT
	addi $t6, $0, PIXEL_WIDTH
	mult $t5, $s1
	mflo $t7
	mult $t6, $s0
	mflo $t8
	add $t7, $t7, $t8
	add $t0, $t0, $t7
	
	
 	sw $t3, 0($t0) 
	sw $t3, 8($t0) 
	sw $t3, 20($t0)  
	
	addi $t0, $t0, nextline
	
	sw $t3, 0($t0) 
	sw $t2, 8($t0)  
	sw $t2, 12($t0) 
	sw $t2, 16($t0) 
	sw $t2, 20($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t3, 0($t0) 
	sw $t1, 8($t0)  
	sw $t1, 12($t0) 
	sw $t1, 16($t0) 
	sw $t2, 20($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t3, 0($t0) 
	sw $t2, 8($t0)  
	sw $t1, 12($t0) 
	sw $t2, 16($t0) 
	sw $t2, 20($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t2, 0($t0) 
	sw $t2, 4($t0)  
	sw $t2, 8($t0)  
	sw $t2, 12($t0) 
	sw $t3, 16($t0) 
	sw $t3, 20($t0) 
	sw $t3, 24($t0)  
	
	addi $t0, $t0, nextline
	
	sw $t2, 8($t0)  
	sw $t2, 12($t0) 
	sw $t3, 16($t0) 
	sw $t2, 20($t0) 
	sw $t3, 24($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t2, 8($t0)  
	sw $t2, 12($t0) 
	sw $t3, 16($t0) 
	sw $t3, 20($t0) 
	sw $t3, 24($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t2, 8($t0) 
	sw $t2, 20($t0) 
	
	jr $ra
	

player_right:
	li $t0, BASE_ADDRESS # $t0 stores the base address for display 
	addi $t5, $0, HEIGHT
	addi $t6, $0, PIXEL_WIDTH
	mult $t5, $s1
	mflo $t7
	mult $t6, $s0
	mflo $t8
	add $t7, $t7, $t8
	add $t0, $t0, $t7
	
	sw $t3, 24($t0) 
	sw $t3, 16($t0) 
	sw $t3, 4($t0)  
	
	addi $t0, $t0, nextline
	
	sw $t3, 24($t0) 
	sw $t2, 16($t0)  
	sw $t2, 12($t0) 
	sw $t2, 8($t0) 
	sw $t2, 4($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t3, 24($t0) 
	sw $t1, 16($t0)  
	sw $t1, 12($t0) 
	sw $t1, 8($t0) 
	sw $t2, 4($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t3, 24($t0) 
	sw $t2, 16($t0)  
	sw $t1, 12($t0) 
	sw $t2, 8($t0) 
	sw $t2, 4($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t2, 24($t0) 
	sw $t2, 20($t0)  
	sw $t2, 16($t0)  
	sw $t2, 12($t0) 
	sw $t3, 8($t0) 
	sw $t3, 4($t0) 
	sw $t3, 0($t0)  
	
	addi $t0, $t0, nextline
	
	sw $t2, 16($t0)  
	sw $t2, 12($t0) 
	sw $t3, 8($t0) 
	sw $t2, 4($t0) 
	sw $t3, 0($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t2, 16($t0)  
	sw $t2, 12($t0) 
	sw $t3, 8($t0) 
	sw $t3, 4($t0) 
	sw $t3, 0($t0) 
	
	addi $t0, $t0, nextline
	
	sw $t2, 16($t0) 
	sw $t2, 4($t0) 
	
	jr $ra

draw_level:
	addi $t9, $0, 0
draw_levelloop:
	li $t0, BASE_ADDRESS # $t0 stores the base address for display 
	li $t1, WHITE   # $t1 stores the white colour code 
	addi $t5, $0, HEIGHT
	addi $t6, $0, PIXEL_WIDTH
	lw $t8, PillarX($t9)
	lw $t7, PillarY($t9)
	mult $t5, $t7
	mflo $t7
	mult $t6, $t8
	mflo $t8
	lw $t4, PillarHeight($t9)
	lw $t5, PillarWidth($t9)
	add $t7, $t7, $t8
	add $t0, $t0, $t7
	add $t2, $0, $t4
	addi $t9, $t9, 4 #iterate to next pillar
	addi $t3, $0, NUM_PILLAR
	addi $t3, $t3, 1
	addi $t8, $0, 4
	mult $t8, $t3
	mflo $t8
	beq $t9, $t8, draw_levelexit
	pillarloop:
		add $t3, $0, $t5
		rowloop:
			sw $t1, 0($t0) 
			subi $t3, $t3, 1
			addi $t0, $t0, 4
			beq $t3, $0, pillarloop_cont
			j rowloop
	pillarloop_cont:
		subi $t2, $t2, 1 #iterate to next row
		beq $t2, $0, draw_levelloop
		addi $t0, $t0, 512
		mult $t5, $t6
		mflo $t8
		sub $t0, $t0, $t8
		beq $t2, $0, draw_levelloop
		j pillarloop
	j draw_levelloop

draw_levelexit:
	jr $ra
	

undraw_coins:
	li $t1, BLACK
	add $t9, $t8, $0
	li $t0, BASE_ADDRESS
	addi $t5, $0, HEIGHT
	addi $t6, $0, PIXEL_WIDTH
	lw $t2, CoinX($t9)
	lw $t7, CoinY($t9)
	mult $t5, $t7
	mflo $t7
	mult $t6, $t2
	mflo $t2
	add $t7, $t7, $t2
	add $t0, $t0, $t7
	
	
	sw $t1, 8($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 8($t0)
	jr $ra
	
draw_coins:
	li $t1, COIN_COLOUR  
	addi $t9, $0, 0
	addi $t2, $0, 0
	lw $t3, Num_Coins

drawcoin_loop:
	li $t0, BASE_ADDRESS
	addi $t5, $0, HEIGHT
	addi $t6, $0, PIXEL_WIDTH
	lw $t8, CoinX($t9)
	lw $t7, CoinY($t9)
	mult $t5, $t7
	mflo $t7
	mult $t6, $t8
	mflo $t8
	add $t7, $t7, $t8
	add $t0, $t0, $t7
	beq $t3, $t2, finish_drawcoins
	addi $t2, $t2, 1
	addi $t9, $t9, 4 #iterate to next pillar
	
	
	sw $t1, 8($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 8($t0)
	
	j drawcoin_loop
	
finish_drawcoins:
	jr $ra

check_coincollision:
	lw $t6, Num_Coins
	add $t7, $0, $0
	li $t8, 0
coincollision_loop:
	beq $t6, $t7, after_coincollision
	lb $t3, CoinFound($t8)
	bne $t3, $0, coincollision_false
	lw $t3, CoinX($t8)
	lw $t4, CoinY($t8)
	addi $t5, $0, 5
	addi $t6, $0, 5
	add $s6, $t3, $t6 #object right x
	add $s7, $t4, $t5 #object bottom y
	lw $t5, PlayerHeight
	lw $t6, PlayerWidth
	add $s5, $s0, $t6 #player right x
	add $s4, $s1, $t5 #player bottom y
	ble $s5, $t3, coincollision_false
	bge $s0, $s6, coincollision_false
	bge $s1, $s7, coincollision_false
	ble $s4, $t4, coincollision_false
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal undraw_coins
	
	lw $t5, Scoreboard_Coin
	
	addi $t6, $0, 1

	sb $t6, CoinFound($t8)
	
	addi $t5, $t5, 1
	sw $t5, Scoreboard_Coin
	
	jal drawplayer
	jal draw_scoreboardcoin

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
coincollision_false:
	addi $t7, $t7, 1
	addi $t8, $t8, 4	
	j coincollision_loop
after_coincollision:
	jr $ra

draw_scoreboardcoin:
	li $t1, COIN_COLOUR  
	li $t0, BASE_ADDRESS
	
	addi $t0, $t0, 3040
	
	lw $t3, Scoreboard_Coin
	addi $t4, $0, 32
	mult $t3, $t4
	mflo $t4
	
	sub $t0, $t0, $t4
	
	sw $t1, 8($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 8($t0)
	jr $ra

exit:
	jal undrawplayer
	j setup
	