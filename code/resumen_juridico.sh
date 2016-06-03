#!/bin/bash


# =======================================================================================================
#    Se cuentan palabras sencillas, palabras en conjuntos y se extrae texto complejo a CSV
# =======================================================================================================

# iniciamos los ficheros vacíos que van a dar lugar a los documentos entregables

echo "DOCUMENTO;PALABRA 1;ALABRA 2;PALABRA 3;PALABRA 4" > "$OUTPUT"/grupos_palabras_"$DOCNAME".csv  # conteo de palabras
echo "DOCUMENTO;TEXTO 1;TEXTO 2;TEXTO 3" > "$OUTPUT"/textos_"$DOCNAME".csv							# extraccion de texto
echo "DOCUMENTO;PERDIDA;PALABRAS" > ${OUTPUT}"/accuracy.csv" 										# csv de pérdida en OCR
echo "<html><head><meta charset="UTF-8"></head><body>" > "$OUTPUT"/summary_"$DOCNAME".html			# informe HTML para procesar con PanDoc
echo "<h2><font color="blue">JURIDICO ${DOCNAME}</font></h2>" >> "$OUTPUT"/summary_"$DOCNAME".html
echo "------ FICHEROS VACIOS ------" > ${OUTPUT}"/error.log"
 
 # buscamos ficheros que no hayan sido procesados
 # se guardan en una carpeta para analisis posterior

cd $FOLDER"/processed"

for f in *.txt
do
en_documento=""$(cat "$f" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | wc -w)

if [ "$en_documento" == 0 ];then
nombrepdf=$(basename $f .txt)".pdf"
nombresinext=$(basename $f .txt)
mv $f ../non_processed/

		if [ -f ${OUTPUT}"/pdf_ocr/"${nombrepdf} ]; then
		mv "$OUTPUT/pdf_ocr/"${nombrepdf}  ../non_processed/
		fi
		
		if [ -f ${OUTPUT}"/pdf_txt/"${nombrepdf} ]; then
		mv "$OUTPUT/pdf_txt/"${nombrepdf}  ../non_processed/
		fi
		
		for i in "${OUTPUT}/img/${nombresinext}*.jpg"
		do
		mv ${i} ../non_processed/
		done
		
		echo $f >> ${OUTPUT}"/error.log"
fi
done

 

cd $FOLDER"/processed"

 for f in *.txt
 do
 	
	#  limpiamos el contenido de caracteres extraños
	CONTENIDOF=""$(cat $f | tr -cd '[[:alnum:]][áéíóúÁÉÍÓÚñÑªºüÜ°;-]\40-\040\045\054\011\012\015\057\050\051\100\128\176\056' | sed '/^$/d' | sed 's/[^[:print:]]/ /g')
	# nombre del fichero sin la extensión
	SIMPLE=""$(basename $f .txt) 
	
	 
	# conteo de palabras seleccionadas por cada departamento -------------------------------------------------------------------------------------
	PALABRA1=""$(echo "$CONTENIDOF" | grep -E -i -o -c 'lorem|ipsum||dolor|sit|amet')
	PALABRA2=""$(echo "$CONTENIDOF" | grep -E -i -o -c  'consectetur|adipiscing|elit|sed|do|eiusmod')
	PALABRA3=""$(echo "$CONTENIDOF" | grep -E -i -o -c 'tempor|incididunt|ut|labore|et|dolore|magna|aliqua')
	PALABRA4=""$(echo "$CONTENIDOF" | grep -E -i -o -c 'Ut|enim|ad|minim|veniam|quis|nostrud|exercitation|ullamco|laboris|nisi|aliquip')
	
	echo "--- Contando palabras agrupadas en $f"
	echo "--- Contando palabras agrupadas en $f" >> ${OUTPUT}"/"${DOCNAME}".log"
	 
	SALIDAGRUPOS="${SIMPLE};${PALABRA1};${PALABRA2};${PALABRA3};${PALABRA4}"
	echo $SALIDAGRUPOS >> "$OUTPUT"/grupos_palabras_"$DOCNAME".csv
	
	
	# cálculo de la pérdida por OCR --------------------------------------------------------------------------------------------------------------
	en_documento=$(echo "$CONTENIDOF" | wc -w)     # total de palabras
	no_en_dicc=$(echo "$CONTENIDOF" | aspell list | sort -u -f | wc -l) # aspell inverso
	perdida=$(echo "scale=2;$no_en_dicc / $en_documento" | bc -l) # ratio
	
	
	echo ${SIMPLE}" pierde "${perdida}" % en ocr." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ${SIMPLE}" pierde "${perdida}" % en ocr."
		
	SALIDANUMEROS="${SIMPLE};${perdida};${en_documento}"
	echo $SALIDANUMEROS >> $OUTPUT"/accuracy.csv"
	
	
	# extracción de texto complejo elegido por cada departamento ---------------------------------------------------------------------------------
	echo " Procesando texto de $SIMPLE"
	echo $SIMPLE";"$TEXTO1";"$TEXTO2";"$TEXTO3 >> "$OUTPUT"/textos_"$DOCNAME".csv
	
	TEXTO1=""$(echo "$CONTENIDOF" | grep -E '[[:print:]]' | grep -Ei ' EN REPRESENTACIÓN DE ' | cut -c -100)  # solamente 100 caracteres
	TEXTO2=""$(echo "$CONTENIDOF" | grep -Ei  '[[:space:]]{0,1}[0123][0-9][[:space:]]{0,1}\/[01][0-9]\/([12][09][0-9][0-9]|[0-9]{2})[[:space:]]')   # capturamos fechas
	TEXTO3=""$(echo "$CONTENIDOF" | grep -E '[[:print:]]' | grep -A 3 JURIDICO ) # 3 LINEAS TRAS LA PALABRA CLAVE
	
	
	# desde HTML es muy sencillo realizar conversiones entre tipos de documento con PANDOC ------------------------------------------------------
	echo $SIMPLE" a resumen HTML"  
	echo $SIMPLE" a resumen HTML" >> ${OUTPUT}"/"${DOCNAME}".log"
	
	echo "<h2><font color=blue>$DOCUMENTOLEGAL</font></h2></hr>" >> "$OUTPUT"/summary_"$DOCNAME".html
    echo "<h3>TEXTO1</h3></br>"  >> "$OUTPUT"/summary_"$DOCNAME".html
	echo $TEXTO1 "<br>" >> "$OUTPUT"/summary_"$DOCNAME".html
	echo  "<h3>TEXTO2</h3>" >> "$OUTPUT"/summary_"$DOCNAME".html
	echo $TEXTO2 "<br>" >> "$OUTPUT"/summary_"$DOCNAME".html
	echo  "<h3>TEXTO3</h3>" >> "$OUTPUT"/summary_"$DOCNAME".html
	echo $TEXTO3 "<br>" >> "$OUTPUT"/summary_"$DOCNAME".html
	
	
 done



# Cerramos el HTML --------------------------------------------------------------------------------------------------------------------------------
echo "</body></html>" >> "$OUTPUT"/summary_"$DOCNAME".html

echo "----------------- Disponible reseumen en $OUTPUT"/summary_"$DOCNAME.html"



# AHORA CONVERTIMOS EL INFORME DESDE HTML AL FORMATO QUE DESEAMOS CON PANDOC  ---------------------------------------------------------------------


echo "---------MICROSOFT WORD "

pandoc -f html -t docx "$OUTPUT"/summary_"$DOCNAME".html -s -o "$OUTPUT"/summary_"$DOCNAME".docx

echo "------------------ Disponible en $OUTPUT"/summary_"$DOCNAME".docx


echo "---------- RTF "

pandoc -f html -t rtf "$OUTPUT"/summary_"$DOCNAME".html -s -o "$OUTPUT"/summary_"$DOCNAME".rtf

echo "------------------ Disponible en $OUTPUT"/summary_"$DOCNAME".rtf


# FIN DE SCRIPT

