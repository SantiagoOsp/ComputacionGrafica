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

Se puede hacer uso de un argumento como `(getstring 1 "Anote descripcion")` para restringir la entrada a NO-NULA.
