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

El proyecto es a grandes rasgos, "lógica de pegamento" y una serie de ajustes menores. El núcleo I2C se modificó en 2 líneas para admitir más frecuencia (pero utilizar muchísimo más espacio)

### Máquinas de estado agregadas al sistema

![Máquina de estados del FIFO](https://github.com/ColdfireMC/netacq/blob/main/diags/fifo_comp3.svg "Máquina de estados del FIFO")



| Estado        | Señal          | Valor                  |
| ------------- |:--------------:|:----------------------:|
| init          | out_valid      |             0          |
|               | out_data_input |             0          |
|               | burst_ready    |             0          |
| wait_1st      | out_valid      |             0          |
|               | out_data_input |             0          |
|               | burst_ready    |             0          |
| wait_others   | out_valid      |             0          |
|               | out_data_input |             0          |
|               | burst_ready    |             0          |
| output_valid  | out_valid      |             0          |
|               | out_data_input |             0          |
|               | burst_ready    |             0          |
| out_chan0     | out_valid      |             0          |
|               | out_data_input |   reg_packed_sample0   |
|               | burst_ready    |             0          |
| signal_chan0  | out_valid      |             1          |
|               | out_data_input |   reg_packed_sample0   |
|               | burst_ready    |             0          |
| out_chan1     | out_valid      |             0          |
|               | out_data_input |   reg_packed_sample1   |
|               | burst_ready    |             0          |
| signal_chan1  | out_valid      |             1          |
|               | out_data_input |   reg_packed_sample1   |
|               | burst_ready    |             0          |
| out_chan2     | out_valid      |             0          |
|               | out_data_input |   reg_packed_sample2   |
|               | burst_ready    |             0          |
| signal_chan2  | out_valid      |             1          |
|               | out_data_input |   reg_packed_sample2   |
|               | burst_ready    |             0          |
| out_term      | out_valid      |             0          |
|               | out_data_input |             0          |
|               | burst_ready    |             1          |





pendiente: Tablas con las salidas(son demasiadas como para incorporarlas al diagrama)

![Máquina de estados del timestamp](https://github.com/ColdfireMC/netacq/blob/main/diags/timestamp.svg "Máquina de estados del timestamp")

pendiente: Tablas con las salidas(son demasiadas como para incorporarlas al diagrama)

### Componente Opcional: Generador de cadenas

En el desarrollo inicial (con serial), se implementó un módulo que convertía a ASCII los valores de la muestra y enviaba las tramas. Se adaptó para usarlo con AXI-Stream y poder ver la integridad del contenido. Sin embargo, no es extraíble de manera cómoda, al menos por matlab, y necesita de un preámbulo para poder ser visto en un terminal, por lo que cualquier ventaja derivada de tener texto, se pierde debido a la complejidad adicional en el software o en el protocolo. Adicionalmente, multiplica en el mejor de los casos por 8 la cantidad de bytes necesarios de transferir, por lo que fue sacada de la implementación final, aunque queda disponible el código fuente para hacer más pruebas.


### Estructura interna del sistema

Pendiente


### Detalles del bus AXI-Stream

Hay en el proyecto, el código fuente de una pequeña máquina de estados que envía una cadena por ethernet. Este podría considerarse un dispositivo AXI-Stream mínimo


## Script de matlab
Hay un script de matlab que hace adquisición basica. Cuenta con una calibración bastante "relajada". Matlab no tiene una buena gestión de eventos, por lo que no es suficientemente atractivo para intentar hacer una adquisición viva (Entiéndase, como un osciloscopio). Para tales fines, un programa ejecutable binario(C, C#,Java) o un script en python podrían ser una mejor solución.


## Posibles Upgrades

* Ráfagas más largas: Es posible en una trama UDP, empaquetar 64kbytes. Cada ráfaga del fifo tiene como máximo 512 muestras, por lo que cada ráfaga del fifo sería de 4kb. vaciando el fifo varias veces y marcando la señal `tlast` al final, es posible consolidar tal trama

* Modo de alargamiento de reloj i2c: El modo de alargamiento de reloj, aunque baja el throughput, puede estabilizar el dispositivo i2c y cargarlo. Esto permite aumentar largamente las frecuencias de operación (sobre el MHz de SCL).

* Bus de 64bit: En el github de Alex Forencich, existe un ejemplo con bus AXI-Stream de 64 bit para otro FPGA. Esto simplificaría en buena parte la máquina de estados del bus, aunque podria dificultar un poco la depuración al ensanchar el bus

* Modo configuración: verilog-ethernet puede recibir tramas UDP o IP. Sin embargo la maquina de estados de interfaz solo envía tramas UDP. Una utilidad de software podría ayudar a configurar el dispositivo para modificar cosas como la configuración de los PMOD, o las tasas de muestro, o la dirección IP.

* IPV6: ?

