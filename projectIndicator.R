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

result <-  RJSONIO::fromJSON("input/response-data-export.json",encoding="UTF-8")

matchData.i <- lapply(result$issues, function(x){ unlist(x)})

matchData <- rbind.fill(lapply(matchData.i, 
                               function(x) do.call("data.frame", as.list(x))
))

nrow(matchData)
ncol(matchData)

matrixA <- matrix(nrow=nrow(matchData),ncol=10)
dim(matrixA)
colnames(matrixA) <- c("Project","Project Type","Service Type","Expected Start Date","Expected End Date","Real End Date","Max Deadline","Total Project Days","Deadline Indicator","Penalty")
matrixA

for(i in 1:nrow(matchData)) {
  matrixA[i,"Project"] <- as.character(matchData$fields.summary[i])
  matrixA[i,"Project Type"] <- as.character(matchData$fields.customfield_32941.value[i])
  matrixA[i,"Service Type"] <- as.character(matchData$fields.customfield_20952[i])
  matrixA[i,"Expected Start Date"] <- as.character(matchData$fields.customfield_10160[i])
  matrixA[i,"Expected End Date"] <- as.character(matchData$fields.customfield_10156[i])
  matrixA[i,"Real End Date"] <- as.character(matchData$fields.customfield_14440[i])
  if ( !(is.na(matrixA[i,"Expected Start Date"]) | is.na(matrixA[i,"Expected End Date"])) & (matrixA[i,"Project Type"]=="Manutenção" | matrixA[i,"Service Type"]=="Diagnóstico" ))
  {
    matrixA[i,"Max Deadline"] <- as.Date(matrixA[i,"Expected End Date"])-as.Date(matrixA[i,"Expected Start Date"])
    if ( !(is.na(matrixA[i,"Real End Date"])))
    {
      matrixA[i,"Total Project Days"] <- as.Date(matrixA[i,"Real End Date"])-as.Date(matrixA[i,"Expected Start Date"])
      matrixA[i,"Deadline Indicator"] <- paste((100*round(as.numeric(matrixA[i,"Max Deadline"]) / as.numeric(matrixA[i,"Total Project Days"]),digits=4)),"%",sep="")
      if (as.numeric(sub("%", "",matrixA[i,"Deadline Indicator"] ,fixed=TRUE)) > 95)
        matrixA[i,"Penalty"] <- "No"
      else if (as.numeric(sub("%", "",matrixA[i,"Deadline Indicator"] ,fixed=TRUE)) > 90 &
               as.numeric(sub("%", "",matrixA[i,"Deadline Indicator"] ,fixed=TRUE)) <= 95 )
        matrixA[i,"Penalty"] <- "Warning"
      else
        matrixA[i,"Penalty"] <- "5% Fee"      
    }
     
  }
}


df <- data.frame(matrixA,stringsAsFactors=FALSE)
str(df)
df <- type_convert(df)
str(df)
summary(df)


df$Mes <- format(df$Real.End.Date, "%Y/%b")
currentMonth = paste(str_to_title(month(today()-30,label = TRUE, abbr = FALSE)),year(today()))


currentDate <-Sys.Date()
endMonth <- currentDate - days(day(currentDate))

startMonth <- currentDate - days(day(currentDate))
startMonth <- startMonth - days(day(startMonth) - 1)

indicadorSumarizadoMes <- df %>% 
  filter(between(Real.End.Date,startMonth,endMonth) & (Project.Type=="Manutenção" |Service.Type=="Diagnóstico"))
  
indicadorSumarizadoFuturo <- df %>% 
  filter((is.na(Real.End.Date) | Real.End.Date>endMonth) & (Project.Type=="Manutenção" | Service.Type=="Diagnóstico"))

indicadorSumarizadoPassado <- df %>% 
  filter(Real.End.Date< startMonth & (Project.Type=="Manutenção" | Service.Type=="Diagnóstico"))

foraSelecaoIndicador <- df %>% 
  filter(Project.Type!="Manutenção" & Service.Type!="Diagnóstico")


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
  write.xlsx(data.frame(indicadorSumarizadoFuturo), sheetIAT, sheetName = "Indicator to be Calculated", append=TRUE, row.names=FALSE) 
} else
{
  indicadorSumarizadoFuturo[nrow(indicadorSumarizadoFuturo)+1,] <- c(rep(NA,11))
  write.xlsx(indicadorSumarizadoFuturo, sheetIAT, sheetName = "Indicator  to be Calculated", append=TRUE, row.names=FALSE)
  
}
if (nrow(indicadorSumarizadoPassado)!=0) 
{
  write.xlsx(data.frame(indicadorSumarizadoPassado), sheetIAT, sheetName = "Past Indicator", append=TRUE, row.names=FALSE) 
}  else 
  {
    indicadorSumarizadoPassado[nrow(indicadorSumarizadoPassado)+1,] <- c(rep(NA,11))
    write.xlsx(indicadorSumarizadoPassado, sheetIAT, sheetName = "Past Indicator", append=TRUE, row.names=FALSE)
  }

if (nrow(foraSelecaoIndicador)!=0) 
{
  write.xlsx(data.frame(foraSelecaoIndicador), sheetIAT, sheetName = "Indicator not Calculated", append=TRUE, row.names=FALSE) 
}  else 
{
  foraSelecaoIndicador[nrow(foraSelecaoIndicador)+1,] <- c(rep(NA,11))
  write.xlsx(foraSelecaoIndicador, sheetIAT, sheetName = "Indicator not Calculated", append=TRUE, row.names=FALSE)
}

df$Deadline.Indicator = as.numeric(sub("%", "",df$Deadline.Indicator ,fixed=TRUE))/100


df$Deadline.Indicator[df$Deadline.Indicator>1] <- 1
    
indicadorMensal <- df  %>% 
    group_by(OS=Project, month_Year=Mes,month=month(df$Real.End.Date),year=year(df$Real.End.Date)) %>% 
    dplyr::summarise(qtd = sum(Deadline.Indicator),n=n() ) %>% 
    filter(!is.na(qtd) & month == month(endMonth) & year == year(endMonth))

indicadorSumarizado <- df  %>% 
  group_by(OS=Project, Expected.Start.Date=Expected.Start.Date, Expected.End.Date=Expected.End.Date, Max.Deadline=Max.Deadline, Total.Project.Days=Total.Project.Days, Real.End.Date=Real.End.Date,month_Year=format(df$Real.End.Date, "%Y/%m"),Penalty=df$Penalty) %>% 
  dplyr:: summarise(Deadline.Indicator = as.numeric(Deadline.Indicator),n = n() ) %>% 
  filter(!is.na(Deadline.Indicator))
indicadorSumarizado

penalidadeSumarizada <- df  %>% 
  group_by(month_Year=format(df$Real.End.Date, "%Y/%m"),Penalty=df$Penalty) %>% 
  dplyr::summarise(n = n() )   %>% 
  filter(!is.na(Penalty))
penalidadeSumarizada


cores <- c("No"="seagreen3","Warning"="yellow2","5% Fee"="red4")

a <- #ggplot(data=indicadorSumarizado,aes(x=month_Year,y=Indicador.de.Prazo,label=Indicador.de.Prazo*100)) + geom_col(aes(fill=penalidade), position = position_dodge2(width = 1, preserve = "single")) + geom_text(position = position_dodge2(width = 1, preserve = "single"),vjust=-0.5,size=3) +
  ggplot(data=indicadorSumarizado,aes(x=month_Year,y=Deadline.Indicator)) + geom_col(aes(fill=Penalty), position = position_dodge2(width = 1, preserve = "single")) + 
  xlab("Year/Month") +
  #ggtitle("Indicador de Atendimento Tempestivo de Ordem de Serviço (IAT)",subtitle="Sumarizado Mensal por Tipo de Penalidade") +
  ggtitle("Project Deadline Indicator (PDI)",subtitle="Monthly Summary by Type of Penalty") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(face="bold",hjust = 0.5),axis.title = element_text(face = "bold"), legend.title = element_text(colour="black", size=11,face="bold"),plot.caption = element_text(face = "italic", size=7,hjust=1)) +
  #labs(caption = "fonte: Sistema Nacional de Informações Florestais - SNIF" ) +
  labs(caption ="IAT > 95%: OK\n90% < IAT <=95%: Warning\nIAT <= 90%: 5% Fee") +
  #labs(caption ="IAT > 95%: OK\n90% < IAT <=95%: Advertência\nIAT <= 90%: Penalidade de 5%") +
  #scale_fill_discrete(name = "Tipo de Penalidade") +
  scale_fill_discrete(name = "Penalty") +
  scale_y_continuous("PDI", labels = percent_format()) +
  scale_fill_manual(values = cores)
  
b <- ggplot(data=indicadorMensal,aes(x=month_Year,y=qtd,label=qtd*100)) + geom_col(aes(fill = OS),width = 0.2,position = position_dodge2(width = 1, preserve = "total")) + geom_text(position = position_dodge2(width = 1, preserve = "total"),vjust=-0.5,size=3) +
  xlab("Year/Month") +
  #ylab("Total(%)") +
  #ggtitle("Indicador de Atendimento Tempestivo de Ordem de Serviço (IAT)",subtitle=paste(str_to_title(month(today()-30,label = TRUE, abbr = FALSE)),year(today()))) +
  ggtitle("Project Deadline Indicator (PDI)",subtitle=paste(str_to_title(month(today()-30,label = TRUE, abbr = FALSE)),year(today()))) +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(face="bold",hjust = 0.5),axis.title = element_text(face = "bold"), legend.title = element_text(colour="black", size=11,face="bold"),plot.caption = element_text(face = "italic", size=7,hjust=1)) +
  #labs(caption = paste("IAT > 95: Nenhuma Penalidade","\n","90 < IAT <=95: Advertência","\n","IAT <= 90: Glosa e 5%",sep="")) +
  #labs(caption ="IAT > 95%: Nenhuma Penalidade   "\n"     90% < IAT <=95%: Advertência        IAT <= 90%: Glosa de 5%") +
  #labs(caption ="IAT > 95%: OK\n90% < IAT <=95%: Advertência\nIAT <= 90%: Penalidade de 5%") +
  labs(caption ="IAT > 95%: OK\n90% < IAT <=95%: Warning\nIAT <= 90%: 5% Fee") +
  scale_fill_discrete(name = "Project") +
  scale_y_continuous("PDI",labels=percent_format())

c <- ggplot(data=penalidadeSumarizada,aes(x=month_Year,y=n,label=n)) + geom_col(aes(fill = Penalty),position = position_dodge2(width = 0.3, preserve = "single")) + geom_text(position = position_dodge2(width=0.3, preserve = "single"),vjust=0.05,size=3) +
  xlab("Year/Month") +
  ylab("Quantity of Projects") +
  ggtitle("Project Deadline Indicator (PDI)",subtitle="Number of Monthly Penalties") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(face="bold",hjust = 0.5),axis.title = element_text(face = "bold"), legend.title = element_text(colour="black", size=11,face="bold")) +
  scale_fill_discrete(name = "Penalty") +
  scale_fill_manual(values = cores)


fileIATMensal = paste("IAT-Mes",currentMonth)

ggsave(path = "C:/R_out/IndicadorOS/output",filename="IAT-Sumarizado-Mensal.png", plot=a)

ggsave(path = "C:/R_out/IndicadorOS/output",filename=paste(fileIATMensal,".png"), plot=b)

ggsave(path = "C:/R_out/IndicadorOS/output",filename="IAT-Quantitativo-Penalidade-Mensal.png", plot=c)

ggsave(path = "C:/R_out/IndicadorOS/output",filename="IAT-Sumarizado-Mensal.pdf", plot=a, device=cairo_pdf, width = 12, height = 4, units = "in", dpi = 600)
ggsave(path = "C:/R_out/IndicadorOS/output",filename=paste(fileIATMensal,".pdf"), plot=b, device=cairo_pdf, width = 12, height = 4, units = "in", dpi = 600)
ggsave(path = "C:/R_out/IndicadorOS/output",filename="IAT-Quantitativo-Penalidade-Mensal.pdf", plot=c, device=cairo_pdf, width = 8, height = 4, units = "in", dpi = 600)
