
#/bin/bash

if [ -d "cleaned" ]; then
        echo "Output TXT folder exists. Doing nothing."
 else
        echo "Output TXT folder not found. Creating folder"
         mkdir "cleaned"
fi


for f in *.txt
 do
lineas=""$(cat "$f" | wc -l)

if [ "$lineas" -gt 5 ]; then

        # dejamos solamente letras, numeros,  espacios y separador de nueva linea como base para el corpus
        limpio=""$(cat $f | tr -cd '[[:alnum:]][áéíóúÁÉÍÓÚñÑªºüÜ°;-]\040\012' | sed '/^$/d' | sed 's/[^[:print:]]/ /g')
		
        # cálculo de la pérdida por OCR-
        en_documento=$(echo "$limpio" | wc -w)     # total de palabras
		
        no_en_dicc=$(echo "$limpio" | aspell list | sort -u -f | wc -l) # aspell inverso
        perdida=$(echo "($no_en_dicc / $en_documento)*100" | bc -l) # ratio
		
        # nos quedamos solamente con documentos que tengan como máximo un 10% de pérdida
        if (( $(echo "$perdida < 11"|bc -l) )) ;then
                echo "$limpio" > cleaned/$f
        fi
else

echo " no tiene lineas suficientes"

fi

done
