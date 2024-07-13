// WEBSERVER ARM64 ASSEMBLY
// SIMPLE AND USELESS PROGRAM TO IMPLEMENT SOME BASIC STUFF ABOUT WEBSERVER 
// AUTHOR: MIRUCHIGAWA <moe@miwudev.my.id> [www.miwudev.xyz]

// SOLVED PORT ISSUE SEE: https://stackoverflow.com/questions/57906952/hword-endianness-on-arm

.section .data
// SOCKET ADDR PORT (8080) ON (*) ADDR
saddr:
    .hword 2                        // AF_INET
    .hword 0                        // REDECLARE!
    .word 0                         // (*)
    .byte 0, 0, 0, 0, 0, 0, 0, 0    // __pad

// RESPONSE THAT WE SEND TO OUR CLIENT
response:
    .asciz "HTTP/1.1 200 OK\r\nContent-Length: 21\r\nContent-Type: text/html\r\n\r\n<h1>Hello World</h1>"

.section .bss
.balign 4
buffer:
    .space 1024                     // 1024 bytes of buffer

.section .text
.global _start

_start:
    // HARD IMPLEMENT CONVERT PORT TO NETWORK BYTE ORDER
    mov w0, 8080                    // PORT (8080)
    bl htons
    ldr x1, =saddr
    strh w0, [x1, #2]

    // CREATE SOCKET
    mov x0, 2                       // domain = AF_INET
    mov x1, 1                       // type = SOCK_SREAM
    mov x2, 0                       // protocol = (0) 
    mov x8, 198
    svc 0
    mov x19, x0
    cmp x19, 0
    blt exit                        // EXIT PROGRAM IF FAILED TO CREATE SOCKET


    // BIND SOCKET
    mov x0, x19                     // sockfd (WE STORE sockfd AT x19)
    ldr x1, =saddr                  // *saddr 
    mov x2, 16                      // sizeof struct sockaddr_in
    mov x8, 200 
    svc 0
    cmp x0, 0
    blt exit                        // EXIT PROGRAM IF FAILED TO BIND

    // LISTEN CONNECTION
    mov x0, x19                     // sockfd
    mov x1, 10                      // backlog = (10)
    mov x8, 201
    svc 0
    cmp x0, 0
    blt exit                        // EXIT PROGRAM IF FAILED TO LISTEM CONNECTION

loop:
    // ACCEPT CONNECTION
    sub sp, sp, 16                  // ALOCATE SPACE FOR clientaddr_len and clientaddr (FOR STORE CLIENT ADDRESS)
    mov x0, x19
    mov x1, sp                      // *clientaddr 
    add x2, sp, 8                   // *clientaddr_len
    mov w3, 16                      // INITIALIZE clientaddr_len (sizeof(struct sockaddr_in))
    str w3, [x2]                    
    mov x8, 202
    svc 0
    mov x20, x0                     
    cmp x0, 0
    blt close                       // CLOSE CONNECTION 

    // READ REQUEST
    mov x0, x20 
    ldr x1, =buffer 
    mov x2, 1024 
    mov x8, 63
    svc 0

    // SEND RESPONSE 
    mov x0, x20 
    ldr x1, =response
    mov x2, 100
    mov x8, 64
    svc 0

close:
    mov x0, x20
    mov x8, 57
    svc 0
    add sp, sp, 16
    b loop

exit:
    mov x0, 1 
    mov x8, 93
    svc 0

htons:
    mov w1, w0, lsr #8         
    bfi w0, w0, #8, #8        
    bfi w0, w1, #0, #8
    ret

