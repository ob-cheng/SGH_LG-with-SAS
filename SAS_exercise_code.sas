*#Assign a library - get access to the data;
libname ess '/home/korczynskiadam/ess';

*#Explore the variables in the input dataset;
proc sql;
create table meta01 as select
* from dictionary.columns where libname='ESS' and memname='ESS9E03_1';
quit;

*#
Documentation:
https://www.europeansocialsurvey.org/docs/round9/fieldwork/source/ESS9_source_questionnaires.pdf
;
*#
Research question: What are the factors making Polish people happy?
Hypothesis: Higher income makes Polish people happy.;

*#Copy the input dataset into WORK library for processing;
PROC FORMAT;
   value $CNTRY_
     'GB' = 'United Kingdom'  
     'BE' = 'Belgium'  
     'DE' = 'Germany' 
     'DK' = 'Danemark' 
     'EE' = 'Estonia'  
     'IE' = 'Ireland'  
     'SE' = 'Sweden'  
     'CH' = 'Switzerland'  
     'FI' = 'Finland'  
     'SI' = 'Slovenia'  
     'IL' = 'Israel'  
     'NL' = 'Netherlands'  
     'PL' = 'Poland'  
     'NO' = 'Norway'  
     'FR' = 'France'  
     'IS' = 'Iceland'  
     'AT' = 'Austria'  
     'RU' = 'Russian Federation'  
     'CZ' = 'Czech Republic' ;
        value $CNTRY
     'GB' = 'United Kingdom'  
     'BE' = 'Belgium'  
     'DE' = 'Germany'  
     'EE' = 'Estonia'  
     'IE' = 'Ireland'  
     'ME' = 'Montenegro'  
     'SE' = 'Sweden'  
     'BG' = 'Bulgaria'  
     'CH' = 'Switzerland'  
     'FI' = 'Finland'  
     'SI' = 'Slovenia'  
     'DK' = 'Denmark'  
     'SK' = 'Slovakia'  
     'NL' = 'Netherlands'  
     'PL' = 'Poland'  
     'NO' = 'Norway'  
     'FR' = 'France'  
     'HR' = 'Croatia'  
     'ES' = 'Spain'  
     'IS' = 'Iceland'  
     'RS' = 'Serbia'  
     'AT' = 'Austria'  
     'IT' = 'Italy'  
     'LT' = 'Lithuania'  
     'PT' = 'Portugal'  
     'HU' = 'Hungary'  
     'LV' = 'Latvia'  
     'CY' = 'Cyprus'  
     'CZ' = 'Czechia' ;
     value HINCTNTA
      1 = 'J - 1st decile'  
      2 = 'R - 2nd decile'  
      3 = 'C - 3rd decile'  
      4 = 'M - 4th decile'  
      5 = 'F - 5th decile'  
      6 = 'S - 6th decile'  
      7 = 'K - 7th decile'  
      8 = 'P - 8th decile'  
      9 = 'D - 9th decile'  
      10 = 'H - 10th decile'  
      77 = 'Refusal'   
      88 = 'Don''t know' 
      99 = 'No answer';
      value happyfmt
      1='Happy'
      0='Unhappy';
run;

*ESS 9;
data e01;
 length country $20;
	set ess.ess9e03_1;
	country=putc(cntry,'$cntry');
	format cntry $cntry. HINCTNTA HINCTNTA.;
run;

	*ESS 8;
	data e01_8;
	 length country $20;
		set ess.ess8e01;
		country=putc(cntry,'$cntry');
		format cntry $cntry8. HINCTNTA HINCTNTA.;
	run;

*#Find out code of the country - formats provided by ESS;
proc freq data=e01;
	table cntry / out=f01;
run;
proc freq data=e01_8;
	table cntry / out=f01;
run;

*# Happy is the response variable. Exploring the categories.
Note: 77 - refusal, 88 - don't know, 99 - missing;
%let Var=happy;
%let Var=hinctnta;
%let Var=health;
%let Var=age;
%let Var=gndr;
proc freq data=e01;
	table &Var. / out=f01;
run;

proc means data=e01 mean std cv;
	var &Var.;
	class country;
	where &Var.<77;
run;

proc sort data=e01 out=e01s;
	by country;
run;
proc freq data=e01s;
	table &Var. / out=f01;
	where &Var.<77;
	by country;
run;

*# OnlineDoc help:
http://documentation.sas.com/?docsetId=grstatproc&docsetVersion=9.4&docsetTarget=n0wqazuv6959fnn1fask7mi68lla.htm&locale=pl#n1rsdobpxxkdz3n1k64783nw7xm3;
proc sgpanel data=e01; /*proc sgplot*/
	panelby country / columns=1;
	vbar &Var. /* / stat=percent*/;
	where &Var.<77;
run;

*####################################
## Project Descriptive Statsitics 1##
#####################################;
*Distribution of the response variable;
%let Var=happy;
proc sgplot data=e01; 
	vbar &Var. / stat=percent  datalabel;
	where cntry='PL' /*and &Var.<77*/;
run;

*Comparing results from two rounds (8 and 9);
data t01;
 set e01 (keep=essround country &Var.) e01_8 (keep=essround country &Var.);
run;

proc sort data=t01 out=t02;
 by country essround;
run;

*Overview of the countries;
proc sgplot data=t02;
 vbar &Var. / group=essround groupdisplay=cluster stat=percent;
 by country;
 where &Var.<77;
run;

*Single country result;
proc sgplot data=t02;
 *vbar &Var. / group=essround groupdisplay=cluster stat=percent;
 vbar &Var. / group=essround groupdisplay=cluster transparency=0.5 stat=percent;
 where country='Poland';
run;



*#Based on frequency analysis the following dichotomization was applied:
0-6 - unhappy (Y=0)
>6 - happy (Y=1);

*#Create dichotomized variable based on variable HAPPY;
data e02;
	set e01;
	if ^missing(happy) then do;
		if happy<=6 then y=0;
		else if 6<happy<=10 then y=1;
	end;
	else if happy>10 or missing(happy) then y=.;
run;

*####################################
## Project Descriptive Statsitics 2##
#####################################;
*#Verify dichotomization;
proc freq data=e02;
	table happy;
	table y;*The project should report the outcome of the dichotomization;
	where cntry='PL';
run;

*#Selecting explanatory variables
Feature|Name of variable in ESS dataset:
INCOME: hinctnta
HEALTH: healts
AGE: YRBRN
SEX: GNDR
Codebook: https://www.europeansocialsurvey.org/docs/round9/survey/ESS9_appendix_a7_e03_1.pdf
;
data e03;
	set e02;
	if hinctnta<=10 then income=hinctnta;
	else if hinctnta>10 then income=11;
	if health<=5 then health_=health;
	else if health>5 then health_=9;
	if ^missing(YRBRN) and yrbrn<7777 then do;
		age = 2016-YRBRN;
	end;
run;

*#Exploring variables using selection procedure
Complete case analysis;
proc freq data=e03;
 tables hinctnta;
 where cntry='PL' and income<=10;
run;

proc logistic data=e03 outest=cov;
	class income (param=ref ref='10');
	model y(event='1')= income;
	*Testing linear hypothesis;
	dec2_vs_dec7: test income2-income7;
	weight anweight;
	where cntry='PL' and income<=10;
run;

 
*#How to explore missing answers? This is a source of potential bias;
proc logistic data=e03;
	class income (param=ref ref='5');
	model y(event='1')= income;
	where cntry='PL';
	oddsratio income/ at(income=all);
run;

proc freq data=e03;
 tables hinctnta;
run;

proc logistic data=e03;
	class hinctnta (param=ref ref='F - 5th decile');
	model y(event='1')= hinctnta;
	where cntry='PL';
	oddsratio hinctnta/ at(hinctnta=all);
run;



*####################################
## Project Descriptive Statsitics 3##
#####################################;
*#Discriminatory performance of categorical variables;
%Macro discperf(Var=);
proc freq data=e03;
	tables y*&Var.;
	ods output CrossTabFreqs=pct01;
	where cntry='PL';
	weight anweight;
run;
proc sgplot data=pct01(where=(^missing(RowPercent)));
	vbar y / group=&Var. groupdisplay=cluster response=RowPercent datalabel;
	format y happyfmt.;
run;
%Mend DiscPerf;
%DiscPerf(Var=income);
%DiscPerf(Var=health_);
%DiscPerf(Var=gndr);

*#Discriminatory performance of continuous variables;
*#Age;
proc means data=e03;
	var age;
	class y;
	where cntry='PL';
run;
proc sgpanel data=e03;
	panelby y / columns=1;
	histogram age ;
	where cntry='PL';
run;

*Use of internet;
proc freq data=e03;
	tables NETUSTM;
	where NETUSTM<2000;*#Missing data coding;
run;

proc means data=e03;
	var NETUSTM;
	class y;
	where NETUSTM<2000;
run;


*#Modelling - confirmatory vs exploratory analysis;
proc logistic data=e03;
	class income (param=ref ref='10') health_ (param=ref ref='3') gndr (param=ref ref='1');
	model y(event='1')= income health_ age gndr health_*age / expb  selection=forward sle=0.2 /*Forward | Backward | Stepwise*/;
	where cntry='PL' and income<=10;
run;

*####################################
## Substantive analysis 1										##
#####################################;
ods exclude Influence;
proc logistic data=e03 plots(only)=roc  /*4. Discriminatory performance*/;
	class income (param=ref ref='10') health_ (param=ref ref='3') gndr (param=ref ref='1');
	model y(event='1')= income health_ age gndr /*health_*age*/ / 
			expb 
			covb corrb /*1. Collinearity - needed?*/
			aggregate scale=none lackfit /*2. Goodness-of-fit, H-L test*/
			influence /*3. Influential observations*/
			;
	weight anweight;
	ods output Influence=inf01;
	output out=p p=pred difdev=difdev difchisq=difchisq h=leverage c=c;
	where cntry='PL' and income<=10 and health_<9 /*and netustm<2000*/;*We need to be careful here. BIAS intoduced by this step;
run;




*#############################################
## Substative analysis - Model diagnostics 1##
##############################################;
*Assessing collinearity;
proc univariate data=e03;
 var netustm;
run;
proc freq data=e03 noprint;
 tables netustm / out=g01;
run;

data e04;
 set e03;
 where NETUSTM<2000;
run;

proc sgplot data=e04;
 scatter x=age y=netustm;
run;

proc corr data=e04;
 var age netustm;
run;

proc reg data=e04 plots=none;
	model y = age netustm / vif tol collin;
run;

*#What if there were correlated exploratory variables?;
		proc iml;
		Mean = {1, 2};
		Cov = {1 0.9, 
		       0.9 1};
		call randseed(4321);               
		X = RandNormal(1000, Mean, Cov);
		*print X;
		create out01 from X[c={"x1" "x2"}];
		append from X;
		quit;
		
		proc corr data=out01;
		var x1 x2;
		run;
		
		data out02;
		 set out01;
		 if ranbin(122,1,0.2) then y=1;
		 else y=0;
		run;
		
		proc logistic data=out02;
			model y(event='1')= x1 x2 / covb corrb;
		run;
		proc reg data=out02 plots=none;
			model y = x1 x2 / vif tol collin;
		run;


*#############################################
## Substative analysis - Model diagnostics 2##
##############################################;
*Outliers;
data p1;
 set p;
 i+1;
 keep i y income health_ age gndr pred dif: leverage c;
 	where cntry='PL' and income<=10 and health_<9;
run;

proc sgplot data=p1;
scatter x=i y=difdev;
run;

proc sgplot data=p1;
scatter x=i y=difchisq / markerattrs=(color=red);
run;

*Influential observations;
*ods graphics on / imagemap;
proc sgplot data=p1;
scatter x=pred y=leverage /  datalabel=i ; *Datapoints that are rare;
run;

proc sgplot data=p1;
scatter x=pred y=difdev;
run;

proc sgplot data=p1;
bubble x=pred y=difchisq size=c / nofill datalabel=i;*Datapoints that go against the general findings;
run;