# Master Thesis Project

Thesis project for the end of Master's degree in Data Science attended during 2015-16.

## Project goal:

Design and deploy an automatic or semi-supervised platform for document classification (mainly pdf) including text extraction.

## Running / Installing

Running this code requires a Linux machine for bash scripts, and iPython Notebook & Rstudio for the rest of the files.

For getting the scope of this work and the methods implemented there's no need of executing code. Just download/clone the repository and read the presentation files:

	1. memoria2.pdf (read this first)
	2. preliminar.html
	3. memoria.html (ioslides version of memoria2.pdf)
	
## File list:

1. memoria2.Rmd  (code folder). Main document.

	Rmarkdown file for deploying pdf presentation with embedded code. This file and the pdf result describes the thesis project, issues and solutions implemented using different tools and languages.
	
2. memoria.Rmd  (code folder)

	Rmarkdown file for deploying ioslides presentation with embedded code (same as the previous file). This one and the ioslide result describes the thesis project, issues and solutions implemented using different tools and languages.

3. memoria2.pdf  (reports folder)

	pdf document returned by the execution of the Rmd file. **THIS MUST BE THE FIRST FILE TO BE OPENED**. Optionally you would prefer to read the ioslides (memoria.html)

4. preliminar.ipynb / preliminar.html  (code / reports folders)

	iPython Notebook describing preliminary data analysis procedure and results. 
	
5. extraccion.sh (code folder)
	
	Linux Bash script regarding the core functionality (file managing and parsing).

6. resumen_juridico.sh  / clasificador.sh /  cleaner.sh /  (code folder)

	bash script to be included for adding some specific text extraction & functionality exemplifying how to get data summary from every document (as term matrix)  & fullfilling specific user needs. Read memoria2.pdf for details.

7. some data files   (data folder)
	
	- pdf_metadata.csv (table containing the extracted metadata via extraccion.sh from every pdf document)
	- files.csv (preliminary file type count)
	- procesado.xls (data source for iPython notebook)
	- accuracy.csv  (text extraction accuracy)
	- df_dtm.csv  (term document matrix)
	- summary.log (text processing log example)
	- .....
	

**The source documents used for this project are protected under confidentiality agreements so, they are not included in this repository.**

## author

Jose Manuel Vera.

Master in Data Science. 

twitter: @verajosemanuel

Linkedin profile: https://es.linkedin.com/in/jose-manuel-vera-813759b

