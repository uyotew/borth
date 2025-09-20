\ borth brainfuck compiler


( can be used immediate and in word-definitions now)
( should maybe not end bf with ;, since it has other meanings?)
: bf ( mem_start_addr -- ) 
    state @ 0= if here @ docol , then
     begin key dup ';' <> while case
    [ char > ] literal of ' 1+ , endof
    [ char < ] literal of ' 1- , endof
    [ char + ] literal of ' dup , ' c@ , ' 1+ , ' over , ' c! , endof
    [ char - ] literal of ' dup , ' c@ , ' 1- , ' over , ' c! , endof
    [ char [ ] literal of here @ ' dup , ' c@ , ' 0branch , here @ 0 , endof 
    [ char ] ] literal of ' branch , swap here @ - ,  
        dup here @ swap - swap ! endof 
    [ char . ] literal of ' dup , ' c@ , ' emit , endof
    [ char , ] literal of ' key , ' over , ' c! , endof
    endcase
    repeat drop ' drop ,
    state @ 0= if ' quit , dup here ! execute then
; immediate

\ example usage
: cat here @ bf ,[.,]; ;
\ or to execute immediately
1 cells allot bf ,[.,]; 

\ add two numbers
here @ dup 34 c, 39 c, align bf >[-<+>]; dup @ here !


( it would be nice if the bf could operate directly on the stack..
    and use the stack as it's memory.
)


