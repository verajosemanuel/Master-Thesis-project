# limpieza de memoria
rm(list=ls(all=TRUE))

# usamos pacman para gestionar la instalacion y carga de los paquetes necesarios
if (!require("pacman")) install.packages("pacman")
pacman::p_load(profvis, tm, party, stringi, evtree, caret, e1071, randomForest, class, gbm)

# obtenemos el directorio dado que hay diferencias entre los entornos windows y linux

so <- .Platform$OS.type

if (so == "windows"){
  
  directorio <- file.path("~","CODIGO","R","documentos")
  datafolder <- file.path("~","CODIGO","datos","documentos")
  
} else {
  
  directorio <- file.path("~","scripts","R","documentos")
  datafolder <- file.path("~","scripts","datos","documentos")
  
}

setwd(directorio)


# cargamos los datos del modelo guardados. 
# Si no han sido guardados se generan de nuevo

archivo.datos <- file.path(directorio, "modeldata.rda")

if(file.exists(archivo.datos)) {
  
  load(archivo.datos)
  
} else {
  
  # fuente de los textos
  txt.files <- DirSource(directory = datafolder, encoding ="UTF-8" )
  docs <- VCorpus(x=txt.files)
  
  # transformaciones aplicadas al corpus
  docs <- tm_map(docs, content_transformer(removePunctuation))
  docs <- tm_map(docs, content_transformer(tolower))
  
  docs <- tm_map(docs, removeWords,c("maria","garcia","jose",
                                     "julio","manuel","juan",
                                     "martinez","alvaro","perez"))
  
  docs <- tm_map(docs, removeWords, stopwords("spanish"))
  docs <- tm_map(docs, content_transformer(removeNumbers))
  
  # el proceso elimina la barra que separa géneros en la palabra abogado: se hace corrige
  docs<-tm_map(docs,content_transformer(function(x)stri_replace_all_fixed(x,"abogadoa",
                                                                          "abogado",vectorize_all=FALSE)))
  docs <- tm_map(docs, content_transformer(stripWhitespace))
  
  # creación de la matriz DTM
  dtm <- DocumentTermMatrix(docs)  
  dtm <- removeSparseTerms(dtm, 0.9)
  
  # serializar
  m <- as.matrix(dtm)   
  df <- as.data.frame(m)
  
  # filename como columna
  df <- cbind(FILENAMES = rownames(df), df)
  rownames(df) <- NULL
  
  # obtencion de la etiqueta entre el guion bajo y la extension
  inicio <- regexpr('[_]',dtm.df$FILENAMES)+1
  fin <- regexpr('[.]',dtm.df$FILENAMES)-1
  
  dtm.df$LABEL <- substring(dtm.df$FILENAMES, inicio , fin)
  
  # subsetting de todo menos el nombre de fichero
  res <- df[,-1]
  res <- res[,c(ncol(res),1:(ncol(res)-1))]
  res$LABEL <- as.factor(res$LABEL)
  
  # convertimos a factor la etiqueta
  res$LABEL <- factor(res$LABEL)
  
  # salvamos 
  save(res, file = "modeldata.rda")
  
} 


# PROBANDO MODELOS PREDICTIVOS


  ## Ctree

archivo.ctree <- file.path(directorio,"ctree.rda")

if(file.exists(archivo.ctree)) {
  
  load(archivo.ctree)
  
} else {
  
  arbol.juridico <- ctree(res$LABEL ~ ., data = res)
  
  save(arbol.juridico, file = "ctree.rda")
}

pred.ctree <- predict(arbol.juridico, res, savePredictions = TRUE)



## Evolutionary tree 


archivo.evotree <- file.path(directorio,"evotree.rda")

if(file.exists(archivo.evotree)) {
  load(archivo.evotree)
  
} else {
  
  fit <- evtree(LABEL ~ . , data=res)
  save(fit, file = "evotree.rda")
}

pred.evo <- predict(fit ,type ="response", savePredictions = TRUE)


## Knn 

archivo.knn <- file.path(directorio,"modeloknn.rda")

if(file.exists(archivo.knn)) {
  
  load(archivo.knn)
  
} else {
  
  entreno2 <- trainControl(method = "knn",
                           number = 10, savePredictions = TRUE)
  grid2 <- expand.grid(k = 1:10)
  modeloknn <- train(LABEL ~ ., data = res)
  save(modeloknn, file = "modeloknn.rda")
}


pred.knn <- predict(modeloknn, res, savePredictions = TRUE)


## Jacknife



archivo.jacknife <- file.path(directorio,"jacknife.rda")

if(file.exists(archivo.jacknife)) {
  
  load(archivo.jacknife)
  
}else{
  
  pred.jacknife <- knn.cv(res[,-1], res$LABEL, k = 1) 
  save(pred.jacknife, file = "jacknife.rda")
}


## Random forest 


archivo.rf <- file.path(directorio,"randomforest.rda")

if(file.exists(archivo.rf)) {
  
  load(archivo.rf)
  
} else {
  
  rf <- randomForest(LABEL ~ ., data = res, ntree = 500)
  save(rf, file = "randomforest.rda")
}

pred.rf <- rf$predicted


## Naive-Bayes


archivo.naive <- file.path(directorio,"naivebayes.rda")

if(file.exists(archivo.naive)) {
  
  load(archivo.naive)
  
} else {
  
  model.nb <- naiveBayes(LABEL ~., data = res,res$LABEL)
  save(model.nb, file = "naivebayes.rda")
  
}

pred.nb <- predict(model.nb,res[,-1])


## Support Vector Machine 


archivo.svm <- file.path(directorio,"svm.rda")

if(file.exists(archivo.svm)) {
  
  load(archivo.svm)
  
} else {
  
  mod.svm <- svm(LABEL ~ ., data = res, kernel = "radial")
  save(mod.svm, file = "svm.rda")
}

pred.svm <- mod.svm$fitted



## Gradient Boosting Machine 


archivo.gbm <- file.path(directorio,"gbm.rda")

if(file.exists(archivo.gbm)) {
  
  load(archivo.gbm)
  
} else {
  
  mod.gbm <- gbm(LABEL ~ ., data = res, interaction.depth = 6, n.trees= 10000, cv.folds = 3)
  save(mod.gbm, file = "gbm.rda")
}

perf <- gbm.perf(mod.gbm, method = "cv")
# probabilidad arbitraria de falso mayor de 0.5
table(res$LABEL, predict(mod.gbm, type = "response", n.trees = perf) > 0.5)  

pred.numbers <- predict(mod.gbm, type = "response", n.trees = perf)

# gbm no devuelve el LABEL de las predicciones para multinomial,
# por tanto escogemos la de mayor probabilidad
pred_class <- apply(pred.numbers,1, which.max)

# lo pasamos a dataframe
pred_class_etiquetas <- data.frame(id = 1:length(pred_class),pred_class)

# hacer la sustitucion de numericos por label teniendo en cuenta que van alfabeticamente
pred_class_etiquetas$pred_class[pred_class_etiquetas$pred_class == "1"] <- "APROBACION"
pred_class_etiquetas$pred_class[pred_class_etiquetas$pred_class == "2"] <- "NOTIFICACIONES"
pred_class_etiquetas$pred_class[pred_class_etiquetas$pred_class == "3"] <- "ORDENAMIENTO"
pred_class_etiquetas$pred_class[pred_class_etiquetas$pred_class == "4"] <- "OTROS"

pred.gbm <- pred_class_etiquetas$pred_class

# GENERAMOS UN DATAFRAME NUEVO AÑADIENDO PREDICCIONES

predicciones <- res

predicciones <- cbind(predicciones, pred.ctree)
predicciones <- cbind(predicciones, pred.evo)
predicciones <- cbind(predicciones, pred.knn)
predicciones <- cbind(predicciones, pred.jacknife)
predicciones <- cbind(predicciones, pred.rf)
predicciones <- cbind(predicciones, pred.nb)
predicciones <- cbind(predicciones, pred.svm)
predicciones <- cbind(predicciones, pred.gbm)

# NOS QUEDAMOS SOLO CON LAS PREDICCIONES

predicciones <- predicciones[,c("LABEL","pred.ctree","pred.evo","pred.knn","pred.jacknife",
                                "pred.rf","pred.nb","pred.svm","pred.gbm")]  


# DE ESTE MODO ES MUCHO MÁS SENCILLO GENERAR MATRICES DE CONFUSIÓN

library(caret)

confusion.ctree <- confusionMatrix(predicciones$pred.ctree, predicciones$LABEL)

confusion.evo <- confusionMatrix(predicciones$pred.evo, predicciones$LABEL)
confusion.knn <- confusionMatrix(predicciones$pred.knn, predicciones$LABEL)
confusion.jack <- confusionMatrix(predicciones$pred.jacknife, predicciones$LABEL)
confusion.rf <- confusionMatrix(predicciones$pred.rf, predicciones$LABEL)
confusion.nb <- confusionMatrix(predicciones$pred.nb, predicciones$LABEL)
confusion.svm <- confusionMatrix(predicciones$pred.svm, predicciones$LABEL)
confusion.gbm <- confusionMatrix(predicciones$pred.gbm, predicciones$LABEL)


# Y OBTENEMOS EL MEJOR MODELO MIRANDO EL ACCURACY

confusion.ctree$overall[["Accuracy"]]
   
confusion.evo$overall[["Accuracy"]]
   
confusion.knn$overall[["Accuracy"]]
 
confusion.jack$overll[["Accuracy"]]
    
confusion.rf$overall[["Accuracy"]]
   
confusion.nb$overall[["Accuracy"]]
   
confusion.svm$overall[["Accuracy"]]
     
confusion.gbm$overall[["Accuracy"]]

