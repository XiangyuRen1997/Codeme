clear all
prog drop _all
capture log close
set more off

log using "/Users/replication exercise.log", replace
use "/Users/raw pums80 slim.dta", clear 
cd "/Users"

/*Preparation of data*/
*generate mom sample*
gen mom=.
replace mom=1 if (us80a_chborn>=3 & us80a_nchild==us80a_chborn-1 & age<=35 & age>=21 & sex==2)
replace mom=0 if mom==.
keep if mom==1
save mother, replace

*merge mom sample to main sample*
keep us80a_pernum us80a_serial
rename us80a_pernum momloc
merge 1:m us80a_serial momloc using "/Users/xiangyuren/Documents/AEM 2172/raw pums80 slim.dta"
keep if _merge==3

*generate children sample*
keep age sex us80a_serial momloc us80a_birthqtr us80a_qage us80a_qsex us80a_qbirthmo
gsort us80a_serial -age
bys us80a_serial: gen childrennumber=_n 
reshape wide age sex us80a_birthqtr us80a_qage us80a_qsex us80a_qbirthmo, i(momloc us80a_serial) j(childrennumber)
keep us80a_serial momloc age1 sex1 us80a_birthqtr1 us80a_qage1 us80a_qsex1 us80a_qbirthmo1 age2 sex2 us80a_birthqtr2 us80a_qage2 us80a_qsex2 us80a_qbirthmo2 age3 sex3 us80a_birthqtr3 
drop if age1>=18 | age2<1 
drop if age2==. | sex2==. 
rename momloc us80a_pernum
save children, replace

*merge children sample to mom sample*
merge 1:m us80a_serial us80a_pernum using "mother.dta"
keep if _merge==3 & us80a_qage1==0 & us80a_qage2==0 & us80a_qsex1==0 & us80a_qsex2==0 & us80a_qbirthmo1==0 & us80a_qbirthmo2==0
save subsample, replace

*generate covariates*
gen chborn=us80a_chborn-1

gen birthqtr1=0 if us80a_birthqtr1==1
replace birthqtr1=0.25 if us80a_birthqtr1==2
replace birthqtr1=0.5 if us80a_birthqtr1==3
replace birthqtr1=0.75 if us80a_birthqtr1==4

gen marrqtr=0 if us80a_marrqtr==1
replace marrqtr=0.25 if us80a_marrqtr==2
replace marrqtr=0.5 if us80a_marrqtr==3
replace marrqtr=0.75 if us80a_marrqtr==4

gen children2more=1 if (us80a_nchild>=3)
replace children2more=0 if (us80a_nchild<3)

gen boy1st=.
replace boy1st=1 if sex1==1
replace boy1st=0 if boy1st==.

gen boy2nd=.
replace boy2nd=1 if sex2==1
replace boy2nd=0 if boy2nd==.

gen twoboys=.
replace twoboys=1 if (sex1==1 & sex2==1)
replace twoboys=0 if twoboys==.

gen twogirls=.
replace twogirls=1 if (sex1==2 & sex2==2)
replace twogirls=0 if twogirls==.

gen samesex=.
replace samesex=1 if (sex1==sex2)
replace samesex=0 if samesex==.

gen twin=.
replace twin=1 if (age2==age3 & us80a_birthqtr2==us80a_birthqtr3)
replace twin=0 if twin==.

gen workedforpay=.
replace workedforpay=1 if us80a_wkswork1>0
replace workedforpay=0 if workedforpay==.


gen inflated_incwage=(us80a_incwage*2.099173554) 
gen inflated_ftotinc=(us80a_ftotinc*2.099173554)
gen nonwifeincome= us80a_ftotinc-us80a_incwage
gen inflated_nonwifeinc=(nonwifeincome*2.099173554)
gen agefirstbirth=age-age1

replace inflated_incwage=0 if inflated_incwage==.
replace inflated_ftotinc=0 if inflated_ftotinc==.
replace inflated_nonwifeinc=0 if inflated_nonwifeinc==.

gen black=1 if us80a_race==3
replace black=0 if black==.

gen otherrace=1 if us80a_race !=1 & us80a_race!=2 & us80a_race!=3
replace otherrace=0 if otherrace==.

gen hispanic=1 if us80a_race==2
replace hispanic=0 if hispanic==.
save replication, replace

/*Part I*/
/*table 2 mean first column all women*/
mean chborn children2more boy1st boy2nd twoboys twogirls samesex twin age agefirstbirth workedforpay us80a_wkswork1 us80a_uhrswork inflated_incwage inflated_ftotinc
outreg2 using table2, excel stats(mean se) ctitle(All Women) replace
/*table 6 OLS regression for all women*/
reg children2more samesex, r
outreg2 using table6, excel ctitle(OLS_More than 2 children) replace
reg children2more boy1st boy2nd samesex age agefirstbirth black otherrace hispanic, r
outreg2 using table6, excel keep(boy1st boy2nd samesex) ctitle(OLS_More than 2 children) append
reg children2more boy1st twoboys twogirls age agefirstbirth black otherrace hispanic, r
outreg2 using table6, excel keep(boy1st twoboys twogirls) ctitle(OLS_More than 2 children) append

/*Table 7 instrumental variable for all wome */
*column 1*
reg workedforpay children2more age agefirstbirth boy1st boy2nd black otherrace hispanic, r
outreg2 using table7, excel keep(children2more) ctitle(column 1 worked for pay all women) replace
reg us80a_wkswork1 children2more age agefirstbirth boy1st boy2nd black otherrace hispanic, r
outreg2 using table7, excel keep(children2more) ctitle(column 1 weeks worked all women) append
reg  us80a_uhrswork children2more age agefirstbirth boy1st boy2nd black otherrace hispanic, r
outreg2 using table7, excel keep(children2more) ctitle(column 1 hours work per week all women) append
reg inflated_incwage children2more age agefirstbirth boy1st boy2nd black otherrace hispanic,r
outreg2 using table7, excel keep(children2more)  ctitle(column 1 labor income all women) append
gen lnfamilyinc=ln(inflated_ftotinc+1)
reg lnfamilyinc children2more age agefirstbirth boy1st boy2nd black otherrace hispanic,r
outreg2 using table7, excel keep(children2more) ctitle(column 1 ln-family income all women) append

*column 2*
ivregress 2sls workedforpay (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace, r
outreg2 using table7, excel keep(children2more) ctitle(column 2 worked for pay all women) append
ivregress 2sls us80a_wkswork1 (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace, r
outreg2 using table7, excel keep(children2more) ctitle(column 2 weeks worked all women) append
ivregress 2sls us80a_uhrswork (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace, r
outreg2 using table7, excel keep(children2more) ctitle(column 2 hours worked per week all women) append
ivregress 2sls inflated_incwage (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace,r
outreg2 using table7, excel keep(children2more) ctitle(column 2 labor income all women) append
ivregress 2sls lnfamilyinc (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace,r
outreg2 using table7, excel keep(children2more) ctitle(column 2 ln-family income all women) append

*column 3*
ivregress 2sls workedforpay (children2more=twogirls twoboys) age agefirstbirth boy1st hispanic black otherrace, r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 3 worked for pay all women) append
ivregress 2sls us80a_wkswork1 (children2more=twogirls twoboys) age agefirstbirth boy1st hispanic black otherrace,r 
estat overid 
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 3 weeks worked all women) append
ivregress 2sls us80a_uhrswork (children2more=twoboys twogirls) age agefirstbirth boy1st hispanic black otherrace,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 3 hours worked per week all women) append
ivregress 2sls inflated_incwage (children2more=twoboys twogirls) age agefirstbirth boy1st hispanic black otherrace,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7,  excel stats(coef se) e(jstat) keep(children2more) ctitle(column 3 labor income all women) append
ivregress 2sls lnfamilyinc (children2more=twoboys twogirls) age agefirstbirth boy1st hispanic black otherrace,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 3 ln-family income all women) append

/*Part II*/
/*maried women*/
keep if us80a_agemarr+marrqtr<=agefirstbirth+birthqtr1 & us80a_marrno==1 
keep if us80a_marst==1 | us80a_marst==2
drop _merge
save Mainsample, replace

/*Table 6 OLS regression married women*/
reg children2more samesex, r
outreg2 using table6,excel ctitle(OLS_More than 2 children) append
reg children2more boy1st boy2nd samesex age agefirstbirth black otherrace hispanic, r
outreg2 using table6,excel keep(boy1st boy2nd samesex) ctitle(OLS_More than 2 children) append
reg children2more boy1st twoboys twogirls age agefirstbirth black otherrace hispanic, r
outreg2 using table6, excel keep(boy1st twoboys twogirls) ctitle(OLS_More than 2 children) append

/*Table 7 instrumental variable married women*/
*column 4*
reg workedforpay children2more age agefirstbirth boy1st boy2nd black otherrace hispanic,r
outreg2 using table7, excel keep(children2more) ctitle(column 4 worked for pay married women) append
reg us80a_wkswork1 children2more age agefirstbirth boy1st boy2nd black otherrace hispanic,r
outreg2 using table7, excel keep(children2more) ctitle(column 4 weeks worked married women) append
reg  us80a_uhrswork children2more age agefirstbirth boy1st boy2nd black otherrace hispanic, r
outreg2 using table7, excel keep(children2more) ctitle(column 4 hours work per week married women) append
reg inflated_incwage children2more age agefirstbirth boy1st boy2nd black otherrace hispanic, r
outreg2 using table7, excel keep(children2more) ctitle(column 4 labor income married women) append
reg lnfamilyinc children2more age agefirstbirth boy1st boy2nd black otherrace hispanic, r
outreg2 using table7, excel keep(children2more) ctitle(column 4 ln-family income married women) append
gen lnnowifeinc=ln(inflated_nonwifeinc+1)
reg lnnowifeinc children2more age agefirstbirth boy1st boy2nd black otherrace hispanic,r
outreg2 using table7, excel keep(children2more) ctitle(column 4 ln-non wife income married women) append

*column 5*
ivregress 2sls workedforpay (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace,r
outreg2 using table7, excel keep(children2more) ctitle(column 5 worked for pay married women) append
ivregress 2sls us80a_wkswork1 (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace,r
outreg2 using table7, excel keep(children2more) ctitle(column 5 weeks worked married women) append
ivregress 2sls us80a_uhrswork (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace,r
outreg2 using table7, excel keep(children2more) ctitle(column 5 hours worked per week married women) append
ivregress 2sls inflated_incwage (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace,r
outreg2 using table7, excel keep(children2more) ctitle(column 5 labor income married women) append
ivregress 2sls lnfamilyinc (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace,r
outreg2 using table7, excel keep(children2more) ctitle(column 5 ln-family income married women) append
ivregress 2sls lnnowifeinc (children2more=samesex) age agefirstbirth boy1st boy2nd hispanic black otherrace,r
outreg2 using table7, excel keep(children2more) ctitle(column 5 ln-non wife income married women) append

*column 6*
ivregress 2sls workedforpay (children2more=twoboys twogirls) age agefirstbirth boy1st hispanic black otherrace,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 6 worked for pay married women) append
ivregress 2sls us80a_wkswork1 (children2more=twoboys twogirls) age agefirstbirth boy1st hispanic black otherrace,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 6 weeks worked married women) append
ivregress 2sls us80a_uhrswork (children2more=twoboys twogirls) age agefirstbirth boy1st hispanic black otherrace,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 6 hours worked per week married women) append
ivregress 2sls inflated_incwage (children2more=twoboys twogirls) age agefirstbirth boy1st hispanic black otherrace,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 6 labor income married women) append
ivregress 2sls lnfamilyinc (children2more=twoboys twogirls) age agefirstbirth boy1st hispanic black otherrace,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 6 ln-family income married women) append
ivregress 2sls lnnowifeinc (children2more=twoboys twogirls) age agefirstbirth boy1st hispanic black otherrace,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 6 ln-non wife income married women) append


/*Part III*/
/*Table 2 mean second column for married women and spouse*/
*generate spouse sample*
use Mainsample, replace
keep us80a_sploc us80a_serial
rename us80a_sploc us80a_pernum
merge 1:m us80a_pernum us80a_serial using "/Users/xiangyuren/Documents/AEM 2172/raw pums80 slim.dta"
keep if _merge==3
gen dad=1 if _merge==3
replace dad=0 if dad==.
save dad, replace
*merge spouse sample with children sample*
drop _merge us80a_sploc
rename us80a_incwage fincwage
rename age fage
rename us80a_wkswork1 fwkswork
rename us80a_uhrswork fuhrswork
rename us80a_race frace
rename us80a_pernum us80a_sploc
merge 1:m us80a_sploc us80a_serial using "Mainsample.dta"
save dadwchild, replace


*generate covariates* 
gen fworkedforpay=1 if fwkswork>0
replace fworkedforpay=0 if fworkedforpay==.
gen inflated_fincwage=(fincwage*2.099173554)
gen fagefirstbirth=fage-age1
gen fblack=1 if frace==3
replace fblack=0 if fblack==.
gen fhispanic=1 if frace==2
replace fhispanic=0 if fhispanic==.
gen fotherrace=1 if frace!=1 & frace!=2 & frace!=3
replace fotherrace=0 if fotherrace==.
save family, replace

mean chborn children2more boy1st boy2nd twoboys twogirls samesex twin age agefirstbirth workedforpay us80a_wkswork1 us80a_uhrswork inflated_incwage inflated_ftotinc inflated_nonwifeinc fage fagefirstbirth fworkedforpay fwkswork fuhrswork inflated_fincwage
outreg2 using table2, excel stats(mean sd) ctitle(Married couples) append

/*Table 7 Instrumental variable spouses*/
*column 7*
reg fworkedforpay children2more fage fagefirstbirth boy1st boy2nd fblack fotherrace fhispanic if dad==1,r
outreg2 using table7, excel keep(children2more) ctitle(column 7 worked for pay sponse)
reg fwkswork children2more age agefirstbirth boy1st boy2nd fblack fotherrace fhispanic if dad==1,r
outreg2 using table7, excel keep(children2more) ctitle(column 7 weeks worked sponse)
reg  fuhrswork children2more fage fagefirstbirth boy1st boy2nd fblack fotherrace fhispanic if dad==1,r
outreg2 using table7, excel keep(children2more) ctitle(column 7 hours worked per week sponse)
reg  inflated_fincwage children2more fage fagefirstbirth boy1st boy2nd fblack fotherrace fhispanic if dad==1,r
outreg2 using table7, excel keep(children2more) ctitle(column 7 labor income sponse)

*column 8*
ivregress 2sls fworkedforpay (children2more=samesex) fage fagefirstbirth boy1st boy2nd fhispanic fblack fotherrace if dad==1, r
outreg2 using table7, excel keep(children2more) ctitle(column 8 worked for pay sponse)
ivregress 2sls fwkswork (children2more=samesex) fage fagefirstbirth boy1st boy2nd fhispanic fblack fotherrace if dad==1,r
outreg2 using table7, excel keep(children2more) ctitle(column 8 weeks worked sponse)
ivregress 2sls fuhrswork (children2more=samesex) fage fagefirstbirth boy1st boy2nd fhispanic fblack fotherrace if dad==1,r
outreg2 using table7, excel keep(children2more) ctitle(column 8 hours worked per week sponse)
ivregress 2sls inflated_fincwage (children2more=samesex) fage fagefirstbirth boy1st boy2nd fhispanic fblack fotherrace if dad==1, r
outreg2 using table7, excel keep(children2more) ctitle(column 8 labor income sponse)

*column 9*
ivregress 2sls fworkedforpay (children2more=twoboys twogirls) fage fagefirstbirth boy1st fhispanic fblack fotherrace if dad==1,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 9 worked for pay sponse)
ivregress 2sls fwkswork (children2more=twoboys twogirls) fage fagefirstbirth boy1st fhispanic fblack fotherrace if dad==1,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 9 weeks worked sponse)
ivregress 2sls fuhrswork (children2more=twoboys twogirls) fage fagefirstbirth boy1st fhispanic fblack fotherrace if dad==1,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 9 hours worked per week sponse)
ivregress 2sls inflated_fincwage (children2more=twoboys twogirls) fage fagefirstbirth boy1st fhispanic fblack fotherrace if dad==1,r
estat overid
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(children2more) ctitle(column 9 labor income sponse)



log close

