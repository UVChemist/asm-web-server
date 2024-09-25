.intel_syntax noprefix
.global _start

.section .bss
buffer:
  .space 512

.section .data
http_response:
  .string "HTTP/1.0 200 OK\r\n\r\n"

.section .text

_start:
  mov rbp, rsp
  sub rsp, 0x8              # This block pushes the bind arguments and calls the socket syscall
  push 0x0000000050000002
  mov r10, rsp
  mov rdi, 2
  mov rsi, 1
  mov rdx, 0
  mov rax, 41
  syscall
  add rsp, 0x8
  mov rsp, rbp

  mov rdi, rax              # bind syscall
  mov rsi, r10
  mov rdx, 16
  mov rax, 49
  syscall

  mov rsi, 0                # listen syscall
  mov rax, 50
  syscall

  Accept:
    mov rsi, 0              # accept syscall
    mov rdx, 0
    mov rax, 43
    syscall

  push rax
  mov rax, 57               # fork()
  syscall

  cmp rax, 0
  jne Parent
  jmp Child

  Parent:                   # close connection to child owned fd, jump back to Accept
    pop rdi
    push rdi
    mov rax, 3
    syscall

    pop rdi
    dec rdi
    jmp Accept

  Child:                    # close connection to parent owned fd, continue execution
    pop rdi
    dec rdi
    mov rax, 3
    syscall

    inc rdi
    lea rsi, [buffer]       # call the read syscall
    mov rdx, 600
    mov rax, 0
    syscall
    push rax
    push rdi

    mov r9b, byte ptr [buffer]
    cmp r9b, 71
    jne Post
    jmp Get

  Get:
    lea rdi, [buffer+4]     # call the open syscall
    lea r10, [buffer+20]
    mov byte ptr [r10], 0
    mov rsi, 0
    mov rax, 2
    syscall

    mov rdi, rax            # read
    lea rsi, [buffer]
    mov rax, 0
    syscall
    push rax

    mov rax, 3              # close
    syscall

    mov r10, 0
    mov rdx, 19
    lea rsi, http_response
    inc rdi
    mov rax, 1
    syscall

  WriteGet:                 # write
    pop rdx
    lea rsi, [buffer]
    mov rax, 1
    syscall
    push rax

    jmp Exit

  Post:
    lea rdi, [buffer+5]     # call the open syscall
    lea r10, [buffer+21]
    mov byte ptr [r10], 0
    mov rsi, 1
    or rsi, 0100
    mov rdx, 0777
    mov rax, 2
    syscall

    mov r8, 0
    mov r11, 0

  Parse:                    # parse the text to get the response body
    mov r9b, byte ptr [buffer+r11]
    add r11, 1
    cmp r9b, 10
    jne Parse
    inc r8
    cmp r8, 8
    jl Parse
    #inc r11
    lea rdi, [buffer+r11]

  mov rsi, rdi              # call the write syscall
  pop rdi
  dec rdi
  pop rdx
  sub rdx, r11
  mov rax, 1
  syscall
  push rax

  mov rax, 3
  syscall

  mov r10, 0
  mov rdx, 19
  lea rsi, http_response
  inc rdi
  mov rax, 1
  syscall

  Exit:
    xor rdi, rdi            # exit
    mov rsi, 0
    mov rdx, 0
    mov rax, 60
    syscall

