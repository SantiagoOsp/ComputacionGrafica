### Guardar una variable

```lisp
(setq a 10)
```

El uso de la palabra reservada `setq`, luego el nombre de la variable y su valor. Se puede guardar cualquier tipo de valor. Incluso puede guardar una lista de la siguiente forma:

```lisp
(setq a 10 b "Bogota" c 7)
(setq d 10 25 4 3) ; Lista
```

### Imprimir variables

```lisp
(print a)
```

Usando `print` se muestra el valor 2 veces, cuando se lee y cuando se imprime. Para solo mostrar la variable por consultar:

```lisp
!a
```

En la consola del editor de LISP es posible solo usar el nombre de la variable. Ademas, podemos usar operaciones de la siguiente forma:

```lisp
(setq radio (* 10 20))
```

[!important] Dato LISP no distingue entre mayusculas y minusculas

### Ejecutar comandos específicos de AutoCAD

```lisp
(command ...)
```

Como AutoCAD tiene distintos idiomas y para estandarizar los comandos a nivel internacional, se puede usar `_` antes del comando deseado:

```lisp
(command "_circle" "100,300" 500)
```

### Ver propiedades

Para ver las propiedades se usa el comando `list`

### Mostrar todos los elementos dibujados

```lisp
(zoom "E")
```

El valor `"E"` de Extends es una opcion predeterminada de zoom para mostrar todo lo dibujado

### Comandos para dibujar Lineas

```lisp
"_line"
"_pline"
```

Estos comandos lo que permiten es dibujar una linea y una polilinea respectivamente. Para la linea necesitamos un punto de inicio y uno de fin.

```lisp
(command "_line" )
```

### Obtener fecha y hora

Para obtener la fecha que usa el dispositivo, debemos usar el comando `cdate`. El formato en el que la da es; `AAAAMMDD.hhmmsscseg`

```lisp
(setq fecha_hora (getvar "cdate"))
```

## Conversion de tipos de datos

Existen variedad de tipos de datos usados en VisualLISP. Estos pueden ser usados como caracteres, como strings, como enteros, como numeros reales, etc... Y para esto podemos convertirlos una ves los tenemos en el sistema:

- itoa --> Convierte un entero en una cadena
- atoi --> Convierte una cadena en un entero
- rtos --> Convierte un numero real en una cadena
- atof --> convierte una cadena en un numero real
- distof --> Convierte una cadena en un numero real
- angtos --> Convierte un angulo en una cadena
- angtof --> Convierte una cadena en un angulo

## Manejo de caracteres de texto

Como en todo lenguaje tenemos uso de caracteres o cadenas de caracteres con las cuales podemos hacer uso de distintos metodos para manipularlos. Estos son:

- ascii --> Devuelve un caracter en codigo ASCII
- chr --> Devuelve el caracter representado por un codigo ASCII
- strlen --> Numero de caracteres en una cadena
- strcat --> Concatena caracteres
- substr --> Subcadena de caracteres
- strcase --> Convierte mayusculas a minusculas o visceversa
- wcmatch --> Encuentra caracteres que coinciden con wild-cards

### SUBSTR

Para poder dividir una cadena de caracteres debemos saber que cada caracter viene indexado desde el numero 1 hasta la cantidad de caracteres que tenga. Si tomamos como ejemplo la fecha, que viene `AAAAMMDD.hhmmsscseg`. Si quisieramos obtener el año, el mes y el dia de forma independiente en una variable, lo hariamos de la siguiente manera:

```LISP
(setq año_t (substr fecha_hora_t 1 4))
(setq mes_t (substr fecha_hora_t 5 2))
(setq dia_t (substr fecha_hora_t 7 2))
```

Donde tenemos como primer argumento la cadena de texto que queremos truncar, fecha_hora_t. Luego tenemos el indice donde queremos que inicie el corte y cuantos caracteres tomar `(... 1 4)`.

---

### Entradas de Usuario y variables del sistema

#### Funciones GET

Estas funciones producen una pausa en el programa para solicitar al usuario que ingrese un valor.

##### GETINT

```lisp
(getint ...)
```

Esta funcion permite solicitarle al usuario un numero entero

##### GETREAL

```lisp
(getreal ...)
```

`getreal` solicita al usuario que ingrese un valor real (puede ser decimal). Siempre responde con un numero real asi la entrada sea un numero entero.

##### GETPOINT - GETCORNER

```lisp
(getpoint ...)
(getcorner ...)
```

Estas funciones piden al usuario una localizacion de un punto, ya sea por click en pantalla o por ingreso de coordenadas del usuario. ESta funcion retorna una lista de tres numeros reales: X Y Z.

Si se ingresan solo 2 valores, la maquina usa por defecto el valor 0.0 en Z

##### GETSTRINGS

```lisp
(getstring ...)
```

Se puede hacer uso de un argumento como `(getstring 1 "Anote descripcion")` para restringir la entrada a NO-NULA. Esto lo veremos mas adelante en una tabla.

#### INITGET con un argumento de numero entero

Toma un argumento de numero entero o cadena de caracteres, o ambos, para poner limitaciones a las respuestas dadas por el usuario en la siguiente funcion-get.

```lisp
(initget 4)
(setq grosor (getreal "\nAnote el grosor:"))
``` 

#### Tabla de valores

Decimal  | Binario  | Significado
------------- | -------------  |  ------------
1  | 0001  | La respuesta no puede ser nula
2  | 0010  | Los numeros no pueden ser ceros
3  | 0011  | No pueden ser ceros ni respuesta nula
4  | 0100  | Los numeros no pueden ser negativos
5  | 0101  | Los numeros no pueden ser negativos ni respuesta nula

Existen mas codigos que permiten combinar varios de los mencionados en la tabla o incluso modificar la entrada para que sea con algun punto o caracter especial.

El uso de `INITGET` es muy importante para el programa ya que filtra las entradas viciadas 

## Listas

Para poder crear una nueva lista y asignarla a alguna variable se hace de la siguiente forma:

```lisp
(setq L1 (list 55 66 77))
```

Esta funcion tiene distintos metodos que modifican su estructura, ya sea agregando o copiandola en otra variable. Estos comandos son `CONS` y `APPEND`. Uno crea una copia de la lista y el otro agrega al final de la lista el valor deseado (respectivamente).

```lisp
(setq L2 (cons 44 L1)) ; Aca se crea una copia de la lista L1 pero con un valor al principio (44)
(setq L3 (append L2 (list 88)))
```

Tambien es posible crear una lista vacia, pasando como argumento `()` o `nil`.

## FUNCIONES

Al igual que la palabra `setq` asigna una lista a una variable deseada, la palabra reservada `defun` asigna una serie de conjunto de listas (un programa) a un simbolo. Luego se cita dicho simbolo y se ejecuta el programa. Los siguientes ejemplos se usan como ilustracion. El primero define una *funcion*, mientras que el segundo define un *comando*.

```lisp
(defun Areacirc (rad) (* pi rad rad))
(defun c: Areacirc ()
    (setq rad (getreal "\nAnotar el radio:"))
    (princ "\nArea = ")(* pi rad rad)
)
```

La sintaxis de una funcion "defun" consta de tres partes: el nombre, la lista de variables y las expresiones del programa. Un ejemplo de una funcion lo vemos en el archivo [EjemploFunc.lsp](/AutoCAD/EjemploFunc.lsp)

---

### Retardos

Usando el comando `delay` podemos generar un tiempo de espera deseado (ingresado por el usuario o definido por nosotros) en milisegundos, antes de pasar a la siguiente instruccion:

```lisp
(command "_delay" 1000)  ; Retardo de 1 segundo
```

Se pueden usar tambien (para mejorar exactitud) los comandos `regen` y `redraw`

### Arreglos

Con el comando `array` se pueden dibujar las lineas de alrededor del cuerpo del reloj

### Funciones VLA