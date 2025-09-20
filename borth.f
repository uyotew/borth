: / /mod swap drop ;
: mod /mod drop ;

: '\n' 10 ;
: bl 32 ;

: cr '\n' emit ;
: space bl emit ;

: negate 0 swap - ;

: true 1 ;
: false 0 ;
: not 0= ;

: literal ' lit , , ; immediate

: ':' [ char : ] literal ;
: ';' [ char ; ] literal ;
: '(' [ char ( ] literal ;
: ')' [ char ) ] literal ;
: '"' [ char " ] literal ;
: 'A' [ char A ] literal ;
: '0' [ char 0 ] literal ;
: '-' [ char - ] literal ;
: '.' [ char . ] literal ;

: [compile] word find >cfa , ; immediate

: recurse latest @ >cfa , ; immediate

: if ' 0branch , here @ 0 , ; immediate
: else ' branch , here @ 0 , swap dup here @ swap - swap ! ; immediate
: then dup here @ swap - swap ! ; immediate

: begin here @ ; immediate
: until ' 0branch , here @ - , ; immediate
: again ' branch , here @ - , ;  immediate

: while ' 0branch , here @ 0 , ; immediate 
: repeat ' branch , swap here @ - , dup here @ swap - swap ! ; immediate 
 
: unless ' not , [compile] if ; immediate

: ( 1 begin key dup '(' = if drop 1+ else ')' = if 1- then then
    dup 0= until drop 
; immediate

: nip ( x y -- y ) swap drop ;
: tuck ( x y -- y x y ) swap over ; 
: pick ( x_u ... x_1 x_0 u -- x_u ... x_1 x_0 x_u ) 1+ 8 * dsp@ + @ ;

: spaces ( n -- ) begin dup 0> while space 1- repeat drop ;

: octal ( -- ) 8 base ! ; 
: decimal ( -- ) 10 base ! ;
: hex ( -- ) 16 base ! ;

: u. ( u -- ) base @ /mod ?dup if recurse then
    dup 10 < if '0' else 10 - 'A' then + emit 
;

: uwidth ( u -- width) base @ / ?dup if recurse 1+ else 1 then ; 

: u.r ( u width -- ) swap dup uwidth rot swap - spaces u. ; 

: .r ( n width -- ) swap dup 0< if negate swap 1- 1 else swap 0 then 
    -rot swap dup uwidth rot swap - spaces swap 0<> if '-' emit then u. 
; 
 
: . 0 .r space ; 
: u. u. space ;

: .s ( -- ) dsp@ s0 @ 8- begin 2dup <= while dup @ . 8- repeat 2drop ;

: ? ( addr -- ) @ . ; 

: within -rot over <= if > if true else false then else 2drop false then ;

: depth s0 @ dsp@ - 8- ; 

: aligned 7 + 7 invert and ; 
: align here @ aligned here ! ;

: c, here @ c! 1 here +! ;

: s" state @ if ( compiling? ) ' litstring , here @ 0 , 
   begin key dup '"' <> while c, repeat drop 
   dup here @ swap - 8- swap ! align 
else ( immediate ) 
   here @ begin key dup '"' <> while over c! 1+ repeat drop
   here @ - here @ swap 
then
; immediate  

: ." state @  if ( comp ) [compile] s" ' tell ,
else ( imm ) begin key dup '"' <> while emit repeat drop
then
; immediate

: constant word create docol , [compile] literal ' exit , ; immediate

: allot ( n -- addr ) here @ swap here +! ; 
: cells 8 * ;

: variable word create docol , ' lit , here @ 16 + , ' exit , 0 , ; immediate

: id. ( addr -- ) 8+ dup c@ f_lenmask and swap 1+ swap tell ;
: ?hidden 8+ c@ f_hidden and ;
: ?immediate 8+ c@ f_immed and ;

: words latest @ begin ?dup while dup ?hidden not 
  if dup id. space then @ repeat cr 
;

: forget word find dup @ latest ! here ! ;

: dump ( addr len -- ) base @ -rot hex begin ?dup while
    over 16 u.r space  2dup 1- 15 and 1+ begin ?dup while
        swap dup c@ 2 .r space 1+ swap 1- 
    repeat drop
    2dup 1- 15 and 1+ begin ?dup while
        swap dup c@ dup 32 128 within if emit else drop '.' emit 
        then 1+ swap 1-
    repeat drop cr dup 1- 15 and 1+ tuck - >r + r>
repeat drop base ! 
;

: case 0 ; immediate
: of ' over , ' = , [compile] if ' drop , ; immediate
: endof [compile] else ; immediate
: endcase ' drop , begin ?dup while [compile] then repeat ; immediate

: cfa> ( codeaddr -- wordaddr ) latest @ begin ?dup while 
   2dup swap < if nip exit then @ repeat drop 0 ;

\ segfaults with syscall0 since the next word is defined in a separate memory space
\ i think
\ but this should not be used with asm words anyways...
: seecol ( word_header_addr -- ) here @ latest @ begin 2 pick over <> while
    nip dup @ repeat drop swap ( end-of-word start-of word ) 
    ':' emit space dup id. space dup ?immediate -rot ( immed? end start )
    >dfa begin 2dup > while dup @ case
        ' lit of 8+ dup @ . endof
        ' litstring of [ char s ] literal emit '"' emit space
            8+ dup @ swap 8+ swap 2dup tell '"' emit space
            + aligned 8- endof ( will be adding 8 next loop )
        ' 0branch of ." 0branch ( " 8+ dup @ . ')' emit space endof
        ' branch of ." branch ( " 8+ dup @ . ')' emit space endof
        ' ' of [ char ' ] literal emit space 8+ dup @ cfa> id. space endof
        ' exit of 2dup 8+ <> if ." exit " then endof
        dup cfa> id. space
    endcase 8+
    repeat
    2drop ';' emit if ."  immediate" then cr
;

( can use ' in immediate mode also now  (it is slow)
    but maybe unnecessary, since it's mostly used in compile mode )
: ' state @ if ' ' , else word find >cfa then ; immediate

: exception-marker rdrop 0 ;
: catch ( xt -- exn? ) dsp@ 8+ >r ' exception-marker 8+ >r execute ;
: throw ( n -- ) ?dup if rsp@ begin dup r0 8- < while 
    dup @ ' exception-marker 8+ = if 
        8+ rsp! dup dup dup r> 8- swap over ! dsp! exit
    then 8+ 
    repeat drop case -1 of ." aborted" cr endof ." uncaught throw " dup . cr
    endcase quit then 
;
: abort -1 throw ;

: print-stack-trace rsp@ begin dup r0 8- < while dup @ case
    ' exception-marker 8+ of ." catch ( dsp=" 8+ dup @ u. ." ) " endof
    dup cfa> ?dup if 2dup id. [ char + ] literal emit swap >dfa 8+ - . then
    endcase 8+ 
    repeat drop cr 
; 

: z" state @ if ( comp ) 
    ' litstring , here @ 0 , begin key dup '"' <> while c, repeat 
    0 c, drop dup here @ swap - 8- swap ! align ' drop , 
else ( imm )
    here @ begin key dup '"' <> while over c! 1+ repeat drop 0 swap c! here @ 
then 
;

: strlen dup begin dup c@ 0<> while 1+ repeat swap - ; 
: cstring swap over here @ swap cmove here @ + 0 swap c! here @ ;

: argc s0 @ @ ;
: argv ( n -- str len ) 1+ cells s0 @ + @ dup strlen ; 
: environ argc 2 + cells s0 @ + ;

: bye 0 sys_exit syscall1 ; 
: get-brk 0 sys_brk syscall1 ;
: unused get-brk here @ - 8 / ;
: brk sys_brk syscall1 ;
: morecore cells get-brk + brk ;

: r/o o_rdonly ; 
: r/w o_rdwr ;
: fopen ( str ln flg -- fd err ) -rot cstring sys_open syscall2
    dup dup 0< if negate else drop 0 then 
;

octal

: fcreate ( str ln flg -- fd err ) o_creat or o_trunc or -rot cstring 
    644 -rot sys_open syscall3 dup dup 0< if negate else drop 0 then 
;

decimal

: fclose ( fd -- err ) sys_close syscall1 negate ; 
: fread ( addr len fd -- ln err ) >r swap r> sys_read syscall3
    dup dup 0< if negate else drop 0 then 
;
: fwrite ( addr len fd -- ln err ) >r swap r> sys_write syscall3
    dup dup 0< if negate else drop 0 then
;

: perror ( errno str ln -- ) tell ." : errno=" . cr ;

\ no assembler included, but a disassembler ?? maybe..
\ seems unnecessary to be able to write assembly
\ and then the data-segment will need to be executable?



\ TODO: extend see to disassemble assembly words??
: see word find dup 0= if ." not found" exit then
    dup >cfa @ docol = if seecol 
    else ." disassembly not implemented yet" cr
        >cfa @ 256 dump
    then 
;

\ maybe have something that checks when the "next" macro appears in a word 
\ and then disassemble up to that point

\ and also, a disasm word, that works like dump, but prints assembly instead of hex


: strargs ( str len -- a_addr ) tuck begin ?dup while 
        over c@ dup bl = if drop 0 c, else c, then 1- swap 1+ swap 
    repeat 
    drop 0 c, ( len ) 1+ dup here @ swap - ( len start ) align here @ -rot
    swap ( a_addr start len ) begin dup 0> while
        over strlen ?dup if tuck - -rot over , + swap 
        then 1- swap 1+ swap 
    repeat 2drop 0 ,
    ( a_addr) dup @ here ! ( restore here )
;   

: run ( str len -- ret ) strargs environ swap dup @ 59 syscall3 ;

