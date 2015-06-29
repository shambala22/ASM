%define first 1<<0
%define second 1<<1
%define is_hit 1<<2

%define set_flag(a) xor bx, a
%define test_flag(a) test bx, a

section .text
org 0x100 ; for .com files

battleship: 
  mov ax,0x0001 ; clear screen, set graphic mode 40x25, color
  int 10h
  xor bx,bx
  push bx
  ; print strings of menu
  mov bp, title
  mov cx, title_len
  mov bx, 0eh
  mov ax,1300h
  mov dx,000ah ;start position
  
  int 10h
  mov bp, one_player
  mov cx, one_player_len
  mov dx, 020dh ; start position
  int 10h
  mov bp, two_players
  mov cx, two_players_len
  mov dx, 030dh ; position
  int 10h
  mov bp, exit
  mov cx, exit_len
  mov dx, 040dh ; startposition
  int 10h
  ;set cursor to begin of first string in menu
  mov ax, 0200h
  mov dx, 020dh ; cursor position
  int 10h
  pop bx
menu_choice:
  xor ax, ax
  int 16h ; listen keyboard
  cmp ax, 4800h ; if up arrow
  jne .continue
  ; dec y-address of cursor
  dec dh 
  cmp dh, 2
  jge .move
  mov dh, 04h
  jmp .move
  .continue: 
  cmp ax, 5000h ; if down arrow
  jne .continue_2
  ;inc y-address of cursor
  inc dh 
  cmp dh, 4
  jle .move
  mov dh, 02h
  jmp .move
  .continue_2:
  cmp ax, 1c0dh ; if enter
  je completed_choice ; go to selected mode
  jmp menu_choice
  .move:
  mov ax, 0200h
  int 10h
  jmp menu_choice
  
completed_choice:
  mov ax, 0300h ; get cursor position
  int 10h
  cmp dh, 02h
  je one_player_game
  cmp dh, 03h
  je two_players_game_preparing
  cmp dh, 04h
  je exit_game
  
one_player_game: ; it is not working
  jmp battleship
  
exit_game:
  mov ax,0002h
  int 10h
  int 20h
  
;||||||||||||||||||||||||||||||||||||||||||||||GAME FOR TWO PLAYERS||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
two_players_game_preparing:
  mov ax,0x0001 ; clear screen, set graphic mode 40x25, color
  int 10h
  push bx
  ;print message for player 1
  mov ax, 1300h
  mov bx, 0eh
  mov bp, hello_player1
  mov cx, hello_player1_len
  push dx
  mov dx, 0000h
  int 10h
  pop dx
  pop bx
  set_flag(first)
  mov [length_index], word 0 ; set insex in array of ship's length
  jmp two_players_game
  
two_players_game:
  mov ax, 1300h
  push bx
  mov bx, 0eh
  mov bp, text_data ; print table for game
  mov cx, text_data_len
  push dx
  mov dx, 0300h
  int 10h
  pop dx
  pop bx
  mov ax, 0200h
  mov dx, 0300h ; set cursor in begin of table
  int 10h
  mov ax, 0100h
  mov cx, 001fh ; set cursor type
  int 10h
  jmp ship_choice
  
ship_choice:
  xor ax, ax
  int 16h ; listen keyboard
  cmp ax, 4800h ; if up arrow
  jne .continue
  cmp dh, 03h; border of table
  je .move
  dec dh ; move up
  jmp .move
.continue:
  cmp ax, 5000h ; if down arrow
  jne .continue_2
  cmp dh, 0ch ; border of table
  je .move
  inc dh ; move down
  jmp .move
.continue_2:
  cmp ax, 4b00h  ;if left arrow
  jne .continue_3
  cmp dl,00h ; border of table
  je .move
  dec dl ; move left
  jmp .move
.continue_3:
  cmp ax, 4d00h ; if right arrow
  jne .continue_4
  cmp dl, 09h ; border of table
  je .move
  inc dl ; move right
  jmp .move
.continue_4:
  cmp ax, 1c0dh ; if enter
  je completed_ship_choice ; selected place for ship
  cmp ax, 011bh ;if escape
  je battleship ; go to main menu
  jmp ship_choice
  .move:
  mov ax, 0200h ; move cursor to new position
  int 10h
  jmp ship_choice
  
completed_ship_choice:
  push dx ; save cursor coords
  push cx
  call check_pos ; cx == 1 => position is incorrect
  cmp cx, 1
  pop cx
  je print_point_error
  pop dx
  mov ax, 0200h 
  int 10h 
  jmp direction_choice ; go to choosing a direction of placing ship
  

check_pos: ; get (x, y) coords in dh:dl ans check positions (x+1, y), (x-1, y), (x, y+1),  (x, y-1) 
; if one of this positions contains part of ship - position (x, y) is incorrect
; return cx = 1 => incorrect, cx = 0 => correct
  xor cx, cx
  mov ax, 0800h
  int 10h
  cmp al, '.'
  jne .fail
  cmp dl, 9
  je .continue_1
  inc dl
  mov ax, 0200h
  int 10h
  mov ax, 0800h
  int 10h
  cmp al, '.'
  jne .fail
  dec dl
.continue_1:
  cmp dl, 0
  je .continue_2
  dec dl
  mov ax, 0200h
  int 10h
  mov ax, 0800h
  int 10h
  cmp al, '.'
  jne .fail
  inc dl
.continue_2:
  cmp dh, 0ch
  je .continue_3
  inc dh
  mov ax, 0200h
  int 10h
  mov ax, 0800h
  int 10h
  cmp al, '.'
  jne .fail
  dec dh
.continue_3:
  cmp dh, 03h
  je .continue_4
  dec dh
  mov ax, 0200h
  int 10h
  mov ax, 0800h
  int 10h
  cmp al, '.'
  jne .fail
  inc dh
.continue_4:
  ret
.fail:
  mov cx, 1
  ret
  
print_O: ; print symbol O in dx coords
  push dx
  push cx
  push bx
  xor bx, bx
  mov ax, 0200h ; move cursor to dx coords
  int 10h
  mov ah, 0ah 
  mov al, 'O'
  mov cx, 1 ; one time
  int 10h
  mov cx, dx
  xor ax, ax
  sub ch, 3
  mov al, ch
  mov bx, 10
  mul bx
  xor ch, ch
  add ax, cx
  mov bx, ax
  add bx, bx
  mov cx, bx
  pop bx
  ;write printed symbol in memory
  test_flag(second)
  push bx
  mov bx, cx
  jnz .sec
  mov [player1_table + bx], word 'O'
  jmp .finish
  .sec:
  mov [player2_table + bx], word 'O'
  .finish:
  pop bx
  pop cx
  pop dx
  ret
  
direction_choice:
  xor ax, ax
  int 16h ;listen keyboard
  cmp ax, 4800h ; up direction
  jne .continue
  jmp up
.continue:
  cmp ax, 5000h ; down direction
  jne .continue_2
  jmp down
.continue_2:
  cmp ax, 4b00h ;left direction
  jne .continue_3
  jmp left
.continue_3:
  cmp ax, 4d00h ; right direction
  jne .continue_4
  jmp right
.continue_4:
  cmp ax, 011bh ; esc - cancel direction
  je ship_choice
  jmp direction_choice
  
up:
  push bx
  mov bx, [length_index] ; get index in mas
  add bx, bx ; bx*=2
  mov ax, word [mas+bx] ; ax = max[bx]
  mov cx, ax 
  pop bx
  dec cx
  push dx ; save coords
.cycle: ; cycle for check if chosen direction is correct
  cmp cx, 0
  je print_up
  cmp dh, 03h
  je print_direction_error ; if border reached - direction is incorrect
  dec dh
  push cx
  call check_pos ; if other ship is near - direction is incorrect
  cmp cx, 1
  pop cx
  je print_direction_error
  dec cx 
  jmp .cycle
  
down:
  push bx
  mov bx, [length_index] ; get index in mas
  add bx, bx
  mov ax, word [mas+bx] ; ax = mas[bx]
  mov cx, ax
  pop bx
  dec cx
  push dx ; save coords
.cycle: ; cycle for check if chosen direction is correct
  cmp cx, 0
  je print_down
  cmp dh, 0ch
  je print_direction_error ; if border reached - direction is incorrect
  inc dh
  push cx
  call check_pos
  cmp cx, 1
  pop cx
  je print_direction_error ; if other ship is near - direction is incorrect
  dec cx
  jmp .cycle

left:
  push bx
  mov bx, [length_index] ; get index in mas
  add bx, bx
  mov ax, word [mas+bx] ; ax = mas[bx]
  mov cx, ax
  pop bx
  dec cx
  push dx ; save coords
.cycle: ; cycle for check if chosen direction is correct
  cmp cx, 0
  je print_left
  cmp dl, 00h
  je print_direction_error ; if border reached - direction is incorrect
  dec dl
  push cx
  call check_pos
  cmp cx, 1
  pop cx
  je print_direction_error ; if other ship is near - direction is incorrect
  dec cx
  jmp .cycle

right:
  push bx
  mov bx, [length_index] ; get index in mas
  add bx, bx
  mov ax, word [mas+bx] ; ax = mas[bx]
  mov cx, ax
  pop bx
  dec cx
  push dx ; save coords
.cycle: ; cycle for check if chosen direction is correct
  cmp cx, 0
  je print_right
  cmp dl, 09h
  je print_direction_error ; if border reached - direction is incorrect
  inc dl
  push cx
  call check_pos
  cmp cx, 1
  pop cx
  je print_direction_error ; if other ship is near - direction is incorrect
  dec cx
  jmp .cycle


print_direction_error:
  pop dx
  mov ax, 0200h ; move cursor to dx coords
  int 10h
  mov ax, 1300h
  push bx
  mov bx, 0eh
  mov bp, d_error
  mov cx, d_error_len
  push dx
  mov dx, 0000h ; print error message
  int 10h
  pop dx
  pop bx
  jmp direction_choice ; try to choose direction again
  
  
; print_up, print_down, print_left, print_right are required for printing ship on the screen in direction which was set before this
print_up:
  pop dx
  push bx
  mov bx, [length_index]
  add bx, bx
  mov ax, word mas[bx]
  mov cx, ax
  pop bx
  push dx
.cycle:
  cmp cx, 0
  je end_direction
  push dx
  push cx
  call print_O
  pop cx
  pop dx
  dec dh
  dec cx
  jmp .cycle

  

print_down:
  pop dx
  push bx
  mov bx, [length_index]
  add bx, bx
  mov ax, word [mas+bx]
  mov cx, ax
  pop bx
  push dx
.cycle:
  cmp cx, 0
  je end_direction
  call print_O
  inc dh
  dec cx
  jmp .cycle

print_left:
  pop dx
  push bx
  mov bx, [length_index]
  add bx, bx
  mov ax, word [mas+bx]
  mov cx, ax
  pop bx
  push dx
.cycle:
  cmp cx, 0
  je end_direction
  call print_O
  dec dl
  dec cx
  jmp .cycle

print_right:
  pop dx
  push bx
  mov bx, [length_index]
  add bx, bx
  mov ax, word [mas+bx]
  mov cx, ax
  pop bx
  push dx
.cycle:
  cmp cx, 0
  je end_direction
  call print_O
  inc dl
  dec cx
  jmp .cycle
  
end_direction:
  pop dx
  mov ax, 0200h
  int 10h
  mov ax, 0100h
  mov cx, 001fh
  int 10h
  mov cx, [length_index]
  inc cx
  mov [length_index], cx ; if player is already set all his ships, go to next player. Else set next ship
  cmp cx, 10
  je next_player 
  jmp ship_choice

next_player:
  mov [length_index], word 0
  test_flag(second) ;if player 2 already set his ships, go to game process, else go to setting ships
  jnz game_process_two
  set_flag(second)
  mov ax, 1300h
  push bx
  mov bx, 0eh
  mov bp, hello_player2
  mov cx, hello_player2_len
  push dx
  mov dx, 0000h
  int 10h ; print start message for player 2
  pop dx
  pop bx
  jmp two_players_game
  
  
print_point_error: ; if you chose illegal point to set your ship, print message about it
  pop dx
  mov ax, 0200h
  int 10h
  mov ax, 1300h
  push bx
  mov bx, 0eh
  mov bp, p_error
  mov cx, p_error_len
  push dx
  mov dx, 0000h
  int 10h
  pop dx
  pop bx
  mov ax, 0100h
  mov cx, 001fh
  int 10h
  jmp ship_choice
  

  
game_process_two:
  set_flag(second)
  mov [player1_result], word 20 ; counter of points which wasn't hit
  mov [player2_result], word 20
  jmp player_step
  

player_step:
  mov ax, 0001h
  int 10h
  test_flag(first)
  jz .second
  call turn1 ; print message for player 1
  jmp .continue
  .second:
  call turn2 ; print message for player 2
  .continue:
  mov ax, 1300h
  push bx
  mov bx, 0eh
  mov bp, text_data
  mov cx, text_data_len
  mov dx, 0e00h
  int 10h ;print game field
  mov dx, 0300h
  int 10h ; two times
  pop bx
  mov dx, 0e00h ;print current player's field
  call print_field
  mov dx, 0300h ;print opponent's field
  call print_field
  mov ax, 0200h
  push bx
  xor bx, bx
  mov dx, 0300h
  int 10h
  pop bx
  jmp shot_choice
  
turn1:
  push bx
  push cx
  push dx
  mov ax, 1300h
  mov bx, 0eh
  mov bp, turn_player1
  mov cx, turn_player1_len
  mov dx, 0000h
  int 10h
  mov bp, p_enter
  mov cx, p_enter_len
  mov dx, 0300h
  int 10h
  .wait: ; wait for pressing enter of player. it means that player is ready to game
  xor ax, ax
  int 16h
  cmp ax, 1c0dh
  jne .wait
  mov ax, 1300h
  mov bx, 0eh
  mov bp, empty
  mov cx, empty_len
  mov dx, 0300h
  int 10h
  pop dx
  pop cx
  pop bx
  ret
  
turn2:
  push bx
  push cx
  push dx
  mov ax, 1300h
  mov bx, 0eh
  mov bp, turn_player2
  mov cx, turn_player2_len
  mov dx, 0000h
  int 10h
  mov bp, p_enter
  mov cx, p_enter_len
  mov dx, 0300h
  int 10h
  .wait: ; wait for pressing enter of player. it means that player is ready to game
  xor ax, ax
  int 16h
  cmp ax, 1c0dh
  jne .wait
  mov ax, 1300h
  mov bx, 0eh
  mov bp, empty
  mov cx, empty_len
  mov dx, 0300h
  int 10h
  pop dx
  pop cx
  pop bx
  ret
  
;in -> dx - start postion of cursor
print_field:
  push bx
  mov bx, 0000h
.cycle1: ;for (bh = 0; bh<10; bh++)
  .cycle2: ;for (bl = 0; bl<10; bl++)
    mov ax, 0200h
    push bx
    xor bx, bx
    int 10h ;move dx to start
    pop bx
    ;counting of address of current position in memory
    xor ax, ax
    mov al, bh
    push dx
    mov dx, 10
    mul dx
    pop dx
    push bx
    xor bh, bh
    add ax, bx
    mov bx, ax
    add bx, bx ;bx*=2 because array of words
    mov cx, bx
    pop bx
    mov ax, bx
    pop bx
    cmp dh, 0eh ; check if it's player's field
    jl .opponent_field
    test_flag(first)
    push bx
    mov bx, cx
    jz .second ;depends on in-game-player
    mov cx, word [player1_table+bx]
    jmp .continue
    .second:
    mov cx, word [player2_table+bx]
    .continue:
    mov bx, ax
    call print_your_symb; print symbol in cx if it's player's field
    jmp .continue2
    .opponent_field:
    test_flag(first)
    push bx
    mov bx, cx
    jz .second_op ;depends on in-game-player
    mov cx, word [player2_table+bx]
    jmp .continue_op
    .second_op:
    mov cx, word [player1_table+bx]
    .continue_op:
    mov bx, ax
    call print_opponent_symb ; print symbol in cx if it's opponent's field
    .continue2:
    inc bl ; increment second indexes in memory and on screen
    inc dl
    cmp bl, 10
    jne .cycle2
  xor bl, bl
  xor dl, dl
  inc bh
  inc dh ; increment first indexes in memory and on screen
  cmp bh, 10
  jne .cycle1
  
  pop bx
  ret
  
print_your_symb:; print synbol on player's field, if it's X or O
  push ax
  push bx
  cmp cx, 'O'
  je .print_O
  cmp cx, 'X'
  je .print_X
  pop bx
  pop ax
  ret
.print_O:
  mov ax, 0a00h
  xor bx, bx
  mov al, 'O'
  mov cx, 1
  int 10h
  jmp .finish
.print_X:
  mov ax, 0a00h
  xor bx, bx
  mov al, 'X'
  mov cx, 1
  int 10h
.finish:
  pop bx
  pop ax
  ret
  
print_opponent_symb: ; print synbol on player's field, if it's X or *. Else print '-' - unknown position 
  push ax
  push bx
  cmp cx, '*'
  je .print_st
  cmp cx, 'X'
  je .print_X
  mov ax, 0a00h
  xor bx, bx
  mov al, '-'
  mov cx, 1
  int 10h
  pop bx
  pop ax
  ret
.print_st:
  mov ax, 0a00h
  xor bx, bx
  mov al, '*'
  mov cx, 1
  int 10h
  jmp .finish
.print_X:
  mov ax, 0a00h
  xor bx, bx
  mov al, 'X'
  mov cx, 1
  int 10h
.finish:
  pop bx
  pop ax
  ret
  
shot_choice: ; choose an aim
  xor ax, ax
  push bx
  xor bx, bx
  int 16h ; listen keyboard
  pop bx
  cmp ax, 4800h ; if up arrow
  jne .continue
  cmp dh, 03h; border of table
  je .move
  dec dh ; move up
  jmp .move
.continue:
  cmp ax, 5000h ; if down arrow
  jne .continue_2
  cmp dh, 0ch ; border of table
  je .move
  inc dh ; move down
  jmp .move
.continue_2:
  cmp ax, 4b00h  ;if left arrow
  jne .continue_3
  cmp dl,00h ; border of table
  je .move
  dec dl ; move left
  jmp .move
.continue_3:
  cmp ax, 4d00h ; if right arrow
  jne .continue_4
  cmp dl, 09h ; border of table
  je .move
  inc dl ; move right
  jmp .move
.continue_4:
  cmp ax, 1c0dh ; if enter
  je completed_shot_choice 
  jmp shot_choice
  .move:
  push bx
  mov ax, 0200h ; move cursor to new position
  xor bx, bx
  int 10h
  pop bx
  jmp shot_choice

completed_shot_choice: ; if aim chose
  push dx
  push bx
  ;count address of chosen position in memory
  mov bx, dx
  sub bh, 3
  xor ax, ax
  mov al, bh
  push cx
  mov cx, 10
  mul cx
  pop cx
  xor bh, bh
  add ax, bx
  mov bx, ax
  add bx, bx
  mov ax, bx
  pop bx
  test_flag(first) ; depends on in-game-player
  push bx
  mov bx, ax
  jz .second
  mov cx, word [player2_table + bx]
  jmp .continue
  .second:
  mov cx, word [player1_table + bx]
  .continue:
  mov [current_address], bx
  cmp cx, word '*' ;if you had alredy chosen this position, return to choice
  je .no_fire
  cmp cx, word 'X'
  je .no_fire
  pop bx
  pop dx
  call shot
  jmp next_step
  .no_fire:
  pop bx
  pop dx
  
  jmp shot_choice
  
next_step: ; count saved postions of each player, and finish game if smb wins
  mov ax, [player1_result]
  cmp ax, 0
  je player2_wins
  mov ax, [player2_result]
  cmp ax, 0
  je player1_wins
  test_flag(is_hit)
  jnz .hit
  set_flag(first) ; swap players flag
  set_flag(second)
  jmp ready_to_next_step
  .hit:
  set_flag(is_hit)
  jmp ready_to_next_step
  
ready_to_next_step: ;wait for pressing enter of player who finished turn
  xor ax, ax
  int 16h
  cmp ax, 1c0dh
  je player_step
  jmp ready_to_next_step

; print messages about win
player1_wins: 
  mov ax, 0001h
  int 10h
  mov ax, 1300h
  mov bx, 0eh
  mov bp, win1
  mov cx, win1_len
  mov dx, 0a00h
  int 10h
  .enter:
  xor ax, ax
  xor bx, bx
  int 16h
  cmp ax, 1c0dh
  je clean_memory
  jmp .enter

  
player2_wins:
  mov ax, 0001h
  int 10h
  mov ax, 1300h
  mov bx, 0eh
  mov bp, win2
  mov cx, win2_len
  mov dx, 0a00h
  int 10h
  .enter:
  xor ax, ax
  xor bx, bx
  int 16h
  cmp ax, 1c0dh
  je clean_memory
  jmp .enter
  
clean_memory:
  xor bx, bx
  .cycle:
    mov [player1_table+bx], word ' '
    mov [player2_table+bx], word ' '
    add bx, 2
    cmp bx, 200
    jl .cycle
  xor bx, bx
  jmp battleship
  
shot:
  push dx
  push bx
  cmp cx, 'O' ;check if player missed
  je .hit
  .miss:
    ;if miss - say about it and save miss symb in memory
    mov ax, 1300h
    mov bx, 0eh
    mov bp, miss
    mov cx, miss_len
    mov dx, 0100h
    int 10h
    pop bx
    pop dx
    
    call print_st
    jmp .continue
    
  .hit:
    ;if hit - check "kill" or "hit" and save hit symbol in memory
    pop bx
    call hit_or_kill
    push bx
    cmp cx, 1
    je .killed
    mov ax, 1300h
    mov bx, 0eh
    mov bp, hit
    mov cx, hit_len
    mov dx, 0100h
    int 10h
    jmp .skip
    .killed: 
    mov ax, 1300h
    mov bx, 0eh
    mov bp, kill
    mov cx, kill_len
    mov dx, 0100h
    int 10h
    .skip:
    pop bx
    set_flag(is_hit)
    pop dx
    call print_X
  .continue:
    ret
  
  
hit_or_kill: 
;this method goes from current position in all 4 dirctions until first symbol of empty position or reaching borders or symbol of ship which wasn't hit
;if it reachs ship symbol - it is not killing
;else current ship was killed
  xor ax, ax
  
  mov dx, 3
  
  push bx
  mov bx, [current_address]
  .right:
  cmp dx, 0
  je .skip_right
  add bx, 2
  push bx
  mov ax, bx
  mov bl, 20
  div bl
  pop bx
  cmp ah, 0
  je .skip_right
  mov ax, bx
  pop bx
  call read_symbol
  push bx
  mov bx, ax
  cmp cx, 'O'
  je .false
  cmp cx, 'X'
  je .skip_right1
  jmp .skip_right
  .skip_right1:
  dec dx
  jmp .right
  .skip_right:
  pop bx
  
  mov dx, 3
  
  push bx
  mov bx, [current_address]
  .left:
  cmp dx, 0
  je .skip_left
  sub bx, 2
  cmp bx, 0
  jl  .skip_left
  push bx
  mov ax, bx
  mov bl, 20
  div bl
  pop bx
  cmp ah, 18
  je .skip_left
  mov ax, bx
  pop bx
  call read_symbol
  push bx
  mov bx, ax
  cmp cx, 'O'
  je .false
  cmp cx, 'X'
  je .skip_left1
  jmp .skip_left
  .skip_left1:
  dec dx
  jmp .left
  .skip_left:
  pop bx
  
  mov dx, 3
  
  push bx
  mov bx, [current_address]
  .up:
  cmp dx, 0
  je .skip_up
  sub bx, 20
  cmp bx, 0
  jl .skip_up
  mov ax, bx
  pop bx
  call read_symbol
  push bx
  mov bx, ax
  cmp cx, 'O'
  je .false
  cmp cx, 'X'
  je .skip_up1
  jmp .skip_up
  .skip_up1:
  dec dx
  jmp .up
  .skip_up:
  pop bx
  
  mov dx, 3
  
  push bx
  mov bx, [current_address]
  .down:
  cmp dx, 0
  je .skip_down
  add bx, 20
  cmp bx, 200
  jge .skip_down
  mov ax, bx
  pop bx
  call read_symbol
  push bx
  mov bx, ax
  cmp cx, 'O'
  je .false
  cmp cx, 'X'
  je .skip_down1
  jmp .skip_down
  .skip_down1:
  dec dx
  jmp .down
  .skip_down:
  pop bx
  
  jmp .true
  
  .false:
    pop bx
    mov cx, 0
    ret
  .true:
    mov cx, 1
    ret
  
  
read_symbol: ; return read symbol in cx
  push bx
  push dx
  test_flag(first)
  mov bx, ax
  jz .second
  mov cx, word [player2_table+bx]
  jmp .continue
  .second:
  mov cx, word [player1_table+bx]
  .continue:
  pop dx
  pop bx
  ret
  
print_st: ; print symbol * in dx coords
  push dx
  push cx
  push bx
  mov bx, [current_address]
  mov cx, bx
  pop bx
  test_flag(second)
  push bx
  mov bx, cx
  jnz .sec
  mov [player2_table + bx], word '*'
  jmp .finish
  .sec:
  mov [player1_table + bx], word '*'
  .finish:
  pop bx
  pop cx
  pop dx
  ret
  
print_X: ; print symbol 'X' in dx coords
  push dx
  push cx
  push bx
  mov bx, [current_address]
  mov cx, bx
  pop bx
  test_flag(second)
  push bx
  mov bx, cx
  jnz .sec
  mov ax, [player2_result]
  dec ax
  mov [player2_result], ax
  mov [player2_table + bx], word 'X'
  jmp .finish
  .sec:
  mov ax, [player1_result]
  dec ax
  mov [player1_result], ax
  mov [player1_table + bx], word 'X'
  .finish:
  pop bx
  pop cx
  pop dx
  ret

section .data
  ;empty game field
  text_data: 
  db "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13, 10, " "
  text_data_len: equ $-text_data
  ; some in-game messages
  title: db "Welcome to battleship"
  title_len: equ $-title
  one_player: db "One player (coming soon)"
  one_player_len: equ $-one_player
  two_players: db "Two players"
  two_players_len: equ $-two_players
  exit: db "Exit"
  exit_len: equ $-exit
  p_error: db "You have chosen incorrect place"
  p_error_len: equ $-p_error
  d_error: db "You've chosen illegal direction"
  d_error_len: equ $-d_error
  hello_player1: db "Player 1, set your ships."
  hello_player1_len: equ $-hello_player1
  hello_player2: db "Player 2, set your ships."
  hello_player2_len: equ $-hello_player2
  turn_player1: db "Player 1, it's your turn"
  turn_player1_len: equ $-turn_player1
  turn_player2: db "Player 2, it's your turn"
  turn_player2_len: equ $-turn_player2
  miss: db "MISS!"
  miss_len: equ $-miss
  hit: db "HIT!"
  hit_len: equ $-hit
  win1: db "Player 1 wins!"
  win1_len: equ $-win1
  win2: db "Player 2 wins!"
  win2_len: equ $-win2
  kill: db "KILL!"
  kill_len: equ $-kill
  p_enter: db "Press ENTER"
  p_enter_len: equ $-p_enter
  empty: db "             "
  empty_len: equ $-empty
  ; array of ship's length
  mas: dw 4, 3, 3, 2, 2, 2, 1, 1, 1, 1

section .bss
  player1_result: resw 1 ; score of players
  player2_result: resw 1
  length_index: resw 1 ; index in array of ship's length
  player1_table: resw 100 ; field of player 1
  player2_table: resw 100 ; and player 2
  current_address: resw 1 ; address of position which was hit