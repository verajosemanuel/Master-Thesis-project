#!/bin/bash


# todos los parametros son obligatorios

FOLDER=$1       # directorio a procesar


echo "DOCUMENTO^PREDICCION^MEJORA^GENERAL^EMBARGO^CONSULTA" > predictivo_temas.csv  # conteo de palabras

#cd $FOLDER

 for f in *.txt
 do
 	
	#  limpiamos el contenido de caracteres extraños
	CONTENIDOF=""$(cat $f | tr -cd '[[:alnum:]][áéíóúÁÉÍÓÚñÑªºüÜ°;-]\40-\040\045\054\011\012\015\057\050\051\100\128\176\056' | sed '/^$/d' | sed 's/[^[:print:]]/ /g')
	# nombre del fichero sin la extensión
	DOCUMENTO=""$(basename $f .txt) 
	
	contiene_mejora=""$(echo "$CONTENIDOF" | grep -E -i -o -c '\bmejora\b')
	contiene_general=""$(echo "$CONTENIDOF" | grep -E -i -o -c '\bgeneral\b')
	contiene_embargo=""$(echo "$CONTENIDOF" | grep -E -i -o -c '\bembargo\b')
	contiene_consulta=""$(echo "$CONTENIDOF" | grep -E -i -o -c '\bconsulta\b')
	tema_detectado="desconocido"

# clasificación por contenido extraída a partir de arbol de inferencia con R
		   
		if [ $contiene_mejora -gt 0 ]; then  
				
				tema_detectado="NOTIFICACIONES"
				
			else
		   
					if [ $contiene_general -gt 2 ]; then  
					
						tema_detectado="ORDENAMIENTO"
					
						else
				
							if [ $contiene_embargo -gt 2 ]; then   
						
									tema_detectado="OTROS"
					
								else
							
									if [ $contiene_consulta -gt 0 ]; then
									
										tema_detectado="ORDENAMIENTO"
										
										else
									
											if [ $contiene_embargo -gt 0 ]; then
										
												tema_detectado="APROBACION-NOTIFICACIONES-OTROS"
										
											else
										
											tema_detectado="APROBACION"
											
											fi
										
									fi
							
								fi
					
						
						fi 
			fi
			
	#insertamos linea con los datos en el fichero CSV
				
	echo "${DOCUMENTO}^${tema_detectado}^${contiene_mejora}^${contiene_general}^${contiene_embargo}^${contiene_consulta}" >> predictivo_temas.csv  

	done


