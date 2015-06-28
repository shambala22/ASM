%define first 1<<0
%define second 1<<1

%define set_flag(a) xor bx, a
%define test_flag(a) test bx, a

SECTION .text
org 0x100 ; для .com файлов. Это не команда, а указания на сдвиг адресов.

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
  
one_player_game:
  ret
  
exit_game:
  ret
  
;||||||||||||||||||||||||||||||||||||||||||||||GAME FOR TWO PLAYERS||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
two_players_game_preparing:
  mov ax,0x0001 ; clear screen, set graphic mode 40x25, color
  int 10h
  push bx
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
  mov [length_index], word 0
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
  mov cl, 0
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
  ;!!!!
  ;mov ax, 0100h
  ;mov ch, 20h ; hide cursor
  ;int 10h
  ;!!!!
  push cx
  call check_pos ; cx == 1 => position is incorrect
  cmp cx, 1
  pop cx
  je print_point_error
  pop dx
  mov ax, 0200h 
  int 10h
  jmp direction_choice
  
print_O: ; print symbol O in dx coords
  push dx
  push cx
  push bx
  xor bx, bx
  mov ax, 0200h
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
  mov cx, ax ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
  mov cx, ax; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
  mov cx, ax ; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
  mov cx, ax ; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
  mov ax, 0200h
  int 10h
  mov ax, 1300h
  push bx
  mov bx, 0eh
  mov bp, d_error
  mov cx, d_error_len
  push dx
  mov dx, 0000h
  int 10h
  pop bx
  pop dx
  jmp direction_choice
  
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
  mov [length_index], cx
  cmp cx, 10
  je next_player 
  jmp ship_choice

next_player:
  mov [length_index], word 0
  test_flag(second)
  jnz game_process_two
  set_flag(second)
  mov ax, player2_table
  mov [cur_table], ax
  mov ax, 1300h
  push bx
  mov bx, 0eh
  mov bp, hello_player2
  mov cx, hello_player2_len
  push dx
  mov dx, 0000h
  int 10h
  pop dx
  pop bx
  jmp two_players_game
  
  
print_point_error:
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
  mov ax, 1300h
  push bx
  mov bx, 0eh
  mov bp, text_data
  mov cx, text_data_len
  mov dx, 0e00h
  int 10h
  mov dx, 0300h
  int 10h
  test_flag(first)
  jnz first_player_step
  jmp first_player_step
  

first_player_step:
  mov dx, 0e00h
  call print_field
  mov dx, 0300h
  call print_field
  .cycle:
  jmp .cycle
  
print_field:
  push bx
  mov bx, 0000h
.cycle1:
  .cycle2:
    mov ax, 0200h
    push bx
    mov bx, 0
    int 10h
    pop bx
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
    add bx, bx
    cmp dh, 0eh
    jl .opponent_field
    test_flag(first)
    jz .second
    mov cx, word [player1_table+bx]
    jmp .continue
    .second:
    mov cx, word [player2_table+bx]
    .continue:
    pop bx
    call print_your_symb
    jmp .continue2
    .opponent_field:
    test_flag(first)
    jz .second_op
    mov cx, word [player2_table+bx]
    jmp .continue_op
    .second_op:
    mov cx, word [player1_table+bx]
    .continue_op:
    pop bx
    call print_opponent_symb
    .continue2:
    inc bl
    inc dl
    cmp bl, 10
    jne .cycle2
  xor bl, bl
  xor dl, dl
  inc bh
  inc dh
  cmp bh, 10
  jne .cycle1
  
  pop bx
  ret
  
print_your_symb:
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
  
print_opponent_symb:
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
  

check_pos:
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
  
  

SECTION .data
  text_data: 
  db "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13,10, "..........", 13, 10, " "
  text_data_len: equ $-text_data

  title: db "Welcome to battleship"
  title_len: equ $-title
  one_player: db "One player"
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
  
  mas: dw 4, 3, 3, 2, 2, 2, 1, 1, 1, 1

section .bss
  length_index: resw 1
  player1_table: resw 100
  player2_table: resw 100
  cur_table: resw 1
  players_count: resb 1