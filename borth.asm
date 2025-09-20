; jonesforth translated from gas x86 to nasm x86-64

%define BORTH_VERSION 1

%macro NEXT 0
        lodsq
        jmp [rax]
%endmacro


; Macros for the return stack
%macro PUSHRSP 1
        lea rbp,[rbp-8]
        mov [rbp],%1
%endmacro

%macro POPRSP 1 
        mov %1, [rbp]
        lea rbp,[rbp+8]
%endmacro


section .text
        align 8, db 0
DOCOL: 
        PUSHRSP rsi
        lea rsi, [rax+8]
        NEXT





section .text
global _start
_start:
        cld
        mov [var_SZ], rsp
        mov rbp, return_stack_top
        call set_up_data_segment

        mov rsi,cold_start
        NEXT

section .rodata
cold_start:
        dq QUIT



%define F_IMMED 0x80
%define F_HIDDEN 0x20
%define F_LENMASK 0x1f

%define link 0


%macro defword 3 ; first argument is string name,  second is flags
                 ;third argument is label
section .rodata
        align 8, db 0
name_%3:
        dq link ; pointer to next word    
        %define link name_%3
        %strlen len_%3 %1
        db %2 + len_%3 ; flags/length of name
        db %1 ; word name
        align 8, db 0
%3:
        dq DOCOL
%endmacro

%macro defword 2 ; no flags version
        defword %1, 0 , %2
%endmacro


%macro defcode 3 ; first argument is string name,  second is flags
                 ;third argument is label
section .rodata
        align 8, db 0
name_%3:
        dq link ; pointer to next word    
        %define link name_%3
        %strlen len_%3 %1
        db %2 + len_%3 ; flags/length of name
        db %1 ; word name
        align 8, db 0
%3:
        dq code_%3
section .text
code_%3:
%endmacro

%macro defcode 2 ; no flags version
        defcode %1, 0, %2
%endmacro


defcode "drop", DROP
pop rax
NEXT

defcode "swap", SWAP
pop rax
pop rbx
push rax
push rbx
NEXT

defcode "dup", DUP
mov rax,[rsp]
push rax
NEXT

defcode "over", OVER
mov rax, [rsp+8]
push rax
NEXT

defcode "rot", ROT
pop rax
pop rbx
pop rcx
push rbx
push rax
push rcx
NEXT

defcode "-rot", NROT
pop rax
pop rbx
pop rcx
push rax
push rcx
push rbx
NEXT

defcode "2drop", TWODROP
pop rax
pop rax
NEXT

defcode "2dup", TWODUP
mov rax, [rsp]
mov rbx, [rsp+8]
push rbx
push rax
NEXT

defcode "2swap", TWOSWAP
pop rax
pop rbx
pop rcx
pop rdx
push rbx
push rax
push rdx
push rcx
NEXT

defcode "?dup", QDUP
mov rax, [rsp]
test rax,rax
jz .end
push rax
.end: NEXT



defcode "1+",INCR
inc qword [rsp]
NEXT

defcode "1-", DECR
dec qword [rsp]
NEXT

defcode "8+", INCR8
add qword [rsp], 8
NEXT

defcode "8-", DECR8
sub qword [rsp], 8
NEXT

defcode "+", ADD
pop rax
add [rsp],rax
NEXT

defcode "-", SUB
pop rax
sub [rsp],rax
NEXT

defcode "*", MUL
pop rax
pop rbx
imul rax,rbx
push rax
NEXT

defcode "/mod", DIVMOD
xor rdx,rdx
pop rbx
pop rax
idiv rbx
push rdx
push rax
NEXT



defcode "=", EQU
pop rax
pop rbx
cmp rax,rbx
sete al
movzx rax, al
push rax
NEXT

defcode "<>", NEQU
pop rax
pop rbx
cmp rax,rbx
setne al
movzx rax, al
push rax
NEXT

defcode "<", LT
pop rbx
pop rax
cmp rax,rbx
setl al
movzx rax, al
push rax
NEXT

defcode ">", GT
pop rbx
pop rax
cmp rax,rbx
setg al
movzx rax, al
push rax
NEXT

defcode "<=", LE
pop rbx
pop rax
cmp rax,rbx
setle al
movzx rax, al
push rax
NEXT

defcode ">=", GE
pop rbx
pop rax
cmp rax,rbx
setge al
movzx rax, al
push rax
NEXT

defcode "0=", ZEQU
pop rax
test rax,rax
setz al
movzx rax, al
push rax
NEXT

defcode "0<>", ZNEQU
pop rax
test rax,rax
setnz al
movzx rax, al
push rax
NEXT

defcode "0<", ZLT
pop rax
test rax,rax
setl al
movzx rax, al
push rax
NEXT

defcode "0>", ZGT
pop rax
test rax,rax
setg al
movzx rax, al
push rax
NEXT

defcode "0<=", ZLE
pop rax
test rax,rax
setle al
movzx rax, al
push rax
NEXT

defcode "0>=", ZGE
pop rax
test rax,rax
setge al
movzx rax, al
push rax
NEXT

defcode "and", AND
pop rax
and [rsp], rax
NEXT

defcode "or", OR
pop rax
or [rsp], rax
NEXT

defcode "xor", XOR
pop rax
xor [rsp],rax
NEXT

defcode "invert", INVERT
not qword [rsp]
NEXT



defcode "exit", EXIT
POPRSP rsi
NEXT



defcode "lit", LIT
lodsq
push rax
NEXT


defcode "!", STORE
pop rax
pop rbx
mov [rax], rbx
NEXT

defcode "@", FETCH
pop rbx
mov rax,[rbx]
push rax
NEXT

defcode "+!", ADDSTORE
pop rax
pop rbx
add [rax], rbx
NEXT

defcode "-!", SUBSTORE
pop rax
pop rbx
sub [rax], rbx
NEXT

defcode "c!", STOREBYTE
pop rax
pop rbx
mov [rax], bl
NEXT

defcode "c@", FETCHBYTE
pop rbx
xor rax,rax
mov al, [rbx] 
push rax
NEXT

defcode "c@c!", CCOPY
mov rbx, [rsp+8]
mov al, [rbx]
pop rdi
stosb
push rdi
inc qword [rsp+8]
NEXT

defcode "cmove", CMOVE
mov rdx,rsi
pop rcx
pop rdi
pop rsi
rep movsb
mov rsi,rdx
NEXT


%macro defvar 4
        defcode %1, %2, %3
        push var_%3
        NEXT
section .data
        align 8, db 0
var_%3:
        dq %4
%endmacro

%macro defvar 3
        defvar %1,0,%2,%3
%endmacro

%macro defvar 2
        defvar %1,0,%2,0
%endmacro


defvar "state", STATE
defvar "here", HERE
defvar "latest",LATEST,name_SYSCALL0
defvar "s0",SZ
defvar "base",BASE,10

%macro defconst 4
        defcode %1,%2,%3
        push %4
        NEXT
%endmacro

%macro defconst 3
        defconst %1,0,%2,%3
%endmacro

defconst "version",VERSION,BORTH_VERSION
defconst "r0",RZ,return_stack_top
defconst "docol",__DOCOL,DOCOL
defconst "f_immed",__F_IMMED,F_IMMED
defconst "f_hidden",__F_HIDDEN,F_HIDDEN
defconst "f_lenmask",__F_LENMASK,F_LENMASK

defconst "sys_exit",SYS_EXIT, 60
defconst "sys_open",SYS_OPEN, 2
defconst "sys_close",SYS_CLOSE,3
defconst "sys_read",SYS_READ,0
defconst "sys_write",SYS_WRITE,1        
defconst "sys_creat",SYS_CREAT, 85        
defconst "sys_brk",SYS_BRK, 12   

defconst "o_rdonly",__O_RDONLY,0
defconst "o_wronly",__O_WRONLY,1
defconst "o_rdwr",__O_RDWR,2
defconst "o_creat",__O_CREAT,0100
defconst "o_excl",__O_EXCL,0200
defconst "o_trunc",__O_TRUNC,01000
defconst "o_append",__O_APPEND,02000
defconst "o_nonblock",__O_NONBLOCK,04000



defcode ">r",TOR
pop rax
PUSHRSP rax
NEXT

defcode "r>",FROMR
POPRSP rax
push rax
NEXT        

defcode "rsp@",RSPFETCH
push rbp
NEXT

defcode "rsp!",RSPSTORE
pop rbp
NEXT

defcode "rdrop",RDROP
add rbp,8
NEXT

defcode "dsp@", DSPFETCH
push rsp
NEXT

defcode "dsp!", DSPSTORE
pop rsp
NEXT


%define BUFFER_SIZE 4096

defcode "key", KEY
call _KEY
push rax
NEXT

_KEY:
        mov rbx, [currkey]            
        cmp rbx, [bufftop]
        jge .update_buffer
        xor rax,rax
        mov al, [rbx]
        inc qword [currkey]
        ret

.update_buffer:
        push rsi
        push rdi
        xor rdi,rdi ; stdin
        mov rsi,buffer
        mov [currkey],rsi
        mov rdx,BUFFER_SIZE
        mov rax,0
        syscall
        test rax,rax
        jbe .exit
        add rsi, rax
        mov [bufftop], rsi
        pop rdi
        pop rsi
        jmp _KEY

.exit:
        xor rdi,rdi
        mov rax,60
        syscall

section .data
        align 8, db 0
currkey: dq buffer
bufftop: dq buffer
        

defcode "emit", EMIT
pop rax
call _EMIT
NEXT

_EMIT:
        push rsi
        mov rdi,1
        mov [emit_scratch], al
        mov rsi,emit_scratch
        mov rdx,1
        mov rax,1
        syscall
        pop rsi
        ret

section .data
emit_scratch: db 0



defcode "word", RWORD
call _WORD
push rdi
push rcx
NEXT

_WORD:
        call _KEY
        cmp al,'\'
        je .comment
        cmp al,' '        
        jbe _WORD

        mov rdi,word_buffer
.store:
        stosb
        call _KEY
        cmp al,' '
        ja .store

        sub rdi,word_buffer
        mov rcx, rdi
        mov rdi,word_buffer
        ret
        
.comment: 
        call _KEY
        cmp al, 10 ; new line
        jne .comment
        jmp _WORD

section .data
word_buffer: times 32 db 0


defcode "number",NUMBER
pop rcx
pop rdi
call _NUMBER
push rax
push rcx
NEXT

_NUMBER:
        xor rax,rax
        xor rbx,rbx
        test rcx,rcx
        jz .ret

        mov rdx, [var_BASE]

        mov bl,[rdi]
        inc rdi
        push rax
        cmp bl,'-'
        jnz .convert
        mov [rsp], rbx
        dec rcx
        jnz .new_digit
        pop rbx
        mov rcx,1
        ret  
.new_digit:
        imul rax,rdx
        mov bl, [rdi]
        inc rdi
.convert:
        sub bl,'0'
        jb .done
        cmp bl,10
        jb .continue
        sub bl,17 ; 'A'
        jb .done
        add bl,10 ; letters represent numbers from 10->
.continue:
        cmp bl,dl
        jge .done

        add rax,rbx
        dec rcx
        jnz .new_digit

.done:  
        pop rbx
        test rbx,rbx
        jz .ret
        neg rax

.ret:   ret


defcode "find",FIND
pop rcx
pop rdi
call _FIND
push rax
NEXT

_FIND:
        push rsi
        mov rdx, [var_LATEST]
.loop:
        test rdx,rdx
        je .not_found

        xor rax,rax
        mov al, [rdx+8]
        and al, F_HIDDEN | F_LENMASK
        cmp al,cl
        jne .next_word

        push rcx
        push rdi
        lea rsi,[rdx+9]
        repe cmpsb
        pop rdi
        pop rcx
        jne .next_word

        mov rax,rdx
        pop rsi
        ret

.next_word:
        mov rdx, [rdx]
        jmp .loop

.not_found:
        xor rax,rax
        pop rsi
        ret

defcode ">cfa",TCFA
pop rdi
call _TCFA
push rdi
NEXT

_TCFA: 
        xor rax,rax
        add rdi,8
        mov al,[rdi]
        inc rdi
        and al,F_LENMASK
        add rdi,rax

        add rdi,7 ; codeword is 8-bit aligned
        and rdi,~7
        ret

defword ">dfa",TDFA
dq TCFA
dq INCR8
dq EXIT



defcode "create", CREATE
pop rcx
pop rbx

mov rdi,[var_HERE]
mov rax,[var_LATEST]
stosq

mov al,cl
stosb
push rsi
mov rsi,rbx
rep movsb
pop rsi
add rdi,7 ; align 8-bit
and rdi,~7

mov rax,[var_HERE]
mov [var_LATEST], rax
mov [var_HERE],rdi
NEXT


defcode ",", COMMA
pop rax
call _COMMA
NEXT
_COMMA:
        mov rdi,[var_HERE]
        stosq
        mov [var_HERE],rdi
        ret


defcode "[",F_IMMED,LBRAC
xor rax,rax
mov [var_STATE],rax
NEXT

defcode "]",RBRAC
mov qword [var_STATE],1
NEXT

defword ":",COLON
dq RWORD
dq CREATE
dq LIT, DOCOL, COMMA
dq LATEST,FETCH,HIDDEN
dq RBRAC
dq EXIT


defword ";",F_IMMED,SEMICOLON
dq LIT, EXIT, COMMA
dq LATEST, FETCH, HIDDEN
dq LBRAC
dq EXIT

defcode "immediate",F_IMMED,IMMEDIATE
mov rdi,[var_LATEST]
add rdi,8
xor byte [rdi],F_IMMED
NEXT

defcode "hidden",HIDDEN
pop rdi
add rdi,8
xor byte [rdi],F_HIDDEN
NEXT

defword "hide",HIDE
dq RWORD
dq FIND
dq HIDDEN
dq EXIT


defcode "'",TICK
lodsq
push rax
NEXT
        

defcode "branch", BRANCH
add rsi,[rsi]
NEXT

defcode "0branch", ZBRANCH
pop rax
test rax,rax
jz code_BRANCH
lodsq
NEXT


defcode "litstring",LITSTRING
lodsq
push rsi
push rax
add rsi,rax
add rsi,7
and rsi,~7
NEXT

defcode "tell",TELL
mov rbx,rsi
mov rdi,1
pop rdx
pop rsi
mov rax,1
syscall
mov rsi,rbx
NEXT


defword "quit",QUIT
dq RZ, RSPSTORE
dq INTERPRET
dq BRANCH,-16


defcode "interpret",INTERPRET
        call _WORD ; rcx: len, rdi: char pointer

        xor rax,rax
        mov [interpret_is_lit],rax
        call _FIND ; rax: pointer to header, or 0 not found
        test rax,rax
        jz .not_in_dict
        
        mov rdi,rax 
        mov al,[rdi+8]
        push ax
        call _TCFA
        pop ax
        and al,F_IMMED
        mov rax,rdi
        jnz .execute
        jmp .comp_or_exec
        
.not_in_dict:
        inc qword [interpret_is_lit]
        call _NUMBER ;number in rax, error in rcx
        test rcx,rcx
        jnz .error
        mov rbx,rax
        mov rax,LIT

.comp_or_exec:
        mov rdx,[var_STATE]
        test rdx,rdx
        jz .execute
        ; compile         
        call _COMMA
        mov rcx, [interpret_is_lit]
        test rcx,rcx
        jz .next
        mov rax,rbx
        call _COMMA
.next:  NEXT

.execute:
        mov rcx, [interpret_is_lit]
        test rcx,rcx 
        jnz .exec_lit

        jmp [rax]
.exec_lit:
        push rbx
        NEXT

.error:
        push rsi
        mov rdi, 2
        mov rsi, errmsg        
        mov rdx, errmsgend-errmsg
        mov rax,1
        syscall

        mov rsi,[currkey]
        mov rdx,rsi
        sub rdx,buffer
        cmp rdx,40
        jle .skip
        mov rdx,40
.skip:  sub rsi,rdx
        mov rax,1
        syscall

        mov rsi,errmsgnl
        mov rdx,1
        mov rax,1
        syscall
        pop rsi
        NEXT


section .rodata
errmsg: db "PARSE ERROR: "
errmsgend:
errmsgnl: db 10

section .data
align 8, db 0
interpret_is_lit: dq 0


defcode "char",CHAR
call _WORD
xor rax,rax
mov al,[rdi]
push rax
NEXT

defcode "execute",EXECUTE
pop rax
jmp [rax]
NEXT

defcode "syscall3",SYSCALL3
mov r15,rsi
pop rax
pop rdi
pop rsi
pop rdx
syscall
push rax
mov rsi,r15
NEXT

defcode "syscall2",SYSCALL2
mov r15,rsi
pop rax
pop rdi
pop rsi
syscall
push rax
mov rsi,r15
NEXT

defcode "syscall1",SYSCALL1
pop rax
pop rdi
syscall
push rax
NEXT

defcode "syscall0",SYSCALL0
pop rax
syscall
push rax
NEXT


section .text
%define INITIAL_DATA_SEGMENT_SIZE 65536
set_up_data_segment:
        xor rdi,rdi
        mov rax,12
        syscall
        mov [var_HERE],rax
        add rax, INITIAL_DATA_SEGMENT_SIZE
        mov rdi,rax
        mov rax,12
        syscall
        ret

%define RETURN_STACK_SIZE 8192

section .bss
align 4096, db 0
return_stack:
resb RETURN_STACK_SIZE
return_stack_top:

align 4096, db 0
buffer:
resb BUFFER_SIZE 

