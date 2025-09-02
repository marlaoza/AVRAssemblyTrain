#include  "m328pdef.inc"
 
 
.equ PWM_READY = 0x0100
.equ POT_HIGH = 0x0104
.equ POT_LOW = 0x0103
 
 
.equ TIMER_TREM1_LOW = 0x0115;
.equ TIMER_TREM1_HIGH = 0x0116;
.equ TIMER_TREM2_LOW = 0x0117;
.equ TIMER_TREM2_HIGH = 0x0118;
 
.equ TREM1_IN = 0x0111;
.equ TREM1_ENTERING = 0x0112;
 
.equ TREM2_IN = 0x0113;
.equ TREM2_ENTERING = 0x0114;
 
.equ pwm_tick = 0x0105
.equ servo1_pulse = 0x0106
.equ servo2_pulse = 0x0107
.equ servo3_pulse = 0x0108
.equ servo4_pulse = 0x0109
 
.equ overflow_timer0 = 0x0110
 
 
;--vetores irados--
.org 0x0000
    RJMP start
 
.org OVF1addr
RJMP TIMER1_OVF_ISR
 
.org OC1Aaddr
RJMP TIMER1_COMPA_ISR
 
.org OC1Baddr
RJMP TIMER1_COMPB_ISR
 
.org OVF0addr
    RJMP TIMER0_OVF_ISR
 
 
 
.org 0x0040
 
 
 
start:
LDI R24, 0
STS TIMER_TREM1_LOW, R24
STS TIMER_TREM1_HIGH, R24
STS TIMER_TREM2_LOW, R24
STS TIMER_TREM2_HIGH, R24
 
;motor A
SBI DDRB, PORTB3 ;pwm
SBI DDRB, PORTB4 ;a1
SBI DDRB, PORTB5 ;a2
 
;motor B
SBI DDRD, PORTD3 ;pwm
SBI DDRD, PORTD1 ;b1
SBI DDRD, PORTD2 ;b2 e led teste
 
;servos 1 e 2 ()
SBI DDRB, PORTB1 ;1
SBI DDRB, PORTB2 ;2
 
;servos 3 e 4 ()
SBI DDRD, PORTD5 ;1
SBI DDRD, PORTD6 ;2
 
;leds
SBI DDRC, PORTC3 ;led verde casa 1
SBI DDRC, PORTC4 ;led verde casa 2
 
 
CALL set_pwm_timer0
CALL set_pwm_timer1
CALL set_pwm_timer2
SEI
 
RJMP loop
 
loop:
SBIC PINC, 0 ; se PINC0 estiver 1, desliga tudo
RJMP emergency_brake
 
CALL read_potenciometro ;le o potenciometro
CALL set_speed ;seta velocidade dos motores
 
CALL trem1_controller ;libera e prende os trem
CALL trem2_controller
 
 
RJMP loop
 
trem1_controller:
SBIC PINC,2 ;se fim de curso da entrada tive pressionado
CALL trem1_check
 
SBIC PIND, 4 ;se o outro trem for entrar
CALL trem1_release
RET
 
trem1_release:
LDS R16, trem1_inside
LDI R17, 1
CP R16, R17
BREQ trem1_can_go ;se tiver trem dentro
 
RET
 
trem1_can_go: ;liga os motores e desliga o led
CBI PORTC, PINC3
SBI PORTB, PINB4
CBI PORTB, PINB5
 
RET
 
trem1_check:
LDS R16, TREM1_ENTERING
LDI R17, 1
CP R16, R17
BREQ trem1_entering_true ;se tiver trem ja entrando
 
LDS R16, TREM1_IN
LDI R17, 1
CP R16, R17
BREQ trem1_not_inside
 
RET
 
trem1_not_inside: ;nao tem trem entrando, abre porta, trem entrando
CALL open_servo3
LDI R16, 1
STS TREM1_ENTERING, R16
RET
 
trem1_entering_true:
LDS R16, TIMER_TREM1_HIGH ; conta um timer até dar 255 * 255.
LDI R17, 255
CP R16, R17
BREQ trem1_inside
LDS R16, TIMER_TREM1_LOW
INC R16
CP R16, R17
BREQ timer_trem1_ovf
 
RET
 
 
trem1_inside: ; trem dentro, liga led, desliga motor, fecha porta
LDI R16, 0
STS TIMER_TREM1_LOW, R16
STS TIMER_TREM1_HIGH, R16
STS TREM1_ENTERING, R16
LDI R19, 1
STS TREM1_IN, R19
SBI PORTC, PINC3
CALL close_servo3
CBI PORTB, PINB4
CBI PORTB, PINB5
 
RET
 
timer_trem1_ovf:
LDI R16, 0
STS TIMER_TREM1_LOW, R16
LDS R16, TIMER_TREM1_HIGH
INC R16
STS TIMER_TREM1_HIGH, R16
 
 
trem2_controller:
SBIC PIND,4
CALL trem2_check
 
SBIC PINC, 2
CALL trem2_release
RET
 
trem2_release:
LDS R16, trem2_inside
LDI R17, 1
CP R16, R17
BREQ trem2_can_go
 
RET
 
trem2_can_go:
CBI PORTC, PINC4
SBI PORTD, PIND1
CBI PORTD, PIND2
 
RET
 
trem2_check:
LDS R16, TREM2_ENTERING
LDI R17, 1
CP R16, R17
BREQ trem2_entering_true
 
LDS R16, TREM2_IN
LDI R17, 1
CP R16, R17
BREQ trem2_not_inside
 
RET
 
trem2_not_inside:
CALL open_servo4
LDI R16, 1
STS TREM2_ENTERING, R16
RET
 
trem2_entering_true:
LDS R16, TIMER_TREM2_HIGH
LDI R17, 255
CP R16, R17
BREQ trem2_inside
LDS R16, TIMER_TREM2_LOW
INC R16
CP R16, R17
BREQ timer_trem2_ovf
 
RET
 
 
trem2_inside:
LDI R16, 0
STS TIMER_TREM2_LOW, R16
STS TIMER_TREM2_HIGH, R16
STS TREM2_ENTERING, R16
LDI R19, 1
STS TREM2_IN, R19
SBI PORTC, PINC4
CALL close_servo3
CBI PORTD, PIND1
CBI PORTD, PIND2
 
RET
 
timer_trem2_ovf:
LDI R16, 0
STS TIMER_TREM2_LOW, R16
LDS R16, TIMER_TREM2_HIGH
INC R16
STS TIMER_TREM2_HIGH, R16
 
 
emergency_brake: ;desliga motores, desliga leds
LDI R24, 0
STS OCR2A, R24
    STS OCR2B, R24
CBI PORTC, PINC3
CBI PORTC, PINC4
RJMP loop
 
 
read_potenciometro: ;usa o ADC da porta do potenciometro pra ler os valores direto, como analogread é 1023, são duas variaveis de 8 bits, high e low (o total é 10bits, os outros 6 a gente nao acessa)
//portenciometro ta na porta C1,é nesse MUX que seto qual porta estou lendo
//e REF1 é o vcc.
LDI R24, (1<<REFS0) | (1<<MUX0)
    STS ADMUX, R24
 
//prescaler 128
LDI R24, (1<<ADEN)|(1<<ADSC)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
    STS ADCSRA, R24
 
LDI R17, (1<<ADSC)
convert_adc:
LDS R16, ADCSRA
SBR R17, (1<<ADSC)
AND R16, R17
BRNE convert_adc
 
LDS R18, ADCL
LDS R19, ADCH
STS POT_HIGH, R19
STS POT_LOW, R18
 
RET
 
set_speed:
 
;transforma de 10bit (1023) pra 8bit (255)
LDS R19, POT_HIGH
LDS R18, POT_LOW
 
LDI R26, 255
 
MOV R21, R18  
    MOV R22, R19  
 
LSR R22
    ROR R21
 
LSR R22
    ROR R21
 
MOV R20, R21
 
 
//range de 125 a 130 pra ser o 0.
 
//seta por padrao as portas pra frente (10 - 10)
SBI PORTB, PINB4
CBI PORTB, PINB5
 
SBI PORTD, PIND2
CBI PORTD, PIND1
 
LDI R21, 125
CP R20, R21
BRLO engine_back
 
LDI R21, 131
CP R20, R21
BRLO engine_zero
 
//motor normal
//subtrai 131 DO valor [x - 131] (se entrar 131, sai 0, se entrar 255 sai 124)
LDI R21, 131
SUB R20, R21
 
MUL R20, R26
 
//divide a saida por 124
MOV R20, R0
CLR R21
LDI R22, 124
RCALL divisor_motor
RJMP engine_speed
 
engine_speed:
//seta velocidadezada que tiver no registrador 20 nos motores
STS OCR2A, R20
STS OCR2B, R20
RET
 
engine_back:
//motor invertido
// subtrai o valor de 124 [124 - x] (inverte) (entrou 0, sai 124, entrou 124 sai 0)
LDI R21, 124
SUB R21, R20
MOV R20, R21
MUL R20, R26
 
 
//divide a saida por 124
MOV R20, R0
CLR R21
LDI R22, 124
RCALL divisor_motor
 
//inverte as portas (01 - 01)
CBI PORTB, PINB4
SBI PORTB, PINB5
 
CBI PORTD, PIND2
SBI PORTD, PIND1
RJMP engine_speed
 
engine_zero:
//zera as portas (00 e 00) e zera a velocidade tbm
CBI PORTB, PINB4
CBI PORTB, PINB5
 
CBI PORTD, PIND2
CBI PORTD, PIND1
LDI R20, 0
RJMP engine_speed
 
 
RET
 
 
//basicamente subtrai o dividendo do divisor, ve se NAO tem sobra com o bit de conta do avr (BRCS), ai sai, se tiver, repete o loop e incrementa o resultado. (foi o melhor divisor que eu consegui)
divisor_motor:
    CLR R21
    CLR R23
LDI R26, 1
divisor_motor_loop:
INC R21
SUB R20, R22
BRCS divisor_motor_end
ADD R23, R26
RJMP divisor_motor_loop
divisor_motor_end:
MOV R20, R23
RET
 
 
 
//retornando os interrupts por segurança
TIMER1_OVF_ISR:
RETI
 
 
//pwm por software. timer 1 incrementa a cada 10 nanosegundos. os servos tem os valores salvos nas variaveis servoX_pulse, com valores de 100 (1ms) até 200 (2 ms) que é 0 graus até 180
TIMER1_COMPA_ISR:
LDS R16, pwm_tick
    INC R16
STS pwm_tick, R16
 
servo1:
LDS R17, servo1_pulse
CP R16, R17
BRLO servo1_on
CBI PORTB, 1
RJMP servo2
servo1_on:
SBI PORTB, 1
 
servo2:
LDS R17, servo2_pulse
CP R16, R17
BRLO servo2_on
CBI PORTB, 2
RJMP servo3
servo2_on:
SBI PORTB, 2
 
servo3:
LDS R17, servo3_pulse
CP R16, R17
BRLO servo3_on
CBI PORTD, 5
RJMP servo4
servo3_on:
SBI PORTD, 5
 
servo4:
LDS R17, servo4_pulse
CP R16, R17
BRLO servo4_on
CBI PORTD, 6
RJMP end
servo4_on:
SBI PORTD, 6
 
end:
RETI
 
TIMER1_COMPB_ISR:
RETI
 
//usando o outro timer pra controlar o overflow (pra nao dar jitter e tambem pra eu nao ter dor de cabeça de fazer o timer1 chegar até 2 mil (precisaria de duas variaveis). conta de 1 em 1 ms até 20ms. ai reseta o pwm tick e o contador
TIMER0_OVF_ISR:
    LDS R17, overflow_timer0
    INC R17
    CPI R17, 20        
    BRLO skip_reset
    LDI R17, 0
    LDI R18, 0
    STS pwm_tick, R18
skip_reset:
    STS overflow_timer0, R17
    RETI
 
//fast pwm, basicamente só pra escrever
set_pwm_timer2:
LDI R24, (1<<COM2A1) | (1<<COM2B1) | (1<<WGM21) | (1<<WGM20)
    STS TCCR2A, R24
 
    LDI R24, (1<<CS22)
    STS TCCR2B, R24
 
RET
 
 
 
//timer de 10nanosegundos (valor setado no COMPA)
set_pwm_timer1:
LDI R16, (1 << WGM12)
    STS TCCR1B, R16
 
    ; prescaler de  8 (CS11 = 1)
    LDI R16, (1 << CS11)
    ORI R16, (1 << WGM12)
    STS TCCR1B, R16
 
    LDI R16, (19 >> 8)
    STS OCR1AH, R16
LDI R16, 19
    STS OCR1AL, R16
 
    LDI R16, (1 << OCIE1A)
    STS TIMSK1, R16
 
    LDI R16, 0
    STS pwm_tick, R16
 
LDI R17, 100
STS servo1_pulse, R17
STS servo2_pulse, R17
STS servo3_pulse, R17
STS servo4_pulse, R17
 
RET
 
//timer de 1ms (sem comparador, a logica ta no overflow.)
 
//fun fact, se voce usar os alias TCCR0B e TCCR0A, o microchip studio joga o valor nas casas 0x36 e 0x37,  ta errado. essas casas são bits dentro do TIMSK1 do timer 1.
//tive que por 0X44 e 0x45 na mao pq os alias tão errados.
set_pwm_timer0:
    LDI R16, 0
    STS 0x44, R16
 
    LDI R16, 3
STS 0x45, R16
 
    LDI R16, (1 << TOIE0)
    STS TIMSK0, R16
 
    LDI R16, (1 << CS01) | (1 << CS00)
STS TCNT0, R16
    STS overflow_timer0, R16
 
    RET
 
 
open_servo1:
LDI R17, 200
STS servo1_pulse, R17
RET
close_servo1:
LDI R17, 100
STS servo1_pulse, R17
RET
 
open_servo2:
LDI R17, 200
STS servo2_pulse, R17
RET
close_servo2:
LDI R17, 100
STS servo2_pulse, R17
RET
 
open_servo3:
LDI R17, 200
STS servo3_pulse, R17
RET
close_servo3:
LDI R17, 100
STS servo3_pulse, R17
RET
 
open_servo4:
LDI R17, 200
STS servo4_pulse, R17
RET
close_servo4:
LDI R17, 100
STS servo4_pulse, R17
RET