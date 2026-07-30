
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	1f813103          	ld	sp,504(sp) # 8000a1f8 <_GLOBAL_OFFSET_TABLE_+0x8>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04a000ef          	jal	80000060 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	stimecmp,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb0b7>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	dbc78793          	addi	a5,a5,-580 # 80000e3c <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:
// user write() system calls to the console go here.
// uses sleep() and UART interrupts.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7119                	addi	sp,sp,-128
    800000d2:	fc86                	sd	ra,120(sp)
    800000d4:	f8a2                	sd	s0,112(sp)
    800000d6:	f4a6                	sd	s1,104(sp)
    800000d8:	0100                	addi	s0,sp,128
  char buf[32]; // move batches from user space to uart.
  int i = 0;

  while(i < n){
    800000da:	06c05a63          	blez	a2,8000014e <consolewrite+0x7e>
    800000de:	f0ca                	sd	s2,96(sp)
    800000e0:	ecce                	sd	s3,88(sp)
    800000e2:	e8d2                	sd	s4,80(sp)
    800000e4:	e4d6                	sd	s5,72(sp)
    800000e6:	e0da                	sd	s6,64(sp)
    800000e8:	fc5e                	sd	s7,56(sp)
    800000ea:	f862                	sd	s8,48(sp)
    800000ec:	f466                	sd	s9,40(sp)
    800000ee:	8aaa                	mv	s5,a0
    800000f0:	8b2e                	mv	s6,a1
    800000f2:	8a32                	mv	s4,a2
  int i = 0;
    800000f4:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f6:	02000c13          	li	s8,32
    800000fa:	02000c93          	li	s9,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fe:	5bfd                	li	s7,-1
    80000100:	a035                	j	8000012c <consolewrite+0x5c>
    if(nn > n - i)
    80000102:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000106:	86ce                	mv	a3,s3
    80000108:	01648633          	add	a2,s1,s6
    8000010c:	85d6                	mv	a1,s5
    8000010e:	f8040513          	addi	a0,s0,-128
    80000112:	252020ef          	jal	80002364 <either_copyin>
    80000116:	03750e63          	beq	a0,s7,80000152 <consolewrite+0x82>
      break;
    uartwrite(buf, nn);
    8000011a:	85ce                	mv	a1,s3
    8000011c:	f8040513          	addi	a0,s0,-128
    80000120:	778000ef          	jal	80000898 <uartwrite>
    i += nn;
    80000124:	009904bb          	addw	s1,s2,s1
  while(i < n){
    80000128:	0144da63          	bge	s1,s4,8000013c <consolewrite+0x6c>
    if(nn > n - i)
    8000012c:	409a093b          	subw	s2,s4,s1
    80000130:	0009079b          	sext.w	a5,s2
    80000134:	fcfc57e3          	bge	s8,a5,80000102 <consolewrite+0x32>
    80000138:	8966                	mv	s2,s9
    8000013a:	b7e1                	j	80000102 <consolewrite+0x32>
    8000013c:	7906                	ld	s2,96(sp)
    8000013e:	69e6                	ld	s3,88(sp)
    80000140:	6a46                	ld	s4,80(sp)
    80000142:	6aa6                	ld	s5,72(sp)
    80000144:	6b06                	ld	s6,64(sp)
    80000146:	7be2                	ld	s7,56(sp)
    80000148:	7c42                	ld	s8,48(sp)
    8000014a:	7ca2                	ld	s9,40(sp)
    8000014c:	a819                	j	80000162 <consolewrite+0x92>
  int i = 0;
    8000014e:	4481                	li	s1,0
    80000150:	a809                	j	80000162 <consolewrite+0x92>
    80000152:	7906                	ld	s2,96(sp)
    80000154:	69e6                	ld	s3,88(sp)
    80000156:	6a46                	ld	s4,80(sp)
    80000158:	6aa6                	ld	s5,72(sp)
    8000015a:	6b06                	ld	s6,64(sp)
    8000015c:	7be2                	ld	s7,56(sp)
    8000015e:	7c42                	ld	s8,48(sp)
    80000160:	7ca2                	ld	s9,40(sp)
  }

  return i;
}
    80000162:	8526                	mv	a0,s1
    80000164:	70e6                	ld	ra,120(sp)
    80000166:	7446                	ld	s0,112(sp)
    80000168:	74a6                	ld	s1,104(sp)
    8000016a:	6109                	addi	sp,sp,128
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dst indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	0b450513          	addi	a0,a0,180 # 80012240 <cons>
    80000194:	23b000ef          	jal	80000bce <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00012497          	auipc	s1,0x12
    8000019c:	0a848493          	addi	s1,s1,168 # 80012240 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00012917          	auipc	s2,0x12
    800001a4:	13890913          	addi	s2,s2,312 # 800122d8 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	716010ef          	jal	800018ce <myproc>
    800001bc:	03a020ef          	jal	800021f6 <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	5f9010ef          	jal	80001fbe <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	00012717          	auipc	a4,0x12
    800001dc:	06870713          	addi	a4,a4,104 # 80012240 <cons>
    800001e0:	0017869b          	addiw	a3,a5,1
    800001e4:	08d72c23          	sw	a3,152(a4)
    800001e8:	07f7f693          	andi	a3,a5,127
    800001ec:	9736                	add	a4,a4,a3
    800001ee:	01874703          	lbu	a4,24(a4)
    800001f2:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001f6:	4691                	li	a3,4
    800001f8:	04db8663          	beq	s7,a3,80000244 <consoleread+0xd6>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    800001fc:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000200:	4685                	li	a3,1
    80000202:	faf40613          	addi	a2,s0,-81
    80000206:	85d2                	mv	a1,s4
    80000208:	8556                	mv	a0,s5
    8000020a:	110020ef          	jal	8000231a <either_copyout>
    8000020e:	57fd                	li	a5,-1
    80000210:	04f50863          	beq	a0,a5,80000260 <consoleread+0xf2>
      break;

    dst++;
    80000214:	0a05                	addi	s4,s4,1
    --n;
    80000216:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000218:	47a9                	li	a5,10
    8000021a:	04fb8d63          	beq	s7,a5,80000274 <consoleread+0x106>
    8000021e:	6be2                	ld	s7,24(sp)
    80000220:	b761                	j	800001a8 <consoleread+0x3a>
        release(&cons.lock);
    80000222:	00012517          	auipc	a0,0x12
    80000226:	01e50513          	addi	a0,a0,30 # 80012240 <cons>
    8000022a:	23d000ef          	jal	80000c66 <release>
        return -1;
    8000022e:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000230:	60e6                	ld	ra,88(sp)
    80000232:	6446                	ld	s0,80(sp)
    80000234:	64a6                	ld	s1,72(sp)
    80000236:	6906                	ld	s2,64(sp)
    80000238:	79e2                	ld	s3,56(sp)
    8000023a:	7a42                	ld	s4,48(sp)
    8000023c:	7aa2                	ld	s5,40(sp)
    8000023e:	7b02                	ld	s6,32(sp)
    80000240:	6125                	addi	sp,sp,96
    80000242:	8082                	ret
      if(n < target){
    80000244:	0009871b          	sext.w	a4,s3
    80000248:	01677a63          	bgeu	a4,s6,8000025c <consoleread+0xee>
        cons.r--;
    8000024c:	00012717          	auipc	a4,0x12
    80000250:	08f72623          	sw	a5,140(a4) # 800122d8 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	00012517          	auipc	a0,0x12
    80000266:	fde50513          	addi	a0,a0,-34 # 80012240 <cons>
    8000026a:	1fd000ef          	jal	80000c66 <release>
  return target - n;
    8000026e:	413b053b          	subw	a0,s6,s3
    80000272:	bf7d                	j	80000230 <consoleread+0xc2>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	b7f5                	j	80000262 <consoleread+0xf4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50863          	beq	a0,a5,80000294 <consputc+0x1c>
    uartputc_sync(c);
    80000288:	6a4000ef          	jal	8000092c <uartputc_sync>
}
    8000028c:	60a2                	ld	ra,8(sp)
    8000028e:	6402                	ld	s0,0(sp)
    80000290:	0141                	addi	sp,sp,16
    80000292:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000294:	4521                	li	a0,8
    80000296:	696000ef          	jal	8000092c <uartputc_sync>
    8000029a:	02000513          	li	a0,32
    8000029e:	68e000ef          	jal	8000092c <uartputc_sync>
    800002a2:	4521                	li	a0,8
    800002a4:	688000ef          	jal	8000092c <uartputc_sync>
    800002a8:	b7d5                	j	8000028c <consputc+0x14>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	1000                	addi	s0,sp,32
    800002b4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b6:	00012517          	auipc	a0,0x12
    800002ba:	f8a50513          	addi	a0,a0,-118 # 80012240 <cons>
    800002be:	111000ef          	jal	80000bce <acquire>

  switch(c){
    800002c2:	47d5                	li	a5,21
    800002c4:	08f48f63          	beq	s1,a5,80000362 <consoleintr+0xb8>
    800002c8:	0297c563          	blt	a5,s1,800002f2 <consoleintr+0x48>
    800002cc:	47a1                	li	a5,8
    800002ce:	0ef48463          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    800002d2:	47c1                	li	a5,16
    800002d4:	10f49563          	bne	s1,a5,800003de <consoleintr+0x134>
  case C('P'):  // Print process list.
    procdump();
    800002d8:	0d6020ef          	jal	800023ae <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	00012517          	auipc	a0,0x12
    800002e0:	f6450513          	addi	a0,a0,-156 # 80012240 <cons>
    800002e4:	183000ef          	jal	80000c66 <release>
}
    800002e8:	60e2                	ld	ra,24(sp)
    800002ea:	6442                	ld	s0,16(sp)
    800002ec:	64a2                	ld	s1,8(sp)
    800002ee:	6105                	addi	sp,sp,32
    800002f0:	8082                	ret
  switch(c){
    800002f2:	07f00793          	li	a5,127
    800002f6:	0cf48063          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002fa:	00012717          	auipc	a4,0x12
    800002fe:	f4670713          	addi	a4,a4,-186 # 80012240 <cons>
    80000302:	0a072783          	lw	a5,160(a4)
    80000306:	09872703          	lw	a4,152(a4)
    8000030a:	9f99                	subw	a5,a5,a4
    8000030c:	07f00713          	li	a4,127
    80000310:	fcf766e3          	bltu	a4,a5,800002dc <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000314:	47b5                	li	a5,13
    80000316:	0cf48763          	beq	s1,a5,800003e4 <consoleintr+0x13a>
      consputc(c);
    8000031a:	8526                	mv	a0,s1
    8000031c:	f5dff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000320:	00012797          	auipc	a5,0x12
    80000324:	f2078793          	addi	a5,a5,-224 # 80012240 <cons>
    80000328:	0a07a683          	lw	a3,160(a5)
    8000032c:	0016871b          	addiw	a4,a3,1
    80000330:	0007061b          	sext.w	a2,a4
    80000334:	0ae7a023          	sw	a4,160(a5)
    80000338:	07f6f693          	andi	a3,a3,127
    8000033c:	97b6                	add	a5,a5,a3
    8000033e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000342:	47a9                	li	a5,10
    80000344:	0cf48563          	beq	s1,a5,8000040e <consoleintr+0x164>
    80000348:	4791                	li	a5,4
    8000034a:	0cf48263          	beq	s1,a5,8000040e <consoleintr+0x164>
    8000034e:	00012797          	auipc	a5,0x12
    80000352:	f8a7a783          	lw	a5,-118(a5) # 800122d8 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	00012717          	auipc	a4,0x12
    80000368:	edc70713          	addi	a4,a4,-292 # 80012240 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	00012497          	auipc	s1,0x12
    80000378:	ecc48493          	addi	s1,s1,-308 # 80012240 <cons>
    while(cons.e != cons.w &&
    8000037c:	4929                	li	s2,10
    8000037e:	02f70863          	beq	a4,a5,800003ae <consoleintr+0x104>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000382:	37fd                	addiw	a5,a5,-1
    80000384:	07f7f713          	andi	a4,a5,127
    80000388:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000038a:	01874703          	lbu	a4,24(a4)
    8000038e:	03270263          	beq	a4,s2,800003b2 <consoleintr+0x108>
      cons.e--;
    80000392:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000396:	10000513          	li	a0,256
    8000039a:	edfff0ef          	jal	80000278 <consputc>
    while(cons.e != cons.w &&
    8000039e:	0a04a783          	lw	a5,160(s1)
    800003a2:	09c4a703          	lw	a4,156(s1)
    800003a6:	fcf71ee3          	bne	a4,a5,80000382 <consoleintr+0xd8>
    800003aa:	6902                	ld	s2,0(sp)
    800003ac:	bf05                	j	800002dc <consoleintr+0x32>
    800003ae:	6902                	ld	s2,0(sp)
    800003b0:	b735                	j	800002dc <consoleintr+0x32>
    800003b2:	6902                	ld	s2,0(sp)
    800003b4:	b725                	j	800002dc <consoleintr+0x32>
    if(cons.e != cons.w){
    800003b6:	00012717          	auipc	a4,0x12
    800003ba:	e8a70713          	addi	a4,a4,-374 # 80012240 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	00012717          	auipc	a4,0x12
    800003d0:	f0f72a23          	sw	a5,-236(a4) # 800122e0 <cons+0xa0>
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	ea1ff0ef          	jal	80000278 <consputc>
    800003dc:	b701                	j	800002dc <consoleintr+0x32>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003de:	ee048fe3          	beqz	s1,800002dc <consoleintr+0x32>
    800003e2:	bf21                	j	800002fa <consoleintr+0x50>
      consputc(c);
    800003e4:	4529                	li	a0,10
    800003e6:	e93ff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003ea:	00012797          	auipc	a5,0x12
    800003ee:	e5678793          	addi	a5,a5,-426 # 80012240 <cons>
    800003f2:	0a07a703          	lw	a4,160(a5)
    800003f6:	0017069b          	addiw	a3,a4,1
    800003fa:	0006861b          	sext.w	a2,a3
    800003fe:	0ad7a023          	sw	a3,160(a5)
    80000402:	07f77713          	andi	a4,a4,127
    80000406:	97ba                	add	a5,a5,a4
    80000408:	4729                	li	a4,10
    8000040a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000040e:	00012797          	auipc	a5,0x12
    80000412:	ecc7a723          	sw	a2,-306(a5) # 800122dc <cons+0x9c>
        wakeup(&cons.r);
    80000416:	00012517          	auipc	a0,0x12
    8000041a:	ec250513          	addi	a0,a0,-318 # 800122d8 <cons+0x98>
    8000041e:	3ed010ef          	jal	8000200a <wakeup>
    80000422:	bd6d                	j	800002dc <consoleintr+0x32>

0000000080000424 <consoleinit>:

void
consoleinit(void)
{
    80000424:	1141                	addi	sp,sp,-16
    80000426:	e406                	sd	ra,8(sp)
    80000428:	e022                	sd	s0,0(sp)
    8000042a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000042c:	00007597          	auipc	a1,0x7
    80000430:	bd458593          	addi	a1,a1,-1068 # 80007000 <etext>
    80000434:	00012517          	auipc	a0,0x12
    80000438:	e0c50513          	addi	a0,a0,-500 # 80012240 <cons>
    8000043c:	712000ef          	jal	80000b4e <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	00022797          	auipc	a5,0x22
    80000448:	16c78793          	addi	a5,a5,364 # 800225b0 <devsw>
    8000044c:	00000717          	auipc	a4,0x0
    80000450:	d2270713          	addi	a4,a4,-734 # 8000016e <consoleread>
    80000454:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000456:	00000717          	auipc	a4,0x0
    8000045a:	c7a70713          	addi	a4,a4,-902 # 800000d0 <consolewrite>
    8000045e:	ef98                	sd	a4,24(a5)
}
    80000460:	60a2                	ld	ra,8(sp)
    80000462:	6402                	ld	s0,0(sp)
    80000464:	0141                	addi	sp,sp,16
    80000466:	8082                	ret

0000000080000468 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000468:	7139                	addi	sp,sp,-64
    8000046a:	fc06                	sd	ra,56(sp)
    8000046c:	f822                	sd	s0,48(sp)
    8000046e:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    80000470:	c219                	beqz	a2,80000476 <printint+0xe>
    80000472:	08054063          	bltz	a0,800004f2 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    80000476:	4881                	li	a7,0
    80000478:	fc840693          	addi	a3,s0,-56

  i = 0;
    8000047c:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000047e:	00007617          	auipc	a2,0x7
    80000482:	29260613          	addi	a2,a2,658 # 80007710 <digits>
    80000486:	883e                	mv	a6,a5
    80000488:	2785                	addiw	a5,a5,1
    8000048a:	02b57733          	remu	a4,a0,a1
    8000048e:	9732                	add	a4,a4,a2
    80000490:	00074703          	lbu	a4,0(a4)
    80000494:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000498:	872a                	mv	a4,a0
    8000049a:	02b55533          	divu	a0,a0,a1
    8000049e:	0685                	addi	a3,a3,1
    800004a0:	feb773e3          	bgeu	a4,a1,80000486 <printint+0x1e>

  if(sign)
    800004a4:	00088a63          	beqz	a7,800004b8 <printint+0x50>
    buf[i++] = '-';
    800004a8:	1781                	addi	a5,a5,-32
    800004aa:	97a2                	add	a5,a5,s0
    800004ac:	02d00713          	li	a4,45
    800004b0:	fee78423          	sb	a4,-24(a5)
    800004b4:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    800004b8:	02f05963          	blez	a5,800004ea <printint+0x82>
    800004bc:	f426                	sd	s1,40(sp)
    800004be:	f04a                	sd	s2,32(sp)
    800004c0:	fc840713          	addi	a4,s0,-56
    800004c4:	00f704b3          	add	s1,a4,a5
    800004c8:	fff70913          	addi	s2,a4,-1
    800004cc:	993e                	add	s2,s2,a5
    800004ce:	37fd                	addiw	a5,a5,-1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004d8:	fff4c503          	lbu	a0,-1(s1)
    800004dc:	d9dff0ef          	jal	80000278 <consputc>
  while(--i >= 0)
    800004e0:	14fd                	addi	s1,s1,-1
    800004e2:	ff249be3          	bne	s1,s2,800004d8 <printint+0x70>
    800004e6:	74a2                	ld	s1,40(sp)
    800004e8:	7902                	ld	s2,32(sp)
}
    800004ea:	70e2                	ld	ra,56(sp)
    800004ec:	7442                	ld	s0,48(sp)
    800004ee:	6121                	addi	sp,sp,64
    800004f0:	8082                	ret
    x = -xx;
    800004f2:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004f6:	4885                	li	a7,1
    x = -xx;
    800004f8:	b741                	j	80000478 <printint+0x10>

00000000800004fa <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004fa:	7131                	addi	sp,sp,-192
    800004fc:	fc86                	sd	ra,120(sp)
    800004fe:	f8a2                	sd	s0,112(sp)
    80000500:	e8d2                	sd	s4,80(sp)
    80000502:	0100                	addi	s0,sp,128
    80000504:	8a2a                	mv	s4,a0
    80000506:	e40c                	sd	a1,8(s0)
    80000508:	e810                	sd	a2,16(s0)
    8000050a:	ec14                	sd	a3,24(s0)
    8000050c:	f018                	sd	a4,32(s0)
    8000050e:	f41c                	sd	a5,40(s0)
    80000510:	03043823          	sd	a6,48(s0)
    80000514:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000518:	0000a797          	auipc	a5,0xa
    8000051c:	cfc7a783          	lw	a5,-772(a5) # 8000a214 <panicking>
    80000520:	c3a1                	beqz	a5,80000560 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000522:	00840793          	addi	a5,s0,8
    80000526:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000052a:	000a4503          	lbu	a0,0(s4)
    8000052e:	28050763          	beqz	a0,800007bc <printf+0x2c2>
    80000532:	f4a6                	sd	s1,104(sp)
    80000534:	f0ca                	sd	s2,96(sp)
    80000536:	ecce                	sd	s3,88(sp)
    80000538:	e4d6                	sd	s5,72(sp)
    8000053a:	e0da                	sd	s6,64(sp)
    8000053c:	f862                	sd	s8,48(sp)
    8000053e:	f466                	sd	s9,40(sp)
    80000540:	f06a                	sd	s10,32(sp)
    80000542:	ec6e                	sd	s11,24(sp)
    80000544:	4981                	li	s3,0
    if(cx != '%'){
    80000546:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000054a:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000054e:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000552:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000556:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000055a:	07000d93          	li	s11,112
    8000055e:	a01d                	j	80000584 <printf+0x8a>
    acquire(&pr.lock);
    80000560:	00012517          	auipc	a0,0x12
    80000564:	d8850513          	addi	a0,a0,-632 # 800122e8 <pr>
    80000568:	666000ef          	jal	80000bce <acquire>
    8000056c:	bf5d                	j	80000522 <printf+0x28>
      consputc(cx);
    8000056e:	d0bff0ef          	jal	80000278 <consputc>
      continue;
    80000572:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000574:	0014899b          	addiw	s3,s1,1
    80000578:	013a07b3          	add	a5,s4,s3
    8000057c:	0007c503          	lbu	a0,0(a5)
    80000580:	20050b63          	beqz	a0,80000796 <printf+0x29c>
    if(cx != '%'){
    80000584:	ff5515e3          	bne	a0,s5,8000056e <printf+0x74>
    i++;
    80000588:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    8000058c:	009a07b3          	add	a5,s4,s1
    80000590:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000594:	20090b63          	beqz	s2,800007aa <printf+0x2b0>
    80000598:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    8000059c:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    8000059e:	c789                	beqz	a5,800005a8 <printf+0xae>
    800005a0:	009a0733          	add	a4,s4,s1
    800005a4:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800005a8:	03690963          	beq	s2,s6,800005da <printf+0xe0>
    } else if(c0 == 'l' && c1 == 'd'){
    800005ac:	05890363          	beq	s2,s8,800005f2 <printf+0xf8>
    } else if(c0 == 'u'){
    800005b0:	0d990663          	beq	s2,s9,8000067c <printf+0x182>
    } else if(c0 == 'x'){
    800005b4:	11a90d63          	beq	s2,s10,800006ce <printf+0x1d4>
    } else if(c0 == 'p'){
    800005b8:	15b90663          	beq	s2,s11,80000704 <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005bc:	06300793          	li	a5,99
    800005c0:	18f90563          	beq	s2,a5,8000074a <printf+0x250>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005c4:	07300793          	li	a5,115
    800005c8:	18f90b63          	beq	s2,a5,8000075e <printf+0x264>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005cc:	03591b63          	bne	s2,s5,80000602 <printf+0x108>
      consputc('%');
    800005d0:	02500513          	li	a0,37
    800005d4:	ca5ff0ef          	jal	80000278 <consputc>
    800005d8:	bf71                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    800005da:	f8843783          	ld	a5,-120(s0)
    800005de:	00878713          	addi	a4,a5,8
    800005e2:	f8e43423          	sd	a4,-120(s0)
    800005e6:	4605                	li	a2,1
    800005e8:	45a9                	li	a1,10
    800005ea:	4388                	lw	a0,0(a5)
    800005ec:	e7dff0ef          	jal	80000468 <printint>
    800005f0:	b751                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    800005f2:	01678f63          	beq	a5,s6,80000610 <printf+0x116>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005f6:	03878b63          	beq	a5,s8,8000062c <printf+0x132>
    } else if(c0 == 'l' && c1 == 'u'){
    800005fa:	09978e63          	beq	a5,s9,80000696 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'x'){
    800005fe:	0fa78563          	beq	a5,s10,800006e8 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000602:	8556                	mv	a0,s5
    80000604:	c75ff0ef          	jal	80000278 <consputc>
      consputc(c0);
    80000608:	854a                	mv	a0,s2
    8000060a:	c6fff0ef          	jal	80000278 <consputc>
    8000060e:	b79d                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000610:	f8843783          	ld	a5,-120(s0)
    80000614:	00878713          	addi	a4,a5,8
    80000618:	f8e43423          	sd	a4,-120(s0)
    8000061c:	4605                	li	a2,1
    8000061e:	45a9                	li	a1,10
    80000620:	6388                	ld	a0,0(a5)
    80000622:	e47ff0ef          	jal	80000468 <printint>
      i += 1;
    80000626:	0029849b          	addiw	s1,s3,2
    8000062a:	b7a9                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000062c:	06400793          	li	a5,100
    80000630:	02f68863          	beq	a3,a5,80000660 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000634:	07500793          	li	a5,117
    80000638:	06f68d63          	beq	a3,a5,800006b2 <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000063c:	07800793          	li	a5,120
    80000640:	fcf691e3          	bne	a3,a5,80000602 <printf+0x108>
      printint(va_arg(ap, uint64), 16, 0);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4601                	li	a2,0
    80000652:	45c1                	li	a1,16
    80000654:	6388                	ld	a0,0(a5)
    80000656:	e13ff0ef          	jal	80000468 <printint>
      i += 2;
    8000065a:	0039849b          	addiw	s1,s3,3
    8000065e:	bf19                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	df7ff0ef          	jal	80000468 <printint>
      i += 2;
    80000676:	0039849b          	addiw	s1,s3,3
    8000067a:	bded                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	0007e503          	lwu	a0,0(a5)
    80000690:	dd9ff0ef          	jal	80000468 <printint>
    80000694:	b5c5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4601                	li	a2,0
    800006a4:	45a9                	li	a1,10
    800006a6:	6388                	ld	a0,0(a5)
    800006a8:	dc1ff0ef          	jal	80000468 <printint>
      i += 1;
    800006ac:	0029849b          	addiw	s1,s3,2
    800006b0:	b5d1                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45a9                	li	a1,10
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	da5ff0ef          	jal	80000468 <printint>
      i += 2;
    800006c8:	0039849b          	addiw	s1,s3,3
    800006cc:	b565                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	4601                	li	a2,0
    800006dc:	45c1                	li	a1,16
    800006de:	0007e503          	lwu	a0,0(a5)
    800006e2:	d87ff0ef          	jal	80000468 <printint>
    800006e6:	b579                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	4601                	li	a2,0
    800006f6:	45c1                	li	a1,16
    800006f8:	6388                	ld	a0,0(a5)
    800006fa:	d6fff0ef          	jal	80000468 <printint>
      i += 1;
    800006fe:	0029849b          	addiw	s1,s3,2
    80000702:	bd8d                	j	80000574 <printf+0x7a>
    80000704:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000716:	03000513          	li	a0,48
    8000071a:	b5fff0ef          	jal	80000278 <consputc>
  consputc('x');
    8000071e:	07800513          	li	a0,120
    80000722:	b57ff0ef          	jal	80000278 <consputc>
    80000726:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000728:	00007b97          	auipc	s7,0x7
    8000072c:	fe8b8b93          	addi	s7,s7,-24 # 80007710 <digits>
    80000730:	03c9d793          	srli	a5,s3,0x3c
    80000734:	97de                	add	a5,a5,s7
    80000736:	0007c503          	lbu	a0,0(a5)
    8000073a:	b3fff0ef          	jal	80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000073e:	0992                	slli	s3,s3,0x4
    80000740:	397d                	addiw	s2,s2,-1
    80000742:	fe0917e3          	bnez	s2,80000730 <printf+0x236>
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	b535                	j	80000574 <printf+0x7a>
      consputc(va_arg(ap, uint));
    8000074a:	f8843783          	ld	a5,-120(s0)
    8000074e:	00878713          	addi	a4,a5,8
    80000752:	f8e43423          	sd	a4,-120(s0)
    80000756:	4388                	lw	a0,0(a5)
    80000758:	b21ff0ef          	jal	80000278 <consputc>
    8000075c:	bd21                	j	80000574 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    8000075e:	f8843783          	ld	a5,-120(s0)
    80000762:	00878713          	addi	a4,a5,8
    80000766:	f8e43423          	sd	a4,-120(s0)
    8000076a:	0007b903          	ld	s2,0(a5)
    8000076e:	00090d63          	beqz	s2,80000788 <printf+0x28e>
      for(; *s; s++)
    80000772:	00094503          	lbu	a0,0(s2)
    80000776:	de050fe3          	beqz	a0,80000574 <printf+0x7a>
        consputc(*s);
    8000077a:	affff0ef          	jal	80000278 <consputc>
      for(; *s; s++)
    8000077e:	0905                	addi	s2,s2,1
    80000780:	00094503          	lbu	a0,0(s2)
    80000784:	f97d                	bnez	a0,8000077a <printf+0x280>
    80000786:	b3fd                	j	80000574 <printf+0x7a>
        s = "(null)";
    80000788:	00007917          	auipc	s2,0x7
    8000078c:	88090913          	addi	s2,s2,-1920 # 80007008 <etext+0x8>
      for(; *s; s++)
    80000790:	02800513          	li	a0,40
    80000794:	b7dd                	j	8000077a <printf+0x280>
    80000796:	74a6                	ld	s1,104(sp)
    80000798:	7906                	ld	s2,96(sp)
    8000079a:	69e6                	ld	s3,88(sp)
    8000079c:	6aa6                	ld	s5,72(sp)
    8000079e:	6b06                	ld	s6,64(sp)
    800007a0:	7c42                	ld	s8,48(sp)
    800007a2:	7ca2                	ld	s9,40(sp)
    800007a4:	7d02                	ld	s10,32(sp)
    800007a6:	6de2                	ld	s11,24(sp)
    800007a8:	a811                	j	800007bc <printf+0x2c2>
    800007aa:	74a6                	ld	s1,104(sp)
    800007ac:	7906                	ld	s2,96(sp)
    800007ae:	69e6                	ld	s3,88(sp)
    800007b0:	6aa6                	ld	s5,72(sp)
    800007b2:	6b06                	ld	s6,64(sp)
    800007b4:	7c42                	ld	s8,48(sp)
    800007b6:	7ca2                	ld	s9,40(sp)
    800007b8:	7d02                	ld	s10,32(sp)
    800007ba:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007bc:	0000a797          	auipc	a5,0xa
    800007c0:	a587a783          	lw	a5,-1448(a5) # 8000a214 <panicking>
    800007c4:	c799                	beqz	a5,800007d2 <printf+0x2d8>
    release(&pr.lock);

  return 0;
}
    800007c6:	4501                	li	a0,0
    800007c8:	70e6                	ld	ra,120(sp)
    800007ca:	7446                	ld	s0,112(sp)
    800007cc:	6a46                	ld	s4,80(sp)
    800007ce:	6129                	addi	sp,sp,192
    800007d0:	8082                	ret
    release(&pr.lock);
    800007d2:	00012517          	auipc	a0,0x12
    800007d6:	b1650513          	addi	a0,a0,-1258 # 800122e8 <pr>
    800007da:	48c000ef          	jal	80000c66 <release>
  return 0;
    800007de:	b7e5                	j	800007c6 <printf+0x2cc>

00000000800007e0 <panic>:

void
panic(char *s)
{
    800007e0:	1101                	addi	sp,sp,-32
    800007e2:	ec06                	sd	ra,24(sp)
    800007e4:	e822                	sd	s0,16(sp)
    800007e6:	e426                	sd	s1,8(sp)
    800007e8:	e04a                	sd	s2,0(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  panicking = 1;
    800007ee:	4905                	li	s2,1
    800007f0:	0000a797          	auipc	a5,0xa
    800007f4:	a327a223          	sw	s2,-1500(a5) # 8000a214 <panicking>
  printf("panic: ");
    800007f8:	00007517          	auipc	a0,0x7
    800007fc:	82050513          	addi	a0,a0,-2016 # 80007018 <etext+0x18>
    80000800:	cfbff0ef          	jal	800004fa <printf>
  printf("%s\n", s);
    80000804:	85a6                	mv	a1,s1
    80000806:	00007517          	auipc	a0,0x7
    8000080a:	81a50513          	addi	a0,a0,-2022 # 80007020 <etext+0x20>
    8000080e:	cedff0ef          	jal	800004fa <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000812:	0000a797          	auipc	a5,0xa
    80000816:	9f27af23          	sw	s2,-1538(a5) # 8000a210 <panicked>
  for(;;)
    8000081a:	a001                	j	8000081a <panic+0x3a>

000000008000081c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000081c:	1141                	addi	sp,sp,-16
    8000081e:	e406                	sd	ra,8(sp)
    80000820:	e022                	sd	s0,0(sp)
    80000822:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000824:	00007597          	auipc	a1,0x7
    80000828:	80458593          	addi	a1,a1,-2044 # 80007028 <etext+0x28>
    8000082c:	00012517          	auipc	a0,0x12
    80000830:	abc50513          	addi	a0,a0,-1348 # 800122e8 <pr>
    80000834:	31a000ef          	jal	80000b4e <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000840:	1141                	addi	sp,sp,-16
    80000842:	e406                	sd	ra,8(sp)
    80000844:	e022                	sd	s0,0(sp)
    80000846:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000848:	100007b7          	lui	a5,0x10000
    8000084c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000850:	10000737          	lui	a4,0x10000
    80000854:	f8000693          	li	a3,-128
    80000858:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000085c:	468d                	li	a3,3
    8000085e:	10000637          	lui	a2,0x10000
    80000862:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000866:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000086a:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000086e:	10000737          	lui	a4,0x10000
    80000872:	461d                	li	a2,7
    80000874:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000878:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    8000087c:	00006597          	auipc	a1,0x6
    80000880:	7b458593          	addi	a1,a1,1972 # 80007030 <etext+0x30>
    80000884:	00012517          	auipc	a0,0x12
    80000888:	a7c50513          	addi	a0,a0,-1412 # 80012300 <tx_lock>
    8000088c:	2c2000ef          	jal	80000b4e <initlock>
}
    80000890:	60a2                	ld	ra,8(sp)
    80000892:	6402                	ld	s0,0(sp)
    80000894:	0141                	addi	sp,sp,16
    80000896:	8082                	ret

0000000080000898 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000898:	715d                	addi	sp,sp,-80
    8000089a:	e486                	sd	ra,72(sp)
    8000089c:	e0a2                	sd	s0,64(sp)
    8000089e:	fc26                	sd	s1,56(sp)
    800008a0:	ec56                	sd	s5,24(sp)
    800008a2:	0880                	addi	s0,sp,80
    800008a4:	8aaa                	mv	s5,a0
    800008a6:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008a8:	00012517          	auipc	a0,0x12
    800008ac:	a5850513          	addi	a0,a0,-1448 # 80012300 <tx_lock>
    800008b0:	31e000ef          	jal	80000bce <acquire>

  int i = 0;
  while(i < n){ 
    800008b4:	06905063          	blez	s1,80000914 <uartwrite+0x7c>
    800008b8:	f84a                	sd	s2,48(sp)
    800008ba:	f44e                	sd	s3,40(sp)
    800008bc:	f052                	sd	s4,32(sp)
    800008be:	e85a                	sd	s6,16(sp)
    800008c0:	e45e                	sd	s7,8(sp)
    800008c2:	8a56                	mv	s4,s5
    800008c4:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008c6:	0000a497          	auipc	s1,0xa
    800008ca:	95648493          	addi	s1,s1,-1706 # 8000a21c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ce:	00012997          	auipc	s3,0x12
    800008d2:	a3298993          	addi	s3,s3,-1486 # 80012300 <tx_lock>
    800008d6:	0000a917          	auipc	s2,0xa
    800008da:	94290913          	addi	s2,s2,-1726 # 8000a218 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    800008de:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    800008e2:	4b05                	li	s6,1
    800008e4:	a005                	j	80000904 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    800008e6:	85ce                	mv	a1,s3
    800008e8:	854a                	mv	a0,s2
    800008ea:	6d4010ef          	jal	80001fbe <sleep>
    while(tx_busy != 0){
    800008ee:	409c                	lw	a5,0(s1)
    800008f0:	fbfd                	bnez	a5,800008e6 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    800008f2:	000a4783          	lbu	a5,0(s4)
    800008f6:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008fa:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008fe:	0a05                	addi	s4,s4,1
    80000900:	015a0563          	beq	s4,s5,8000090a <uartwrite+0x72>
    while(tx_busy != 0){
    80000904:	409c                	lw	a5,0(s1)
    80000906:	f3e5                	bnez	a5,800008e6 <uartwrite+0x4e>
    80000908:	b7ed                	j	800008f2 <uartwrite+0x5a>
    8000090a:	7942                	ld	s2,48(sp)
    8000090c:	79a2                	ld	s3,40(sp)
    8000090e:	7a02                	ld	s4,32(sp)
    80000910:	6b42                	ld	s6,16(sp)
    80000912:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000914:	00012517          	auipc	a0,0x12
    80000918:	9ec50513          	addi	a0,a0,-1556 # 80012300 <tx_lock>
    8000091c:	34a000ef          	jal	80000c66 <release>
}
    80000920:	60a6                	ld	ra,72(sp)
    80000922:	6406                	ld	s0,64(sp)
    80000924:	74e2                	ld	s1,56(sp)
    80000926:	6ae2                	ld	s5,24(sp)
    80000928:	6161                	addi	sp,sp,80
    8000092a:	8082                	ret

000000008000092c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000092c:	1101                	addi	sp,sp,-32
    8000092e:	ec06                	sd	ra,24(sp)
    80000930:	e822                	sd	s0,16(sp)
    80000932:	e426                	sd	s1,8(sp)
    80000934:	1000                	addi	s0,sp,32
    80000936:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000938:	0000a797          	auipc	a5,0xa
    8000093c:	8dc7a783          	lw	a5,-1828(a5) # 8000a214 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	0000a797          	auipc	a5,0xa
    80000946:	8ce7a783          	lw	a5,-1842(a5) # 8000a210 <panicked>
    8000094a:	ef85                	bnez	a5,80000982 <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000094c:	10000737          	lui	a4,0x10000
    80000950:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000952:	00074783          	lbu	a5,0(a4)
    80000956:	0207f793          	andi	a5,a5,32
    8000095a:	dfe5                	beqz	a5,80000952 <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    8000095c:	0ff4f513          	zext.b	a0,s1
    80000960:	100007b7          	lui	a5,0x10000
    80000964:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000968:	0000a797          	auipc	a5,0xa
    8000096c:	8ac7a783          	lw	a5,-1876(a5) # 8000a214 <panicking>
    80000970:	cb91                	beqz	a5,80000984 <uartputc_sync+0x58>
    pop_off();
}
    80000972:	60e2                	ld	ra,24(sp)
    80000974:	6442                	ld	s0,16(sp)
    80000976:	64a2                	ld	s1,8(sp)
    80000978:	6105                	addi	sp,sp,32
    8000097a:	8082                	ret
    push_off();
    8000097c:	212000ef          	jal	80000b8e <push_off>
    80000980:	b7c9                	j	80000942 <uartputc_sync+0x16>
    for(;;)
    80000982:	a001                	j	80000982 <uartputc_sync+0x56>
    pop_off();
    80000984:	28e000ef          	jal	80000c12 <pop_off>
}
    80000988:	b7ed                	j	80000972 <uartputc_sync+0x46>

000000008000098a <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000098a:	1141                	addi	sp,sp,-16
    8000098c:	e422                	sd	s0,8(sp)
    8000098e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000990:	100007b7          	lui	a5,0x10000
    80000994:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    80000996:	0007c783          	lbu	a5,0(a5)
    8000099a:	8b85                	andi	a5,a5,1
    8000099c:	cb81                	beqz	a5,800009ac <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a6:	6422                	ld	s0,8(sp)
    800009a8:	0141                	addi	sp,sp,16
    800009aa:	8082                	ret
    return -1;
    800009ac:	557d                	li	a0,-1
    800009ae:	bfe5                	j	800009a6 <uartgetc+0x1c>

00000000800009b0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009b0:	1101                	addi	sp,sp,-32
    800009b2:	ec06                	sd	ra,24(sp)
    800009b4:	e822                	sd	s0,16(sp)
    800009b6:	e426                	sd	s1,8(sp)
    800009b8:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0789                	addi	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    800009c0:	0007c783          	lbu	a5,0(a5)

  acquire(&tx_lock);
    800009c4:	00012517          	auipc	a0,0x12
    800009c8:	93c50513          	addi	a0,a0,-1732 # 80012300 <tx_lock>
    800009cc:	202000ef          	jal	80000bce <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    800009d0:	100007b7          	lui	a5,0x10000
    800009d4:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009d6:	0007c783          	lbu	a5,0(a5)
    800009da:	0207f793          	andi	a5,a5,32
    800009de:	eb89                	bnez	a5,800009f0 <uartintr+0x40>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    800009e0:	00012517          	auipc	a0,0x12
    800009e4:	92050513          	addi	a0,a0,-1760 # 80012300 <tx_lock>
    800009e8:	27e000ef          	jal	80000c66 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	0000a797          	auipc	a5,0xa
    800009f4:	8207a623          	sw	zero,-2004(a5) # 8000a21c <tx_busy>
    wakeup(&tx_chan);
    800009f8:	0000a517          	auipc	a0,0xa
    800009fc:	82050513          	addi	a0,a0,-2016 # 8000a218 <tx_chan>
    80000a00:	60a010ef          	jal	8000200a <wakeup>
    80000a04:	bff1                	j	800009e0 <uartintr+0x30>
      break;
    consoleintr(c);
    80000a06:	8a5ff0ef          	jal	800002aa <consoleintr>
    int c = uartgetc();
    80000a0a:	f81ff0ef          	jal	8000098a <uartgetc>
    if(c == -1)
    80000a0e:	fe951ce3          	bne	a0,s1,80000a06 <uartintr+0x56>
  }
}
    80000a12:	60e2                	ld	ra,24(sp)
    80000a14:	6442                	ld	s0,16(sp)
    80000a16:	64a2                	ld	s1,8(sp)
    80000a18:	6105                	addi	sp,sp,32
    80000a1a:	8082                	ret

0000000080000a1c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1c:	1101                	addi	sp,sp,-32
    80000a1e:	ec06                	sd	ra,24(sp)
    80000a20:	e822                	sd	s0,16(sp)
    80000a22:	e426                	sd	s1,8(sp)
    80000a24:	e04a                	sd	s2,0(sp)
    80000a26:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a28:	03451793          	slli	a5,a0,0x34
    80000a2c:	e7a9                	bnez	a5,80000a76 <kfree+0x5a>
    80000a2e:	84aa                	mv	s1,a0
    80000a30:	00023797          	auipc	a5,0x23
    80000a34:	d1878793          	addi	a5,a5,-744 # 80023748 <end>
    80000a38:	02f56f63          	bltu	a0,a5,80000a76 <kfree+0x5a>
    80000a3c:	47c5                	li	a5,17
    80000a3e:	07ee                	slli	a5,a5,0x1b
    80000a40:	02f57b63          	bgeu	a0,a5,80000a76 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4585                	li	a1,1
    80000a48:	25a000ef          	jal	80000ca2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4c:	00012917          	auipc	s2,0x12
    80000a50:	8cc90913          	addi	s2,s2,-1844 # 80012318 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	178000ef          	jal	80000bce <acquire>
  r->next = kmem.freelist;
    80000a5a:	01893783          	ld	a5,24(s2)
    80000a5e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a60:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a64:	854a                	mv	a0,s2
    80000a66:	200000ef          	jal	80000c66 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00006517          	auipc	a0,0x6
    80000a7a:	5c250513          	addi	a0,a0,1474 # 80007038 <etext+0x38>
    80000a7e:	d63ff0ef          	jal	800007e0 <panic>

0000000080000a82 <freerange>:
{
    80000a82:	7179                	addi	sp,sp,-48
    80000a84:	f406                	sd	ra,40(sp)
    80000a86:	f022                	sd	s0,32(sp)
    80000a88:	ec26                	sd	s1,24(sp)
    80000a8a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a8c:	6785                	lui	a5,0x1
    80000a8e:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a92:	00e504b3          	add	s1,a0,a4
    80000a96:	777d                	lui	a4,0xfffff
    80000a98:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	94be                	add	s1,s1,a5
    80000a9c:	0295e263          	bltu	a1,s1,80000ac0 <freerange+0x3e>
    80000aa0:	e84a                	sd	s2,16(sp)
    80000aa2:	e44e                	sd	s3,8(sp)
    80000aa4:	e052                	sd	s4,0(sp)
    80000aa6:	892e                	mv	s2,a1
    kfree(p);
    80000aa8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aaa:	6985                	lui	s3,0x1
    kfree(p);
    80000aac:	01448533          	add	a0,s1,s4
    80000ab0:	f6dff0ef          	jal	80000a1c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab4:	94ce                	add	s1,s1,s3
    80000ab6:	fe997be3          	bgeu	s2,s1,80000aac <freerange+0x2a>
    80000aba:	6942                	ld	s2,16(sp)
    80000abc:	69a2                	ld	s3,8(sp)
    80000abe:	6a02                	ld	s4,0(sp)
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6145                	addi	sp,sp,48
    80000ac8:	8082                	ret

0000000080000aca <kinit>:
{
    80000aca:	1141                	addi	sp,sp,-16
    80000acc:	e406                	sd	ra,8(sp)
    80000ace:	e022                	sd	s0,0(sp)
    80000ad0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad2:	00006597          	auipc	a1,0x6
    80000ad6:	56e58593          	addi	a1,a1,1390 # 80007040 <etext+0x40>
    80000ada:	00012517          	auipc	a0,0x12
    80000ade:	83e50513          	addi	a0,a0,-1986 # 80012318 <kmem>
    80000ae2:	06c000ef          	jal	80000b4e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	00023517          	auipc	a0,0x23
    80000aee:	c5e50513          	addi	a0,a0,-930 # 80023748 <end>
    80000af2:	f91ff0ef          	jal	80000a82 <freerange>
}
    80000af6:	60a2                	ld	ra,8(sp)
    80000af8:	6402                	ld	s0,0(sp)
    80000afa:	0141                	addi	sp,sp,16
    80000afc:	8082                	ret

0000000080000afe <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afe:	1101                	addi	sp,sp,-32
    80000b00:	ec06                	sd	ra,24(sp)
    80000b02:	e822                	sd	s0,16(sp)
    80000b04:	e426                	sd	s1,8(sp)
    80000b06:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b08:	00012497          	auipc	s1,0x12
    80000b0c:	81048493          	addi	s1,s1,-2032 # 80012318 <kmem>
    80000b10:	8526                	mv	a0,s1
    80000b12:	0bc000ef          	jal	80000bce <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c485                	beqz	s1,80000b40 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00011517          	auipc	a0,0x11
    80000b20:	7fc50513          	addi	a0,a0,2044 # 80012318 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	140000ef          	jal	80000c66 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2a:	6605                	lui	a2,0x1
    80000b2c:	4595                	li	a1,5
    80000b2e:	8526                	mv	a0,s1
    80000b30:	172000ef          	jal	80000ca2 <memset>
  return (void*)r;
}
    80000b34:	8526                	mv	a0,s1
    80000b36:	60e2                	ld	ra,24(sp)
    80000b38:	6442                	ld	s0,16(sp)
    80000b3a:	64a2                	ld	s1,8(sp)
    80000b3c:	6105                	addi	sp,sp,32
    80000b3e:	8082                	ret
  release(&kmem.lock);
    80000b40:	00011517          	auipc	a0,0x11
    80000b44:	7d850513          	addi	a0,a0,2008 # 80012318 <kmem>
    80000b48:	11e000ef          	jal	80000c66 <release>
  if(r)
    80000b4c:	b7e5                	j	80000b34 <kalloc+0x36>

0000000080000b4e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b4e:	1141                	addi	sp,sp,-16
    80000b50:	e422                	sd	s0,8(sp)
    80000b52:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b54:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b56:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b5a:	00053823          	sd	zero,16(a0)
}
    80000b5e:	6422                	ld	s0,8(sp)
    80000b60:	0141                	addi	sp,sp,16
    80000b62:	8082                	ret

0000000080000b64 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b64:	411c                	lw	a5,0(a0)
    80000b66:	e399                	bnez	a5,80000b6c <holding+0x8>
    80000b68:	4501                	li	a0,0
  return r;
}
    80000b6a:	8082                	ret
{
    80000b6c:	1101                	addi	sp,sp,-32
    80000b6e:	ec06                	sd	ra,24(sp)
    80000b70:	e822                	sd	s0,16(sp)
    80000b72:	e426                	sd	s1,8(sp)
    80000b74:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b76:	6904                	ld	s1,16(a0)
    80000b78:	53b000ef          	jal	800018b2 <mycpu>
    80000b7c:	40a48533          	sub	a0,s1,a0
    80000b80:	00153513          	seqz	a0,a0
}
    80000b84:	60e2                	ld	ra,24(sp)
    80000b86:	6442                	ld	s0,16(sp)
    80000b88:	64a2                	ld	s1,8(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret

0000000080000b8e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b98:	100024f3          	csrr	s1,sstatus
    80000b9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ba0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ba2:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000ba6:	50d000ef          	jal	800018b2 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cb99                	beqz	a5,80000bc2 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	505000ef          	jal	800018b2 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	4f1000ef          	jal	800018b2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc6:	8085                	srli	s1,s1,0x1
    80000bc8:	8885                	andi	s1,s1,1
    80000bca:	dd64                	sw	s1,124(a0)
    80000bcc:	b7cd                	j	80000bae <push_off+0x20>

0000000080000bce <acquire>:
{
    80000bce:	1101                	addi	sp,sp,-32
    80000bd0:	ec06                	sd	ra,24(sp)
    80000bd2:	e822                	sd	s0,16(sp)
    80000bd4:	e426                	sd	s1,8(sp)
    80000bd6:	1000                	addi	s0,sp,32
    80000bd8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bda:	fb5ff0ef          	jal	80000b8e <push_off>
  if(holding(lk))
    80000bde:	8526                	mv	a0,s1
    80000be0:	f85ff0ef          	jal	80000b64 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	4705                	li	a4,1
  if(holding(lk))
    80000be6:	e105                	bnez	a0,80000c06 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be8:	87ba                	mv	a5,a4
    80000bea:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bee:	2781                	sext.w	a5,a5
    80000bf0:	ffe5                	bnez	a5,80000be8 <acquire+0x1a>
  __sync_synchronize();
    80000bf2:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000bf6:	4bd000ef          	jal	800018b2 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00006517          	auipc	a0,0x6
    80000c0a:	44250513          	addi	a0,a0,1090 # 80007048 <etext+0x48>
    80000c0e:	bd3ff0ef          	jal	800007e0 <panic>

0000000080000c12 <pop_off>:

void
pop_off(void)
{
    80000c12:	1141                	addi	sp,sp,-16
    80000c14:	e406                	sd	ra,8(sp)
    80000c16:	e022                	sd	s0,0(sp)
    80000c18:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1a:	499000ef          	jal	800018b2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c22:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c24:	e78d                	bnez	a5,80000c4e <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c26:	5d3c                	lw	a5,120(a0)
    80000c28:	02f05963          	blez	a5,80000c5a <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c2c:	37fd                	addiw	a5,a5,-1
    80000c2e:	0007871b          	sext.w	a4,a5
    80000c32:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c34:	eb09                	bnez	a4,80000c46 <pop_off+0x34>
    80000c36:	5d7c                	lw	a5,124(a0)
    80000c38:	c799                	beqz	a5,80000c46 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c42:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c46:	60a2                	ld	ra,8(sp)
    80000c48:	6402                	ld	s0,0(sp)
    80000c4a:	0141                	addi	sp,sp,16
    80000c4c:	8082                	ret
    panic("pop_off - interruptible");
    80000c4e:	00006517          	auipc	a0,0x6
    80000c52:	40250513          	addi	a0,a0,1026 # 80007050 <etext+0x50>
    80000c56:	b8bff0ef          	jal	800007e0 <panic>
    panic("pop_off");
    80000c5a:	00006517          	auipc	a0,0x6
    80000c5e:	40e50513          	addi	a0,a0,1038 # 80007068 <etext+0x68>
    80000c62:	b7fff0ef          	jal	800007e0 <panic>

0000000080000c66 <release>:
{
    80000c66:	1101                	addi	sp,sp,-32
    80000c68:	ec06                	sd	ra,24(sp)
    80000c6a:	e822                	sd	s0,16(sp)
    80000c6c:	e426                	sd	s1,8(sp)
    80000c6e:	1000                	addi	s0,sp,32
    80000c70:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c72:	ef3ff0ef          	jal	80000b64 <holding>
    80000c76:	c105                	beqz	a0,80000c96 <release+0x30>
  lk->cpu = 0;
    80000c78:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c7c:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000c80:	0310000f          	fence	rw,w
    80000c84:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000c88:	f8bff0ef          	jal	80000c12 <pop_off>
}
    80000c8c:	60e2                	ld	ra,24(sp)
    80000c8e:	6442                	ld	s0,16(sp)
    80000c90:	64a2                	ld	s1,8(sp)
    80000c92:	6105                	addi	sp,sp,32
    80000c94:	8082                	ret
    panic("release");
    80000c96:	00006517          	auipc	a0,0x6
    80000c9a:	3da50513          	addi	a0,a0,986 # 80007070 <etext+0x70>
    80000c9e:	b43ff0ef          	jal	800007e0 <panic>

0000000080000ca2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ca2:	1141                	addi	sp,sp,-16
    80000ca4:	e422                	sd	s0,8(sp)
    80000ca6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ca8:	ca19                	beqz	a2,80000cbe <memset+0x1c>
    80000caa:	87aa                	mv	a5,a0
    80000cac:	1602                	slli	a2,a2,0x20
    80000cae:	9201                	srli	a2,a2,0x20
    80000cb0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cb4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cb8:	0785                	addi	a5,a5,1
    80000cba:	fee79de3          	bne	a5,a4,80000cb4 <memset+0x12>
  }
  return dst;
}
    80000cbe:	6422                	ld	s0,8(sp)
    80000cc0:	0141                	addi	sp,sp,16
    80000cc2:	8082                	ret

0000000080000cc4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cc4:	1141                	addi	sp,sp,-16
    80000cc6:	e422                	sd	s0,8(sp)
    80000cc8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cca:	ca05                	beqz	a2,80000cfa <memcmp+0x36>
    80000ccc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cd0:	1682                	slli	a3,a3,0x20
    80000cd2:	9281                	srli	a3,a3,0x20
    80000cd4:	0685                	addi	a3,a3,1
    80000cd6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cd8:	00054783          	lbu	a5,0(a0)
    80000cdc:	0005c703          	lbu	a4,0(a1)
    80000ce0:	00e79863          	bne	a5,a4,80000cf0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ce4:	0505                	addi	a0,a0,1
    80000ce6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ce8:	fed518e3          	bne	a0,a3,80000cd8 <memcmp+0x14>
  }

  return 0;
    80000cec:	4501                	li	a0,0
    80000cee:	a019                	j	80000cf4 <memcmp+0x30>
      return *s1 - *s2;
    80000cf0:	40e7853b          	subw	a0,a5,a4
}
    80000cf4:	6422                	ld	s0,8(sp)
    80000cf6:	0141                	addi	sp,sp,16
    80000cf8:	8082                	ret
  return 0;
    80000cfa:	4501                	li	a0,0
    80000cfc:	bfe5                	j	80000cf4 <memcmp+0x30>

0000000080000cfe <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000cfe:	1141                	addi	sp,sp,-16
    80000d00:	e422                	sd	s0,8(sp)
    80000d02:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d04:	c205                	beqz	a2,80000d24 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d06:	02a5e263          	bltu	a1,a0,80000d2a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d0a:	1602                	slli	a2,a2,0x20
    80000d0c:	9201                	srli	a2,a2,0x20
    80000d0e:	00c587b3          	add	a5,a1,a2
{
    80000d12:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d14:	0585                	addi	a1,a1,1
    80000d16:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdb8b9>
    80000d18:	fff5c683          	lbu	a3,-1(a1)
    80000d1c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d20:	feb79ae3          	bne	a5,a1,80000d14 <memmove+0x16>

  return dst;
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  if(s < d && s + n > d){
    80000d2a:	02061693          	slli	a3,a2,0x20
    80000d2e:	9281                	srli	a3,a3,0x20
    80000d30:	00d58733          	add	a4,a1,a3
    80000d34:	fce57be3          	bgeu	a0,a4,80000d0a <memmove+0xc>
    d += n;
    80000d38:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d3a:	fff6079b          	addiw	a5,a2,-1
    80000d3e:	1782                	slli	a5,a5,0x20
    80000d40:	9381                	srli	a5,a5,0x20
    80000d42:	fff7c793          	not	a5,a5
    80000d46:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d48:	177d                	addi	a4,a4,-1
    80000d4a:	16fd                	addi	a3,a3,-1
    80000d4c:	00074603          	lbu	a2,0(a4)
    80000d50:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d54:	fef71ae3          	bne	a4,a5,80000d48 <memmove+0x4a>
    80000d58:	b7f1                	j	80000d24 <memmove+0x26>

0000000080000d5a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d5a:	1141                	addi	sp,sp,-16
    80000d5c:	e406                	sd	ra,8(sp)
    80000d5e:	e022                	sd	s0,0(sp)
    80000d60:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d62:	f9dff0ef          	jal	80000cfe <memmove>
}
    80000d66:	60a2                	ld	ra,8(sp)
    80000d68:	6402                	ld	s0,0(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret

0000000080000d6e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d74:	ce11                	beqz	a2,80000d90 <strncmp+0x22>
    80000d76:	00054783          	lbu	a5,0(a0)
    80000d7a:	cf89                	beqz	a5,80000d94 <strncmp+0x26>
    80000d7c:	0005c703          	lbu	a4,0(a1)
    80000d80:	00f71a63          	bne	a4,a5,80000d94 <strncmp+0x26>
    n--, p++, q++;
    80000d84:	367d                	addiw	a2,a2,-1
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000d8a:	f675                	bnez	a2,80000d76 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	a801                	j	80000d9e <strncmp+0x30>
    80000d90:	4501                	li	a0,0
    80000d92:	a031                	j	80000d9e <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000d94:	00054503          	lbu	a0,0(a0)
    80000d98:	0005c783          	lbu	a5,0(a1)
    80000d9c:	9d1d                	subw	a0,a0,a5
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret

0000000080000da4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000da4:	1141                	addi	sp,sp,-16
    80000da6:	e422                	sd	s0,8(sp)
    80000da8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000daa:	87aa                	mv	a5,a0
    80000dac:	86b2                	mv	a3,a2
    80000dae:	367d                	addiw	a2,a2,-1
    80000db0:	02d05563          	blez	a3,80000dda <strncpy+0x36>
    80000db4:	0785                	addi	a5,a5,1
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	fee78fa3          	sb	a4,-1(a5)
    80000dbe:	0585                	addi	a1,a1,1
    80000dc0:	f775                	bnez	a4,80000dac <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dc2:	873e                	mv	a4,a5
    80000dc4:	9fb5                	addw	a5,a5,a3
    80000dc6:	37fd                	addiw	a5,a5,-1
    80000dc8:	00c05963          	blez	a2,80000dda <strncpy+0x36>
    *s++ = 0;
    80000dcc:	0705                	addi	a4,a4,1
    80000dce:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000dd2:	40e786bb          	subw	a3,a5,a4
    80000dd6:	fed04be3          	bgtz	a3,80000dcc <strncpy+0x28>
  return os;
}
    80000dda:	6422                	ld	s0,8(sp)
    80000ddc:	0141                	addi	sp,sp,16
    80000dde:	8082                	ret

0000000080000de0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000de0:	1141                	addi	sp,sp,-16
    80000de2:	e422                	sd	s0,8(sp)
    80000de4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000de6:	02c05363          	blez	a2,80000e0c <safestrcpy+0x2c>
    80000dea:	fff6069b          	addiw	a3,a2,-1
    80000dee:	1682                	slli	a3,a3,0x20
    80000df0:	9281                	srli	a3,a3,0x20
    80000df2:	96ae                	add	a3,a3,a1
    80000df4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000df6:	00d58963          	beq	a1,a3,80000e08 <safestrcpy+0x28>
    80000dfa:	0585                	addi	a1,a1,1
    80000dfc:	0785                	addi	a5,a5,1
    80000dfe:	fff5c703          	lbu	a4,-1(a1)
    80000e02:	fee78fa3          	sb	a4,-1(a5)
    80000e06:	fb65                	bnez	a4,80000df6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e08:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e0c:	6422                	ld	s0,8(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret

0000000080000e12 <strlen>:

int
strlen(const char *s)
{
    80000e12:	1141                	addi	sp,sp,-16
    80000e14:	e422                	sd	s0,8(sp)
    80000e16:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e18:	00054783          	lbu	a5,0(a0)
    80000e1c:	cf91                	beqz	a5,80000e38 <strlen+0x26>
    80000e1e:	0505                	addi	a0,a0,1
    80000e20:	87aa                	mv	a5,a0
    80000e22:	86be                	mv	a3,a5
    80000e24:	0785                	addi	a5,a5,1
    80000e26:	fff7c703          	lbu	a4,-1(a5)
    80000e2a:	ff65                	bnez	a4,80000e22 <strlen+0x10>
    80000e2c:	40a6853b          	subw	a0,a3,a0
    80000e30:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e38:	4501                	li	a0,0
    80000e3a:	bfe5                	j	80000e32 <strlen+0x20>

0000000080000e3c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e406                	sd	ra,8(sp)
    80000e40:	e022                	sd	s0,0(sp)
    80000e42:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e44:	25f000ef          	jal	800018a2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e48:	00009717          	auipc	a4,0x9
    80000e4c:	3d870713          	addi	a4,a4,984 # 8000a220 <started>
  if(cpuid() == 0){
    80000e50:	c51d                	beqz	a0,80000e7e <main+0x42>
    while(started == 0)
    80000e52:	431c                	lw	a5,0(a4)
    80000e54:	2781                	sext.w	a5,a5
    80000e56:	dff5                	beqz	a5,80000e52 <main+0x16>
      ;
    __sync_synchronize();
    80000e58:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000e5c:	247000ef          	jal	800018a2 <cpuid>
    80000e60:	85aa                	mv	a1,a0
    80000e62:	00006517          	auipc	a0,0x6
    80000e66:	23650513          	addi	a0,a0,566 # 80007098 <etext+0x98>
    80000e6a:	e90ff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000e6e:	080000ef          	jal	80000eee <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e72:	664010ef          	jal	800024d6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e76:	672040ef          	jal	800054e8 <plicinithart>
  }

  scheduler();        
    80000e7a:	759000ef          	jal	80001dd2 <scheduler>
    consoleinit();
    80000e7e:	da6ff0ef          	jal	80000424 <consoleinit>
    printfinit();
    80000e82:	99bff0ef          	jal	8000081c <printfinit>
    printf("\n");
    80000e86:	00006517          	auipc	a0,0x6
    80000e8a:	1f250513          	addi	a0,a0,498 # 80007078 <etext+0x78>
    80000e8e:	e6cff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000e92:	00006517          	auipc	a0,0x6
    80000e96:	1ee50513          	addi	a0,a0,494 # 80007080 <etext+0x80>
    80000e9a:	e60ff0ef          	jal	800004fa <printf>
    printf("\n");
    80000e9e:	00006517          	auipc	a0,0x6
    80000ea2:	1da50513          	addi	a0,a0,474 # 80007078 <etext+0x78>
    80000ea6:	e54ff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000eaa:	c21ff0ef          	jal	80000aca <kinit>
    kvminit();       // create kernel page table
    80000eae:	2ca000ef          	jal	80001178 <kvminit>
    kvminithart();   // turn on paging
    80000eb2:	03c000ef          	jal	80000eee <kvminithart>
    procinit();      // process table
    80000eb6:	137000ef          	jal	800017ec <procinit>
    trapinit();      // trap vectors
    80000eba:	5f8010ef          	jal	800024b2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ebe:	618010ef          	jal	800024d6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ec2:	60c040ef          	jal	800054ce <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ec6:	622040ef          	jal	800054e8 <plicinithart>
    binit();         // buffer cache
    80000eca:	4e7010ef          	jal	80002bb0 <binit>
    iinit();         // inode table
    80000ece:	26c020ef          	jal	8000313a <iinit>
    fileinit();      // file table
    80000ed2:	15e030ef          	jal	80004030 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ed6:	702040ef          	jal	800055d8 <virtio_disk_init>
    userinit();      // first user process
    80000eda:	537000ef          	jal	80001c10 <userinit>
    __sync_synchronize();
    80000ede:	0330000f          	fence	rw,rw
    started = 1;
    80000ee2:	4785                	li	a5,1
    80000ee4:	00009717          	auipc	a4,0x9
    80000ee8:	32f72e23          	sw	a5,828(a4) # 8000a220 <started>
    80000eec:	b779                	j	80000e7a <main+0x3e>

0000000080000eee <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000eee:	1141                	addi	sp,sp,-16
    80000ef0:	e422                	sd	s0,8(sp)
    80000ef2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ef4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ef8:	00009797          	auipc	a5,0x9
    80000efc:	3307b783          	ld	a5,816(a5) # 8000a228 <kernel_pagetable>
    80000f00:	83b1                	srli	a5,a5,0xc
    80000f02:	577d                	li	a4,-1
    80000f04:	177e                	slli	a4,a4,0x3f
    80000f06:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f08:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f0c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret

0000000080000f16 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f16:	7139                	addi	sp,sp,-64
    80000f18:	fc06                	sd	ra,56(sp)
    80000f1a:	f822                	sd	s0,48(sp)
    80000f1c:	f426                	sd	s1,40(sp)
    80000f1e:	f04a                	sd	s2,32(sp)
    80000f20:	ec4e                	sd	s3,24(sp)
    80000f22:	e852                	sd	s4,16(sp)
    80000f24:	e456                	sd	s5,8(sp)
    80000f26:	e05a                	sd	s6,0(sp)
    80000f28:	0080                	addi	s0,sp,64
    80000f2a:	84aa                	mv	s1,a0
    80000f2c:	89ae                	mv	s3,a1
    80000f2e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f30:	57fd                	li	a5,-1
    80000f32:	83e9                	srli	a5,a5,0x1a
    80000f34:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f36:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f38:	02b7fc63          	bgeu	a5,a1,80000f70 <walk+0x5a>
    panic("walk");
    80000f3c:	00006517          	auipc	a0,0x6
    80000f40:	17450513          	addi	a0,a0,372 # 800070b0 <etext+0xb0>
    80000f44:	89dff0ef          	jal	800007e0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f48:	060a8263          	beqz	s5,80000fac <walk+0x96>
    80000f4c:	bb3ff0ef          	jal	80000afe <kalloc>
    80000f50:	84aa                	mv	s1,a0
    80000f52:	c139                	beqz	a0,80000f98 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f54:	6605                	lui	a2,0x1
    80000f56:	4581                	li	a1,0
    80000f58:	d4bff0ef          	jal	80000ca2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f5c:	00c4d793          	srli	a5,s1,0xc
    80000f60:	07aa                	slli	a5,a5,0xa
    80000f62:	0017e793          	ori	a5,a5,1
    80000f66:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000f6a:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdb8af>
    80000f6c:	036a0063          	beq	s4,s6,80000f8c <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000f70:	0149d933          	srl	s2,s3,s4
    80000f74:	1ff97913          	andi	s2,s2,511
    80000f78:	090e                	slli	s2,s2,0x3
    80000f7a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000f7c:	00093483          	ld	s1,0(s2)
    80000f80:	0014f793          	andi	a5,s1,1
    80000f84:	d3f1                	beqz	a5,80000f48 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000f86:	80a9                	srli	s1,s1,0xa
    80000f88:	04b2                	slli	s1,s1,0xc
    80000f8a:	b7c5                	j	80000f6a <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000f8c:	00c9d513          	srli	a0,s3,0xc
    80000f90:	1ff57513          	andi	a0,a0,511
    80000f94:	050e                	slli	a0,a0,0x3
    80000f96:	9526                	add	a0,a0,s1
}
    80000f98:	70e2                	ld	ra,56(sp)
    80000f9a:	7442                	ld	s0,48(sp)
    80000f9c:	74a2                	ld	s1,40(sp)
    80000f9e:	7902                	ld	s2,32(sp)
    80000fa0:	69e2                	ld	s3,24(sp)
    80000fa2:	6a42                	ld	s4,16(sp)
    80000fa4:	6aa2                	ld	s5,8(sp)
    80000fa6:	6b02                	ld	s6,0(sp)
    80000fa8:	6121                	addi	sp,sp,64
    80000faa:	8082                	ret
        return 0;
    80000fac:	4501                	li	a0,0
    80000fae:	b7ed                	j	80000f98 <walk+0x82>

0000000080000fb0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000fb0:	57fd                	li	a5,-1
    80000fb2:	83e9                	srli	a5,a5,0x1a
    80000fb4:	00b7f463          	bgeu	a5,a1,80000fbc <walkaddr+0xc>
    return 0;
    80000fb8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000fba:	8082                	ret
{
    80000fbc:	1141                	addi	sp,sp,-16
    80000fbe:	e406                	sd	ra,8(sp)
    80000fc0:	e022                	sd	s0,0(sp)
    80000fc2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000fc4:	4601                	li	a2,0
    80000fc6:	f51ff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    80000fca:	c105                	beqz	a0,80000fea <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000fcc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000fce:	0117f693          	andi	a3,a5,17
    80000fd2:	4745                	li	a4,17
    return 0;
    80000fd4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000fd6:	00e68663          	beq	a3,a4,80000fe2 <walkaddr+0x32>
}
    80000fda:	60a2                	ld	ra,8(sp)
    80000fdc:	6402                	ld	s0,0(sp)
    80000fde:	0141                	addi	sp,sp,16
    80000fe0:	8082                	ret
  pa = PTE2PA(*pte);
    80000fe2:	83a9                	srli	a5,a5,0xa
    80000fe4:	00c79513          	slli	a0,a5,0xc
  return pa;
    80000fe8:	bfcd                	j	80000fda <walkaddr+0x2a>
    return 0;
    80000fea:	4501                	li	a0,0
    80000fec:	b7fd                	j	80000fda <walkaddr+0x2a>

0000000080000fee <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80000fee:	715d                	addi	sp,sp,-80
    80000ff0:	e486                	sd	ra,72(sp)
    80000ff2:	e0a2                	sd	s0,64(sp)
    80000ff4:	fc26                	sd	s1,56(sp)
    80000ff6:	f84a                	sd	s2,48(sp)
    80000ff8:	f44e                	sd	s3,40(sp)
    80000ffa:	f052                	sd	s4,32(sp)
    80000ffc:	ec56                	sd	s5,24(sp)
    80000ffe:	e85a                	sd	s6,16(sp)
    80001000:	e45e                	sd	s7,8(sp)
    80001002:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001004:	03459793          	slli	a5,a1,0x34
    80001008:	e7a9                	bnez	a5,80001052 <mappages+0x64>
    8000100a:	8aaa                	mv	s5,a0
    8000100c:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000100e:	03461793          	slli	a5,a2,0x34
    80001012:	e7b1                	bnez	a5,8000105e <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    80001014:	ca39                	beqz	a2,8000106a <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001016:	77fd                	lui	a5,0xfffff
    80001018:	963e                	add	a2,a2,a5
    8000101a:	00b609b3          	add	s3,a2,a1
  a = va;
    8000101e:	892e                	mv	s2,a1
    80001020:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001024:	6b85                	lui	s7,0x1
    80001026:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    8000102a:	4605                	li	a2,1
    8000102c:	85ca                	mv	a1,s2
    8000102e:	8556                	mv	a0,s5
    80001030:	ee7ff0ef          	jal	80000f16 <walk>
    80001034:	c539                	beqz	a0,80001082 <mappages+0x94>
    if(*pte & PTE_V)
    80001036:	611c                	ld	a5,0(a0)
    80001038:	8b85                	andi	a5,a5,1
    8000103a:	ef95                	bnez	a5,80001076 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000103c:	80b1                	srli	s1,s1,0xc
    8000103e:	04aa                	slli	s1,s1,0xa
    80001040:	0164e4b3          	or	s1,s1,s6
    80001044:	0014e493          	ori	s1,s1,1
    80001048:	e104                	sd	s1,0(a0)
    if(a == last)
    8000104a:	05390863          	beq	s2,s3,8000109a <mappages+0xac>
    a += PGSIZE;
    8000104e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001050:	bfd9                	j	80001026 <mappages+0x38>
    panic("mappages: va not aligned");
    80001052:	00006517          	auipc	a0,0x6
    80001056:	06650513          	addi	a0,a0,102 # 800070b8 <etext+0xb8>
    8000105a:	f86ff0ef          	jal	800007e0 <panic>
    panic("mappages: size not aligned");
    8000105e:	00006517          	auipc	a0,0x6
    80001062:	07a50513          	addi	a0,a0,122 # 800070d8 <etext+0xd8>
    80001066:	f7aff0ef          	jal	800007e0 <panic>
    panic("mappages: size");
    8000106a:	00006517          	auipc	a0,0x6
    8000106e:	08e50513          	addi	a0,a0,142 # 800070f8 <etext+0xf8>
    80001072:	f6eff0ef          	jal	800007e0 <panic>
      panic("mappages: remap");
    80001076:	00006517          	auipc	a0,0x6
    8000107a:	09250513          	addi	a0,a0,146 # 80007108 <etext+0x108>
    8000107e:	f62ff0ef          	jal	800007e0 <panic>
      return -1;
    80001082:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001084:	60a6                	ld	ra,72(sp)
    80001086:	6406                	ld	s0,64(sp)
    80001088:	74e2                	ld	s1,56(sp)
    8000108a:	7942                	ld	s2,48(sp)
    8000108c:	79a2                	ld	s3,40(sp)
    8000108e:	7a02                	ld	s4,32(sp)
    80001090:	6ae2                	ld	s5,24(sp)
    80001092:	6b42                	ld	s6,16(sp)
    80001094:	6ba2                	ld	s7,8(sp)
    80001096:	6161                	addi	sp,sp,80
    80001098:	8082                	ret
  return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7e5                	j	80001084 <mappages+0x96>

000000008000109e <kvmmap>:
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e406                	sd	ra,8(sp)
    800010a2:	e022                	sd	s0,0(sp)
    800010a4:	0800                	addi	s0,sp,16
    800010a6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010a8:	86b2                	mv	a3,a2
    800010aa:	863e                	mv	a2,a5
    800010ac:	f43ff0ef          	jal	80000fee <mappages>
    800010b0:	e509                	bnez	a0,800010ba <kvmmap+0x1c>
}
    800010b2:	60a2                	ld	ra,8(sp)
    800010b4:	6402                	ld	s0,0(sp)
    800010b6:	0141                	addi	sp,sp,16
    800010b8:	8082                	ret
    panic("kvmmap");
    800010ba:	00006517          	auipc	a0,0x6
    800010be:	05e50513          	addi	a0,a0,94 # 80007118 <etext+0x118>
    800010c2:	f1eff0ef          	jal	800007e0 <panic>

00000000800010c6 <kvmmake>:
{
    800010c6:	1101                	addi	sp,sp,-32
    800010c8:	ec06                	sd	ra,24(sp)
    800010ca:	e822                	sd	s0,16(sp)
    800010cc:	e426                	sd	s1,8(sp)
    800010ce:	e04a                	sd	s2,0(sp)
    800010d0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800010d2:	a2dff0ef          	jal	80000afe <kalloc>
    800010d6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800010d8:	6605                	lui	a2,0x1
    800010da:	4581                	li	a1,0
    800010dc:	bc7ff0ef          	jal	80000ca2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800010e0:	4719                	li	a4,6
    800010e2:	6685                	lui	a3,0x1
    800010e4:	10000637          	lui	a2,0x10000
    800010e8:	100005b7          	lui	a1,0x10000
    800010ec:	8526                	mv	a0,s1
    800010ee:	fb1ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800010f2:	4719                	li	a4,6
    800010f4:	6685                	lui	a3,0x1
    800010f6:	10001637          	lui	a2,0x10001
    800010fa:	100015b7          	lui	a1,0x10001
    800010fe:	8526                	mv	a0,s1
    80001100:	f9fff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001104:	4719                	li	a4,6
    80001106:	040006b7          	lui	a3,0x4000
    8000110a:	0c000637          	lui	a2,0xc000
    8000110e:	0c0005b7          	lui	a1,0xc000
    80001112:	8526                	mv	a0,s1
    80001114:	f8bff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001118:	00006917          	auipc	s2,0x6
    8000111c:	ee890913          	addi	s2,s2,-280 # 80007000 <etext>
    80001120:	4729                	li	a4,10
    80001122:	80006697          	auipc	a3,0x80006
    80001126:	ede68693          	addi	a3,a3,-290 # 7000 <_entry-0x7fff9000>
    8000112a:	4605                	li	a2,1
    8000112c:	067e                	slli	a2,a2,0x1f
    8000112e:	85b2                	mv	a1,a2
    80001130:	8526                	mv	a0,s1
    80001132:	f6dff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001136:	46c5                	li	a3,17
    80001138:	06ee                	slli	a3,a3,0x1b
    8000113a:	4719                	li	a4,6
    8000113c:	412686b3          	sub	a3,a3,s2
    80001140:	864a                	mv	a2,s2
    80001142:	85ca                	mv	a1,s2
    80001144:	8526                	mv	a0,s1
    80001146:	f59ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000114a:	4729                	li	a4,10
    8000114c:	6685                	lui	a3,0x1
    8000114e:	00005617          	auipc	a2,0x5
    80001152:	eb260613          	addi	a2,a2,-334 # 80006000 <_trampoline>
    80001156:	040005b7          	lui	a1,0x4000
    8000115a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000115c:	05b2                	slli	a1,a1,0xc
    8000115e:	8526                	mv	a0,s1
    80001160:	f3fff0ef          	jal	8000109e <kvmmap>
  proc_mapstacks(kpgtbl);
    80001164:	8526                	mv	a0,s1
    80001166:	5ee000ef          	jal	80001754 <proc_mapstacks>
}
    8000116a:	8526                	mv	a0,s1
    8000116c:	60e2                	ld	ra,24(sp)
    8000116e:	6442                	ld	s0,16(sp)
    80001170:	64a2                	ld	s1,8(sp)
    80001172:	6902                	ld	s2,0(sp)
    80001174:	6105                	addi	sp,sp,32
    80001176:	8082                	ret

0000000080001178 <kvminit>:
{
    80001178:	1141                	addi	sp,sp,-16
    8000117a:	e406                	sd	ra,8(sp)
    8000117c:	e022                	sd	s0,0(sp)
    8000117e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001180:	f47ff0ef          	jal	800010c6 <kvmmake>
    80001184:	00009797          	auipc	a5,0x9
    80001188:	0aa7b223          	sd	a0,164(a5) # 8000a228 <kernel_pagetable>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	addi	sp,sp,16
    80001192:	8082                	ret

0000000080001194 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001194:	1101                	addi	sp,sp,-32
    80001196:	ec06                	sd	ra,24(sp)
    80001198:	e822                	sd	s0,16(sp)
    8000119a:	e426                	sd	s1,8(sp)
    8000119c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000119e:	961ff0ef          	jal	80000afe <kalloc>
    800011a2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011a4:	c509                	beqz	a0,800011ae <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011a6:	6605                	lui	a2,0x1
    800011a8:	4581                	li	a1,0
    800011aa:	af9ff0ef          	jal	80000ca2 <memset>
  return pagetable;
}
    800011ae:	8526                	mv	a0,s1
    800011b0:	60e2                	ld	ra,24(sp)
    800011b2:	6442                	ld	s0,16(sp)
    800011b4:	64a2                	ld	s1,8(sp)
    800011b6:	6105                	addi	sp,sp,32
    800011b8:	8082                	ret

00000000800011ba <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011ba:	7139                	addi	sp,sp,-64
    800011bc:	fc06                	sd	ra,56(sp)
    800011be:	f822                	sd	s0,48(sp)
    800011c0:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800011c2:	03459793          	slli	a5,a1,0x34
    800011c6:	e38d                	bnez	a5,800011e8 <uvmunmap+0x2e>
    800011c8:	f04a                	sd	s2,32(sp)
    800011ca:	ec4e                	sd	s3,24(sp)
    800011cc:	e852                	sd	s4,16(sp)
    800011ce:	e456                	sd	s5,8(sp)
    800011d0:	e05a                	sd	s6,0(sp)
    800011d2:	8a2a                	mv	s4,a0
    800011d4:	892e                	mv	s2,a1
    800011d6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800011d8:	0632                	slli	a2,a2,0xc
    800011da:	00b609b3          	add	s3,a2,a1
    800011de:	6b05                	lui	s6,0x1
    800011e0:	0535f963          	bgeu	a1,s3,80001232 <uvmunmap+0x78>
    800011e4:	f426                	sd	s1,40(sp)
    800011e6:	a015                	j	8000120a <uvmunmap+0x50>
    800011e8:	f426                	sd	s1,40(sp)
    800011ea:	f04a                	sd	s2,32(sp)
    800011ec:	ec4e                	sd	s3,24(sp)
    800011ee:	e852                	sd	s4,16(sp)
    800011f0:	e456                	sd	s5,8(sp)
    800011f2:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    800011f4:	00006517          	auipc	a0,0x6
    800011f8:	f2c50513          	addi	a0,a0,-212 # 80007120 <etext+0x120>
    800011fc:	de4ff0ef          	jal	800007e0 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001200:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001204:	995a                	add	s2,s2,s6
    80001206:	03397563          	bgeu	s2,s3,80001230 <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    8000120a:	4601                	li	a2,0
    8000120c:	85ca                	mv	a1,s2
    8000120e:	8552                	mv	a0,s4
    80001210:	d07ff0ef          	jal	80000f16 <walk>
    80001214:	84aa                	mv	s1,a0
    80001216:	d57d                	beqz	a0,80001204 <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001218:	611c                	ld	a5,0(a0)
    8000121a:	0017f713          	andi	a4,a5,1
    8000121e:	d37d                	beqz	a4,80001204 <uvmunmap+0x4a>
    if(do_free){
    80001220:	fe0a80e3          	beqz	s5,80001200 <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    80001224:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001226:	00c79513          	slli	a0,a5,0xc
    8000122a:	ff2ff0ef          	jal	80000a1c <kfree>
    8000122e:	bfc9                	j	80001200 <uvmunmap+0x46>
    80001230:	74a2                	ld	s1,40(sp)
    80001232:	7902                	ld	s2,32(sp)
    80001234:	69e2                	ld	s3,24(sp)
    80001236:	6a42                	ld	s4,16(sp)
    80001238:	6aa2                	ld	s5,8(sp)
    8000123a:	6b02                	ld	s6,0(sp)
  }
}
    8000123c:	70e2                	ld	ra,56(sp)
    8000123e:	7442                	ld	s0,48(sp)
    80001240:	6121                	addi	sp,sp,64
    80001242:	8082                	ret

0000000080001244 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001244:	1101                	addi	sp,sp,-32
    80001246:	ec06                	sd	ra,24(sp)
    80001248:	e822                	sd	s0,16(sp)
    8000124a:	e426                	sd	s1,8(sp)
    8000124c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000124e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001250:	00b67d63          	bgeu	a2,a1,8000126a <uvmdealloc+0x26>
    80001254:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001256:	6785                	lui	a5,0x1
    80001258:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000125a:	00f60733          	add	a4,a2,a5
    8000125e:	76fd                	lui	a3,0xfffff
    80001260:	8f75                	and	a4,a4,a3
    80001262:	97ae                	add	a5,a5,a1
    80001264:	8ff5                	and	a5,a5,a3
    80001266:	00f76863          	bltu	a4,a5,80001276 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000126a:	8526                	mv	a0,s1
    8000126c:	60e2                	ld	ra,24(sp)
    8000126e:	6442                	ld	s0,16(sp)
    80001270:	64a2                	ld	s1,8(sp)
    80001272:	6105                	addi	sp,sp,32
    80001274:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001276:	8f99                	sub	a5,a5,a4
    80001278:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000127a:	4685                	li	a3,1
    8000127c:	0007861b          	sext.w	a2,a5
    80001280:	85ba                	mv	a1,a4
    80001282:	f39ff0ef          	jal	800011ba <uvmunmap>
    80001286:	b7d5                	j	8000126a <uvmdealloc+0x26>

0000000080001288 <uvmalloc>:
  if(newsz < oldsz)
    80001288:	08b66f63          	bltu	a2,a1,80001326 <uvmalloc+0x9e>
{
    8000128c:	7139                	addi	sp,sp,-64
    8000128e:	fc06                	sd	ra,56(sp)
    80001290:	f822                	sd	s0,48(sp)
    80001292:	ec4e                	sd	s3,24(sp)
    80001294:	e852                	sd	s4,16(sp)
    80001296:	e456                	sd	s5,8(sp)
    80001298:	0080                	addi	s0,sp,64
    8000129a:	8aaa                	mv	s5,a0
    8000129c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000129e:	6785                	lui	a5,0x1
    800012a0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012a2:	95be                	add	a1,a1,a5
    800012a4:	77fd                	lui	a5,0xfffff
    800012a6:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012aa:	08c9f063          	bgeu	s3,a2,8000132a <uvmalloc+0xa2>
    800012ae:	f426                	sd	s1,40(sp)
    800012b0:	f04a                	sd	s2,32(sp)
    800012b2:	e05a                	sd	s6,0(sp)
    800012b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800012ba:	845ff0ef          	jal	80000afe <kalloc>
    800012be:	84aa                	mv	s1,a0
    if(mem == 0){
    800012c0:	c515                	beqz	a0,800012ec <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800012c2:	6605                	lui	a2,0x1
    800012c4:	4581                	li	a1,0
    800012c6:	9ddff0ef          	jal	80000ca2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012ca:	875a                	mv	a4,s6
    800012cc:	86a6                	mv	a3,s1
    800012ce:	6605                	lui	a2,0x1
    800012d0:	85ca                	mv	a1,s2
    800012d2:	8556                	mv	a0,s5
    800012d4:	d1bff0ef          	jal	80000fee <mappages>
    800012d8:	e915                	bnez	a0,8000130c <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012da:	6785                	lui	a5,0x1
    800012dc:	993e                	add	s2,s2,a5
    800012de:	fd496ee3          	bltu	s2,s4,800012ba <uvmalloc+0x32>
  return newsz;
    800012e2:	8552                	mv	a0,s4
    800012e4:	74a2                	ld	s1,40(sp)
    800012e6:	7902                	ld	s2,32(sp)
    800012e8:	6b02                	ld	s6,0(sp)
    800012ea:	a811                	j	800012fe <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    800012ec:	864e                	mv	a2,s3
    800012ee:	85ca                	mv	a1,s2
    800012f0:	8556                	mv	a0,s5
    800012f2:	f53ff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    800012f6:	4501                	li	a0,0
    800012f8:	74a2                	ld	s1,40(sp)
    800012fa:	7902                	ld	s2,32(sp)
    800012fc:	6b02                	ld	s6,0(sp)
}
    800012fe:	70e2                	ld	ra,56(sp)
    80001300:	7442                	ld	s0,48(sp)
    80001302:	69e2                	ld	s3,24(sp)
    80001304:	6a42                	ld	s4,16(sp)
    80001306:	6aa2                	ld	s5,8(sp)
    80001308:	6121                	addi	sp,sp,64
    8000130a:	8082                	ret
      kfree(mem);
    8000130c:	8526                	mv	a0,s1
    8000130e:	f0eff0ef          	jal	80000a1c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001312:	864e                	mv	a2,s3
    80001314:	85ca                	mv	a1,s2
    80001316:	8556                	mv	a0,s5
    80001318:	f2dff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    8000131c:	4501                	li	a0,0
    8000131e:	74a2                	ld	s1,40(sp)
    80001320:	7902                	ld	s2,32(sp)
    80001322:	6b02                	ld	s6,0(sp)
    80001324:	bfe9                	j	800012fe <uvmalloc+0x76>
    return oldsz;
    80001326:	852e                	mv	a0,a1
}
    80001328:	8082                	ret
  return newsz;
    8000132a:	8532                	mv	a0,a2
    8000132c:	bfc9                	j	800012fe <uvmalloc+0x76>

000000008000132e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000132e:	7179                	addi	sp,sp,-48
    80001330:	f406                	sd	ra,40(sp)
    80001332:	f022                	sd	s0,32(sp)
    80001334:	ec26                	sd	s1,24(sp)
    80001336:	e84a                	sd	s2,16(sp)
    80001338:	e44e                	sd	s3,8(sp)
    8000133a:	e052                	sd	s4,0(sp)
    8000133c:	1800                	addi	s0,sp,48
    8000133e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001340:	84aa                	mv	s1,a0
    80001342:	6905                	lui	s2,0x1
    80001344:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001346:	4985                	li	s3,1
    80001348:	a819                	j	8000135e <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000134a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000134c:	00c79513          	slli	a0,a5,0xc
    80001350:	fdfff0ef          	jal	8000132e <freewalk>
      pagetable[i] = 0;
    80001354:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001358:	04a1                	addi	s1,s1,8
    8000135a:	01248f63          	beq	s1,s2,80001378 <freewalk+0x4a>
    pte_t pte = pagetable[i];
    8000135e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001360:	00f7f713          	andi	a4,a5,15
    80001364:	ff3703e3          	beq	a4,s3,8000134a <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001368:	8b85                	andi	a5,a5,1
    8000136a:	d7fd                	beqz	a5,80001358 <freewalk+0x2a>
      panic("freewalk: leaf");
    8000136c:	00006517          	auipc	a0,0x6
    80001370:	dcc50513          	addi	a0,a0,-564 # 80007138 <etext+0x138>
    80001374:	c6cff0ef          	jal	800007e0 <panic>
    }
  }
  kfree((void*)pagetable);
    80001378:	8552                	mv	a0,s4
    8000137a:	ea2ff0ef          	jal	80000a1c <kfree>
}
    8000137e:	70a2                	ld	ra,40(sp)
    80001380:	7402                	ld	s0,32(sp)
    80001382:	64e2                	ld	s1,24(sp)
    80001384:	6942                	ld	s2,16(sp)
    80001386:	69a2                	ld	s3,8(sp)
    80001388:	6a02                	ld	s4,0(sp)
    8000138a:	6145                	addi	sp,sp,48
    8000138c:	8082                	ret

000000008000138e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000138e:	1101                	addi	sp,sp,-32
    80001390:	ec06                	sd	ra,24(sp)
    80001392:	e822                	sd	s0,16(sp)
    80001394:	e426                	sd	s1,8(sp)
    80001396:	1000                	addi	s0,sp,32
    80001398:	84aa                	mv	s1,a0
  if(sz > 0)
    8000139a:	e989                	bnez	a1,800013ac <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000139c:	8526                	mv	a0,s1
    8000139e:	f91ff0ef          	jal	8000132e <freewalk>
}
    800013a2:	60e2                	ld	ra,24(sp)
    800013a4:	6442                	ld	s0,16(sp)
    800013a6:	64a2                	ld	s1,8(sp)
    800013a8:	6105                	addi	sp,sp,32
    800013aa:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013ac:	6785                	lui	a5,0x1
    800013ae:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013b0:	95be                	add	a1,a1,a5
    800013b2:	4685                	li	a3,1
    800013b4:	00c5d613          	srli	a2,a1,0xc
    800013b8:	4581                	li	a1,0
    800013ba:	e01ff0ef          	jal	800011ba <uvmunmap>
    800013be:	bff9                	j	8000139c <uvmfree+0xe>

00000000800013c0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800013c0:	ce49                	beqz	a2,8000145a <uvmcopy+0x9a>
{
    800013c2:	715d                	addi	sp,sp,-80
    800013c4:	e486                	sd	ra,72(sp)
    800013c6:	e0a2                	sd	s0,64(sp)
    800013c8:	fc26                	sd	s1,56(sp)
    800013ca:	f84a                	sd	s2,48(sp)
    800013cc:	f44e                	sd	s3,40(sp)
    800013ce:	f052                	sd	s4,32(sp)
    800013d0:	ec56                	sd	s5,24(sp)
    800013d2:	e85a                	sd	s6,16(sp)
    800013d4:	e45e                	sd	s7,8(sp)
    800013d6:	0880                	addi	s0,sp,80
    800013d8:	8aaa                	mv	s5,a0
    800013da:	8b2e                	mv	s6,a1
    800013dc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800013de:	4481                	li	s1,0
    800013e0:	a029                	j	800013ea <uvmcopy+0x2a>
    800013e2:	6785                	lui	a5,0x1
    800013e4:	94be                	add	s1,s1,a5
    800013e6:	0544fe63          	bgeu	s1,s4,80001442 <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    800013ea:	4601                	li	a2,0
    800013ec:	85a6                	mv	a1,s1
    800013ee:	8556                	mv	a0,s5
    800013f0:	b27ff0ef          	jal	80000f16 <walk>
    800013f4:	d57d                	beqz	a0,800013e2 <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    800013f6:	6118                	ld	a4,0(a0)
    800013f8:	00177793          	andi	a5,a4,1
    800013fc:	d3fd                	beqz	a5,800013e2 <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    800013fe:	00a75593          	srli	a1,a4,0xa
    80001402:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001406:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000140a:	ef4ff0ef          	jal	80000afe <kalloc>
    8000140e:	89aa                	mv	s3,a0
    80001410:	c105                	beqz	a0,80001430 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001412:	6605                	lui	a2,0x1
    80001414:	85de                	mv	a1,s7
    80001416:	8e9ff0ef          	jal	80000cfe <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000141a:	874a                	mv	a4,s2
    8000141c:	86ce                	mv	a3,s3
    8000141e:	6605                	lui	a2,0x1
    80001420:	85a6                	mv	a1,s1
    80001422:	855a                	mv	a0,s6
    80001424:	bcbff0ef          	jal	80000fee <mappages>
    80001428:	dd4d                	beqz	a0,800013e2 <uvmcopy+0x22>
      kfree(mem);
    8000142a:	854e                	mv	a0,s3
    8000142c:	df0ff0ef          	jal	80000a1c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001430:	4685                	li	a3,1
    80001432:	00c4d613          	srli	a2,s1,0xc
    80001436:	4581                	li	a1,0
    80001438:	855a                	mv	a0,s6
    8000143a:	d81ff0ef          	jal	800011ba <uvmunmap>
  return -1;
    8000143e:	557d                	li	a0,-1
    80001440:	a011                	j	80001444 <uvmcopy+0x84>
  return 0;
    80001442:	4501                	li	a0,0
}
    80001444:	60a6                	ld	ra,72(sp)
    80001446:	6406                	ld	s0,64(sp)
    80001448:	74e2                	ld	s1,56(sp)
    8000144a:	7942                	ld	s2,48(sp)
    8000144c:	79a2                	ld	s3,40(sp)
    8000144e:	7a02                	ld	s4,32(sp)
    80001450:	6ae2                	ld	s5,24(sp)
    80001452:	6b42                	ld	s6,16(sp)
    80001454:	6ba2                	ld	s7,8(sp)
    80001456:	6161                	addi	sp,sp,80
    80001458:	8082                	ret
  return 0;
    8000145a:	4501                	li	a0,0
}
    8000145c:	8082                	ret

000000008000145e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000145e:	1141                	addi	sp,sp,-16
    80001460:	e406                	sd	ra,8(sp)
    80001462:	e022                	sd	s0,0(sp)
    80001464:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001466:	4601                	li	a2,0
    80001468:	aafff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    8000146c:	c901                	beqz	a0,8000147c <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000146e:	611c                	ld	a5,0(a0)
    80001470:	9bbd                	andi	a5,a5,-17
    80001472:	e11c                	sd	a5,0(a0)
}
    80001474:	60a2                	ld	ra,8(sp)
    80001476:	6402                	ld	s0,0(sp)
    80001478:	0141                	addi	sp,sp,16
    8000147a:	8082                	ret
    panic("uvmclear");
    8000147c:	00006517          	auipc	a0,0x6
    80001480:	ccc50513          	addi	a0,a0,-820 # 80007148 <etext+0x148>
    80001484:	b5cff0ef          	jal	800007e0 <panic>

0000000080001488 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001488:	c6dd                	beqz	a3,80001536 <copyinstr+0xae>
{
    8000148a:	715d                	addi	sp,sp,-80
    8000148c:	e486                	sd	ra,72(sp)
    8000148e:	e0a2                	sd	s0,64(sp)
    80001490:	fc26                	sd	s1,56(sp)
    80001492:	f84a                	sd	s2,48(sp)
    80001494:	f44e                	sd	s3,40(sp)
    80001496:	f052                	sd	s4,32(sp)
    80001498:	ec56                	sd	s5,24(sp)
    8000149a:	e85a                	sd	s6,16(sp)
    8000149c:	e45e                	sd	s7,8(sp)
    8000149e:	0880                	addi	s0,sp,80
    800014a0:	8a2a                	mv	s4,a0
    800014a2:	8b2e                	mv	s6,a1
    800014a4:	8bb2                	mv	s7,a2
    800014a6:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014a8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014aa:	6985                	lui	s3,0x1
    800014ac:	a825                	j	800014e4 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014ae:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014b2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014b4:	37fd                	addiw	a5,a5,-1
    800014b6:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014ba:	60a6                	ld	ra,72(sp)
    800014bc:	6406                	ld	s0,64(sp)
    800014be:	74e2                	ld	s1,56(sp)
    800014c0:	7942                	ld	s2,48(sp)
    800014c2:	79a2                	ld	s3,40(sp)
    800014c4:	7a02                	ld	s4,32(sp)
    800014c6:	6ae2                	ld	s5,24(sp)
    800014c8:	6b42                	ld	s6,16(sp)
    800014ca:	6ba2                	ld	s7,8(sp)
    800014cc:	6161                	addi	sp,sp,80
    800014ce:	8082                	ret
    800014d0:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    800014d4:	9742                	add	a4,a4,a6
      --max;
    800014d6:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    800014da:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    800014de:	04e58463          	beq	a1,a4,80001526 <copyinstr+0x9e>
{
    800014e2:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    800014e4:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800014e8:	85a6                	mv	a1,s1
    800014ea:	8552                	mv	a0,s4
    800014ec:	ac5ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0)
    800014f0:	cd0d                	beqz	a0,8000152a <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800014f2:	417486b3          	sub	a3,s1,s7
    800014f6:	96ce                	add	a3,a3,s3
    if(n > max)
    800014f8:	00d97363          	bgeu	s2,a3,800014fe <copyinstr+0x76>
    800014fc:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    800014fe:	955e                	add	a0,a0,s7
    80001500:	8d05                	sub	a0,a0,s1
    while(n > 0){
    80001502:	c695                	beqz	a3,8000152e <copyinstr+0xa6>
    80001504:	87da                	mv	a5,s6
    80001506:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001508:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000150c:	96da                	add	a3,a3,s6
    8000150e:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001510:	00f60733          	add	a4,a2,a5
    80001514:	00074703          	lbu	a4,0(a4)
    80001518:	db59                	beqz	a4,800014ae <copyinstr+0x26>
        *dst = *p;
    8000151a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000151e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001520:	fed797e3          	bne	a5,a3,8000150e <copyinstr+0x86>
    80001524:	b775                	j	800014d0 <copyinstr+0x48>
    80001526:	4781                	li	a5,0
    80001528:	b771                	j	800014b4 <copyinstr+0x2c>
      return -1;
    8000152a:	557d                	li	a0,-1
    8000152c:	b779                	j	800014ba <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    8000152e:	6b85                	lui	s7,0x1
    80001530:	9ba6                	add	s7,s7,s1
    80001532:	87da                	mv	a5,s6
    80001534:	b77d                	j	800014e2 <copyinstr+0x5a>
  int got_null = 0;
    80001536:	4781                	li	a5,0
  if(got_null){
    80001538:	37fd                	addiw	a5,a5,-1
    8000153a:	0007851b          	sext.w	a0,a5
}
    8000153e:	8082                	ret

0000000080001540 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001540:	1141                	addi	sp,sp,-16
    80001542:	e406                	sd	ra,8(sp)
    80001544:	e022                	sd	s0,0(sp)
    80001546:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001548:	4601                	li	a2,0
    8000154a:	9cdff0ef          	jal	80000f16 <walk>
  if (pte == 0) {
    8000154e:	c519                	beqz	a0,8000155c <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001550:	6108                	ld	a0,0(a0)
    80001552:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    80001554:	60a2                	ld	ra,8(sp)
    80001556:	6402                	ld	s0,0(sp)
    80001558:	0141                	addi	sp,sp,16
    8000155a:	8082                	ret
    return 0;
    8000155c:	4501                	li	a0,0
    8000155e:	bfdd                	j	80001554 <ismapped+0x14>

0000000080001560 <vmfault>:
{
    80001560:	7179                	addi	sp,sp,-48
    80001562:	f406                	sd	ra,40(sp)
    80001564:	f022                	sd	s0,32(sp)
    80001566:	ec26                	sd	s1,24(sp)
    80001568:	e44e                	sd	s3,8(sp)
    8000156a:	1800                	addi	s0,sp,48
    8000156c:	89aa                	mv	s3,a0
    8000156e:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    80001570:	35e000ef          	jal	800018ce <myproc>
  if (va >= p->sz)
    80001574:	653c                	ld	a5,72(a0)
    80001576:	00f4ea63          	bltu	s1,a5,8000158a <vmfault+0x2a>
    return 0;
    8000157a:	4981                	li	s3,0
}
    8000157c:	854e                	mv	a0,s3
    8000157e:	70a2                	ld	ra,40(sp)
    80001580:	7402                	ld	s0,32(sp)
    80001582:	64e2                	ld	s1,24(sp)
    80001584:	69a2                	ld	s3,8(sp)
    80001586:	6145                	addi	sp,sp,48
    80001588:	8082                	ret
    8000158a:	e84a                	sd	s2,16(sp)
    8000158c:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    8000158e:	77fd                	lui	a5,0xfffff
    80001590:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    80001592:	85a6                	mv	a1,s1
    80001594:	854e                	mv	a0,s3
    80001596:	fabff0ef          	jal	80001540 <ismapped>
    return 0;
    8000159a:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    8000159c:	c119                	beqz	a0,800015a2 <vmfault+0x42>
    8000159e:	6942                	ld	s2,16(sp)
    800015a0:	bff1                	j	8000157c <vmfault+0x1c>
    800015a2:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015a4:	d5aff0ef          	jal	80000afe <kalloc>
    800015a8:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015aa:	c90d                	beqz	a0,800015dc <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015ac:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	4581                	li	a1,0
    800015b2:	ef0ff0ef          	jal	80000ca2 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015b6:	4759                	li	a4,22
    800015b8:	86d2                	mv	a3,s4
    800015ba:	6605                	lui	a2,0x1
    800015bc:	85a6                	mv	a1,s1
    800015be:	05093503          	ld	a0,80(s2)
    800015c2:	a2dff0ef          	jal	80000fee <mappages>
    800015c6:	e501                	bnez	a0,800015ce <vmfault+0x6e>
    800015c8:	6942                	ld	s2,16(sp)
    800015ca:	6a02                	ld	s4,0(sp)
    800015cc:	bf45                	j	8000157c <vmfault+0x1c>
    kfree((void *)mem);
    800015ce:	8552                	mv	a0,s4
    800015d0:	c4cff0ef          	jal	80000a1c <kfree>
    return 0;
    800015d4:	4981                	li	s3,0
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	6a02                	ld	s4,0(sp)
    800015da:	b74d                	j	8000157c <vmfault+0x1c>
    800015dc:	6942                	ld	s2,16(sp)
    800015de:	6a02                	ld	s4,0(sp)
    800015e0:	bf71                	j	8000157c <vmfault+0x1c>

00000000800015e2 <copyout>:
  while(len > 0){
    800015e2:	c2cd                	beqz	a3,80001684 <copyout+0xa2>
{
    800015e4:	711d                	addi	sp,sp,-96
    800015e6:	ec86                	sd	ra,88(sp)
    800015e8:	e8a2                	sd	s0,80(sp)
    800015ea:	e4a6                	sd	s1,72(sp)
    800015ec:	f852                	sd	s4,48(sp)
    800015ee:	f05a                	sd	s6,32(sp)
    800015f0:	ec5e                	sd	s7,24(sp)
    800015f2:	e862                	sd	s8,16(sp)
    800015f4:	1080                	addi	s0,sp,96
    800015f6:	8c2a                	mv	s8,a0
    800015f8:	8b2e                	mv	s6,a1
    800015fa:	8bb2                	mv	s7,a2
    800015fc:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800015fe:	74fd                	lui	s1,0xfffff
    80001600:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001602:	57fd                	li	a5,-1
    80001604:	83e9                	srli	a5,a5,0x1a
    80001606:	0897e163          	bltu	a5,s1,80001688 <copyout+0xa6>
    8000160a:	e0ca                	sd	s2,64(sp)
    8000160c:	fc4e                	sd	s3,56(sp)
    8000160e:	f456                	sd	s5,40(sp)
    80001610:	e466                	sd	s9,8(sp)
    80001612:	e06a                	sd	s10,0(sp)
    80001614:	6d05                	lui	s10,0x1
    80001616:	8cbe                	mv	s9,a5
    80001618:	a015                	j	8000163c <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000161a:	409b0533          	sub	a0,s6,s1
    8000161e:	0009861b          	sext.w	a2,s3
    80001622:	85de                	mv	a1,s7
    80001624:	954a                	add	a0,a0,s2
    80001626:	ed8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000162a:	413a0a33          	sub	s4,s4,s3
    src += n;
    8000162e:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001630:	040a0363          	beqz	s4,80001676 <copyout+0x94>
    if(va0 >= MAXVA)
    80001634:	055cec63          	bltu	s9,s5,8000168c <copyout+0xaa>
    80001638:	84d6                	mv	s1,s5
    8000163a:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    8000163c:	85a6                	mv	a1,s1
    8000163e:	8562                	mv	a0,s8
    80001640:	971ff0ef          	jal	80000fb0 <walkaddr>
    80001644:	892a                	mv	s2,a0
    if(pa0 == 0) {
    80001646:	e901                	bnez	a0,80001656 <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001648:	4601                	li	a2,0
    8000164a:	85a6                	mv	a1,s1
    8000164c:	8562                	mv	a0,s8
    8000164e:	f13ff0ef          	jal	80001560 <vmfault>
    80001652:	892a                	mv	s2,a0
    80001654:	c139                	beqz	a0,8000169a <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    80001656:	4601                	li	a2,0
    80001658:	85a6                	mv	a1,s1
    8000165a:	8562                	mv	a0,s8
    8000165c:	8bbff0ef          	jal	80000f16 <walk>
    if((*pte & PTE_W) == 0)
    80001660:	611c                	ld	a5,0(a0)
    80001662:	8b91                	andi	a5,a5,4
    80001664:	c3b1                	beqz	a5,800016a8 <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    80001666:	01a48ab3          	add	s5,s1,s10
    8000166a:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    8000166e:	fb3a76e3          	bgeu	s4,s3,8000161a <copyout+0x38>
    80001672:	89d2                	mv	s3,s4
    80001674:	b75d                	j	8000161a <copyout+0x38>
  return 0;
    80001676:	4501                	li	a0,0
    80001678:	6906                	ld	s2,64(sp)
    8000167a:	79e2                	ld	s3,56(sp)
    8000167c:	7aa2                	ld	s5,40(sp)
    8000167e:	6ca2                	ld	s9,8(sp)
    80001680:	6d02                	ld	s10,0(sp)
    80001682:	a80d                	j	800016b4 <copyout+0xd2>
    80001684:	4501                	li	a0,0
}
    80001686:	8082                	ret
      return -1;
    80001688:	557d                	li	a0,-1
    8000168a:	a02d                	j	800016b4 <copyout+0xd2>
    8000168c:	557d                	li	a0,-1
    8000168e:	6906                	ld	s2,64(sp)
    80001690:	79e2                	ld	s3,56(sp)
    80001692:	7aa2                	ld	s5,40(sp)
    80001694:	6ca2                	ld	s9,8(sp)
    80001696:	6d02                	ld	s10,0(sp)
    80001698:	a831                	j	800016b4 <copyout+0xd2>
        return -1;
    8000169a:	557d                	li	a0,-1
    8000169c:	6906                	ld	s2,64(sp)
    8000169e:	79e2                	ld	s3,56(sp)
    800016a0:	7aa2                	ld	s5,40(sp)
    800016a2:	6ca2                	ld	s9,8(sp)
    800016a4:	6d02                	ld	s10,0(sp)
    800016a6:	a039                	j	800016b4 <copyout+0xd2>
      return -1;
    800016a8:	557d                	li	a0,-1
    800016aa:	6906                	ld	s2,64(sp)
    800016ac:	79e2                	ld	s3,56(sp)
    800016ae:	7aa2                	ld	s5,40(sp)
    800016b0:	6ca2                	ld	s9,8(sp)
    800016b2:	6d02                	ld	s10,0(sp)
}
    800016b4:	60e6                	ld	ra,88(sp)
    800016b6:	6446                	ld	s0,80(sp)
    800016b8:	64a6                	ld	s1,72(sp)
    800016ba:	7a42                	ld	s4,48(sp)
    800016bc:	7b02                	ld	s6,32(sp)
    800016be:	6be2                	ld	s7,24(sp)
    800016c0:	6c42                	ld	s8,16(sp)
    800016c2:	6125                	addi	sp,sp,96
    800016c4:	8082                	ret

00000000800016c6 <copyin>:
  while(len > 0){
    800016c6:	c6c9                	beqz	a3,80001750 <copyin+0x8a>
{
    800016c8:	715d                	addi	sp,sp,-80
    800016ca:	e486                	sd	ra,72(sp)
    800016cc:	e0a2                	sd	s0,64(sp)
    800016ce:	fc26                	sd	s1,56(sp)
    800016d0:	f84a                	sd	s2,48(sp)
    800016d2:	f44e                	sd	s3,40(sp)
    800016d4:	f052                	sd	s4,32(sp)
    800016d6:	ec56                	sd	s5,24(sp)
    800016d8:	e85a                	sd	s6,16(sp)
    800016da:	e45e                	sd	s7,8(sp)
    800016dc:	e062                	sd	s8,0(sp)
    800016de:	0880                	addi	s0,sp,80
    800016e0:	8baa                	mv	s7,a0
    800016e2:	8aae                	mv	s5,a1
    800016e4:	8932                	mv	s2,a2
    800016e6:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    800016e8:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    800016ea:	6b05                	lui	s6,0x1
    800016ec:	a035                	j	80001718 <copyin+0x52>
    800016ee:	412984b3          	sub	s1,s3,s2
    800016f2:	94da                	add	s1,s1,s6
    if(n > len)
    800016f4:	009a7363          	bgeu	s4,s1,800016fa <copyin+0x34>
    800016f8:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016fa:	413905b3          	sub	a1,s2,s3
    800016fe:	0004861b          	sext.w	a2,s1
    80001702:	95aa                	add	a1,a1,a0
    80001704:	8556                	mv	a0,s5
    80001706:	df8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000170a:	409a0a33          	sub	s4,s4,s1
    dst += n;
    8000170e:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001710:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001714:	020a0163          	beqz	s4,80001736 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001718:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000171c:	85ce                	mv	a1,s3
    8000171e:	855e                	mv	a0,s7
    80001720:	891ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0) {
    80001724:	f569                	bnez	a0,800016ee <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001726:	4601                	li	a2,0
    80001728:	85ce                	mv	a1,s3
    8000172a:	855e                	mv	a0,s7
    8000172c:	e35ff0ef          	jal	80001560 <vmfault>
    80001730:	fd5d                	bnez	a0,800016ee <copyin+0x28>
        return -1;
    80001732:	557d                	li	a0,-1
    80001734:	a011                	j	80001738 <copyin+0x72>
  return 0;
    80001736:	4501                	li	a0,0
}
    80001738:	60a6                	ld	ra,72(sp)
    8000173a:	6406                	ld	s0,64(sp)
    8000173c:	74e2                	ld	s1,56(sp)
    8000173e:	7942                	ld	s2,48(sp)
    80001740:	79a2                	ld	s3,40(sp)
    80001742:	7a02                	ld	s4,32(sp)
    80001744:	6ae2                	ld	s5,24(sp)
    80001746:	6b42                	ld	s6,16(sp)
    80001748:	6ba2                	ld	s7,8(sp)
    8000174a:	6c02                	ld	s8,0(sp)
    8000174c:	6161                	addi	sp,sp,80
    8000174e:	8082                	ret
  return 0;
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret

0000000080001754 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001754:	7139                	addi	sp,sp,-64
    80001756:	fc06                	sd	ra,56(sp)
    80001758:	f822                	sd	s0,48(sp)
    8000175a:	f426                	sd	s1,40(sp)
    8000175c:	f04a                	sd	s2,32(sp)
    8000175e:	ec4e                	sd	s3,24(sp)
    80001760:	e852                	sd	s4,16(sp)
    80001762:	e456                	sd	s5,8(sp)
    80001764:	e05a                	sd	s6,0(sp)
    80001766:	0080                	addi	s0,sp,64
    80001768:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000176a:	00011497          	auipc	s1,0x11
    8000176e:	ffe48493          	addi	s1,s1,-2 # 80012768 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001772:	8b26                	mv	s6,s1
    80001774:	ff4df937          	lui	s2,0xff4df
    80001778:	9bd90913          	addi	s2,s2,-1603 # ffffffffff4de9bd <end+0xffffffff7f4bb275>
    8000177c:	0936                	slli	s2,s2,0xd
    8000177e:	6f590913          	addi	s2,s2,1781
    80001782:	0936                	slli	s2,s2,0xd
    80001784:	bd390913          	addi	s2,s2,-1069
    80001788:	0932                	slli	s2,s2,0xc
    8000178a:	7a790913          	addi	s2,s2,1959
    8000178e:	040009b7          	lui	s3,0x4000
    80001792:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001794:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001796:	00017a97          	auipc	s5,0x17
    8000179a:	bd2a8a93          	addi	s5,s5,-1070 # 80018368 <tickslock>
    char *pa = kalloc();
    8000179e:	b60ff0ef          	jal	80000afe <kalloc>
    800017a2:	862a                	mv	a2,a0
    if(pa == 0)
    800017a4:	cd15                	beqz	a0,800017e0 <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int) (p - proc));
    800017a6:	416485b3          	sub	a1,s1,s6
    800017aa:	8591                	srai	a1,a1,0x4
    800017ac:	032585b3          	mul	a1,a1,s2
    800017b0:	2585                	addiw	a1,a1,1
    800017b2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017b6:	4719                	li	a4,6
    800017b8:	6685                	lui	a3,0x1
    800017ba:	40b985b3          	sub	a1,s3,a1
    800017be:	8552                	mv	a0,s4
    800017c0:	8dfff0ef          	jal	8000109e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800017c4:	17048493          	addi	s1,s1,368
    800017c8:	fd549be3          	bne	s1,s5,8000179e <proc_mapstacks+0x4a>
  }
}
    800017cc:	70e2                	ld	ra,56(sp)
    800017ce:	7442                	ld	s0,48(sp)
    800017d0:	74a2                	ld	s1,40(sp)
    800017d2:	7902                	ld	s2,32(sp)
    800017d4:	69e2                	ld	s3,24(sp)
    800017d6:	6a42                	ld	s4,16(sp)
    800017d8:	6aa2                	ld	s5,8(sp)
    800017da:	6b02                	ld	s6,0(sp)
    800017dc:	6121                	addi	sp,sp,64
    800017de:	8082                	ret
      panic("kalloc");
    800017e0:	00006517          	auipc	a0,0x6
    800017e4:	97850513          	addi	a0,a0,-1672 # 80007158 <etext+0x158>
    800017e8:	ff9fe0ef          	jal	800007e0 <panic>

00000000800017ec <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800017ec:	7139                	addi	sp,sp,-64
    800017ee:	fc06                	sd	ra,56(sp)
    800017f0:	f822                	sd	s0,48(sp)
    800017f2:	f426                	sd	s1,40(sp)
    800017f4:	f04a                	sd	s2,32(sp)
    800017f6:	ec4e                	sd	s3,24(sp)
    800017f8:	e852                	sd	s4,16(sp)
    800017fa:	e456                	sd	s5,8(sp)
    800017fc:	e05a                	sd	s6,0(sp)
    800017fe:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001800:	00006597          	auipc	a1,0x6
    80001804:	96058593          	addi	a1,a1,-1696 # 80007160 <etext+0x160>
    80001808:	00011517          	auipc	a0,0x11
    8000180c:	b3050513          	addi	a0,a0,-1232 # 80012338 <pid_lock>
    80001810:	b3eff0ef          	jal	80000b4e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001814:	00006597          	auipc	a1,0x6
    80001818:	95458593          	addi	a1,a1,-1708 # 80007168 <etext+0x168>
    8000181c:	00011517          	auipc	a0,0x11
    80001820:	b3450513          	addi	a0,a0,-1228 # 80012350 <wait_lock>
    80001824:	b2aff0ef          	jal	80000b4e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001828:	00011497          	auipc	s1,0x11
    8000182c:	f4048493          	addi	s1,s1,-192 # 80012768 <proc>
      initlock(&p->lock, "proc");
    80001830:	00006b17          	auipc	s6,0x6
    80001834:	948b0b13          	addi	s6,s6,-1720 # 80007178 <etext+0x178>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001838:	8aa6                	mv	s5,s1
    8000183a:	ff4df937          	lui	s2,0xff4df
    8000183e:	9bd90913          	addi	s2,s2,-1603 # ffffffffff4de9bd <end+0xffffffff7f4bb275>
    80001842:	0936                	slli	s2,s2,0xd
    80001844:	6f590913          	addi	s2,s2,1781
    80001848:	0936                	slli	s2,s2,0xd
    8000184a:	bd390913          	addi	s2,s2,-1069
    8000184e:	0932                	slli	s2,s2,0xc
    80001850:	7a790913          	addi	s2,s2,1959
    80001854:	040009b7          	lui	s3,0x4000
    80001858:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000185a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00017a17          	auipc	s4,0x17
    80001860:	b0ca0a13          	addi	s4,s4,-1268 # 80018368 <tickslock>
      initlock(&p->lock, "proc");
    80001864:	85da                	mv	a1,s6
    80001866:	8526                	mv	a0,s1
    80001868:	ae6ff0ef          	jal	80000b4e <initlock>
      p->state = UNUSED;
    8000186c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001870:	415487b3          	sub	a5,s1,s5
    80001874:	8791                	srai	a5,a5,0x4
    80001876:	032787b3          	mul	a5,a5,s2
    8000187a:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffdb8b9>
    8000187c:	00d7979b          	slliw	a5,a5,0xd
    80001880:	40f987b3          	sub	a5,s3,a5
    80001884:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001886:	17048493          	addi	s1,s1,368
    8000188a:	fd449de3          	bne	s1,s4,80001864 <procinit+0x78>
  }
}
    8000188e:	70e2                	ld	ra,56(sp)
    80001890:	7442                	ld	s0,48(sp)
    80001892:	74a2                	ld	s1,40(sp)
    80001894:	7902                	ld	s2,32(sp)
    80001896:	69e2                	ld	s3,24(sp)
    80001898:	6a42                	ld	s4,16(sp)
    8000189a:	6aa2                	ld	s5,8(sp)
    8000189c:	6b02                	ld	s6,0(sp)
    8000189e:	6121                	addi	sp,sp,64
    800018a0:	8082                	ret

00000000800018a2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018a2:	1141                	addi	sp,sp,-16
    800018a4:	e422                	sd	s0,8(sp)
    800018a6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018a8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018aa:	2501                	sext.w	a0,a0
    800018ac:	6422                	ld	s0,8(sp)
    800018ae:	0141                	addi	sp,sp,16
    800018b0:	8082                	ret

00000000800018b2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800018b2:	1141                	addi	sp,sp,-16
    800018b4:	e422                	sd	s0,8(sp)
    800018b6:	0800                	addi	s0,sp,16
    800018b8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018ba:	2781                	sext.w	a5,a5
    800018bc:	079e                	slli	a5,a5,0x7
  return c;
}
    800018be:	00011517          	auipc	a0,0x11
    800018c2:	aaa50513          	addi	a0,a0,-1366 # 80012368 <cpus>
    800018c6:	953e                	add	a0,a0,a5
    800018c8:	6422                	ld	s0,8(sp)
    800018ca:	0141                	addi	sp,sp,16
    800018cc:	8082                	ret

00000000800018ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800018ce:	1101                	addi	sp,sp,-32
    800018d0:	ec06                	sd	ra,24(sp)
    800018d2:	e822                	sd	s0,16(sp)
    800018d4:	e426                	sd	s1,8(sp)
    800018d6:	1000                	addi	s0,sp,32
  push_off();
    800018d8:	ab6ff0ef          	jal	80000b8e <push_off>
    800018dc:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800018de:	2781                	sext.w	a5,a5
    800018e0:	079e                	slli	a5,a5,0x7
    800018e2:	00011717          	auipc	a4,0x11
    800018e6:	a5670713          	addi	a4,a4,-1450 # 80012338 <pid_lock>
    800018ea:	97ba                	add	a5,a5,a4
    800018ec:	7b84                	ld	s1,48(a5)
  pop_off();
    800018ee:	b24ff0ef          	jal	80000c12 <pop_off>
  return p;
}
    800018f2:	8526                	mv	a0,s1
    800018f4:	60e2                	ld	ra,24(sp)
    800018f6:	6442                	ld	s0,16(sp)
    800018f8:	64a2                	ld	s1,8(sp)
    800018fa:	6105                	addi	sp,sp,32
    800018fc:	8082                	ret

00000000800018fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800018fe:	7179                	addi	sp,sp,-48
    80001900:	f406                	sd	ra,40(sp)
    80001902:	f022                	sd	s0,32(sp)
    80001904:	ec26                	sd	s1,24(sp)
    80001906:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001908:	fc7ff0ef          	jal	800018ce <myproc>
    8000190c:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    8000190e:	b58ff0ef          	jal	80000c66 <release>

  if (first) {
    80001912:	00009797          	auipc	a5,0x9
    80001916:	8be7a783          	lw	a5,-1858(a5) # 8000a1d0 <first.1>
    8000191a:	cf8d                	beqz	a5,80001954 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    8000191c:	4505                	li	a0,1
    8000191e:	4d9010ef          	jal	800035f6 <fsinit>

    first = 0;
    80001922:	00009797          	auipc	a5,0x9
    80001926:	8a07a723          	sw	zero,-1874(a5) # 8000a1d0 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    8000192a:	0330000f          	fence	rw,rw

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    8000192e:	00006517          	auipc	a0,0x6
    80001932:	85250513          	addi	a0,a0,-1966 # 80007180 <etext+0x180>
    80001936:	fca43823          	sd	a0,-48(s0)
    8000193a:	fc043c23          	sd	zero,-40(s0)
    8000193e:	fd040593          	addi	a1,s0,-48
    80001942:	5bf020ef          	jal	80004700 <kexec>
    80001946:	6cbc                	ld	a5,88(s1)
    80001948:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    8000194a:	6cbc                	ld	a5,88(s1)
    8000194c:	7bb8                	ld	a4,112(a5)
    8000194e:	57fd                	li	a5,-1
    80001950:	02f70d63          	beq	a4,a5,8000198a <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001954:	39b000ef          	jal	800024ee <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001958:	68a8                	ld	a0,80(s1)
    8000195a:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000195c:	04000737          	lui	a4,0x4000
    80001960:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80001962:	0732                	slli	a4,a4,0xc
    80001964:	00004797          	auipc	a5,0x4
    80001968:	73878793          	addi	a5,a5,1848 # 8000609c <userret>
    8000196c:	00004697          	auipc	a3,0x4
    80001970:	69468693          	addi	a3,a3,1684 # 80006000 <_trampoline>
    80001974:	8f95                	sub	a5,a5,a3
    80001976:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001978:	577d                	li	a4,-1
    8000197a:	177e                	slli	a4,a4,0x3f
    8000197c:	8d59                	or	a0,a0,a4
    8000197e:	9782                	jalr	a5
}
    80001980:	70a2                	ld	ra,40(sp)
    80001982:	7402                	ld	s0,32(sp)
    80001984:	64e2                	ld	s1,24(sp)
    80001986:	6145                	addi	sp,sp,48
    80001988:	8082                	ret
      panic("exec");
    8000198a:	00005517          	auipc	a0,0x5
    8000198e:	7fe50513          	addi	a0,a0,2046 # 80007188 <etext+0x188>
    80001992:	e4ffe0ef          	jal	800007e0 <panic>

0000000080001996 <allocpid>:
{
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	e04a                	sd	s2,0(sp)
    800019a0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019a2:	00011917          	auipc	s2,0x11
    800019a6:	99690913          	addi	s2,s2,-1642 # 80012338 <pid_lock>
    800019aa:	854a                	mv	a0,s2
    800019ac:	a22ff0ef          	jal	80000bce <acquire>
  pid = nextpid;
    800019b0:	00009797          	auipc	a5,0x9
    800019b4:	83078793          	addi	a5,a5,-2000 # 8000a1e0 <nextpid>
    800019b8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019ba:	0014871b          	addiw	a4,s1,1
    800019be:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800019c0:	854a                	mv	a0,s2
    800019c2:	aa4ff0ef          	jal	80000c66 <release>
}
    800019c6:	8526                	mv	a0,s1
    800019c8:	60e2                	ld	ra,24(sp)
    800019ca:	6442                	ld	s0,16(sp)
    800019cc:	64a2                	ld	s1,8(sp)
    800019ce:	6902                	ld	s2,0(sp)
    800019d0:	6105                	addi	sp,sp,32
    800019d2:	8082                	ret

00000000800019d4 <do_rand>:
{
    800019d4:	1141                	addi	sp,sp,-16
    800019d6:	e422                	sd	s0,8(sp)
    800019d8:	0800                	addi	s0,sp,16
  x = (*ctx % 0x7ffffffe) + 1;
    800019da:	611c                	ld	a5,0(a0)
    800019dc:	80000737          	lui	a4,0x80000
    800019e0:	ffe74713          	xori	a4,a4,-2
    800019e4:	02e7f7b3          	remu	a5,a5,a4
    800019e8:	0785                	addi	a5,a5,1
  lo = x % 127773;
    800019ea:	66fd                	lui	a3,0x1f
    800019ec:	31d68693          	addi	a3,a3,797 # 1f31d <_entry-0x7ffe0ce3>
    800019f0:	02d7e733          	rem	a4,a5,a3
  x = 16807 * lo - 2836 * hi;
    800019f4:	6611                	lui	a2,0x4
    800019f6:	1a760613          	addi	a2,a2,423 # 41a7 <_entry-0x7fffbe59>
    800019fa:	02c70733          	mul	a4,a4,a2
  hi = x / 127773;
    800019fe:	02d7c7b3          	div	a5,a5,a3
  x = 16807 * lo - 2836 * hi;
    80001a02:	76fd                	lui	a3,0xfffff
    80001a04:	4ec68693          	addi	a3,a3,1260 # fffffffffffff4ec <end+0xffffffff7ffdbda4>
    80001a08:	02d787b3          	mul	a5,a5,a3
    80001a0c:	97ba                	add	a5,a5,a4
  if (x < 0)
    80001a0e:	0007c963          	bltz	a5,80001a20 <do_rand+0x4c>
  x--;
    80001a12:	17fd                	addi	a5,a5,-1
  *ctx = x;
    80001a14:	e11c                	sd	a5,0(a0)
}
    80001a16:	0007851b          	sext.w	a0,a5
    80001a1a:	6422                	ld	s0,8(sp)
    80001a1c:	0141                	addi	sp,sp,16
    80001a1e:	8082                	ret
    x += 0x7fffffff;
    80001a20:	80000737          	lui	a4,0x80000
    80001a24:	fff74713          	not	a4,a4
    80001a28:	97ba                	add	a5,a5,a4
    80001a2a:	b7e5                	j	80001a12 <do_rand+0x3e>

0000000080001a2c <rand>:
{
    80001a2c:	1141                	addi	sp,sp,-16
    80001a2e:	e406                	sd	ra,8(sp)
    80001a30:	e022                	sd	s0,0(sp)
    80001a32:	0800                	addi	s0,sp,16
  return do_rand(&rand_next);
    80001a34:	00008517          	auipc	a0,0x8
    80001a38:	7a450513          	addi	a0,a0,1956 # 8000a1d8 <rand_next>
    80001a3c:	f99ff0ef          	jal	800019d4 <do_rand>
}
    80001a40:	60a2                	ld	ra,8(sp)
    80001a42:	6402                	ld	s0,0(sp)
    80001a44:	0141                	addi	sp,sp,16
    80001a46:	8082                	ret

0000000080001a48 <proc_pagetable>:
{
    80001a48:	1101                	addi	sp,sp,-32
    80001a4a:	ec06                	sd	ra,24(sp)
    80001a4c:	e822                	sd	s0,16(sp)
    80001a4e:	e426                	sd	s1,8(sp)
    80001a50:	e04a                	sd	s2,0(sp)
    80001a52:	1000                	addi	s0,sp,32
    80001a54:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a56:	f3eff0ef          	jal	80001194 <uvmcreate>
    80001a5a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a5c:	cd05                	beqz	a0,80001a94 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a5e:	4729                	li	a4,10
    80001a60:	00004697          	auipc	a3,0x4
    80001a64:	5a068693          	addi	a3,a3,1440 # 80006000 <_trampoline>
    80001a68:	6605                	lui	a2,0x1
    80001a6a:	040005b7          	lui	a1,0x4000
    80001a6e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a70:	05b2                	slli	a1,a1,0xc
    80001a72:	d7cff0ef          	jal	80000fee <mappages>
    80001a76:	02054663          	bltz	a0,80001aa2 <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a7a:	4719                	li	a4,6
    80001a7c:	05893683          	ld	a3,88(s2)
    80001a80:	6605                	lui	a2,0x1
    80001a82:	020005b7          	lui	a1,0x2000
    80001a86:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a88:	05b6                	slli	a1,a1,0xd
    80001a8a:	8526                	mv	a0,s1
    80001a8c:	d62ff0ef          	jal	80000fee <mappages>
    80001a90:	00054f63          	bltz	a0,80001aae <proc_pagetable+0x66>
}
    80001a94:	8526                	mv	a0,s1
    80001a96:	60e2                	ld	ra,24(sp)
    80001a98:	6442                	ld	s0,16(sp)
    80001a9a:	64a2                	ld	s1,8(sp)
    80001a9c:	6902                	ld	s2,0(sp)
    80001a9e:	6105                	addi	sp,sp,32
    80001aa0:	8082                	ret
    uvmfree(pagetable, 0);
    80001aa2:	4581                	li	a1,0
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	8e9ff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001aaa:	4481                	li	s1,0
    80001aac:	b7e5                	j	80001a94 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aae:	4681                	li	a3,0
    80001ab0:	4605                	li	a2,1
    80001ab2:	040005b7          	lui	a1,0x4000
    80001ab6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ab8:	05b2                	slli	a1,a1,0xc
    80001aba:	8526                	mv	a0,s1
    80001abc:	efeff0ef          	jal	800011ba <uvmunmap>
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	8cbff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001ac8:	4481                	li	s1,0
    80001aca:	b7e9                	j	80001a94 <proc_pagetable+0x4c>

0000000080001acc <proc_freepagetable>:
{
    80001acc:	1101                	addi	sp,sp,-32
    80001ace:	ec06                	sd	ra,24(sp)
    80001ad0:	e822                	sd	s0,16(sp)
    80001ad2:	e426                	sd	s1,8(sp)
    80001ad4:	e04a                	sd	s2,0(sp)
    80001ad6:	1000                	addi	s0,sp,32
    80001ad8:	84aa                	mv	s1,a0
    80001ada:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001adc:	4681                	li	a3,0
    80001ade:	4605                	li	a2,1
    80001ae0:	040005b7          	lui	a1,0x4000
    80001ae4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ae6:	05b2                	slli	a1,a1,0xc
    80001ae8:	ed2ff0ef          	jal	800011ba <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001aec:	4681                	li	a3,0
    80001aee:	4605                	li	a2,1
    80001af0:	020005b7          	lui	a1,0x2000
    80001af4:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001af6:	05b6                	slli	a1,a1,0xd
    80001af8:	8526                	mv	a0,s1
    80001afa:	ec0ff0ef          	jal	800011ba <uvmunmap>
  uvmfree(pagetable, sz);
    80001afe:	85ca                	mv	a1,s2
    80001b00:	8526                	mv	a0,s1
    80001b02:	88dff0ef          	jal	8000138e <uvmfree>
}
    80001b06:	60e2                	ld	ra,24(sp)
    80001b08:	6442                	ld	s0,16(sp)
    80001b0a:	64a2                	ld	s1,8(sp)
    80001b0c:	6902                	ld	s2,0(sp)
    80001b0e:	6105                	addi	sp,sp,32
    80001b10:	8082                	ret

0000000080001b12 <freeproc>:
{
    80001b12:	1101                	addi	sp,sp,-32
    80001b14:	ec06                	sd	ra,24(sp)
    80001b16:	e822                	sd	s0,16(sp)
    80001b18:	e426                	sd	s1,8(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b1e:	6d28                	ld	a0,88(a0)
    80001b20:	c119                	beqz	a0,80001b26 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001b22:	efbfe0ef          	jal	80000a1c <kfree>
  p->trapframe = 0;
    80001b26:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b2a:	68a8                	ld	a0,80(s1)
    80001b2c:	c501                	beqz	a0,80001b34 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001b2e:	64ac                	ld	a1,72(s1)
    80001b30:	f9dff0ef          	jal	80001acc <proc_freepagetable>
  p->pagetable = 0;
    80001b34:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b38:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b3c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b40:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b44:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001b48:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b4c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b50:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b54:	0004ac23          	sw	zero,24(s1)
}
    80001b58:	60e2                	ld	ra,24(sp)
    80001b5a:	6442                	ld	s0,16(sp)
    80001b5c:	64a2                	ld	s1,8(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <allocproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	e04a                	sd	s2,0(sp)
    80001b6c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b6e:	00011497          	auipc	s1,0x11
    80001b72:	bfa48493          	addi	s1,s1,-1030 # 80012768 <proc>
    80001b76:	00016917          	auipc	s2,0x16
    80001b7a:	7f290913          	addi	s2,s2,2034 # 80018368 <tickslock>
    acquire(&p->lock);
    80001b7e:	8526                	mv	a0,s1
    80001b80:	84eff0ef          	jal	80000bce <acquire>
    if(p->state == UNUSED) {
    80001b84:	4c9c                	lw	a5,24(s1)
    80001b86:	cb91                	beqz	a5,80001b9a <allocproc+0x38>
      release(&p->lock);
    80001b88:	8526                	mv	a0,s1
    80001b8a:	8dcff0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b8e:	17048493          	addi	s1,s1,368
    80001b92:	ff2496e3          	bne	s1,s2,80001b7e <allocproc+0x1c>
  return 0;
    80001b96:	4481                	li	s1,0
    80001b98:	a0a9                	j	80001be2 <allocproc+0x80>
  p->pid = allocpid();
    80001b9a:	dfdff0ef          	jal	80001996 <allocpid>
    80001b9e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ba0:	4785                	li	a5,1
    80001ba2:	cc9c                	sw	a5,24(s1)
  p->tickets = 1;
    80001ba4:	14f4ac23          	sw	a5,344(s1)
  p->rounds = 0;
    80001ba8:	1404ae23          	sw	zero,348(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bac:	f53fe0ef          	jal	80000afe <kalloc>
    80001bb0:	892a                	mv	s2,a0
    80001bb2:	eca8                	sd	a0,88(s1)
    80001bb4:	cd15                	beqz	a0,80001bf0 <allocproc+0x8e>
  p->pagetable = proc_pagetable(p);
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	e91ff0ef          	jal	80001a48 <proc_pagetable>
    80001bbc:	892a                	mv	s2,a0
    80001bbe:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001bc0:	c121                	beqz	a0,80001c00 <allocproc+0x9e>
  memset(&p->context, 0, sizeof(p->context));
    80001bc2:	07000613          	li	a2,112
    80001bc6:	4581                	li	a1,0
    80001bc8:	06048513          	addi	a0,s1,96
    80001bcc:	8d6ff0ef          	jal	80000ca2 <memset>
  p->context.ra = (uint64)forkret;
    80001bd0:	00000797          	auipc	a5,0x0
    80001bd4:	d2e78793          	addi	a5,a5,-722 # 800018fe <forkret>
    80001bd8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001bda:	60bc                	ld	a5,64(s1)
    80001bdc:	6705                	lui	a4,0x1
    80001bde:	97ba                	add	a5,a5,a4
    80001be0:	f4bc                	sd	a5,104(s1)
}
    80001be2:	8526                	mv	a0,s1
    80001be4:	60e2                	ld	ra,24(sp)
    80001be6:	6442                	ld	s0,16(sp)
    80001be8:	64a2                	ld	s1,8(sp)
    80001bea:	6902                	ld	s2,0(sp)
    80001bec:	6105                	addi	sp,sp,32
    80001bee:	8082                	ret
    freeproc(p);
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	f21ff0ef          	jal	80001b12 <freeproc>
    release(&p->lock);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	86eff0ef          	jal	80000c66 <release>
    return 0;
    80001bfc:	84ca                	mv	s1,s2
    80001bfe:	b7d5                	j	80001be2 <allocproc+0x80>
    freeproc(p);
    80001c00:	8526                	mv	a0,s1
    80001c02:	f11ff0ef          	jal	80001b12 <freeproc>
    release(&p->lock);
    80001c06:	8526                	mv	a0,s1
    80001c08:	85eff0ef          	jal	80000c66 <release>
    return 0;
    80001c0c:	84ca                	mv	s1,s2
    80001c0e:	bfd1                	j	80001be2 <allocproc+0x80>

0000000080001c10 <userinit>:
{
    80001c10:	1101                	addi	sp,sp,-32
    80001c12:	ec06                	sd	ra,24(sp)
    80001c14:	e822                	sd	s0,16(sp)
    80001c16:	e426                	sd	s1,8(sp)
    80001c18:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c1a:	f49ff0ef          	jal	80001b62 <allocproc>
    80001c1e:	84aa                	mv	s1,a0
  initproc = p;
    80001c20:	00008797          	auipc	a5,0x8
    80001c24:	60a7b823          	sd	a0,1552(a5) # 8000a230 <initproc>
  p->tickets = 10;
    80001c28:	47a9                	li	a5,10
    80001c2a:	14f52c23          	sw	a5,344(a0)
  p->rounds = 0;
    80001c2e:	14052e23          	sw	zero,348(a0)
  p->cwd = namei("/");
    80001c32:	00005517          	auipc	a0,0x5
    80001c36:	55e50513          	addi	a0,a0,1374 # 80007190 <etext+0x190>
    80001c3a:	6df010ef          	jal	80003b18 <namei>
    80001c3e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001c42:	478d                	li	a5,3
    80001c44:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001c46:	8526                	mv	a0,s1
    80001c48:	81eff0ef          	jal	80000c66 <release>
}
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6105                	addi	sp,sp,32
    80001c54:	8082                	ret

0000000080001c56 <growproc>:
{
    80001c56:	1101                	addi	sp,sp,-32
    80001c58:	ec06                	sd	ra,24(sp)
    80001c5a:	e822                	sd	s0,16(sp)
    80001c5c:	e426                	sd	s1,8(sp)
    80001c5e:	e04a                	sd	s2,0(sp)
    80001c60:	1000                	addi	s0,sp,32
    80001c62:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001c64:	c6bff0ef          	jal	800018ce <myproc>
    80001c68:	892a                	mv	s2,a0
  sz = p->sz;
    80001c6a:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001c6c:	02905963          	blez	s1,80001c9e <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001c70:	00b48633          	add	a2,s1,a1
    80001c74:	020007b7          	lui	a5,0x2000
    80001c78:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001c7a:	07b6                	slli	a5,a5,0xd
    80001c7c:	02c7ea63          	bltu	a5,a2,80001cb0 <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c80:	4691                	li	a3,4
    80001c82:	6928                	ld	a0,80(a0)
    80001c84:	e04ff0ef          	jal	80001288 <uvmalloc>
    80001c88:	85aa                	mv	a1,a0
    80001c8a:	c50d                	beqz	a0,80001cb4 <growproc+0x5e>
  p->sz = sz;
    80001c8c:	04b93423          	sd	a1,72(s2)
  return 0;
    80001c90:	4501                	li	a0,0
}
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6902                	ld	s2,0(sp)
    80001c9a:	6105                	addi	sp,sp,32
    80001c9c:	8082                	ret
  } else if(n < 0){
    80001c9e:	fe04d7e3          	bgez	s1,80001c8c <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ca2:	00b48633          	add	a2,s1,a1
    80001ca6:	6928                	ld	a0,80(a0)
    80001ca8:	d9cff0ef          	jal	80001244 <uvmdealloc>
    80001cac:	85aa                	mv	a1,a0
    80001cae:	bff9                	j	80001c8c <growproc+0x36>
      return -1;
    80001cb0:	557d                	li	a0,-1
    80001cb2:	b7c5                	j	80001c92 <growproc+0x3c>
      return -1;
    80001cb4:	557d                	li	a0,-1
    80001cb6:	bff1                	j	80001c92 <growproc+0x3c>

0000000080001cb8 <kfork>:
{
    80001cb8:	7139                	addi	sp,sp,-64
    80001cba:	fc06                	sd	ra,56(sp)
    80001cbc:	f822                	sd	s0,48(sp)
    80001cbe:	f04a                	sd	s2,32(sp)
    80001cc0:	e456                	sd	s5,8(sp)
    80001cc2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001cc4:	c0bff0ef          	jal	800018ce <myproc>
    80001cc8:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001cca:	e99ff0ef          	jal	80001b62 <allocproc>
    80001cce:	10050063          	beqz	a0,80001dce <kfork+0x116>
    80001cd2:	ec4e                	sd	s3,24(sp)
    80001cd4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001cd6:	048ab603          	ld	a2,72(s5)
    80001cda:	692c                	ld	a1,80(a0)
    80001cdc:	050ab503          	ld	a0,80(s5)
    80001ce0:	ee0ff0ef          	jal	800013c0 <uvmcopy>
    80001ce4:	06054063          	bltz	a0,80001d44 <kfork+0x8c>
    80001ce8:	f426                	sd	s1,40(sp)
    80001cea:	e852                	sd	s4,16(sp)
  np->sz = p->sz;
    80001cec:	048ab783          	ld	a5,72(s5)
    80001cf0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001cf4:	058ab683          	ld	a3,88(s5)
    80001cf8:	87b6                	mv	a5,a3
    80001cfa:	0589b703          	ld	a4,88(s3)
    80001cfe:	12068693          	addi	a3,a3,288
    80001d02:	0007b803          	ld	a6,0(a5)
    80001d06:	6788                	ld	a0,8(a5)
    80001d08:	6b8c                	ld	a1,16(a5)
    80001d0a:	6f90                	ld	a2,24(a5)
    80001d0c:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001d10:	e708                	sd	a0,8(a4)
    80001d12:	eb0c                	sd	a1,16(a4)
    80001d14:	ef10                	sd	a2,24(a4)
    80001d16:	02078793          	addi	a5,a5,32
    80001d1a:	02070713          	addi	a4,a4,32
    80001d1e:	fed792e3          	bne	a5,a3,80001d02 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001d22:	0589b783          	ld	a5,88(s3)
    80001d26:	0607b823          	sd	zero,112(a5)
  np->tickets = p->tickets;
    80001d2a:	158aa783          	lw	a5,344(s5)
    80001d2e:	14f9ac23          	sw	a5,344(s3)
  np->rounds = 0;
    80001d32:	1409ae23          	sw	zero,348(s3)
  for(i = 0; i < NOFILE; i++)
    80001d36:	0d0a8493          	addi	s1,s5,208
    80001d3a:	0d098913          	addi	s2,s3,208
    80001d3e:	150a8a13          	addi	s4,s5,336
    80001d42:	a831                	j	80001d5e <kfork+0xa6>
    freeproc(np);
    80001d44:	854e                	mv	a0,s3
    80001d46:	dcdff0ef          	jal	80001b12 <freeproc>
    release(&np->lock);
    80001d4a:	854e                	mv	a0,s3
    80001d4c:	f1bfe0ef          	jal	80000c66 <release>
    return -1;
    80001d50:	597d                	li	s2,-1
    80001d52:	69e2                	ld	s3,24(sp)
    80001d54:	a0b5                	j	80001dc0 <kfork+0x108>
  for(i = 0; i < NOFILE; i++)
    80001d56:	04a1                	addi	s1,s1,8
    80001d58:	0921                	addi	s2,s2,8
    80001d5a:	01448963          	beq	s1,s4,80001d6c <kfork+0xb4>
    if(p->ofile[i])
    80001d5e:	6088                	ld	a0,0(s1)
    80001d60:	d97d                	beqz	a0,80001d56 <kfork+0x9e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001d62:	350020ef          	jal	800040b2 <filedup>
    80001d66:	00a93023          	sd	a0,0(s2)
    80001d6a:	b7f5                	j	80001d56 <kfork+0x9e>
  np->cwd = idup(p->cwd);
    80001d6c:	150ab503          	ld	a0,336(s5)
    80001d70:	55c010ef          	jal	800032cc <idup>
    80001d74:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001d78:	4641                	li	a2,16
    80001d7a:	160a8593          	addi	a1,s5,352
    80001d7e:	16098513          	addi	a0,s3,352
    80001d82:	85eff0ef          	jal	80000de0 <safestrcpy>
  pid = np->pid;
    80001d86:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001d8a:	854e                	mv	a0,s3
    80001d8c:	edbfe0ef          	jal	80000c66 <release>
  acquire(&wait_lock);
    80001d90:	00010497          	auipc	s1,0x10
    80001d94:	5c048493          	addi	s1,s1,1472 # 80012350 <wait_lock>
    80001d98:	8526                	mv	a0,s1
    80001d9a:	e35fe0ef          	jal	80000bce <acquire>
  np->parent = p;
    80001d9e:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001da2:	8526                	mv	a0,s1
    80001da4:	ec3fe0ef          	jal	80000c66 <release>
  acquire(&np->lock);
    80001da8:	854e                	mv	a0,s3
    80001daa:	e25fe0ef          	jal	80000bce <acquire>
  np->state = RUNNABLE;
    80001dae:	478d                	li	a5,3
    80001db0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001db4:	854e                	mv	a0,s3
    80001db6:	eb1fe0ef          	jal	80000c66 <release>
  return pid;
    80001dba:	74a2                	ld	s1,40(sp)
    80001dbc:	69e2                	ld	s3,24(sp)
    80001dbe:	6a42                	ld	s4,16(sp)
}
    80001dc0:	854a                	mv	a0,s2
    80001dc2:	70e2                	ld	ra,56(sp)
    80001dc4:	7442                	ld	s0,48(sp)
    80001dc6:	7902                	ld	s2,32(sp)
    80001dc8:	6aa2                	ld	s5,8(sp)
    80001dca:	6121                	addi	sp,sp,64
    80001dcc:	8082                	ret
    return -1;
    80001dce:	597d                	li	s2,-1
    80001dd0:	bfc5                	j	80001dc0 <kfork+0x108>

0000000080001dd2 <scheduler>:
{
    80001dd2:	711d                	addi	sp,sp,-96
    80001dd4:	ec86                	sd	ra,88(sp)
    80001dd6:	e8a2                	sd	s0,80(sp)
    80001dd8:	e4a6                	sd	s1,72(sp)
    80001dda:	e0ca                	sd	s2,64(sp)
    80001ddc:	fc4e                	sd	s3,56(sp)
    80001dde:	f852                	sd	s4,48(sp)
    80001de0:	f456                	sd	s5,40(sp)
    80001de2:	f05a                	sd	s6,32(sp)
    80001de4:	ec5e                	sd	s7,24(sp)
    80001de6:	e862                	sd	s8,16(sp)
    80001de8:	e466                	sd	s9,8(sp)
    80001dea:	1080                	addi	s0,sp,96
    80001dec:	8792                	mv	a5,tp
  int id = r_tp();
    80001dee:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001df0:	00779b93          	slli	s7,a5,0x7
    80001df4:	00010717          	auipc	a4,0x10
    80001df8:	54470713          	addi	a4,a4,1348 # 80012338 <pid_lock>
    80001dfc:	975e                	add	a4,a4,s7
    80001dfe:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &p->context);
    80001e02:	00010717          	auipc	a4,0x10
    80001e06:	56e70713          	addi	a4,a4,1390 # 80012370 <cpus+0x8>
    80001e0a:	9bba                	add	s7,s7,a4
    int total_tickets = 0;
    80001e0c:	4a81                	li	s5,0
      if(p->state == RUNNABLE)
    80001e0e:	490d                	li	s2,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e10:	00016997          	auipc	s3,0x16
    80001e14:	55898993          	addi	s3,s3,1368 # 80018368 <tickslock>
            p->state = RUNNING;
    80001e18:	4c11                	li	s8,4
            c->proc = p;
    80001e1a:	079e                	slli	a5,a5,0x7
    80001e1c:	00010b17          	auipc	s6,0x10
    80001e20:	51cb0b13          	addi	s6,s6,1308 # 80012338 <pid_lock>
    80001e24:	9b3e                	add	s6,s6,a5
    80001e26:	a841                	j	80001eb6 <scheduler+0xe4>
      release(&p->lock);
    80001e28:	8526                	mv	a0,s1
    80001e2a:	e3dfe0ef          	jal	80000c66 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e2e:	17048493          	addi	s1,s1,368
    80001e32:	01348d63          	beq	s1,s3,80001e4c <scheduler+0x7a>
      acquire(&p->lock);
    80001e36:	8526                	mv	a0,s1
    80001e38:	d97fe0ef          	jal	80000bce <acquire>
      if(p->state == RUNNABLE)
    80001e3c:	4c9c                	lw	a5,24(s1)
    80001e3e:	ff2795e3          	bne	a5,s2,80001e28 <scheduler+0x56>
        total_tickets += p->tickets;
    80001e42:	1584a783          	lw	a5,344(s1)
    80001e46:	01978cbb          	addw	s9,a5,s9
    80001e4a:	bff9                	j	80001e28 <scheduler+0x56>
    if(total_tickets > 0) {
    80001e4c:	07905363          	blez	s9,80001eb2 <scheduler+0xe0>
      int winning = rand() % total_tickets;
    80001e50:	bddff0ef          	jal	80001a2c <rand>
    80001e54:	03956cbb          	remw	s9,a0,s9
      int current = 0;
    80001e58:	8a56                	mv	s4,s5
      for(p = proc; p < &proc[NPROC]; p++) {
    80001e5a:	00011497          	auipc	s1,0x11
    80001e5e:	90e48493          	addi	s1,s1,-1778 # 80012768 <proc>
    80001e62:	a801                	j	80001e72 <scheduler+0xa0>
        release(&p->lock);
    80001e64:	8526                	mv	a0,s1
    80001e66:	e01fe0ef          	jal	80000c66 <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    80001e6a:	17048493          	addi	s1,s1,368
    80001e6e:	05348263          	beq	s1,s3,80001eb2 <scheduler+0xe0>
        acquire(&p->lock);
    80001e72:	8526                	mv	a0,s1
    80001e74:	d5bfe0ef          	jal	80000bce <acquire>
        if(p->state == RUNNABLE) {
    80001e78:	4c9c                	lw	a5,24(s1)
    80001e7a:	ff2795e3          	bne	a5,s2,80001e64 <scheduler+0x92>
          current += p->tickets;
    80001e7e:	1584a783          	lw	a5,344(s1)
    80001e82:	01478a3b          	addw	s4,a5,s4
          if(current > winning) {
    80001e86:	fd4cdfe3          	bge	s9,s4,80001e64 <scheduler+0x92>
            p->state = RUNNING;
    80001e8a:	0184ac23          	sw	s8,24(s1)
            c->proc = p;
    80001e8e:	029b3823          	sd	s1,48(s6)
            p->rounds += 1;
    80001e92:	15c4a783          	lw	a5,348(s1)
    80001e96:	2785                	addiw	a5,a5,1
    80001e98:	14f4ae23          	sw	a5,348(s1)
            swtch(&c->context, &p->context);
    80001e9c:	06048593          	addi	a1,s1,96
    80001ea0:	855e                	mv	a0,s7
    80001ea2:	5a6000ef          	jal	80002448 <swtch>
            c->proc = 0;
    80001ea6:	020b3823          	sd	zero,48(s6)
            release(&p->lock);
    80001eaa:	8526                	mv	a0,s1
    80001eac:	dbbfe0ef          	jal	80000c66 <release>
    if(found == 0) {
    80001eb0:	a019                	j	80001eb6 <scheduler+0xe4>
      asm volatile("wfi");
    80001eb2:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eb6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ebe:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ec2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001ec6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ec8:	10079073          	csrw	sstatus,a5
    int total_tickets = 0;
    80001ecc:	8cd6                	mv	s9,s5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ece:	00011497          	auipc	s1,0x11
    80001ed2:	89a48493          	addi	s1,s1,-1894 # 80012768 <proc>
    80001ed6:	b785                	j	80001e36 <scheduler+0x64>

0000000080001ed8 <sched>:
{
    80001ed8:	7179                	addi	sp,sp,-48
    80001eda:	f406                	sd	ra,40(sp)
    80001edc:	f022                	sd	s0,32(sp)
    80001ede:	ec26                	sd	s1,24(sp)
    80001ee0:	e84a                	sd	s2,16(sp)
    80001ee2:	e44e                	sd	s3,8(sp)
    80001ee4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ee6:	9e9ff0ef          	jal	800018ce <myproc>
    80001eea:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001eec:	c79fe0ef          	jal	80000b64 <holding>
    80001ef0:	c92d                	beqz	a0,80001f62 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ef2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ef4:	2781                	sext.w	a5,a5
    80001ef6:	079e                	slli	a5,a5,0x7
    80001ef8:	00010717          	auipc	a4,0x10
    80001efc:	44070713          	addi	a4,a4,1088 # 80012338 <pid_lock>
    80001f00:	97ba                	add	a5,a5,a4
    80001f02:	0a87a703          	lw	a4,168(a5)
    80001f06:	4785                	li	a5,1
    80001f08:	06f71363          	bne	a4,a5,80001f6e <sched+0x96>
  if(p->state == RUNNING)
    80001f0c:	4c98                	lw	a4,24(s1)
    80001f0e:	4791                	li	a5,4
    80001f10:	06f70563          	beq	a4,a5,80001f7a <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f14:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f18:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f1a:	e7b5                	bnez	a5,80001f86 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f1c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f1e:	00010917          	auipc	s2,0x10
    80001f22:	41a90913          	addi	s2,s2,1050 # 80012338 <pid_lock>
    80001f26:	2781                	sext.w	a5,a5
    80001f28:	079e                	slli	a5,a5,0x7
    80001f2a:	97ca                	add	a5,a5,s2
    80001f2c:	0ac7a983          	lw	s3,172(a5)
    80001f30:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f32:	2781                	sext.w	a5,a5
    80001f34:	079e                	slli	a5,a5,0x7
    80001f36:	00010597          	auipc	a1,0x10
    80001f3a:	43a58593          	addi	a1,a1,1082 # 80012370 <cpus+0x8>
    80001f3e:	95be                	add	a1,a1,a5
    80001f40:	06048513          	addi	a0,s1,96
    80001f44:	504000ef          	jal	80002448 <swtch>
    80001f48:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f4a:	2781                	sext.w	a5,a5
    80001f4c:	079e                	slli	a5,a5,0x7
    80001f4e:	993e                	add	s2,s2,a5
    80001f50:	0b392623          	sw	s3,172(s2)
}
    80001f54:	70a2                	ld	ra,40(sp)
    80001f56:	7402                	ld	s0,32(sp)
    80001f58:	64e2                	ld	s1,24(sp)
    80001f5a:	6942                	ld	s2,16(sp)
    80001f5c:	69a2                	ld	s3,8(sp)
    80001f5e:	6145                	addi	sp,sp,48
    80001f60:	8082                	ret
    panic("sched p->lock");
    80001f62:	00005517          	auipc	a0,0x5
    80001f66:	23650513          	addi	a0,a0,566 # 80007198 <etext+0x198>
    80001f6a:	877fe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    80001f6e:	00005517          	auipc	a0,0x5
    80001f72:	23a50513          	addi	a0,a0,570 # 800071a8 <etext+0x1a8>
    80001f76:	86bfe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    80001f7a:	00005517          	auipc	a0,0x5
    80001f7e:	23e50513          	addi	a0,a0,574 # 800071b8 <etext+0x1b8>
    80001f82:	85ffe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80001f86:	00005517          	auipc	a0,0x5
    80001f8a:	24250513          	addi	a0,a0,578 # 800071c8 <etext+0x1c8>
    80001f8e:	853fe0ef          	jal	800007e0 <panic>

0000000080001f92 <yield>:
{
    80001f92:	1101                	addi	sp,sp,-32
    80001f94:	ec06                	sd	ra,24(sp)
    80001f96:	e822                	sd	s0,16(sp)
    80001f98:	e426                	sd	s1,8(sp)
    80001f9a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f9c:	933ff0ef          	jal	800018ce <myproc>
    80001fa0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fa2:	c2dfe0ef          	jal	80000bce <acquire>
  p->state = RUNNABLE;
    80001fa6:	478d                	li	a5,3
    80001fa8:	cc9c                	sw	a5,24(s1)
  sched();
    80001faa:	f2fff0ef          	jal	80001ed8 <sched>
  release(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	cb7fe0ef          	jal	80000c66 <release>
}
    80001fb4:	60e2                	ld	ra,24(sp)
    80001fb6:	6442                	ld	s0,16(sp)
    80001fb8:	64a2                	ld	s1,8(sp)
    80001fba:	6105                	addi	sp,sp,32
    80001fbc:	8082                	ret

0000000080001fbe <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001fbe:	7179                	addi	sp,sp,-48
    80001fc0:	f406                	sd	ra,40(sp)
    80001fc2:	f022                	sd	s0,32(sp)
    80001fc4:	ec26                	sd	s1,24(sp)
    80001fc6:	e84a                	sd	s2,16(sp)
    80001fc8:	e44e                	sd	s3,8(sp)
    80001fca:	1800                	addi	s0,sp,48
    80001fcc:	89aa                	mv	s3,a0
    80001fce:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001fd0:	8ffff0ef          	jal	800018ce <myproc>
    80001fd4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001fd6:	bf9fe0ef          	jal	80000bce <acquire>
  release(lk);
    80001fda:	854a                	mv	a0,s2
    80001fdc:	c8bfe0ef          	jal	80000c66 <release>

  // Go to sleep.
  p->chan = chan;
    80001fe0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001fe4:	4789                	li	a5,2
    80001fe6:	cc9c                	sw	a5,24(s1)

  sched();
    80001fe8:	ef1ff0ef          	jal	80001ed8 <sched>

  // Tidy up.
  p->chan = 0;
    80001fec:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	c75fe0ef          	jal	80000c66 <release>
  acquire(lk);
    80001ff6:	854a                	mv	a0,s2
    80001ff8:	bd7fe0ef          	jal	80000bce <acquire>
}
    80001ffc:	70a2                	ld	ra,40(sp)
    80001ffe:	7402                	ld	s0,32(sp)
    80002000:	64e2                	ld	s1,24(sp)
    80002002:	6942                	ld	s2,16(sp)
    80002004:	69a2                	ld	s3,8(sp)
    80002006:	6145                	addi	sp,sp,48
    80002008:	8082                	ret

000000008000200a <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    8000200a:	7139                	addi	sp,sp,-64
    8000200c:	fc06                	sd	ra,56(sp)
    8000200e:	f822                	sd	s0,48(sp)
    80002010:	f426                	sd	s1,40(sp)
    80002012:	f04a                	sd	s2,32(sp)
    80002014:	ec4e                	sd	s3,24(sp)
    80002016:	e852                	sd	s4,16(sp)
    80002018:	e456                	sd	s5,8(sp)
    8000201a:	0080                	addi	s0,sp,64
    8000201c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000201e:	00010497          	auipc	s1,0x10
    80002022:	74a48493          	addi	s1,s1,1866 # 80012768 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002026:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002028:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000202a:	00016917          	auipc	s2,0x16
    8000202e:	33e90913          	addi	s2,s2,830 # 80018368 <tickslock>
    80002032:	a801                	j	80002042 <wakeup+0x38>
      }
      release(&p->lock);
    80002034:	8526                	mv	a0,s1
    80002036:	c31fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000203a:	17048493          	addi	s1,s1,368
    8000203e:	03248263          	beq	s1,s2,80002062 <wakeup+0x58>
    if(p != myproc()){
    80002042:	88dff0ef          	jal	800018ce <myproc>
    80002046:	fea48ae3          	beq	s1,a0,8000203a <wakeup+0x30>
      acquire(&p->lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	b83fe0ef          	jal	80000bce <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002050:	4c9c                	lw	a5,24(s1)
    80002052:	ff3791e3          	bne	a5,s3,80002034 <wakeup+0x2a>
    80002056:	709c                	ld	a5,32(s1)
    80002058:	fd479ee3          	bne	a5,s4,80002034 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000205c:	0154ac23          	sw	s5,24(s1)
    80002060:	bfd1                	j	80002034 <wakeup+0x2a>
    }
  }
}
    80002062:	70e2                	ld	ra,56(sp)
    80002064:	7442                	ld	s0,48(sp)
    80002066:	74a2                	ld	s1,40(sp)
    80002068:	7902                	ld	s2,32(sp)
    8000206a:	69e2                	ld	s3,24(sp)
    8000206c:	6a42                	ld	s4,16(sp)
    8000206e:	6aa2                	ld	s5,8(sp)
    80002070:	6121                	addi	sp,sp,64
    80002072:	8082                	ret

0000000080002074 <reparent>:
{
    80002074:	7179                	addi	sp,sp,-48
    80002076:	f406                	sd	ra,40(sp)
    80002078:	f022                	sd	s0,32(sp)
    8000207a:	ec26                	sd	s1,24(sp)
    8000207c:	e84a                	sd	s2,16(sp)
    8000207e:	e44e                	sd	s3,8(sp)
    80002080:	e052                	sd	s4,0(sp)
    80002082:	1800                	addi	s0,sp,48
    80002084:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002086:	00010497          	auipc	s1,0x10
    8000208a:	6e248493          	addi	s1,s1,1762 # 80012768 <proc>
      pp->parent = initproc;
    8000208e:	00008a17          	auipc	s4,0x8
    80002092:	1a2a0a13          	addi	s4,s4,418 # 8000a230 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002096:	00016997          	auipc	s3,0x16
    8000209a:	2d298993          	addi	s3,s3,722 # 80018368 <tickslock>
    8000209e:	a029                	j	800020a8 <reparent+0x34>
    800020a0:	17048493          	addi	s1,s1,368
    800020a4:	01348b63          	beq	s1,s3,800020ba <reparent+0x46>
    if(pp->parent == p){
    800020a8:	7c9c                	ld	a5,56(s1)
    800020aa:	ff279be3          	bne	a5,s2,800020a0 <reparent+0x2c>
      pp->parent = initproc;
    800020ae:	000a3503          	ld	a0,0(s4)
    800020b2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800020b4:	f57ff0ef          	jal	8000200a <wakeup>
    800020b8:	b7e5                	j	800020a0 <reparent+0x2c>
}
    800020ba:	70a2                	ld	ra,40(sp)
    800020bc:	7402                	ld	s0,32(sp)
    800020be:	64e2                	ld	s1,24(sp)
    800020c0:	6942                	ld	s2,16(sp)
    800020c2:	69a2                	ld	s3,8(sp)
    800020c4:	6a02                	ld	s4,0(sp)
    800020c6:	6145                	addi	sp,sp,48
    800020c8:	8082                	ret

00000000800020ca <kexit>:
{
    800020ca:	7179                	addi	sp,sp,-48
    800020cc:	f406                	sd	ra,40(sp)
    800020ce:	f022                	sd	s0,32(sp)
    800020d0:	ec26                	sd	s1,24(sp)
    800020d2:	e84a                	sd	s2,16(sp)
    800020d4:	e44e                	sd	s3,8(sp)
    800020d6:	e052                	sd	s4,0(sp)
    800020d8:	1800                	addi	s0,sp,48
    800020da:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020dc:	ff2ff0ef          	jal	800018ce <myproc>
    800020e0:	89aa                	mv	s3,a0
  if(p == initproc)
    800020e2:	00008797          	auipc	a5,0x8
    800020e6:	14e7b783          	ld	a5,334(a5) # 8000a230 <initproc>
    800020ea:	0d050493          	addi	s1,a0,208
    800020ee:	15050913          	addi	s2,a0,336
    800020f2:	00a79f63          	bne	a5,a0,80002110 <kexit+0x46>
    panic("init exiting");
    800020f6:	00005517          	auipc	a0,0x5
    800020fa:	0ea50513          	addi	a0,a0,234 # 800071e0 <etext+0x1e0>
    800020fe:	ee2fe0ef          	jal	800007e0 <panic>
      fileclose(f);
    80002102:	7f7010ef          	jal	800040f8 <fileclose>
      p->ofile[fd] = 0;
    80002106:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000210a:	04a1                	addi	s1,s1,8
    8000210c:	01248563          	beq	s1,s2,80002116 <kexit+0x4c>
    if(p->ofile[fd]){
    80002110:	6088                	ld	a0,0(s1)
    80002112:	f965                	bnez	a0,80002102 <kexit+0x38>
    80002114:	bfdd                	j	8000210a <kexit+0x40>
  begin_op();
    80002116:	3d7010ef          	jal	80003cec <begin_op>
  iput(p->cwd);
    8000211a:	1509b503          	ld	a0,336(s3)
    8000211e:	366010ef          	jal	80003484 <iput>
  end_op();
    80002122:	435010ef          	jal	80003d56 <end_op>
  p->cwd = 0;
    80002126:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000212a:	00010497          	auipc	s1,0x10
    8000212e:	22648493          	addi	s1,s1,550 # 80012350 <wait_lock>
    80002132:	8526                	mv	a0,s1
    80002134:	a9bfe0ef          	jal	80000bce <acquire>
  reparent(p);
    80002138:	854e                	mv	a0,s3
    8000213a:	f3bff0ef          	jal	80002074 <reparent>
  wakeup(p->parent);
    8000213e:	0389b503          	ld	a0,56(s3)
    80002142:	ec9ff0ef          	jal	8000200a <wakeup>
  acquire(&p->lock);
    80002146:	854e                	mv	a0,s3
    80002148:	a87fe0ef          	jal	80000bce <acquire>
  p->xstate = status;
    8000214c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002150:	4795                	li	a5,5
    80002152:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002156:	8526                	mv	a0,s1
    80002158:	b0ffe0ef          	jal	80000c66 <release>
  sched();
    8000215c:	d7dff0ef          	jal	80001ed8 <sched>
  panic("zombie exit");
    80002160:	00005517          	auipc	a0,0x5
    80002164:	09050513          	addi	a0,a0,144 # 800071f0 <etext+0x1f0>
    80002168:	e78fe0ef          	jal	800007e0 <panic>

000000008000216c <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    8000216c:	7179                	addi	sp,sp,-48
    8000216e:	f406                	sd	ra,40(sp)
    80002170:	f022                	sd	s0,32(sp)
    80002172:	ec26                	sd	s1,24(sp)
    80002174:	e84a                	sd	s2,16(sp)
    80002176:	e44e                	sd	s3,8(sp)
    80002178:	1800                	addi	s0,sp,48
    8000217a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000217c:	00010497          	auipc	s1,0x10
    80002180:	5ec48493          	addi	s1,s1,1516 # 80012768 <proc>
    80002184:	00016997          	auipc	s3,0x16
    80002188:	1e498993          	addi	s3,s3,484 # 80018368 <tickslock>
    acquire(&p->lock);
    8000218c:	8526                	mv	a0,s1
    8000218e:	a41fe0ef          	jal	80000bce <acquire>
    if(p->pid == pid){
    80002192:	589c                	lw	a5,48(s1)
    80002194:	01278b63          	beq	a5,s2,800021aa <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	acdfe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000219e:	17048493          	addi	s1,s1,368
    800021a2:	ff3495e3          	bne	s1,s3,8000218c <kkill+0x20>
  }
  return -1;
    800021a6:	557d                	li	a0,-1
    800021a8:	a819                	j	800021be <kkill+0x52>
      p->killed = 1;
    800021aa:	4785                	li	a5,1
    800021ac:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800021ae:	4c98                	lw	a4,24(s1)
    800021b0:	4789                	li	a5,2
    800021b2:	00f70d63          	beq	a4,a5,800021cc <kkill+0x60>
      release(&p->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	aaffe0ef          	jal	80000c66 <release>
      return 0;
    800021bc:	4501                	li	a0,0
}
    800021be:	70a2                	ld	ra,40(sp)
    800021c0:	7402                	ld	s0,32(sp)
    800021c2:	64e2                	ld	s1,24(sp)
    800021c4:	6942                	ld	s2,16(sp)
    800021c6:	69a2                	ld	s3,8(sp)
    800021c8:	6145                	addi	sp,sp,48
    800021ca:	8082                	ret
        p->state = RUNNABLE;
    800021cc:	478d                	li	a5,3
    800021ce:	cc9c                	sw	a5,24(s1)
    800021d0:	b7dd                	j	800021b6 <kkill+0x4a>

00000000800021d2 <setkilled>:

void
setkilled(struct proc *p)
{
    800021d2:	1101                	addi	sp,sp,-32
    800021d4:	ec06                	sd	ra,24(sp)
    800021d6:	e822                	sd	s0,16(sp)
    800021d8:	e426                	sd	s1,8(sp)
    800021da:	1000                	addi	s0,sp,32
    800021dc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021de:	9f1fe0ef          	jal	80000bce <acquire>
  p->killed = 1;
    800021e2:	4785                	li	a5,1
    800021e4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	a7ffe0ef          	jal	80000c66 <release>
}
    800021ec:	60e2                	ld	ra,24(sp)
    800021ee:	6442                	ld	s0,16(sp)
    800021f0:	64a2                	ld	s1,8(sp)
    800021f2:	6105                	addi	sp,sp,32
    800021f4:	8082                	ret

00000000800021f6 <killed>:

int
killed(struct proc *p)
{
    800021f6:	1101                	addi	sp,sp,-32
    800021f8:	ec06                	sd	ra,24(sp)
    800021fa:	e822                	sd	s0,16(sp)
    800021fc:	e426                	sd	s1,8(sp)
    800021fe:	e04a                	sd	s2,0(sp)
    80002200:	1000                	addi	s0,sp,32
    80002202:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002204:	9cbfe0ef          	jal	80000bce <acquire>
  k = p->killed;
    80002208:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	a59fe0ef          	jal	80000c66 <release>
  return k;
}
    80002212:	854a                	mv	a0,s2
    80002214:	60e2                	ld	ra,24(sp)
    80002216:	6442                	ld	s0,16(sp)
    80002218:	64a2                	ld	s1,8(sp)
    8000221a:	6902                	ld	s2,0(sp)
    8000221c:	6105                	addi	sp,sp,32
    8000221e:	8082                	ret

0000000080002220 <kwait>:
{
    80002220:	715d                	addi	sp,sp,-80
    80002222:	e486                	sd	ra,72(sp)
    80002224:	e0a2                	sd	s0,64(sp)
    80002226:	fc26                	sd	s1,56(sp)
    80002228:	f84a                	sd	s2,48(sp)
    8000222a:	f44e                	sd	s3,40(sp)
    8000222c:	f052                	sd	s4,32(sp)
    8000222e:	ec56                	sd	s5,24(sp)
    80002230:	e85a                	sd	s6,16(sp)
    80002232:	e45e                	sd	s7,8(sp)
    80002234:	e062                	sd	s8,0(sp)
    80002236:	0880                	addi	s0,sp,80
    80002238:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000223a:	e94ff0ef          	jal	800018ce <myproc>
    8000223e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002240:	00010517          	auipc	a0,0x10
    80002244:	11050513          	addi	a0,a0,272 # 80012350 <wait_lock>
    80002248:	987fe0ef          	jal	80000bce <acquire>
    havekids = 0;
    8000224c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000224e:	4a15                	li	s4,5
        havekids = 1;
    80002250:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002252:	00016997          	auipc	s3,0x16
    80002256:	11698993          	addi	s3,s3,278 # 80018368 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000225a:	00010c17          	auipc	s8,0x10
    8000225e:	0f6c0c13          	addi	s8,s8,246 # 80012350 <wait_lock>
    80002262:	a871                	j	800022fe <kwait+0xde>
          pid = pp->pid;
    80002264:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002268:	000b0c63          	beqz	s6,80002280 <kwait+0x60>
    8000226c:	4691                	li	a3,4
    8000226e:	02c48613          	addi	a2,s1,44
    80002272:	85da                	mv	a1,s6
    80002274:	05093503          	ld	a0,80(s2)
    80002278:	b6aff0ef          	jal	800015e2 <copyout>
    8000227c:	02054b63          	bltz	a0,800022b2 <kwait+0x92>
          freeproc(pp);
    80002280:	8526                	mv	a0,s1
    80002282:	891ff0ef          	jal	80001b12 <freeproc>
          release(&pp->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	9dffe0ef          	jal	80000c66 <release>
          release(&wait_lock);
    8000228c:	00010517          	auipc	a0,0x10
    80002290:	0c450513          	addi	a0,a0,196 # 80012350 <wait_lock>
    80002294:	9d3fe0ef          	jal	80000c66 <release>
}
    80002298:	854e                	mv	a0,s3
    8000229a:	60a6                	ld	ra,72(sp)
    8000229c:	6406                	ld	s0,64(sp)
    8000229e:	74e2                	ld	s1,56(sp)
    800022a0:	7942                	ld	s2,48(sp)
    800022a2:	79a2                	ld	s3,40(sp)
    800022a4:	7a02                	ld	s4,32(sp)
    800022a6:	6ae2                	ld	s5,24(sp)
    800022a8:	6b42                	ld	s6,16(sp)
    800022aa:	6ba2                	ld	s7,8(sp)
    800022ac:	6c02                	ld	s8,0(sp)
    800022ae:	6161                	addi	sp,sp,80
    800022b0:	8082                	ret
            release(&pp->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	9b3fe0ef          	jal	80000c66 <release>
            release(&wait_lock);
    800022b8:	00010517          	auipc	a0,0x10
    800022bc:	09850513          	addi	a0,a0,152 # 80012350 <wait_lock>
    800022c0:	9a7fe0ef          	jal	80000c66 <release>
            return -1;
    800022c4:	59fd                	li	s3,-1
    800022c6:	bfc9                	j	80002298 <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c8:	17048493          	addi	s1,s1,368
    800022cc:	03348063          	beq	s1,s3,800022ec <kwait+0xcc>
      if(pp->parent == p){
    800022d0:	7c9c                	ld	a5,56(s1)
    800022d2:	ff279be3          	bne	a5,s2,800022c8 <kwait+0xa8>
        acquire(&pp->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	8f7fe0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    800022dc:	4c9c                	lw	a5,24(s1)
    800022de:	f94783e3          	beq	a5,s4,80002264 <kwait+0x44>
        release(&pp->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	983fe0ef          	jal	80000c66 <release>
        havekids = 1;
    800022e8:	8756                	mv	a4,s5
    800022ea:	bff9                	j	800022c8 <kwait+0xa8>
    if(!havekids || killed(p)){
    800022ec:	cf19                	beqz	a4,8000230a <kwait+0xea>
    800022ee:	854a                	mv	a0,s2
    800022f0:	f07ff0ef          	jal	800021f6 <killed>
    800022f4:	e919                	bnez	a0,8000230a <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022f6:	85e2                	mv	a1,s8
    800022f8:	854a                	mv	a0,s2
    800022fa:	cc5ff0ef          	jal	80001fbe <sleep>
    havekids = 0;
    800022fe:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002300:	00010497          	auipc	s1,0x10
    80002304:	46848493          	addi	s1,s1,1128 # 80012768 <proc>
    80002308:	b7e1                	j	800022d0 <kwait+0xb0>
      release(&wait_lock);
    8000230a:	00010517          	auipc	a0,0x10
    8000230e:	04650513          	addi	a0,a0,70 # 80012350 <wait_lock>
    80002312:	955fe0ef          	jal	80000c66 <release>
      return -1;
    80002316:	59fd                	li	s3,-1
    80002318:	b741                	j	80002298 <kwait+0x78>

000000008000231a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000231a:	7179                	addi	sp,sp,-48
    8000231c:	f406                	sd	ra,40(sp)
    8000231e:	f022                	sd	s0,32(sp)
    80002320:	ec26                	sd	s1,24(sp)
    80002322:	e84a                	sd	s2,16(sp)
    80002324:	e44e                	sd	s3,8(sp)
    80002326:	e052                	sd	s4,0(sp)
    80002328:	1800                	addi	s0,sp,48
    8000232a:	84aa                	mv	s1,a0
    8000232c:	892e                	mv	s2,a1
    8000232e:	89b2                	mv	s3,a2
    80002330:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002332:	d9cff0ef          	jal	800018ce <myproc>
  if(user_dst){
    80002336:	cc99                	beqz	s1,80002354 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002338:	86d2                	mv	a3,s4
    8000233a:	864e                	mv	a2,s3
    8000233c:	85ca                	mv	a1,s2
    8000233e:	6928                	ld	a0,80(a0)
    80002340:	aa2ff0ef          	jal	800015e2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002344:	70a2                	ld	ra,40(sp)
    80002346:	7402                	ld	s0,32(sp)
    80002348:	64e2                	ld	s1,24(sp)
    8000234a:	6942                	ld	s2,16(sp)
    8000234c:	69a2                	ld	s3,8(sp)
    8000234e:	6a02                	ld	s4,0(sp)
    80002350:	6145                	addi	sp,sp,48
    80002352:	8082                	ret
    memmove((char *)dst, src, len);
    80002354:	000a061b          	sext.w	a2,s4
    80002358:	85ce                	mv	a1,s3
    8000235a:	854a                	mv	a0,s2
    8000235c:	9a3fe0ef          	jal	80000cfe <memmove>
    return 0;
    80002360:	8526                	mv	a0,s1
    80002362:	b7cd                	j	80002344 <either_copyout+0x2a>

0000000080002364 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002364:	7179                	addi	sp,sp,-48
    80002366:	f406                	sd	ra,40(sp)
    80002368:	f022                	sd	s0,32(sp)
    8000236a:	ec26                	sd	s1,24(sp)
    8000236c:	e84a                	sd	s2,16(sp)
    8000236e:	e44e                	sd	s3,8(sp)
    80002370:	e052                	sd	s4,0(sp)
    80002372:	1800                	addi	s0,sp,48
    80002374:	892a                	mv	s2,a0
    80002376:	84ae                	mv	s1,a1
    80002378:	89b2                	mv	s3,a2
    8000237a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000237c:	d52ff0ef          	jal	800018ce <myproc>
  if(user_src){
    80002380:	cc99                	beqz	s1,8000239e <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80002382:	86d2                	mv	a3,s4
    80002384:	864e                	mv	a2,s3
    80002386:	85ca                	mv	a1,s2
    80002388:	6928                	ld	a0,80(a0)
    8000238a:	b3cff0ef          	jal	800016c6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000238e:	70a2                	ld	ra,40(sp)
    80002390:	7402                	ld	s0,32(sp)
    80002392:	64e2                	ld	s1,24(sp)
    80002394:	6942                	ld	s2,16(sp)
    80002396:	69a2                	ld	s3,8(sp)
    80002398:	6a02                	ld	s4,0(sp)
    8000239a:	6145                	addi	sp,sp,48
    8000239c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000239e:	000a061b          	sext.w	a2,s4
    800023a2:	85ce                	mv	a1,s3
    800023a4:	854a                	mv	a0,s2
    800023a6:	959fe0ef          	jal	80000cfe <memmove>
    return 0;
    800023aa:	8526                	mv	a0,s1
    800023ac:	b7cd                	j	8000238e <either_copyin+0x2a>

00000000800023ae <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800023ae:	7139                	addi	sp,sp,-64
    800023b0:	fc06                	sd	ra,56(sp)
    800023b2:	f822                	sd	s0,48(sp)
    800023b4:	f426                	sd	s1,40(sp)
    800023b6:	f04a                	sd	s2,32(sp)
    800023b8:	ec4e                	sd	s3,24(sp)
    800023ba:	e852                	sd	s4,16(sp)
    800023bc:	e456                	sd	s5,8(sp)
    800023be:	e05a                	sd	s6,0(sp)
    800023c0:	0080                	addi	s0,sp,64
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800023c2:	00005517          	auipc	a0,0x5
    800023c6:	cb650513          	addi	a0,a0,-842 # 80007078 <etext+0x78>
    800023ca:	930fe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800023ce:	00010497          	auipc	s1,0x10
    800023d2:	4fa48493          	addi	s1,s1,1274 # 800128c8 <proc+0x160>
    800023d6:	00016917          	auipc	s2,0x16
    800023da:	0f290913          	addi	s2,s2,242 # 800184c8 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023de:	4a95                	li	s5,5
      state = states[p->state];
    else
      state = "???";
    800023e0:	00005997          	auipc	s3,0x5
    800023e4:	e2098993          	addi	s3,s3,-480 # 80007200 <etext+0x200>
    printf("%d %s %s %d %d\n", p->pid, state, p->name, p->tickets, p->rounds);
    800023e8:	00005a17          	auipc	s4,0x5
    800023ec:	e20a0a13          	addi	s4,s4,-480 # 80007208 <etext+0x208>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023f0:	00005b17          	auipc	s6,0x5
    800023f4:	338b0b13          	addi	s6,s6,824 # 80007728 <states.0>
    800023f8:	a831                	j	80002414 <procdump+0x66>
    printf("%d %s %s %d %d\n", p->pid, state, p->name, p->tickets, p->rounds);
    800023fa:	ffc6a783          	lw	a5,-4(a3)
    800023fe:	ff86a703          	lw	a4,-8(a3)
    80002402:	ed06a583          	lw	a1,-304(a3)
    80002406:	8552                	mv	a0,s4
    80002408:	8f2fe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000240c:	17048493          	addi	s1,s1,368
    80002410:	03248263          	beq	s1,s2,80002434 <procdump+0x86>
    if(p->state == UNUSED)
    80002414:	86a6                	mv	a3,s1
    80002416:	eb84a783          	lw	a5,-328(s1)
    8000241a:	dbed                	beqz	a5,8000240c <procdump+0x5e>
      state = "???";
    8000241c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000241e:	fcfaeee3          	bltu	s5,a5,800023fa <procdump+0x4c>
    80002422:	02079713          	slli	a4,a5,0x20
    80002426:	01d75793          	srli	a5,a4,0x1d
    8000242a:	97da                	add	a5,a5,s6
    8000242c:	6390                	ld	a2,0(a5)
    8000242e:	f671                	bnez	a2,800023fa <procdump+0x4c>
      state = "???";
    80002430:	864e                	mv	a2,s3
    80002432:	b7e1                	j	800023fa <procdump+0x4c>
  }
}
    80002434:	70e2                	ld	ra,56(sp)
    80002436:	7442                	ld	s0,48(sp)
    80002438:	74a2                	ld	s1,40(sp)
    8000243a:	7902                	ld	s2,32(sp)
    8000243c:	69e2                	ld	s3,24(sp)
    8000243e:	6a42                	ld	s4,16(sp)
    80002440:	6aa2                	ld	s5,8(sp)
    80002442:	6b02                	ld	s6,0(sp)
    80002444:	6121                	addi	sp,sp,64
    80002446:	8082                	ret

0000000080002448 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    80002448:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    8000244c:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    80002450:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    80002452:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002454:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    80002458:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    8000245c:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    80002460:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002464:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    80002468:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    8000246c:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    80002470:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002474:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80002478:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    8000247c:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    80002480:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002484:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002486:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    80002488:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    8000248c:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    80002490:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002494:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    80002498:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    8000249c:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    800024a0:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    800024a4:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    800024a8:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    800024ac:	0685bd83          	ld	s11,104(a1)
        
        ret
    800024b0:	8082                	ret

00000000800024b2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800024b2:	1141                	addi	sp,sp,-16
    800024b4:	e406                	sd	ra,8(sp)
    800024b6:	e022                	sd	s0,0(sp)
    800024b8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800024ba:	00005597          	auipc	a1,0x5
    800024be:	d8e58593          	addi	a1,a1,-626 # 80007248 <etext+0x248>
    800024c2:	00016517          	auipc	a0,0x16
    800024c6:	ea650513          	addi	a0,a0,-346 # 80018368 <tickslock>
    800024ca:	e84fe0ef          	jal	80000b4e <initlock>
}
    800024ce:	60a2                	ld	ra,8(sp)
    800024d0:	6402                	ld	s0,0(sp)
    800024d2:	0141                	addi	sp,sp,16
    800024d4:	8082                	ret

00000000800024d6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800024d6:	1141                	addi	sp,sp,-16
    800024d8:	e422                	sd	s0,8(sp)
    800024da:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800024dc:	00003797          	auipc	a5,0x3
    800024e0:	f9478793          	addi	a5,a5,-108 # 80005470 <kernelvec>
    800024e4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800024e8:	6422                	ld	s0,8(sp)
    800024ea:	0141                	addi	sp,sp,16
    800024ec:	8082                	ret

00000000800024ee <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800024ee:	1141                	addi	sp,sp,-16
    800024f0:	e406                	sd	ra,8(sp)
    800024f2:	e022                	sd	s0,0(sp)
    800024f4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800024f6:	bd8ff0ef          	jal	800018ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024fa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800024fe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002500:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002504:	04000737          	lui	a4,0x4000
    80002508:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    8000250a:	0732                	slli	a4,a4,0xc
    8000250c:	00004797          	auipc	a5,0x4
    80002510:	af478793          	addi	a5,a5,-1292 # 80006000 <_trampoline>
    80002514:	00004697          	auipc	a3,0x4
    80002518:	aec68693          	addi	a3,a3,-1300 # 80006000 <_trampoline>
    8000251c:	8f95                	sub	a5,a5,a3
    8000251e:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002520:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002524:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002526:	18002773          	csrr	a4,satp
    8000252a:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000252c:	6d38                	ld	a4,88(a0)
    8000252e:	613c                	ld	a5,64(a0)
    80002530:	6685                	lui	a3,0x1
    80002532:	97b6                	add	a5,a5,a3
    80002534:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002536:	6d3c                	ld	a5,88(a0)
    80002538:	00000717          	auipc	a4,0x0
    8000253c:	0f870713          	addi	a4,a4,248 # 80002630 <usertrap>
    80002540:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002542:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002544:	8712                	mv	a4,tp
    80002546:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002548:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000254c:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002550:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002554:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002558:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000255a:	6f9c                	ld	a5,24(a5)
    8000255c:	14179073          	csrw	sepc,a5
}
    80002560:	60a2                	ld	ra,8(sp)
    80002562:	6402                	ld	s0,0(sp)
    80002564:	0141                	addi	sp,sp,16
    80002566:	8082                	ret

0000000080002568 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002568:	1101                	addi	sp,sp,-32
    8000256a:	ec06                	sd	ra,24(sp)
    8000256c:	e822                	sd	s0,16(sp)
    8000256e:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    80002570:	b32ff0ef          	jal	800018a2 <cpuid>
    80002574:	cd11                	beqz	a0,80002590 <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002576:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    8000257a:	000f4737          	lui	a4,0xf4
    8000257e:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002582:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002584:	14d79073          	csrw	stimecmp,a5
}
    80002588:	60e2                	ld	ra,24(sp)
    8000258a:	6442                	ld	s0,16(sp)
    8000258c:	6105                	addi	sp,sp,32
    8000258e:	8082                	ret
    80002590:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    80002592:	00016497          	auipc	s1,0x16
    80002596:	dd648493          	addi	s1,s1,-554 # 80018368 <tickslock>
    8000259a:	8526                	mv	a0,s1
    8000259c:	e32fe0ef          	jal	80000bce <acquire>
    ticks++;
    800025a0:	00008517          	auipc	a0,0x8
    800025a4:	c9850513          	addi	a0,a0,-872 # 8000a238 <ticks>
    800025a8:	411c                	lw	a5,0(a0)
    800025aa:	2785                	addiw	a5,a5,1
    800025ac:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800025ae:	a5dff0ef          	jal	8000200a <wakeup>
    release(&tickslock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	eb2fe0ef          	jal	80000c66 <release>
    800025b8:	64a2                	ld	s1,8(sp)
    800025ba:	bf75                	j	80002576 <clockintr+0xe>

00000000800025bc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800025bc:	1101                	addi	sp,sp,-32
    800025be:	ec06                	sd	ra,24(sp)
    800025c0:	e822                	sd	s0,16(sp)
    800025c2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025c4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800025c8:	57fd                	li	a5,-1
    800025ca:	17fe                	slli	a5,a5,0x3f
    800025cc:	07a5                	addi	a5,a5,9
    800025ce:	00f70c63          	beq	a4,a5,800025e6 <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800025d2:	57fd                	li	a5,-1
    800025d4:	17fe                	slli	a5,a5,0x3f
    800025d6:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800025d8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800025da:	04f70763          	beq	a4,a5,80002628 <devintr+0x6c>
  }
}
    800025de:	60e2                	ld	ra,24(sp)
    800025e0:	6442                	ld	s0,16(sp)
    800025e2:	6105                	addi	sp,sp,32
    800025e4:	8082                	ret
    800025e6:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    800025e8:	735020ef          	jal	8000551c <plic_claim>
    800025ec:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800025ee:	47a9                	li	a5,10
    800025f0:	00f50963          	beq	a0,a5,80002602 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    800025f4:	4785                	li	a5,1
    800025f6:	00f50963          	beq	a0,a5,80002608 <devintr+0x4c>
    return 1;
    800025fa:	4505                	li	a0,1
    } else if(irq){
    800025fc:	e889                	bnez	s1,8000260e <devintr+0x52>
    800025fe:	64a2                	ld	s1,8(sp)
    80002600:	bff9                	j	800025de <devintr+0x22>
      uartintr();
    80002602:	baefe0ef          	jal	800009b0 <uartintr>
    if(irq)
    80002606:	a819                	j	8000261c <devintr+0x60>
      virtio_disk_intr();
    80002608:	3da030ef          	jal	800059e2 <virtio_disk_intr>
    if(irq)
    8000260c:	a801                	j	8000261c <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    8000260e:	85a6                	mv	a1,s1
    80002610:	00005517          	auipc	a0,0x5
    80002614:	c4050513          	addi	a0,a0,-960 # 80007250 <etext+0x250>
    80002618:	ee3fd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    8000261c:	8526                	mv	a0,s1
    8000261e:	71f020ef          	jal	8000553c <plic_complete>
    return 1;
    80002622:	4505                	li	a0,1
    80002624:	64a2                	ld	s1,8(sp)
    80002626:	bf65                	j	800025de <devintr+0x22>
    clockintr();
    80002628:	f41ff0ef          	jal	80002568 <clockintr>
    return 2;
    8000262c:	4509                	li	a0,2
    8000262e:	bf45                	j	800025de <devintr+0x22>

0000000080002630 <usertrap>:
{
    80002630:	1101                	addi	sp,sp,-32
    80002632:	ec06                	sd	ra,24(sp)
    80002634:	e822                	sd	s0,16(sp)
    80002636:	e426                	sd	s1,8(sp)
    80002638:	e04a                	sd	s2,0(sp)
    8000263a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000263c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002640:	1007f793          	andi	a5,a5,256
    80002644:	eba5                	bnez	a5,800026b4 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002646:	00003797          	auipc	a5,0x3
    8000264a:	e2a78793          	addi	a5,a5,-470 # 80005470 <kernelvec>
    8000264e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002652:	a7cff0ef          	jal	800018ce <myproc>
    80002656:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002658:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000265a:	14102773          	csrr	a4,sepc
    8000265e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002660:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002664:	47a1                	li	a5,8
    80002666:	04f70d63          	beq	a4,a5,800026c0 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    8000266a:	f53ff0ef          	jal	800025bc <devintr>
    8000266e:	892a                	mv	s2,a0
    80002670:	e945                	bnez	a0,80002720 <usertrap+0xf0>
    80002672:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002676:	47bd                	li	a5,15
    80002678:	08f70863          	beq	a4,a5,80002708 <usertrap+0xd8>
    8000267c:	14202773          	csrr	a4,scause
    80002680:	47b5                	li	a5,13
    80002682:	08f70363          	beq	a4,a5,80002708 <usertrap+0xd8>
    80002686:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    8000268a:	5890                	lw	a2,48(s1)
    8000268c:	00005517          	auipc	a0,0x5
    80002690:	c0450513          	addi	a0,a0,-1020 # 80007290 <etext+0x290>
    80002694:	e67fd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002698:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000269c:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    800026a0:	00005517          	auipc	a0,0x5
    800026a4:	c2050513          	addi	a0,a0,-992 # 800072c0 <etext+0x2c0>
    800026a8:	e53fd0ef          	jal	800004fa <printf>
    setkilled(p);
    800026ac:	8526                	mv	a0,s1
    800026ae:	b25ff0ef          	jal	800021d2 <setkilled>
    800026b2:	a035                	j	800026de <usertrap+0xae>
    panic("usertrap: not from user mode");
    800026b4:	00005517          	auipc	a0,0x5
    800026b8:	bbc50513          	addi	a0,a0,-1092 # 80007270 <etext+0x270>
    800026bc:	924fe0ef          	jal	800007e0 <panic>
    if(killed(p))
    800026c0:	b37ff0ef          	jal	800021f6 <killed>
    800026c4:	ed15                	bnez	a0,80002700 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800026c6:	6cb8                	ld	a4,88(s1)
    800026c8:	6f1c                	ld	a5,24(a4)
    800026ca:	0791                	addi	a5,a5,4
    800026cc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800026d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026d6:	10079073          	csrw	sstatus,a5
    syscall();
    800026da:	246000ef          	jal	80002920 <syscall>
  if(killed(p))
    800026de:	8526                	mv	a0,s1
    800026e0:	b17ff0ef          	jal	800021f6 <killed>
    800026e4:	e139                	bnez	a0,8000272a <usertrap+0xfa>
  prepare_return();
    800026e6:	e09ff0ef          	jal	800024ee <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800026ea:	68a8                	ld	a0,80(s1)
    800026ec:	8131                	srli	a0,a0,0xc
    800026ee:	57fd                	li	a5,-1
    800026f0:	17fe                	slli	a5,a5,0x3f
    800026f2:	8d5d                	or	a0,a0,a5
}
    800026f4:	60e2                	ld	ra,24(sp)
    800026f6:	6442                	ld	s0,16(sp)
    800026f8:	64a2                	ld	s1,8(sp)
    800026fa:	6902                	ld	s2,0(sp)
    800026fc:	6105                	addi	sp,sp,32
    800026fe:	8082                	ret
      kexit(-1);
    80002700:	557d                	li	a0,-1
    80002702:	9c9ff0ef          	jal	800020ca <kexit>
    80002706:	b7c1                	j	800026c6 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002708:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000270c:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002710:	164d                	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    80002712:	00163613          	seqz	a2,a2
    80002716:	68a8                	ld	a0,80(s1)
    80002718:	e49fe0ef          	jal	80001560 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    8000271c:	f169                	bnez	a0,800026de <usertrap+0xae>
    8000271e:	b7a5                	j	80002686 <usertrap+0x56>
  if(killed(p))
    80002720:	8526                	mv	a0,s1
    80002722:	ad5ff0ef          	jal	800021f6 <killed>
    80002726:	c511                	beqz	a0,80002732 <usertrap+0x102>
    80002728:	a011                	j	8000272c <usertrap+0xfc>
    8000272a:	4901                	li	s2,0
    kexit(-1);
    8000272c:	557d                	li	a0,-1
    8000272e:	99dff0ef          	jal	800020ca <kexit>
  if(which_dev == 2)
    80002732:	4789                	li	a5,2
    80002734:	faf919e3          	bne	s2,a5,800026e6 <usertrap+0xb6>
    yield();
    80002738:	85bff0ef          	jal	80001f92 <yield>
    8000273c:	b76d                	j	800026e6 <usertrap+0xb6>

000000008000273e <kerneltrap>:
{
    8000273e:	7179                	addi	sp,sp,-48
    80002740:	f406                	sd	ra,40(sp)
    80002742:	f022                	sd	s0,32(sp)
    80002744:	ec26                	sd	s1,24(sp)
    80002746:	e84a                	sd	s2,16(sp)
    80002748:	e44e                	sd	s3,8(sp)
    8000274a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000274c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002750:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002754:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002758:	1004f793          	andi	a5,s1,256
    8000275c:	c795                	beqz	a5,80002788 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000275e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002762:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002764:	eb85                	bnez	a5,80002794 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002766:	e57ff0ef          	jal	800025bc <devintr>
    8000276a:	c91d                	beqz	a0,800027a0 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    8000276c:	4789                	li	a5,2
    8000276e:	04f50a63          	beq	a0,a5,800027c2 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002772:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002776:	10049073          	csrw	sstatus,s1
}
    8000277a:	70a2                	ld	ra,40(sp)
    8000277c:	7402                	ld	s0,32(sp)
    8000277e:	64e2                	ld	s1,24(sp)
    80002780:	6942                	ld	s2,16(sp)
    80002782:	69a2                	ld	s3,8(sp)
    80002784:	6145                	addi	sp,sp,48
    80002786:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002788:	00005517          	auipc	a0,0x5
    8000278c:	b6050513          	addi	a0,a0,-1184 # 800072e8 <etext+0x2e8>
    80002790:	850fe0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002794:	00005517          	auipc	a0,0x5
    80002798:	b7c50513          	addi	a0,a0,-1156 # 80007310 <etext+0x310>
    8000279c:	844fe0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027a0:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800027a4:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    800027a8:	85ce                	mv	a1,s3
    800027aa:	00005517          	auipc	a0,0x5
    800027ae:	b8650513          	addi	a0,a0,-1146 # 80007330 <etext+0x330>
    800027b2:	d49fd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    800027b6:	00005517          	auipc	a0,0x5
    800027ba:	ba250513          	addi	a0,a0,-1118 # 80007358 <etext+0x358>
    800027be:	822fe0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0)
    800027c2:	90cff0ef          	jal	800018ce <myproc>
    800027c6:	d555                	beqz	a0,80002772 <kerneltrap+0x34>
    yield();
    800027c8:	fcaff0ef          	jal	80001f92 <yield>
    800027cc:	b75d                	j	80002772 <kerneltrap+0x34>

00000000800027ce <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800027ce:	1101                	addi	sp,sp,-32
    800027d0:	ec06                	sd	ra,24(sp)
    800027d2:	e822                	sd	s0,16(sp)
    800027d4:	e426                	sd	s1,8(sp)
    800027d6:	1000                	addi	s0,sp,32
    800027d8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800027da:	8f4ff0ef          	jal	800018ce <myproc>
  switch (n) {
    800027de:	4795                	li	a5,5
    800027e0:	0497e163          	bltu	a5,s1,80002822 <argraw+0x54>
    800027e4:	048a                	slli	s1,s1,0x2
    800027e6:	00005717          	auipc	a4,0x5
    800027ea:	f7270713          	addi	a4,a4,-142 # 80007758 <states.0+0x30>
    800027ee:	94ba                	add	s1,s1,a4
    800027f0:	409c                	lw	a5,0(s1)
    800027f2:	97ba                	add	a5,a5,a4
    800027f4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800027f6:	6d3c                	ld	a5,88(a0)
    800027f8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800027fa:	60e2                	ld	ra,24(sp)
    800027fc:	6442                	ld	s0,16(sp)
    800027fe:	64a2                	ld	s1,8(sp)
    80002800:	6105                	addi	sp,sp,32
    80002802:	8082                	ret
    return p->trapframe->a1;
    80002804:	6d3c                	ld	a5,88(a0)
    80002806:	7fa8                	ld	a0,120(a5)
    80002808:	bfcd                	j	800027fa <argraw+0x2c>
    return p->trapframe->a2;
    8000280a:	6d3c                	ld	a5,88(a0)
    8000280c:	63c8                	ld	a0,128(a5)
    8000280e:	b7f5                	j	800027fa <argraw+0x2c>
    return p->trapframe->a3;
    80002810:	6d3c                	ld	a5,88(a0)
    80002812:	67c8                	ld	a0,136(a5)
    80002814:	b7dd                	j	800027fa <argraw+0x2c>
    return p->trapframe->a4;
    80002816:	6d3c                	ld	a5,88(a0)
    80002818:	6bc8                	ld	a0,144(a5)
    8000281a:	b7c5                	j	800027fa <argraw+0x2c>
    return p->trapframe->a5;
    8000281c:	6d3c                	ld	a5,88(a0)
    8000281e:	6fc8                	ld	a0,152(a5)
    80002820:	bfe9                	j	800027fa <argraw+0x2c>
  panic("argraw");
    80002822:	00005517          	auipc	a0,0x5
    80002826:	b4650513          	addi	a0,a0,-1210 # 80007368 <etext+0x368>
    8000282a:	fb7fd0ef          	jal	800007e0 <panic>

000000008000282e <fetchaddr>:
{
    8000282e:	1101                	addi	sp,sp,-32
    80002830:	ec06                	sd	ra,24(sp)
    80002832:	e822                	sd	s0,16(sp)
    80002834:	e426                	sd	s1,8(sp)
    80002836:	e04a                	sd	s2,0(sp)
    80002838:	1000                	addi	s0,sp,32
    8000283a:	84aa                	mv	s1,a0
    8000283c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000283e:	890ff0ef          	jal	800018ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002842:	653c                	ld	a5,72(a0)
    80002844:	02f4f663          	bgeu	s1,a5,80002870 <fetchaddr+0x42>
    80002848:	00848713          	addi	a4,s1,8
    8000284c:	02e7e463          	bltu	a5,a4,80002874 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002850:	46a1                	li	a3,8
    80002852:	8626                	mv	a2,s1
    80002854:	85ca                	mv	a1,s2
    80002856:	6928                	ld	a0,80(a0)
    80002858:	e6ffe0ef          	jal	800016c6 <copyin>
    8000285c:	00a03533          	snez	a0,a0
    80002860:	40a00533          	neg	a0,a0
}
    80002864:	60e2                	ld	ra,24(sp)
    80002866:	6442                	ld	s0,16(sp)
    80002868:	64a2                	ld	s1,8(sp)
    8000286a:	6902                	ld	s2,0(sp)
    8000286c:	6105                	addi	sp,sp,32
    8000286e:	8082                	ret
    return -1;
    80002870:	557d                	li	a0,-1
    80002872:	bfcd                	j	80002864 <fetchaddr+0x36>
    80002874:	557d                	li	a0,-1
    80002876:	b7fd                	j	80002864 <fetchaddr+0x36>

0000000080002878 <fetchstr>:
{
    80002878:	7179                	addi	sp,sp,-48
    8000287a:	f406                	sd	ra,40(sp)
    8000287c:	f022                	sd	s0,32(sp)
    8000287e:	ec26                	sd	s1,24(sp)
    80002880:	e84a                	sd	s2,16(sp)
    80002882:	e44e                	sd	s3,8(sp)
    80002884:	1800                	addi	s0,sp,48
    80002886:	892a                	mv	s2,a0
    80002888:	84ae                	mv	s1,a1
    8000288a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000288c:	842ff0ef          	jal	800018ce <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002890:	86ce                	mv	a3,s3
    80002892:	864a                	mv	a2,s2
    80002894:	85a6                	mv	a1,s1
    80002896:	6928                	ld	a0,80(a0)
    80002898:	bf1fe0ef          	jal	80001488 <copyinstr>
    8000289c:	00054c63          	bltz	a0,800028b4 <fetchstr+0x3c>
  return strlen(buf);
    800028a0:	8526                	mv	a0,s1
    800028a2:	d70fe0ef          	jal	80000e12 <strlen>
}
    800028a6:	70a2                	ld	ra,40(sp)
    800028a8:	7402                	ld	s0,32(sp)
    800028aa:	64e2                	ld	s1,24(sp)
    800028ac:	6942                	ld	s2,16(sp)
    800028ae:	69a2                	ld	s3,8(sp)
    800028b0:	6145                	addi	sp,sp,48
    800028b2:	8082                	ret
    return -1;
    800028b4:	557d                	li	a0,-1
    800028b6:	bfc5                	j	800028a6 <fetchstr+0x2e>

00000000800028b8 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800028b8:	1101                	addi	sp,sp,-32
    800028ba:	ec06                	sd	ra,24(sp)
    800028bc:	e822                	sd	s0,16(sp)
    800028be:	e426                	sd	s1,8(sp)
    800028c0:	1000                	addi	s0,sp,32
    800028c2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800028c4:	f0bff0ef          	jal	800027ce <argraw>
    800028c8:	c088                	sw	a0,0(s1)
}
    800028ca:	60e2                	ld	ra,24(sp)
    800028cc:	6442                	ld	s0,16(sp)
    800028ce:	64a2                	ld	s1,8(sp)
    800028d0:	6105                	addi	sp,sp,32
    800028d2:	8082                	ret

00000000800028d4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800028d4:	1101                	addi	sp,sp,-32
    800028d6:	ec06                	sd	ra,24(sp)
    800028d8:	e822                	sd	s0,16(sp)
    800028da:	e426                	sd	s1,8(sp)
    800028dc:	1000                	addi	s0,sp,32
    800028de:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800028e0:	eefff0ef          	jal	800027ce <argraw>
    800028e4:	e088                	sd	a0,0(s1)
}
    800028e6:	60e2                	ld	ra,24(sp)
    800028e8:	6442                	ld	s0,16(sp)
    800028ea:	64a2                	ld	s1,8(sp)
    800028ec:	6105                	addi	sp,sp,32
    800028ee:	8082                	ret

00000000800028f0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800028f0:	7179                	addi	sp,sp,-48
    800028f2:	f406                	sd	ra,40(sp)
    800028f4:	f022                	sd	s0,32(sp)
    800028f6:	ec26                	sd	s1,24(sp)
    800028f8:	e84a                	sd	s2,16(sp)
    800028fa:	1800                	addi	s0,sp,48
    800028fc:	84ae                	mv	s1,a1
    800028fe:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002900:	fd840593          	addi	a1,s0,-40
    80002904:	fd1ff0ef          	jal	800028d4 <argaddr>
  return fetchstr(addr, buf, max);
    80002908:	864a                	mv	a2,s2
    8000290a:	85a6                	mv	a1,s1
    8000290c:	fd843503          	ld	a0,-40(s0)
    80002910:	f69ff0ef          	jal	80002878 <fetchstr>
}
    80002914:	70a2                	ld	ra,40(sp)
    80002916:	7402                	ld	s0,32(sp)
    80002918:	64e2                	ld	s1,24(sp)
    8000291a:	6942                	ld	s2,16(sp)
    8000291c:	6145                	addi	sp,sp,48
    8000291e:	8082                	ret

0000000080002920 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002920:	1101                	addi	sp,sp,-32
    80002922:	ec06                	sd	ra,24(sp)
    80002924:	e822                	sd	s0,16(sp)
    80002926:	e426                	sd	s1,8(sp)
    80002928:	e04a                	sd	s2,0(sp)
    8000292a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000292c:	fa3fe0ef          	jal	800018ce <myproc>
    80002930:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002932:	05853903          	ld	s2,88(a0)
    80002936:	0a893783          	ld	a5,168(s2)
    8000293a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000293e:	37fd                	addiw	a5,a5,-1
    80002940:	4755                	li	a4,21
    80002942:	00f76f63          	bltu	a4,a5,80002960 <syscall+0x40>
    80002946:	00369713          	slli	a4,a3,0x3
    8000294a:	00005797          	auipc	a5,0x5
    8000294e:	e2678793          	addi	a5,a5,-474 # 80007770 <syscalls>
    80002952:	97ba                	add	a5,a5,a4
    80002954:	639c                	ld	a5,0(a5)
    80002956:	c789                	beqz	a5,80002960 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002958:	9782                	jalr	a5
    8000295a:	06a93823          	sd	a0,112(s2)
    8000295e:	a829                	j	80002978 <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002960:	16048613          	addi	a2,s1,352
    80002964:	588c                	lw	a1,48(s1)
    80002966:	00005517          	auipc	a0,0x5
    8000296a:	a0a50513          	addi	a0,a0,-1526 # 80007370 <etext+0x370>
    8000296e:	b8dfd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002972:	6cbc                	ld	a5,88(s1)
    80002974:	577d                	li	a4,-1
    80002976:	fbb8                	sd	a4,112(a5)
  }
}
    80002978:	60e2                	ld	ra,24(sp)
    8000297a:	6442                	ld	s0,16(sp)
    8000297c:	64a2                	ld	s1,8(sp)
    8000297e:	6902                	ld	s2,0(sp)
    80002980:	6105                	addi	sp,sp,32
    80002982:	8082                	ret

0000000080002984 <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    80002984:	1101                	addi	sp,sp,-32
    80002986:	ec06                	sd	ra,24(sp)
    80002988:	e822                	sd	s0,16(sp)
    8000298a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000298c:	fec40593          	addi	a1,s0,-20
    80002990:	4501                	li	a0,0
    80002992:	f27ff0ef          	jal	800028b8 <argint>
  kexit(n);
    80002996:	fec42503          	lw	a0,-20(s0)
    8000299a:	f30ff0ef          	jal	800020ca <kexit>
  return 0;  // not reached
}
    8000299e:	4501                	li	a0,0
    800029a0:	60e2                	ld	ra,24(sp)
    800029a2:	6442                	ld	s0,16(sp)
    800029a4:	6105                	addi	sp,sp,32
    800029a6:	8082                	ret

00000000800029a8 <sys_getpid>:

uint64
sys_getpid(void)
{
    800029a8:	1141                	addi	sp,sp,-16
    800029aa:	e406                	sd	ra,8(sp)
    800029ac:	e022                	sd	s0,0(sp)
    800029ae:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800029b0:	f1ffe0ef          	jal	800018ce <myproc>
}
    800029b4:	5908                	lw	a0,48(a0)
    800029b6:	60a2                	ld	ra,8(sp)
    800029b8:	6402                	ld	s0,0(sp)
    800029ba:	0141                	addi	sp,sp,16
    800029bc:	8082                	ret

00000000800029be <sys_fork>:

uint64
sys_fork(void)
{
    800029be:	1141                	addi	sp,sp,-16
    800029c0:	e406                	sd	ra,8(sp)
    800029c2:	e022                	sd	s0,0(sp)
    800029c4:	0800                	addi	s0,sp,16
  return kfork();
    800029c6:	af2ff0ef          	jal	80001cb8 <kfork>
}
    800029ca:	60a2                	ld	ra,8(sp)
    800029cc:	6402                	ld	s0,0(sp)
    800029ce:	0141                	addi	sp,sp,16
    800029d0:	8082                	ret

00000000800029d2 <sys_wait>:

uint64
sys_wait(void)
{
    800029d2:	1101                	addi	sp,sp,-32
    800029d4:	ec06                	sd	ra,24(sp)
    800029d6:	e822                	sd	s0,16(sp)
    800029d8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800029da:	fe840593          	addi	a1,s0,-24
    800029de:	4501                	li	a0,0
    800029e0:	ef5ff0ef          	jal	800028d4 <argaddr>
  return kwait(p);
    800029e4:	fe843503          	ld	a0,-24(s0)
    800029e8:	839ff0ef          	jal	80002220 <kwait>
}
    800029ec:	60e2                	ld	ra,24(sp)
    800029ee:	6442                	ld	s0,16(sp)
    800029f0:	6105                	addi	sp,sp,32
    800029f2:	8082                	ret

00000000800029f4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800029f4:	7179                	addi	sp,sp,-48
    800029f6:	f406                	sd	ra,40(sp)
    800029f8:	f022                	sd	s0,32(sp)
    800029fa:	ec26                	sd	s1,24(sp)
    800029fc:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    800029fe:	fd840593          	addi	a1,s0,-40
    80002a02:	4501                	li	a0,0
    80002a04:	eb5ff0ef          	jal	800028b8 <argint>
  argint(1, &t);
    80002a08:	fdc40593          	addi	a1,s0,-36
    80002a0c:	4505                	li	a0,1
    80002a0e:	eabff0ef          	jal	800028b8 <argint>
  addr = myproc()->sz;
    80002a12:	ebdfe0ef          	jal	800018ce <myproc>
    80002a16:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002a18:	fdc42703          	lw	a4,-36(s0)
    80002a1c:	4785                	li	a5,1
    80002a1e:	02f70763          	beq	a4,a5,80002a4c <sys_sbrk+0x58>
    80002a22:	fd842783          	lw	a5,-40(s0)
    80002a26:	0207c363          	bltz	a5,80002a4c <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002a2a:	97a6                	add	a5,a5,s1
    80002a2c:	0297ee63          	bltu	a5,s1,80002a68 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002a30:	02000737          	lui	a4,0x2000
    80002a34:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    80002a36:	0736                	slli	a4,a4,0xd
    80002a38:	02f76a63          	bltu	a4,a5,80002a6c <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    80002a3c:	e93fe0ef          	jal	800018ce <myproc>
    80002a40:	fd842703          	lw	a4,-40(s0)
    80002a44:	653c                	ld	a5,72(a0)
    80002a46:	97ba                	add	a5,a5,a4
    80002a48:	e53c                	sd	a5,72(a0)
    80002a4a:	a039                	j	80002a58 <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    80002a4c:	fd842503          	lw	a0,-40(s0)
    80002a50:	a06ff0ef          	jal	80001c56 <growproc>
    80002a54:	00054863          	bltz	a0,80002a64 <sys_sbrk+0x70>
  }
  return addr;
}
    80002a58:	8526                	mv	a0,s1
    80002a5a:	70a2                	ld	ra,40(sp)
    80002a5c:	7402                	ld	s0,32(sp)
    80002a5e:	64e2                	ld	s1,24(sp)
    80002a60:	6145                	addi	sp,sp,48
    80002a62:	8082                	ret
      return -1;
    80002a64:	54fd                	li	s1,-1
    80002a66:	bfcd                	j	80002a58 <sys_sbrk+0x64>
      return -1;
    80002a68:	54fd                	li	s1,-1
    80002a6a:	b7fd                	j	80002a58 <sys_sbrk+0x64>
      return -1;
    80002a6c:	54fd                	li	s1,-1
    80002a6e:	b7ed                	j	80002a58 <sys_sbrk+0x64>

0000000080002a70 <sys_pause>:

uint64
sys_pause(void)
{
    80002a70:	7139                	addi	sp,sp,-64
    80002a72:	fc06                	sd	ra,56(sp)
    80002a74:	f822                	sd	s0,48(sp)
    80002a76:	f04a                	sd	s2,32(sp)
    80002a78:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002a7a:	fcc40593          	addi	a1,s0,-52
    80002a7e:	4501                	li	a0,0
    80002a80:	e39ff0ef          	jal	800028b8 <argint>
  if(n < 0)
    80002a84:	fcc42783          	lw	a5,-52(s0)
    80002a88:	0607c763          	bltz	a5,80002af6 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80002a8c:	00016517          	auipc	a0,0x16
    80002a90:	8dc50513          	addi	a0,a0,-1828 # 80018368 <tickslock>
    80002a94:	93afe0ef          	jal	80000bce <acquire>
  ticks0 = ticks;
    80002a98:	00007917          	auipc	s2,0x7
    80002a9c:	7a092903          	lw	s2,1952(s2) # 8000a238 <ticks>
  while(ticks - ticks0 < n){
    80002aa0:	fcc42783          	lw	a5,-52(s0)
    80002aa4:	cf8d                	beqz	a5,80002ade <sys_pause+0x6e>
    80002aa6:	f426                	sd	s1,40(sp)
    80002aa8:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002aaa:	00016997          	auipc	s3,0x16
    80002aae:	8be98993          	addi	s3,s3,-1858 # 80018368 <tickslock>
    80002ab2:	00007497          	auipc	s1,0x7
    80002ab6:	78648493          	addi	s1,s1,1926 # 8000a238 <ticks>
    if(killed(myproc())){
    80002aba:	e15fe0ef          	jal	800018ce <myproc>
    80002abe:	f38ff0ef          	jal	800021f6 <killed>
    80002ac2:	ed0d                	bnez	a0,80002afc <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002ac4:	85ce                	mv	a1,s3
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	cf6ff0ef          	jal	80001fbe <sleep>
  while(ticks - ticks0 < n){
    80002acc:	409c                	lw	a5,0(s1)
    80002ace:	412787bb          	subw	a5,a5,s2
    80002ad2:	fcc42703          	lw	a4,-52(s0)
    80002ad6:	fee7e2e3          	bltu	a5,a4,80002aba <sys_pause+0x4a>
    80002ada:	74a2                	ld	s1,40(sp)
    80002adc:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002ade:	00016517          	auipc	a0,0x16
    80002ae2:	88a50513          	addi	a0,a0,-1910 # 80018368 <tickslock>
    80002ae6:	980fe0ef          	jal	80000c66 <release>
  return 0;
    80002aea:	4501                	li	a0,0
}
    80002aec:	70e2                	ld	ra,56(sp)
    80002aee:	7442                	ld	s0,48(sp)
    80002af0:	7902                	ld	s2,32(sp)
    80002af2:	6121                	addi	sp,sp,64
    80002af4:	8082                	ret
    n = 0;
    80002af6:	fc042623          	sw	zero,-52(s0)
    80002afa:	bf49                	j	80002a8c <sys_pause+0x1c>
      release(&tickslock);
    80002afc:	00016517          	auipc	a0,0x16
    80002b00:	86c50513          	addi	a0,a0,-1940 # 80018368 <tickslock>
    80002b04:	962fe0ef          	jal	80000c66 <release>
      return -1;
    80002b08:	557d                	li	a0,-1
    80002b0a:	74a2                	ld	s1,40(sp)
    80002b0c:	69e2                	ld	s3,24(sp)
    80002b0e:	bff9                	j	80002aec <sys_pause+0x7c>

0000000080002b10 <sys_kill>:

uint64
sys_kill(void)
{
    80002b10:	1101                	addi	sp,sp,-32
    80002b12:	ec06                	sd	ra,24(sp)
    80002b14:	e822                	sd	s0,16(sp)
    80002b16:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002b18:	fec40593          	addi	a1,s0,-20
    80002b1c:	4501                	li	a0,0
    80002b1e:	d9bff0ef          	jal	800028b8 <argint>
  return kkill(pid);
    80002b22:	fec42503          	lw	a0,-20(s0)
    80002b26:	e46ff0ef          	jal	8000216c <kkill>
}
    80002b2a:	60e2                	ld	ra,24(sp)
    80002b2c:	6442                	ld	s0,16(sp)
    80002b2e:	6105                	addi	sp,sp,32
    80002b30:	8082                	ret

0000000080002b32 <sys_settickets>:

uint64
sys_settickets(void)
{
    80002b32:	7179                	addi	sp,sp,-48
    80002b34:	f406                	sd	ra,40(sp)
    80002b36:	f022                	sd	s0,32(sp)
    80002b38:	ec26                	sd	s1,24(sp)
    80002b3a:	1800                	addi	s0,sp,48
  int n;
  struct proc *p = myproc();
    80002b3c:	d93fe0ef          	jal	800018ce <myproc>
    80002b40:	84aa                	mv	s1,a0

  argint(0, &n);
    80002b42:	fdc40593          	addi	a1,s0,-36
    80002b46:	4501                	li	a0,0
    80002b48:	d71ff0ef          	jal	800028b8 <argint>
  if(n <= 0)
    80002b4c:	fdc42783          	lw	a5,-36(s0)
    return -1;
    80002b50:	557d                	li	a0,-1
  if(n <= 0)
    80002b52:	00f05d63          	blez	a5,80002b6c <sys_settickets+0x3a>

  acquire(&p->lock);
    80002b56:	8526                	mv	a0,s1
    80002b58:	876fe0ef          	jal	80000bce <acquire>
  p->tickets = n;
    80002b5c:	fdc42783          	lw	a5,-36(s0)
    80002b60:	14f4ac23          	sw	a5,344(s1)
  release(&p->lock);
    80002b64:	8526                	mv	a0,s1
    80002b66:	900fe0ef          	jal	80000c66 <release>
  return 0;
    80002b6a:	4501                	li	a0,0
}
    80002b6c:	70a2                	ld	ra,40(sp)
    80002b6e:	7402                	ld	s0,32(sp)
    80002b70:	64e2                	ld	s1,24(sp)
    80002b72:	6145                	addi	sp,sp,48
    80002b74:	8082                	ret

0000000080002b76 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002b76:	1101                	addi	sp,sp,-32
    80002b78:	ec06                	sd	ra,24(sp)
    80002b7a:	e822                	sd	s0,16(sp)
    80002b7c:	e426                	sd	s1,8(sp)
    80002b7e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002b80:	00015517          	auipc	a0,0x15
    80002b84:	7e850513          	addi	a0,a0,2024 # 80018368 <tickslock>
    80002b88:	846fe0ef          	jal	80000bce <acquire>
  xticks = ticks;
    80002b8c:	00007497          	auipc	s1,0x7
    80002b90:	6ac4a483          	lw	s1,1708(s1) # 8000a238 <ticks>
  release(&tickslock);
    80002b94:	00015517          	auipc	a0,0x15
    80002b98:	7d450513          	addi	a0,a0,2004 # 80018368 <tickslock>
    80002b9c:	8cafe0ef          	jal	80000c66 <release>
  return xticks;
}
    80002ba0:	02049513          	slli	a0,s1,0x20
    80002ba4:	9101                	srli	a0,a0,0x20
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret

0000000080002bb0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002bb0:	7179                	addi	sp,sp,-48
    80002bb2:	f406                	sd	ra,40(sp)
    80002bb4:	f022                	sd	s0,32(sp)
    80002bb6:	ec26                	sd	s1,24(sp)
    80002bb8:	e84a                	sd	s2,16(sp)
    80002bba:	e44e                	sd	s3,8(sp)
    80002bbc:	e052                	sd	s4,0(sp)
    80002bbe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002bc0:	00004597          	auipc	a1,0x4
    80002bc4:	7d058593          	addi	a1,a1,2000 # 80007390 <etext+0x390>
    80002bc8:	00015517          	auipc	a0,0x15
    80002bcc:	7b850513          	addi	a0,a0,1976 # 80018380 <bcache>
    80002bd0:	f7ffd0ef          	jal	80000b4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002bd4:	0001d797          	auipc	a5,0x1d
    80002bd8:	7ac78793          	addi	a5,a5,1964 # 80020380 <bcache+0x8000>
    80002bdc:	0001e717          	auipc	a4,0x1e
    80002be0:	a0c70713          	addi	a4,a4,-1524 # 800205e8 <bcache+0x8268>
    80002be4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002be8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002bec:	00015497          	auipc	s1,0x15
    80002bf0:	7ac48493          	addi	s1,s1,1964 # 80018398 <bcache+0x18>
    b->next = bcache.head.next;
    80002bf4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002bf6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002bf8:	00004a17          	auipc	s4,0x4
    80002bfc:	7a0a0a13          	addi	s4,s4,1952 # 80007398 <etext+0x398>
    b->next = bcache.head.next;
    80002c00:	2b893783          	ld	a5,696(s2)
    80002c04:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002c06:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002c0a:	85d2                	mv	a1,s4
    80002c0c:	01048513          	addi	a0,s1,16
    80002c10:	322010ef          	jal	80003f32 <initsleeplock>
    bcache.head.next->prev = b;
    80002c14:	2b893783          	ld	a5,696(s2)
    80002c18:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002c1a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002c1e:	45848493          	addi	s1,s1,1112
    80002c22:	fd349fe3          	bne	s1,s3,80002c00 <binit+0x50>
  }
}
    80002c26:	70a2                	ld	ra,40(sp)
    80002c28:	7402                	ld	s0,32(sp)
    80002c2a:	64e2                	ld	s1,24(sp)
    80002c2c:	6942                	ld	s2,16(sp)
    80002c2e:	69a2                	ld	s3,8(sp)
    80002c30:	6a02                	ld	s4,0(sp)
    80002c32:	6145                	addi	sp,sp,48
    80002c34:	8082                	ret

0000000080002c36 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002c36:	7179                	addi	sp,sp,-48
    80002c38:	f406                	sd	ra,40(sp)
    80002c3a:	f022                	sd	s0,32(sp)
    80002c3c:	ec26                	sd	s1,24(sp)
    80002c3e:	e84a                	sd	s2,16(sp)
    80002c40:	e44e                	sd	s3,8(sp)
    80002c42:	1800                	addi	s0,sp,48
    80002c44:	892a                	mv	s2,a0
    80002c46:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002c48:	00015517          	auipc	a0,0x15
    80002c4c:	73850513          	addi	a0,a0,1848 # 80018380 <bcache>
    80002c50:	f7ffd0ef          	jal	80000bce <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002c54:	0001e497          	auipc	s1,0x1e
    80002c58:	9e44b483          	ld	s1,-1564(s1) # 80020638 <bcache+0x82b8>
    80002c5c:	0001e797          	auipc	a5,0x1e
    80002c60:	98c78793          	addi	a5,a5,-1652 # 800205e8 <bcache+0x8268>
    80002c64:	02f48b63          	beq	s1,a5,80002c9a <bread+0x64>
    80002c68:	873e                	mv	a4,a5
    80002c6a:	a021                	j	80002c72 <bread+0x3c>
    80002c6c:	68a4                	ld	s1,80(s1)
    80002c6e:	02e48663          	beq	s1,a4,80002c9a <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002c72:	449c                	lw	a5,8(s1)
    80002c74:	ff279ce3          	bne	a5,s2,80002c6c <bread+0x36>
    80002c78:	44dc                	lw	a5,12(s1)
    80002c7a:	ff3799e3          	bne	a5,s3,80002c6c <bread+0x36>
      b->refcnt++;
    80002c7e:	40bc                	lw	a5,64(s1)
    80002c80:	2785                	addiw	a5,a5,1
    80002c82:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002c84:	00015517          	auipc	a0,0x15
    80002c88:	6fc50513          	addi	a0,a0,1788 # 80018380 <bcache>
    80002c8c:	fdbfd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002c90:	01048513          	addi	a0,s1,16
    80002c94:	2d4010ef          	jal	80003f68 <acquiresleep>
      return b;
    80002c98:	a889                	j	80002cea <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002c9a:	0001e497          	auipc	s1,0x1e
    80002c9e:	9964b483          	ld	s1,-1642(s1) # 80020630 <bcache+0x82b0>
    80002ca2:	0001e797          	auipc	a5,0x1e
    80002ca6:	94678793          	addi	a5,a5,-1722 # 800205e8 <bcache+0x8268>
    80002caa:	00f48863          	beq	s1,a5,80002cba <bread+0x84>
    80002cae:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002cb0:	40bc                	lw	a5,64(s1)
    80002cb2:	cb91                	beqz	a5,80002cc6 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002cb4:	64a4                	ld	s1,72(s1)
    80002cb6:	fee49de3          	bne	s1,a4,80002cb0 <bread+0x7a>
  panic("bget: no buffers");
    80002cba:	00004517          	auipc	a0,0x4
    80002cbe:	6e650513          	addi	a0,a0,1766 # 800073a0 <etext+0x3a0>
    80002cc2:	b1ffd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    80002cc6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002cca:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002cce:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002cd2:	4785                	li	a5,1
    80002cd4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002cd6:	00015517          	auipc	a0,0x15
    80002cda:	6aa50513          	addi	a0,a0,1706 # 80018380 <bcache>
    80002cde:	f89fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002ce2:	01048513          	addi	a0,s1,16
    80002ce6:	282010ef          	jal	80003f68 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002cea:	409c                	lw	a5,0(s1)
    80002cec:	cb89                	beqz	a5,80002cfe <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002cee:	8526                	mv	a0,s1
    80002cf0:	70a2                	ld	ra,40(sp)
    80002cf2:	7402                	ld	s0,32(sp)
    80002cf4:	64e2                	ld	s1,24(sp)
    80002cf6:	6942                	ld	s2,16(sp)
    80002cf8:	69a2                	ld	s3,8(sp)
    80002cfa:	6145                	addi	sp,sp,48
    80002cfc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002cfe:	4581                	li	a1,0
    80002d00:	8526                	mv	a0,s1
    80002d02:	2cf020ef          	jal	800057d0 <virtio_disk_rw>
    b->valid = 1;
    80002d06:	4785                	li	a5,1
    80002d08:	c09c                	sw	a5,0(s1)
  return b;
    80002d0a:	b7d5                	j	80002cee <bread+0xb8>

0000000080002d0c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002d0c:	1101                	addi	sp,sp,-32
    80002d0e:	ec06                	sd	ra,24(sp)
    80002d10:	e822                	sd	s0,16(sp)
    80002d12:	e426                	sd	s1,8(sp)
    80002d14:	1000                	addi	s0,sp,32
    80002d16:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002d18:	0541                	addi	a0,a0,16
    80002d1a:	2cc010ef          	jal	80003fe6 <holdingsleep>
    80002d1e:	c911                	beqz	a0,80002d32 <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002d20:	4585                	li	a1,1
    80002d22:	8526                	mv	a0,s1
    80002d24:	2ad020ef          	jal	800057d0 <virtio_disk_rw>
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret
    panic("bwrite");
    80002d32:	00004517          	auipc	a0,0x4
    80002d36:	68650513          	addi	a0,a0,1670 # 800073b8 <etext+0x3b8>
    80002d3a:	aa7fd0ef          	jal	800007e0 <panic>

0000000080002d3e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	e04a                	sd	s2,0(sp)
    80002d48:	1000                	addi	s0,sp,32
    80002d4a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002d4c:	01050913          	addi	s2,a0,16
    80002d50:	854a                	mv	a0,s2
    80002d52:	294010ef          	jal	80003fe6 <holdingsleep>
    80002d56:	c135                	beqz	a0,80002dba <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80002d58:	854a                	mv	a0,s2
    80002d5a:	254010ef          	jal	80003fae <releasesleep>

  acquire(&bcache.lock);
    80002d5e:	00015517          	auipc	a0,0x15
    80002d62:	62250513          	addi	a0,a0,1570 # 80018380 <bcache>
    80002d66:	e69fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80002d6a:	40bc                	lw	a5,64(s1)
    80002d6c:	37fd                	addiw	a5,a5,-1
    80002d6e:	0007871b          	sext.w	a4,a5
    80002d72:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002d74:	e71d                	bnez	a4,80002da2 <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002d76:	68b8                	ld	a4,80(s1)
    80002d78:	64bc                	ld	a5,72(s1)
    80002d7a:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002d7c:	68b8                	ld	a4,80(s1)
    80002d7e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002d80:	0001d797          	auipc	a5,0x1d
    80002d84:	60078793          	addi	a5,a5,1536 # 80020380 <bcache+0x8000>
    80002d88:	2b87b703          	ld	a4,696(a5)
    80002d8c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002d8e:	0001e717          	auipc	a4,0x1e
    80002d92:	85a70713          	addi	a4,a4,-1958 # 800205e8 <bcache+0x8268>
    80002d96:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002d98:	2b87b703          	ld	a4,696(a5)
    80002d9c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002d9e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002da2:	00015517          	auipc	a0,0x15
    80002da6:	5de50513          	addi	a0,a0,1502 # 80018380 <bcache>
    80002daa:	ebdfd0ef          	jal	80000c66 <release>
}
    80002dae:	60e2                	ld	ra,24(sp)
    80002db0:	6442                	ld	s0,16(sp)
    80002db2:	64a2                	ld	s1,8(sp)
    80002db4:	6902                	ld	s2,0(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret
    panic("brelse");
    80002dba:	00004517          	auipc	a0,0x4
    80002dbe:	60650513          	addi	a0,a0,1542 # 800073c0 <etext+0x3c0>
    80002dc2:	a1ffd0ef          	jal	800007e0 <panic>

0000000080002dc6 <bpin>:

void
bpin(struct buf *b) {
    80002dc6:	1101                	addi	sp,sp,-32
    80002dc8:	ec06                	sd	ra,24(sp)
    80002dca:	e822                	sd	s0,16(sp)
    80002dcc:	e426                	sd	s1,8(sp)
    80002dce:	1000                	addi	s0,sp,32
    80002dd0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002dd2:	00015517          	auipc	a0,0x15
    80002dd6:	5ae50513          	addi	a0,a0,1454 # 80018380 <bcache>
    80002dda:	df5fd0ef          	jal	80000bce <acquire>
  b->refcnt++;
    80002dde:	40bc                	lw	a5,64(s1)
    80002de0:	2785                	addiw	a5,a5,1
    80002de2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002de4:	00015517          	auipc	a0,0x15
    80002de8:	59c50513          	addi	a0,a0,1436 # 80018380 <bcache>
    80002dec:	e7bfd0ef          	jal	80000c66 <release>
}
    80002df0:	60e2                	ld	ra,24(sp)
    80002df2:	6442                	ld	s0,16(sp)
    80002df4:	64a2                	ld	s1,8(sp)
    80002df6:	6105                	addi	sp,sp,32
    80002df8:	8082                	ret

0000000080002dfa <bunpin>:

void
bunpin(struct buf *b) {
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	e426                	sd	s1,8(sp)
    80002e02:	1000                	addi	s0,sp,32
    80002e04:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002e06:	00015517          	auipc	a0,0x15
    80002e0a:	57a50513          	addi	a0,a0,1402 # 80018380 <bcache>
    80002e0e:	dc1fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80002e12:	40bc                	lw	a5,64(s1)
    80002e14:	37fd                	addiw	a5,a5,-1
    80002e16:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002e18:	00015517          	auipc	a0,0x15
    80002e1c:	56850513          	addi	a0,a0,1384 # 80018380 <bcache>
    80002e20:	e47fd0ef          	jal	80000c66 <release>
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002e2e:	1101                	addi	sp,sp,-32
    80002e30:	ec06                	sd	ra,24(sp)
    80002e32:	e822                	sd	s0,16(sp)
    80002e34:	e426                	sd	s1,8(sp)
    80002e36:	e04a                	sd	s2,0(sp)
    80002e38:	1000                	addi	s0,sp,32
    80002e3a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002e3c:	00d5d59b          	srliw	a1,a1,0xd
    80002e40:	0001e797          	auipc	a5,0x1e
    80002e44:	c1c7a783          	lw	a5,-996(a5) # 80020a5c <sb+0x1c>
    80002e48:	9dbd                	addw	a1,a1,a5
    80002e4a:	dedff0ef          	jal	80002c36 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002e4e:	0074f713          	andi	a4,s1,7
    80002e52:	4785                	li	a5,1
    80002e54:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002e58:	14ce                	slli	s1,s1,0x33
    80002e5a:	90d9                	srli	s1,s1,0x36
    80002e5c:	00950733          	add	a4,a0,s1
    80002e60:	05874703          	lbu	a4,88(a4)
    80002e64:	00e7f6b3          	and	a3,a5,a4
    80002e68:	c29d                	beqz	a3,80002e8e <bfree+0x60>
    80002e6a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002e6c:	94aa                	add	s1,s1,a0
    80002e6e:	fff7c793          	not	a5,a5
    80002e72:	8f7d                	and	a4,a4,a5
    80002e74:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80002e78:	7f9000ef          	jal	80003e70 <log_write>
  brelse(bp);
    80002e7c:	854a                	mv	a0,s2
    80002e7e:	ec1ff0ef          	jal	80002d3e <brelse>
}
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	64a2                	ld	s1,8(sp)
    80002e88:	6902                	ld	s2,0(sp)
    80002e8a:	6105                	addi	sp,sp,32
    80002e8c:	8082                	ret
    panic("freeing free block");
    80002e8e:	00004517          	auipc	a0,0x4
    80002e92:	53a50513          	addi	a0,a0,1338 # 800073c8 <etext+0x3c8>
    80002e96:	94bfd0ef          	jal	800007e0 <panic>

0000000080002e9a <balloc>:
{
    80002e9a:	711d                	addi	sp,sp,-96
    80002e9c:	ec86                	sd	ra,88(sp)
    80002e9e:	e8a2                	sd	s0,80(sp)
    80002ea0:	e4a6                	sd	s1,72(sp)
    80002ea2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002ea4:	0001e797          	auipc	a5,0x1e
    80002ea8:	ba07a783          	lw	a5,-1120(a5) # 80020a44 <sb+0x4>
    80002eac:	0e078f63          	beqz	a5,80002faa <balloc+0x110>
    80002eb0:	e0ca                	sd	s2,64(sp)
    80002eb2:	fc4e                	sd	s3,56(sp)
    80002eb4:	f852                	sd	s4,48(sp)
    80002eb6:	f456                	sd	s5,40(sp)
    80002eb8:	f05a                	sd	s6,32(sp)
    80002eba:	ec5e                	sd	s7,24(sp)
    80002ebc:	e862                	sd	s8,16(sp)
    80002ebe:	e466                	sd	s9,8(sp)
    80002ec0:	8baa                	mv	s7,a0
    80002ec2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002ec4:	0001eb17          	auipc	s6,0x1e
    80002ec8:	b7cb0b13          	addi	s6,s6,-1156 # 80020a40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002ecc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002ece:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002ed0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002ed2:	6c89                	lui	s9,0x2
    80002ed4:	a0b5                	j	80002f40 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002ed6:	97ca                	add	a5,a5,s2
    80002ed8:	8e55                	or	a2,a2,a3
    80002eda:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80002ede:	854a                	mv	a0,s2
    80002ee0:	791000ef          	jal	80003e70 <log_write>
        brelse(bp);
    80002ee4:	854a                	mv	a0,s2
    80002ee6:	e59ff0ef          	jal	80002d3e <brelse>
  bp = bread(dev, bno);
    80002eea:	85a6                	mv	a1,s1
    80002eec:	855e                	mv	a0,s7
    80002eee:	d49ff0ef          	jal	80002c36 <bread>
    80002ef2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002ef4:	40000613          	li	a2,1024
    80002ef8:	4581                	li	a1,0
    80002efa:	05850513          	addi	a0,a0,88
    80002efe:	da5fd0ef          	jal	80000ca2 <memset>
  log_write(bp);
    80002f02:	854a                	mv	a0,s2
    80002f04:	76d000ef          	jal	80003e70 <log_write>
  brelse(bp);
    80002f08:	854a                	mv	a0,s2
    80002f0a:	e35ff0ef          	jal	80002d3e <brelse>
}
    80002f0e:	6906                	ld	s2,64(sp)
    80002f10:	79e2                	ld	s3,56(sp)
    80002f12:	7a42                	ld	s4,48(sp)
    80002f14:	7aa2                	ld	s5,40(sp)
    80002f16:	7b02                	ld	s6,32(sp)
    80002f18:	6be2                	ld	s7,24(sp)
    80002f1a:	6c42                	ld	s8,16(sp)
    80002f1c:	6ca2                	ld	s9,8(sp)
}
    80002f1e:	8526                	mv	a0,s1
    80002f20:	60e6                	ld	ra,88(sp)
    80002f22:	6446                	ld	s0,80(sp)
    80002f24:	64a6                	ld	s1,72(sp)
    80002f26:	6125                	addi	sp,sp,96
    80002f28:	8082                	ret
    brelse(bp);
    80002f2a:	854a                	mv	a0,s2
    80002f2c:	e13ff0ef          	jal	80002d3e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002f30:	015c87bb          	addw	a5,s9,s5
    80002f34:	00078a9b          	sext.w	s5,a5
    80002f38:	004b2703          	lw	a4,4(s6)
    80002f3c:	04eaff63          	bgeu	s5,a4,80002f9a <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    80002f40:	41fad79b          	sraiw	a5,s5,0x1f
    80002f44:	0137d79b          	srliw	a5,a5,0x13
    80002f48:	015787bb          	addw	a5,a5,s5
    80002f4c:	40d7d79b          	sraiw	a5,a5,0xd
    80002f50:	01cb2583          	lw	a1,28(s6)
    80002f54:	9dbd                	addw	a1,a1,a5
    80002f56:	855e                	mv	a0,s7
    80002f58:	cdfff0ef          	jal	80002c36 <bread>
    80002f5c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002f5e:	004b2503          	lw	a0,4(s6)
    80002f62:	000a849b          	sext.w	s1,s5
    80002f66:	8762                	mv	a4,s8
    80002f68:	fca4f1e3          	bgeu	s1,a0,80002f2a <balloc+0x90>
      m = 1 << (bi % 8);
    80002f6c:	00777693          	andi	a3,a4,7
    80002f70:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002f74:	41f7579b          	sraiw	a5,a4,0x1f
    80002f78:	01d7d79b          	srliw	a5,a5,0x1d
    80002f7c:	9fb9                	addw	a5,a5,a4
    80002f7e:	4037d79b          	sraiw	a5,a5,0x3
    80002f82:	00f90633          	add	a2,s2,a5
    80002f86:	05864603          	lbu	a2,88(a2)
    80002f8a:	00c6f5b3          	and	a1,a3,a2
    80002f8e:	d5a1                	beqz	a1,80002ed6 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002f90:	2705                	addiw	a4,a4,1
    80002f92:	2485                	addiw	s1,s1,1
    80002f94:	fd471ae3          	bne	a4,s4,80002f68 <balloc+0xce>
    80002f98:	bf49                	j	80002f2a <balloc+0x90>
    80002f9a:	6906                	ld	s2,64(sp)
    80002f9c:	79e2                	ld	s3,56(sp)
    80002f9e:	7a42                	ld	s4,48(sp)
    80002fa0:	7aa2                	ld	s5,40(sp)
    80002fa2:	7b02                	ld	s6,32(sp)
    80002fa4:	6be2                	ld	s7,24(sp)
    80002fa6:	6c42                	ld	s8,16(sp)
    80002fa8:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80002faa:	00004517          	auipc	a0,0x4
    80002fae:	43650513          	addi	a0,a0,1078 # 800073e0 <etext+0x3e0>
    80002fb2:	d48fd0ef          	jal	800004fa <printf>
  return 0;
    80002fb6:	4481                	li	s1,0
    80002fb8:	b79d                	j	80002f1e <balloc+0x84>

0000000080002fba <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002fba:	7179                	addi	sp,sp,-48
    80002fbc:	f406                	sd	ra,40(sp)
    80002fbe:	f022                	sd	s0,32(sp)
    80002fc0:	ec26                	sd	s1,24(sp)
    80002fc2:	e84a                	sd	s2,16(sp)
    80002fc4:	e44e                	sd	s3,8(sp)
    80002fc6:	1800                	addi	s0,sp,48
    80002fc8:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002fca:	47ad                	li	a5,11
    80002fcc:	02b7e663          	bltu	a5,a1,80002ff8 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80002fd0:	02059793          	slli	a5,a1,0x20
    80002fd4:	01e7d593          	srli	a1,a5,0x1e
    80002fd8:	00b504b3          	add	s1,a0,a1
    80002fdc:	0504a903          	lw	s2,80(s1)
    80002fe0:	06091a63          	bnez	s2,80003054 <bmap+0x9a>
      addr = balloc(ip->dev);
    80002fe4:	4108                	lw	a0,0(a0)
    80002fe6:	eb5ff0ef          	jal	80002e9a <balloc>
    80002fea:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002fee:	06090363          	beqz	s2,80003054 <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    80002ff2:	0524a823          	sw	s2,80(s1)
    80002ff6:	a8b9                	j	80003054 <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002ff8:	ff45849b          	addiw	s1,a1,-12
    80002ffc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003000:	0ff00793          	li	a5,255
    80003004:	06e7ee63          	bltu	a5,a4,80003080 <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003008:	08052903          	lw	s2,128(a0)
    8000300c:	00091d63          	bnez	s2,80003026 <bmap+0x6c>
      addr = balloc(ip->dev);
    80003010:	4108                	lw	a0,0(a0)
    80003012:	e89ff0ef          	jal	80002e9a <balloc>
    80003016:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000301a:	02090d63          	beqz	s2,80003054 <bmap+0x9a>
    8000301e:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003020:	0929a023          	sw	s2,128(s3)
    80003024:	a011                	j	80003028 <bmap+0x6e>
    80003026:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80003028:	85ca                	mv	a1,s2
    8000302a:	0009a503          	lw	a0,0(s3)
    8000302e:	c09ff0ef          	jal	80002c36 <bread>
    80003032:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003034:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003038:	02049713          	slli	a4,s1,0x20
    8000303c:	01e75593          	srli	a1,a4,0x1e
    80003040:	00b784b3          	add	s1,a5,a1
    80003044:	0004a903          	lw	s2,0(s1)
    80003048:	00090e63          	beqz	s2,80003064 <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000304c:	8552                	mv	a0,s4
    8000304e:	cf1ff0ef          	jal	80002d3e <brelse>
    return addr;
    80003052:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003054:	854a                	mv	a0,s2
    80003056:	70a2                	ld	ra,40(sp)
    80003058:	7402                	ld	s0,32(sp)
    8000305a:	64e2                	ld	s1,24(sp)
    8000305c:	6942                	ld	s2,16(sp)
    8000305e:	69a2                	ld	s3,8(sp)
    80003060:	6145                	addi	sp,sp,48
    80003062:	8082                	ret
      addr = balloc(ip->dev);
    80003064:	0009a503          	lw	a0,0(s3)
    80003068:	e33ff0ef          	jal	80002e9a <balloc>
    8000306c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003070:	fc090ee3          	beqz	s2,8000304c <bmap+0x92>
        a[bn] = addr;
    80003074:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003078:	8552                	mv	a0,s4
    8000307a:	5f7000ef          	jal	80003e70 <log_write>
    8000307e:	b7f9                	j	8000304c <bmap+0x92>
    80003080:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80003082:	00004517          	auipc	a0,0x4
    80003086:	37650513          	addi	a0,a0,886 # 800073f8 <etext+0x3f8>
    8000308a:	f56fd0ef          	jal	800007e0 <panic>

000000008000308e <iget>:
{
    8000308e:	7179                	addi	sp,sp,-48
    80003090:	f406                	sd	ra,40(sp)
    80003092:	f022                	sd	s0,32(sp)
    80003094:	ec26                	sd	s1,24(sp)
    80003096:	e84a                	sd	s2,16(sp)
    80003098:	e44e                	sd	s3,8(sp)
    8000309a:	e052                	sd	s4,0(sp)
    8000309c:	1800                	addi	s0,sp,48
    8000309e:	89aa                	mv	s3,a0
    800030a0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800030a2:	0001e517          	auipc	a0,0x1e
    800030a6:	9be50513          	addi	a0,a0,-1602 # 80020a60 <itable>
    800030aa:	b25fd0ef          	jal	80000bce <acquire>
  empty = 0;
    800030ae:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800030b0:	0001e497          	auipc	s1,0x1e
    800030b4:	9c848493          	addi	s1,s1,-1592 # 80020a78 <itable+0x18>
    800030b8:	0001f697          	auipc	a3,0x1f
    800030bc:	45068693          	addi	a3,a3,1104 # 80022508 <log>
    800030c0:	a039                	j	800030ce <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800030c2:	02090963          	beqz	s2,800030f4 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800030c6:	08848493          	addi	s1,s1,136
    800030ca:	02d48863          	beq	s1,a3,800030fa <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800030ce:	449c                	lw	a5,8(s1)
    800030d0:	fef059e3          	blez	a5,800030c2 <iget+0x34>
    800030d4:	4098                	lw	a4,0(s1)
    800030d6:	ff3716e3          	bne	a4,s3,800030c2 <iget+0x34>
    800030da:	40d8                	lw	a4,4(s1)
    800030dc:	ff4713e3          	bne	a4,s4,800030c2 <iget+0x34>
      ip->ref++;
    800030e0:	2785                	addiw	a5,a5,1
    800030e2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800030e4:	0001e517          	auipc	a0,0x1e
    800030e8:	97c50513          	addi	a0,a0,-1668 # 80020a60 <itable>
    800030ec:	b7bfd0ef          	jal	80000c66 <release>
      return ip;
    800030f0:	8926                	mv	s2,s1
    800030f2:	a02d                	j	8000311c <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800030f4:	fbe9                	bnez	a5,800030c6 <iget+0x38>
      empty = ip;
    800030f6:	8926                	mv	s2,s1
    800030f8:	b7f9                	j	800030c6 <iget+0x38>
  if(empty == 0)
    800030fa:	02090a63          	beqz	s2,8000312e <iget+0xa0>
  ip->dev = dev;
    800030fe:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003102:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003106:	4785                	li	a5,1
    80003108:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000310c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003110:	0001e517          	auipc	a0,0x1e
    80003114:	95050513          	addi	a0,a0,-1712 # 80020a60 <itable>
    80003118:	b4ffd0ef          	jal	80000c66 <release>
}
    8000311c:	854a                	mv	a0,s2
    8000311e:	70a2                	ld	ra,40(sp)
    80003120:	7402                	ld	s0,32(sp)
    80003122:	64e2                	ld	s1,24(sp)
    80003124:	6942                	ld	s2,16(sp)
    80003126:	69a2                	ld	s3,8(sp)
    80003128:	6a02                	ld	s4,0(sp)
    8000312a:	6145                	addi	sp,sp,48
    8000312c:	8082                	ret
    panic("iget: no inodes");
    8000312e:	00004517          	auipc	a0,0x4
    80003132:	2e250513          	addi	a0,a0,738 # 80007410 <etext+0x410>
    80003136:	eaafd0ef          	jal	800007e0 <panic>

000000008000313a <iinit>:
{
    8000313a:	7179                	addi	sp,sp,-48
    8000313c:	f406                	sd	ra,40(sp)
    8000313e:	f022                	sd	s0,32(sp)
    80003140:	ec26                	sd	s1,24(sp)
    80003142:	e84a                	sd	s2,16(sp)
    80003144:	e44e                	sd	s3,8(sp)
    80003146:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003148:	00004597          	auipc	a1,0x4
    8000314c:	2d858593          	addi	a1,a1,728 # 80007420 <etext+0x420>
    80003150:	0001e517          	auipc	a0,0x1e
    80003154:	91050513          	addi	a0,a0,-1776 # 80020a60 <itable>
    80003158:	9f7fd0ef          	jal	80000b4e <initlock>
  for(i = 0; i < NINODE; i++) {
    8000315c:	0001e497          	auipc	s1,0x1e
    80003160:	92c48493          	addi	s1,s1,-1748 # 80020a88 <itable+0x28>
    80003164:	0001f997          	auipc	s3,0x1f
    80003168:	3b498993          	addi	s3,s3,948 # 80022518 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000316c:	00004917          	auipc	s2,0x4
    80003170:	2bc90913          	addi	s2,s2,700 # 80007428 <etext+0x428>
    80003174:	85ca                	mv	a1,s2
    80003176:	8526                	mv	a0,s1
    80003178:	5bb000ef          	jal	80003f32 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000317c:	08848493          	addi	s1,s1,136
    80003180:	ff349ae3          	bne	s1,s3,80003174 <iinit+0x3a>
}
    80003184:	70a2                	ld	ra,40(sp)
    80003186:	7402                	ld	s0,32(sp)
    80003188:	64e2                	ld	s1,24(sp)
    8000318a:	6942                	ld	s2,16(sp)
    8000318c:	69a2                	ld	s3,8(sp)
    8000318e:	6145                	addi	sp,sp,48
    80003190:	8082                	ret

0000000080003192 <ialloc>:
{
    80003192:	7139                	addi	sp,sp,-64
    80003194:	fc06                	sd	ra,56(sp)
    80003196:	f822                	sd	s0,48(sp)
    80003198:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000319a:	0001e717          	auipc	a4,0x1e
    8000319e:	8b272703          	lw	a4,-1870(a4) # 80020a4c <sb+0xc>
    800031a2:	4785                	li	a5,1
    800031a4:	06e7f063          	bgeu	a5,a4,80003204 <ialloc+0x72>
    800031a8:	f426                	sd	s1,40(sp)
    800031aa:	f04a                	sd	s2,32(sp)
    800031ac:	ec4e                	sd	s3,24(sp)
    800031ae:	e852                	sd	s4,16(sp)
    800031b0:	e456                	sd	s5,8(sp)
    800031b2:	e05a                	sd	s6,0(sp)
    800031b4:	8aaa                	mv	s5,a0
    800031b6:	8b2e                	mv	s6,a1
    800031b8:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800031ba:	0001ea17          	auipc	s4,0x1e
    800031be:	886a0a13          	addi	s4,s4,-1914 # 80020a40 <sb>
    800031c2:	00495593          	srli	a1,s2,0x4
    800031c6:	018a2783          	lw	a5,24(s4)
    800031ca:	9dbd                	addw	a1,a1,a5
    800031cc:	8556                	mv	a0,s5
    800031ce:	a69ff0ef          	jal	80002c36 <bread>
    800031d2:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800031d4:	05850993          	addi	s3,a0,88
    800031d8:	00f97793          	andi	a5,s2,15
    800031dc:	079a                	slli	a5,a5,0x6
    800031de:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800031e0:	00099783          	lh	a5,0(s3)
    800031e4:	cb9d                	beqz	a5,8000321a <ialloc+0x88>
    brelse(bp);
    800031e6:	b59ff0ef          	jal	80002d3e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800031ea:	0905                	addi	s2,s2,1
    800031ec:	00ca2703          	lw	a4,12(s4)
    800031f0:	0009079b          	sext.w	a5,s2
    800031f4:	fce7e7e3          	bltu	a5,a4,800031c2 <ialloc+0x30>
    800031f8:	74a2                	ld	s1,40(sp)
    800031fa:	7902                	ld	s2,32(sp)
    800031fc:	69e2                	ld	s3,24(sp)
    800031fe:	6a42                	ld	s4,16(sp)
    80003200:	6aa2                	ld	s5,8(sp)
    80003202:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    80003204:	00004517          	auipc	a0,0x4
    80003208:	22c50513          	addi	a0,a0,556 # 80007430 <etext+0x430>
    8000320c:	aeefd0ef          	jal	800004fa <printf>
  return 0;
    80003210:	4501                	li	a0,0
}
    80003212:	70e2                	ld	ra,56(sp)
    80003214:	7442                	ld	s0,48(sp)
    80003216:	6121                	addi	sp,sp,64
    80003218:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000321a:	04000613          	li	a2,64
    8000321e:	4581                	li	a1,0
    80003220:	854e                	mv	a0,s3
    80003222:	a81fd0ef          	jal	80000ca2 <memset>
      dip->type = type;
    80003226:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000322a:	8526                	mv	a0,s1
    8000322c:	445000ef          	jal	80003e70 <log_write>
      brelse(bp);
    80003230:	8526                	mv	a0,s1
    80003232:	b0dff0ef          	jal	80002d3e <brelse>
      return iget(dev, inum);
    80003236:	0009059b          	sext.w	a1,s2
    8000323a:	8556                	mv	a0,s5
    8000323c:	e53ff0ef          	jal	8000308e <iget>
    80003240:	74a2                	ld	s1,40(sp)
    80003242:	7902                	ld	s2,32(sp)
    80003244:	69e2                	ld	s3,24(sp)
    80003246:	6a42                	ld	s4,16(sp)
    80003248:	6aa2                	ld	s5,8(sp)
    8000324a:	6b02                	ld	s6,0(sp)
    8000324c:	b7d9                	j	80003212 <ialloc+0x80>

000000008000324e <iupdate>:
{
    8000324e:	1101                	addi	sp,sp,-32
    80003250:	ec06                	sd	ra,24(sp)
    80003252:	e822                	sd	s0,16(sp)
    80003254:	e426                	sd	s1,8(sp)
    80003256:	e04a                	sd	s2,0(sp)
    80003258:	1000                	addi	s0,sp,32
    8000325a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000325c:	415c                	lw	a5,4(a0)
    8000325e:	0047d79b          	srliw	a5,a5,0x4
    80003262:	0001d597          	auipc	a1,0x1d
    80003266:	7f65a583          	lw	a1,2038(a1) # 80020a58 <sb+0x18>
    8000326a:	9dbd                	addw	a1,a1,a5
    8000326c:	4108                	lw	a0,0(a0)
    8000326e:	9c9ff0ef          	jal	80002c36 <bread>
    80003272:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003274:	05850793          	addi	a5,a0,88
    80003278:	40d8                	lw	a4,4(s1)
    8000327a:	8b3d                	andi	a4,a4,15
    8000327c:	071a                	slli	a4,a4,0x6
    8000327e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003280:	04449703          	lh	a4,68(s1)
    80003284:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003288:	04649703          	lh	a4,70(s1)
    8000328c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003290:	04849703          	lh	a4,72(s1)
    80003294:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003298:	04a49703          	lh	a4,74(s1)
    8000329c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800032a0:	44f8                	lw	a4,76(s1)
    800032a2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800032a4:	03400613          	li	a2,52
    800032a8:	05048593          	addi	a1,s1,80
    800032ac:	00c78513          	addi	a0,a5,12
    800032b0:	a4ffd0ef          	jal	80000cfe <memmove>
  log_write(bp);
    800032b4:	854a                	mv	a0,s2
    800032b6:	3bb000ef          	jal	80003e70 <log_write>
  brelse(bp);
    800032ba:	854a                	mv	a0,s2
    800032bc:	a83ff0ef          	jal	80002d3e <brelse>
}
    800032c0:	60e2                	ld	ra,24(sp)
    800032c2:	6442                	ld	s0,16(sp)
    800032c4:	64a2                	ld	s1,8(sp)
    800032c6:	6902                	ld	s2,0(sp)
    800032c8:	6105                	addi	sp,sp,32
    800032ca:	8082                	ret

00000000800032cc <idup>:
{
    800032cc:	1101                	addi	sp,sp,-32
    800032ce:	ec06                	sd	ra,24(sp)
    800032d0:	e822                	sd	s0,16(sp)
    800032d2:	e426                	sd	s1,8(sp)
    800032d4:	1000                	addi	s0,sp,32
    800032d6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800032d8:	0001d517          	auipc	a0,0x1d
    800032dc:	78850513          	addi	a0,a0,1928 # 80020a60 <itable>
    800032e0:	8effd0ef          	jal	80000bce <acquire>
  ip->ref++;
    800032e4:	449c                	lw	a5,8(s1)
    800032e6:	2785                	addiw	a5,a5,1
    800032e8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800032ea:	0001d517          	auipc	a0,0x1d
    800032ee:	77650513          	addi	a0,a0,1910 # 80020a60 <itable>
    800032f2:	975fd0ef          	jal	80000c66 <release>
}
    800032f6:	8526                	mv	a0,s1
    800032f8:	60e2                	ld	ra,24(sp)
    800032fa:	6442                	ld	s0,16(sp)
    800032fc:	64a2                	ld	s1,8(sp)
    800032fe:	6105                	addi	sp,sp,32
    80003300:	8082                	ret

0000000080003302 <ilock>:
{
    80003302:	1101                	addi	sp,sp,-32
    80003304:	ec06                	sd	ra,24(sp)
    80003306:	e822                	sd	s0,16(sp)
    80003308:	e426                	sd	s1,8(sp)
    8000330a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000330c:	cd19                	beqz	a0,8000332a <ilock+0x28>
    8000330e:	84aa                	mv	s1,a0
    80003310:	451c                	lw	a5,8(a0)
    80003312:	00f05c63          	blez	a5,8000332a <ilock+0x28>
  acquiresleep(&ip->lock);
    80003316:	0541                	addi	a0,a0,16
    80003318:	451000ef          	jal	80003f68 <acquiresleep>
  if(ip->valid == 0){
    8000331c:	40bc                	lw	a5,64(s1)
    8000331e:	cf89                	beqz	a5,80003338 <ilock+0x36>
}
    80003320:	60e2                	ld	ra,24(sp)
    80003322:	6442                	ld	s0,16(sp)
    80003324:	64a2                	ld	s1,8(sp)
    80003326:	6105                	addi	sp,sp,32
    80003328:	8082                	ret
    8000332a:	e04a                	sd	s2,0(sp)
    panic("ilock");
    8000332c:	00004517          	auipc	a0,0x4
    80003330:	11c50513          	addi	a0,a0,284 # 80007448 <etext+0x448>
    80003334:	cacfd0ef          	jal	800007e0 <panic>
    80003338:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000333a:	40dc                	lw	a5,4(s1)
    8000333c:	0047d79b          	srliw	a5,a5,0x4
    80003340:	0001d597          	auipc	a1,0x1d
    80003344:	7185a583          	lw	a1,1816(a1) # 80020a58 <sb+0x18>
    80003348:	9dbd                	addw	a1,a1,a5
    8000334a:	4088                	lw	a0,0(s1)
    8000334c:	8ebff0ef          	jal	80002c36 <bread>
    80003350:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003352:	05850593          	addi	a1,a0,88
    80003356:	40dc                	lw	a5,4(s1)
    80003358:	8bbd                	andi	a5,a5,15
    8000335a:	079a                	slli	a5,a5,0x6
    8000335c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000335e:	00059783          	lh	a5,0(a1)
    80003362:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003366:	00259783          	lh	a5,2(a1)
    8000336a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000336e:	00459783          	lh	a5,4(a1)
    80003372:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003376:	00659783          	lh	a5,6(a1)
    8000337a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000337e:	459c                	lw	a5,8(a1)
    80003380:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003382:	03400613          	li	a2,52
    80003386:	05b1                	addi	a1,a1,12
    80003388:	05048513          	addi	a0,s1,80
    8000338c:	973fd0ef          	jal	80000cfe <memmove>
    brelse(bp);
    80003390:	854a                	mv	a0,s2
    80003392:	9adff0ef          	jal	80002d3e <brelse>
    ip->valid = 1;
    80003396:	4785                	li	a5,1
    80003398:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000339a:	04449783          	lh	a5,68(s1)
    8000339e:	c399                	beqz	a5,800033a4 <ilock+0xa2>
    800033a0:	6902                	ld	s2,0(sp)
    800033a2:	bfbd                	j	80003320 <ilock+0x1e>
      panic("ilock: no type");
    800033a4:	00004517          	auipc	a0,0x4
    800033a8:	0ac50513          	addi	a0,a0,172 # 80007450 <etext+0x450>
    800033ac:	c34fd0ef          	jal	800007e0 <panic>

00000000800033b0 <iunlock>:
{
    800033b0:	1101                	addi	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	e426                	sd	s1,8(sp)
    800033b8:	e04a                	sd	s2,0(sp)
    800033ba:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800033bc:	c505                	beqz	a0,800033e4 <iunlock+0x34>
    800033be:	84aa                	mv	s1,a0
    800033c0:	01050913          	addi	s2,a0,16
    800033c4:	854a                	mv	a0,s2
    800033c6:	421000ef          	jal	80003fe6 <holdingsleep>
    800033ca:	cd09                	beqz	a0,800033e4 <iunlock+0x34>
    800033cc:	449c                	lw	a5,8(s1)
    800033ce:	00f05b63          	blez	a5,800033e4 <iunlock+0x34>
  releasesleep(&ip->lock);
    800033d2:	854a                	mv	a0,s2
    800033d4:	3db000ef          	jal	80003fae <releasesleep>
}
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	64a2                	ld	s1,8(sp)
    800033de:	6902                	ld	s2,0(sp)
    800033e0:	6105                	addi	sp,sp,32
    800033e2:	8082                	ret
    panic("iunlock");
    800033e4:	00004517          	auipc	a0,0x4
    800033e8:	07c50513          	addi	a0,a0,124 # 80007460 <etext+0x460>
    800033ec:	bf4fd0ef          	jal	800007e0 <panic>

00000000800033f0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800033f0:	7179                	addi	sp,sp,-48
    800033f2:	f406                	sd	ra,40(sp)
    800033f4:	f022                	sd	s0,32(sp)
    800033f6:	ec26                	sd	s1,24(sp)
    800033f8:	e84a                	sd	s2,16(sp)
    800033fa:	e44e                	sd	s3,8(sp)
    800033fc:	1800                	addi	s0,sp,48
    800033fe:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003400:	05050493          	addi	s1,a0,80
    80003404:	08050913          	addi	s2,a0,128
    80003408:	a021                	j	80003410 <itrunc+0x20>
    8000340a:	0491                	addi	s1,s1,4
    8000340c:	01248b63          	beq	s1,s2,80003422 <itrunc+0x32>
    if(ip->addrs[i]){
    80003410:	408c                	lw	a1,0(s1)
    80003412:	dde5                	beqz	a1,8000340a <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    80003414:	0009a503          	lw	a0,0(s3)
    80003418:	a17ff0ef          	jal	80002e2e <bfree>
      ip->addrs[i] = 0;
    8000341c:	0004a023          	sw	zero,0(s1)
    80003420:	b7ed                	j	8000340a <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003422:	0809a583          	lw	a1,128(s3)
    80003426:	ed89                	bnez	a1,80003440 <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003428:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000342c:	854e                	mv	a0,s3
    8000342e:	e21ff0ef          	jal	8000324e <iupdate>
}
    80003432:	70a2                	ld	ra,40(sp)
    80003434:	7402                	ld	s0,32(sp)
    80003436:	64e2                	ld	s1,24(sp)
    80003438:	6942                	ld	s2,16(sp)
    8000343a:	69a2                	ld	s3,8(sp)
    8000343c:	6145                	addi	sp,sp,48
    8000343e:	8082                	ret
    80003440:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003442:	0009a503          	lw	a0,0(s3)
    80003446:	ff0ff0ef          	jal	80002c36 <bread>
    8000344a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000344c:	05850493          	addi	s1,a0,88
    80003450:	45850913          	addi	s2,a0,1112
    80003454:	a021                	j	8000345c <itrunc+0x6c>
    80003456:	0491                	addi	s1,s1,4
    80003458:	01248963          	beq	s1,s2,8000346a <itrunc+0x7a>
      if(a[j])
    8000345c:	408c                	lw	a1,0(s1)
    8000345e:	dde5                	beqz	a1,80003456 <itrunc+0x66>
        bfree(ip->dev, a[j]);
    80003460:	0009a503          	lw	a0,0(s3)
    80003464:	9cbff0ef          	jal	80002e2e <bfree>
    80003468:	b7fd                	j	80003456 <itrunc+0x66>
    brelse(bp);
    8000346a:	8552                	mv	a0,s4
    8000346c:	8d3ff0ef          	jal	80002d3e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003470:	0809a583          	lw	a1,128(s3)
    80003474:	0009a503          	lw	a0,0(s3)
    80003478:	9b7ff0ef          	jal	80002e2e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000347c:	0809a023          	sw	zero,128(s3)
    80003480:	6a02                	ld	s4,0(sp)
    80003482:	b75d                	j	80003428 <itrunc+0x38>

0000000080003484 <iput>:
{
    80003484:	1101                	addi	sp,sp,-32
    80003486:	ec06                	sd	ra,24(sp)
    80003488:	e822                	sd	s0,16(sp)
    8000348a:	e426                	sd	s1,8(sp)
    8000348c:	1000                	addi	s0,sp,32
    8000348e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003490:	0001d517          	auipc	a0,0x1d
    80003494:	5d050513          	addi	a0,a0,1488 # 80020a60 <itable>
    80003498:	f36fd0ef          	jal	80000bce <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000349c:	4498                	lw	a4,8(s1)
    8000349e:	4785                	li	a5,1
    800034a0:	02f70063          	beq	a4,a5,800034c0 <iput+0x3c>
  ip->ref--;
    800034a4:	449c                	lw	a5,8(s1)
    800034a6:	37fd                	addiw	a5,a5,-1
    800034a8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800034aa:	0001d517          	auipc	a0,0x1d
    800034ae:	5b650513          	addi	a0,a0,1462 # 80020a60 <itable>
    800034b2:	fb4fd0ef          	jal	80000c66 <release>
}
    800034b6:	60e2                	ld	ra,24(sp)
    800034b8:	6442                	ld	s0,16(sp)
    800034ba:	64a2                	ld	s1,8(sp)
    800034bc:	6105                	addi	sp,sp,32
    800034be:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800034c0:	40bc                	lw	a5,64(s1)
    800034c2:	d3ed                	beqz	a5,800034a4 <iput+0x20>
    800034c4:	04a49783          	lh	a5,74(s1)
    800034c8:	fff1                	bnez	a5,800034a4 <iput+0x20>
    800034ca:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    800034cc:	01048913          	addi	s2,s1,16
    800034d0:	854a                	mv	a0,s2
    800034d2:	297000ef          	jal	80003f68 <acquiresleep>
    release(&itable.lock);
    800034d6:	0001d517          	auipc	a0,0x1d
    800034da:	58a50513          	addi	a0,a0,1418 # 80020a60 <itable>
    800034de:	f88fd0ef          	jal	80000c66 <release>
    itrunc(ip);
    800034e2:	8526                	mv	a0,s1
    800034e4:	f0dff0ef          	jal	800033f0 <itrunc>
    ip->type = 0;
    800034e8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800034ec:	8526                	mv	a0,s1
    800034ee:	d61ff0ef          	jal	8000324e <iupdate>
    ip->valid = 0;
    800034f2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800034f6:	854a                	mv	a0,s2
    800034f8:	2b7000ef          	jal	80003fae <releasesleep>
    acquire(&itable.lock);
    800034fc:	0001d517          	auipc	a0,0x1d
    80003500:	56450513          	addi	a0,a0,1380 # 80020a60 <itable>
    80003504:	ecafd0ef          	jal	80000bce <acquire>
    80003508:	6902                	ld	s2,0(sp)
    8000350a:	bf69                	j	800034a4 <iput+0x20>

000000008000350c <iunlockput>:
{
    8000350c:	1101                	addi	sp,sp,-32
    8000350e:	ec06                	sd	ra,24(sp)
    80003510:	e822                	sd	s0,16(sp)
    80003512:	e426                	sd	s1,8(sp)
    80003514:	1000                	addi	s0,sp,32
    80003516:	84aa                	mv	s1,a0
  iunlock(ip);
    80003518:	e99ff0ef          	jal	800033b0 <iunlock>
  iput(ip);
    8000351c:	8526                	mv	a0,s1
    8000351e:	f67ff0ef          	jal	80003484 <iput>
}
    80003522:	60e2                	ld	ra,24(sp)
    80003524:	6442                	ld	s0,16(sp)
    80003526:	64a2                	ld	s1,8(sp)
    80003528:	6105                	addi	sp,sp,32
    8000352a:	8082                	ret

000000008000352c <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000352c:	0001d717          	auipc	a4,0x1d
    80003530:	52072703          	lw	a4,1312(a4) # 80020a4c <sb+0xc>
    80003534:	4785                	li	a5,1
    80003536:	0ae7ff63          	bgeu	a5,a4,800035f4 <ireclaim+0xc8>
{
    8000353a:	7139                	addi	sp,sp,-64
    8000353c:	fc06                	sd	ra,56(sp)
    8000353e:	f822                	sd	s0,48(sp)
    80003540:	f426                	sd	s1,40(sp)
    80003542:	f04a                	sd	s2,32(sp)
    80003544:	ec4e                	sd	s3,24(sp)
    80003546:	e852                	sd	s4,16(sp)
    80003548:	e456                	sd	s5,8(sp)
    8000354a:	e05a                	sd	s6,0(sp)
    8000354c:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000354e:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003550:	00050a1b          	sext.w	s4,a0
    80003554:	0001da97          	auipc	s5,0x1d
    80003558:	4eca8a93          	addi	s5,s5,1260 # 80020a40 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    8000355c:	00004b17          	auipc	s6,0x4
    80003560:	f0cb0b13          	addi	s6,s6,-244 # 80007468 <etext+0x468>
    80003564:	a099                	j	800035aa <ireclaim+0x7e>
    80003566:	85ce                	mv	a1,s3
    80003568:	855a                	mv	a0,s6
    8000356a:	f91fc0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    8000356e:	85ce                	mv	a1,s3
    80003570:	8552                	mv	a0,s4
    80003572:	b1dff0ef          	jal	8000308e <iget>
    80003576:	89aa                	mv	s3,a0
    brelse(bp);
    80003578:	854a                	mv	a0,s2
    8000357a:	fc4ff0ef          	jal	80002d3e <brelse>
    if (ip) {
    8000357e:	00098f63          	beqz	s3,8000359c <ireclaim+0x70>
      begin_op();
    80003582:	76a000ef          	jal	80003cec <begin_op>
      ilock(ip);
    80003586:	854e                	mv	a0,s3
    80003588:	d7bff0ef          	jal	80003302 <ilock>
      iunlock(ip);
    8000358c:	854e                	mv	a0,s3
    8000358e:	e23ff0ef          	jal	800033b0 <iunlock>
      iput(ip);
    80003592:	854e                	mv	a0,s3
    80003594:	ef1ff0ef          	jal	80003484 <iput>
      end_op();
    80003598:	7be000ef          	jal	80003d56 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000359c:	0485                	addi	s1,s1,1
    8000359e:	00caa703          	lw	a4,12(s5)
    800035a2:	0004879b          	sext.w	a5,s1
    800035a6:	02e7fd63          	bgeu	a5,a4,800035e0 <ireclaim+0xb4>
    800035aa:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800035ae:	0044d593          	srli	a1,s1,0x4
    800035b2:	018aa783          	lw	a5,24(s5)
    800035b6:	9dbd                	addw	a1,a1,a5
    800035b8:	8552                	mv	a0,s4
    800035ba:	e7cff0ef          	jal	80002c36 <bread>
    800035be:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    800035c0:	05850793          	addi	a5,a0,88
    800035c4:	00f9f713          	andi	a4,s3,15
    800035c8:	071a                	slli	a4,a4,0x6
    800035ca:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    800035cc:	00079703          	lh	a4,0(a5)
    800035d0:	c701                	beqz	a4,800035d8 <ireclaim+0xac>
    800035d2:	00679783          	lh	a5,6(a5)
    800035d6:	dbc1                	beqz	a5,80003566 <ireclaim+0x3a>
    brelse(bp);
    800035d8:	854a                	mv	a0,s2
    800035da:	f64ff0ef          	jal	80002d3e <brelse>
    if (ip) {
    800035de:	bf7d                	j	8000359c <ireclaim+0x70>
}
    800035e0:	70e2                	ld	ra,56(sp)
    800035e2:	7442                	ld	s0,48(sp)
    800035e4:	74a2                	ld	s1,40(sp)
    800035e6:	7902                	ld	s2,32(sp)
    800035e8:	69e2                	ld	s3,24(sp)
    800035ea:	6a42                	ld	s4,16(sp)
    800035ec:	6aa2                	ld	s5,8(sp)
    800035ee:	6b02                	ld	s6,0(sp)
    800035f0:	6121                	addi	sp,sp,64
    800035f2:	8082                	ret
    800035f4:	8082                	ret

00000000800035f6 <fsinit>:
fsinit(int dev) {
    800035f6:	7179                	addi	sp,sp,-48
    800035f8:	f406                	sd	ra,40(sp)
    800035fa:	f022                	sd	s0,32(sp)
    800035fc:	ec26                	sd	s1,24(sp)
    800035fe:	e84a                	sd	s2,16(sp)
    80003600:	e44e                	sd	s3,8(sp)
    80003602:	1800                	addi	s0,sp,48
    80003604:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    80003606:	4585                	li	a1,1
    80003608:	e2eff0ef          	jal	80002c36 <bread>
    8000360c:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000360e:	0001d997          	auipc	s3,0x1d
    80003612:	43298993          	addi	s3,s3,1074 # 80020a40 <sb>
    80003616:	02000613          	li	a2,32
    8000361a:	05850593          	addi	a1,a0,88
    8000361e:	854e                	mv	a0,s3
    80003620:	edefd0ef          	jal	80000cfe <memmove>
  brelse(bp);
    80003624:	854a                	mv	a0,s2
    80003626:	f18ff0ef          	jal	80002d3e <brelse>
  if(sb.magic != FSMAGIC)
    8000362a:	0009a703          	lw	a4,0(s3)
    8000362e:	102037b7          	lui	a5,0x10203
    80003632:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003636:	02f71363          	bne	a4,a5,8000365c <fsinit+0x66>
  initlog(dev, &sb);
    8000363a:	0001d597          	auipc	a1,0x1d
    8000363e:	40658593          	addi	a1,a1,1030 # 80020a40 <sb>
    80003642:	8526                	mv	a0,s1
    80003644:	62a000ef          	jal	80003c6e <initlog>
  ireclaim(dev);
    80003648:	8526                	mv	a0,s1
    8000364a:	ee3ff0ef          	jal	8000352c <ireclaim>
}
    8000364e:	70a2                	ld	ra,40(sp)
    80003650:	7402                	ld	s0,32(sp)
    80003652:	64e2                	ld	s1,24(sp)
    80003654:	6942                	ld	s2,16(sp)
    80003656:	69a2                	ld	s3,8(sp)
    80003658:	6145                	addi	sp,sp,48
    8000365a:	8082                	ret
    panic("invalid file system");
    8000365c:	00004517          	auipc	a0,0x4
    80003660:	e2c50513          	addi	a0,a0,-468 # 80007488 <etext+0x488>
    80003664:	97cfd0ef          	jal	800007e0 <panic>

0000000080003668 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003668:	1141                	addi	sp,sp,-16
    8000366a:	e422                	sd	s0,8(sp)
    8000366c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000366e:	411c                	lw	a5,0(a0)
    80003670:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003672:	415c                	lw	a5,4(a0)
    80003674:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003676:	04451783          	lh	a5,68(a0)
    8000367a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000367e:	04a51783          	lh	a5,74(a0)
    80003682:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003686:	04c56783          	lwu	a5,76(a0)
    8000368a:	e99c                	sd	a5,16(a1)
}
    8000368c:	6422                	ld	s0,8(sp)
    8000368e:	0141                	addi	sp,sp,16
    80003690:	8082                	ret

0000000080003692 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003692:	457c                	lw	a5,76(a0)
    80003694:	0ed7eb63          	bltu	a5,a3,8000378a <readi+0xf8>
{
    80003698:	7159                	addi	sp,sp,-112
    8000369a:	f486                	sd	ra,104(sp)
    8000369c:	f0a2                	sd	s0,96(sp)
    8000369e:	eca6                	sd	s1,88(sp)
    800036a0:	e0d2                	sd	s4,64(sp)
    800036a2:	fc56                	sd	s5,56(sp)
    800036a4:	f85a                	sd	s6,48(sp)
    800036a6:	f45e                	sd	s7,40(sp)
    800036a8:	1880                	addi	s0,sp,112
    800036aa:	8b2a                	mv	s6,a0
    800036ac:	8bae                	mv	s7,a1
    800036ae:	8a32                	mv	s4,a2
    800036b0:	84b6                	mv	s1,a3
    800036b2:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800036b4:	9f35                	addw	a4,a4,a3
    return 0;
    800036b6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800036b8:	0cd76063          	bltu	a4,a3,80003778 <readi+0xe6>
    800036bc:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    800036be:	00e7f463          	bgeu	a5,a4,800036c6 <readi+0x34>
    n = ip->size - off;
    800036c2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800036c6:	080a8f63          	beqz	s5,80003764 <readi+0xd2>
    800036ca:	e8ca                	sd	s2,80(sp)
    800036cc:	f062                	sd	s8,32(sp)
    800036ce:	ec66                	sd	s9,24(sp)
    800036d0:	e86a                	sd	s10,16(sp)
    800036d2:	e46e                	sd	s11,8(sp)
    800036d4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800036d6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800036da:	5c7d                	li	s8,-1
    800036dc:	a80d                	j	8000370e <readi+0x7c>
    800036de:	020d1d93          	slli	s11,s10,0x20
    800036e2:	020ddd93          	srli	s11,s11,0x20
    800036e6:	05890613          	addi	a2,s2,88
    800036ea:	86ee                	mv	a3,s11
    800036ec:	963a                	add	a2,a2,a4
    800036ee:	85d2                	mv	a1,s4
    800036f0:	855e                	mv	a0,s7
    800036f2:	c29fe0ef          	jal	8000231a <either_copyout>
    800036f6:	05850763          	beq	a0,s8,80003744 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800036fa:	854a                	mv	a0,s2
    800036fc:	e42ff0ef          	jal	80002d3e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003700:	013d09bb          	addw	s3,s10,s3
    80003704:	009d04bb          	addw	s1,s10,s1
    80003708:	9a6e                	add	s4,s4,s11
    8000370a:	0559f763          	bgeu	s3,s5,80003758 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    8000370e:	00a4d59b          	srliw	a1,s1,0xa
    80003712:	855a                	mv	a0,s6
    80003714:	8a7ff0ef          	jal	80002fba <bmap>
    80003718:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000371c:	c5b1                	beqz	a1,80003768 <readi+0xd6>
    bp = bread(ip->dev, addr);
    8000371e:	000b2503          	lw	a0,0(s6)
    80003722:	d14ff0ef          	jal	80002c36 <bread>
    80003726:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003728:	3ff4f713          	andi	a4,s1,1023
    8000372c:	40ec87bb          	subw	a5,s9,a4
    80003730:	413a86bb          	subw	a3,s5,s3
    80003734:	8d3e                	mv	s10,a5
    80003736:	2781                	sext.w	a5,a5
    80003738:	0006861b          	sext.w	a2,a3
    8000373c:	faf671e3          	bgeu	a2,a5,800036de <readi+0x4c>
    80003740:	8d36                	mv	s10,a3
    80003742:	bf71                	j	800036de <readi+0x4c>
      brelse(bp);
    80003744:	854a                	mv	a0,s2
    80003746:	df8ff0ef          	jal	80002d3e <brelse>
      tot = -1;
    8000374a:	59fd                	li	s3,-1
      break;
    8000374c:	6946                	ld	s2,80(sp)
    8000374e:	7c02                	ld	s8,32(sp)
    80003750:	6ce2                	ld	s9,24(sp)
    80003752:	6d42                	ld	s10,16(sp)
    80003754:	6da2                	ld	s11,8(sp)
    80003756:	a831                	j	80003772 <readi+0xe0>
    80003758:	6946                	ld	s2,80(sp)
    8000375a:	7c02                	ld	s8,32(sp)
    8000375c:	6ce2                	ld	s9,24(sp)
    8000375e:	6d42                	ld	s10,16(sp)
    80003760:	6da2                	ld	s11,8(sp)
    80003762:	a801                	j	80003772 <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003764:	89d6                	mv	s3,s5
    80003766:	a031                	j	80003772 <readi+0xe0>
    80003768:	6946                	ld	s2,80(sp)
    8000376a:	7c02                	ld	s8,32(sp)
    8000376c:	6ce2                	ld	s9,24(sp)
    8000376e:	6d42                	ld	s10,16(sp)
    80003770:	6da2                	ld	s11,8(sp)
  }
  return tot;
    80003772:	0009851b          	sext.w	a0,s3
    80003776:	69a6                	ld	s3,72(sp)
}
    80003778:	70a6                	ld	ra,104(sp)
    8000377a:	7406                	ld	s0,96(sp)
    8000377c:	64e6                	ld	s1,88(sp)
    8000377e:	6a06                	ld	s4,64(sp)
    80003780:	7ae2                	ld	s5,56(sp)
    80003782:	7b42                	ld	s6,48(sp)
    80003784:	7ba2                	ld	s7,40(sp)
    80003786:	6165                	addi	sp,sp,112
    80003788:	8082                	ret
    return 0;
    8000378a:	4501                	li	a0,0
}
    8000378c:	8082                	ret

000000008000378e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000378e:	457c                	lw	a5,76(a0)
    80003790:	10d7e063          	bltu	a5,a3,80003890 <writei+0x102>
{
    80003794:	7159                	addi	sp,sp,-112
    80003796:	f486                	sd	ra,104(sp)
    80003798:	f0a2                	sd	s0,96(sp)
    8000379a:	e8ca                	sd	s2,80(sp)
    8000379c:	e0d2                	sd	s4,64(sp)
    8000379e:	fc56                	sd	s5,56(sp)
    800037a0:	f85a                	sd	s6,48(sp)
    800037a2:	f45e                	sd	s7,40(sp)
    800037a4:	1880                	addi	s0,sp,112
    800037a6:	8aaa                	mv	s5,a0
    800037a8:	8bae                	mv	s7,a1
    800037aa:	8a32                	mv	s4,a2
    800037ac:	8936                	mv	s2,a3
    800037ae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800037b0:	00e687bb          	addw	a5,a3,a4
    800037b4:	0ed7e063          	bltu	a5,a3,80003894 <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800037b8:	00043737          	lui	a4,0x43
    800037bc:	0cf76e63          	bltu	a4,a5,80003898 <writei+0x10a>
    800037c0:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800037c2:	0a0b0f63          	beqz	s6,80003880 <writei+0xf2>
    800037c6:	eca6                	sd	s1,88(sp)
    800037c8:	f062                	sd	s8,32(sp)
    800037ca:	ec66                	sd	s9,24(sp)
    800037cc:	e86a                	sd	s10,16(sp)
    800037ce:	e46e                	sd	s11,8(sp)
    800037d0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800037d2:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800037d6:	5c7d                	li	s8,-1
    800037d8:	a825                	j	80003810 <writei+0x82>
    800037da:	020d1d93          	slli	s11,s10,0x20
    800037de:	020ddd93          	srli	s11,s11,0x20
    800037e2:	05848513          	addi	a0,s1,88
    800037e6:	86ee                	mv	a3,s11
    800037e8:	8652                	mv	a2,s4
    800037ea:	85de                	mv	a1,s7
    800037ec:	953a                	add	a0,a0,a4
    800037ee:	b77fe0ef          	jal	80002364 <either_copyin>
    800037f2:	05850a63          	beq	a0,s8,80003846 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    800037f6:	8526                	mv	a0,s1
    800037f8:	678000ef          	jal	80003e70 <log_write>
    brelse(bp);
    800037fc:	8526                	mv	a0,s1
    800037fe:	d40ff0ef          	jal	80002d3e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003802:	013d09bb          	addw	s3,s10,s3
    80003806:	012d093b          	addw	s2,s10,s2
    8000380a:	9a6e                	add	s4,s4,s11
    8000380c:	0569f063          	bgeu	s3,s6,8000384c <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003810:	00a9559b          	srliw	a1,s2,0xa
    80003814:	8556                	mv	a0,s5
    80003816:	fa4ff0ef          	jal	80002fba <bmap>
    8000381a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000381e:	c59d                	beqz	a1,8000384c <writei+0xbe>
    bp = bread(ip->dev, addr);
    80003820:	000aa503          	lw	a0,0(s5)
    80003824:	c12ff0ef          	jal	80002c36 <bread>
    80003828:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000382a:	3ff97713          	andi	a4,s2,1023
    8000382e:	40ec87bb          	subw	a5,s9,a4
    80003832:	413b06bb          	subw	a3,s6,s3
    80003836:	8d3e                	mv	s10,a5
    80003838:	2781                	sext.w	a5,a5
    8000383a:	0006861b          	sext.w	a2,a3
    8000383e:	f8f67ee3          	bgeu	a2,a5,800037da <writei+0x4c>
    80003842:	8d36                	mv	s10,a3
    80003844:	bf59                	j	800037da <writei+0x4c>
      brelse(bp);
    80003846:	8526                	mv	a0,s1
    80003848:	cf6ff0ef          	jal	80002d3e <brelse>
  }

  if(off > ip->size)
    8000384c:	04caa783          	lw	a5,76(s5)
    80003850:	0327fa63          	bgeu	a5,s2,80003884 <writei+0xf6>
    ip->size = off;
    80003854:	052aa623          	sw	s2,76(s5)
    80003858:	64e6                	ld	s1,88(sp)
    8000385a:	7c02                	ld	s8,32(sp)
    8000385c:	6ce2                	ld	s9,24(sp)
    8000385e:	6d42                	ld	s10,16(sp)
    80003860:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003862:	8556                	mv	a0,s5
    80003864:	9ebff0ef          	jal	8000324e <iupdate>

  return tot;
    80003868:	0009851b          	sext.w	a0,s3
    8000386c:	69a6                	ld	s3,72(sp)
}
    8000386e:	70a6                	ld	ra,104(sp)
    80003870:	7406                	ld	s0,96(sp)
    80003872:	6946                	ld	s2,80(sp)
    80003874:	6a06                	ld	s4,64(sp)
    80003876:	7ae2                	ld	s5,56(sp)
    80003878:	7b42                	ld	s6,48(sp)
    8000387a:	7ba2                	ld	s7,40(sp)
    8000387c:	6165                	addi	sp,sp,112
    8000387e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003880:	89da                	mv	s3,s6
    80003882:	b7c5                	j	80003862 <writei+0xd4>
    80003884:	64e6                	ld	s1,88(sp)
    80003886:	7c02                	ld	s8,32(sp)
    80003888:	6ce2                	ld	s9,24(sp)
    8000388a:	6d42                	ld	s10,16(sp)
    8000388c:	6da2                	ld	s11,8(sp)
    8000388e:	bfd1                	j	80003862 <writei+0xd4>
    return -1;
    80003890:	557d                	li	a0,-1
}
    80003892:	8082                	ret
    return -1;
    80003894:	557d                	li	a0,-1
    80003896:	bfe1                	j	8000386e <writei+0xe0>
    return -1;
    80003898:	557d                	li	a0,-1
    8000389a:	bfd1                	j	8000386e <writei+0xe0>

000000008000389c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000389c:	1141                	addi	sp,sp,-16
    8000389e:	e406                	sd	ra,8(sp)
    800038a0:	e022                	sd	s0,0(sp)
    800038a2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800038a4:	4639                	li	a2,14
    800038a6:	cc8fd0ef          	jal	80000d6e <strncmp>
}
    800038aa:	60a2                	ld	ra,8(sp)
    800038ac:	6402                	ld	s0,0(sp)
    800038ae:	0141                	addi	sp,sp,16
    800038b0:	8082                	ret

00000000800038b2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800038b2:	7139                	addi	sp,sp,-64
    800038b4:	fc06                	sd	ra,56(sp)
    800038b6:	f822                	sd	s0,48(sp)
    800038b8:	f426                	sd	s1,40(sp)
    800038ba:	f04a                	sd	s2,32(sp)
    800038bc:	ec4e                	sd	s3,24(sp)
    800038be:	e852                	sd	s4,16(sp)
    800038c0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800038c2:	04451703          	lh	a4,68(a0)
    800038c6:	4785                	li	a5,1
    800038c8:	00f71a63          	bne	a4,a5,800038dc <dirlookup+0x2a>
    800038cc:	892a                	mv	s2,a0
    800038ce:	89ae                	mv	s3,a1
    800038d0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800038d2:	457c                	lw	a5,76(a0)
    800038d4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800038d6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800038d8:	e39d                	bnez	a5,800038fe <dirlookup+0x4c>
    800038da:	a095                	j	8000393e <dirlookup+0x8c>
    panic("dirlookup not DIR");
    800038dc:	00004517          	auipc	a0,0x4
    800038e0:	bc450513          	addi	a0,a0,-1084 # 800074a0 <etext+0x4a0>
    800038e4:	efdfc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    800038e8:	00004517          	auipc	a0,0x4
    800038ec:	bd050513          	addi	a0,a0,-1072 # 800074b8 <etext+0x4b8>
    800038f0:	ef1fc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800038f4:	24c1                	addiw	s1,s1,16
    800038f6:	04c92783          	lw	a5,76(s2)
    800038fa:	04f4f163          	bgeu	s1,a5,8000393c <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800038fe:	4741                	li	a4,16
    80003900:	86a6                	mv	a3,s1
    80003902:	fc040613          	addi	a2,s0,-64
    80003906:	4581                	li	a1,0
    80003908:	854a                	mv	a0,s2
    8000390a:	d89ff0ef          	jal	80003692 <readi>
    8000390e:	47c1                	li	a5,16
    80003910:	fcf51ce3          	bne	a0,a5,800038e8 <dirlookup+0x36>
    if(de.inum == 0)
    80003914:	fc045783          	lhu	a5,-64(s0)
    80003918:	dff1                	beqz	a5,800038f4 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    8000391a:	fc240593          	addi	a1,s0,-62
    8000391e:	854e                	mv	a0,s3
    80003920:	f7dff0ef          	jal	8000389c <namecmp>
    80003924:	f961                	bnez	a0,800038f4 <dirlookup+0x42>
      if(poff)
    80003926:	000a0463          	beqz	s4,8000392e <dirlookup+0x7c>
        *poff = off;
    8000392a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000392e:	fc045583          	lhu	a1,-64(s0)
    80003932:	00092503          	lw	a0,0(s2)
    80003936:	f58ff0ef          	jal	8000308e <iget>
    8000393a:	a011                	j	8000393e <dirlookup+0x8c>
  return 0;
    8000393c:	4501                	li	a0,0
}
    8000393e:	70e2                	ld	ra,56(sp)
    80003940:	7442                	ld	s0,48(sp)
    80003942:	74a2                	ld	s1,40(sp)
    80003944:	7902                	ld	s2,32(sp)
    80003946:	69e2                	ld	s3,24(sp)
    80003948:	6a42                	ld	s4,16(sp)
    8000394a:	6121                	addi	sp,sp,64
    8000394c:	8082                	ret

000000008000394e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000394e:	711d                	addi	sp,sp,-96
    80003950:	ec86                	sd	ra,88(sp)
    80003952:	e8a2                	sd	s0,80(sp)
    80003954:	e4a6                	sd	s1,72(sp)
    80003956:	e0ca                	sd	s2,64(sp)
    80003958:	fc4e                	sd	s3,56(sp)
    8000395a:	f852                	sd	s4,48(sp)
    8000395c:	f456                	sd	s5,40(sp)
    8000395e:	f05a                	sd	s6,32(sp)
    80003960:	ec5e                	sd	s7,24(sp)
    80003962:	e862                	sd	s8,16(sp)
    80003964:	e466                	sd	s9,8(sp)
    80003966:	1080                	addi	s0,sp,96
    80003968:	84aa                	mv	s1,a0
    8000396a:	8b2e                	mv	s6,a1
    8000396c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000396e:	00054703          	lbu	a4,0(a0)
    80003972:	02f00793          	li	a5,47
    80003976:	00f70e63          	beq	a4,a5,80003992 <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000397a:	f55fd0ef          	jal	800018ce <myproc>
    8000397e:	15053503          	ld	a0,336(a0)
    80003982:	94bff0ef          	jal	800032cc <idup>
    80003986:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003988:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000398c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000398e:	4b85                	li	s7,1
    80003990:	a871                	j	80003a2c <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    80003992:	4585                	li	a1,1
    80003994:	4505                	li	a0,1
    80003996:	ef8ff0ef          	jal	8000308e <iget>
    8000399a:	8a2a                	mv	s4,a0
    8000399c:	b7f5                	j	80003988 <namex+0x3a>
      iunlockput(ip);
    8000399e:	8552                	mv	a0,s4
    800039a0:	b6dff0ef          	jal	8000350c <iunlockput>
      return 0;
    800039a4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800039a6:	8552                	mv	a0,s4
    800039a8:	60e6                	ld	ra,88(sp)
    800039aa:	6446                	ld	s0,80(sp)
    800039ac:	64a6                	ld	s1,72(sp)
    800039ae:	6906                	ld	s2,64(sp)
    800039b0:	79e2                	ld	s3,56(sp)
    800039b2:	7a42                	ld	s4,48(sp)
    800039b4:	7aa2                	ld	s5,40(sp)
    800039b6:	7b02                	ld	s6,32(sp)
    800039b8:	6be2                	ld	s7,24(sp)
    800039ba:	6c42                	ld	s8,16(sp)
    800039bc:	6ca2                	ld	s9,8(sp)
    800039be:	6125                	addi	sp,sp,96
    800039c0:	8082                	ret
      iunlock(ip);
    800039c2:	8552                	mv	a0,s4
    800039c4:	9edff0ef          	jal	800033b0 <iunlock>
      return ip;
    800039c8:	bff9                	j	800039a6 <namex+0x58>
      iunlockput(ip);
    800039ca:	8552                	mv	a0,s4
    800039cc:	b41ff0ef          	jal	8000350c <iunlockput>
      return 0;
    800039d0:	8a4e                	mv	s4,s3
    800039d2:	bfd1                	j	800039a6 <namex+0x58>
  len = path - s;
    800039d4:	40998633          	sub	a2,s3,s1
    800039d8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800039dc:	099c5063          	bge	s8,s9,80003a5c <namex+0x10e>
    memmove(name, s, DIRSIZ);
    800039e0:	4639                	li	a2,14
    800039e2:	85a6                	mv	a1,s1
    800039e4:	8556                	mv	a0,s5
    800039e6:	b18fd0ef          	jal	80000cfe <memmove>
    800039ea:	84ce                	mv	s1,s3
  while(*path == '/')
    800039ec:	0004c783          	lbu	a5,0(s1)
    800039f0:	01279763          	bne	a5,s2,800039fe <namex+0xb0>
    path++;
    800039f4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800039f6:	0004c783          	lbu	a5,0(s1)
    800039fa:	ff278de3          	beq	a5,s2,800039f4 <namex+0xa6>
    ilock(ip);
    800039fe:	8552                	mv	a0,s4
    80003a00:	903ff0ef          	jal	80003302 <ilock>
    if(ip->type != T_DIR){
    80003a04:	044a1783          	lh	a5,68(s4)
    80003a08:	f9779be3          	bne	a5,s7,8000399e <namex+0x50>
    if(nameiparent && *path == '\0'){
    80003a0c:	000b0563          	beqz	s6,80003a16 <namex+0xc8>
    80003a10:	0004c783          	lbu	a5,0(s1)
    80003a14:	d7dd                	beqz	a5,800039c2 <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003a16:	4601                	li	a2,0
    80003a18:	85d6                	mv	a1,s5
    80003a1a:	8552                	mv	a0,s4
    80003a1c:	e97ff0ef          	jal	800038b2 <dirlookup>
    80003a20:	89aa                	mv	s3,a0
    80003a22:	d545                	beqz	a0,800039ca <namex+0x7c>
    iunlockput(ip);
    80003a24:	8552                	mv	a0,s4
    80003a26:	ae7ff0ef          	jal	8000350c <iunlockput>
    ip = next;
    80003a2a:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003a2c:	0004c783          	lbu	a5,0(s1)
    80003a30:	01279763          	bne	a5,s2,80003a3e <namex+0xf0>
    path++;
    80003a34:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003a36:	0004c783          	lbu	a5,0(s1)
    80003a3a:	ff278de3          	beq	a5,s2,80003a34 <namex+0xe6>
  if(*path == 0)
    80003a3e:	cb8d                	beqz	a5,80003a70 <namex+0x122>
  while(*path != '/' && *path != 0)
    80003a40:	0004c783          	lbu	a5,0(s1)
    80003a44:	89a6                	mv	s3,s1
  len = path - s;
    80003a46:	4c81                	li	s9,0
    80003a48:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003a4a:	01278963          	beq	a5,s2,80003a5c <namex+0x10e>
    80003a4e:	d3d9                	beqz	a5,800039d4 <namex+0x86>
    path++;
    80003a50:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003a52:	0009c783          	lbu	a5,0(s3)
    80003a56:	ff279ce3          	bne	a5,s2,80003a4e <namex+0x100>
    80003a5a:	bfad                	j	800039d4 <namex+0x86>
    memmove(name, s, len);
    80003a5c:	2601                	sext.w	a2,a2
    80003a5e:	85a6                	mv	a1,s1
    80003a60:	8556                	mv	a0,s5
    80003a62:	a9cfd0ef          	jal	80000cfe <memmove>
    name[len] = 0;
    80003a66:	9cd6                	add	s9,s9,s5
    80003a68:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003a6c:	84ce                	mv	s1,s3
    80003a6e:	bfbd                	j	800039ec <namex+0x9e>
  if(nameiparent){
    80003a70:	f20b0be3          	beqz	s6,800039a6 <namex+0x58>
    iput(ip);
    80003a74:	8552                	mv	a0,s4
    80003a76:	a0fff0ef          	jal	80003484 <iput>
    return 0;
    80003a7a:	4a01                	li	s4,0
    80003a7c:	b72d                	j	800039a6 <namex+0x58>

0000000080003a7e <dirlink>:
{
    80003a7e:	7139                	addi	sp,sp,-64
    80003a80:	fc06                	sd	ra,56(sp)
    80003a82:	f822                	sd	s0,48(sp)
    80003a84:	f04a                	sd	s2,32(sp)
    80003a86:	ec4e                	sd	s3,24(sp)
    80003a88:	e852                	sd	s4,16(sp)
    80003a8a:	0080                	addi	s0,sp,64
    80003a8c:	892a                	mv	s2,a0
    80003a8e:	8a2e                	mv	s4,a1
    80003a90:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003a92:	4601                	li	a2,0
    80003a94:	e1fff0ef          	jal	800038b2 <dirlookup>
    80003a98:	e535                	bnez	a0,80003b04 <dirlink+0x86>
    80003a9a:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a9c:	04c92483          	lw	s1,76(s2)
    80003aa0:	c48d                	beqz	s1,80003aca <dirlink+0x4c>
    80003aa2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003aa4:	4741                	li	a4,16
    80003aa6:	86a6                	mv	a3,s1
    80003aa8:	fc040613          	addi	a2,s0,-64
    80003aac:	4581                	li	a1,0
    80003aae:	854a                	mv	a0,s2
    80003ab0:	be3ff0ef          	jal	80003692 <readi>
    80003ab4:	47c1                	li	a5,16
    80003ab6:	04f51b63          	bne	a0,a5,80003b0c <dirlink+0x8e>
    if(de.inum == 0)
    80003aba:	fc045783          	lhu	a5,-64(s0)
    80003abe:	c791                	beqz	a5,80003aca <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ac0:	24c1                	addiw	s1,s1,16
    80003ac2:	04c92783          	lw	a5,76(s2)
    80003ac6:	fcf4efe3          	bltu	s1,a5,80003aa4 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003aca:	4639                	li	a2,14
    80003acc:	85d2                	mv	a1,s4
    80003ace:	fc240513          	addi	a0,s0,-62
    80003ad2:	ad2fd0ef          	jal	80000da4 <strncpy>
  de.inum = inum;
    80003ad6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ada:	4741                	li	a4,16
    80003adc:	86a6                	mv	a3,s1
    80003ade:	fc040613          	addi	a2,s0,-64
    80003ae2:	4581                	li	a1,0
    80003ae4:	854a                	mv	a0,s2
    80003ae6:	ca9ff0ef          	jal	8000378e <writei>
    80003aea:	1541                	addi	a0,a0,-16
    80003aec:	00a03533          	snez	a0,a0
    80003af0:	40a00533          	neg	a0,a0
    80003af4:	74a2                	ld	s1,40(sp)
}
    80003af6:	70e2                	ld	ra,56(sp)
    80003af8:	7442                	ld	s0,48(sp)
    80003afa:	7902                	ld	s2,32(sp)
    80003afc:	69e2                	ld	s3,24(sp)
    80003afe:	6a42                	ld	s4,16(sp)
    80003b00:	6121                	addi	sp,sp,64
    80003b02:	8082                	ret
    iput(ip);
    80003b04:	981ff0ef          	jal	80003484 <iput>
    return -1;
    80003b08:	557d                	li	a0,-1
    80003b0a:	b7f5                	j	80003af6 <dirlink+0x78>
      panic("dirlink read");
    80003b0c:	00004517          	auipc	a0,0x4
    80003b10:	9bc50513          	addi	a0,a0,-1604 # 800074c8 <etext+0x4c8>
    80003b14:	ccdfc0ef          	jal	800007e0 <panic>

0000000080003b18 <namei>:

struct inode*
namei(char *path)
{
    80003b18:	1101                	addi	sp,sp,-32
    80003b1a:	ec06                	sd	ra,24(sp)
    80003b1c:	e822                	sd	s0,16(sp)
    80003b1e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003b20:	fe040613          	addi	a2,s0,-32
    80003b24:	4581                	li	a1,0
    80003b26:	e29ff0ef          	jal	8000394e <namex>
}
    80003b2a:	60e2                	ld	ra,24(sp)
    80003b2c:	6442                	ld	s0,16(sp)
    80003b2e:	6105                	addi	sp,sp,32
    80003b30:	8082                	ret

0000000080003b32 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003b32:	1141                	addi	sp,sp,-16
    80003b34:	e406                	sd	ra,8(sp)
    80003b36:	e022                	sd	s0,0(sp)
    80003b38:	0800                	addi	s0,sp,16
    80003b3a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003b3c:	4585                	li	a1,1
    80003b3e:	e11ff0ef          	jal	8000394e <namex>
}
    80003b42:	60a2                	ld	ra,8(sp)
    80003b44:	6402                	ld	s0,0(sp)
    80003b46:	0141                	addi	sp,sp,16
    80003b48:	8082                	ret

0000000080003b4a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003b4a:	1101                	addi	sp,sp,-32
    80003b4c:	ec06                	sd	ra,24(sp)
    80003b4e:	e822                	sd	s0,16(sp)
    80003b50:	e426                	sd	s1,8(sp)
    80003b52:	e04a                	sd	s2,0(sp)
    80003b54:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003b56:	0001f917          	auipc	s2,0x1f
    80003b5a:	9b290913          	addi	s2,s2,-1614 # 80022508 <log>
    80003b5e:	01892583          	lw	a1,24(s2)
    80003b62:	02492503          	lw	a0,36(s2)
    80003b66:	8d0ff0ef          	jal	80002c36 <bread>
    80003b6a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003b6c:	02892603          	lw	a2,40(s2)
    80003b70:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003b72:	00c05f63          	blez	a2,80003b90 <write_head+0x46>
    80003b76:	0001f717          	auipc	a4,0x1f
    80003b7a:	9be70713          	addi	a4,a4,-1602 # 80022534 <log+0x2c>
    80003b7e:	87aa                	mv	a5,a0
    80003b80:	060a                	slli	a2,a2,0x2
    80003b82:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003b84:	4314                	lw	a3,0(a4)
    80003b86:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003b88:	0711                	addi	a4,a4,4
    80003b8a:	0791                	addi	a5,a5,4
    80003b8c:	fec79ce3          	bne	a5,a2,80003b84 <write_head+0x3a>
  }
  bwrite(buf);
    80003b90:	8526                	mv	a0,s1
    80003b92:	97aff0ef          	jal	80002d0c <bwrite>
  brelse(buf);
    80003b96:	8526                	mv	a0,s1
    80003b98:	9a6ff0ef          	jal	80002d3e <brelse>
}
    80003b9c:	60e2                	ld	ra,24(sp)
    80003b9e:	6442                	ld	s0,16(sp)
    80003ba0:	64a2                	ld	s1,8(sp)
    80003ba2:	6902                	ld	s2,0(sp)
    80003ba4:	6105                	addi	sp,sp,32
    80003ba6:	8082                	ret

0000000080003ba8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ba8:	0001f797          	auipc	a5,0x1f
    80003bac:	9887a783          	lw	a5,-1656(a5) # 80022530 <log+0x28>
    80003bb0:	0af05e63          	blez	a5,80003c6c <install_trans+0xc4>
{
    80003bb4:	715d                	addi	sp,sp,-80
    80003bb6:	e486                	sd	ra,72(sp)
    80003bb8:	e0a2                	sd	s0,64(sp)
    80003bba:	fc26                	sd	s1,56(sp)
    80003bbc:	f84a                	sd	s2,48(sp)
    80003bbe:	f44e                	sd	s3,40(sp)
    80003bc0:	f052                	sd	s4,32(sp)
    80003bc2:	ec56                	sd	s5,24(sp)
    80003bc4:	e85a                	sd	s6,16(sp)
    80003bc6:	e45e                	sd	s7,8(sp)
    80003bc8:	0880                	addi	s0,sp,80
    80003bca:	8b2a                	mv	s6,a0
    80003bcc:	0001fa97          	auipc	s5,0x1f
    80003bd0:	968a8a93          	addi	s5,s5,-1688 # 80022534 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003bd4:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003bd6:	00004b97          	auipc	s7,0x4
    80003bda:	902b8b93          	addi	s7,s7,-1790 # 800074d8 <etext+0x4d8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003bde:	0001fa17          	auipc	s4,0x1f
    80003be2:	92aa0a13          	addi	s4,s4,-1750 # 80022508 <log>
    80003be6:	a025                	j	80003c0e <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003be8:	000aa603          	lw	a2,0(s5)
    80003bec:	85ce                	mv	a1,s3
    80003bee:	855e                	mv	a0,s7
    80003bf0:	90bfc0ef          	jal	800004fa <printf>
    80003bf4:	a839                	j	80003c12 <install_trans+0x6a>
    brelse(lbuf);
    80003bf6:	854a                	mv	a0,s2
    80003bf8:	946ff0ef          	jal	80002d3e <brelse>
    brelse(dbuf);
    80003bfc:	8526                	mv	a0,s1
    80003bfe:	940ff0ef          	jal	80002d3e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c02:	2985                	addiw	s3,s3,1
    80003c04:	0a91                	addi	s5,s5,4
    80003c06:	028a2783          	lw	a5,40(s4)
    80003c0a:	04f9d663          	bge	s3,a5,80003c56 <install_trans+0xae>
    if(recovering) {
    80003c0e:	fc0b1de3          	bnez	s6,80003be8 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003c12:	018a2583          	lw	a1,24(s4)
    80003c16:	013585bb          	addw	a1,a1,s3
    80003c1a:	2585                	addiw	a1,a1,1
    80003c1c:	024a2503          	lw	a0,36(s4)
    80003c20:	816ff0ef          	jal	80002c36 <bread>
    80003c24:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003c26:	000aa583          	lw	a1,0(s5)
    80003c2a:	024a2503          	lw	a0,36(s4)
    80003c2e:	808ff0ef          	jal	80002c36 <bread>
    80003c32:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003c34:	40000613          	li	a2,1024
    80003c38:	05890593          	addi	a1,s2,88
    80003c3c:	05850513          	addi	a0,a0,88
    80003c40:	8befd0ef          	jal	80000cfe <memmove>
    bwrite(dbuf);  // write dst to disk
    80003c44:	8526                	mv	a0,s1
    80003c46:	8c6ff0ef          	jal	80002d0c <bwrite>
    if(recovering == 0)
    80003c4a:	fa0b16e3          	bnez	s6,80003bf6 <install_trans+0x4e>
      bunpin(dbuf);
    80003c4e:	8526                	mv	a0,s1
    80003c50:	9aaff0ef          	jal	80002dfa <bunpin>
    80003c54:	b74d                	j	80003bf6 <install_trans+0x4e>
}
    80003c56:	60a6                	ld	ra,72(sp)
    80003c58:	6406                	ld	s0,64(sp)
    80003c5a:	74e2                	ld	s1,56(sp)
    80003c5c:	7942                	ld	s2,48(sp)
    80003c5e:	79a2                	ld	s3,40(sp)
    80003c60:	7a02                	ld	s4,32(sp)
    80003c62:	6ae2                	ld	s5,24(sp)
    80003c64:	6b42                	ld	s6,16(sp)
    80003c66:	6ba2                	ld	s7,8(sp)
    80003c68:	6161                	addi	sp,sp,80
    80003c6a:	8082                	ret
    80003c6c:	8082                	ret

0000000080003c6e <initlog>:
{
    80003c6e:	7179                	addi	sp,sp,-48
    80003c70:	f406                	sd	ra,40(sp)
    80003c72:	f022                	sd	s0,32(sp)
    80003c74:	ec26                	sd	s1,24(sp)
    80003c76:	e84a                	sd	s2,16(sp)
    80003c78:	e44e                	sd	s3,8(sp)
    80003c7a:	1800                	addi	s0,sp,48
    80003c7c:	892a                	mv	s2,a0
    80003c7e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003c80:	0001f497          	auipc	s1,0x1f
    80003c84:	88848493          	addi	s1,s1,-1912 # 80022508 <log>
    80003c88:	00004597          	auipc	a1,0x4
    80003c8c:	87058593          	addi	a1,a1,-1936 # 800074f8 <etext+0x4f8>
    80003c90:	8526                	mv	a0,s1
    80003c92:	ebdfc0ef          	jal	80000b4e <initlock>
  log.start = sb->logstart;
    80003c96:	0149a583          	lw	a1,20(s3)
    80003c9a:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003c9c:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003ca0:	854a                	mv	a0,s2
    80003ca2:	f95fe0ef          	jal	80002c36 <bread>
  log.lh.n = lh->n;
    80003ca6:	4d30                	lw	a2,88(a0)
    80003ca8:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003caa:	00c05f63          	blez	a2,80003cc8 <initlog+0x5a>
    80003cae:	87aa                	mv	a5,a0
    80003cb0:	0001f717          	auipc	a4,0x1f
    80003cb4:	88470713          	addi	a4,a4,-1916 # 80022534 <log+0x2c>
    80003cb8:	060a                	slli	a2,a2,0x2
    80003cba:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003cbc:	4ff4                	lw	a3,92(a5)
    80003cbe:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003cc0:	0791                	addi	a5,a5,4
    80003cc2:	0711                	addi	a4,a4,4
    80003cc4:	fec79ce3          	bne	a5,a2,80003cbc <initlog+0x4e>
  brelse(buf);
    80003cc8:	876ff0ef          	jal	80002d3e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003ccc:	4505                	li	a0,1
    80003cce:	edbff0ef          	jal	80003ba8 <install_trans>
  log.lh.n = 0;
    80003cd2:	0001f797          	auipc	a5,0x1f
    80003cd6:	8407af23          	sw	zero,-1954(a5) # 80022530 <log+0x28>
  write_head(); // clear the log
    80003cda:	e71ff0ef          	jal	80003b4a <write_head>
}
    80003cde:	70a2                	ld	ra,40(sp)
    80003ce0:	7402                	ld	s0,32(sp)
    80003ce2:	64e2                	ld	s1,24(sp)
    80003ce4:	6942                	ld	s2,16(sp)
    80003ce6:	69a2                	ld	s3,8(sp)
    80003ce8:	6145                	addi	sp,sp,48
    80003cea:	8082                	ret

0000000080003cec <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003cec:	1101                	addi	sp,sp,-32
    80003cee:	ec06                	sd	ra,24(sp)
    80003cf0:	e822                	sd	s0,16(sp)
    80003cf2:	e426                	sd	s1,8(sp)
    80003cf4:	e04a                	sd	s2,0(sp)
    80003cf6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003cf8:	0001f517          	auipc	a0,0x1f
    80003cfc:	81050513          	addi	a0,a0,-2032 # 80022508 <log>
    80003d00:	ecffc0ef          	jal	80000bce <acquire>
  while(1){
    if(log.committing){
    80003d04:	0001f497          	auipc	s1,0x1f
    80003d08:	80448493          	addi	s1,s1,-2044 # 80022508 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003d0c:	4979                	li	s2,30
    80003d0e:	a029                	j	80003d18 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003d10:	85a6                	mv	a1,s1
    80003d12:	8526                	mv	a0,s1
    80003d14:	aaafe0ef          	jal	80001fbe <sleep>
    if(log.committing){
    80003d18:	509c                	lw	a5,32(s1)
    80003d1a:	fbfd                	bnez	a5,80003d10 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003d1c:	4cd8                	lw	a4,28(s1)
    80003d1e:	2705                	addiw	a4,a4,1
    80003d20:	0027179b          	slliw	a5,a4,0x2
    80003d24:	9fb9                	addw	a5,a5,a4
    80003d26:	0017979b          	slliw	a5,a5,0x1
    80003d2a:	5494                	lw	a3,40(s1)
    80003d2c:	9fb5                	addw	a5,a5,a3
    80003d2e:	00f95763          	bge	s2,a5,80003d3c <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003d32:	85a6                	mv	a1,s1
    80003d34:	8526                	mv	a0,s1
    80003d36:	a88fe0ef          	jal	80001fbe <sleep>
    80003d3a:	bff9                	j	80003d18 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003d3c:	0001e517          	auipc	a0,0x1e
    80003d40:	7cc50513          	addi	a0,a0,1996 # 80022508 <log>
    80003d44:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003d46:	f21fc0ef          	jal	80000c66 <release>
      break;
    }
  }
}
    80003d4a:	60e2                	ld	ra,24(sp)
    80003d4c:	6442                	ld	s0,16(sp)
    80003d4e:	64a2                	ld	s1,8(sp)
    80003d50:	6902                	ld	s2,0(sp)
    80003d52:	6105                	addi	sp,sp,32
    80003d54:	8082                	ret

0000000080003d56 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003d56:	7139                	addi	sp,sp,-64
    80003d58:	fc06                	sd	ra,56(sp)
    80003d5a:	f822                	sd	s0,48(sp)
    80003d5c:	f426                	sd	s1,40(sp)
    80003d5e:	f04a                	sd	s2,32(sp)
    80003d60:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003d62:	0001e497          	auipc	s1,0x1e
    80003d66:	7a648493          	addi	s1,s1,1958 # 80022508 <log>
    80003d6a:	8526                	mv	a0,s1
    80003d6c:	e63fc0ef          	jal	80000bce <acquire>
  log.outstanding -= 1;
    80003d70:	4cdc                	lw	a5,28(s1)
    80003d72:	37fd                	addiw	a5,a5,-1
    80003d74:	0007891b          	sext.w	s2,a5
    80003d78:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003d7a:	509c                	lw	a5,32(s1)
    80003d7c:	ef9d                	bnez	a5,80003dba <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80003d7e:	04091763          	bnez	s2,80003dcc <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003d82:	0001e497          	auipc	s1,0x1e
    80003d86:	78648493          	addi	s1,s1,1926 # 80022508 <log>
    80003d8a:	4785                	li	a5,1
    80003d8c:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003d8e:	8526                	mv	a0,s1
    80003d90:	ed7fc0ef          	jal	80000c66 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003d94:	549c                	lw	a5,40(s1)
    80003d96:	04f04b63          	bgtz	a5,80003dec <end_op+0x96>
    acquire(&log.lock);
    80003d9a:	0001e497          	auipc	s1,0x1e
    80003d9e:	76e48493          	addi	s1,s1,1902 # 80022508 <log>
    80003da2:	8526                	mv	a0,s1
    80003da4:	e2bfc0ef          	jal	80000bce <acquire>
    log.committing = 0;
    80003da8:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80003dac:	8526                	mv	a0,s1
    80003dae:	a5cfe0ef          	jal	8000200a <wakeup>
    release(&log.lock);
    80003db2:	8526                	mv	a0,s1
    80003db4:	eb3fc0ef          	jal	80000c66 <release>
}
    80003db8:	a025                	j	80003de0 <end_op+0x8a>
    80003dba:	ec4e                	sd	s3,24(sp)
    80003dbc:	e852                	sd	s4,16(sp)
    80003dbe:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80003dc0:	00003517          	auipc	a0,0x3
    80003dc4:	74050513          	addi	a0,a0,1856 # 80007500 <etext+0x500>
    80003dc8:	a19fc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80003dcc:	0001e497          	auipc	s1,0x1e
    80003dd0:	73c48493          	addi	s1,s1,1852 # 80022508 <log>
    80003dd4:	8526                	mv	a0,s1
    80003dd6:	a34fe0ef          	jal	8000200a <wakeup>
  release(&log.lock);
    80003dda:	8526                	mv	a0,s1
    80003ddc:	e8bfc0ef          	jal	80000c66 <release>
}
    80003de0:	70e2                	ld	ra,56(sp)
    80003de2:	7442                	ld	s0,48(sp)
    80003de4:	74a2                	ld	s1,40(sp)
    80003de6:	7902                	ld	s2,32(sp)
    80003de8:	6121                	addi	sp,sp,64
    80003dea:	8082                	ret
    80003dec:	ec4e                	sd	s3,24(sp)
    80003dee:	e852                	sd	s4,16(sp)
    80003df0:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80003df2:	0001ea97          	auipc	s5,0x1e
    80003df6:	742a8a93          	addi	s5,s5,1858 # 80022534 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003dfa:	0001ea17          	auipc	s4,0x1e
    80003dfe:	70ea0a13          	addi	s4,s4,1806 # 80022508 <log>
    80003e02:	018a2583          	lw	a1,24(s4)
    80003e06:	012585bb          	addw	a1,a1,s2
    80003e0a:	2585                	addiw	a1,a1,1
    80003e0c:	024a2503          	lw	a0,36(s4)
    80003e10:	e27fe0ef          	jal	80002c36 <bread>
    80003e14:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003e16:	000aa583          	lw	a1,0(s5)
    80003e1a:	024a2503          	lw	a0,36(s4)
    80003e1e:	e19fe0ef          	jal	80002c36 <bread>
    80003e22:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003e24:	40000613          	li	a2,1024
    80003e28:	05850593          	addi	a1,a0,88
    80003e2c:	05848513          	addi	a0,s1,88
    80003e30:	ecffc0ef          	jal	80000cfe <memmove>
    bwrite(to);  // write the log
    80003e34:	8526                	mv	a0,s1
    80003e36:	ed7fe0ef          	jal	80002d0c <bwrite>
    brelse(from);
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	f03fe0ef          	jal	80002d3e <brelse>
    brelse(to);
    80003e40:	8526                	mv	a0,s1
    80003e42:	efdfe0ef          	jal	80002d3e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e46:	2905                	addiw	s2,s2,1
    80003e48:	0a91                	addi	s5,s5,4
    80003e4a:	028a2783          	lw	a5,40(s4)
    80003e4e:	faf94ae3          	blt	s2,a5,80003e02 <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003e52:	cf9ff0ef          	jal	80003b4a <write_head>
    install_trans(0); // Now install writes to home locations
    80003e56:	4501                	li	a0,0
    80003e58:	d51ff0ef          	jal	80003ba8 <install_trans>
    log.lh.n = 0;
    80003e5c:	0001e797          	auipc	a5,0x1e
    80003e60:	6c07aa23          	sw	zero,1748(a5) # 80022530 <log+0x28>
    write_head();    // Erase the transaction from the log
    80003e64:	ce7ff0ef          	jal	80003b4a <write_head>
    80003e68:	69e2                	ld	s3,24(sp)
    80003e6a:	6a42                	ld	s4,16(sp)
    80003e6c:	6aa2                	ld	s5,8(sp)
    80003e6e:	b735                	j	80003d9a <end_op+0x44>

0000000080003e70 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003e70:	1101                	addi	sp,sp,-32
    80003e72:	ec06                	sd	ra,24(sp)
    80003e74:	e822                	sd	s0,16(sp)
    80003e76:	e426                	sd	s1,8(sp)
    80003e78:	e04a                	sd	s2,0(sp)
    80003e7a:	1000                	addi	s0,sp,32
    80003e7c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003e7e:	0001e917          	auipc	s2,0x1e
    80003e82:	68a90913          	addi	s2,s2,1674 # 80022508 <log>
    80003e86:	854a                	mv	a0,s2
    80003e88:	d47fc0ef          	jal	80000bce <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003e8c:	02892603          	lw	a2,40(s2)
    80003e90:	47f5                	li	a5,29
    80003e92:	04c7cc63          	blt	a5,a2,80003eea <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003e96:	0001e797          	auipc	a5,0x1e
    80003e9a:	68e7a783          	lw	a5,1678(a5) # 80022524 <log+0x1c>
    80003e9e:	04f05c63          	blez	a5,80003ef6 <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003ea2:	4781                	li	a5,0
    80003ea4:	04c05f63          	blez	a2,80003f02 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003ea8:	44cc                	lw	a1,12(s1)
    80003eaa:	0001e717          	auipc	a4,0x1e
    80003eae:	68a70713          	addi	a4,a4,1674 # 80022534 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003eb2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003eb4:	4314                	lw	a3,0(a4)
    80003eb6:	04b68663          	beq	a3,a1,80003f02 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003eba:	2785                	addiw	a5,a5,1
    80003ebc:	0711                	addi	a4,a4,4
    80003ebe:	fef61be3          	bne	a2,a5,80003eb4 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003ec2:	0621                	addi	a2,a2,8
    80003ec4:	060a                	slli	a2,a2,0x2
    80003ec6:	0001e797          	auipc	a5,0x1e
    80003eca:	64278793          	addi	a5,a5,1602 # 80022508 <log>
    80003ece:	97b2                	add	a5,a5,a2
    80003ed0:	44d8                	lw	a4,12(s1)
    80003ed2:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003ed4:	8526                	mv	a0,s1
    80003ed6:	ef1fe0ef          	jal	80002dc6 <bpin>
    log.lh.n++;
    80003eda:	0001e717          	auipc	a4,0x1e
    80003ede:	62e70713          	addi	a4,a4,1582 # 80022508 <log>
    80003ee2:	571c                	lw	a5,40(a4)
    80003ee4:	2785                	addiw	a5,a5,1
    80003ee6:	d71c                	sw	a5,40(a4)
    80003ee8:	a80d                	j	80003f1a <log_write+0xaa>
    panic("too big a transaction");
    80003eea:	00003517          	auipc	a0,0x3
    80003eee:	62650513          	addi	a0,a0,1574 # 80007510 <etext+0x510>
    80003ef2:	8effc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    80003ef6:	00003517          	auipc	a0,0x3
    80003efa:	63250513          	addi	a0,a0,1586 # 80007528 <etext+0x528>
    80003efe:	8e3fc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    80003f02:	00878693          	addi	a3,a5,8
    80003f06:	068a                	slli	a3,a3,0x2
    80003f08:	0001e717          	auipc	a4,0x1e
    80003f0c:	60070713          	addi	a4,a4,1536 # 80022508 <log>
    80003f10:	9736                	add	a4,a4,a3
    80003f12:	44d4                	lw	a3,12(s1)
    80003f14:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003f16:	faf60fe3          	beq	a2,a5,80003ed4 <log_write+0x64>
  }
  release(&log.lock);
    80003f1a:	0001e517          	auipc	a0,0x1e
    80003f1e:	5ee50513          	addi	a0,a0,1518 # 80022508 <log>
    80003f22:	d45fc0ef          	jal	80000c66 <release>
}
    80003f26:	60e2                	ld	ra,24(sp)
    80003f28:	6442                	ld	s0,16(sp)
    80003f2a:	64a2                	ld	s1,8(sp)
    80003f2c:	6902                	ld	s2,0(sp)
    80003f2e:	6105                	addi	sp,sp,32
    80003f30:	8082                	ret

0000000080003f32 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003f32:	1101                	addi	sp,sp,-32
    80003f34:	ec06                	sd	ra,24(sp)
    80003f36:	e822                	sd	s0,16(sp)
    80003f38:	e426                	sd	s1,8(sp)
    80003f3a:	e04a                	sd	s2,0(sp)
    80003f3c:	1000                	addi	s0,sp,32
    80003f3e:	84aa                	mv	s1,a0
    80003f40:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003f42:	00003597          	auipc	a1,0x3
    80003f46:	60658593          	addi	a1,a1,1542 # 80007548 <etext+0x548>
    80003f4a:	0521                	addi	a0,a0,8
    80003f4c:	c03fc0ef          	jal	80000b4e <initlock>
  lk->name = name;
    80003f50:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003f54:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003f58:	0204a423          	sw	zero,40(s1)
}
    80003f5c:	60e2                	ld	ra,24(sp)
    80003f5e:	6442                	ld	s0,16(sp)
    80003f60:	64a2                	ld	s1,8(sp)
    80003f62:	6902                	ld	s2,0(sp)
    80003f64:	6105                	addi	sp,sp,32
    80003f66:	8082                	ret

0000000080003f68 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003f68:	1101                	addi	sp,sp,-32
    80003f6a:	ec06                	sd	ra,24(sp)
    80003f6c:	e822                	sd	s0,16(sp)
    80003f6e:	e426                	sd	s1,8(sp)
    80003f70:	e04a                	sd	s2,0(sp)
    80003f72:	1000                	addi	s0,sp,32
    80003f74:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003f76:	00850913          	addi	s2,a0,8
    80003f7a:	854a                	mv	a0,s2
    80003f7c:	c53fc0ef          	jal	80000bce <acquire>
  while (lk->locked) {
    80003f80:	409c                	lw	a5,0(s1)
    80003f82:	c799                	beqz	a5,80003f90 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003f84:	85ca                	mv	a1,s2
    80003f86:	8526                	mv	a0,s1
    80003f88:	836fe0ef          	jal	80001fbe <sleep>
  while (lk->locked) {
    80003f8c:	409c                	lw	a5,0(s1)
    80003f8e:	fbfd                	bnez	a5,80003f84 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003f90:	4785                	li	a5,1
    80003f92:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003f94:	93bfd0ef          	jal	800018ce <myproc>
    80003f98:	591c                	lw	a5,48(a0)
    80003f9a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003f9c:	854a                	mv	a0,s2
    80003f9e:	cc9fc0ef          	jal	80000c66 <release>
}
    80003fa2:	60e2                	ld	ra,24(sp)
    80003fa4:	6442                	ld	s0,16(sp)
    80003fa6:	64a2                	ld	s1,8(sp)
    80003fa8:	6902                	ld	s2,0(sp)
    80003faa:	6105                	addi	sp,sp,32
    80003fac:	8082                	ret

0000000080003fae <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003fae:	1101                	addi	sp,sp,-32
    80003fb0:	ec06                	sd	ra,24(sp)
    80003fb2:	e822                	sd	s0,16(sp)
    80003fb4:	e426                	sd	s1,8(sp)
    80003fb6:	e04a                	sd	s2,0(sp)
    80003fb8:	1000                	addi	s0,sp,32
    80003fba:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003fbc:	00850913          	addi	s2,a0,8
    80003fc0:	854a                	mv	a0,s2
    80003fc2:	c0dfc0ef          	jal	80000bce <acquire>
  lk->locked = 0;
    80003fc6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003fca:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003fce:	8526                	mv	a0,s1
    80003fd0:	83afe0ef          	jal	8000200a <wakeup>
  release(&lk->lk);
    80003fd4:	854a                	mv	a0,s2
    80003fd6:	c91fc0ef          	jal	80000c66 <release>
}
    80003fda:	60e2                	ld	ra,24(sp)
    80003fdc:	6442                	ld	s0,16(sp)
    80003fde:	64a2                	ld	s1,8(sp)
    80003fe0:	6902                	ld	s2,0(sp)
    80003fe2:	6105                	addi	sp,sp,32
    80003fe4:	8082                	ret

0000000080003fe6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003fe6:	7179                	addi	sp,sp,-48
    80003fe8:	f406                	sd	ra,40(sp)
    80003fea:	f022                	sd	s0,32(sp)
    80003fec:	ec26                	sd	s1,24(sp)
    80003fee:	e84a                	sd	s2,16(sp)
    80003ff0:	1800                	addi	s0,sp,48
    80003ff2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003ff4:	00850913          	addi	s2,a0,8
    80003ff8:	854a                	mv	a0,s2
    80003ffa:	bd5fc0ef          	jal	80000bce <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003ffe:	409c                	lw	a5,0(s1)
    80004000:	ef81                	bnez	a5,80004018 <holdingsleep+0x32>
    80004002:	4481                	li	s1,0
  release(&lk->lk);
    80004004:	854a                	mv	a0,s2
    80004006:	c61fc0ef          	jal	80000c66 <release>
  return r;
}
    8000400a:	8526                	mv	a0,s1
    8000400c:	70a2                	ld	ra,40(sp)
    8000400e:	7402                	ld	s0,32(sp)
    80004010:	64e2                	ld	s1,24(sp)
    80004012:	6942                	ld	s2,16(sp)
    80004014:	6145                	addi	sp,sp,48
    80004016:	8082                	ret
    80004018:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    8000401a:	0284a983          	lw	s3,40(s1)
    8000401e:	8b1fd0ef          	jal	800018ce <myproc>
    80004022:	5904                	lw	s1,48(a0)
    80004024:	413484b3          	sub	s1,s1,s3
    80004028:	0014b493          	seqz	s1,s1
    8000402c:	69a2                	ld	s3,8(sp)
    8000402e:	bfd9                	j	80004004 <holdingsleep+0x1e>

0000000080004030 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004030:	1141                	addi	sp,sp,-16
    80004032:	e406                	sd	ra,8(sp)
    80004034:	e022                	sd	s0,0(sp)
    80004036:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004038:	00003597          	auipc	a1,0x3
    8000403c:	52058593          	addi	a1,a1,1312 # 80007558 <etext+0x558>
    80004040:	0001e517          	auipc	a0,0x1e
    80004044:	61050513          	addi	a0,a0,1552 # 80022650 <ftable>
    80004048:	b07fc0ef          	jal	80000b4e <initlock>
}
    8000404c:	60a2                	ld	ra,8(sp)
    8000404e:	6402                	ld	s0,0(sp)
    80004050:	0141                	addi	sp,sp,16
    80004052:	8082                	ret

0000000080004054 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004054:	1101                	addi	sp,sp,-32
    80004056:	ec06                	sd	ra,24(sp)
    80004058:	e822                	sd	s0,16(sp)
    8000405a:	e426                	sd	s1,8(sp)
    8000405c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000405e:	0001e517          	auipc	a0,0x1e
    80004062:	5f250513          	addi	a0,a0,1522 # 80022650 <ftable>
    80004066:	b69fc0ef          	jal	80000bce <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000406a:	0001e497          	auipc	s1,0x1e
    8000406e:	5fe48493          	addi	s1,s1,1534 # 80022668 <ftable+0x18>
    80004072:	0001f717          	auipc	a4,0x1f
    80004076:	59670713          	addi	a4,a4,1430 # 80023608 <disk>
    if(f->ref == 0){
    8000407a:	40dc                	lw	a5,4(s1)
    8000407c:	cf89                	beqz	a5,80004096 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000407e:	02848493          	addi	s1,s1,40
    80004082:	fee49ce3          	bne	s1,a4,8000407a <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004086:	0001e517          	auipc	a0,0x1e
    8000408a:	5ca50513          	addi	a0,a0,1482 # 80022650 <ftable>
    8000408e:	bd9fc0ef          	jal	80000c66 <release>
  return 0;
    80004092:	4481                	li	s1,0
    80004094:	a809                	j	800040a6 <filealloc+0x52>
      f->ref = 1;
    80004096:	4785                	li	a5,1
    80004098:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000409a:	0001e517          	auipc	a0,0x1e
    8000409e:	5b650513          	addi	a0,a0,1462 # 80022650 <ftable>
    800040a2:	bc5fc0ef          	jal	80000c66 <release>
}
    800040a6:	8526                	mv	a0,s1
    800040a8:	60e2                	ld	ra,24(sp)
    800040aa:	6442                	ld	s0,16(sp)
    800040ac:	64a2                	ld	s1,8(sp)
    800040ae:	6105                	addi	sp,sp,32
    800040b0:	8082                	ret

00000000800040b2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800040b2:	1101                	addi	sp,sp,-32
    800040b4:	ec06                	sd	ra,24(sp)
    800040b6:	e822                	sd	s0,16(sp)
    800040b8:	e426                	sd	s1,8(sp)
    800040ba:	1000                	addi	s0,sp,32
    800040bc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800040be:	0001e517          	auipc	a0,0x1e
    800040c2:	59250513          	addi	a0,a0,1426 # 80022650 <ftable>
    800040c6:	b09fc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    800040ca:	40dc                	lw	a5,4(s1)
    800040cc:	02f05063          	blez	a5,800040ec <filedup+0x3a>
    panic("filedup");
  f->ref++;
    800040d0:	2785                	addiw	a5,a5,1
    800040d2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800040d4:	0001e517          	auipc	a0,0x1e
    800040d8:	57c50513          	addi	a0,a0,1404 # 80022650 <ftable>
    800040dc:	b8bfc0ef          	jal	80000c66 <release>
  return f;
}
    800040e0:	8526                	mv	a0,s1
    800040e2:	60e2                	ld	ra,24(sp)
    800040e4:	6442                	ld	s0,16(sp)
    800040e6:	64a2                	ld	s1,8(sp)
    800040e8:	6105                	addi	sp,sp,32
    800040ea:	8082                	ret
    panic("filedup");
    800040ec:	00003517          	auipc	a0,0x3
    800040f0:	47450513          	addi	a0,a0,1140 # 80007560 <etext+0x560>
    800040f4:	eecfc0ef          	jal	800007e0 <panic>

00000000800040f8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800040f8:	7139                	addi	sp,sp,-64
    800040fa:	fc06                	sd	ra,56(sp)
    800040fc:	f822                	sd	s0,48(sp)
    800040fe:	f426                	sd	s1,40(sp)
    80004100:	0080                	addi	s0,sp,64
    80004102:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004104:	0001e517          	auipc	a0,0x1e
    80004108:	54c50513          	addi	a0,a0,1356 # 80022650 <ftable>
    8000410c:	ac3fc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    80004110:	40dc                	lw	a5,4(s1)
    80004112:	04f05a63          	blez	a5,80004166 <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    80004116:	37fd                	addiw	a5,a5,-1
    80004118:	0007871b          	sext.w	a4,a5
    8000411c:	c0dc                	sw	a5,4(s1)
    8000411e:	04e04e63          	bgtz	a4,8000417a <fileclose+0x82>
    80004122:	f04a                	sd	s2,32(sp)
    80004124:	ec4e                	sd	s3,24(sp)
    80004126:	e852                	sd	s4,16(sp)
    80004128:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000412a:	0004a903          	lw	s2,0(s1)
    8000412e:	0094ca83          	lbu	s5,9(s1)
    80004132:	0104ba03          	ld	s4,16(s1)
    80004136:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000413a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000413e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004142:	0001e517          	auipc	a0,0x1e
    80004146:	50e50513          	addi	a0,a0,1294 # 80022650 <ftable>
    8000414a:	b1dfc0ef          	jal	80000c66 <release>

  if(ff.type == FD_PIPE){
    8000414e:	4785                	li	a5,1
    80004150:	04f90063          	beq	s2,a5,80004190 <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004154:	3979                	addiw	s2,s2,-2
    80004156:	4785                	li	a5,1
    80004158:	0527f563          	bgeu	a5,s2,800041a2 <fileclose+0xaa>
    8000415c:	7902                	ld	s2,32(sp)
    8000415e:	69e2                	ld	s3,24(sp)
    80004160:	6a42                	ld	s4,16(sp)
    80004162:	6aa2                	ld	s5,8(sp)
    80004164:	a00d                	j	80004186 <fileclose+0x8e>
    80004166:	f04a                	sd	s2,32(sp)
    80004168:	ec4e                	sd	s3,24(sp)
    8000416a:	e852                	sd	s4,16(sp)
    8000416c:	e456                	sd	s5,8(sp)
    panic("fileclose");
    8000416e:	00003517          	auipc	a0,0x3
    80004172:	3fa50513          	addi	a0,a0,1018 # 80007568 <etext+0x568>
    80004176:	e6afc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    8000417a:	0001e517          	auipc	a0,0x1e
    8000417e:	4d650513          	addi	a0,a0,1238 # 80022650 <ftable>
    80004182:	ae5fc0ef          	jal	80000c66 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80004186:	70e2                	ld	ra,56(sp)
    80004188:	7442                	ld	s0,48(sp)
    8000418a:	74a2                	ld	s1,40(sp)
    8000418c:	6121                	addi	sp,sp,64
    8000418e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004190:	85d6                	mv	a1,s5
    80004192:	8552                	mv	a0,s4
    80004194:	336000ef          	jal	800044ca <pipeclose>
    80004198:	7902                	ld	s2,32(sp)
    8000419a:	69e2                	ld	s3,24(sp)
    8000419c:	6a42                	ld	s4,16(sp)
    8000419e:	6aa2                	ld	s5,8(sp)
    800041a0:	b7dd                	j	80004186 <fileclose+0x8e>
    begin_op();
    800041a2:	b4bff0ef          	jal	80003cec <begin_op>
    iput(ff.ip);
    800041a6:	854e                	mv	a0,s3
    800041a8:	adcff0ef          	jal	80003484 <iput>
    end_op();
    800041ac:	babff0ef          	jal	80003d56 <end_op>
    800041b0:	7902                	ld	s2,32(sp)
    800041b2:	69e2                	ld	s3,24(sp)
    800041b4:	6a42                	ld	s4,16(sp)
    800041b6:	6aa2                	ld	s5,8(sp)
    800041b8:	b7f9                	j	80004186 <fileclose+0x8e>

00000000800041ba <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800041ba:	715d                	addi	sp,sp,-80
    800041bc:	e486                	sd	ra,72(sp)
    800041be:	e0a2                	sd	s0,64(sp)
    800041c0:	fc26                	sd	s1,56(sp)
    800041c2:	f44e                	sd	s3,40(sp)
    800041c4:	0880                	addi	s0,sp,80
    800041c6:	84aa                	mv	s1,a0
    800041c8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800041ca:	f04fd0ef          	jal	800018ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800041ce:	409c                	lw	a5,0(s1)
    800041d0:	37f9                	addiw	a5,a5,-2
    800041d2:	4705                	li	a4,1
    800041d4:	04f76063          	bltu	a4,a5,80004214 <filestat+0x5a>
    800041d8:	f84a                	sd	s2,48(sp)
    800041da:	892a                	mv	s2,a0
    ilock(f->ip);
    800041dc:	6c88                	ld	a0,24(s1)
    800041de:	924ff0ef          	jal	80003302 <ilock>
    stati(f->ip, &st);
    800041e2:	fb840593          	addi	a1,s0,-72
    800041e6:	6c88                	ld	a0,24(s1)
    800041e8:	c80ff0ef          	jal	80003668 <stati>
    iunlock(f->ip);
    800041ec:	6c88                	ld	a0,24(s1)
    800041ee:	9c2ff0ef          	jal	800033b0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800041f2:	46e1                	li	a3,24
    800041f4:	fb840613          	addi	a2,s0,-72
    800041f8:	85ce                	mv	a1,s3
    800041fa:	05093503          	ld	a0,80(s2)
    800041fe:	be4fd0ef          	jal	800015e2 <copyout>
    80004202:	41f5551b          	sraiw	a0,a0,0x1f
    80004206:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004208:	60a6                	ld	ra,72(sp)
    8000420a:	6406                	ld	s0,64(sp)
    8000420c:	74e2                	ld	s1,56(sp)
    8000420e:	79a2                	ld	s3,40(sp)
    80004210:	6161                	addi	sp,sp,80
    80004212:	8082                	ret
  return -1;
    80004214:	557d                	li	a0,-1
    80004216:	bfcd                	j	80004208 <filestat+0x4e>

0000000080004218 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004218:	7179                	addi	sp,sp,-48
    8000421a:	f406                	sd	ra,40(sp)
    8000421c:	f022                	sd	s0,32(sp)
    8000421e:	e84a                	sd	s2,16(sp)
    80004220:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004222:	00854783          	lbu	a5,8(a0)
    80004226:	cfd1                	beqz	a5,800042c2 <fileread+0xaa>
    80004228:	ec26                	sd	s1,24(sp)
    8000422a:	e44e                	sd	s3,8(sp)
    8000422c:	84aa                	mv	s1,a0
    8000422e:	89ae                	mv	s3,a1
    80004230:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004232:	411c                	lw	a5,0(a0)
    80004234:	4705                	li	a4,1
    80004236:	04e78363          	beq	a5,a4,8000427c <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000423a:	470d                	li	a4,3
    8000423c:	04e78763          	beq	a5,a4,8000428a <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004240:	4709                	li	a4,2
    80004242:	06e79a63          	bne	a5,a4,800042b6 <fileread+0x9e>
    ilock(f->ip);
    80004246:	6d08                	ld	a0,24(a0)
    80004248:	8baff0ef          	jal	80003302 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000424c:	874a                	mv	a4,s2
    8000424e:	5094                	lw	a3,32(s1)
    80004250:	864e                	mv	a2,s3
    80004252:	4585                	li	a1,1
    80004254:	6c88                	ld	a0,24(s1)
    80004256:	c3cff0ef          	jal	80003692 <readi>
    8000425a:	892a                	mv	s2,a0
    8000425c:	00a05563          	blez	a0,80004266 <fileread+0x4e>
      f->off += r;
    80004260:	509c                	lw	a5,32(s1)
    80004262:	9fa9                	addw	a5,a5,a0
    80004264:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004266:	6c88                	ld	a0,24(s1)
    80004268:	948ff0ef          	jal	800033b0 <iunlock>
    8000426c:	64e2                	ld	s1,24(sp)
    8000426e:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004270:	854a                	mv	a0,s2
    80004272:	70a2                	ld	ra,40(sp)
    80004274:	7402                	ld	s0,32(sp)
    80004276:	6942                	ld	s2,16(sp)
    80004278:	6145                	addi	sp,sp,48
    8000427a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000427c:	6908                	ld	a0,16(a0)
    8000427e:	388000ef          	jal	80004606 <piperead>
    80004282:	892a                	mv	s2,a0
    80004284:	64e2                	ld	s1,24(sp)
    80004286:	69a2                	ld	s3,8(sp)
    80004288:	b7e5                	j	80004270 <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000428a:	02451783          	lh	a5,36(a0)
    8000428e:	03079693          	slli	a3,a5,0x30
    80004292:	92c1                	srli	a3,a3,0x30
    80004294:	4725                	li	a4,9
    80004296:	02d76863          	bltu	a4,a3,800042c6 <fileread+0xae>
    8000429a:	0792                	slli	a5,a5,0x4
    8000429c:	0001e717          	auipc	a4,0x1e
    800042a0:	31470713          	addi	a4,a4,788 # 800225b0 <devsw>
    800042a4:	97ba                	add	a5,a5,a4
    800042a6:	639c                	ld	a5,0(a5)
    800042a8:	c39d                	beqz	a5,800042ce <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    800042aa:	4505                	li	a0,1
    800042ac:	9782                	jalr	a5
    800042ae:	892a                	mv	s2,a0
    800042b0:	64e2                	ld	s1,24(sp)
    800042b2:	69a2                	ld	s3,8(sp)
    800042b4:	bf75                	j	80004270 <fileread+0x58>
    panic("fileread");
    800042b6:	00003517          	auipc	a0,0x3
    800042ba:	2c250513          	addi	a0,a0,706 # 80007578 <etext+0x578>
    800042be:	d22fc0ef          	jal	800007e0 <panic>
    return -1;
    800042c2:	597d                	li	s2,-1
    800042c4:	b775                	j	80004270 <fileread+0x58>
      return -1;
    800042c6:	597d                	li	s2,-1
    800042c8:	64e2                	ld	s1,24(sp)
    800042ca:	69a2                	ld	s3,8(sp)
    800042cc:	b755                	j	80004270 <fileread+0x58>
    800042ce:	597d                	li	s2,-1
    800042d0:	64e2                	ld	s1,24(sp)
    800042d2:	69a2                	ld	s3,8(sp)
    800042d4:	bf71                	j	80004270 <fileread+0x58>

00000000800042d6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800042d6:	00954783          	lbu	a5,9(a0)
    800042da:	10078b63          	beqz	a5,800043f0 <filewrite+0x11a>
{
    800042de:	715d                	addi	sp,sp,-80
    800042e0:	e486                	sd	ra,72(sp)
    800042e2:	e0a2                	sd	s0,64(sp)
    800042e4:	f84a                	sd	s2,48(sp)
    800042e6:	f052                	sd	s4,32(sp)
    800042e8:	e85a                	sd	s6,16(sp)
    800042ea:	0880                	addi	s0,sp,80
    800042ec:	892a                	mv	s2,a0
    800042ee:	8b2e                	mv	s6,a1
    800042f0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800042f2:	411c                	lw	a5,0(a0)
    800042f4:	4705                	li	a4,1
    800042f6:	02e78763          	beq	a5,a4,80004324 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800042fa:	470d                	li	a4,3
    800042fc:	02e78863          	beq	a5,a4,8000432c <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004300:	4709                	li	a4,2
    80004302:	0ce79c63          	bne	a5,a4,800043da <filewrite+0x104>
    80004306:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004308:	0ac05863          	blez	a2,800043b8 <filewrite+0xe2>
    8000430c:	fc26                	sd	s1,56(sp)
    8000430e:	ec56                	sd	s5,24(sp)
    80004310:	e45e                	sd	s7,8(sp)
    80004312:	e062                	sd	s8,0(sp)
    int i = 0;
    80004314:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004316:	6b85                	lui	s7,0x1
    80004318:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000431c:	6c05                	lui	s8,0x1
    8000431e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004322:	a8b5                	j	8000439e <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    80004324:	6908                	ld	a0,16(a0)
    80004326:	1fc000ef          	jal	80004522 <pipewrite>
    8000432a:	a04d                	j	800043cc <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000432c:	02451783          	lh	a5,36(a0)
    80004330:	03079693          	slli	a3,a5,0x30
    80004334:	92c1                	srli	a3,a3,0x30
    80004336:	4725                	li	a4,9
    80004338:	0ad76e63          	bltu	a4,a3,800043f4 <filewrite+0x11e>
    8000433c:	0792                	slli	a5,a5,0x4
    8000433e:	0001e717          	auipc	a4,0x1e
    80004342:	27270713          	addi	a4,a4,626 # 800225b0 <devsw>
    80004346:	97ba                	add	a5,a5,a4
    80004348:	679c                	ld	a5,8(a5)
    8000434a:	c7dd                	beqz	a5,800043f8 <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    8000434c:	4505                	li	a0,1
    8000434e:	9782                	jalr	a5
    80004350:	a8b5                	j	800043cc <filewrite+0xf6>
      if(n1 > max)
    80004352:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004356:	997ff0ef          	jal	80003cec <begin_op>
      ilock(f->ip);
    8000435a:	01893503          	ld	a0,24(s2)
    8000435e:	fa5fe0ef          	jal	80003302 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004362:	8756                	mv	a4,s5
    80004364:	02092683          	lw	a3,32(s2)
    80004368:	01698633          	add	a2,s3,s6
    8000436c:	4585                	li	a1,1
    8000436e:	01893503          	ld	a0,24(s2)
    80004372:	c1cff0ef          	jal	8000378e <writei>
    80004376:	84aa                	mv	s1,a0
    80004378:	00a05763          	blez	a0,80004386 <filewrite+0xb0>
        f->off += r;
    8000437c:	02092783          	lw	a5,32(s2)
    80004380:	9fa9                	addw	a5,a5,a0
    80004382:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004386:	01893503          	ld	a0,24(s2)
    8000438a:	826ff0ef          	jal	800033b0 <iunlock>
      end_op();
    8000438e:	9c9ff0ef          	jal	80003d56 <end_op>

      if(r != n1){
    80004392:	029a9563          	bne	s5,s1,800043bc <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    80004396:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000439a:	0149da63          	bge	s3,s4,800043ae <filewrite+0xd8>
      int n1 = n - i;
    8000439e:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800043a2:	0004879b          	sext.w	a5,s1
    800043a6:	fafbd6e3          	bge	s7,a5,80004352 <filewrite+0x7c>
    800043aa:	84e2                	mv	s1,s8
    800043ac:	b75d                	j	80004352 <filewrite+0x7c>
    800043ae:	74e2                	ld	s1,56(sp)
    800043b0:	6ae2                	ld	s5,24(sp)
    800043b2:	6ba2                	ld	s7,8(sp)
    800043b4:	6c02                	ld	s8,0(sp)
    800043b6:	a039                	j	800043c4 <filewrite+0xee>
    int i = 0;
    800043b8:	4981                	li	s3,0
    800043ba:	a029                	j	800043c4 <filewrite+0xee>
    800043bc:	74e2                	ld	s1,56(sp)
    800043be:	6ae2                	ld	s5,24(sp)
    800043c0:	6ba2                	ld	s7,8(sp)
    800043c2:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    800043c4:	033a1c63          	bne	s4,s3,800043fc <filewrite+0x126>
    800043c8:	8552                	mv	a0,s4
    800043ca:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    800043cc:	60a6                	ld	ra,72(sp)
    800043ce:	6406                	ld	s0,64(sp)
    800043d0:	7942                	ld	s2,48(sp)
    800043d2:	7a02                	ld	s4,32(sp)
    800043d4:	6b42                	ld	s6,16(sp)
    800043d6:	6161                	addi	sp,sp,80
    800043d8:	8082                	ret
    800043da:	fc26                	sd	s1,56(sp)
    800043dc:	f44e                	sd	s3,40(sp)
    800043de:	ec56                	sd	s5,24(sp)
    800043e0:	e45e                	sd	s7,8(sp)
    800043e2:	e062                	sd	s8,0(sp)
    panic("filewrite");
    800043e4:	00003517          	auipc	a0,0x3
    800043e8:	1a450513          	addi	a0,a0,420 # 80007588 <etext+0x588>
    800043ec:	bf4fc0ef          	jal	800007e0 <panic>
    return -1;
    800043f0:	557d                	li	a0,-1
}
    800043f2:	8082                	ret
      return -1;
    800043f4:	557d                	li	a0,-1
    800043f6:	bfd9                	j	800043cc <filewrite+0xf6>
    800043f8:	557d                	li	a0,-1
    800043fa:	bfc9                	j	800043cc <filewrite+0xf6>
    ret = (i == n ? n : -1);
    800043fc:	557d                	li	a0,-1
    800043fe:	79a2                	ld	s3,40(sp)
    80004400:	b7f1                	j	800043cc <filewrite+0xf6>

0000000080004402 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004402:	7179                	addi	sp,sp,-48
    80004404:	f406                	sd	ra,40(sp)
    80004406:	f022                	sd	s0,32(sp)
    80004408:	ec26                	sd	s1,24(sp)
    8000440a:	e052                	sd	s4,0(sp)
    8000440c:	1800                	addi	s0,sp,48
    8000440e:	84aa                	mv	s1,a0
    80004410:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004412:	0005b023          	sd	zero,0(a1)
    80004416:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000441a:	c3bff0ef          	jal	80004054 <filealloc>
    8000441e:	e088                	sd	a0,0(s1)
    80004420:	c549                	beqz	a0,800044aa <pipealloc+0xa8>
    80004422:	c33ff0ef          	jal	80004054 <filealloc>
    80004426:	00aa3023          	sd	a0,0(s4)
    8000442a:	cd25                	beqz	a0,800044a2 <pipealloc+0xa0>
    8000442c:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000442e:	ed0fc0ef          	jal	80000afe <kalloc>
    80004432:	892a                	mv	s2,a0
    80004434:	c12d                	beqz	a0,80004496 <pipealloc+0x94>
    80004436:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004438:	4985                	li	s3,1
    8000443a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000443e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004442:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004446:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000444a:	00003597          	auipc	a1,0x3
    8000444e:	14e58593          	addi	a1,a1,334 # 80007598 <etext+0x598>
    80004452:	efcfc0ef          	jal	80000b4e <initlock>
  (*f0)->type = FD_PIPE;
    80004456:	609c                	ld	a5,0(s1)
    80004458:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000445c:	609c                	ld	a5,0(s1)
    8000445e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004462:	609c                	ld	a5,0(s1)
    80004464:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004468:	609c                	ld	a5,0(s1)
    8000446a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000446e:	000a3783          	ld	a5,0(s4)
    80004472:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004476:	000a3783          	ld	a5,0(s4)
    8000447a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000447e:	000a3783          	ld	a5,0(s4)
    80004482:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004486:	000a3783          	ld	a5,0(s4)
    8000448a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000448e:	4501                	li	a0,0
    80004490:	6942                	ld	s2,16(sp)
    80004492:	69a2                	ld	s3,8(sp)
    80004494:	a01d                	j	800044ba <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004496:	6088                	ld	a0,0(s1)
    80004498:	c119                	beqz	a0,8000449e <pipealloc+0x9c>
    8000449a:	6942                	ld	s2,16(sp)
    8000449c:	a029                	j	800044a6 <pipealloc+0xa4>
    8000449e:	6942                	ld	s2,16(sp)
    800044a0:	a029                	j	800044aa <pipealloc+0xa8>
    800044a2:	6088                	ld	a0,0(s1)
    800044a4:	c10d                	beqz	a0,800044c6 <pipealloc+0xc4>
    fileclose(*f0);
    800044a6:	c53ff0ef          	jal	800040f8 <fileclose>
  if(*f1)
    800044aa:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800044ae:	557d                	li	a0,-1
  if(*f1)
    800044b0:	c789                	beqz	a5,800044ba <pipealloc+0xb8>
    fileclose(*f1);
    800044b2:	853e                	mv	a0,a5
    800044b4:	c45ff0ef          	jal	800040f8 <fileclose>
  return -1;
    800044b8:	557d                	li	a0,-1
}
    800044ba:	70a2                	ld	ra,40(sp)
    800044bc:	7402                	ld	s0,32(sp)
    800044be:	64e2                	ld	s1,24(sp)
    800044c0:	6a02                	ld	s4,0(sp)
    800044c2:	6145                	addi	sp,sp,48
    800044c4:	8082                	ret
  return -1;
    800044c6:	557d                	li	a0,-1
    800044c8:	bfcd                	j	800044ba <pipealloc+0xb8>

00000000800044ca <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800044ca:	1101                	addi	sp,sp,-32
    800044cc:	ec06                	sd	ra,24(sp)
    800044ce:	e822                	sd	s0,16(sp)
    800044d0:	e426                	sd	s1,8(sp)
    800044d2:	e04a                	sd	s2,0(sp)
    800044d4:	1000                	addi	s0,sp,32
    800044d6:	84aa                	mv	s1,a0
    800044d8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800044da:	ef4fc0ef          	jal	80000bce <acquire>
  if(writable){
    800044de:	02090763          	beqz	s2,8000450c <pipeclose+0x42>
    pi->writeopen = 0;
    800044e2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800044e6:	21848513          	addi	a0,s1,536
    800044ea:	b21fd0ef          	jal	8000200a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800044ee:	2204b783          	ld	a5,544(s1)
    800044f2:	e785                	bnez	a5,8000451a <pipeclose+0x50>
    release(&pi->lock);
    800044f4:	8526                	mv	a0,s1
    800044f6:	f70fc0ef          	jal	80000c66 <release>
    kfree((char*)pi);
    800044fa:	8526                	mv	a0,s1
    800044fc:	d20fc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    80004500:	60e2                	ld	ra,24(sp)
    80004502:	6442                	ld	s0,16(sp)
    80004504:	64a2                	ld	s1,8(sp)
    80004506:	6902                	ld	s2,0(sp)
    80004508:	6105                	addi	sp,sp,32
    8000450a:	8082                	ret
    pi->readopen = 0;
    8000450c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004510:	21c48513          	addi	a0,s1,540
    80004514:	af7fd0ef          	jal	8000200a <wakeup>
    80004518:	bfd9                	j	800044ee <pipeclose+0x24>
    release(&pi->lock);
    8000451a:	8526                	mv	a0,s1
    8000451c:	f4afc0ef          	jal	80000c66 <release>
}
    80004520:	b7c5                	j	80004500 <pipeclose+0x36>

0000000080004522 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004522:	711d                	addi	sp,sp,-96
    80004524:	ec86                	sd	ra,88(sp)
    80004526:	e8a2                	sd	s0,80(sp)
    80004528:	e4a6                	sd	s1,72(sp)
    8000452a:	e0ca                	sd	s2,64(sp)
    8000452c:	fc4e                	sd	s3,56(sp)
    8000452e:	f852                	sd	s4,48(sp)
    80004530:	f456                	sd	s5,40(sp)
    80004532:	1080                	addi	s0,sp,96
    80004534:	84aa                	mv	s1,a0
    80004536:	8aae                	mv	s5,a1
    80004538:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000453a:	b94fd0ef          	jal	800018ce <myproc>
    8000453e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004540:	8526                	mv	a0,s1
    80004542:	e8cfc0ef          	jal	80000bce <acquire>
  while(i < n){
    80004546:	0b405a63          	blez	s4,800045fa <pipewrite+0xd8>
    8000454a:	f05a                	sd	s6,32(sp)
    8000454c:	ec5e                	sd	s7,24(sp)
    8000454e:	e862                	sd	s8,16(sp)
  int i = 0;
    80004550:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004552:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004554:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004558:	21c48b93          	addi	s7,s1,540
    8000455c:	a81d                	j	80004592 <pipewrite+0x70>
      release(&pi->lock);
    8000455e:	8526                	mv	a0,s1
    80004560:	f06fc0ef          	jal	80000c66 <release>
      return -1;
    80004564:	597d                	li	s2,-1
    80004566:	7b02                	ld	s6,32(sp)
    80004568:	6be2                	ld	s7,24(sp)
    8000456a:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000456c:	854a                	mv	a0,s2
    8000456e:	60e6                	ld	ra,88(sp)
    80004570:	6446                	ld	s0,80(sp)
    80004572:	64a6                	ld	s1,72(sp)
    80004574:	6906                	ld	s2,64(sp)
    80004576:	79e2                	ld	s3,56(sp)
    80004578:	7a42                	ld	s4,48(sp)
    8000457a:	7aa2                	ld	s5,40(sp)
    8000457c:	6125                	addi	sp,sp,96
    8000457e:	8082                	ret
      wakeup(&pi->nread);
    80004580:	8562                	mv	a0,s8
    80004582:	a89fd0ef          	jal	8000200a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004586:	85a6                	mv	a1,s1
    80004588:	855e                	mv	a0,s7
    8000458a:	a35fd0ef          	jal	80001fbe <sleep>
  while(i < n){
    8000458e:	05495b63          	bge	s2,s4,800045e4 <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    80004592:	2204a783          	lw	a5,544(s1)
    80004596:	d7e1                	beqz	a5,8000455e <pipewrite+0x3c>
    80004598:	854e                	mv	a0,s3
    8000459a:	c5dfd0ef          	jal	800021f6 <killed>
    8000459e:	f161                	bnez	a0,8000455e <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800045a0:	2184a783          	lw	a5,536(s1)
    800045a4:	21c4a703          	lw	a4,540(s1)
    800045a8:	2007879b          	addiw	a5,a5,512
    800045ac:	fcf70ae3          	beq	a4,a5,80004580 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800045b0:	4685                	li	a3,1
    800045b2:	01590633          	add	a2,s2,s5
    800045b6:	faf40593          	addi	a1,s0,-81
    800045ba:	0509b503          	ld	a0,80(s3)
    800045be:	908fd0ef          	jal	800016c6 <copyin>
    800045c2:	03650e63          	beq	a0,s6,800045fe <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800045c6:	21c4a783          	lw	a5,540(s1)
    800045ca:	0017871b          	addiw	a4,a5,1
    800045ce:	20e4ae23          	sw	a4,540(s1)
    800045d2:	1ff7f793          	andi	a5,a5,511
    800045d6:	97a6                	add	a5,a5,s1
    800045d8:	faf44703          	lbu	a4,-81(s0)
    800045dc:	00e78c23          	sb	a4,24(a5)
      i++;
    800045e0:	2905                	addiw	s2,s2,1
    800045e2:	b775                	j	8000458e <pipewrite+0x6c>
    800045e4:	7b02                	ld	s6,32(sp)
    800045e6:	6be2                	ld	s7,24(sp)
    800045e8:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    800045ea:	21848513          	addi	a0,s1,536
    800045ee:	a1dfd0ef          	jal	8000200a <wakeup>
  release(&pi->lock);
    800045f2:	8526                	mv	a0,s1
    800045f4:	e72fc0ef          	jal	80000c66 <release>
  return i;
    800045f8:	bf95                	j	8000456c <pipewrite+0x4a>
  int i = 0;
    800045fa:	4901                	li	s2,0
    800045fc:	b7fd                	j	800045ea <pipewrite+0xc8>
    800045fe:	7b02                	ld	s6,32(sp)
    80004600:	6be2                	ld	s7,24(sp)
    80004602:	6c42                	ld	s8,16(sp)
    80004604:	b7dd                	j	800045ea <pipewrite+0xc8>

0000000080004606 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004606:	715d                	addi	sp,sp,-80
    80004608:	e486                	sd	ra,72(sp)
    8000460a:	e0a2                	sd	s0,64(sp)
    8000460c:	fc26                	sd	s1,56(sp)
    8000460e:	f84a                	sd	s2,48(sp)
    80004610:	f44e                	sd	s3,40(sp)
    80004612:	f052                	sd	s4,32(sp)
    80004614:	ec56                	sd	s5,24(sp)
    80004616:	0880                	addi	s0,sp,80
    80004618:	84aa                	mv	s1,a0
    8000461a:	892e                	mv	s2,a1
    8000461c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000461e:	ab0fd0ef          	jal	800018ce <myproc>
    80004622:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004624:	8526                	mv	a0,s1
    80004626:	da8fc0ef          	jal	80000bce <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000462a:	2184a703          	lw	a4,536(s1)
    8000462e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004632:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004636:	02f71563          	bne	a4,a5,80004660 <piperead+0x5a>
    8000463a:	2244a783          	lw	a5,548(s1)
    8000463e:	cb85                	beqz	a5,8000466e <piperead+0x68>
    if(killed(pr)){
    80004640:	8552                	mv	a0,s4
    80004642:	bb5fd0ef          	jal	800021f6 <killed>
    80004646:	ed19                	bnez	a0,80004664 <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004648:	85a6                	mv	a1,s1
    8000464a:	854e                	mv	a0,s3
    8000464c:	973fd0ef          	jal	80001fbe <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004650:	2184a703          	lw	a4,536(s1)
    80004654:	21c4a783          	lw	a5,540(s1)
    80004658:	fef701e3          	beq	a4,a5,8000463a <piperead+0x34>
    8000465c:	e85a                	sd	s6,16(sp)
    8000465e:	a809                	j	80004670 <piperead+0x6a>
    80004660:	e85a                	sd	s6,16(sp)
    80004662:	a039                	j	80004670 <piperead+0x6a>
      release(&pi->lock);
    80004664:	8526                	mv	a0,s1
    80004666:	e00fc0ef          	jal	80000c66 <release>
      return -1;
    8000466a:	59fd                	li	s3,-1
    8000466c:	a8b9                	j	800046ca <piperead+0xc4>
    8000466e:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004670:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004672:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004674:	05505363          	blez	s5,800046ba <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004678:	2184a783          	lw	a5,536(s1)
    8000467c:	21c4a703          	lw	a4,540(s1)
    80004680:	02f70d63          	beq	a4,a5,800046ba <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    80004684:	1ff7f793          	andi	a5,a5,511
    80004688:	97a6                	add	a5,a5,s1
    8000468a:	0187c783          	lbu	a5,24(a5)
    8000468e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004692:	4685                	li	a3,1
    80004694:	fbf40613          	addi	a2,s0,-65
    80004698:	85ca                	mv	a1,s2
    8000469a:	050a3503          	ld	a0,80(s4)
    8000469e:	f45fc0ef          	jal	800015e2 <copyout>
    800046a2:	03650e63          	beq	a0,s6,800046de <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    800046a6:	2184a783          	lw	a5,536(s1)
    800046aa:	2785                	addiw	a5,a5,1
    800046ac:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046b0:	2985                	addiw	s3,s3,1
    800046b2:	0905                	addi	s2,s2,1
    800046b4:	fd3a92e3          	bne	s5,s3,80004678 <piperead+0x72>
    800046b8:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800046ba:	21c48513          	addi	a0,s1,540
    800046be:	94dfd0ef          	jal	8000200a <wakeup>
  release(&pi->lock);
    800046c2:	8526                	mv	a0,s1
    800046c4:	da2fc0ef          	jal	80000c66 <release>
    800046c8:	6b42                	ld	s6,16(sp)
  return i;
}
    800046ca:	854e                	mv	a0,s3
    800046cc:	60a6                	ld	ra,72(sp)
    800046ce:	6406                	ld	s0,64(sp)
    800046d0:	74e2                	ld	s1,56(sp)
    800046d2:	7942                	ld	s2,48(sp)
    800046d4:	79a2                	ld	s3,40(sp)
    800046d6:	7a02                	ld	s4,32(sp)
    800046d8:	6ae2                	ld	s5,24(sp)
    800046da:	6161                	addi	sp,sp,80
    800046dc:	8082                	ret
      if(i == 0)
    800046de:	fc099ee3          	bnez	s3,800046ba <piperead+0xb4>
        i = -1;
    800046e2:	89aa                	mv	s3,a0
    800046e4:	bfd9                	j	800046ba <piperead+0xb4>

00000000800046e6 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    800046e6:	1141                	addi	sp,sp,-16
    800046e8:	e422                	sd	s0,8(sp)
    800046ea:	0800                	addi	s0,sp,16
    800046ec:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800046ee:	8905                	andi	a0,a0,1
    800046f0:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800046f2:	8b89                	andi	a5,a5,2
    800046f4:	c399                	beqz	a5,800046fa <flags2perm+0x14>
      perm |= PTE_W;
    800046f6:	00456513          	ori	a0,a0,4
    return perm;
}
    800046fa:	6422                	ld	s0,8(sp)
    800046fc:	0141                	addi	sp,sp,16
    800046fe:	8082                	ret

0000000080004700 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004700:	df010113          	addi	sp,sp,-528
    80004704:	20113423          	sd	ra,520(sp)
    80004708:	20813023          	sd	s0,512(sp)
    8000470c:	ffa6                	sd	s1,504(sp)
    8000470e:	fbca                	sd	s2,496(sp)
    80004710:	0c00                	addi	s0,sp,528
    80004712:	892a                	mv	s2,a0
    80004714:	dea43c23          	sd	a0,-520(s0)
    80004718:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000471c:	9b2fd0ef          	jal	800018ce <myproc>
    80004720:	84aa                	mv	s1,a0

  begin_op();
    80004722:	dcaff0ef          	jal	80003cec <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004726:	854a                	mv	a0,s2
    80004728:	bf0ff0ef          	jal	80003b18 <namei>
    8000472c:	c931                	beqz	a0,80004780 <kexec+0x80>
    8000472e:	f3d2                	sd	s4,480(sp)
    80004730:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004732:	bd1fe0ef          	jal	80003302 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004736:	04000713          	li	a4,64
    8000473a:	4681                	li	a3,0
    8000473c:	e5040613          	addi	a2,s0,-432
    80004740:	4581                	li	a1,0
    80004742:	8552                	mv	a0,s4
    80004744:	f4ffe0ef          	jal	80003692 <readi>
    80004748:	04000793          	li	a5,64
    8000474c:	00f51a63          	bne	a0,a5,80004760 <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    80004750:	e5042703          	lw	a4,-432(s0)
    80004754:	464c47b7          	lui	a5,0x464c4
    80004758:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000475c:	02f70663          	beq	a4,a5,80004788 <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004760:	8552                	mv	a0,s4
    80004762:	dabfe0ef          	jal	8000350c <iunlockput>
    end_op();
    80004766:	df0ff0ef          	jal	80003d56 <end_op>
  }
  return -1;
    8000476a:	557d                	li	a0,-1
    8000476c:	7a1e                	ld	s4,480(sp)
}
    8000476e:	20813083          	ld	ra,520(sp)
    80004772:	20013403          	ld	s0,512(sp)
    80004776:	74fe                	ld	s1,504(sp)
    80004778:	795e                	ld	s2,496(sp)
    8000477a:	21010113          	addi	sp,sp,528
    8000477e:	8082                	ret
    end_op();
    80004780:	dd6ff0ef          	jal	80003d56 <end_op>
    return -1;
    80004784:	557d                	li	a0,-1
    80004786:	b7e5                	j	8000476e <kexec+0x6e>
    80004788:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    8000478a:	8526                	mv	a0,s1
    8000478c:	abcfd0ef          	jal	80001a48 <proc_pagetable>
    80004790:	8b2a                	mv	s6,a0
    80004792:	2c050b63          	beqz	a0,80004a68 <kexec+0x368>
    80004796:	f7ce                	sd	s3,488(sp)
    80004798:	efd6                	sd	s5,472(sp)
    8000479a:	e7de                	sd	s7,456(sp)
    8000479c:	e3e2                	sd	s8,448(sp)
    8000479e:	ff66                	sd	s9,440(sp)
    800047a0:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800047a2:	e7042d03          	lw	s10,-400(s0)
    800047a6:	e8845783          	lhu	a5,-376(s0)
    800047aa:	12078963          	beqz	a5,800048dc <kexec+0x1dc>
    800047ae:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800047b0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800047b2:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800047b4:	6c85                	lui	s9,0x1
    800047b6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800047ba:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800047be:	6a85                	lui	s5,0x1
    800047c0:	a085                	j	80004820 <kexec+0x120>
      panic("loadseg: address should exist");
    800047c2:	00003517          	auipc	a0,0x3
    800047c6:	dde50513          	addi	a0,a0,-546 # 800075a0 <etext+0x5a0>
    800047ca:	816fc0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    800047ce:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800047d0:	8726                	mv	a4,s1
    800047d2:	012c06bb          	addw	a3,s8,s2
    800047d6:	4581                	li	a1,0
    800047d8:	8552                	mv	a0,s4
    800047da:	eb9fe0ef          	jal	80003692 <readi>
    800047de:	2501                	sext.w	a0,a0
    800047e0:	24a49a63          	bne	s1,a0,80004a34 <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    800047e4:	012a893b          	addw	s2,s5,s2
    800047e8:	03397363          	bgeu	s2,s3,8000480e <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    800047ec:	02091593          	slli	a1,s2,0x20
    800047f0:	9181                	srli	a1,a1,0x20
    800047f2:	95de                	add	a1,a1,s7
    800047f4:	855a                	mv	a0,s6
    800047f6:	fbafc0ef          	jal	80000fb0 <walkaddr>
    800047fa:	862a                	mv	a2,a0
    if(pa == 0)
    800047fc:	d179                	beqz	a0,800047c2 <kexec+0xc2>
    if(sz - i < PGSIZE)
    800047fe:	412984bb          	subw	s1,s3,s2
    80004802:	0004879b          	sext.w	a5,s1
    80004806:	fcfcf4e3          	bgeu	s9,a5,800047ce <kexec+0xce>
    8000480a:	84d6                	mv	s1,s5
    8000480c:	b7c9                	j	800047ce <kexec+0xce>
    sz = sz1;
    8000480e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004812:	2d85                	addiw	s11,s11,1
    80004814:	038d0d1b          	addiw	s10,s10,56 # 1038 <_entry-0x7fffefc8>
    80004818:	e8845783          	lhu	a5,-376(s0)
    8000481c:	08fdd063          	bge	s11,a5,8000489c <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004820:	2d01                	sext.w	s10,s10
    80004822:	03800713          	li	a4,56
    80004826:	86ea                	mv	a3,s10
    80004828:	e1840613          	addi	a2,s0,-488
    8000482c:	4581                	li	a1,0
    8000482e:	8552                	mv	a0,s4
    80004830:	e63fe0ef          	jal	80003692 <readi>
    80004834:	03800793          	li	a5,56
    80004838:	1cf51663          	bne	a0,a5,80004a04 <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    8000483c:	e1842783          	lw	a5,-488(s0)
    80004840:	4705                	li	a4,1
    80004842:	fce798e3          	bne	a5,a4,80004812 <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80004846:	e4043483          	ld	s1,-448(s0)
    8000484a:	e3843783          	ld	a5,-456(s0)
    8000484e:	1af4ef63          	bltu	s1,a5,80004a0c <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004852:	e2843783          	ld	a5,-472(s0)
    80004856:	94be                	add	s1,s1,a5
    80004858:	1af4ee63          	bltu	s1,a5,80004a14 <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    8000485c:	df043703          	ld	a4,-528(s0)
    80004860:	8ff9                	and	a5,a5,a4
    80004862:	1a079d63          	bnez	a5,80004a1c <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004866:	e1c42503          	lw	a0,-484(s0)
    8000486a:	e7dff0ef          	jal	800046e6 <flags2perm>
    8000486e:	86aa                	mv	a3,a0
    80004870:	8626                	mv	a2,s1
    80004872:	85ca                	mv	a1,s2
    80004874:	855a                	mv	a0,s6
    80004876:	a13fc0ef          	jal	80001288 <uvmalloc>
    8000487a:	e0a43423          	sd	a0,-504(s0)
    8000487e:	1a050363          	beqz	a0,80004a24 <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004882:	e2843b83          	ld	s7,-472(s0)
    80004886:	e2042c03          	lw	s8,-480(s0)
    8000488a:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000488e:	00098463          	beqz	s3,80004896 <kexec+0x196>
    80004892:	4901                	li	s2,0
    80004894:	bfa1                	j	800047ec <kexec+0xec>
    sz = sz1;
    80004896:	e0843903          	ld	s2,-504(s0)
    8000489a:	bfa5                	j	80004812 <kexec+0x112>
    8000489c:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    8000489e:	8552                	mv	a0,s4
    800048a0:	c6dfe0ef          	jal	8000350c <iunlockput>
  end_op();
    800048a4:	cb2ff0ef          	jal	80003d56 <end_op>
  p = myproc();
    800048a8:	826fd0ef          	jal	800018ce <myproc>
    800048ac:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800048ae:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800048b2:	6985                	lui	s3,0x1
    800048b4:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800048b6:	99ca                	add	s3,s3,s2
    800048b8:	77fd                	lui	a5,0xfffff
    800048ba:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800048be:	4691                	li	a3,4
    800048c0:	6609                	lui	a2,0x2
    800048c2:	964e                	add	a2,a2,s3
    800048c4:	85ce                	mv	a1,s3
    800048c6:	855a                	mv	a0,s6
    800048c8:	9c1fc0ef          	jal	80001288 <uvmalloc>
    800048cc:	892a                	mv	s2,a0
    800048ce:	e0a43423          	sd	a0,-504(s0)
    800048d2:	e519                	bnez	a0,800048e0 <kexec+0x1e0>
  if(pagetable)
    800048d4:	e1343423          	sd	s3,-504(s0)
    800048d8:	4a01                	li	s4,0
    800048da:	aab1                	j	80004a36 <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800048dc:	4901                	li	s2,0
    800048de:	b7c1                	j	8000489e <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800048e0:	75f9                	lui	a1,0xffffe
    800048e2:	95aa                	add	a1,a1,a0
    800048e4:	855a                	mv	a0,s6
    800048e6:	b79fc0ef          	jal	8000145e <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800048ea:	7bfd                	lui	s7,0xfffff
    800048ec:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800048ee:	e0043783          	ld	a5,-512(s0)
    800048f2:	6388                	ld	a0,0(a5)
    800048f4:	cd39                	beqz	a0,80004952 <kexec+0x252>
    800048f6:	e9040993          	addi	s3,s0,-368
    800048fa:	f9040c13          	addi	s8,s0,-112
    800048fe:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004900:	d12fc0ef          	jal	80000e12 <strlen>
    80004904:	0015079b          	addiw	a5,a0,1
    80004908:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000490c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004910:	11796e63          	bltu	s2,s7,80004a2c <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004914:	e0043d03          	ld	s10,-512(s0)
    80004918:	000d3a03          	ld	s4,0(s10)
    8000491c:	8552                	mv	a0,s4
    8000491e:	cf4fc0ef          	jal	80000e12 <strlen>
    80004922:	0015069b          	addiw	a3,a0,1
    80004926:	8652                	mv	a2,s4
    80004928:	85ca                	mv	a1,s2
    8000492a:	855a                	mv	a0,s6
    8000492c:	cb7fc0ef          	jal	800015e2 <copyout>
    80004930:	10054063          	bltz	a0,80004a30 <kexec+0x330>
    ustack[argc] = sp;
    80004934:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004938:	0485                	addi	s1,s1,1
    8000493a:	008d0793          	addi	a5,s10,8
    8000493e:	e0f43023          	sd	a5,-512(s0)
    80004942:	008d3503          	ld	a0,8(s10)
    80004946:	c909                	beqz	a0,80004958 <kexec+0x258>
    if(argc >= MAXARG)
    80004948:	09a1                	addi	s3,s3,8
    8000494a:	fb899be3          	bne	s3,s8,80004900 <kexec+0x200>
  ip = 0;
    8000494e:	4a01                	li	s4,0
    80004950:	a0dd                	j	80004a36 <kexec+0x336>
  sp = sz;
    80004952:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004956:	4481                	li	s1,0
  ustack[argc] = 0;
    80004958:	00349793          	slli	a5,s1,0x3
    8000495c:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdb848>
    80004960:	97a2                	add	a5,a5,s0
    80004962:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004966:	00148693          	addi	a3,s1,1
    8000496a:	068e                	slli	a3,a3,0x3
    8000496c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004970:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004974:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004978:	f5796ee3          	bltu	s2,s7,800048d4 <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000497c:	e9040613          	addi	a2,s0,-368
    80004980:	85ca                	mv	a1,s2
    80004982:	855a                	mv	a0,s6
    80004984:	c5ffc0ef          	jal	800015e2 <copyout>
    80004988:	0e054263          	bltz	a0,80004a6c <kexec+0x36c>
  p->trapframe->a1 = sp;
    8000498c:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004990:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004994:	df843783          	ld	a5,-520(s0)
    80004998:	0007c703          	lbu	a4,0(a5)
    8000499c:	cf11                	beqz	a4,800049b8 <kexec+0x2b8>
    8000499e:	0785                	addi	a5,a5,1
    if(*s == '/')
    800049a0:	02f00693          	li	a3,47
    800049a4:	a039                	j	800049b2 <kexec+0x2b2>
      last = s+1;
    800049a6:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800049aa:	0785                	addi	a5,a5,1
    800049ac:	fff7c703          	lbu	a4,-1(a5)
    800049b0:	c701                	beqz	a4,800049b8 <kexec+0x2b8>
    if(*s == '/')
    800049b2:	fed71ce3          	bne	a4,a3,800049aa <kexec+0x2aa>
    800049b6:	bfc5                	j	800049a6 <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    800049b8:	4641                	li	a2,16
    800049ba:	df843583          	ld	a1,-520(s0)
    800049be:	160a8513          	addi	a0,s5,352
    800049c2:	c1efc0ef          	jal	80000de0 <safestrcpy>
  oldpagetable = p->pagetable;
    800049c6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800049ca:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800049ce:	e0843783          	ld	a5,-504(s0)
    800049d2:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    800049d6:	058ab783          	ld	a5,88(s5)
    800049da:	e6843703          	ld	a4,-408(s0)
    800049de:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800049e0:	058ab783          	ld	a5,88(s5)
    800049e4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800049e8:	85e6                	mv	a1,s9
    800049ea:	8e2fd0ef          	jal	80001acc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800049ee:	0004851b          	sext.w	a0,s1
    800049f2:	79be                	ld	s3,488(sp)
    800049f4:	7a1e                	ld	s4,480(sp)
    800049f6:	6afe                	ld	s5,472(sp)
    800049f8:	6b5e                	ld	s6,464(sp)
    800049fa:	6bbe                	ld	s7,456(sp)
    800049fc:	6c1e                	ld	s8,448(sp)
    800049fe:	7cfa                	ld	s9,440(sp)
    80004a00:	7d5a                	ld	s10,432(sp)
    80004a02:	b3b5                	j	8000476e <kexec+0x6e>
    80004a04:	e1243423          	sd	s2,-504(s0)
    80004a08:	7dba                	ld	s11,424(sp)
    80004a0a:	a035                	j	80004a36 <kexec+0x336>
    80004a0c:	e1243423          	sd	s2,-504(s0)
    80004a10:	7dba                	ld	s11,424(sp)
    80004a12:	a015                	j	80004a36 <kexec+0x336>
    80004a14:	e1243423          	sd	s2,-504(s0)
    80004a18:	7dba                	ld	s11,424(sp)
    80004a1a:	a831                	j	80004a36 <kexec+0x336>
    80004a1c:	e1243423          	sd	s2,-504(s0)
    80004a20:	7dba                	ld	s11,424(sp)
    80004a22:	a811                	j	80004a36 <kexec+0x336>
    80004a24:	e1243423          	sd	s2,-504(s0)
    80004a28:	7dba                	ld	s11,424(sp)
    80004a2a:	a031                	j	80004a36 <kexec+0x336>
  ip = 0;
    80004a2c:	4a01                	li	s4,0
    80004a2e:	a021                	j	80004a36 <kexec+0x336>
    80004a30:	4a01                	li	s4,0
  if(pagetable)
    80004a32:	a011                	j	80004a36 <kexec+0x336>
    80004a34:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80004a36:	e0843583          	ld	a1,-504(s0)
    80004a3a:	855a                	mv	a0,s6
    80004a3c:	890fd0ef          	jal	80001acc <proc_freepagetable>
  return -1;
    80004a40:	557d                	li	a0,-1
  if(ip){
    80004a42:	000a1b63          	bnez	s4,80004a58 <kexec+0x358>
    80004a46:	79be                	ld	s3,488(sp)
    80004a48:	7a1e                	ld	s4,480(sp)
    80004a4a:	6afe                	ld	s5,472(sp)
    80004a4c:	6b5e                	ld	s6,464(sp)
    80004a4e:	6bbe                	ld	s7,456(sp)
    80004a50:	6c1e                	ld	s8,448(sp)
    80004a52:	7cfa                	ld	s9,440(sp)
    80004a54:	7d5a                	ld	s10,432(sp)
    80004a56:	bb21                	j	8000476e <kexec+0x6e>
    80004a58:	79be                	ld	s3,488(sp)
    80004a5a:	6afe                	ld	s5,472(sp)
    80004a5c:	6b5e                	ld	s6,464(sp)
    80004a5e:	6bbe                	ld	s7,456(sp)
    80004a60:	6c1e                	ld	s8,448(sp)
    80004a62:	7cfa                	ld	s9,440(sp)
    80004a64:	7d5a                	ld	s10,432(sp)
    80004a66:	b9ed                	j	80004760 <kexec+0x60>
    80004a68:	6b5e                	ld	s6,464(sp)
    80004a6a:	b9dd                	j	80004760 <kexec+0x60>
  sz = sz1;
    80004a6c:	e0843983          	ld	s3,-504(s0)
    80004a70:	b595                	j	800048d4 <kexec+0x1d4>

0000000080004a72 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004a72:	7179                	addi	sp,sp,-48
    80004a74:	f406                	sd	ra,40(sp)
    80004a76:	f022                	sd	s0,32(sp)
    80004a78:	ec26                	sd	s1,24(sp)
    80004a7a:	e84a                	sd	s2,16(sp)
    80004a7c:	1800                	addi	s0,sp,48
    80004a7e:	892e                	mv	s2,a1
    80004a80:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004a82:	fdc40593          	addi	a1,s0,-36
    80004a86:	e33fd0ef          	jal	800028b8 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004a8a:	fdc42703          	lw	a4,-36(s0)
    80004a8e:	47bd                	li	a5,15
    80004a90:	02e7e963          	bltu	a5,a4,80004ac2 <argfd+0x50>
    80004a94:	e3bfc0ef          	jal	800018ce <myproc>
    80004a98:	fdc42703          	lw	a4,-36(s0)
    80004a9c:	01a70793          	addi	a5,a4,26
    80004aa0:	078e                	slli	a5,a5,0x3
    80004aa2:	953e                	add	a0,a0,a5
    80004aa4:	611c                	ld	a5,0(a0)
    80004aa6:	c385                	beqz	a5,80004ac6 <argfd+0x54>
    return -1;
  if(pfd)
    80004aa8:	00090463          	beqz	s2,80004ab0 <argfd+0x3e>
    *pfd = fd;
    80004aac:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ab0:	4501                	li	a0,0
  if(pf)
    80004ab2:	c091                	beqz	s1,80004ab6 <argfd+0x44>
    *pf = f;
    80004ab4:	e09c                	sd	a5,0(s1)
}
    80004ab6:	70a2                	ld	ra,40(sp)
    80004ab8:	7402                	ld	s0,32(sp)
    80004aba:	64e2                	ld	s1,24(sp)
    80004abc:	6942                	ld	s2,16(sp)
    80004abe:	6145                	addi	sp,sp,48
    80004ac0:	8082                	ret
    return -1;
    80004ac2:	557d                	li	a0,-1
    80004ac4:	bfcd                	j	80004ab6 <argfd+0x44>
    80004ac6:	557d                	li	a0,-1
    80004ac8:	b7fd                	j	80004ab6 <argfd+0x44>

0000000080004aca <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004aca:	1101                	addi	sp,sp,-32
    80004acc:	ec06                	sd	ra,24(sp)
    80004ace:	e822                	sd	s0,16(sp)
    80004ad0:	e426                	sd	s1,8(sp)
    80004ad2:	1000                	addi	s0,sp,32
    80004ad4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004ad6:	df9fc0ef          	jal	800018ce <myproc>
    80004ada:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004adc:	0d050793          	addi	a5,a0,208
    80004ae0:	4501                	li	a0,0
    80004ae2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ae4:	6398                	ld	a4,0(a5)
    80004ae6:	cb19                	beqz	a4,80004afc <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004ae8:	2505                	addiw	a0,a0,1
    80004aea:	07a1                	addi	a5,a5,8
    80004aec:	fed51ce3          	bne	a0,a3,80004ae4 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004af0:	557d                	li	a0,-1
}
    80004af2:	60e2                	ld	ra,24(sp)
    80004af4:	6442                	ld	s0,16(sp)
    80004af6:	64a2                	ld	s1,8(sp)
    80004af8:	6105                	addi	sp,sp,32
    80004afa:	8082                	ret
      p->ofile[fd] = f;
    80004afc:	01a50793          	addi	a5,a0,26
    80004b00:	078e                	slli	a5,a5,0x3
    80004b02:	963e                	add	a2,a2,a5
    80004b04:	e204                	sd	s1,0(a2)
      return fd;
    80004b06:	b7f5                	j	80004af2 <fdalloc+0x28>

0000000080004b08 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004b08:	715d                	addi	sp,sp,-80
    80004b0a:	e486                	sd	ra,72(sp)
    80004b0c:	e0a2                	sd	s0,64(sp)
    80004b0e:	fc26                	sd	s1,56(sp)
    80004b10:	f84a                	sd	s2,48(sp)
    80004b12:	f44e                	sd	s3,40(sp)
    80004b14:	ec56                	sd	s5,24(sp)
    80004b16:	e85a                	sd	s6,16(sp)
    80004b18:	0880                	addi	s0,sp,80
    80004b1a:	8b2e                	mv	s6,a1
    80004b1c:	89b2                	mv	s3,a2
    80004b1e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004b20:	fb040593          	addi	a1,s0,-80
    80004b24:	80eff0ef          	jal	80003b32 <nameiparent>
    80004b28:	84aa                	mv	s1,a0
    80004b2a:	10050a63          	beqz	a0,80004c3e <create+0x136>
    return 0;

  ilock(dp);
    80004b2e:	fd4fe0ef          	jal	80003302 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004b32:	4601                	li	a2,0
    80004b34:	fb040593          	addi	a1,s0,-80
    80004b38:	8526                	mv	a0,s1
    80004b3a:	d79fe0ef          	jal	800038b2 <dirlookup>
    80004b3e:	8aaa                	mv	s5,a0
    80004b40:	c129                	beqz	a0,80004b82 <create+0x7a>
    iunlockput(dp);
    80004b42:	8526                	mv	a0,s1
    80004b44:	9c9fe0ef          	jal	8000350c <iunlockput>
    ilock(ip);
    80004b48:	8556                	mv	a0,s5
    80004b4a:	fb8fe0ef          	jal	80003302 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004b4e:	4789                	li	a5,2
    80004b50:	02fb1463          	bne	s6,a5,80004b78 <create+0x70>
    80004b54:	044ad783          	lhu	a5,68(s5)
    80004b58:	37f9                	addiw	a5,a5,-2
    80004b5a:	17c2                	slli	a5,a5,0x30
    80004b5c:	93c1                	srli	a5,a5,0x30
    80004b5e:	4705                	li	a4,1
    80004b60:	00f76c63          	bltu	a4,a5,80004b78 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004b64:	8556                	mv	a0,s5
    80004b66:	60a6                	ld	ra,72(sp)
    80004b68:	6406                	ld	s0,64(sp)
    80004b6a:	74e2                	ld	s1,56(sp)
    80004b6c:	7942                	ld	s2,48(sp)
    80004b6e:	79a2                	ld	s3,40(sp)
    80004b70:	6ae2                	ld	s5,24(sp)
    80004b72:	6b42                	ld	s6,16(sp)
    80004b74:	6161                	addi	sp,sp,80
    80004b76:	8082                	ret
    iunlockput(ip);
    80004b78:	8556                	mv	a0,s5
    80004b7a:	993fe0ef          	jal	8000350c <iunlockput>
    return 0;
    80004b7e:	4a81                	li	s5,0
    80004b80:	b7d5                	j	80004b64 <create+0x5c>
    80004b82:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004b84:	85da                	mv	a1,s6
    80004b86:	4088                	lw	a0,0(s1)
    80004b88:	e0afe0ef          	jal	80003192 <ialloc>
    80004b8c:	8a2a                	mv	s4,a0
    80004b8e:	cd15                	beqz	a0,80004bca <create+0xc2>
  ilock(ip);
    80004b90:	f72fe0ef          	jal	80003302 <ilock>
  ip->major = major;
    80004b94:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004b98:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004b9c:	4905                	li	s2,1
    80004b9e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004ba2:	8552                	mv	a0,s4
    80004ba4:	eaafe0ef          	jal	8000324e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004ba8:	032b0763          	beq	s6,s2,80004bd6 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004bac:	004a2603          	lw	a2,4(s4)
    80004bb0:	fb040593          	addi	a1,s0,-80
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	ec9fe0ef          	jal	80003a7e <dirlink>
    80004bba:	06054563          	bltz	a0,80004c24 <create+0x11c>
  iunlockput(dp);
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	94dfe0ef          	jal	8000350c <iunlockput>
  return ip;
    80004bc4:	8ad2                	mv	s5,s4
    80004bc6:	7a02                	ld	s4,32(sp)
    80004bc8:	bf71                	j	80004b64 <create+0x5c>
    iunlockput(dp);
    80004bca:	8526                	mv	a0,s1
    80004bcc:	941fe0ef          	jal	8000350c <iunlockput>
    return 0;
    80004bd0:	8ad2                	mv	s5,s4
    80004bd2:	7a02                	ld	s4,32(sp)
    80004bd4:	bf41                	j	80004b64 <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004bd6:	004a2603          	lw	a2,4(s4)
    80004bda:	00003597          	auipc	a1,0x3
    80004bde:	9e658593          	addi	a1,a1,-1562 # 800075c0 <etext+0x5c0>
    80004be2:	8552                	mv	a0,s4
    80004be4:	e9bfe0ef          	jal	80003a7e <dirlink>
    80004be8:	02054e63          	bltz	a0,80004c24 <create+0x11c>
    80004bec:	40d0                	lw	a2,4(s1)
    80004bee:	00003597          	auipc	a1,0x3
    80004bf2:	9da58593          	addi	a1,a1,-1574 # 800075c8 <etext+0x5c8>
    80004bf6:	8552                	mv	a0,s4
    80004bf8:	e87fe0ef          	jal	80003a7e <dirlink>
    80004bfc:	02054463          	bltz	a0,80004c24 <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004c00:	004a2603          	lw	a2,4(s4)
    80004c04:	fb040593          	addi	a1,s0,-80
    80004c08:	8526                	mv	a0,s1
    80004c0a:	e75fe0ef          	jal	80003a7e <dirlink>
    80004c0e:	00054b63          	bltz	a0,80004c24 <create+0x11c>
    dp->nlink++;  // for ".."
    80004c12:	04a4d783          	lhu	a5,74(s1)
    80004c16:	2785                	addiw	a5,a5,1
    80004c18:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004c1c:	8526                	mv	a0,s1
    80004c1e:	e30fe0ef          	jal	8000324e <iupdate>
    80004c22:	bf71                	j	80004bbe <create+0xb6>
  ip->nlink = 0;
    80004c24:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004c28:	8552                	mv	a0,s4
    80004c2a:	e24fe0ef          	jal	8000324e <iupdate>
  iunlockput(ip);
    80004c2e:	8552                	mv	a0,s4
    80004c30:	8ddfe0ef          	jal	8000350c <iunlockput>
  iunlockput(dp);
    80004c34:	8526                	mv	a0,s1
    80004c36:	8d7fe0ef          	jal	8000350c <iunlockput>
  return 0;
    80004c3a:	7a02                	ld	s4,32(sp)
    80004c3c:	b725                	j	80004b64 <create+0x5c>
    return 0;
    80004c3e:	8aaa                	mv	s5,a0
    80004c40:	b715                	j	80004b64 <create+0x5c>

0000000080004c42 <sys_dup>:
{
    80004c42:	7179                	addi	sp,sp,-48
    80004c44:	f406                	sd	ra,40(sp)
    80004c46:	f022                	sd	s0,32(sp)
    80004c48:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004c4a:	fd840613          	addi	a2,s0,-40
    80004c4e:	4581                	li	a1,0
    80004c50:	4501                	li	a0,0
    80004c52:	e21ff0ef          	jal	80004a72 <argfd>
    return -1;
    80004c56:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004c58:	02054363          	bltz	a0,80004c7e <sys_dup+0x3c>
    80004c5c:	ec26                	sd	s1,24(sp)
    80004c5e:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004c60:	fd843903          	ld	s2,-40(s0)
    80004c64:	854a                	mv	a0,s2
    80004c66:	e65ff0ef          	jal	80004aca <fdalloc>
    80004c6a:	84aa                	mv	s1,a0
    return -1;
    80004c6c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004c6e:	00054d63          	bltz	a0,80004c88 <sys_dup+0x46>
  filedup(f);
    80004c72:	854a                	mv	a0,s2
    80004c74:	c3eff0ef          	jal	800040b2 <filedup>
  return fd;
    80004c78:	87a6                	mv	a5,s1
    80004c7a:	64e2                	ld	s1,24(sp)
    80004c7c:	6942                	ld	s2,16(sp)
}
    80004c7e:	853e                	mv	a0,a5
    80004c80:	70a2                	ld	ra,40(sp)
    80004c82:	7402                	ld	s0,32(sp)
    80004c84:	6145                	addi	sp,sp,48
    80004c86:	8082                	ret
    80004c88:	64e2                	ld	s1,24(sp)
    80004c8a:	6942                	ld	s2,16(sp)
    80004c8c:	bfcd                	j	80004c7e <sys_dup+0x3c>

0000000080004c8e <sys_read>:
{
    80004c8e:	7179                	addi	sp,sp,-48
    80004c90:	f406                	sd	ra,40(sp)
    80004c92:	f022                	sd	s0,32(sp)
    80004c94:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004c96:	fd840593          	addi	a1,s0,-40
    80004c9a:	4505                	li	a0,1
    80004c9c:	c39fd0ef          	jal	800028d4 <argaddr>
  argint(2, &n);
    80004ca0:	fe440593          	addi	a1,s0,-28
    80004ca4:	4509                	li	a0,2
    80004ca6:	c13fd0ef          	jal	800028b8 <argint>
  if(argfd(0, 0, &f) < 0)
    80004caa:	fe840613          	addi	a2,s0,-24
    80004cae:	4581                	li	a1,0
    80004cb0:	4501                	li	a0,0
    80004cb2:	dc1ff0ef          	jal	80004a72 <argfd>
    80004cb6:	87aa                	mv	a5,a0
    return -1;
    80004cb8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004cba:	0007ca63          	bltz	a5,80004cce <sys_read+0x40>
  return fileread(f, p, n);
    80004cbe:	fe442603          	lw	a2,-28(s0)
    80004cc2:	fd843583          	ld	a1,-40(s0)
    80004cc6:	fe843503          	ld	a0,-24(s0)
    80004cca:	d4eff0ef          	jal	80004218 <fileread>
}
    80004cce:	70a2                	ld	ra,40(sp)
    80004cd0:	7402                	ld	s0,32(sp)
    80004cd2:	6145                	addi	sp,sp,48
    80004cd4:	8082                	ret

0000000080004cd6 <sys_write>:
{
    80004cd6:	7179                	addi	sp,sp,-48
    80004cd8:	f406                	sd	ra,40(sp)
    80004cda:	f022                	sd	s0,32(sp)
    80004cdc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004cde:	fd840593          	addi	a1,s0,-40
    80004ce2:	4505                	li	a0,1
    80004ce4:	bf1fd0ef          	jal	800028d4 <argaddr>
  argint(2, &n);
    80004ce8:	fe440593          	addi	a1,s0,-28
    80004cec:	4509                	li	a0,2
    80004cee:	bcbfd0ef          	jal	800028b8 <argint>
  if(argfd(0, 0, &f) < 0)
    80004cf2:	fe840613          	addi	a2,s0,-24
    80004cf6:	4581                	li	a1,0
    80004cf8:	4501                	li	a0,0
    80004cfa:	d79ff0ef          	jal	80004a72 <argfd>
    80004cfe:	87aa                	mv	a5,a0
    return -1;
    80004d00:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004d02:	0007ca63          	bltz	a5,80004d16 <sys_write+0x40>
  return filewrite(f, p, n);
    80004d06:	fe442603          	lw	a2,-28(s0)
    80004d0a:	fd843583          	ld	a1,-40(s0)
    80004d0e:	fe843503          	ld	a0,-24(s0)
    80004d12:	dc4ff0ef          	jal	800042d6 <filewrite>
}
    80004d16:	70a2                	ld	ra,40(sp)
    80004d18:	7402                	ld	s0,32(sp)
    80004d1a:	6145                	addi	sp,sp,48
    80004d1c:	8082                	ret

0000000080004d1e <sys_close>:
{
    80004d1e:	1101                	addi	sp,sp,-32
    80004d20:	ec06                	sd	ra,24(sp)
    80004d22:	e822                	sd	s0,16(sp)
    80004d24:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004d26:	fe040613          	addi	a2,s0,-32
    80004d2a:	fec40593          	addi	a1,s0,-20
    80004d2e:	4501                	li	a0,0
    80004d30:	d43ff0ef          	jal	80004a72 <argfd>
    return -1;
    80004d34:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004d36:	02054063          	bltz	a0,80004d56 <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004d3a:	b95fc0ef          	jal	800018ce <myproc>
    80004d3e:	fec42783          	lw	a5,-20(s0)
    80004d42:	07e9                	addi	a5,a5,26
    80004d44:	078e                	slli	a5,a5,0x3
    80004d46:	953e                	add	a0,a0,a5
    80004d48:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80004d4c:	fe043503          	ld	a0,-32(s0)
    80004d50:	ba8ff0ef          	jal	800040f8 <fileclose>
  return 0;
    80004d54:	4781                	li	a5,0
}
    80004d56:	853e                	mv	a0,a5
    80004d58:	60e2                	ld	ra,24(sp)
    80004d5a:	6442                	ld	s0,16(sp)
    80004d5c:	6105                	addi	sp,sp,32
    80004d5e:	8082                	ret

0000000080004d60 <sys_fstat>:
{
    80004d60:	1101                	addi	sp,sp,-32
    80004d62:	ec06                	sd	ra,24(sp)
    80004d64:	e822                	sd	s0,16(sp)
    80004d66:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004d68:	fe040593          	addi	a1,s0,-32
    80004d6c:	4505                	li	a0,1
    80004d6e:	b67fd0ef          	jal	800028d4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004d72:	fe840613          	addi	a2,s0,-24
    80004d76:	4581                	li	a1,0
    80004d78:	4501                	li	a0,0
    80004d7a:	cf9ff0ef          	jal	80004a72 <argfd>
    80004d7e:	87aa                	mv	a5,a0
    return -1;
    80004d80:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004d82:	0007c863          	bltz	a5,80004d92 <sys_fstat+0x32>
  return filestat(f, st);
    80004d86:	fe043583          	ld	a1,-32(s0)
    80004d8a:	fe843503          	ld	a0,-24(s0)
    80004d8e:	c2cff0ef          	jal	800041ba <filestat>
}
    80004d92:	60e2                	ld	ra,24(sp)
    80004d94:	6442                	ld	s0,16(sp)
    80004d96:	6105                	addi	sp,sp,32
    80004d98:	8082                	ret

0000000080004d9a <sys_link>:
{
    80004d9a:	7169                	addi	sp,sp,-304
    80004d9c:	f606                	sd	ra,296(sp)
    80004d9e:	f222                	sd	s0,288(sp)
    80004da0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004da2:	08000613          	li	a2,128
    80004da6:	ed040593          	addi	a1,s0,-304
    80004daa:	4501                	li	a0,0
    80004dac:	b45fd0ef          	jal	800028f0 <argstr>
    return -1;
    80004db0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004db2:	0c054e63          	bltz	a0,80004e8e <sys_link+0xf4>
    80004db6:	08000613          	li	a2,128
    80004dba:	f5040593          	addi	a1,s0,-176
    80004dbe:	4505                	li	a0,1
    80004dc0:	b31fd0ef          	jal	800028f0 <argstr>
    return -1;
    80004dc4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004dc6:	0c054463          	bltz	a0,80004e8e <sys_link+0xf4>
    80004dca:	ee26                	sd	s1,280(sp)
  begin_op();
    80004dcc:	f21fe0ef          	jal	80003cec <begin_op>
  if((ip = namei(old)) == 0){
    80004dd0:	ed040513          	addi	a0,s0,-304
    80004dd4:	d45fe0ef          	jal	80003b18 <namei>
    80004dd8:	84aa                	mv	s1,a0
    80004dda:	c53d                	beqz	a0,80004e48 <sys_link+0xae>
  ilock(ip);
    80004ddc:	d26fe0ef          	jal	80003302 <ilock>
  if(ip->type == T_DIR){
    80004de0:	04449703          	lh	a4,68(s1)
    80004de4:	4785                	li	a5,1
    80004de6:	06f70663          	beq	a4,a5,80004e52 <sys_link+0xb8>
    80004dea:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80004dec:	04a4d783          	lhu	a5,74(s1)
    80004df0:	2785                	addiw	a5,a5,1
    80004df2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004df6:	8526                	mv	a0,s1
    80004df8:	c56fe0ef          	jal	8000324e <iupdate>
  iunlock(ip);
    80004dfc:	8526                	mv	a0,s1
    80004dfe:	db2fe0ef          	jal	800033b0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004e02:	fd040593          	addi	a1,s0,-48
    80004e06:	f5040513          	addi	a0,s0,-176
    80004e0a:	d29fe0ef          	jal	80003b32 <nameiparent>
    80004e0e:	892a                	mv	s2,a0
    80004e10:	cd21                	beqz	a0,80004e68 <sys_link+0xce>
  ilock(dp);
    80004e12:	cf0fe0ef          	jal	80003302 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004e16:	00092703          	lw	a4,0(s2)
    80004e1a:	409c                	lw	a5,0(s1)
    80004e1c:	04f71363          	bne	a4,a5,80004e62 <sys_link+0xc8>
    80004e20:	40d0                	lw	a2,4(s1)
    80004e22:	fd040593          	addi	a1,s0,-48
    80004e26:	854a                	mv	a0,s2
    80004e28:	c57fe0ef          	jal	80003a7e <dirlink>
    80004e2c:	02054b63          	bltz	a0,80004e62 <sys_link+0xc8>
  iunlockput(dp);
    80004e30:	854a                	mv	a0,s2
    80004e32:	edafe0ef          	jal	8000350c <iunlockput>
  iput(ip);
    80004e36:	8526                	mv	a0,s1
    80004e38:	e4cfe0ef          	jal	80003484 <iput>
  end_op();
    80004e3c:	f1bfe0ef          	jal	80003d56 <end_op>
  return 0;
    80004e40:	4781                	li	a5,0
    80004e42:	64f2                	ld	s1,280(sp)
    80004e44:	6952                	ld	s2,272(sp)
    80004e46:	a0a1                	j	80004e8e <sys_link+0xf4>
    end_op();
    80004e48:	f0ffe0ef          	jal	80003d56 <end_op>
    return -1;
    80004e4c:	57fd                	li	a5,-1
    80004e4e:	64f2                	ld	s1,280(sp)
    80004e50:	a83d                	j	80004e8e <sys_link+0xf4>
    iunlockput(ip);
    80004e52:	8526                	mv	a0,s1
    80004e54:	eb8fe0ef          	jal	8000350c <iunlockput>
    end_op();
    80004e58:	efffe0ef          	jal	80003d56 <end_op>
    return -1;
    80004e5c:	57fd                	li	a5,-1
    80004e5e:	64f2                	ld	s1,280(sp)
    80004e60:	a03d                	j	80004e8e <sys_link+0xf4>
    iunlockput(dp);
    80004e62:	854a                	mv	a0,s2
    80004e64:	ea8fe0ef          	jal	8000350c <iunlockput>
  ilock(ip);
    80004e68:	8526                	mv	a0,s1
    80004e6a:	c98fe0ef          	jal	80003302 <ilock>
  ip->nlink--;
    80004e6e:	04a4d783          	lhu	a5,74(s1)
    80004e72:	37fd                	addiw	a5,a5,-1
    80004e74:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004e78:	8526                	mv	a0,s1
    80004e7a:	bd4fe0ef          	jal	8000324e <iupdate>
  iunlockput(ip);
    80004e7e:	8526                	mv	a0,s1
    80004e80:	e8cfe0ef          	jal	8000350c <iunlockput>
  end_op();
    80004e84:	ed3fe0ef          	jal	80003d56 <end_op>
  return -1;
    80004e88:	57fd                	li	a5,-1
    80004e8a:	64f2                	ld	s1,280(sp)
    80004e8c:	6952                	ld	s2,272(sp)
}
    80004e8e:	853e                	mv	a0,a5
    80004e90:	70b2                	ld	ra,296(sp)
    80004e92:	7412                	ld	s0,288(sp)
    80004e94:	6155                	addi	sp,sp,304
    80004e96:	8082                	ret

0000000080004e98 <sys_unlink>:
{
    80004e98:	7151                	addi	sp,sp,-240
    80004e9a:	f586                	sd	ra,232(sp)
    80004e9c:	f1a2                	sd	s0,224(sp)
    80004e9e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004ea0:	08000613          	li	a2,128
    80004ea4:	f3040593          	addi	a1,s0,-208
    80004ea8:	4501                	li	a0,0
    80004eaa:	a47fd0ef          	jal	800028f0 <argstr>
    80004eae:	16054063          	bltz	a0,8000500e <sys_unlink+0x176>
    80004eb2:	eda6                	sd	s1,216(sp)
  begin_op();
    80004eb4:	e39fe0ef          	jal	80003cec <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004eb8:	fb040593          	addi	a1,s0,-80
    80004ebc:	f3040513          	addi	a0,s0,-208
    80004ec0:	c73fe0ef          	jal	80003b32 <nameiparent>
    80004ec4:	84aa                	mv	s1,a0
    80004ec6:	c945                	beqz	a0,80004f76 <sys_unlink+0xde>
  ilock(dp);
    80004ec8:	c3afe0ef          	jal	80003302 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004ecc:	00002597          	auipc	a1,0x2
    80004ed0:	6f458593          	addi	a1,a1,1780 # 800075c0 <etext+0x5c0>
    80004ed4:	fb040513          	addi	a0,s0,-80
    80004ed8:	9c5fe0ef          	jal	8000389c <namecmp>
    80004edc:	10050e63          	beqz	a0,80004ff8 <sys_unlink+0x160>
    80004ee0:	00002597          	auipc	a1,0x2
    80004ee4:	6e858593          	addi	a1,a1,1768 # 800075c8 <etext+0x5c8>
    80004ee8:	fb040513          	addi	a0,s0,-80
    80004eec:	9b1fe0ef          	jal	8000389c <namecmp>
    80004ef0:	10050463          	beqz	a0,80004ff8 <sys_unlink+0x160>
    80004ef4:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004ef6:	f2c40613          	addi	a2,s0,-212
    80004efa:	fb040593          	addi	a1,s0,-80
    80004efe:	8526                	mv	a0,s1
    80004f00:	9b3fe0ef          	jal	800038b2 <dirlookup>
    80004f04:	892a                	mv	s2,a0
    80004f06:	0e050863          	beqz	a0,80004ff6 <sys_unlink+0x15e>
  ilock(ip);
    80004f0a:	bf8fe0ef          	jal	80003302 <ilock>
  if(ip->nlink < 1)
    80004f0e:	04a91783          	lh	a5,74(s2)
    80004f12:	06f05763          	blez	a5,80004f80 <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004f16:	04491703          	lh	a4,68(s2)
    80004f1a:	4785                	li	a5,1
    80004f1c:	06f70963          	beq	a4,a5,80004f8e <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    80004f20:	4641                	li	a2,16
    80004f22:	4581                	li	a1,0
    80004f24:	fc040513          	addi	a0,s0,-64
    80004f28:	d7bfb0ef          	jal	80000ca2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004f2c:	4741                	li	a4,16
    80004f2e:	f2c42683          	lw	a3,-212(s0)
    80004f32:	fc040613          	addi	a2,s0,-64
    80004f36:	4581                	li	a1,0
    80004f38:	8526                	mv	a0,s1
    80004f3a:	855fe0ef          	jal	8000378e <writei>
    80004f3e:	47c1                	li	a5,16
    80004f40:	08f51b63          	bne	a0,a5,80004fd6 <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    80004f44:	04491703          	lh	a4,68(s2)
    80004f48:	4785                	li	a5,1
    80004f4a:	08f70d63          	beq	a4,a5,80004fe4 <sys_unlink+0x14c>
  iunlockput(dp);
    80004f4e:	8526                	mv	a0,s1
    80004f50:	dbcfe0ef          	jal	8000350c <iunlockput>
  ip->nlink--;
    80004f54:	04a95783          	lhu	a5,74(s2)
    80004f58:	37fd                	addiw	a5,a5,-1
    80004f5a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004f5e:	854a                	mv	a0,s2
    80004f60:	aeefe0ef          	jal	8000324e <iupdate>
  iunlockput(ip);
    80004f64:	854a                	mv	a0,s2
    80004f66:	da6fe0ef          	jal	8000350c <iunlockput>
  end_op();
    80004f6a:	dedfe0ef          	jal	80003d56 <end_op>
  return 0;
    80004f6e:	4501                	li	a0,0
    80004f70:	64ee                	ld	s1,216(sp)
    80004f72:	694e                	ld	s2,208(sp)
    80004f74:	a849                	j	80005006 <sys_unlink+0x16e>
    end_op();
    80004f76:	de1fe0ef          	jal	80003d56 <end_op>
    return -1;
    80004f7a:	557d                	li	a0,-1
    80004f7c:	64ee                	ld	s1,216(sp)
    80004f7e:	a061                	j	80005006 <sys_unlink+0x16e>
    80004f80:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80004f82:	00002517          	auipc	a0,0x2
    80004f86:	64e50513          	addi	a0,a0,1614 # 800075d0 <etext+0x5d0>
    80004f8a:	857fb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004f8e:	04c92703          	lw	a4,76(s2)
    80004f92:	02000793          	li	a5,32
    80004f96:	f8e7f5e3          	bgeu	a5,a4,80004f20 <sys_unlink+0x88>
    80004f9a:	e5ce                	sd	s3,200(sp)
    80004f9c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004fa0:	4741                	li	a4,16
    80004fa2:	86ce                	mv	a3,s3
    80004fa4:	f1840613          	addi	a2,s0,-232
    80004fa8:	4581                	li	a1,0
    80004faa:	854a                	mv	a0,s2
    80004fac:	ee6fe0ef          	jal	80003692 <readi>
    80004fb0:	47c1                	li	a5,16
    80004fb2:	00f51c63          	bne	a0,a5,80004fca <sys_unlink+0x132>
    if(de.inum != 0)
    80004fb6:	f1845783          	lhu	a5,-232(s0)
    80004fba:	efa1                	bnez	a5,80005012 <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004fbc:	29c1                	addiw	s3,s3,16
    80004fbe:	04c92783          	lw	a5,76(s2)
    80004fc2:	fcf9efe3          	bltu	s3,a5,80004fa0 <sys_unlink+0x108>
    80004fc6:	69ae                	ld	s3,200(sp)
    80004fc8:	bfa1                	j	80004f20 <sys_unlink+0x88>
      panic("isdirempty: readi");
    80004fca:	00002517          	auipc	a0,0x2
    80004fce:	61e50513          	addi	a0,a0,1566 # 800075e8 <etext+0x5e8>
    80004fd2:	80ffb0ef          	jal	800007e0 <panic>
    80004fd6:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80004fd8:	00002517          	auipc	a0,0x2
    80004fdc:	62850513          	addi	a0,a0,1576 # 80007600 <etext+0x600>
    80004fe0:	801fb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    80004fe4:	04a4d783          	lhu	a5,74(s1)
    80004fe8:	37fd                	addiw	a5,a5,-1
    80004fea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004fee:	8526                	mv	a0,s1
    80004ff0:	a5efe0ef          	jal	8000324e <iupdate>
    80004ff4:	bfa9                	j	80004f4e <sys_unlink+0xb6>
    80004ff6:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80004ff8:	8526                	mv	a0,s1
    80004ffa:	d12fe0ef          	jal	8000350c <iunlockput>
  end_op();
    80004ffe:	d59fe0ef          	jal	80003d56 <end_op>
  return -1;
    80005002:	557d                	li	a0,-1
    80005004:	64ee                	ld	s1,216(sp)
}
    80005006:	70ae                	ld	ra,232(sp)
    80005008:	740e                	ld	s0,224(sp)
    8000500a:	616d                	addi	sp,sp,240
    8000500c:	8082                	ret
    return -1;
    8000500e:	557d                	li	a0,-1
    80005010:	bfdd                	j	80005006 <sys_unlink+0x16e>
    iunlockput(ip);
    80005012:	854a                	mv	a0,s2
    80005014:	cf8fe0ef          	jal	8000350c <iunlockput>
    goto bad;
    80005018:	694e                	ld	s2,208(sp)
    8000501a:	69ae                	ld	s3,200(sp)
    8000501c:	bff1                	j	80004ff8 <sys_unlink+0x160>

000000008000501e <sys_open>:

uint64
sys_open(void)
{
    8000501e:	7131                	addi	sp,sp,-192
    80005020:	fd06                	sd	ra,184(sp)
    80005022:	f922                	sd	s0,176(sp)
    80005024:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005026:	f4c40593          	addi	a1,s0,-180
    8000502a:	4505                	li	a0,1
    8000502c:	88dfd0ef          	jal	800028b8 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005030:	08000613          	li	a2,128
    80005034:	f5040593          	addi	a1,s0,-176
    80005038:	4501                	li	a0,0
    8000503a:	8b7fd0ef          	jal	800028f0 <argstr>
    8000503e:	87aa                	mv	a5,a0
    return -1;
    80005040:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005042:	0a07c263          	bltz	a5,800050e6 <sys_open+0xc8>
    80005046:	f526                	sd	s1,168(sp)

  begin_op();
    80005048:	ca5fe0ef          	jal	80003cec <begin_op>

  if(omode & O_CREATE){
    8000504c:	f4c42783          	lw	a5,-180(s0)
    80005050:	2007f793          	andi	a5,a5,512
    80005054:	c3d5                	beqz	a5,800050f8 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80005056:	4681                	li	a3,0
    80005058:	4601                	li	a2,0
    8000505a:	4589                	li	a1,2
    8000505c:	f5040513          	addi	a0,s0,-176
    80005060:	aa9ff0ef          	jal	80004b08 <create>
    80005064:	84aa                	mv	s1,a0
    if(ip == 0){
    80005066:	c541                	beqz	a0,800050ee <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005068:	04449703          	lh	a4,68(s1)
    8000506c:	478d                	li	a5,3
    8000506e:	00f71763          	bne	a4,a5,8000507c <sys_open+0x5e>
    80005072:	0464d703          	lhu	a4,70(s1)
    80005076:	47a5                	li	a5,9
    80005078:	0ae7ed63          	bltu	a5,a4,80005132 <sys_open+0x114>
    8000507c:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000507e:	fd7fe0ef          	jal	80004054 <filealloc>
    80005082:	892a                	mv	s2,a0
    80005084:	c179                	beqz	a0,8000514a <sys_open+0x12c>
    80005086:	ed4e                	sd	s3,152(sp)
    80005088:	a43ff0ef          	jal	80004aca <fdalloc>
    8000508c:	89aa                	mv	s3,a0
    8000508e:	0a054a63          	bltz	a0,80005142 <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005092:	04449703          	lh	a4,68(s1)
    80005096:	478d                	li	a5,3
    80005098:	0cf70263          	beq	a4,a5,8000515c <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000509c:	4789                	li	a5,2
    8000509e:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800050a2:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800050a6:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800050aa:	f4c42783          	lw	a5,-180(s0)
    800050ae:	0017c713          	xori	a4,a5,1
    800050b2:	8b05                	andi	a4,a4,1
    800050b4:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800050b8:	0037f713          	andi	a4,a5,3
    800050bc:	00e03733          	snez	a4,a4
    800050c0:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800050c4:	4007f793          	andi	a5,a5,1024
    800050c8:	c791                	beqz	a5,800050d4 <sys_open+0xb6>
    800050ca:	04449703          	lh	a4,68(s1)
    800050ce:	4789                	li	a5,2
    800050d0:	08f70d63          	beq	a4,a5,8000516a <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    800050d4:	8526                	mv	a0,s1
    800050d6:	adafe0ef          	jal	800033b0 <iunlock>
  end_op();
    800050da:	c7dfe0ef          	jal	80003d56 <end_op>

  return fd;
    800050de:	854e                	mv	a0,s3
    800050e0:	74aa                	ld	s1,168(sp)
    800050e2:	790a                	ld	s2,160(sp)
    800050e4:	69ea                	ld	s3,152(sp)
}
    800050e6:	70ea                	ld	ra,184(sp)
    800050e8:	744a                	ld	s0,176(sp)
    800050ea:	6129                	addi	sp,sp,192
    800050ec:	8082                	ret
      end_op();
    800050ee:	c69fe0ef          	jal	80003d56 <end_op>
      return -1;
    800050f2:	557d                	li	a0,-1
    800050f4:	74aa                	ld	s1,168(sp)
    800050f6:	bfc5                	j	800050e6 <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    800050f8:	f5040513          	addi	a0,s0,-176
    800050fc:	a1dfe0ef          	jal	80003b18 <namei>
    80005100:	84aa                	mv	s1,a0
    80005102:	c11d                	beqz	a0,80005128 <sys_open+0x10a>
    ilock(ip);
    80005104:	9fefe0ef          	jal	80003302 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005108:	04449703          	lh	a4,68(s1)
    8000510c:	4785                	li	a5,1
    8000510e:	f4f71de3          	bne	a4,a5,80005068 <sys_open+0x4a>
    80005112:	f4c42783          	lw	a5,-180(s0)
    80005116:	d3bd                	beqz	a5,8000507c <sys_open+0x5e>
      iunlockput(ip);
    80005118:	8526                	mv	a0,s1
    8000511a:	bf2fe0ef          	jal	8000350c <iunlockput>
      end_op();
    8000511e:	c39fe0ef          	jal	80003d56 <end_op>
      return -1;
    80005122:	557d                	li	a0,-1
    80005124:	74aa                	ld	s1,168(sp)
    80005126:	b7c1                	j	800050e6 <sys_open+0xc8>
      end_op();
    80005128:	c2ffe0ef          	jal	80003d56 <end_op>
      return -1;
    8000512c:	557d                	li	a0,-1
    8000512e:	74aa                	ld	s1,168(sp)
    80005130:	bf5d                	j	800050e6 <sys_open+0xc8>
    iunlockput(ip);
    80005132:	8526                	mv	a0,s1
    80005134:	bd8fe0ef          	jal	8000350c <iunlockput>
    end_op();
    80005138:	c1ffe0ef          	jal	80003d56 <end_op>
    return -1;
    8000513c:	557d                	li	a0,-1
    8000513e:	74aa                	ld	s1,168(sp)
    80005140:	b75d                	j	800050e6 <sys_open+0xc8>
      fileclose(f);
    80005142:	854a                	mv	a0,s2
    80005144:	fb5fe0ef          	jal	800040f8 <fileclose>
    80005148:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    8000514a:	8526                	mv	a0,s1
    8000514c:	bc0fe0ef          	jal	8000350c <iunlockput>
    end_op();
    80005150:	c07fe0ef          	jal	80003d56 <end_op>
    return -1;
    80005154:	557d                	li	a0,-1
    80005156:	74aa                	ld	s1,168(sp)
    80005158:	790a                	ld	s2,160(sp)
    8000515a:	b771                	j	800050e6 <sys_open+0xc8>
    f->type = FD_DEVICE;
    8000515c:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005160:	04649783          	lh	a5,70(s1)
    80005164:	02f91223          	sh	a5,36(s2)
    80005168:	bf3d                	j	800050a6 <sys_open+0x88>
    itrunc(ip);
    8000516a:	8526                	mv	a0,s1
    8000516c:	a84fe0ef          	jal	800033f0 <itrunc>
    80005170:	b795                	j	800050d4 <sys_open+0xb6>

0000000080005172 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005172:	7175                	addi	sp,sp,-144
    80005174:	e506                	sd	ra,136(sp)
    80005176:	e122                	sd	s0,128(sp)
    80005178:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000517a:	b73fe0ef          	jal	80003cec <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000517e:	08000613          	li	a2,128
    80005182:	f7040593          	addi	a1,s0,-144
    80005186:	4501                	li	a0,0
    80005188:	f68fd0ef          	jal	800028f0 <argstr>
    8000518c:	02054363          	bltz	a0,800051b2 <sys_mkdir+0x40>
    80005190:	4681                	li	a3,0
    80005192:	4601                	li	a2,0
    80005194:	4585                	li	a1,1
    80005196:	f7040513          	addi	a0,s0,-144
    8000519a:	96fff0ef          	jal	80004b08 <create>
    8000519e:	c911                	beqz	a0,800051b2 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800051a0:	b6cfe0ef          	jal	8000350c <iunlockput>
  end_op();
    800051a4:	bb3fe0ef          	jal	80003d56 <end_op>
  return 0;
    800051a8:	4501                	li	a0,0
}
    800051aa:	60aa                	ld	ra,136(sp)
    800051ac:	640a                	ld	s0,128(sp)
    800051ae:	6149                	addi	sp,sp,144
    800051b0:	8082                	ret
    end_op();
    800051b2:	ba5fe0ef          	jal	80003d56 <end_op>
    return -1;
    800051b6:	557d                	li	a0,-1
    800051b8:	bfcd                	j	800051aa <sys_mkdir+0x38>

00000000800051ba <sys_mknod>:

uint64
sys_mknod(void)
{
    800051ba:	7135                	addi	sp,sp,-160
    800051bc:	ed06                	sd	ra,152(sp)
    800051be:	e922                	sd	s0,144(sp)
    800051c0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800051c2:	b2bfe0ef          	jal	80003cec <begin_op>
  argint(1, &major);
    800051c6:	f6c40593          	addi	a1,s0,-148
    800051ca:	4505                	li	a0,1
    800051cc:	eecfd0ef          	jal	800028b8 <argint>
  argint(2, &minor);
    800051d0:	f6840593          	addi	a1,s0,-152
    800051d4:	4509                	li	a0,2
    800051d6:	ee2fd0ef          	jal	800028b8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800051da:	08000613          	li	a2,128
    800051de:	f7040593          	addi	a1,s0,-144
    800051e2:	4501                	li	a0,0
    800051e4:	f0cfd0ef          	jal	800028f0 <argstr>
    800051e8:	02054563          	bltz	a0,80005212 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800051ec:	f6841683          	lh	a3,-152(s0)
    800051f0:	f6c41603          	lh	a2,-148(s0)
    800051f4:	458d                	li	a1,3
    800051f6:	f7040513          	addi	a0,s0,-144
    800051fa:	90fff0ef          	jal	80004b08 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800051fe:	c911                	beqz	a0,80005212 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005200:	b0cfe0ef          	jal	8000350c <iunlockput>
  end_op();
    80005204:	b53fe0ef          	jal	80003d56 <end_op>
  return 0;
    80005208:	4501                	li	a0,0
}
    8000520a:	60ea                	ld	ra,152(sp)
    8000520c:	644a                	ld	s0,144(sp)
    8000520e:	610d                	addi	sp,sp,160
    80005210:	8082                	ret
    end_op();
    80005212:	b45fe0ef          	jal	80003d56 <end_op>
    return -1;
    80005216:	557d                	li	a0,-1
    80005218:	bfcd                	j	8000520a <sys_mknod+0x50>

000000008000521a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000521a:	7135                	addi	sp,sp,-160
    8000521c:	ed06                	sd	ra,152(sp)
    8000521e:	e922                	sd	s0,144(sp)
    80005220:	e14a                	sd	s2,128(sp)
    80005222:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005224:	eaafc0ef          	jal	800018ce <myproc>
    80005228:	892a                	mv	s2,a0
  
  begin_op();
    8000522a:	ac3fe0ef          	jal	80003cec <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000522e:	08000613          	li	a2,128
    80005232:	f6040593          	addi	a1,s0,-160
    80005236:	4501                	li	a0,0
    80005238:	eb8fd0ef          	jal	800028f0 <argstr>
    8000523c:	04054363          	bltz	a0,80005282 <sys_chdir+0x68>
    80005240:	e526                	sd	s1,136(sp)
    80005242:	f6040513          	addi	a0,s0,-160
    80005246:	8d3fe0ef          	jal	80003b18 <namei>
    8000524a:	84aa                	mv	s1,a0
    8000524c:	c915                	beqz	a0,80005280 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    8000524e:	8b4fe0ef          	jal	80003302 <ilock>
  if(ip->type != T_DIR){
    80005252:	04449703          	lh	a4,68(s1)
    80005256:	4785                	li	a5,1
    80005258:	02f71963          	bne	a4,a5,8000528a <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000525c:	8526                	mv	a0,s1
    8000525e:	952fe0ef          	jal	800033b0 <iunlock>
  iput(p->cwd);
    80005262:	15093503          	ld	a0,336(s2)
    80005266:	a1efe0ef          	jal	80003484 <iput>
  end_op();
    8000526a:	aedfe0ef          	jal	80003d56 <end_op>
  p->cwd = ip;
    8000526e:	14993823          	sd	s1,336(s2)
  return 0;
    80005272:	4501                	li	a0,0
    80005274:	64aa                	ld	s1,136(sp)
}
    80005276:	60ea                	ld	ra,152(sp)
    80005278:	644a                	ld	s0,144(sp)
    8000527a:	690a                	ld	s2,128(sp)
    8000527c:	610d                	addi	sp,sp,160
    8000527e:	8082                	ret
    80005280:	64aa                	ld	s1,136(sp)
    end_op();
    80005282:	ad5fe0ef          	jal	80003d56 <end_op>
    return -1;
    80005286:	557d                	li	a0,-1
    80005288:	b7fd                	j	80005276 <sys_chdir+0x5c>
    iunlockput(ip);
    8000528a:	8526                	mv	a0,s1
    8000528c:	a80fe0ef          	jal	8000350c <iunlockput>
    end_op();
    80005290:	ac7fe0ef          	jal	80003d56 <end_op>
    return -1;
    80005294:	557d                	li	a0,-1
    80005296:	64aa                	ld	s1,136(sp)
    80005298:	bff9                	j	80005276 <sys_chdir+0x5c>

000000008000529a <sys_exec>:

uint64
sys_exec(void)
{
    8000529a:	7121                	addi	sp,sp,-448
    8000529c:	ff06                	sd	ra,440(sp)
    8000529e:	fb22                	sd	s0,432(sp)
    800052a0:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800052a2:	e4840593          	addi	a1,s0,-440
    800052a6:	4505                	li	a0,1
    800052a8:	e2cfd0ef          	jal	800028d4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800052ac:	08000613          	li	a2,128
    800052b0:	f5040593          	addi	a1,s0,-176
    800052b4:	4501                	li	a0,0
    800052b6:	e3afd0ef          	jal	800028f0 <argstr>
    800052ba:	87aa                	mv	a5,a0
    return -1;
    800052bc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800052be:	0c07c463          	bltz	a5,80005386 <sys_exec+0xec>
    800052c2:	f726                	sd	s1,424(sp)
    800052c4:	f34a                	sd	s2,416(sp)
    800052c6:	ef4e                	sd	s3,408(sp)
    800052c8:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800052ca:	10000613          	li	a2,256
    800052ce:	4581                	li	a1,0
    800052d0:	e5040513          	addi	a0,s0,-432
    800052d4:	9cffb0ef          	jal	80000ca2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800052d8:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800052dc:	89a6                	mv	s3,s1
    800052de:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800052e0:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800052e4:	00391513          	slli	a0,s2,0x3
    800052e8:	e4040593          	addi	a1,s0,-448
    800052ec:	e4843783          	ld	a5,-440(s0)
    800052f0:	953e                	add	a0,a0,a5
    800052f2:	d3cfd0ef          	jal	8000282e <fetchaddr>
    800052f6:	02054663          	bltz	a0,80005322 <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    800052fa:	e4043783          	ld	a5,-448(s0)
    800052fe:	c3a9                	beqz	a5,80005340 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005300:	ffefb0ef          	jal	80000afe <kalloc>
    80005304:	85aa                	mv	a1,a0
    80005306:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000530a:	cd01                	beqz	a0,80005322 <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000530c:	6605                	lui	a2,0x1
    8000530e:	e4043503          	ld	a0,-448(s0)
    80005312:	d66fd0ef          	jal	80002878 <fetchstr>
    80005316:	00054663          	bltz	a0,80005322 <sys_exec+0x88>
    if(i >= NELEM(argv)){
    8000531a:	0905                	addi	s2,s2,1
    8000531c:	09a1                	addi	s3,s3,8
    8000531e:	fd4913e3          	bne	s2,s4,800052e4 <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005322:	f5040913          	addi	s2,s0,-176
    80005326:	6088                	ld	a0,0(s1)
    80005328:	c931                	beqz	a0,8000537c <sys_exec+0xe2>
    kfree(argv[i]);
    8000532a:	ef2fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000532e:	04a1                	addi	s1,s1,8
    80005330:	ff249be3          	bne	s1,s2,80005326 <sys_exec+0x8c>
  return -1;
    80005334:	557d                	li	a0,-1
    80005336:	74ba                	ld	s1,424(sp)
    80005338:	791a                	ld	s2,416(sp)
    8000533a:	69fa                	ld	s3,408(sp)
    8000533c:	6a5a                	ld	s4,400(sp)
    8000533e:	a0a1                	j	80005386 <sys_exec+0xec>
      argv[i] = 0;
    80005340:	0009079b          	sext.w	a5,s2
    80005344:	078e                	slli	a5,a5,0x3
    80005346:	fd078793          	addi	a5,a5,-48
    8000534a:	97a2                	add	a5,a5,s0
    8000534c:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    80005350:	e5040593          	addi	a1,s0,-432
    80005354:	f5040513          	addi	a0,s0,-176
    80005358:	ba8ff0ef          	jal	80004700 <kexec>
    8000535c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000535e:	f5040993          	addi	s3,s0,-176
    80005362:	6088                	ld	a0,0(s1)
    80005364:	c511                	beqz	a0,80005370 <sys_exec+0xd6>
    kfree(argv[i]);
    80005366:	eb6fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000536a:	04a1                	addi	s1,s1,8
    8000536c:	ff349be3          	bne	s1,s3,80005362 <sys_exec+0xc8>
  return ret;
    80005370:	854a                	mv	a0,s2
    80005372:	74ba                	ld	s1,424(sp)
    80005374:	791a                	ld	s2,416(sp)
    80005376:	69fa                	ld	s3,408(sp)
    80005378:	6a5a                	ld	s4,400(sp)
    8000537a:	a031                	j	80005386 <sys_exec+0xec>
  return -1;
    8000537c:	557d                	li	a0,-1
    8000537e:	74ba                	ld	s1,424(sp)
    80005380:	791a                	ld	s2,416(sp)
    80005382:	69fa                	ld	s3,408(sp)
    80005384:	6a5a                	ld	s4,400(sp)
}
    80005386:	70fa                	ld	ra,440(sp)
    80005388:	745a                	ld	s0,432(sp)
    8000538a:	6139                	addi	sp,sp,448
    8000538c:	8082                	ret

000000008000538e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000538e:	7139                	addi	sp,sp,-64
    80005390:	fc06                	sd	ra,56(sp)
    80005392:	f822                	sd	s0,48(sp)
    80005394:	f426                	sd	s1,40(sp)
    80005396:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005398:	d36fc0ef          	jal	800018ce <myproc>
    8000539c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000539e:	fd840593          	addi	a1,s0,-40
    800053a2:	4501                	li	a0,0
    800053a4:	d30fd0ef          	jal	800028d4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800053a8:	fc840593          	addi	a1,s0,-56
    800053ac:	fd040513          	addi	a0,s0,-48
    800053b0:	852ff0ef          	jal	80004402 <pipealloc>
    return -1;
    800053b4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800053b6:	0a054463          	bltz	a0,8000545e <sys_pipe+0xd0>
  fd0 = -1;
    800053ba:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800053be:	fd043503          	ld	a0,-48(s0)
    800053c2:	f08ff0ef          	jal	80004aca <fdalloc>
    800053c6:	fca42223          	sw	a0,-60(s0)
    800053ca:	08054163          	bltz	a0,8000544c <sys_pipe+0xbe>
    800053ce:	fc843503          	ld	a0,-56(s0)
    800053d2:	ef8ff0ef          	jal	80004aca <fdalloc>
    800053d6:	fca42023          	sw	a0,-64(s0)
    800053da:	06054063          	bltz	a0,8000543a <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800053de:	4691                	li	a3,4
    800053e0:	fc440613          	addi	a2,s0,-60
    800053e4:	fd843583          	ld	a1,-40(s0)
    800053e8:	68a8                	ld	a0,80(s1)
    800053ea:	9f8fc0ef          	jal	800015e2 <copyout>
    800053ee:	00054e63          	bltz	a0,8000540a <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800053f2:	4691                	li	a3,4
    800053f4:	fc040613          	addi	a2,s0,-64
    800053f8:	fd843583          	ld	a1,-40(s0)
    800053fc:	0591                	addi	a1,a1,4
    800053fe:	68a8                	ld	a0,80(s1)
    80005400:	9e2fc0ef          	jal	800015e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005404:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005406:	04055c63          	bgez	a0,8000545e <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    8000540a:	fc442783          	lw	a5,-60(s0)
    8000540e:	07e9                	addi	a5,a5,26
    80005410:	078e                	slli	a5,a5,0x3
    80005412:	97a6                	add	a5,a5,s1
    80005414:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005418:	fc042783          	lw	a5,-64(s0)
    8000541c:	07e9                	addi	a5,a5,26
    8000541e:	078e                	slli	a5,a5,0x3
    80005420:	94be                	add	s1,s1,a5
    80005422:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005426:	fd043503          	ld	a0,-48(s0)
    8000542a:	ccffe0ef          	jal	800040f8 <fileclose>
    fileclose(wf);
    8000542e:	fc843503          	ld	a0,-56(s0)
    80005432:	cc7fe0ef          	jal	800040f8 <fileclose>
    return -1;
    80005436:	57fd                	li	a5,-1
    80005438:	a01d                	j	8000545e <sys_pipe+0xd0>
    if(fd0 >= 0)
    8000543a:	fc442783          	lw	a5,-60(s0)
    8000543e:	0007c763          	bltz	a5,8000544c <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    80005442:	07e9                	addi	a5,a5,26
    80005444:	078e                	slli	a5,a5,0x3
    80005446:	97a6                	add	a5,a5,s1
    80005448:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000544c:	fd043503          	ld	a0,-48(s0)
    80005450:	ca9fe0ef          	jal	800040f8 <fileclose>
    fileclose(wf);
    80005454:	fc843503          	ld	a0,-56(s0)
    80005458:	ca1fe0ef          	jal	800040f8 <fileclose>
    return -1;
    8000545c:	57fd                	li	a5,-1
}
    8000545e:	853e                	mv	a0,a5
    80005460:	70e2                	ld	ra,56(sp)
    80005462:	7442                	ld	s0,48(sp)
    80005464:	74a2                	ld	s1,40(sp)
    80005466:	6121                	addi	sp,sp,64
    80005468:	8082                	ret
    8000546a:	0000                	unimp
    8000546c:	0000                	unimp
	...

0000000080005470 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005470:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005472:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005474:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005476:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005478:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000547a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000547c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000547e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005480:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005482:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005484:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005486:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005488:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000548a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000548c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000548e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005490:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005492:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005494:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005496:	aa8fd0ef          	jal	8000273e <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000549a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000549c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000549e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800054a0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800054a2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800054a4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800054a6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800054a8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800054aa:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800054ac:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800054ae:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800054b0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800054b2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800054b4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800054b6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800054b8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800054ba:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800054bc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800054be:	10200073          	sret
	...

00000000800054ce <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800054ce:	1141                	addi	sp,sp,-16
    800054d0:	e422                	sd	s0,8(sp)
    800054d2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800054d4:	0c0007b7          	lui	a5,0xc000
    800054d8:	4705                	li	a4,1
    800054da:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800054dc:	0c0007b7          	lui	a5,0xc000
    800054e0:	c3d8                	sw	a4,4(a5)
}
    800054e2:	6422                	ld	s0,8(sp)
    800054e4:	0141                	addi	sp,sp,16
    800054e6:	8082                	ret

00000000800054e8 <plicinithart>:

void
plicinithart(void)
{
    800054e8:	1141                	addi	sp,sp,-16
    800054ea:	e406                	sd	ra,8(sp)
    800054ec:	e022                	sd	s0,0(sp)
    800054ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800054f0:	bb2fc0ef          	jal	800018a2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800054f4:	0085171b          	slliw	a4,a0,0x8
    800054f8:	0c0027b7          	lui	a5,0xc002
    800054fc:	97ba                	add	a5,a5,a4
    800054fe:	40200713          	li	a4,1026
    80005502:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005506:	00d5151b          	slliw	a0,a0,0xd
    8000550a:	0c2017b7          	lui	a5,0xc201
    8000550e:	97aa                	add	a5,a5,a0
    80005510:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005514:	60a2                	ld	ra,8(sp)
    80005516:	6402                	ld	s0,0(sp)
    80005518:	0141                	addi	sp,sp,16
    8000551a:	8082                	ret

000000008000551c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000551c:	1141                	addi	sp,sp,-16
    8000551e:	e406                	sd	ra,8(sp)
    80005520:	e022                	sd	s0,0(sp)
    80005522:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005524:	b7efc0ef          	jal	800018a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005528:	00d5151b          	slliw	a0,a0,0xd
    8000552c:	0c2017b7          	lui	a5,0xc201
    80005530:	97aa                	add	a5,a5,a0
  return irq;
}
    80005532:	43c8                	lw	a0,4(a5)
    80005534:	60a2                	ld	ra,8(sp)
    80005536:	6402                	ld	s0,0(sp)
    80005538:	0141                	addi	sp,sp,16
    8000553a:	8082                	ret

000000008000553c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000553c:	1101                	addi	sp,sp,-32
    8000553e:	ec06                	sd	ra,24(sp)
    80005540:	e822                	sd	s0,16(sp)
    80005542:	e426                	sd	s1,8(sp)
    80005544:	1000                	addi	s0,sp,32
    80005546:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005548:	b5afc0ef          	jal	800018a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000554c:	00d5151b          	slliw	a0,a0,0xd
    80005550:	0c2017b7          	lui	a5,0xc201
    80005554:	97aa                	add	a5,a5,a0
    80005556:	c3c4                	sw	s1,4(a5)
}
    80005558:	60e2                	ld	ra,24(sp)
    8000555a:	6442                	ld	s0,16(sp)
    8000555c:	64a2                	ld	s1,8(sp)
    8000555e:	6105                	addi	sp,sp,32
    80005560:	8082                	ret

0000000080005562 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005562:	1141                	addi	sp,sp,-16
    80005564:	e406                	sd	ra,8(sp)
    80005566:	e022                	sd	s0,0(sp)
    80005568:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000556a:	479d                	li	a5,7
    8000556c:	04a7ca63          	blt	a5,a0,800055c0 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80005570:	0001e797          	auipc	a5,0x1e
    80005574:	09878793          	addi	a5,a5,152 # 80023608 <disk>
    80005578:	97aa                	add	a5,a5,a0
    8000557a:	0187c783          	lbu	a5,24(a5)
    8000557e:	e7b9                	bnez	a5,800055cc <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005580:	00451693          	slli	a3,a0,0x4
    80005584:	0001e797          	auipc	a5,0x1e
    80005588:	08478793          	addi	a5,a5,132 # 80023608 <disk>
    8000558c:	6398                	ld	a4,0(a5)
    8000558e:	9736                	add	a4,a4,a3
    80005590:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005594:	6398                	ld	a4,0(a5)
    80005596:	9736                	add	a4,a4,a3
    80005598:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    8000559c:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800055a0:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800055a4:	97aa                	add	a5,a5,a0
    800055a6:	4705                	li	a4,1
    800055a8:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800055ac:	0001e517          	auipc	a0,0x1e
    800055b0:	07450513          	addi	a0,a0,116 # 80023620 <disk+0x18>
    800055b4:	a57fc0ef          	jal	8000200a <wakeup>
}
    800055b8:	60a2                	ld	ra,8(sp)
    800055ba:	6402                	ld	s0,0(sp)
    800055bc:	0141                	addi	sp,sp,16
    800055be:	8082                	ret
    panic("free_desc 1");
    800055c0:	00002517          	auipc	a0,0x2
    800055c4:	05050513          	addi	a0,a0,80 # 80007610 <etext+0x610>
    800055c8:	a18fb0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    800055cc:	00002517          	auipc	a0,0x2
    800055d0:	05450513          	addi	a0,a0,84 # 80007620 <etext+0x620>
    800055d4:	a0cfb0ef          	jal	800007e0 <panic>

00000000800055d8 <virtio_disk_init>:
{
    800055d8:	1101                	addi	sp,sp,-32
    800055da:	ec06                	sd	ra,24(sp)
    800055dc:	e822                	sd	s0,16(sp)
    800055de:	e426                	sd	s1,8(sp)
    800055e0:	e04a                	sd	s2,0(sp)
    800055e2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800055e4:	00002597          	auipc	a1,0x2
    800055e8:	04c58593          	addi	a1,a1,76 # 80007630 <etext+0x630>
    800055ec:	0001e517          	auipc	a0,0x1e
    800055f0:	14450513          	addi	a0,a0,324 # 80023730 <disk+0x128>
    800055f4:	d5afb0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800055f8:	100017b7          	lui	a5,0x10001
    800055fc:	4398                	lw	a4,0(a5)
    800055fe:	2701                	sext.w	a4,a4
    80005600:	747277b7          	lui	a5,0x74727
    80005604:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005608:	18f71063          	bne	a4,a5,80005788 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000560c:	100017b7          	lui	a5,0x10001
    80005610:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80005612:	439c                	lw	a5,0(a5)
    80005614:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005616:	4709                	li	a4,2
    80005618:	16e79863          	bne	a5,a4,80005788 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000561c:	100017b7          	lui	a5,0x10001
    80005620:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80005622:	439c                	lw	a5,0(a5)
    80005624:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005626:	16e79163          	bne	a5,a4,80005788 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000562a:	100017b7          	lui	a5,0x10001
    8000562e:	47d8                	lw	a4,12(a5)
    80005630:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005632:	554d47b7          	lui	a5,0x554d4
    80005636:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000563a:	14f71763          	bne	a4,a5,80005788 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000563e:	100017b7          	lui	a5,0x10001
    80005642:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005646:	4705                	li	a4,1
    80005648:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000564a:	470d                	li	a4,3
    8000564c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000564e:	10001737          	lui	a4,0x10001
    80005652:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005654:	c7ffe737          	lui	a4,0xc7ffe
    80005658:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb017>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000565c:	8ef9                	and	a3,a3,a4
    8000565e:	10001737          	lui	a4,0x10001
    80005662:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005664:	472d                	li	a4,11
    80005666:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005668:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    8000566c:	439c                	lw	a5,0(a5)
    8000566e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005672:	8ba1                	andi	a5,a5,8
    80005674:	12078063          	beqz	a5,80005794 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005678:	100017b7          	lui	a5,0x10001
    8000567c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005680:	100017b7          	lui	a5,0x10001
    80005684:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80005688:	439c                	lw	a5,0(a5)
    8000568a:	2781                	sext.w	a5,a5
    8000568c:	10079a63          	bnez	a5,800057a0 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005690:	100017b7          	lui	a5,0x10001
    80005694:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80005698:	439c                	lw	a5,0(a5)
    8000569a:	2781                	sext.w	a5,a5
  if(max == 0)
    8000569c:	10078863          	beqz	a5,800057ac <virtio_disk_init+0x1d4>
  if(max < NUM)
    800056a0:	471d                	li	a4,7
    800056a2:	10f77b63          	bgeu	a4,a5,800057b8 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    800056a6:	c58fb0ef          	jal	80000afe <kalloc>
    800056aa:	0001e497          	auipc	s1,0x1e
    800056ae:	f5e48493          	addi	s1,s1,-162 # 80023608 <disk>
    800056b2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800056b4:	c4afb0ef          	jal	80000afe <kalloc>
    800056b8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800056ba:	c44fb0ef          	jal	80000afe <kalloc>
    800056be:	87aa                	mv	a5,a0
    800056c0:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800056c2:	6088                	ld	a0,0(s1)
    800056c4:	10050063          	beqz	a0,800057c4 <virtio_disk_init+0x1ec>
    800056c8:	0001e717          	auipc	a4,0x1e
    800056cc:	f4873703          	ld	a4,-184(a4) # 80023610 <disk+0x8>
    800056d0:	0e070a63          	beqz	a4,800057c4 <virtio_disk_init+0x1ec>
    800056d4:	0e078863          	beqz	a5,800057c4 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    800056d8:	6605                	lui	a2,0x1
    800056da:	4581                	li	a1,0
    800056dc:	dc6fb0ef          	jal	80000ca2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800056e0:	0001e497          	auipc	s1,0x1e
    800056e4:	f2848493          	addi	s1,s1,-216 # 80023608 <disk>
    800056e8:	6605                	lui	a2,0x1
    800056ea:	4581                	li	a1,0
    800056ec:	6488                	ld	a0,8(s1)
    800056ee:	db4fb0ef          	jal	80000ca2 <memset>
  memset(disk.used, 0, PGSIZE);
    800056f2:	6605                	lui	a2,0x1
    800056f4:	4581                	li	a1,0
    800056f6:	6888                	ld	a0,16(s1)
    800056f8:	daafb0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800056fc:	100017b7          	lui	a5,0x10001
    80005700:	4721                	li	a4,8
    80005702:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005704:	4098                	lw	a4,0(s1)
    80005706:	100017b7          	lui	a5,0x10001
    8000570a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    8000570e:	40d8                	lw	a4,4(s1)
    80005710:	100017b7          	lui	a5,0x10001
    80005714:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005718:	649c                	ld	a5,8(s1)
    8000571a:	0007869b          	sext.w	a3,a5
    8000571e:	10001737          	lui	a4,0x10001
    80005722:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005726:	9781                	srai	a5,a5,0x20
    80005728:	10001737          	lui	a4,0x10001
    8000572c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005730:	689c                	ld	a5,16(s1)
    80005732:	0007869b          	sext.w	a3,a5
    80005736:	10001737          	lui	a4,0x10001
    8000573a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    8000573e:	9781                	srai	a5,a5,0x20
    80005740:	10001737          	lui	a4,0x10001
    80005744:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005748:	10001737          	lui	a4,0x10001
    8000574c:	4785                	li	a5,1
    8000574e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80005750:	00f48c23          	sb	a5,24(s1)
    80005754:	00f48ca3          	sb	a5,25(s1)
    80005758:	00f48d23          	sb	a5,26(s1)
    8000575c:	00f48da3          	sb	a5,27(s1)
    80005760:	00f48e23          	sb	a5,28(s1)
    80005764:	00f48ea3          	sb	a5,29(s1)
    80005768:	00f48f23          	sb	a5,30(s1)
    8000576c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005770:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005774:	100017b7          	lui	a5,0x10001
    80005778:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    8000577c:	60e2                	ld	ra,24(sp)
    8000577e:	6442                	ld	s0,16(sp)
    80005780:	64a2                	ld	s1,8(sp)
    80005782:	6902                	ld	s2,0(sp)
    80005784:	6105                	addi	sp,sp,32
    80005786:	8082                	ret
    panic("could not find virtio disk");
    80005788:	00002517          	auipc	a0,0x2
    8000578c:	eb850513          	addi	a0,a0,-328 # 80007640 <etext+0x640>
    80005790:	850fb0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005794:	00002517          	auipc	a0,0x2
    80005798:	ecc50513          	addi	a0,a0,-308 # 80007660 <etext+0x660>
    8000579c:	844fb0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    800057a0:	00002517          	auipc	a0,0x2
    800057a4:	ee050513          	addi	a0,a0,-288 # 80007680 <etext+0x680>
    800057a8:	838fb0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    800057ac:	00002517          	auipc	a0,0x2
    800057b0:	ef450513          	addi	a0,a0,-268 # 800076a0 <etext+0x6a0>
    800057b4:	82cfb0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    800057b8:	00002517          	auipc	a0,0x2
    800057bc:	f0850513          	addi	a0,a0,-248 # 800076c0 <etext+0x6c0>
    800057c0:	820fb0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    800057c4:	00002517          	auipc	a0,0x2
    800057c8:	f1c50513          	addi	a0,a0,-228 # 800076e0 <etext+0x6e0>
    800057cc:	814fb0ef          	jal	800007e0 <panic>

00000000800057d0 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800057d0:	7159                	addi	sp,sp,-112
    800057d2:	f486                	sd	ra,104(sp)
    800057d4:	f0a2                	sd	s0,96(sp)
    800057d6:	eca6                	sd	s1,88(sp)
    800057d8:	e8ca                	sd	s2,80(sp)
    800057da:	e4ce                	sd	s3,72(sp)
    800057dc:	e0d2                	sd	s4,64(sp)
    800057de:	fc56                	sd	s5,56(sp)
    800057e0:	f85a                	sd	s6,48(sp)
    800057e2:	f45e                	sd	s7,40(sp)
    800057e4:	f062                	sd	s8,32(sp)
    800057e6:	ec66                	sd	s9,24(sp)
    800057e8:	1880                	addi	s0,sp,112
    800057ea:	8a2a                	mv	s4,a0
    800057ec:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800057ee:	00c52c83          	lw	s9,12(a0)
    800057f2:	001c9c9b          	slliw	s9,s9,0x1
    800057f6:	1c82                	slli	s9,s9,0x20
    800057f8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800057fc:	0001e517          	auipc	a0,0x1e
    80005800:	f3450513          	addi	a0,a0,-204 # 80023730 <disk+0x128>
    80005804:	bcafb0ef          	jal	80000bce <acquire>
  for(int i = 0; i < 3; i++){
    80005808:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000580a:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000580c:	0001eb17          	auipc	s6,0x1e
    80005810:	dfcb0b13          	addi	s6,s6,-516 # 80023608 <disk>
  for(int i = 0; i < 3; i++){
    80005814:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005816:	0001ec17          	auipc	s8,0x1e
    8000581a:	f1ac0c13          	addi	s8,s8,-230 # 80023730 <disk+0x128>
    8000581e:	a8b9                	j	8000587c <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005820:	00fb0733          	add	a4,s6,a5
    80005824:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80005828:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000582a:	0207c563          	bltz	a5,80005854 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    8000582e:	2905                	addiw	s2,s2,1
    80005830:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005832:	05590963          	beq	s2,s5,80005884 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80005836:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005838:	0001e717          	auipc	a4,0x1e
    8000583c:	dd070713          	addi	a4,a4,-560 # 80023608 <disk>
    80005840:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005842:	01874683          	lbu	a3,24(a4)
    80005846:	fee9                	bnez	a3,80005820 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005848:	2785                	addiw	a5,a5,1
    8000584a:	0705                	addi	a4,a4,1
    8000584c:	fe979be3          	bne	a5,s1,80005842 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005850:	57fd                	li	a5,-1
    80005852:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005854:	01205d63          	blez	s2,8000586e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005858:	f9042503          	lw	a0,-112(s0)
    8000585c:	d07ff0ef          	jal	80005562 <free_desc>
      for(int j = 0; j < i; j++)
    80005860:	4785                	li	a5,1
    80005862:	0127d663          	bge	a5,s2,8000586e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005866:	f9442503          	lw	a0,-108(s0)
    8000586a:	cf9ff0ef          	jal	80005562 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000586e:	85e2                	mv	a1,s8
    80005870:	0001e517          	auipc	a0,0x1e
    80005874:	db050513          	addi	a0,a0,-592 # 80023620 <disk+0x18>
    80005878:	f46fc0ef          	jal	80001fbe <sleep>
  for(int i = 0; i < 3; i++){
    8000587c:	f9040613          	addi	a2,s0,-112
    80005880:	894e                	mv	s2,s3
    80005882:	bf55                	j	80005836 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005884:	f9042503          	lw	a0,-112(s0)
    80005888:	00451693          	slli	a3,a0,0x4

  if(write)
    8000588c:	0001e797          	auipc	a5,0x1e
    80005890:	d7c78793          	addi	a5,a5,-644 # 80023608 <disk>
    80005894:	00a50713          	addi	a4,a0,10
    80005898:	0712                	slli	a4,a4,0x4
    8000589a:	973e                	add	a4,a4,a5
    8000589c:	01703633          	snez	a2,s7
    800058a0:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800058a2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800058a6:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800058aa:	6398                	ld	a4,0(a5)
    800058ac:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800058ae:	0a868613          	addi	a2,a3,168
    800058b2:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800058b4:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800058b6:	6390                	ld	a2,0(a5)
    800058b8:	00d605b3          	add	a1,a2,a3
    800058bc:	4741                	li	a4,16
    800058be:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800058c0:	4805                	li	a6,1
    800058c2:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    800058c6:	f9442703          	lw	a4,-108(s0)
    800058ca:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800058ce:	0712                	slli	a4,a4,0x4
    800058d0:	963a                	add	a2,a2,a4
    800058d2:	058a0593          	addi	a1,s4,88
    800058d6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800058d8:	0007b883          	ld	a7,0(a5)
    800058dc:	9746                	add	a4,a4,a7
    800058de:	40000613          	li	a2,1024
    800058e2:	c710                	sw	a2,8(a4)
  if(write)
    800058e4:	001bb613          	seqz	a2,s7
    800058e8:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800058ec:	00166613          	ori	a2,a2,1
    800058f0:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800058f4:	f9842583          	lw	a1,-104(s0)
    800058f8:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800058fc:	00250613          	addi	a2,a0,2
    80005900:	0612                	slli	a2,a2,0x4
    80005902:	963e                	add	a2,a2,a5
    80005904:	577d                	li	a4,-1
    80005906:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000590a:	0592                	slli	a1,a1,0x4
    8000590c:	98ae                	add	a7,a7,a1
    8000590e:	03068713          	addi	a4,a3,48
    80005912:	973e                	add	a4,a4,a5
    80005914:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80005918:	6398                	ld	a4,0(a5)
    8000591a:	972e                	add	a4,a4,a1
    8000591c:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005920:	4689                	li	a3,2
    80005922:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80005926:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000592a:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    8000592e:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005932:	6794                	ld	a3,8(a5)
    80005934:	0026d703          	lhu	a4,2(a3)
    80005938:	8b1d                	andi	a4,a4,7
    8000593a:	0706                	slli	a4,a4,0x1
    8000593c:	96ba                	add	a3,a3,a4
    8000593e:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005942:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005946:	6798                	ld	a4,8(a5)
    80005948:	00275783          	lhu	a5,2(a4)
    8000594c:	2785                	addiw	a5,a5,1
    8000594e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005952:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005956:	100017b7          	lui	a5,0x10001
    8000595a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000595e:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80005962:	0001e917          	auipc	s2,0x1e
    80005966:	dce90913          	addi	s2,s2,-562 # 80023730 <disk+0x128>
  while(b->disk == 1) {
    8000596a:	4485                	li	s1,1
    8000596c:	01079a63          	bne	a5,a6,80005980 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    80005970:	85ca                	mv	a1,s2
    80005972:	8552                	mv	a0,s4
    80005974:	e4afc0ef          	jal	80001fbe <sleep>
  while(b->disk == 1) {
    80005978:	004a2783          	lw	a5,4(s4)
    8000597c:	fe978ae3          	beq	a5,s1,80005970 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    80005980:	f9042903          	lw	s2,-112(s0)
    80005984:	00290713          	addi	a4,s2,2
    80005988:	0712                	slli	a4,a4,0x4
    8000598a:	0001e797          	auipc	a5,0x1e
    8000598e:	c7e78793          	addi	a5,a5,-898 # 80023608 <disk>
    80005992:	97ba                	add	a5,a5,a4
    80005994:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005998:	0001e997          	auipc	s3,0x1e
    8000599c:	c7098993          	addi	s3,s3,-912 # 80023608 <disk>
    800059a0:	00491713          	slli	a4,s2,0x4
    800059a4:	0009b783          	ld	a5,0(s3)
    800059a8:	97ba                	add	a5,a5,a4
    800059aa:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800059ae:	854a                	mv	a0,s2
    800059b0:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800059b4:	bafff0ef          	jal	80005562 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800059b8:	8885                	andi	s1,s1,1
    800059ba:	f0fd                	bnez	s1,800059a0 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800059bc:	0001e517          	auipc	a0,0x1e
    800059c0:	d7450513          	addi	a0,a0,-652 # 80023730 <disk+0x128>
    800059c4:	aa2fb0ef          	jal	80000c66 <release>
}
    800059c8:	70a6                	ld	ra,104(sp)
    800059ca:	7406                	ld	s0,96(sp)
    800059cc:	64e6                	ld	s1,88(sp)
    800059ce:	6946                	ld	s2,80(sp)
    800059d0:	69a6                	ld	s3,72(sp)
    800059d2:	6a06                	ld	s4,64(sp)
    800059d4:	7ae2                	ld	s5,56(sp)
    800059d6:	7b42                	ld	s6,48(sp)
    800059d8:	7ba2                	ld	s7,40(sp)
    800059da:	7c02                	ld	s8,32(sp)
    800059dc:	6ce2                	ld	s9,24(sp)
    800059de:	6165                	addi	sp,sp,112
    800059e0:	8082                	ret

00000000800059e2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800059e2:	1101                	addi	sp,sp,-32
    800059e4:	ec06                	sd	ra,24(sp)
    800059e6:	e822                	sd	s0,16(sp)
    800059e8:	e426                	sd	s1,8(sp)
    800059ea:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800059ec:	0001e497          	auipc	s1,0x1e
    800059f0:	c1c48493          	addi	s1,s1,-996 # 80023608 <disk>
    800059f4:	0001e517          	auipc	a0,0x1e
    800059f8:	d3c50513          	addi	a0,a0,-708 # 80023730 <disk+0x128>
    800059fc:	9d2fb0ef          	jal	80000bce <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005a00:	100017b7          	lui	a5,0x10001
    80005a04:	53b8                	lw	a4,96(a5)
    80005a06:	8b0d                	andi	a4,a4,3
    80005a08:	100017b7          	lui	a5,0x10001
    80005a0c:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80005a0e:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005a12:	689c                	ld	a5,16(s1)
    80005a14:	0204d703          	lhu	a4,32(s1)
    80005a18:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80005a1c:	04f70663          	beq	a4,a5,80005a68 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005a20:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005a24:	6898                	ld	a4,16(s1)
    80005a26:	0204d783          	lhu	a5,32(s1)
    80005a2a:	8b9d                	andi	a5,a5,7
    80005a2c:	078e                	slli	a5,a5,0x3
    80005a2e:	97ba                	add	a5,a5,a4
    80005a30:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005a32:	00278713          	addi	a4,a5,2
    80005a36:	0712                	slli	a4,a4,0x4
    80005a38:	9726                	add	a4,a4,s1
    80005a3a:	01074703          	lbu	a4,16(a4)
    80005a3e:	e321                	bnez	a4,80005a7e <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005a40:	0789                	addi	a5,a5,2
    80005a42:	0792                	slli	a5,a5,0x4
    80005a44:	97a6                	add	a5,a5,s1
    80005a46:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005a48:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005a4c:	dbefc0ef          	jal	8000200a <wakeup>

    disk.used_idx += 1;
    80005a50:	0204d783          	lhu	a5,32(s1)
    80005a54:	2785                	addiw	a5,a5,1
    80005a56:	17c2                	slli	a5,a5,0x30
    80005a58:	93c1                	srli	a5,a5,0x30
    80005a5a:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005a5e:	6898                	ld	a4,16(s1)
    80005a60:	00275703          	lhu	a4,2(a4)
    80005a64:	faf71ee3          	bne	a4,a5,80005a20 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005a68:	0001e517          	auipc	a0,0x1e
    80005a6c:	cc850513          	addi	a0,a0,-824 # 80023730 <disk+0x128>
    80005a70:	9f6fb0ef          	jal	80000c66 <release>
}
    80005a74:	60e2                	ld	ra,24(sp)
    80005a76:	6442                	ld	s0,16(sp)
    80005a78:	64a2                	ld	s1,8(sp)
    80005a7a:	6105                	addi	sp,sp,32
    80005a7c:	8082                	ret
      panic("virtio_disk_intr status");
    80005a7e:	00002517          	auipc	a0,0x2
    80005a82:	c7a50513          	addi	a0,a0,-902 # 800076f8 <etext+0x6f8>
    80005a86:	d5bfa0ef          	jal	800007e0 <panic>
	...

0000000080006000 <_trampoline>:
    80006000:	14051073          	csrw	sscratch,a0
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000600a:	0536                	slli	a0,a0,0xd
    8000600c:	02153423          	sd	ra,40(a0)
    80006010:	02253823          	sd	sp,48(a0)
    80006014:	02353c23          	sd	gp,56(a0)
    80006018:	04453023          	sd	tp,64(a0)
    8000601c:	04553423          	sd	t0,72(a0)
    80006020:	04653823          	sd	t1,80(a0)
    80006024:	04753c23          	sd	t2,88(a0)
    80006028:	f120                	sd	s0,96(a0)
    8000602a:	f524                	sd	s1,104(a0)
    8000602c:	fd2c                	sd	a1,120(a0)
    8000602e:	e150                	sd	a2,128(a0)
    80006030:	e554                	sd	a3,136(a0)
    80006032:	e958                	sd	a4,144(a0)
    80006034:	ed5c                	sd	a5,152(a0)
    80006036:	0b053023          	sd	a6,160(a0)
    8000603a:	0b153423          	sd	a7,168(a0)
    8000603e:	0b253823          	sd	s2,176(a0)
    80006042:	0b353c23          	sd	s3,184(a0)
    80006046:	0d453023          	sd	s4,192(a0)
    8000604a:	0d553423          	sd	s5,200(a0)
    8000604e:	0d653823          	sd	s6,208(a0)
    80006052:	0d753c23          	sd	s7,216(a0)
    80006056:	0f853023          	sd	s8,224(a0)
    8000605a:	0f953423          	sd	s9,232(a0)
    8000605e:	0fa53823          	sd	s10,240(a0)
    80006062:	0fb53c23          	sd	s11,248(a0)
    80006066:	11c53023          	sd	t3,256(a0)
    8000606a:	11d53423          	sd	t4,264(a0)
    8000606e:	11e53823          	sd	t5,272(a0)
    80006072:	11f53c23          	sd	t6,280(a0)
    80006076:	140022f3          	csrr	t0,sscratch
    8000607a:	06553823          	sd	t0,112(a0)
    8000607e:	00853103          	ld	sp,8(a0)
    80006082:	02053203          	ld	tp,32(a0)
    80006086:	01053283          	ld	t0,16(a0)
    8000608a:	00053303          	ld	t1,0(a0)
    8000608e:	12000073          	sfence.vma
    80006092:	18031073          	csrw	satp,t1
    80006096:	12000073          	sfence.vma
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
    8000609c:	12000073          	sfence.vma
    800060a0:	18051073          	csrw	satp,a0
    800060a4:	12000073          	sfence.vma
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800060ae:	0536                	slli	a0,a0,0xd
    800060b0:	02853083          	ld	ra,40(a0)
    800060b4:	03053103          	ld	sp,48(a0)
    800060b8:	03853183          	ld	gp,56(a0)
    800060bc:	04053203          	ld	tp,64(a0)
    800060c0:	04853283          	ld	t0,72(a0)
    800060c4:	05053303          	ld	t1,80(a0)
    800060c8:	05853383          	ld	t2,88(a0)
    800060cc:	7120                	ld	s0,96(a0)
    800060ce:	7524                	ld	s1,104(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
    800060d2:	6150                	ld	a2,128(a0)
    800060d4:	6554                	ld	a3,136(a0)
    800060d6:	6958                	ld	a4,144(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
    800060da:	0a053803          	ld	a6,160(a0)
    800060de:	0a853883          	ld	a7,168(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
    80006112:	11053f03          	ld	t5,272(a0)
    80006116:	11853f83          	ld	t6,280(a0)
    8000611a:	7928                	ld	a0,112(a0)
    8000611c:	10200073          	sret
	...
