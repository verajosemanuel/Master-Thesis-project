#!/bin/bash

#################################################################################################
#							EXTRACCION DE CONTENIDOS DE DOCUMENTOS								#
#################################################################################################
#																								#
# 	Author: 	Jose Manuel Vera Oteo                MAYO, 2016									#
#																								#
# 	Dada una carpeta repleta de documentos sin subdirectorios, extrae todos los textos			#
# 		No importa si el PDF está hecho de imágenes, pues realiza OCR							#
#																								#
# Requisitos:      																				#
#                                                                         						#
#    poppler-utils,tesseract,convert,pandoc,Libre Office CLI,parallel,ImageMagick            	#
#																								#
#################################################################################################

# todos los parametros son obligatorios

FOLDER=$1       # directorio a procesar
OUTPUT=$2		# directorio de salida del proceso (recomendable que sea el mismo que $1)
DOCNAME=$3		# nombre de los ficheros de resumen finales
THREADS=$4		# numero maximo de hilos de ejecución (PELIGRO!!! NO SOBREPASAR EL NUMERO DE NUCLEOS)
STYPE=$5		# Tipo de resumen palabras extraidas (depende del departamento)



# ALMACENAMOS LAS FECHAS Y LAS HORAS DE INICIO PARA REALIZAR CALCULOS DE TIEMPO EN CADA FASE
# SE GENERA UN INFORME AL FINAL, ADEMÁS DE MOSTRAR PROCESOS POR PANTALLA Y POR LOG A DISCO

start=`date`
start_time=`date +%s`
echo "Start date:" `date`
echo "Start date:" `date` >> ${OUTPUT}"/"${DOCNAME}".log"

# __________ SETTINGS Y PREPARACIÓN DEL ENTORNO ________________________


# generamos un fichero de log vacío e insertamos los primeros datos

touch ${OUTPUT}"/"${DOCNAME}".log"

echo "_______________INIT AND ENVIRONMENT SETTING_______________"  >> ${OUTPUT}"/"${DOCNAME}".log"
echo "_______________INIT AND ENVIRONMENT SETTING______________"
echo "Data folder: $FOLDER" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Output folder: $OUTPUT" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Summary file: $OUTPUT/$DOCNAME" >> ${OUTPUT}"/"${DOCNAME}".log"

# para evitar problemas sustituimos todos los espacios vacios de los archivos por guiones bajos

cd $FOLDER

find -name "* *" -type f | rename 's/ /_/g'


# pasamos todas las extensiones a lowercase.

for ext_pdf in *.PDF
do
    mv $ext_pdf $(basename $ext_pdf .PDF)".pdf"
done

for ext_doc in *.DOC
do
    mv $ext_doc $(basename $ext_doc .DOC)".doc"
done

for ext_rtf in *.RTF
do
    mv $ext_rtf $(basename $ext_rtf .RTF)".rtf"
done

for ext_docx in *.DOCX
do
    mv $ext_docx $(basename $ext_docx .DOCX)".docx"
done


# creamos todos los directorios de trabajo comprobando previamente si existen.

# para pdf constituidos de texto

if [ -d ${OUTPUT}"/pdf_txt/" ]; then
	echo "Carpeta TXT existe. No se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
else
	echo "Carpeta TXT no existe. Se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
mkdir ${OUTPUT}"/pdf_txt/"
fi

# para pdf constituidos de imágenes

if [ -d ${OUTPUT}"/pdf_ocr/" ]; then
	echo "Carpeta OCR existe. No se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
else
	echo "Carpeta OCR no existe. Se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
mkdir ${OUTPUT}"/pdf_ocr/"
fi

# para archivos temporales

if [ -d ${OUTPUT}"/tmp/" ]; then
	echo "Carpeta TMP existe. No se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
else
	echo "Carpeta TMP no existe. Se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
mkdir ${OUTPUT}"/tmp/"
fi

# para las imágenes extraidas

if [ -d ${OUTPUT}"/img/" ]; then
	echo "Carpeta IMG existe. No se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
else
	echo "Carpeta IMG no existe. Se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
mkdir ${OUTPUT}"/img/"
fi

# para los textos finales del proceso

if [ -d ${OUTPUT}"/processed/" ]; then
	echo "Carpeta PROCESSED existe. No se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
else
	echo "Carpeta PROCESSED no existe. Se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
mkdir ${OUTPUT}"/processed/"
fi

# para los ficheros rtf

if [ -d ${OUTPUT}"/rtf/" ]; then
	echo "Carpeta RTF existe. No se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
else
	echo "Carpeta RTF no existe. Se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
mkdir ${OUTPUT}"/rtf/"
fi

# para los PDF de más de 20 páginas, que por requerimientos de negocio exigen lectura completa.

if [ -d ${OUTPUT}"/rejected/" ]; then
	echo "Carpeta REJECTED existe. No se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
else
	echo "Carpeta REJECTED no existe. Se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
mkdir ${OUTPUT}"/rejected/"
fi

# para los documentos word

if [ -d ${OUTPUT}"/word/" ]; then
	echo "Carpeta WORD existe. No se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
else
	echo "Carpeta WORD no existe. Se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
mkdir ${OUTPUT}"/word/"
fi

if [ -d ${OUTPUT}"/non_processed/" ]; then
	echo "Carpeta NON PROCESSED exsite. No se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
else
	echo "Carpeta NON PROCESSED no existe. Se crea." >> ${OUTPUT}"/"${DOCNAME}".log"
mkdir ${OUTPUT}"/non_processed/"
fi

echo "----------------------------------------------------------------------------------------"
echo "		            PROCESANDO DIRECTORIO $FOLDER"
echo "------PROCESANDO DIRECTORIO $FOLDER" >> ${OUTPUT}"/"${DOCNAME}".log"

# inicialización de diversos contadores para el informe final y el log

totalfiles=0   	# total de ficheros procesados
detexto=0		# total pdf de texto procesados
txt=0			# textos finales extraidos
deimagen=0		# total pdf de imagen procesados
imgd=0			# total imagenes procesadas
wrd=0			# documentos word doc
rtfd=0			# documentos rtf
wrdx=0			# documentos word docx
twords=0		# total de palabras en documento
tlines=0		# total de lineas en documento
totalwords=0	# total de palabras proceso
totallines=0	# total de lineas proceso
ocr=0			# total de OCR ejecutados
rejected=0		# total ficheros rechazados


# fecha y hora de inicio del proceso de conversión de ficheros
start_conversion=`date`
start_conversion_time=`date +%s`

# fecha y hora de inicio del proceso de conversión de ficheros no-pdf
start_nonpdf=`date`
start_nonpdf_time=`date +%s`

# convirtiendo DOCX, DOC, RTF
# cada fichero una vez extraido su texto, se mueve a su carpeta de almacenamiento

	cd $FOLDER

	for wd in *.doc
		do
		libreoffice --invisible --norestore --convert-to txt:"Text" --headless $wd --outdir ${OUTPUT}"/processed"
		echo ${wd}" -> procesado word doc." >> ${OUTPUT}"/"${DOCNAME}".log"
		mv $wd ${OUTPUT}"/word/"
		let wrd=wrd+1
	done

	for rd in *.rtf
		do
		libreoffice --invisible --norestore --convert-to txt:"Text" --headless $rd --outdir ${OUTPUT}"/processed"
		echo ${rd}" -> procesado rtf." >> ${OUTPUT}"/"${DOCNAME}".log"
		mv $rd ${OUTPUT}"/rtf/"
		let rtfd=rtfd+1
	done

	for wdx in *.docx
		do
		libreoffice --invisible --norestore --convert-to txt:"Text" --headless $wdx --outdir ${OUTPUT}"/processed"
		echo ${rd}" -> procesado rtf." >> ${OUTPUT}"/"${DOCNAME}".log"
		mv $wdx ${OUTPUT}"/word/"
		let wrdx=wrdx+1
	done

end_nonpdf_time=`date +%s`
end_nonpdf=`date`


# Extracción inicial de metadatos para el proceso de clasificación
# Eliminando lineas vacías, códigos de formulario o de página nueva........solo necesitamos el texto plano sin cosas raras!!!
#

# tiempos de inicio del proceso para PDF
start_pdf_time=`date +%s`
start_pdf=`date`

tipo=""  # tipo de fichero (text|ocr)

# creamos un fichero nuevo con la cabeceera del CSV que alojará los metadatos

echo "FILE^TIPO^IMAGES^FONTS^SIZE^TITLE^AUTHOR^CREATOR^PRODUCER^TAGGED^FORM^PAGES^ENCRYPTED^OPTIMIZED^PAGESIZE^VERSION^ROTATION^PAGELINESFIRST^PAGELINESSECOND^PAGELINESLAST^FWORDS1^TWORDS1^LABEL" > ${OUTPUT}"/MachineLearning.csv"

	for pdf_file in *.pdf   # extraemos metadatos y diversa información sobre cada PDF para hacer una tentativa de clasificación
		do
			 FILENAMEsinPDF=$(basename "${pdf_file}" .pdf)  # nombre del fichero sin la extension
			# texto de la primera página
			 firstpage=""$(pdftotext -f 1 -l 1 -enc UTF-8 "$pdf_file" - | tr -cd '[[:alnum:]][áéíóúÁÉÍÓÚñÑªºüÜ°;]\40-\040\045\054\011\012\014\015\057\050\051\100\128\176\056' | sed '/^$/d' | sed 's/[^[:print:]]/ /g')
 		    # numero de páginas
			 pages=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep Pages: | sed 's/Pages:[ ]*//'  | tr '\r\n' ' ')

			   if [ $pages -gt 1 ]; then  # si hay más de una página obtenemos información de la última y de la segunda

					  lastpage=""$(pdftotext -f $pages -l $pages -enc UTF-8 "$pdf_file" - | tr -cd '[[:alnum:]][áéíóúÁÉÍÓÚñÑªºüÜ°;]\40-\040\045\054\011\012\014\015\057\050\051\100\128\176\056' | sed '/^$/d' | sed 's/[^[:print:]]/ /g')
					  lastpagelines=""$(echo "$lastpage" | wc -l)
					  secondpage=""$(pdftotext -f 2 -l 2 -enc UTF-8 "$pdf_file" - | tr -cd '[[:alnum:]][áéíóúÁÉÍÓÚñÑªºüÜ°;]\40-\040\045\054\011\012\014\015\057\050\051\100\128\176\056' | sed '/^$/d' | sed 's/[^[:print:]]/ /g')
					  secondpagelines=""$(echo "$secondpage" | wc -l)

				   else

					  lastpage=""
					  lastpagelines=0
					  secondpage=""
					  secondpagelines=0

			   fi

			firstpagelines=""$(echo "$firstpage" | wc -l) # numero de lineas de la primera página
			fwords=""$(echo "$firstpage" | grep -E de\|la\|que | wc -l)  # conteo de las 3 palabras más frecuentes en castellano en primera pagina
			twords=""$(echo "$firstpage" | wc -w)				# numero total de palabras de la primera página
			#metadatos del PDF
			title=""$(pdfinfo "$pdf_file" |  sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep Title | sed 's/Title:[ ]*//' | tr '\r\n' ' ')
			author=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep Author | sed 's/Author:[ ]*//' | tr '\r\n' ' ')
			creator=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep Creator | sed 's/Creator:[ ]*//' | tr '\r\n' ' ')
			fonts=""$(pdffonts "$pdf_file" | wc -l)
			cfonts=""$(echo $fonts-2 | bc -l)
			producer=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' |  grep Producer | sed 's/Producer:[ ]*//' | tr '\r\n' ' ')
			tagged=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep Tagged | sed 's/Tagged:[ ]*//' | tr '\r\n' ' ')
			form=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep Form | sed 's/Form:[ ]*//' | tr '\r\n' ' ')
			encrypted=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep Encrypted | sed 's/Encrypted:[ ]*//' | tr '\r\n' ' ')
			optimized=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep Optimized | sed 's/Optimized:[ ]*//' | tr '\r\n' ' ')
			pagesize=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep 'Page size:' | sed -e 's/Page size:[ ]*//' | tr '\r\n' ' ')
			pdfversion=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep 'PDF version:' | sed -e's/PDF version:[ ]*//' | tr '\r\n' ' ')
			pdf_size=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep 'File size:' | sed -e's/File size:[ ]*//' | sed -e's/ bytes//' | tr '\r\n' ' ')
			imagesp=""$(pdfimages -list "${pdf_file}" | tr -cd '[[:alnum:]][áéíóúÁÉÍÓÚñÑªºüÜ°;-]\40-\040\045\054\011\012\014\015\057\050\051\100\128\176\056' | wc -l)
		    cimages=""$(echo $imagesp-2 | bc -l)
			pagerotation=""$(pdfinfo "$pdf_file" | sed '/^$/d' | sed 's/[^[:print:]]/ /g' | grep 'Page rot:' | sed -e's/Page rot:[ ]*//' | tr '\r\n' ' ')
			label=""$(echo "$FILENAMEsinPDF" | cut -d'[' -f2 | cut -d']' -f1)

			 # Los diferentes departamentos han renombrado los documentos, asisabemos si son imagenes porque tienen doble i en el nombre
			 # sabemos si son texto porque tienen doble t en el nombre. Esto nos sirve para clasificarlos y usarlos tanto como training y como validación

			 if [[ "$FILENAMEsinPDF" == *"_II_"* ]]
			then
				tipo="ocr"
			elif [[ "$FILENAMEsinPDF" == *"_ii_"* ]]
			then
				tipo="ocr"
			elif [[ "$FILENAMEsinPDF" == *"_i_"* ]]
			then
				tipo="ocr"
			elif [[ "$FILENAMEsinPDF" == *"_TT_"* ]]
			then
				tipo="txt"
			elif [[ "$FILENAMEsinPDF" == *"_tt_"* ]]
			then
				tipo="txt"
			elif [[ "$FILENAMEsinPDF" == *"_t_"* ]]
			then
				tipo="txt"
			else
				tipo="unknown"
			fi

		    let totalfiles=totalfiles+1

			if [ $pages -gt 19 ]; then  # más de 20 páginas es obligatorio lectura supervisada
				mv ${OUTPUT}"/"${pdf_file} ${OUTPUT}"/rejected/"
				echo ${pdf_file} " -> RECHAZADO." >> ${OUTPUT}"/"${DOCNAME}".log"
				echo ${pdf_file} " -> RECHAZADO."
				tipo="rejected"
				let rejected=rejected+1
			else

				if [ $cfonts -le 1 ]; then  # no tiene fuentes, por tanto pasa a OCR

					mv ${OUTPUT}"/"${pdf_file} ${OUTPUT}"/pdf_ocr/"
					tipo="ocr"
					let ocr=ocr+1
					echo ${pdf_file} " -> pdf a ocr." >> ${OUTPUT}"/"${DOCNAME}".log"
					echo ${pdf_file} " -> pdf a ocr."
				else
					if [ $fwords -le 3 ]; then   # si las palabras más frecuentes menos de 3 pasa a OCR

						if [ $pages -le $cimages ]; then  # si más imagnes que páginas pasa a OCR
							mv ${OUTPUT}"/"${pdf_file} ${OUTPUT}"/pdf_ocr/"
							tipo="ocr"
							let ocr=ocr+1
							echo ${pdf_file} " -> pdf a ocr." >> ${OUTPUT}"/"${DOCNAME}".log"
							echo ${pdf_file} " -> pdf a ocr."
						else
							if [ $firstpagelines -gt 20 ]; then  # más de 20 lineas de texto en primera página es PDF de texto

									$(pdftotext -enc UTF-8  "$pdf_file" ${OUTPUT}/processed/${FILENAMEsinPDF}.txt)

									mv ${OUTPUT}"/"${pdf_file} ${OUTPUT}"/pdf_txt/"
									echo ${pdf_file} " -> pdf a texto." >> ${OUTPUT}"/"${DOCNAME}".log"
									echo ${pdf_file} " -> pdf a texto."
									let txt=txt+1
									tipo="txt"
							else
								mv ${OUTPUT}"/"${pdf_file} ${OUTPUT}"/pdf_ocr/"
								tipo="ocr"
								let ocr=ocr+1
								echo ${pdf_file} " -> pdf a ocr." >> ${OUTPUT}"/"${DOCNAME}".log"
								echo ${pdf_file} " -> pdf a ocr."
							fi # fin mas de 20 lineas
						fi # fin mas imagenes que paginas
					else

						$(pdftotext -enc UTF-8  "$pdf_file" ${OUTPUT}/processed/${FILENAMEsinPDF}.txt)

						mv ${OUTPUT}"/"${pdf_file} ${OUTPUT}"/pdf_txt/"
						echo ${pdf_file} " -> pdf a texto." >> ${OUTPUT}"/"${DOCNAME}".log"
						echo ${pdf_file} " -> pdf a texto."
						let txt=txt+1
						tipo="txt"

					fi # fin 3 palabras mas frecuentes
				fi # fin no tiene fuentes
			fi
	#insertamos linea con los metadatos en el fichero CSV

	echo "${pdf_file}^${tipo}^${cimages}^${cfonts}^${pdf_size}^${title}^${author}^${creator}^${producer}^${tagged}^${form}^${pages}^${encrypted}^${optimized}^${pagesize}^${pdfversion}^${pagerotation}^${firstpagelines}^${secondpagelines}^${lastpagelines}^${fwords}^${twords}^${label}" >> ${OUTPUT}"/MachineLearning.csv"

	done

#fin del proceso de clasificación de PDF
end_pdf_time=`date +%s`
end_pdf=`date`

echo "----------------------------------------------------------------------------------------"
echo "		EXTRACCIÓN DE IMAGENES Y PROCESO OCR EN "$FOLDER"/pdf_ocr"
echo "----- EXTRACCIÓN DE IMAGENES Y PROCESO OCR EN "$FOLDER"/pdf_ocr" >> ${OUTPUT}"/"${DOCNAME}".log"

# -------------------------
#  Extraer imagenes de pdf
#--------------------------

iniciojpg=`date +%s`  # para tabla final de tiempos

cd $FOLDER"/pdf_ocr"

# con GNU Parallel aceleramos la extracción de IMG. ¡¡¡¡NO SUPERAR EL NUMERO DE NUCLEOS DEL SERVIDOR CON EL PARAMETRO THREADS!!!!  Se genera una imagen por página con el nombre del PDF "padre" y una secuencia
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=
find . -name '*.pdf' | parallel -j ${THREADS} --progress convert -density 600 -trim {} -quality 100 -set filename:f '%t'  '../tmp/$(basename '{}' .pdf)'__%03d.jpg |& tee ${OUTPUT}"/parallel_convert.log"
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=

finjpg=`date +%s`


# Nos movemos a la carpeta temporal para hacer OCR sobre todas las imágenes extraídas
cd $FOLDER"/tmp"

# fecha y hora del inicio del proceso de ocr
start_imgocr_time=`date +%s`
start_imgocr=`date`

# con GNU Parallel aceleramos el proceso de OCR  ¡¡¡¡NUNCA SUPERAR EL NUMERO DE NUCLEOS DEL SERVIDOR CON EL PARAMETRO THREADS!!!!
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
find . -name '*.jpg' | parallel -j ${THREADS} --progress tesseract {} -l spa '$(basename '{}' .jpg)' |& tee ${OUTPUT}"/parallel_tesseract.log"
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

end_imgocr=`date`
end_imgocr_time=`date +%s`


# ---------------------------------------------------------------------
#  concatenar el contenido de los textos "hijos" del mismo pdf "padre"
#----------------------------------------------------------------------

start_stacking=`date`
start_stacking_time=`date +%s`

cd $FOLDER"/pdf_ocr"

         for pdffile in *.pdf
         do
            nombrebase=""$(basename $pdffile .pdf)"*.txt"
                echo "concatenando "$nombrebase

                for tt in "../tmp/"$(echo $nombrebase | sed -e 's/]/?/g') # la comparación de ficheros falla si el nombre tiene corchetes. Lo cambiamos por la interrogación
                do

                FINALTXTNAME=$(echo ${nombrebase} | sed -e 's/\*//g')  # texto final con el mismo nombre que el PDF "padre" eliminando todo tipo de caracteres extraños
				cat $tt | tr -cd '[[:alnum:]][áéíóúÁÉÍÓÚñÑªºüÜ°;-]\11\12\15\40-\040\045\054\011\012\015\057\050\051\100\128\176\056' | sed '/^$/d' | sed 's/\o14//g' | sed 's/[^[:print:]]/ /g' >> ${OUTPUT}"/processed/"${FINALTXTNAME}
                rm -f $tt  # borrando todos los ficheros procesados de dicho "padre"

                done
         done

# moviendo todos los JPG al directorio de almacenamiento
 mv $FOLDER/tmp/*.jpg  $FOLDER/img/
# contamos el total para el resumen
 img=""$(ls $FOLDER/img/  | wc -l)


# GRAN PARTE DE LOS CONTADORES DE TIEMPO ACABAN AQUI
end_stacking=`date`
end_stacking_time=`date +%s`

end_conversion=`date`
end_conversion_time=`date +%s`

# ----------------------------------------------------------------------------
#  	GENERACIÓN DE UN DOCUMENTO RESUMEN: parámetro STYPE (obligatorio)
# algunos departamentos piden un CSV con el conteo de unas palabras concretas
# este csv les permite acelerar la identificación de los documentos.
# Dado que las palabras difieren según el departamento, se colocan fuera.
# solamente hay que ir incluyendo los archivos externos necesarios por depto.
# a modo de ejemplo se incluye un fichero externo llamado resumen.sh
# ----------------------------------------------------------------------------
# warning: solo puede existir un documento resumen activo

start_summary=`date`
start_summary_time=`date +%s`

echo "-----------------------------RESUMEN-----------------------------" >> ${OUTPUT}"/"${DOCNAME}".log"

cd ~/scripts

if [ $STYPE == "financiero" ];then
source resumen.sh
else
source resumen.sh
fi

echo "-----------------------------FIN RESUMEN-----------------------------"

end_summary_time=`date +%s`
end_summary=`date`


echo "-----------------------------CONTADORES-----------------------------" >> ${OUTPUT}"/"${DOCNAME}".log"

	# escribir contadores al log y mostrar por pantalla
	totalfinal=$(echo "$totalfiles + $wrd + $rtfd + $wrdx" | bc -l)
	echo ${txt}" text pdfs." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ${imgd}" imagen pdfs." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ${img}" imagenes extraidas para OCR." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ${totalfiles}" procesados." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ${ocr}" img a OCR." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ""$(echo "scale=2;$wrd - 1" | bc -l)" processed Word Doc." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ""$(echo "scale=2;$rtfd - 1" | bc -l)" processed rtf." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ""$(echo "scale=2;$wrdx - 1" | bc -l)" processed Word DocX." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ${rejected}" rechazados." >> ${OUTPUT}"/"${DOCNAME}".log"
	echo ${totalfinal}" Total documentos." >> ${OUTPUT}"/"${DOCNAME}".log"

	echo ${txt}" text pdfs."
	echo ${imgd}" imagen pdfs."
	echo ${totalfiles}" procesados."
	echo ${ocr}" img a OCR."
	echo ${wrd}" Word Doc."
	echo ${rtfd}" rtf."
	echo ${wrdx}" Word DocX."
	echo ${rejected}" rechazados."
	echo ${totalfinal}" Total documentos."

# --------------------------------------------------------------------------------------------
# ---------------------------------- TABLA DE TIEMPOS ----------------------------------------
# --------------------------------------------------------------------------------------------

end_time=`date +%s`

echo "------------------------------- tabla de tiempos --------------------------------------"
echo "------------------------------- tabla de tiempos --------------------------------------" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Inicio:" $start
echo "Fin:" `date`
echo "Inicio:" $start >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Fin:" `date` >> ${OUTPUT}"/"${DOCNAME}".log"
echo "-------" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Inicio no PDF: $start_nonpdf"
echo "Fin no PDF: $end_nonpdf"
echo "Inicio no PDF: $start_nonpdf" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Fin no PDF: $end_nonpdf" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Tiempo de no PDF" $(echo "scale=2;$end_nonpdf_time - $start_nonpdf_time" | bc -l) seconds.
echo "Tiempo de no PDF" $(echo "scale=2;$end_nonpdf_time - $start_nonpdf_time" | bc -l) seconds. >> ${OUTPUT}"/"${DOCNAME}".log"
echo "-------" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Inicio PDF: $start_pdf"
echo "Fin PDF: $end_pdf"
echo "Inicio PDF: $start_pdf" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Fin PDF: $end_pdf" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Tiempo de pdf" $(echo "scale=2;($end_pdf_time - $start_pdf_time)/60" | bc -l) m.
echo "Tiempo de pdf" $(echo "scale=2;($end_pdf_time - $start_pdf_time)/60" | bc -l) m. >> ${OUTPUT}"/"${DOCNAME}".log"
echo "-------" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Inicio IMG y OCR: $start_imgocr"
echo "Fin IMG y OCR: $end_imgocr"
echo "Inicio IMG y OCR: $start_imgocr" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Fin IMG y OCR: $end_imgocr" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "IMG y OCR total" $(echo "scale=2;($end_imgocr_time - $start_imgocr_time)/60" | bc -l) m.
echo "IMG y OCR total" $(echo "scale=2;($end_imgocr_time - $start_imgocr_time)/60" | bc -l) m. >> ${OUTPUT}"/"${DOCNAME}".log"
echo "-------" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Inicio Concatenado: $start_stacking" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Fin concatenado: $end_stacking" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Inicio Concatenado: $start_stacking"
echo "Fin Concatenado: $end_stacking"
echo "Total concatenado: "$(echo "scale=2;($end_stacking_time - $start_stacking_time)/60" | bc -l) m.
echo "Total concatenado: "$(echo "scale=2;($end_stacking_time - $start_stacking_time)/60" | bc -l) m. >> ${OUTPUT}"/"${DOCNAME}".log"
echo "-------" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Inicio conversion y extracción: $start_conversion"
echo "Fin conversion y extracción: $end_conversion"
echo "Inicio conversion y extracción: $start_conversion" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Fin conversion y extracción: $end_conversion" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Total conversion y extracción " $(echo "scale=2;($end_conversion_time - $start_conversion_time)/60" | bc -l) m.
echo "Total conversion y extracción " $(echo "scale=2;($end_conversion_time - $start_conversion_time)/60" | bc -l) m. >> ${OUTPUT}"/"${DOCNAME}".log"
echo "-------" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Inicio summary: $start_summary"
echo "Fin summary: $end_summary"
echo "Inicio summary: $start_summary" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Fin summary: $end_summary" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Summary " $(echo "scale=2;$end_summary_time - $start_summary_time" | bc -l) seconds.
echo "Summary " $(echo "scale=2;$end_summary_time - $start_summary_time" | bc -l) seconds. >> ${OUTPUT}"/"${DOCNAME}".log"
echo "-----------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------" >> ${OUTPUT}"/"${DOCNAME}".log"
echo "Total ejecución de programa " $(echo "scale=2;($end_time - $start_time)/60" | bc -l) m.
echo "Total ejecución de programa " $(echo "scale=2;($end_time - $start_time)/60" | bc -l) m. >> ${OUTPUT}"/"${DOCNAME}".log"
echo "======================================FIN====================================="
echo "===================================== FIN ======================================" >> ${OUTPUT}"/"${DOCNAME}".log"

# FIN DEL SCRIPT
