######################################################
### CONTEO DE PLANTAS CON EL PAQUETE "FIELDImageR"####
######################################################
#no TePpuedo

#VIDEO EN Youtube QUE EXPLICA EL FUNCIONAMIENTO: https://www.youtube.com/watch?v=v0gAq302Ueg
# VIDEO COMPLETO EN Youtube: https://www.youtube.com/watch?v=DOD0ZX_J8tk

#INFORMACION EN GitHub:https://github.com/OpenDroneMap/FIELDimageR 

# "FIELDimageR: A Tool to Analyze Orthomosaic Images From Agricultural Field Trials in R"

## Para acceder y guardar las librerias en el repositorio de GitHub se necesita isntalar "Rtools4." 
#Esta versión de Rtools se basa en msys2,lo que facilita la creación y el mantenimiento de R en sí, así como las bibliotecas 
#del sistema que necesitan los paquetes de R en Windows. 

##Para instalar la paquetería ("Rtools4") nececitamos instalar "devtools"  

install.packages("devtools")
devtools::install_github("filipematias23/FIELDimageR")

##Using R/FIELDimageR
setwd("D:\\Ra\\Ideas_Proyectos_Cursos\\Diplomatura_Cs._de_Datos\\Prueba_CountPLant")

# 1. First steps
library(sp) ## paquete de "Spatial Data"
library(FIELDimageR)
library(raster)


# 2. Selecting the targeted field from the original image
#Primero es necesario reducir el tamaño de la imagen/mosaico alrededor de los límites del campo para un análisis de imagen más rápido.
#Función a utilizar: fieldCrop. El siguiente ejemplo usa una imagen disponible para descargar aquí: EX1_RGB.tif.

Image1= stack("EX1_RGB.tif")
plotRGB(Image1, r = 1, g = 2, b= 3)

Image1.Crop = fieldCrop(mosaic = Image1) #Para imágenes pesadas (grandes, de alta resolución) utilice: fast.plot = T 

# 3. Rotating the image

# Codeline when you don't know the rotation angle "Theta":
Image1.crop.Rotated <- fieldRotate(mosaic = Image1.Crop, clockwise = F, h=F) # h=horizontal

# Codeline when you know the rotation angle "Theta" (theta = 2.3):
Image1.crop.Rotated <- fieldRotate(mosaic = Image1.crop, theta = 2.3)

# Codeline with "extentGIS=TRUE" to fit back the shapefile to the original image GIS. More information at section "5. Building the plot shape file":
Image1.crop.Rotated <-fieldRotate(mosaic = Image1.crop, theta = 2.3, extentGIS=TRUE)

# 4. Removing soil using vegetation indices

# La presencia de suelo puede introducir sesgos en los datos extraídos de la imagen. Por lo tanto, eliminar el suelo de la imagen es uno de 
# los pasos más importantes para el análisis de imágenes en las ciencias agrícolas. Función a utilizar: fieldMask 

Image1.RemSoil <- fieldMask(mosaic = Image1.crop.Rotated, Red = 1, Green = 2, Blue = 3, index = "HUE")

# 5. Building the plot shape file

# Una vez que el campo ha alcanzado una posición recta correcta, el archivo de forma de la trama se puede dibujar seleccionando al menos cuatro puntos en las esquinas del experimento. 
# Se debe informar el número de columnas y filas. En este punto se pueden eliminar los bordes experimentales, en el ejemplo de abajo se eliminaron los bordes en todos los lados. Función a utilizar: fieldShape

Image1.Shape <- fieldShape(mosaic = Image1.RemSoil, ncols = 14, nrows = 9)

# Atención: Las parcelas se identifican en orden ascendente de izquierda a derecha y de arriba a abajo 
# estando uniformemente espaciadas y distribuidas dentro del área seleccionada independientemente de los callejones.


#Se puede usar una matriz para identificar la posición de las parcelas de acuerdo con la imagen de arriba. 
#La función fieldMap se puede usar para especificar el ID de la parcela automáticamente o también se puede usar cualquier otra matriz (construida manualmente). 
#Por ejemplo, la nueva columna PlotName será la nueva identificación.


### Field map identification (name for each Plot). 'fieldPlot' argument can be a number or name.

DataTable<-read.csv("DataTable.csv",header = T)

fieldMap<-fieldMap(fieldPlot= DataTable$Plot, fieldColumn=DataTable$Row, fieldRow=DataTable$Range, decreasing=T)
fieldMap

# The new column PlotName is identifying the plots:

Image1.Shape<-fieldShape(mosaic = Image1.RemSoil, ncols = 14, nrows = 9, fieldMap = fieldMap)

### Joing all information in one "fieldShape" file:

Image1.Shape<-fieldShape(mosaic = Image1.RemSoil, ncols = 14, nrows = 9, fieldMap = fieldMap, 
                      fieldData = DataTable, ID = "Plot")

# The new column PlotName is identifying the plots:                      
Image1.Shape$fieldShape@data                      

# Importante: Código que muestra cómo hacer ShapeFile usando GIS original 
# Ejemplo 01: Usando el ángulo de rotación (theta = 2.3) del paso 3 (fieldRotate) para ajustar el archivo "fieldShape" a la imagen original GIS (fieldShapeGIS):

### Rotation angle "theta=2.3" from fieldRotate():

Image1.Shape<-fieldShape(mosaic = Image1.RemSoil, ncols = 14, nrows = 9, fieldMap = fieldMap, 
                      fieldData = DataTable, ID = "Plot", theta = 2.3)

plotRGB(Image1)
plotRGB(Image1.RemSoil$newMosaic)
plot(Image1.Shape$fieldShape,add=T)

plotRGB(Image1)
plot(Image1.Shape$fieldShapeGIS,add=T) 


# 6. Building vegetation indices

# Se implementa un número general de índices en FIELDimageR usando la función fieldIndex. 
# Además, puede crear su propio índice utilizando el parámetro myIndex

# Calculating myIndex = "(Red-Blue)/Green" (not avaliable at 'FIELDimageR')

Image1.Indices<- fieldIndex(mosaic = Image1.RemSoil$newMosaic, Red = 1, Green = 2, Blue = 3, 
                         index = c("NGRDI","BGI"), 
                         myIndex = c("(Red-Blue)/Green"))

# More than one myIndex code: myIndex = c("myIndex1","myIndex2","myIndex3")    

Image1.Indices.myIndex<- fieldIndex(mosaic = Image1.RemSoil$newMosaic, Red = 1, Green = 2, Blue = 3, 
                                 index = c("NGRDI","BGI"), 
                                 myIndex = c("(Red-Blue)/Green","Red/Green","Blue/Green"))


#Sugerencia: esta función también se puede utilizar para crear un índice para eliminar la tierra o las malas hierbas. 
#Primero es necesario identificar el umbral para diferenciar el suelo del material vegetal. En el siguiente ejemplo (B), 
#todos los valores por encima de 0,7 se consideraron suelo y se eliminaron con fieldMask (C & D).


Image1.Indices.BGI<- fieldIndex(mosaic = Image1.crop.Rotated, index = c("BGI"))

dev.off()
hist(Image1.Indices.BGI$BGI) # Image segmentation start from 0.7 (soil and plants)

Image1.BGI<- fieldMask(mosaic = Image1.crop.Rotated, Red = 1, Green = 2, Blue = 3, 
                    index = "BGI", cropValue = 0.7, cropAbove = T) 

#Check if: cropValue=0.8 or cropValue=0.6 works better.


# 7. Counting the number of objects (e.g. plants, seeds, etc)

# FIELDimageR se puede utilizar para evaluar el número de rodales durante las primeras etapas. 
# Se debe realizar una buena práctica de control de malezas para evitar errores de identificación dentro de la parcela.
# Se deben utilizar la salida de máscara de fieldMask y la salida de fieldshape de fieldShape. 
# Función a utilizar: fieldCount. El parámetro n.core se utiliza para acelerar el conteo (paralelo)

Image1.SC<-fieldCount(mosaic = Image1.RemSoil$mask, fieldShape = Image1.Shape$fieldShape, cex=0.4, col="blue")
Image1.SC$fieldCount

### Parallel (n.core = 3)
EX1.SC<-fieldCount(mosaic = EX1.RemSoil$mask, fieldShape = EX1.Shape$fieldShape, n.core = 3, cex=0.4, col="blue")
EX1.SC$fieldCount

# Para refinar el recuento de rodales, podemos eliminar aún más las malezas (plantas pequeñas) o las ramas periféricas de la 
# salida utilizando el parámetro Tamaño mínimo. 
# El siguiente ejemplo utiliza una imagen disponible para descargar aquí: EX_StandCount.tif


# Uploading file (PRUEBA CON MIS DATOS...)  ############3 NO FUNCIONO BIEN, HAY ALGUN ERROR ###################

Prueba<-stack("2075883_2_2_406352007_20210304.jpg")
Prueba
plotRGB(Prueba, r = 1, g = 2, b = 3)

# Removing the soil
Prueba.RemSoil<- fieldMask(mosaic = Prueba, index = "BGI", cropValue = 0.55, cropAbove = T)

##Acá podría ver un poco la tolerancia de las plantas con respecto al suelo...

Prueba.RemSoil.BGI<- fieldIndex(mosaic = Prueba.RemSoil, index = c("BGI"))

dev.off()
hist(Prueba.RemSoil.BGI$BGI) # Image segmentation start from 0.7 (soil and plants)

Prueba.RemSoil.Mask.BGI<- fieldMask(mosaic = Prueba.RemSoil.BGI, Red = 1, Green = 2, Blue = 3, 
                       index = "BGI", cropValue = 0.5, cropAbove = T,
                       dist)
distmap()

# Building the plot shapefile (ncols = 1 and nrows = 7)

Prueba.RemSoil.Mask.BGI.Shape<-fieldShape(mosaic = Prueba.RemSoil, ncols = 1, nrows = 8)
Prueba.RemSoil.Mask.BGI.Shape

### When all shapes are counted: minSize = 0.00

Prueba.FINAL<-fieldCount(mosaic = Prueba.RemSoil$mask, 
                   fieldShape = Prueba.RemSoil$fieldShape,
                   minSize = 0)

Prueba$objectSel[[4]] # Identifies 14 points, but point 6 and 9 are small artifacts
Prueba$objectReject[[4]] # No shape rejected because minSize = 0.00



# Uploading file (PRUEBA 1)

EX.SC<-stack("2075883_2_2_406352007_20210304.jpg")
plotRGB(EX.SC, r = 1, g = 2, b = 3)
EX.SC

# Removing the soil
EX.SC.RemSoil<- fieldMask(mosaic = EX.SC, Red = 1, Green = 2, Blue = 3, index = "BGI", cropValue = 0.55) 
## sE CAMBIO DE INDICE "HUE" POR E "BGI"

# Building the plot shapefile (ncols = 1 and nrows = 7)
EX.SC.Shape<-fieldShape(mosaic = EX.SC.RemSoil,ncols = 1, nrows = 8)

### When all shapes are counted: minSize = 0.00

EX1.SC<-fieldCount(mosaic = EX.SC.RemSoil$mask, 
                   fieldShape = EX.SC.Shape$fieldShape,
                   minSize = 0.00)

EX1.SC$objectSel[[4]] # Identifies 14 points, but point 6 and 9 are small artifacts 
# A ANALIZAR EL SURCO 4, SEENCUENTRAN PTOS QUE NO REPRESENTAN PLANTAS, EN ESTE CASO POR SU TAMAÑO. 
# AL ANALIZAR SU TAMAÑO SE PUEDE COLOCAR UN FILTRO PARA QUE SOLO SE CONSIDEREN LAS MAS IMPORTANTES
EX1.SC$objectReject[[4]] # No shape rejected because minSize = 0.00

### When all shapes with size greater than 0.04% of plot area are counted: minSize = 0.04

EX1.SC<-fieldCount(mosaic = EX.SC.RemSoil$mask, 
                   fieldShape = EX.SC.Shape$fieldShape,
                   minSize = 0.35)

EX1.SC$objectSel[[4]] # Identifies 12 points
EX1.SC$objectReject[[4]] # Shows 2 artifacts that were rejected (6 and 9 from previous example)

########################################################################################################

# Uploading file (PRUEBA 2)

EX.SC<-stack("2071758_2_4_405368378_1.TIF")
plotRGB(EX.SC, r = 1, g = 2, b = 3)
EX.SC

# Removing the soil
EX.SC.RemSoil<- fieldMask(mosaic = EX.SC, Red = 1, Green = 2, Blue = 3, index = "HUE", cropValue = 0.9) 
## sE CAMBIO DE INDICE "HUE" POR E "BGI"

# Building the plot shapefile (ncols = 1 and nrows = 7)
EX.SC.Shape<-fieldShape(mosaic = EX.SC.RemSoil,ncols = 1, nrows = 1)

### When all shapes are counted: minSize = 0.00

EX1.SC<-fieldCount(mosaic = EX.SC.RemSoil$mask, 
                   fieldShape = EX.SC.Shape$fieldShape,
                   minSize = 0.00)

EX1.SC$objectSel[[4]] # Identifies 14 points, but point 6 and 9 are small artifacts 
# A ANALIZAR EL SURCO 4, SEENCUENTRAN PTOS QUE NO REPRESENTAN PLANTAS, EN ESTE CASO POR SU TAMAÑO. 
# AL ANALIZAR SU TAMAÑO SE PUEDE COLOCAR UN FILTRO PARA QUE SOLO SE CONSIDEREN LAS MAS IMPORTANTES
EX1.SC$objectReject[[4]] # No shape rejected because minSize = 0.00

### When all shapes with size greater than 0.04% of plot area are counted: minSize = 0.04

EX1.SC<-fieldCount(mosaic = EX.SC.RemSoil$mask, 
                   fieldShape = EX.SC.Shape$fieldShape,
                   minSize = 0.06)

EX1.SC$objectSel[[4]] # Identifies 12 points
EX1.SC$objectReject[[4]] # Shows 2 artifacts that were rejected (6 and 9 from previous example)





