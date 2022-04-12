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
# - https://youtu.be/-0HjAN0JdXM. Make sure we can view it! 
# 
# Are you OK with us sharing the video with people outside course staff? 
# - yes and please share this project github link as well! 
# https://github.com/vincentliang06091/CSCB58-Assembly-Project
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
.eqv NUM_COINS 3

.eqv nextline 512
.eqv COLOUR_PLAYER 0xA9A9A9
.eqv COLOUR_PLAYER2  0x808080
.eqv COLOUR_PLAYER3  0xD3D3D3
.eqv WHITE 0xFFFFFF
.eqv BLACK 0x000000
.eqv COIN_COLOUR 0xFFD700
.eqv FLAG_COLOUR 0xFF0000
.eqv FLAG_POLE 0xC0C0C0
.eqv POWER_COLOUR 0x90ee90



.data

FACE_LEFT: .byte 0
JUMP: .byte 0
JUMP_HEIGHT: .word 15
DASH_DISTANCE: .word 15

PlayerHeight: .word 8
PlayerWidth: .word 7
PillarX: .word 100, 46, 98, 75, 61, 80, 30, 0 
PillarY: .word 63, 92, 96, 118, 25, 75, 45, 0
PillarHeight: .word 8, 8, 8, 5, 3, 5, 7, 15
PillarWidth: .word 10, 27, 10, 27, 30, 13, 35, 128

CoinX: .word 110, 80, 25
CoinY: .word 123, 40, 45
CoinNUM: .word 0
Scoreboard_Coin: .word 0

Got_Powerup: .byte 0

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
 	add $s0, $0, $0 #characterx
 	addi $s1, $0, 120 #charactery
 	add $s2, $0, $0 #jumping count
 	add $t0, $0, $0
 	sb $t0, FACE_LEFT
 	sb $t0, JUMP
 	sb $t0, COLLISION
 	sw $t0, Scoreboard_Coin
 	sw $t0, CoinNUM
	sb $t0, Got_Powerup
 	li $t2, 15
 	sw $t2, JUMP_HEIGHT
 	jal drawplayer
 	jal draw_level
 	jal draw_coins
	jal draw_flag
	jal draw_powerup
	
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
	jal check_flagcollision
	jal check_powerupcollision
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
	add $t5, $0, $0	
	
dash_left_loop:
	blez $s0, dash_exit	
	beq $t5, $t4, dash_exit
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	addi $sp, $sp, -4
	sw $t4, 0($sp)
	jal check_coincollision
	jal check_flagcollision
	jal check_powerupcollision
	subi $s0, $s0, 1
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
		addi $sp, $sp, -4
		sw $t5, 0($sp)
		addi $sp, $sp, -4
		sw $t4, 0($sp)
		jal undrawplayer
		subi $s0, $s0, 1
		jal drawplayer
		lw $t4, 0($sp)
		addi $sp, $sp, 4
		lw $t5, 0($sp)
		addi $sp, $sp, 4
		addi $t5, $t5, 1
		jal delay
		j dash_left_loop
	
dash_right:
	lw $t4, DASH_DISTANCE
	addi $t5, $0, 0

dash_right_loop:
	bge $s0, 121, dash_exit
	beq $t5, $t4, dash_exit
	addi $sp, $sp, -4
	sw $t5, 0($sp)
	addi $sp, $sp, -4
	sw $t4, 0($sp)
	jal check_coincollision
	jal check_flagcollision
	jal check_powerupcollision
	addi $s0, $s0, 1
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
		addi $sp, $sp, -4
		sw $t5, 0($sp)
		addi $sp, $sp, -4
		sw $t4, 0($sp)
		jal undrawplayer
		addi $s0, $s0, 1
		jal drawplayer
		lw $t4, 0($sp)
		addi $sp, $sp, 4
		lw $t5, 0($sp)
		addi $sp, $sp, 4
		addi $t5, $t5, 1
		jal delay
		j dash_right_loop
dash_exit:
add $s2, $0, $0
sb $s2, JUMP
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
	lw $t9, CoinNUM
	li $t7, NUM_COINS
	beq $t9, $t7, finish_drawcoins
	li $t7, 4
	mult $t9, $t7
	mflo $t9	

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
	
finish_drawcoins:
	jr $ra

check_coincollision:
	lw $t8, CoinNUM
	li $t7, NUM_COINS
	beq $t8, $t7, after_coincollision
	li $t7, 4
	mult $t8, $t7
	mflo $t8
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
	ble $s5, $t3, after_coincollision
	bge $s0, $s6, after_coincollision
	bge $s1, $s7, after_coincollision
	ble $s4, $t4, after_coincollision
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal undraw_coins
	
	lw $t5, Scoreboard_Coin
	
	lw $t6, CoinNUM
	
	addi $t6, $t6, 1

	sw $t6, CoinNUM
	
	li $v0, 1
	move $a0, $t6
	syscall
		
	addi $t5, $t5, 1
	sw $t5, Scoreboard_Coin
	
	jal draw_coins
	jal drawplayer	
	jal draw_scoreboardcoin

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
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
undrawpowerup:
	li $t1, BLACK
	j powerup_aftercolour

draw_powerup:
	li $t1, POWER_COLOUR

powerup_aftercolour:
	li $t0, BASE_ADDRESS

	addi $t0, $t0, 51128
	
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
	
	
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	jr $ra
	
check_powerupcollision:
	lb $t3, Got_Powerup
	bne $t3, $0, after_powercollision
	li $t3, 110
	li $t4, 99
	addi $t5, $0, 5
	addi $t6, $0, 5
	add $s6, $t3, $t6 #object right x
	add $s7, $t4, $t5 #object bottom y
	lw $t5, PlayerHeight
	lw $t6, PlayerWidth
	add $s5, $s0, $t6 #player right x
	add $s4, $s1, $t5 #player bottom y
	ble $s5, $t3, after_powercollision
	bge $s0, $s6, after_powercollision
	bge $s1, $s7, after_powercollision
	ble $s4, $t4, after_powercollision
	
	j gain_powerup
	
after_powercollision:
	jr $ra

gain_powerup:
	li $t2, 30
 	sw $t2, JUMP_HEIGHT
 	add $s2, $0, $0
	sb $s2, JUMP
	li $t2, 1
	sb $t2, Got_Powerup
	
 	addi $sp, $sp, -4
	sw $ra, 0($sp)
 	
 	jal undrawpowerup
 	jal drawplayer
 	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

draw_flag:
	li $t1, FLAG_COLOUR  
	li $t2, FLAG_POLE
	li $t0, BASE_ADDRESS
	
	addi $t0, $t0, 9536
	
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	
	addi $t0, $t0, 512

	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t2, 12($t0)
	
	addi $t0, $t0, 512
	
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t2, 20($t0)
	jr $ra

check_flagcollision:
	li $t3, 80
	li $t4, 18
	addi $t5, $0, 7
	addi $t6, $0, 7
	add $s6, $t3, $t6 #object right x
	add $s7, $t4, $t5 #object bottom y
	lw $t5, PlayerHeight
	lw $t6, PlayerWidth
	add $s5, $s0, $t6 #player right x
	add $s4, $s1, $t5 #player bottom y
	ble $s5, $t3, after_flagcollision
	bge $s0, $s6, after_flagcollision
	bge $s1, $s7, after_flagcollision
	ble $s4, $t4, after_flagcollision
	
	j drawwin
	
after_flagcollision:
	jr $ra
	
drawwin:
	li $t1, BLACK
	li $t0, BASE_ADDRESS
	
	sw $t1, 0($t0)
	sw $t1, 16($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 44($t0)
	sw $t1, 56($t0)
	sw $t1, 64($t0)
	sw $t1, 72($t0)
	sw $t1, 80($t0)
	sw $t1, 88($t0)
	sw $t1, 96($t0)
	sw $t1, 112($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 4($t0)
	sw $t1, 12($t0)
	sw $t1, 24($t0)
	sw $t1, 36($t0)
	sw $t1, 44($t0)
	sw $t1, 56($t0)
	sw $t1, 64($t0)
	sw $t1, 72($t0)
	sw $t1, 80($t0)
	sw $t1, 88($t0)
	sw $t1, 96($t0)
	sw $t1, 100($t0)
	sw $t1, 112($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 8($t0)
	sw $t1, 24($t0)
	sw $t1, 36($t0)
	sw $t1, 44($t0)
	sw $t1, 56($t0)
	sw $t1, 64($t0)
	sw $t1, 72($t0)
	sw $t1, 80($t0)
	sw $t1, 88($t0)
	sw $t1, 96($t0)
	sw $t1, 104($t0)
	sw $t1, 112($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 8($t0)
	sw $t1, 24($t0)
	sw $t1, 36($t0)
	sw $t1, 44($t0)
	sw $t1, 56($t0)
	sw $t1, 64($t0)
	sw $t1, 72($t0)
	sw $t1, 80($t0)
	sw $t1, 88($t0)
	sw $t1, 96($t0)
	sw $t1, 108($t0)
	sw $t1, 112($t0)
	
	addi $t0, $t0, 512
	
	sw $t1, 8($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 68($t0)
	sw $t1, 76($t0)
	sw $t1, 88($t0)
	sw $t1, 96($t0)
	sw $t1, 112($t0)
	
	addi $t0, $t0, 512
	
endloop:
	#check input
	li $t9, INPUT
	lw $t8, 0($t9)
	bne $t8, 1, after_end
	lw $a0, 4($t9)
	jal input_end
after_end:
	j endloop
	
input_end:
	beq $a0, 0x70, exit			# ASCII code of 'p'
	jr $ra
	
exit:
	lw $t8, CoinNUM
	li $t7, NUM_COINS
	beq $t8, $t7, skip_erasecoin
	li $t7, 4
	mult $t8, $t7
	mflo $t8
	jal undraw_coins
skip_erasecoin:
	jal undrawplayer
	j setup
	
