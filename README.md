# Master-Thesis-project

Thesis project for the end of Master course in Data Science attended during 2015-16.

## Main goal:

Design and deploy an automatic or semi-supervised platform for document classification (mainly pdf)

## File list:

1. Memoria.Rmd

	Rmarkdown file for deploying ioslides presentation with embedded code. This file and the generated html result describes the thesis project, found issues and solutions implemented using different tools and languages.

2. Memoria.html

	html ioslides presentation returned by the execution of the Rmd file. *THIS MUST BE THE FIRST FILE TO BE OPENED*.

3. preliminar.ipynb / preliminar.html

	iPython Notebook describing procedure and results of preliminary data analysis. 
	
4. extraccion.sh
	
	Linux Bash script regarding the core functionality (file managing and parsing).

4. resumen.sh

	bash script to be included for adding some specific text extraction exemplifying how to get data summary from every document (as term matrix) fullfilling specific department needs.

5. some data files
	
	- pdf_metadata.csv (table containing the extracted metadata via extraccion.sh from every pdf document)
	- files.csv (preliminary file type count)
	- procesado.csv (data source for iPython notebook)
	

	The documents used for this project are protected under confidentiality agreements so, they are not included in this repository.

