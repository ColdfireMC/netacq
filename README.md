# netacq-Para Nexys Video
Datalogger de I2C. Contiene porciones de los siguientes autores
* Alex Forencich: verilog-ethernet
* Luke Renaud, Digilent: i2c-demo

## Instrucciones de uso

El sistema comienza a adquirir automáticamente una vez encendido, de 192.168.1.128:1234 al 192.168.1.2:54638. El sistema envía una ráfaga de 3 tramas UDP. Cada muestra es de 64bit con un formato como este

![tipo de la muestra](https://github.com/ColdfireMC/netacq/blob/main/diags/sampletype.svg "Tipo de la muestra")


Los tipos son big endian. El timestamp corre a 25MHz.Puede configurarse desde el código fuente la frecuencia del bus i2c, con ello aumenta la frecuencia de muestreo con la siguiente expresión


El i2c está en modo normal, no en modo estiramiento de reloj, por lo que deben alambrarse resistencias de pull up adicionales a SCL y SDA para estabilizar la comunicación y deben corresponder con la frecuencia.

## Detalles para nerds

![Máquina de estados del FIFO](https://github.com/ColdfireMC/netacq/blob/main/diags/fifo_comp3.svg "Máquina de estados del FIFO")


![Máquina de estados del FIFO](https://github.com/ColdfireMC/netacq/blob/main/diags/timestamp.svg "Máquina de estados del timestamp")

### Estructura interna del sistema




### Detalles del bus AXI-Stream




## Script de matlab
Hay un script de matlab que hace adquisición basica. Cuenta con una calibración bastante "relajada". Matlab no tiene una buena gestión de eventos, por lo que no es suficientemente atraxctivo para intentar hacer una adquisición viva (Entiéndase, como un osciloscopio).



## Posibles Upgrades

* Ráfagas más largas: Es posible en una trama UDP, empaquetar 64kbytes. Cada ráfaga del fifo tiene como máximo 512 muestras, por lo que cada ráfaga del fifo sería de 4kb. vaciando el fifo varias veces y marcando la señal `tlast` al final, es posible consolidar tal trama

* Modo de alargamiento de reloj i2c: El modo de alargamiento de reloj, aunque baja el troughput, puede estabilizar el dispositivo i2c y cargarlo. Esto permite aumentar largamente las frecuencias de operación (sobre el MHz de SCL).

* Bus de 64bit: En el github de Alex Forencich, existe un ejemplo con bus AXI-Stream de 64 bit para otro FPGA. Esto simplificaría en buena parte la máquina de estados del bus, aunque podria dificultar un poco la depuración al ensanchar el bus

* Modo configuración: verilog-ethernet puede recibir tramas UDP o IP. Sin embargo la maquina de estados de interfaz solo envía tramas UDP. Una utilidad de software podría ayudar a configurar el dispositivo para modificar cosas como la configuración de los PMOD, o la velocidad de reloj.



