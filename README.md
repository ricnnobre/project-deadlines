# Project-Deadlines

This is an R code to bring project deadlines from Jira software and show them to the manager.

The projects developed in the IT area have delivery deadlines that need to be monitored and later collected in order to ensure that the  SLAs are met.

The IT contract include any penalties as a result of a missed SLA by a project. 

These penalties range from a formal warning to even 5% of total value of the bill to be charged as penalty.


# Rule for calculating the deadline indicator of projects

- Projects with a deadline indicator above 95%: No penalty
- Projects with a deadline indicator between 90% and 95%: Warning
- Projects with a deadline indicator equal or below 90%: 5% fine on the total bill to be paid


# R Code
projectIndicator.R


#Input
Json file extracted from Jira app:
response-data-export.json 


#Outputs
a) Monthly Deadline Indicator:
IAT-Mes Fevereiro 2020.pdf
IAT-Mes Fevereiro 2020.png

b) Total of Monthly Penalties
IAT-Quantitativo-Penalidade-Mensal.pdf
IAT-Quantitativo-Penalidade-Mensal.png
 
c) Monthly Summary by Type of Penalties 
IAT-Sumarizado-Mensal.pdf
IAT-Sumarizado-Mensal.png
