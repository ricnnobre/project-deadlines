setwd("C:/R_out/IndicadorOS")

library("rjson")
library("RJSONIO")
library("xlsx")
library("devtools")
library("plyr")
library("scales")
library("ggplot2")
library("lubridate")
library("dplyr")
library("stringr")
library("emojifont")
library("Cairo")
library("lubridate")
library("readr")

result <-  RJSONIO::fromJSON("response-data-export.json",encoding="UTF-8")

matchData.i <- lapply(result$issues, function(x){ unlist(x)})

matchData <- rbind.fill(lapply(matchData.i, 
                               function(x) do.call("data.frame", as.list(x))
))

nrow(matchData)
ncol(matchData)

matrixA <- matrix(nrow=nrow(matchData),ncol=10)
dim(matrixA)
colnames(matrixA) <- c("Nome da OS","Natureza da OS","Categoria de Serviço","Inicio Previsto","Conclusao Prevista","Conclusao Real","Prazo Maximo","Prazo Realizado","Indicador de Prazo","Penalidade")
matrixA

for(i in 1:nrow(matchData)) {
  matrixA[i,"Nome da OS"] <- as.character(matchData$fields.summary[i])
  matrixA[i,"Natureza da OS"] <- as.character(matchData$fields.customfield_32941.value[i])
  matrixA[i,"Categoria de Serviço"] <- as.character(matchData$fields.customfield_20952[i])
  matrixA[i,"Inicio Previsto"] <- as.character(matchData$fields.customfield_10160[i])
  matrixA[i,"Conclusao Prevista"] <- as.character(matchData$fields.customfield_10156[i])
  matrixA[i,"Conclusao Real"] <- as.character(matchData$fields.customfield_14440[i])
  if ( !(is.na(matrixA[i,"Inicio Previsto"]) | is.na(matrixA[i,"Conclusao Prevista"])) & (matrixA[i,"Natureza da OS"]=="Manutenção" | matrixA[i,"Categoria de Serviço"]=="Diagnóstico" ))
  {
    matrixA[i,"Prazo Maximo"] <- as.Date(matrixA[i,"Conclusao Prevista"])-as.Date(matrixA[i,"Inicio Previsto"])
    if ( !(is.na(matrixA[i,"Conclusao Real"])))
    {
      matrixA[i,"Prazo Realizado"] <- as.Date(matrixA[i,"Conclusao Real"])-as.Date(matrixA[i,"Inicio Previsto"])
      matrixA[i,"Indicador de Prazo"] <- paste((100*round(as.numeric(matrixA[i,"Prazo Maximo"]) / as.numeric(matrixA[i,"Prazo Realizado"]),digits=4)),"%",sep="")
      if (as.numeric(sub("%", "",matrixA[i,"Indicador de Prazo"] ,fixed=TRUE)) > 95)
        matrixA[i,"Penalidade"] <- "Nenhuma"
      else if (as.numeric(sub("%", "",matrixA[i,"Indicador de Prazo"] ,fixed=TRUE)) > 90 &
               as.numeric(sub("%", "",matrixA[i,"Indicador de Prazo"] ,fixed=TRUE)) <= 95 )
        matrixA[i,"Penalidade"] <- "Advertencia"
      else
        matrixA[i,"Penalidade"] <- "Glosa de 5%"      
    }
     
  }
}


df <- data.frame(matrixA,stringsAsFactors=FALSE)
str(df)
df <- type_convert(df)
str(df)
summary(df)


df$Mes <- format(df$Conclusao.Real, "%Y/%b")
currentMonth = paste(str_to_title(month(today()-30,label = TRUE, abbr = FALSE)),year(today()))


currentDate <-Sys.Date()
endMonth <- currentDate - days(day(currentDate))

startMonth <- currentDate - days(day(currentDate))
startMonth <- startMonth - days(day(startMonth) - 1)

indicadorSumarizadoMes <- df %>% 
  filter(between(Conclusao.Real,startMonth,endMonth) & (Natureza.da.OS=="Manutenção" | Categoria.de.Serviço=="Diagnóstico"))
  
indicadorSumarizadoFuturo <- df %>% 
  filter((is.na(Conclusao.Real) | Conclusao.Real>endMonth) & (Natureza.da.OS=="Manutenção" | Categoria.de.Serviço=="Diagnóstico"))

indicadorSumarizadoPassado <- df %>% 
  filter(Conclusao.Real< startMonth & (Natureza.da.OS=="Manutenção" | Categoria.de.Serviço=="Diagnóstico"))

foraSelecaoIndicador <- df %>% 
  filter(Natureza.da.OS!="Manutenção" & Categoria.de.Serviço!="Diagnóstico")


sheetIAT = paste("indicador_prazo",currentMonth,".xls")
if (nrow(indicadorSumarizadoMes)!=0)
{
  write.xlsx(data.frame(indicadorSumarizadoMes), sheetIAT, sheetName = currentMonth, row.names = FALSE) 
}  else
{
  indicadorSumarizadoMes[nrow(indicadorSumarizadoMes)+1,] <- c(rep(NA,11))
  write.xlsx(indicadorSumarizadoMes, sheetIAT, sheetName = currentMonth , row.names=FALSE)
  
}
  
if (nrow(indicadorSumarizadoFuturo)!=0)
{
  write.xlsx(data.frame(indicadorSumarizadoFuturo), sheetIAT, sheetName = "Indicador a Calcular", append=TRUE, row.names=FALSE) 
} else
{
  indicadorSumarizadoFuturo[nrow(indicadorSumarizadoFuturo)+1,] <- c(rep(NA,11))
  write.xlsx(indicadorSumarizadoFuturo, sheetIAT, sheetName = "Indicador a Calcular", append=TRUE, row.names=FALSE)
  
}
if (nrow(indicadorSumarizadoPassado)!=0) 
{
  write.xlsx(data.frame(indicadorSumarizadoPassado), sheetIAT, sheetName = "Indicador Passado", append=TRUE, row.names=FALSE) 
}  else 
  {
    indicadorSumarizadoPassado[nrow(indicadorSumarizadoPassado)+1,] <- c(rep(NA,11))
    write.xlsx(indicadorSumarizadoPassado, sheetIAT, sheetName = "Indicador Passado", append=TRUE, row.names=FALSE)
  }

if (nrow(foraSelecaoIndicador)!=0) 
{
  write.xlsx(data.frame(foraSelecaoIndicador), sheetIAT, sheetName = "Indicador não Calculado", append=TRUE, row.names=FALSE) 
}  else 
{
  foraSelecaoIndicador[nrow(foraSelecaoIndicador)+1,] <- c(rep(NA,11))
  write.xlsx(foraSelecaoIndicador, sheetIAT, sheetName = "Indicador não Calculado", append=TRUE, row.names=FALSE)
}

df$Indicador.de.Prazo = as.numeric(sub("%", "",df$Indicador.de.Prazo ,fixed=TRUE))/100


df$Indicador.de.Prazo[df$Indicador.de.Prazo>1] <- 1
    
indicadorMensal <- df  %>% 
    group_by(OS=Nome.da.OS, month_Year=Mes,month=month(df$Conclusao.Real),year=year(df$Conclusao.Real)) %>% 
    dplyr::summarise(qtd = sum(Indicador.de.Prazo),n=n() ) %>% 
    filter(!is.na(qtd) & month == month(endMonth) & year == year(endMonth))

indicadorSumarizado <- df  %>% 
  group_by(OS=Nome.da.OS, Inicio.Previsto=Inicio.Previsto, Conclusao.Prevista=Conclusao.Prevista, Prazo.Maximo=Prazo.Maximo, Prazo.Realizado=Prazo.Realizado, Conclusao.Real=Conclusao.Real,month_Year=format(df$Conclusao.Real, "%Y/%m"),penalidade=df$Penalidade) %>% 
  dplyr:: summarise(Indicador.de.Prazo = as.numeric(Indicador.de.Prazo),n = n() ) %>% 
  filter(!is.na(Indicador.de.Prazo))
indicadorSumarizado

penalidadeSumarizada <- df  %>% 
  group_by(month_Year=format(df$Conclusao.Real, "%Y/%m"),Penalidade) %>% 
  dplyr::summarise(n = n() )   %>% 
  filter(!is.na(Penalidade))
penalidadeSumarizada


cores <- c("Nenhuma"="seagreen3","Advertencia"="yellow2","Glosa de 5%"="red4")

a <- #ggplot(data=indicadorSumarizado,aes(x=month_Year,y=Indicador.de.Prazo,label=Indicador.de.Prazo*100)) + geom_col(aes(fill=penalidade), position = position_dodge2(width = 1, preserve = "single")) + geom_text(position = position_dodge2(width = 1, preserve = "single"),vjust=-0.5,size=3) +
  ggplot(data=indicadorSumarizado,aes(x=month_Year,y=Indicador.de.Prazo)) + geom_col(aes(fill=penalidade), position = position_dodge2(width = 1, preserve = "single")) + 
  xlab("Ano/Mês") +
  ggtitle("Indicador de Atendimento Tempestivo de Ordem de Serviço (IAT)",subtitle="Sumarizado Mensal por Tipo de Penalidade") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(face="bold",hjust = 0.5),axis.title = element_text(face = "bold"), legend.title = element_text(colour="black", size=11,face="bold"),plot.caption = element_text(face = "italic", size=7,hjust=1)) +
  labs(caption ="IAT > 95%: OK\n90% < IAT <=95%: Advertência\nIAT <= 90%: Penalidade de 5%") +
  scale_fill_discrete(name = "Penalidade") +
  scale_y_continuous("IAT", labels = percent_format()) +
  scale_fill_manual(values = cores)
  
b <- ggplot(data=indicadorMensal,aes(x=month_Year,y=qtd,label=qtd*100)) + geom_col(aes(fill = OS),width = 0.3,position = position_dodge2(width = 0.3, preserve = "total")) + geom_text(position = position_dodge2(width = 1, preserve = "total"),vjust=-0.5,size=3) +
  xlab("Ano/Mês") +
  ggtitle("Indicador de Atendimento Tempestivo de Ordem de Serviço (IAT)",subtitle=paste(str_to_title(month(today()-30,label = TRUE, abbr = FALSE)),year(today()))) +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(face="bold",hjust = 0.5),axis.title = element_text(face = "bold"), legend.title = element_text(colour="black", size=11,face="bold"),plot.caption = element_text(face = "italic", size=7,hjust=1)) +
  labs(caption ="IAT > 95%: OK\n90% < IAT <=95%: Advertência\nIAT <= 90%: Penalidade de 5%") +
  scale_fill_discrete(name = "OS") +
  scale_y_continuous("IAT",labels=percent_format())

c <- ggplot(data=penalidadeSumarizada,aes(x=month_Year,y=n,label=n)) + geom_col(aes(fill = Penalidade),position = position_dodge2(width = 0.9, preserve = "single")) + geom_text(position = position_dodge2(width=0.9, preserve = "single"),vjust=0.05,size=3) +
  xlab("Ano/Mês") +
  ylab("Total de OSs") +
  ggtitle("Indicador de Atendimento Tempestivo de Ordem de Serviço (IAT)",subtitle="Total de Penalidades Mensais") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(face="bold",hjust = 0.5),axis.title = element_text(face = "bold"), legend.title = element_text(colour="black", size=11,face="bold")) +
  scale_fill_discrete(name = "Penalidade") +
  scale_fill_manual(values = cores)


fileIATMensal = paste("IAT-Mes",currentMonth)

ggsave(filename="IAT-Sumarizado-Mensal.png", plot=a)

ggsave(filename=paste(fileIATMensal,".png"), plot=b)

ggsave(filename="IAT-Quantitativo-Penalidade-Mensal.png", plot=c)

ggsave(filename="IAT-Sumarizado-Mensal.pdf", plot=a, device=cairo_pdf, width = 12, height = 4, units = "in", dpi = 600)
ggsave(filename=paste(fileIATMensal,".pdf"), plot=b, device=cairo_pdf, width = 12, height = 4, units = "in", dpi = 600)
ggsave(filename="IAT-Quantitativo-Penalidade-Mensal.pdf", plot=c, device=cairo_pdf, width = 8, height = 4, units = "in", dpi = 600)
