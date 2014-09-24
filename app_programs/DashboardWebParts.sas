******************************************************************************************************************************;
** Program: DashboardWebParts.sas																							**;
** Purpose: A compilation of all web parts used in the Dashboard. If web part is a copy from a WebParts.sas program it		**;
**			may be assigned the same Web Part ID.																			**;
**																															**;
** Date: 01/01/2014																											**;
** Developer: John Sandoval																									**;
** Application Version: 2.0																									**;
**																															**;
** Data sources: Defined in Metadata																						**;
**																															**;
** Includes (pay attention to UNC vs. Relative pathing):																	**;
**  None																													**;
**																															**;
** Notes:																													**;
** History:																													**;
**		01/01/2014 John Sandoval - Initial Release																			**;
**																															**;
******************************************************************************************************************************;

%macro dashboard_web_parts;

/*****************************************************************************************************************************/
/** Default Dashboard Web Part 									(for users that have not yet customized their dashboard)	**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 0 %then %do;

		/** Getting Started slideshow **/
		data web_part(keep=text);
			length text $5000.;
			text = '<div id="dashboard-slideshow" style="margin: 10px auto;">'; output;
			text = cats('<img src="/SAS/images/', "&app_version", '/Slideshow/Welcome_Image_1.png" width="794" height="442" alt="Welcome" />'); output;
			text = cats('<img src="/SAS/images/', "&app_version", '/Slideshow/Your_Dashboard.png" width="794" height="442" alt="YourDashboard" />'); output;
			text = cats('<img src="/SAS/images/', "&app_version", '/Slideshow/Your_Favorites.png" width="794" height="442" alt="YourFavorites" />'); output;
			text = cats('<img src="/SAS/images/', "&app_version", '/Slideshow/Your_Browser.png" width="794" height="442" alt="YourBrowser" />'); output;
			text = cats('<img src="/SAS/images/', "&app_version", '/Slideshow/Getting_Started.png" width="794" height="442" alt="GettingStarted" />'); output;
			text = '</div>'; output;
			text = '<div id="slideshow-nav"></div>'; output;
		run;

	%end;

/****************************/
/** Basic Web Part samples **/
/****************************/
	%if %eval(&web_part_id) = 53 %then %do;
		proc sort data = vzwbtst.billing_validate_log out = tngraph(keep=entity_id);
			by entity_id;
			where billing_period = '01OCT2013'd;
		run;

		data web_part(keep=text);
			set tngraph end=last;
			length text $5000.;
			if _n_ = 1 then do;
				text = cats('<table><tr><td>', entity_id, '</td></tr>');
			end;
			if (_n_ ne 1) and (not last) then do;
				text = cats('<tr><td>', entity_id, '</td</tr>');
			end;
			if last then do;
				text = cats('<tr><td>', entity_id, '</td</tr></table>');
			end;
		run;

	%end;


	%if %eval(&web_part_id) = 9999 %then %do;
		proc sort data = vzwbtst.billing_validate_log out = tngraph(keep=entity_id);
			by entity_id;
			where billing_period = '01OCT2013'd;
		run;

		data web_part(keep=text);
			set tngraph end=last;
			length text $5000.;
			if _n_ = 1 then do;
				text = cats('<table><tr><td>', entity_id, '</td></tr>');
			end;
			if (_n_ ne 1) and (not last) then do;
				text = cats('<tr><td>', entity_id, '</td</tr>');
			end;
			if last then do;
				text = cats('<tr><td>', entity_id, '</td</tr></table>');
			end;
		run;

	%end;

/*****************************************************************************************************************************/
/** Sample Verizon Billing Nation Summary Graph																				**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 54 %then %do;

		/*************************************/
		/** Create the Nation Summary graph **/
		/*************************************/
		%let tn_type = WRLN;
		%let procdatew = SEP2013N;
		%let entity_display_type = Wireline;
		%let graph_months = 13;
		/*%let bar_color_scale = cxBBBBBB cxB9B9B9 cxB5B5B5 cxAAAAAA cxA9A9A9 cxA5A5A5 cx999999 cx888888 cx777777 cx666666 cx555555 cx444444 cx333333;*/
		%let bar_color_scale = cx1faae9 cx1faae9 cx1faae9 cx1faae9 cx1faae9 cx1faae9 cx1faae9 cx1faae9 cx1faae9 cx1faae9 cx1faae9 cx1faae9 cx1faae9;

		/** Create the TN Graph data set **/
		proc sort data = vzwbtst.billing_validate_log out = tngraph;
			by billing_period entity_type entity_id create_dt;
		run;

		data tngraph;
			set tngraph;
			by billing_period entity_type entity_id create_dt;
			if last.entity_id;
			if entity_type = "&tn_type";
			if billing_period > intnx('month', input(substr("&procdatew",1,7),monyy7.), -&graph_months)
			   and billing_period <= intnx('month', input(substr("&procdatew",1,7),monyy7.), 0);
			length billing_period_str $50.;
			billing_period_str = trim(put(billing_period, monyy7.));
			if tn_count = . then tn_count = 0;
			drill = cats('TITLE="', put(billing_period, monyy7.), '&#013', "&entity_display_type", ':&#160;', trim(entity_id), '&#013TNs:&#160;', put(tn_count, comma12.), '" HREF="#"');
			format billing_period monyy7. tn_count comma12.;
		run;

		/** Create custom style **/
		ODS PATH work.templat(update) sasuser.templat(read) sashelp.tmplmst(read);

		proc template;
			define style Styles.Saturn;
			parent = styles.default;
			replace colors /
	   			'headerbg' = cxEEF0F2
				'headerfg' = cxFFFFFF
				'docbg' = cxFFFFFF;				
			replace GraphWalls /
				gradient_direction = "XAxis"
				startcolor = colors('headerfg')
				endcolor = colors('headerfg');
			/*replace GraphFloor /
				background = colors('headerfg')
				transparency = 0.0;
			replace GraphCharts from GraphCharts /
				transparency = 0.0;*/
			end;
		run;

		/** Create HAXIS Value/Order String **/
		%local valorder;
		%do i = %eval(&graph_months) - 1 %to 0 %by -1;
			data _null_;
				temp = intnx('month', input(substr("&procdatew",1,7),monyy7.), -&i);
				call symputx('valorder', catx(' ', "&valorder", cats("'", put(temp, monyy7.), "'")));
			run;
		%end;

		data _null_;
			x = 10000 + 89999 * ranuni(0);
			call symputx('eid', 'All');
			call symputx('uniquename', cats('gAll', x));
			call symputx('ini_display', 'inline');
		run;

		proc means data = tngraph sum nway noprint;
			class billing_period_str;
			var tn_count;
			output out = cur_entity(drop=_type_ _freq_) sum=;
		run;

		data cur_entity;
			set cur_entity;
			entity_id = 'All';
			drill = cats('TITLE="', billing_period_str, '&#013', "&entity_display_type", ':&#160;', catx(' ', 'All', "&entity_display_type"), 's&#013TNs:&#160;', put(tn_count, comma12.), '" HREF="#"');
		run;

		/** Custom Y-Axis scaling **/
		data rangedef (keep=tn_count);
			set cur_entity;
		run;

		proc sort data = rangedef;
			by tn_count;
		run;

		data rangedef;
			set rangedef;
			by tn_count;
			if last.tn_count;
		run;

		data _null_;
			set rangedef;
			if tn_count > 0 then do;
				max_interval = 100000000;
				length yaxis_max 8. interval 8.;
				do x = 0 to log10(max_interval);
					if (tn_count / (max_interval*(10**-x))) > = 1 then do;
						major = max_interval*(10**-x);
						leave;
					end;
				end;
				if round(ceil(tn_count/major), 1) >= 5 then interval = round(major, 1);
				else interval = round(major / 2, 1);
				if tn_count / round(major*ceil(tn_count/major),major) >= .9 then do;
					yaxis_max = round(major*ceil(tn_count/major),major) + interval;
				end;
				else do;
					yaxis_max = round(major*ceil(tn_count/major),major);
				end;
				call symput('toprange', yaxis_max);
				call symput('byvar', interval);
			end;
			else do;
				call symput('toprange', 100000);
				call symput('byvar', 10000);
			end;
		run;
						
		/** Output graph image to temp catalog **/
		goptions reset;
		ods html body="E:\imd\web_server\admin\graphs\&uniquename..html" path=&_tmpcat (URL=&_REPLAY) rs=none style=Saturn
			PARAMETERS=("DRILLDOWNMODE"="URL" "DRILLTARGET"="_self"	"TIPMODE"="HTML" "showbackdrop"="true" "backdropcolor"="#FFFFFF");
		goptions device=actximg ftext=tahoma htext=2 xpixels=500 ypixels=225 cback=white;

		/***********************/
		/** Line Chart Option **/
		/***********************
		proc gplot data = cur_entity imagemap=imagemap;
			plot tn_count*billing_period_str=entity_id/overlay frame caxis=cxA4A8AE autovref cvref=cxE9E9E9 legend=legend1 haxis=axis1 vaxis=axis2 name="&uniquename" html=drill;
			symbol1 v=dot line=1 h=.7 i=spline c=cx006699; 
			symbol2 v=dot line=1 h=.7 i=spline;
			symbol3 v=dot line=1 h=.7 i=spline;
			axis1 label=(h=0 pct '') c=black  value=(&valorder) order=(&valorder);
			axis2 label=(a=90 r=0 f=zapfb c=black h=4 pct '') c=black width=2 order=(0 to &toprange by &byvar);
			legend1 label=('') down=0 position=(top outside center);
					
		run;
		quit;
		/** End Line Chart Option **/

		/**********************/
		/** Bar Chart Option **/
		/**********************/
		goptions colors=(&bar_color_scale);
		proc gchart data = cur_entity;
	    	vbar billing_period_str/sumvar=tn_count frame caxis=cxA4A8AE raxis=axis2 maxis=axis1 name="&uniquename" html=drill
					patternid=midpoint discrete /*shape=block*/ width=2 cautoref="CXE8E5EA" wautoref=0.1 coutline="CXFFFFFF" /*cframe="CXDEDDED"*/ noframe autoref clipref cref= dagr;
			axis1 label=(h=0 pct '') c=black  value=(&valorder) order=(&valorder);
			axis2 label=(a=90 r=0 f=zapfb c=black h=4 pct '') c=black width=2 order=(0 to &toprange by &byvar);
		run;
		quit;
		/** End Bar Chart Option **/

		ods html close;
		ods listing;

		/** Read in graph file (eliminate a lot of the auto-generated HTML) **/
		%let delete_before = -1;
		data tempgraph(compress=yes);
			length text $1500.;
			infile "E:\imd\web_server\admin\graphs\&uniquename..html" TRUNCOVER dlm='|' LRECL= 1500;
			input text;
			if index(text, '&amp;') > 0 then text = tranwrd(text, '&amp;', '&');
			/** Remove header, CSS, and ending html tags **/
			if index(text, '</script> ') > 0 then call symputx('delete_before', _n_);
			if index(text, '</body>') > 0 then delete;
			if index(text, '</html>') > 0 then delete;
		run;

		data tempgraph;
			set tempgraph;
			if (_n_ <= %eval(&delete_before)) then delete;
		run;

		/** Construct GraphIMG DIVs - by default show only the "All" graph **/
		data graphdiv1;
			length text $1500.;
			text = cats('<div id="GraphIMGx1', '" style="display: ', "&ini_display" ,';">'); output;
		run;

		data graphdiv2;
			length text $1500.;
			text = '</div>'; output;
		run;

		data tempgraph;
			length entity_type entity_id $50.;
			set graphdiv1 tempgraph graphdiv2;
			entity_type = trim("&tn_type");
			entity_id = trim("&eid");
		run;				

		/** Delete the html output file from E:\ drive **/
		/*%let rc=%sysfunc(filename(myRef,E:\imd\web_server\admin\graphs\&uniquename..html)); 
		%let sysrc=%sysfunc(fdelete(&myRef));*/

		data reportdata3;
			length text $1500.;
			set tempgraph end=last;
			if _n_ = 1 then do;
				text = cats('<div class="web-part-container">',
							'<div class="web-part-title">Verizon TN Count</div>',
							'<div class="web-part-filter-text">September 2013, TN Type: Wireline</div>',
							'<div class="web-part-content">',
							text);
			end;
			else if last then do;
				text = cats(text,
							'</div>',
							'</div>');
			end;
		run;

		/** Create a standard data set for output **/
		data web_part(keep=text);
			length text $5000.;
			set reportdata3;
		run;

	%end;

/*****************************************************************************************************************************/
/** Sample Verizon SLA Snapshot Table																						**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 9998 %then %do;
		
		%let procdatew = SEP2013N;
		%let reportname = SLA Snapshot;
		/*****************************************************/
		/** Wireline Service Classes 						**/
		/*****************************************************/
		data _null_;
			call symput('wireline_sclass', "'0','1','2','3','4','5','6','7','9','A'");
		run;
		/*****************************************************/
		/** Wireless Service Classes 						**/
		/*****************************************************/
		data _null_;
			call symput('wireless_sclass', "'8','G','H','W','X'");
		run;
		/*****************************************************/
		/** VoIP Service Classes	 						**/
		/*****************************************************/
		data _null_;
			call symput('voip_sclass', "'C','D','E','F','J','K','V'");
		run;
		/*****************************************************/
		/** Hover text displayed on links that are only		**/
		/** visible to internal Intrado users				**/
		/*****************************************************/
		data _null_;
			call symput('internal_link_title', "This link is only available to internal Intrado users");
		run;

		%if "&reportname"="SLA Snapshot" %then %do;
			data _null_;
				/** If it's the first of the month then set procdate to previous month **/
				if day(today()) < 2 then call symput('monthlag', -1);
				else call symput('monthlag', 0);
			run;

			data _null_;
				call symputx('procdatew', cats(put(intnx('month', today(), &monthlag), monyy7.), 'N'));
				call symput('internal_link_title', "The SLA Snapshot is an internal-only report");
				call symputx('fromSN', 'Y');
			run;

			data snapshot;
				length sla_name $1000.;
				length sla_met2 $1500.;
				length system $100.;
			run;
		%end;
		%else %do;
			%if not %symexist(fromSN) %then %do;
				data _null_;
					call symputx('fromSN', 'N');
				run;
			%end;
		%end;

		/**********************************************************************/
		/** This is Measurement 2: DBMC Flow Through Rates Report Processing **/
		/**********************************************************************/
		%if "&reportname"="Measurement 2: DBMC Flow Through Rates" %then %do;

			data _null_;
	      		procdate = input(substr("&procdatew",1,7),monyy7.);
	      		call symputx('comptable','vztables.companytable' || put(procdate,mmyyn4.));
				if (intnx('month',today(),-1)=intnx('month',procdate,0) and day(today())<3) or (intnx('month',today(),0)=intnx('month',procdate,0)) then do;
					call symputx('thewarehouse','vzsoi.soiwarehouse');
				end;
	  			else call symputx('thewarehouse','vzsoimth.soiwarehouse' || put(procdate,mmyyn4.));
	        	%if %eval(&level) = 1 %then %do;
	        		call symputx('classstr','compname');
	        		call symputx('sortvar','thesort compname');
					call symputx('keepvar','compname goodsoi errorsoi totsoi pcterr_str filecount proctime_str pctflow_str sla_met');
					call symputx('labelvar',"compname='Company Name' goodsoi='Valid<br>Records' errorsoi='Flow<br>Through<br>Error<br>Records' totsoi='Total<br>Flow<br>Through<br>Records' pcterr_str='% of<br>Records in<br>Error'" || 
										   "filecount='Total<br>Flow<br>Through<br>Files' proctime_str='Average<br>Processing<br>Minutes per<br>File' pctflow_str='% Flow<br>Through' sla_met='SLA<br>Met'");
					call symputx('num_tables', 2);
	      		%end;
	     		%if %eval(&level) = 2 %then %do;
	        		call symputx('classstr','filename');
	        		call symputx('sortvar','descending thesort filename');
					call symputx('keepvar','&classstr goodsoi errorsoi totsoi pcterr_str filecount proctime_str pctflow_str');
					call symputx('labelvar','&classstr="Filename" goodsoi="Valid<br>Records" errorsoi="Flow<br>Through<br>Error<br>Records" totsoi="Total<br>Flow<br>Through<br>Records" pcterr_str="% of<br>Records in<br>Error"' || 
										   'filecount="Total<br>Flow<br>Through<br>Files" proctime_str="Processing<br>Minutes" pctflow_str="% Flow<br>Through"');
					call symputx('num_tables', 1);
	        	%end;
	    	run;

			data soidata;
	  			set &thewarehouse;
				if input(substr("&procdatew",1,7),monyy7.) <= procdate < intnx('month', input(substr("&procdatew",1,7),monyy7.), 1);
				if (flowthrough = 'Y' or flowthrough = '') and special = 'N';
				totsoi = sum(errorsoi,goodsoi);
			run;

			proc sort data = soidata;
				by compid;
			run;

			proc sort data = &comptable out = comptable(drop=telcotype);
				by compid;
			run;

			data soidata;
		  		merge soidata(in=a) comptable (in=b);
		  		by compid;
		  		if a;
		  		if not b then compname = 'Default Report Group';
				%if %eval(&level) = 2 %then %do;
	        		if compname = trim("&compname");
	      		%end;
			run;

			proc means data = soidata missing nway sum max noprint;
				class compname filename;
				var procdate errorsoi goodsoi totsoi received completed aliupdate;
				output out = soidata (drop=_type_ _freq_) sum(errorsoi goodsoi totsoi)= max(procdate received completed aliupdate)=;
			run;

			data soidata;
		  		set soidata;
				filecount = 1;
				if received = . then received = completed;
				if aliupdate ne . then completed = aliupdate;
				proctime = completed - received;
			run;

			proc means data = soidata missing sum noprint;
		    	class &classstr;
		    	var goodsoi errorsoi totsoi filecount proctime;
		    	output out = soisum (drop = _freq_) sum(goodsoi errorsoi totsoi filecount)= mean(proctime)=;
		    run;

		    data reportdata1 reportdata2 reportdata3;
				retain &keepvar;
				length &classstr $500. pctflow_str pcterr_str $50. proctime_str $1500. sla_met $1500.;
				set soisum;
				if totsoi > 0 then do;
					pctflow = goodsoi / totsoi;
					if pctflow = 1 then pctflow_str = '100%';
					else if pctflow > 0 then pctflow_str = cats(put(pctflow, percent8.1));
					else pctflow_str = '0%';
					pcterr = errorsoi / totsoi;
					if pcterr = 1 then pcterr_str = '100%';
					else if pcterr > 0 then pcterr_str = cats(put(pcterr, percent8.1));
					else pcterr_str = '0%';
					if pctflow >= .95 then sla_met = 'Y';
					else do;
						%if "&review"="Y" %then %do;
							sla_met = cats('<a href="', "&overall", '&level=2&procdatew=', "&procdatew", '&pass=compname=', trim(compname), '::Flowthrough=', 'Less than 95 percent::">N</a>');
						%end;
						%else %do;
							sla_met = 'N';
						%end;
					end;
				end;
				else do;
					pctflow = 2;
					pcterr = 2;
					pctflow_str = 'N/A';
					pcterr_str = 'N/A';
					sla_met = 'Y';
				end;
				if proctime >= 0 then proctime_str = put(proctime / 60, comma8.2);
				else proctime_str = cats('<a href="#" style="text-decoration: none; color: #000000;" title="Negative processing time is result of not maintaining filename sequence" onclick="return false;">', put(proctime / 60, comma8.2), '</a>');
				if upcase(&classstr) = 'DEFAULT REPORT GROUP' then thesort = 2;
				else thesort = 1;
				%if %eval(&level) = 1 %then %do;
					if _type_ = 0 then do;
						&classstr = 'Total';
						output reportdata3;
					end;
					else if upcase(&classstr) = 'VERIZON' then output reportdata1;
					else do;
						&classstr = cats('<span style="width: 100%; text-align: left;">', &classstr, '</span>');
						output reportdata2;
					end;
				%end;
				%if %eval(&level) = 2 %then %do;
					if pctflow < .95;
					if _type_ = 0 then delete;
					else do;
						thesort = pcterr;
						output reportdata1;
					end;
				%end;
				format &classstr $500. goodsoi errorsoi totsoi filecount comma12. proctime comma8.2;
				label &labelvar;
	    	run;

			proc sort data = reportdata1;
		    	by &sortvar;
		    run;
		
			proc sort data = reportdata2;
	    		by &sortvar;
	    	run;

			proc sort data = reportdata3;
	    		by &sortvar;
	    	run;

			data reportdata1(keep=&keepvar);
				set reportdata1;
			run;

			data reportdata2(keep=&keepvar drop=sla_met);
				set reportdata2;
			run;

			data reportdata3(keep=&keepvar drop=sla_met);
				set reportdata3;
			run;

			data _null_;
				call symput('totaldata', "N");
			run;		

		%end;

		/******************************************************************/
		/** This is Metric 1 and Metric 2 Availability Report Processing **/
		/******************************************************************/
		%if "&reportname"="Metric 1: ALI Availability" or
			"&reportname"="Metric 2: 9-1-1 NET Availability" or
			"&reportname"="Metric 2: IUP Availability" or
			"&reportname"="Metric 2: TSS Availability" or 
			"&reportname"="SLA Snapshot" %then %do;

			%if "&reportname" ne "SLA Snapshot" %then %do;
				/**********************************/
				/** This is the number of months **/
				/** available in the first table **/
				/**********************************/
				data _null_;
					call symputx('num_months', 3);
				run;

				data _null_;
					call symputx('num_loop', "&num_months");
				run;

				*** Metric 1 and Metric 2 Reports All Levels ***;
				data _null_;
					procdate = input(substr("&procdatew",1,7),monyy7.);
					call symputx('procdate', put(procdate, monyy7.));
					%if "&reportname"="Metric 1: ALI Availability" %then %do;
						call symputx('system', "ALI");
					%end;
					%else %if "&reportname"="Metric 2: 9-1-1 NET Availability" %then %do;
						call symputx('system', "9-1-1 NET");
					%end;
					%else %if "&reportname"="Metric 2: IUP Availability" %then %do;
						call symputx('system', "IUP");
					%end;
					%else %if "&reportname"="Metric 2: TSS Availability" %then %do;
						call symputx('system', "TSS");
					%end;
				run;
			%end;
			%else %do;
				/*************************************/
				/** This is the number of systems 	**/
				/** to loop through for SLA Snapshot**/
				/*************************************/
				data _null_;
					call symputx('num_systems', 4);
				run;

				data _null_;
					call symputx('num_loop', "&num_systems");
				run;
			%end;

			%do i = 1 %to %eval(&num_loop);
				data _null_;
					%if "&reportname"="SLA Snapshot" %then %do;	
						if %eval(&i) = 1 then do;
							call symputx('system', 'ALI');
							call symput('sla_name', "Metric 1: ALI Availability");
						end;
						else if %eval(&i) = 2 then do;
							call symputx('system', '9-1-1 NET');
							call symput('sla_name', "Metric 2: 9-1-1 NET Availability");
						end;
						else if %eval(&i) = 3 then do;
							call symputx('system', 'IUP');
							call symput('sla_name', "Metric 2: IUP Availability");
						end;
						else if %eval(&i) = 4 then do;
							call symputx('system', 'TSS');
							call symput('sla_name', "Metric 2: TSS Availability");
						end;
						procdate = intnx('month', input("&procdatew", monyy7.), 0, 'beginning');
					%end;
					%else %do;
						procdate = intnx('month', input("&procdate", monyy7.), -(&i - 1), 'beginning');
					%end;
					x = input(cats(put(intnx('month', procdate, 1, 'beginning'), date9.), ':00:00:00'), datetime18.);
					/** For APR2012 - the go-live month - calculate back to the go-live dates **/
					if procdate = '01APR2012'd then do;
						if "&system"="ALI" then do;
							y = '24APR2012:00:00:00'dt;
						end;
						else do;
							y = '13APR2012:00:00:00'dt;
						end;
					end;
					else do;
						y = input(cats(put(intnx('month', procdate, 0, 'beginning'), date9.), ':00:00:00'), datetime18.);
					end;
					mth_mins = (x - y)/60;
					call symputx('mth_mins', mth_mins);
					call symputx('procmth', put(procdate, date9.));
				run;
				
				data outage(keep=sched_mins unsched_mins);
					set vzwbtst.system_outage_data;
					if system = "&system";
					procmth = intnx('month', input("&procmth", date9.), 0, 'beginning');
					procmth_end = intnx('month', input("&procmth", date9.), 0, 'end');
					date_start = intnx('month', datepart(start_dt), 0, 'beginning');
					date_end = intnx('month', datepart(end_dt), 0, 'beginning');
					if (date_start = procmth) or (date_end = procmth);
					sched_mins = 0;
					unsched_mins = 0;
					/** If the outage started in the reporting month, but ended in a future month **/
					if (date_start = procmth) and (date_end ne procmth) then do;
						if outage_type = 'Scheduled' then do;
							sched_mins = round((input(cats(put(procmth_end, date9.), ':23:59:59'), datetime18.) - start_dt)/60, 1);
						end;
						if outage_type = 'Unscheduled' then do;
							unsched_mins = round((input(cats(put(procmth_end, date9.), ':23:59:59'), datetime18.) - start_dt)/60, 1);
						end;
					end;
					/** If the outage started in a past month, but ended in the reporting month **/
					else if (date_start ne procmth) and (date_end = procmth) then do;
						if outage_type = 'Scheduled' then do;
							sched_mins = round((end_dt - input(cats(put(procmth, date9.), ':00:00:00'), datetime18.))/60, 1);
						end;
						if outage_type = 'Unscheduled' then do;
							unsched_mins = round((end_dt - input(cats(put(procmth, date9.), ':00:00:00'), datetime18.))/60, 1);
						end;
					end;
					/** If the outage started and ended in the reporting month **/
					else do;
						if outage_type = 'Scheduled' then do;
							sched_mins = round((end_dt - start_dt)/60, 1);
						end;
						if outage_type = 'Unscheduled' then do;
							unsched_mins = round((end_dt - start_dt)/60, 1);
						end;
					end;
				run;

				proc sql noprint;
					select count(*) into: nrec_m
					  from outage;
				quit;
				run;

				%if %eval(&nrec_m) = 0 %then %do;
					data outage;
						sched_mins = 0;
						unsched_mins = 0;
					run;
				%end;

				proc means data = outage sum nway noprint missing;
					var sched_mins unsched_mins;
					output out = outagesum(drop=_type_ _freq_) sum=;
				run;

				data outagesum(keep=procmth avail_mins unsched_mins pct_avail sla_met);
					set outagesum;
					length sla_met $3.;
					procmth = input("&procmth", date9.);
					if procmth >= '01APR2012'd;
					if sched_mins = . then sched_mins = 0;
					if unsched_mins = . then unsched_mins = 0;
					avail_mins = input("&mth_mins", 8.) - sched_mins;
					if avail_mins > 0 then do;
						pct_avail = (avail_mins - unsched_mins) / avail_mins;
						%if "&system"="ALI" %then %do;
						if pct_avail >= .99999 then sla_met = 'Y';
						%end;
						%else %do;
						if pct_avail >= .9999 then sla_met = 'Y';
						%end;
						else sla_met = 'N';
					end;
					else do;
						pct_avail = 0;
						sla_met = 'N/A';
					end;
					format procmth monyy7.;
				run;

				%if "&reportname"="SLA Snapshot" %then %do;
					data outagesum;
						set outagesum;
						length sla_name $100.;
						length system $100.;
						sla_name = trim("&sla_name");
						system = trim("&system");
					run;
				%end;

				%if %eval(&i) = 1 %then %do;
					data reportdata1;
						set outagesum;
					run;
				%end;
				%else %do;
					data reportdata1;
						set reportdata1 outagesum;
					run;
				%end;
			%end;

			%if "&reportname" ne "SLA Snapshot" %then %do;
			data reportdata1(keep=str_procmth avail_mins unsched_mins str_pct_avail sla_met2);
			%end;
			%else %do;
			data reportdata1(keep=str_procmth avail_mins unsched_mins str_pct_avail sla_met2 sla_name system);
			%end;
				retain str_procmth avail_mins unsched_mins str_pct_avail sla_met2;
				set reportdata1;
				length str_procmth $25. str_pct_avail $50. sla_met2 $1500.;
				str_procmth = catx(' ', put(procmth, monname.), put(procmth, year4.));
				/** Allow internal users to drill to the internal system availability report if SLA_MET=N **/
				length sla_met2 $1500.;
				%if "&review"="Y" %then %do;
					%let fwd = /Reporting Tools/Verizon/Internal Reports/System Availability;
					overall2 = tranwrd("&overall", "&_program", "&fwd");
					if sla_met = 'N' then do;
						sla_met2 = '<a title="'|| "&internal_link_title" ||'" 
									href="'|| trim(overall2) ||'&level=2&procdatew='|| put(procmth, monyy7.) ||'N&fromSN='|| "&fromSN" ||'&pass=Date='|| put(procmth, monyy7.) || '::System=' || "&system" || '::">' || trim(sla_met) ||'</a>';;
					end;
					else do;
						sla_met2 = sla_met;
					end;
				%end;
				%else %do;
					sla_met2 = sla_met;
				%end;
				%if "&system"="ALI" %then %do;
					str_pct_avail = compress(put(pct_avail, percent9.3));
				%end;
				%else %do;
					str_pct_avail = compress(put(pct_avail, percent9.2));
				%end;
				if str_pct_avail in ('100.00%', '100.0%') then str_pct_avail = '100%';
				label str_procmth = 'Month' avail_mins = 'Available Minutes' unsched_mins = 'Unscheduled Minutes' str_pct_avail = '% Availability' sla_met2 = 'SLA Met';
				format avail_mins unsched_mins comma12.;
			run;

			%if "&reportname" ne "SLA Snapshot" %then %do;
				/** Calculate the Year-to-Date **/
				data _null_;
					procdate = intnx('month', input("&procdate", monyy7.), 0, 'beginning');
					x = input(cats(put(intnx('month', procdate, 1, 'beginning'), date9.), ':00:00:00'), datetime18.);
					/** For 2012 - the go-live year, calculate back to the go-live dates **/
					if substr("&procdate", 4, 4) = '2012' then do;
						if "&system"="ALI" then do;
							y = '24APR2012:00:00:00'dt;
						end;
						else do;
							y = '13APR2012:00:00:00'dt;
						end;
					end;
					else do;
						y = input(cats(put(intnx('year', procdate, 0, 'beginning'), date9.), ':00:00:00'), datetime18.);
					end;
					ytd_mins = (x - y)/60;
					call symputx('ytd_mins', ytd_mins);
					call symputx('ytdmth', put(procdate, date9.));
				run;

				data ytd(keep=sched_mins unsched_mins);
					set vzwbtst.system_outage_data;
					if system = "&system";
					ytd_start = intnx('year', input("&ytdmth", date9.), 0, 'beginning');
					ytd_end = intnx('month', input("&ytdmth", date9.), 0, 'end');
					date_start = intnx('day', datepart(start_dt), 0);
					date_end = intnx('day', datepart(end_dt), 0);
					if (date_start >= ytd_start and date_start <= ytd_end) or (date_end >= ytd_start and date_end <= ytd_end);
					sched_mins = 0;
					unsched_mins = 0;
					/** If the outage started in the YTD, but ended in the future (makes sense if you've seen the entire Back to the Future trilogy) **/
					if (date_end > ytd_end) then do;
						if outage_type = 'Scheduled' then do;
							sched_mins = round((input(cats(put(ytd_end, date9.), ':23:59:59'), datetime18.) - start_dt)/60, 1);
						end;
						if outage_type = 'Unscheduled' then do;
							unsched_mins = round((input(cats(put(ytd_end, date9.), ':23:59:59'), datetime18.) - start_dt)/60, 1);
						end;
					end;
					/** If the outage started prior to the YTD, but ended in the YTD **/
					else if (date_start < ytd_start) then do;
						if outage_type = 'Scheduled' then do;
							sched_mins = round((end_dt - input(cats(put(ytd_start, date9.), ':00:00:00'), datetime18.))/60, 1);
						end;
						if outage_type = 'Unscheduled' then do;
							unsched_mins = round((end_dt - input(cats(put(ytd_start, date9.), ':00:00:00'), datetime18.))/60, 1);
						end;
					end;
					/** If the outage started and ended in the YTD **/
					else do;
						if outage_type = 'Scheduled' then do;
							sched_mins = round((end_dt - start_dt)/60, 1);
						end;
						if outage_type = 'Unscheduled' then do;
							unsched_mins = round((end_dt - start_dt)/60, 1);
						end;
					end;
					format date_start date_end ytd_start ytd_end date9.;
				run;

				proc sql noprint;
					select count(*) into: nrec_y
					  from ytd;
				quit;
				run;

				%if %eval(&nrec_y) = 0 %then %do;
					data ytd;
						sched_mins = 0;
						unsched_mins = 0;
					run;
				%end;

				proc means data = ytd sum nway noprint missing;
					var sched_mins unsched_mins;
					output out = ytdsum(drop=_type_ _freq_) sum=;
				run;

				data reportdata2(keep=avail_mins unsched_mins str_pct_avail);
					retain avail_mins unsched_mins str_pct_avail;
					set ytdsum;
					length str_pct_avail $10.;
					if sched_mins = . then sched_mins = 0;
					if unsched_mins = . then unsched_mins = 0;
					avail_mins = input("&ytd_mins", 8.) - sched_mins;
					if avail_mins > 0 then do;
						pct_avail = (avail_mins - unsched_mins) / avail_mins;
					end;
					else do;
						pct_avail = 0;
					end;
					%if "&system"="ALI" %then %do;
						str_pct_avail = compress(put(pct_avail, percent9.3));
					%end;
					%else %do;
						str_pct_avail = compress(put(pct_avail, percent9.2));
					%end;
					if str_pct_avail in ('100.00%', '100.0%') then str_pct_avail = '100%';
					label avail_mins = 'YTD Available Minutes' unsched_mins = 'YTD Unscheduled Minutes' str_pct_avail = '% YTD Availablity';
					format avail_mins unsched_mins comma12.;
				run;

				data _null_;
					call symput('num_tables', 2);
				run;

				data _null_;
					call symput('totaldata', "N");
				run;
			%end;
			%else %do;
				data snapshot;
					set snapshot reportdata1;
				run;
			%end;

			/** All Levels **/
			%if "&fromSN"="Y" %then %do;
				data _null_;
					call symput('selections', 'N');
				run;
			%end;				

		%end;

		/********************************************************************************/
		/** This is Metric 3: Elapsed Time to Post TN Record Updates Report Processing **/
		/********************************************************************************/
		%if "&reportname"="Metric 3: Elapsed Time to Post TN Record Updates" or "&reportname"="SLA Snapshot" %then %do;

			*** Elpased Time to Post TN Record Updates - Level 1 ***;
			%if %eval(&level) = 1 %then %do;
				data _null_;
					procdate = input(substr("&procdatew",1,7), monyy7.);
					call symput('procmmyy',put(intnx("month",procdate,0), mmyyn4.));
					call symput('datevar',put(intnx("month",procdate,0), monyy7.));
					if (intnx('month',today(),-1)=intnx('month',procdate,0) and day(today())<3) or (intnx('month',today(),0)=intnx('month',procdate,0)) then do;
						call symput('thewarehouse','vzsoi.soiwarehouse;if intnx(''month'', procdate, 0, ''beginning'') = intnx(''month'', input(substr("&procdatew",1,7),monyy7.), 0, ''beginning'')');
					end;
	  				else call symput('thewarehouse','vzsoimth.soiwarehouse' || put(procdate,mmyyn4.));
				run;

				data soi(keep=filename alirec elapsed_gt_1hr elapsed_time);
					set &thewarehouse;
					if special = "N";
				run;

				/** The "avg time to process a record" calculation uses a normalized method that	**/
				/** assures the average record processing time does not exceed the avegrage	file	**/
				/** processing time found in the SOI Statistics report.								**/
				proc means data = soi sum nway noprint missing;
					class filename;
					var alirec elapsed_gt_1hr elapsed_time;
					output out = soisum(drop=_type_ _freq_) sum=;
				run;

				data soisum;
					set soisum;
					if alirec > 0 then avgproctime = (elapsed_time/alirec)/60;
					else avgproctime = 0;
				run;

				proc means data = soisum sum mean nway noprint missing;
					var alirec elapsed_gt_1hr avgproctime;
					output out = soisum(drop=_type_ _freq_) sum(alirec elapsed_gt_1hr)= mean(avgproctime)=;
				run;

				data reportdata1(keep=alirec elapsed_gt_1hr elapsed_lt_1hr pct_lt_1hr_str avg_time sla_met2);
					retain alirec elapsed_gt_1hr elapsed_lt_1hr pct_lt_1hr_str avg_time sla_met2;
					set soisum;
					avg_time = trim(catx(' ', put(avgproctime, 10.2), 'minutes'));
					elapsed_lt_1hr = alirec - elapsed_gt_1hr;
					pct_lt_1hr = elapsed_lt_1hr / alirec;
					length pct_lt_1hr_str $50.;
					if pct_lt_1hr = 1 then pct_lt_1hr_str = '100%';
					else pct_lt_1hr_str = cats(substr(compress(put(pct_lt_1hr, percent12.9)), 1, 5), '%');
					if pct_lt_1hr < 1 then sla_met = 'N';
					else sla_met = 'Y';
					length sla_met2 $1500.;
					/** Allow internal users to drill to out-of-metric data if SLA_MET=N **/
					%if "&review"="Y" %then %do;
						if sla_met = 'N' then do;
							sla_met2 = '<a title="'|| "&internal_link_title" ||'" href="'|| "&overall" ||'&level=2&procdatew='|| "&procdatew" ||'&fromSN='|| "&fromSN" ||'&pass=Date='|| "&datevar" || '::">' || sla_met ||'</a>';;
						end;
						else do;
							sla_met2 = sla_met;
						end;
					%end;
					%else %do;
						sla_met2 = sla_met;
					%end;
					format alirec elapsed_gt_1hr elapsed_lt_1hr comma12.;
					label alirec = 'Total TNs Posted' elapsed_gt_1hr = 'Posted greater<br>than 1 Hour' elapsed_lt_1hr = 'Posted within<br>1 Hour' 
			  		  	  pct_lt_1hr_str = '% Posted<br>within 1 Hour' avg_time = 'Average Time<br>to Post' sla_met2 = 'SLA Met';
				run;

				data _null_;
					call symput('totaldata', "N");
				run;

				%if "&reportname"="SLA Snapshot" %then %do;
					data reportdata1;
						set reportdata1;
						sla_name = "Metric 3: Elapsed Time to Post TN Record Updates";
					run;

					data snapshot;
						set snapshot reportdata1;
					run;
				%end;

			%end;

			*** Elpased Time to Post TN Record Updates - Level 2 ***;
			%if %eval(&level) = 2 %then %do;
				%if "&review"="Y" %then %do;
					data _null_;
						procdate = input(substr("&procdatew",1,7),monyy7.);
						call symput('procmmyy',put(intnx("month",procdate,0),mmyyn4.));
						call symput('datevar',put(intnx("month",procdate,0), monyy7.));
						if (intnx('month',today(),-1)=intnx('month',procdate,0) and day(today())<3) or (intnx('month',today(),0)=intnx('month',procdate,0)) then do;
							call symput('thewarehouse','vzsoi.soiwarehouse;if intnx(''month'', procdate, 0, ''beginning'') = intnx(''month'', input(substr("&procdatew",1,7),monyy7.), 0, ''beginning'')');
						end;
	  					else call symput('thewarehouse','vzsoimth.soiwarehouse' || put(procdate,mmyyn4.));
					run;
					
					data soi(keep=procdate filename goodsoi errorsoi alirec elapsed_gt_1hr received aliupdate);
						set &thewarehouse;
						if special = "N";
					run;

					proc means data = soi sum max nway noprint missing;
						class procdate filename received;
						var errorsoi goodsoi alirec elapsed_gt_1hr aliupdate;
						output out = soisum(drop=_type_ _freq_) sum(errorsoi goodsoi alirec elapsed_gt_1hr)= max(aliupdate)=;
					run;

					data reportdata1(keep=procdate filename errorsoi goodsoi alirec elapsed_gt_1hr2 received fileproctime);
						retain procdate filename errorsoi goodsoi alirec elapsed_gt_1hr2 received fileproctime;
						set soisum;
						if elapsed_gt_1hr > 0;
						fileproctime = (aliupdate - received)/60;
						elapsed_gt_1hr2 = '<a href="'|| "&overall" ||'&level=3&procdatew='|| put(procdate, date9.) ||'N&fromSN='|| "&fromSN" ||
											'&pass=' || "&pass" || 'Filename='|| trim(filename) || '::ALIDate='|| put(procdate, date9.) ||'::">' || compress(put(elapsed_gt_1hr, comma12.)) ||'</a>';
						format procdate mmddyy10. errorsoi goodsoi alirec comma12. received mdyampm. fileproctime 8.2;
						label procdate = 'Processing<br>Date' filename = 'Filename' errorsoi = 'Error<br>Records' goodsoi = 'Valid<br>Records'
							  alirec = 'ALI Updates' elapsed_gt_1hr2 = 'ALI Updates<br>> 1 Hour' received = 'File<br>Received' fileproctime = 'File Processing<br>Minutes';
					run; 
				%end;
				%else %do;
					data reportdata1;
					run;
				%end;
				
				data _null_;
					call symput('totaldata', "N");
				run;

			%end;

			*** Elpased Time to Post TN Record Updates - Level 3 ***;
			%if %eval(&level) = 3 %then %do;
				%if "&review"="Y" %then %do;
					data _null_;
						procdate = input(substr("&procdatew",1,9),date9.);
						call symput('procmmdd',put(procdate, mmddyy4.));
					run;
					
					data soi(keep=compid state msagid tn elapsed_time);
						set vzsoiday.soi&procmmdd;
						if elapsed_gt_1hr > 0 and filename = trim("&Filename");
						if special = "N";
					run;

					proc sort data = soi;
						by descending elapsed_time;
					run;

					data reportdata1;
						retain compid state msagid tn elapsed_time;
						set soi;
						elapsed_time = elapsed_time/60;
						format elapsed_time 8.2;
						label compid = 'Company ID' state = 'State' msagid = 'MSAG' tn = 'TN' elapsed_time = 'Processing<br>Minutes';
					run;

					/** Only display &row_limit records before recommending export	**/
					%global rdnumrec;
					data _null_;
						call symput('rdnumrec',0);
					run;

					data _null_;
						call symput('rdnumrec', compress(_n_));
						set reportdata1;
					run;

					%if %eval(&rdnumrec) > &row_limit %then %do;
						data _null_;
							call symput('showexportrec',"Y");
							call symput('rdnumrec', put(input("&rdnumrec", 10.) -1, comma10.));
						run;
					%end;

					data reportdata1;
						%if &exportto = html %then %do;
						set reportdata1(firstobs = 1 obs = &row_limit);
						%end;
						%else %do;
						set reportdata1;
						%end;
					run;

					data _null_;
						call symput('warnlevel', "N");
					run;
				%end;
				%else %do;
					data reportdata1;
					run;
				%end;

				data _null_;
					call symput('totaldata', "N");
				run;

			%end;

		%end;

		/***********************************************************/
		/** This is Metric 4: ALI Records Found Report Processing **/
		/***********************************************************/
		%if "&reportname"="Metric 4: ALI Records Found" or "&reportname"="SLA Snapshot" %then %do;

			data _null_;
				procdate = input(substr("&procdatew",1,7),monyy7.);
				call symput('procmmyy',put(intnx("month",procdate,0),mmyyn4.));
				call symput('datevar',put(intnx("month",procdate,0), monyy7.));
				if (intnx('month',today(),-1)=intnx('month',procdate,0) and day(today())<3) or (intnx('month',today(),0)=intnx('month',procdate,0)) then do;
					call symput('thewarehouse','vzali.aliwarehouse;if intnx(''month'', biddate, 0, ''beginning'') = intnx(''month'', input(substr("&procdatew",1,7),monyy7.), 0, ''beginning'');if manual = "N";totnrf=nrf');
				end;
	  			else call symput('thewarehouse','vzalimth.alirptwarehouse' || put(procdate,mmyyn4.) || ';totbids = sum(of h0-h23)');
			run;

			*** ALI Records Found Report - Level 1 ***;
			%if %eval(&level) = 1 %then %do;
				data ali(keep=totbids totnrf);
					set &thewarehouse;
				run;

				proc means data = ali sum nway noprint missing;
					var totbids totnrf;
					output out = alisum(drop=_type_ _freq_) sum=;
				run;

				data reportdata1(keep=totbids totnrf pct_found_str sla_met2);
					retain totbids totnrf pct_found_str sla_met2;
					set alisum;
					/*pct_found = round((totbids - totnrf) / totbids, .001);*/
					pct_found = (totbids - totnrf) / totbids;
					length pct_found_str $50.;
					if pct_found = 1 then pct_found_str = '100%';
					else pct_found_str = cats(substr(compress(put(pct_found, percent12.9)), 1, 4), '%');
					if pct_found < .993 then sla_met = 'N';
					else sla_met = 'Y';
					length sla_met2 $1500.;
					/** Allow internal users to drill to out-of-metric data if SLA_MET=N **/
					%if "&review"="Y" %then %do;
						if sla_met = 'N' then do;
							sla_met2 = '<a title="'|| "&internal_link_title" ||'" href="'|| "&overall" ||'&level=2&procdatew='|| "&procdatew" ||'&fromSN='|| "&fromSN" ||'&pass=Date='|| "&datevar" || '::">' || sla_met ||'</a>';;
						end;
						else do;
							sla_met2 = sla_met;
						end;
					%end;
					%else %do;
						sla_met2 = sla_met;
					%end;
					format totbids totnrf comma12.;
					label totbids = 'Total ALI Bids' totnrf = 'Total NRFs' pct_found_str = '% ALI Records Found' sla_met2 = 'SLA Met';
				run;

				data _null_;
					call symput('totaldata', "N");
				run;

				%if "&reportname"="SLA Snapshot" %then %do;
					data reportdata1;
						set reportdata1;
						sla_name = "Metric 4: ALI Records Found";
					run;

					data snapshot;
						set snapshot reportdata1;
					run;
				%end;

			%end;

			*** ALI Records Found Report - Level 2 ***;
			%if %eval(&level) = 2 %then %do;
				%if "&review"="Y" %then %do;
					data ali(keep=statename state totbids totnrf);
						set &thewarehouse;
						length statename $100.;
						state = put(state, $RealState.);
						if stnamel(state) ne '' then statename = stnamel(state);
						else do;
							statename = 'ZZDRG';
							state = '';
						end;
					run;

					proc means data = ali sum noprint missing;
						class statename state;
						var totbids totnrf;
						ways 0 2;
						output out = alisum sum=;
					run;

					data reportdata1(keep=statename2 totnrf nrf_pct) totals1(keep=statename2 totnrf nrf_pct);
						retain statename2 totnrf nrf_pct;
						set alisum;
						if totbids > 0 then nrf_pct = totnrf/totbids;
						else nrf_pct = 0;
						length statename2 $1500.;
						if totnrf > 0 then do;
							statename2 = '<a href="'|| "&overall" ||'&level=3&procdatew='|| "&procdatew" ||'&fromSN='|| "&fromSN" ||'&pass=Date='|| "&datevar" || '::State='|| trim(state) ||'::">' || 
										 tranwrd(statename, 'ZZDRG', 'Default Report Group') ||'</a>';
						end;
						else statename2 = tranwrd(statename, 'ZZDRG', 'Default Report Group');
						format totnrf comma12. nrf_pct percent9.2;
						label statename2 = 'State' totnrf = 'NRF' nrf_pct = 'NRF Rate';
						if _type_ = 0 then do;
							statename2 = 'Total';
							output totals1;
						end;
						else output reportdata1;
					run;

					proc sort data = reportdata1;
						by descending nrf_pct statename2;
					run;
				%end;
				%else %do;
					data reportdata1;
					run;

					data _null_;
						call symput('totaldata', "N");
					run;
				%end;
			%end;

			*** ALI Records Found Report - Level 3 ***;
			%if %eval(&level) = 3 %then %do;
				%if "&review"="Y" %then %do;
					data ali(keep=psapid totbids totnrf);
						set &thewarehouse;
						state = put(state, $RealState.);
						if stnamel(state) = '' then state = '';
						if state = "&State";
					run;

					proc means data = ali sum noprint missing;
						class psapid;
						var totbids totnrf;
						output out = alisum sum=;
					run;

					data reportdata1(keep=psapid totnrf nrf_pct) totals1(keep=psapid totnrf nrf_pct);
						retain psapid totnrf nrf_pct;
						set alisum;
						if totbids > 0 then nrf_pct = totnrf/totbids;
						else nrf_pct = 0;
						format totnrf comma12. nrf_pct percent9.2;
						label psapid = 'PSAP' totnrf = 'NRF' nrf_pct = 'NRF Rate';
						if _type_ = 0 then do;
							psapid = 'Total';
							output totals1;
						end;
						else output reportdata1;
					run;

					proc sort data = reportdata1;
						by descending nrf_pct psapid;
					run;
				%end;
				%else %do;
					data reportdata1;
					run;

					data _null_;
						call symput('totaldata', "N");
					run;
				%end;
			%end;

		%end;

		/*******************************************************************/
		/** This is Metric 5: Response Time for ALI Dip Report Processing **/
		/*******************************************************************/
		%if "&reportname"="Metric 5: Response Time for ALI Dip" or "&reportname"="SLA Snapshot" %then %do;

			*** Response Time for ALI Dip Report - Level 1 ***;
			%if %eval(&level) = 1 %then %do;
				data _null_;
					procdate = input(substr("&procdatew",1,7),monyy7.);
					call symput('procmmyy',put(intnx("month",procdate,0),mmyyn4.));
					call symput('datevar',put(intnx("month",procdate,0), monyy7.));
					if (intnx('month',today(),-1)=intnx('month',procdate,0) and day(today())<3) or (intnx('month',today(),0)=intnx('month',procdate,0)) then do;
						call symput('thewarehouse','vzali.sclasswarehouse;if intnx(''month'', biddate, 0, ''beginning'') = intnx(''month'', input(substr("&procdatew",1,7),monyy7.), 0, ''beginning'')');
					end;
	  				else call symput('thewarehouse','vzalimth.sclasswarehouse' || put(procdate,mmyyn4.));
				run;

				data ali(keep=tech_type totbids gt_2_sec gt_5_sec gt_10_sec);
					set &thewarehouse;
					length tech_type $20.;
					if sclass in(&wireline_sclass) then tech_type = 'Wireline';
					if sclass in (&wireless_sclass) then tech_type = 'Wireless';
					if sclass in (&voip_sclass) then tech_type = 'VoIP';
					if tech_type ne '';
				run;

				proc means data = ali sum nway noprint missing;
					class tech_type;
					var totbids gt_2_sec gt_5_sec gt_10_sec;
					output out = alisum(drop=_type_ _freq_) sum=;
				run;

				data reportdata1(keep=tech_type totbids resp_wi_2 pct_2_str sla_2_met2 resp_wi_5 pct_5_str sla_5_met2);
					retain tech_type totbids resp_wi_2 pct_2_str sla_2_met2 resp_wi_5 pct_5_str sla_5_met2;
					set alisum;
					if tech_type in ('Wireline');
					resp_wi_2 = totbids - gt_2_sec;
					pct_2 = resp_wi_2 / totbids;
					if pct_2 >= .95 then sla_2_met = 'Y';
					else sla_2_met = 'N';
					resp_wi_5 = totbids - gt_5_sec;
					pct_5 = resp_wi_5 / totbids;
					if pct_5 >= 1 then sla_5_met = 'Y';
					else sla_5_met = 'N';
					length pct_2_str pct_5_str $50.;
					if pct_2 = 1 then pct_2_str = '100%';
					else pct_2_str = cats(substr(put(pct_2, percent12.9), 1, 5), '%');
					if pct_5 = 1 then pct_5_str = '100%';
					else pct_5_str = cats(substr(put(pct_5, percent12.9), 1, 5), '%');
					length sla_2_met2 $1500. sla_5_met2 $1500.;
					/** Allow internal users to drill to out-of-metric data if SLA_MET=N **/
					%if "&review"="Y" %then %do;
						if sla_2_met = 'N' then do;
							sla_2_met2 = '<a title="'|| "&internal_link_title" ||'" 
										 href="'|| "&overall" ||'&level=2&procdatew='|| "&procdatew" ||'&m=2&fromSN='|| "&fromSN" ||'&pass=ResponseType='|| trim(tech_type) ||'::GreaterThan=2sec::">' || compress(sla_2_met) ||'</a>';
						end;
						else sla_2_met2 = sla_2_met;
					%end;
					%else %do;
						sla_2_met2 = sla_2_met;
					%end;
					%if "&review"="Y" %then %do;
						if sla_5_met = 'N' then do;
							sla_5_met2 = '<a title="'|| "&internal_link_title" ||'" href="'|| "&overall" ||'&level=2&procdatew='|| "&procdatew" ||'&m=5&fromSN='|| "&fromSN" ||'&pass=ResponseType='|| trim(tech_type) ||'::GreaterThan=5sec::">' || compress(sla_5_met) ||'</a>';
						end;
						else sla_5_met2 = sla_5_met;
					%end;
					%else %do;
						sla_5_met2 = sla_5_met;
					%end;
					format totbids resp_wi_2 resp_wi_5 comma12.;
					label tech_type = 'Response<br>Type' totbids = 'Total<br>Responses' resp_wi_2 = 'Responses<br>within 2 sec' pct_2_str = '%<br>within 2 sec' 
			  			  sla_2_met2 = '2 sec<br>SLA Met' resp_wi_5 = 'Responses<br>within 5 sec' pct_5_str = '%<br>within 5 sec' sla_5_met2 = '5 sec<br>SLA Met';
				run;

				data reportdata2(keep=tech_type totbids resp_wi_10 pct_10_str sla_10_met2);
					retain tech_type totbids resp_wi_10 pct_10_str sla_10_met2;
					set alisum;
					if tech_type in ('Wireless', 'VoIP');
					resp_wi_10 = totbids - gt_10_sec;
					pct_10 = resp_wi_10 / totbids;
					if pct_10 >= 1 then sla_10_met = 'Y';
					else sla_10_met = 'N';
					length pct_10_str $50.;
					if pct_10 = 1 then pct_10_str = '100%';
					else pct_10_str = cats(substr(put(pct_10, percent12.9), 1, 5), '%');
					length sla_10_met2 $1500.;
					/** Allow internal users to drill to out-of-metric data if SLA_MET=N **/
					%if "&review"="Y" %then %do;
						if sla_10_met = 'N' then do;
							sla_10_met2 = '<a class="tooltip" title="'|| "&internal_link_title" ||'" 
										 href="'|| "&overall" ||'&level=2&procdatew='|| "&procdatew" ||'&m=10&fromSN='|| "&fromSN" ||'&pass=ResponseType='|| trim(tech_type) ||'::GreaterThan=10sec::">' || compress(sla_10_met) ||'</a>';
						end;
						else sla_10_met2 = sla_10_met;
					%end;
					%else %do;
						sla_10_met2 = sla_10_met;
					%end;
					format totbids resp_wi_10 comma12. pct_10 percent8.2;
					label tech_type = 'Response<br>Type' totbids = 'Total<br>Responses' resp_wi_10 = 'Responses<br>within 10 sec' pct_10_str = '%<br>within 10 sec' sla_10_met2 = '10 sec<br>SLA Met';
				run;

				proc sort data = reportdata2;
					by descending tech_type;
				run;

				data _null_;
					call symput('num_tables', 2);
				run;

				data _null_;
					call symput('totaldata', "N");
				run;

				%if "&reportname"="SLA Snapshot" %then %do;
					data snapshot;
						set snapshot reportdata1 reportdata2;
						if tech_type = 'Wireline' then do;
							if sla_2_met2 ne 'Y' then sla_met2 = sla_2_met2;
							else if sla_5_met2 ne 'Y' then sla_met2 = sla_5_met2;
							else sla_met2 = sla_2_met2;
							sla_name = 'Metric 5: Response Time for ALI Dip - Wireline';
						end;
						else if tech_type = 'Wireless' then do;
							sla_met2 = sla_10_met2;
							sla_name = 'Metric 5: Response Time for ALI Dip - Wireless';
						end;
						else if tech_type = 'VoIP' then do;
							sla_met2 = sla_10_met2;
							sla_name = 'Metric 5: Response Time for ALI Dip - VoIP';
						end;
					run;
				%end;

			%end;

			*** Response Time for ALI Dip Report - Level 2 ***;
			%if %eval(&level) = 2 %then %do;
				%if "&review"="Y" %then %do;
					data _null_;
						procdate = input(substr("&procdatew",1,7),monyy7.);
						call symput('procmmyy',put(intnx("month",procdate,0),mmyyn4.));
						if (intnx('month',today(),-1)=intnx('month',procdate,0) and day(today())<3) or (intnx('month',today(),0)=intnx('month',procdate,0)) then do;
							call symput('thewarehouse','vzali.sclasswarehouse;if intnx(''month'', biddate, 0, ''beginning'') = intnx(''month'', input(substr("&procdatew",1,7),monyy7.), 0, ''beginning'')');
						end;
	  					else call symput('thewarehouse','vzalimth.sclasswarehouse' || put(procdate,mmyyn4.));
					run;

					data ali(keep=biddate gt_&m._sec);
						set &thewarehouse;
						length tech_type $20.;
						if sclass in(&wireline_sclass) then tech_type = 'Wireline';
						if sclass in (&wireless_sclass) then tech_type = 'Wireless';
						if sclass in (&voip_sclass) then tech_type = 'VoIP';
						if tech_type = "&ResponseType" and gt_&m._sec > 0;
					run;

					proc means data = ali sum missing noprint;
						class biddate;
						var gt_&m._sec;
						output out = alisum sum=;
					run;

					data reportdata1(keep=biddate2 gt_&m._sec) totals1(keep=biddate2 gt_&m._sec);
						retain biddate2 gt_&m._sec;
						set alisum;
						if _type_ ne 0 then do;
							length biddate2 $1500.;
							biddate2 = '<a href="'|| "&overall" ||'&level=3&procdatew='|| "&procdatew" ||'&m='|| "&m" ||'&fromSN='|| "&fromSN" ||'&pass=ResponseType='|| "&ResponseType" ||'::GreaterThan='|| "&m" ||'sec::Date='|| put(biddate, date9.) || '::">' || 
										put(biddate, mmddyy10.) ||'</a>';
							output reportdata1;
						end;
						else do;
							biddate2 = 'Total';
							output totals1;
						end;
						format gt_&m._sec comma12.;
						label biddate2 = 'Bid Date' gt_&m._sec = "Greater<br>than &m sec";
					run;
				%end;
				%else %do;
					data reportdata1;
					run;

					data _null_;
						call symput('totaldata', "N");
					run;
				%end;
		
			%end;

			*** Response Time for ALI Dip Report - Level 3 ***;
			%if %eval(&level) = 3 %then %do;
				%if "&review"="Y" %then %do;
					data _null_;
						procdate = input("&Date",date9.);
						call symput('procmmdd',put(procdate,mmddyy4.));
					run;

					data ali(keep=biddt sysnode state psapid tn manual base resp_time2);
						set vzaliday.ali&procmmdd;
						length tech_type $20. tn $10. resp_time2 $50.;
						if servclass in(&wireline_sclass) then tech_type = 'Wireline';
						if servclass in (&wireless_sclass) then tech_type = 'Wireless';
						if servclass in (&voip_sclass) then tech_type = 'VoIP';
						if tech_type = "&ResponseType" and resp_time > input("&m", 8.);
						tn = cats(npa, nxx, line);
						resp_time2 = catx(' ', put(resp_time, 8.2), 'seconds');
					run;

					proc format;
						picture dtap low-high ='%m/%d/%Y %I:%0M:%0S %p' (datatype = datetime);
					run;

					data reportdata1;
						retain biddt sysnode state psapid tn manual base resp_time2;
						set ali;
						format biddt dtap.;
						label biddt = 'Bid Date<br>and Time' sysnode = 'ALI Node' state = 'State' psapid = 'PSAP' tn = 'TN' manual = 'Manual' base = 'Base' resp_time2 = 'Response<br>Time';
					run;

					proc sort data = reportdata1;
						by biddt psapid tn;
					run;
				%end;
				%else %do;
					data reportdata1;
					run;
				%end;
					data _null_;
						call symput('totaldata', 'N');
					run;

					data _null_;
						call symput('warnlevel', 'N');
					run;
			%end;	

		%end;

		/*******************************************************************************************/
		/** This is Metric 9: User Workflow Ticket Response and Resolution Time Report Processing **/
		/*******************************************************************************************/
		%if "&reportname"="Metric 9: User Workflow Ticket Response and Resolution Time" or "&reportname"="SLA Snapshot" %then %do;
			
			*** User Workflow Ticket Response and Resolution Time Report - Level 1 ***;
			%if %eval(&level) = 1 %then %do;
				data _null_;
					procdate = input(substr("&procdatew",1,7),monyy7.);
					if intnx('month', today(), -1, 'beginning') = intnx('month', procdate, 0, 'beginning') or
					   intnx('month', today(), 0, 'beginning') = intnx('month', procdate, 0, 'beginning') then do;
						call symput('thewarehouse', 'vzwfl.slawarehouse');
					end;
					else do;
						call symput('thewarehouse', cats('vzwflmth.slawarehouse', put(procdate, mmyyn4.)));
					end;
					call symput('procdate', put(intnx('month', procdate, 0, 'end'), date9.));
					call symput('datevar', put(procdate, monyy7.));
				run;

				/** If report is SLA Snapshot then update the &procdate variable to the last good day of workflow processing **/
				%if "&reportname"="SLA Snapshot" %then %do;
					data workflow_log;
						set vzwflday.validate_log;
						if intnx('month', procdate, 0, 'beginning') = intnx('month', input(substr("&procdatew",1,7),monyy7.), 0, 'beginning');
						if status_priority = 0;
					run;

					proc sort data = workflow_log;
						by procdate;
					run;

					data _null_;
						set workflow_log end=last;
						if last then call symput('procdate', put(procdate, date9.));
					run;
				%end;
		
				data tickets;
					set &thewarehouse;
					if procdate = input("&procdate", date9.);
				run;

				proc means data = tickets sum noprint missing;
					class priority_cat;
					var num_tix responded responded_ontime resolved resolved_ontime;
					output out = ticketsum sum=;
				run;

				data reportdata1(keep=priority_cat2 num_tix responded_ontime pct_responded_ontime_str resolved_ontime pct_resolved_ontime_str sla_met2)
		 			 totals1(keep=priority_cat2 num_tix responded_ontime pct_responded_ontime_str resolved_ontime pct_resolved_ontime_str sla_met2);
					retain priority_cat2 num_tix responded_ontime pct_responded_ontime_str resolved_ontime pct_resolved_ontime_str sla_met2;
					length pct_responded_ontime_str pct_resolved_ontime_str $100. priority_cat2 $256. sla_met2 $1500.;
					set ticketsum;
					sla_met = 'Y';
					/** Calculate Percent On Time **/
					if num_tix > 0 then pct_responded_ontime = responded_ontime / num_tix;
					else pct_responded_ontime = 2;
					if resolved > 0 then pct_resolved_ontime = resolved_ontime / resolved;
					else pct_resolved_ontime = 2;
					if pct_responded_ontime = . then pct_responded_ontime = 0;
					if pct_resolved_ontime = . then pct_resolved_ontime = 0;
					/** Format Percent Change String and Calculate SLA **/
					if pct_responded_ontime <= 1 then do;
						pct_responded_ontime_str = compress(put(pct_responded_ontime, percent8.));
						if pct_responded_ontime < 1 then do;
							sla_met = 'N';
						end;
					end;
					else if pct_responded_ontime = 2 then do;
						pct_responded_ontime_str = 'N/A';
					end;
					if pct_resolved_ontime <= 1 then do;
						pct_resolved_ontime_str = compress(put(pct_resolved_ontime, percent8.));
						if pct_resolved_ontime < 1 then do;
							sla_met = 'N';
						end;
					end;
					else if pct_resolved_ontime = 2 then do;
						pct_resolved_ontime_str = 'N/A';
					end;				
					priority_cat2 = cats('<span style="width: 100px; text-align: left; font-weight: bold;">', priority_cat, '</span>');
					if _type_ = 0 then do;
						priority_cat2 = 'Total';
						/** Allow internal users to drill to out-of-metric data if SLA_MET=N **/
						%if "&review"="Y" %then %do;
							if sla_met = 'N' then do;
								sla_met2 = '<a title="'|| "&internal_link_title" ||'" href="'|| "&overall" ||'&level=2&procdatew='|| "&procdatew" ||'&fromSN='|| "&fromSN" ||
											'&pass=Date='|| "&datevar" ||'::Priority=All::OnTime=No::">' || compress(sla_met) ||'</a>';
							end;
							else sla_met2 = sla_met;
						%end;
						%else %do;
							sla_met2 = sla_met;
						%end;
						output totals1;
					end;
					else do;
						/** Allow internal users to drill to out-of-metric data if SLA_MET=N **/
						%if "&review"="Y" %then %do;
							if sla_met = 'N' then do;
								sla_met2 = '<a title="'|| "&internal_link_title" ||'" href="'|| "&overall" ||'&level=2&procdatew='|| "&procdatew" ||'&fromSN='|| "&fromSN" ||
											'&pass=Date='|| "&datevar" ||'::Priority='|| trim(urlencode(trim(priority_cat))) ||'::OnTime=No::">' || compress(sla_met) ||'</a>';
							end;
							else sla_met2 = sla_met;
						%end;
						%else %do;
							sla_met2 = sla_met;
						%end;
						output reportdata1;
					end;
					format num_tix responded_ontime resolved_ontime comma12. pct_resolved_ontime percent8.;
					label priority_cat2 = 'Priority' num_tix = 'Tickets<br>Opened' responded_ontime = 'Responded<br>On Time' pct_responded_ontime_str = '% Responded<br>On Time'
			  			  resolved_ontime = 'Resolved<br>On Time' pct_resolved_ontime_str = '% Resolved<br>On Time' sla_met2 = 'SLA Met';
				run;

				%if "&reportname"="SLA Snapshot" %then %do;
					data totals1;
						set totals1;
						length sla_name $1000.;
						sla_name = "Metric 9: User Workflow Ticket Response and Resolution Time";
					run;

					data snapshot;
						set snapshot totals1;
					run;
				%end;

			%end;

			*** User Workflow Ticket Response and Resolution Time Report - Level 2 ***;
			%if %eval(&level) = 2 %then %do;
				%if "&review"="Y" %then %do;
					data _null_;
						procdate = input(substr("&procdatew",1,7),monyy7.);
						call symput('procmmdd', put(intnx('month', procdate, 0, 'end'), mmddyy4.));
					run;

					/** If report is SLA Snapshot then update the &procdate variable to the last good day of workflow processing **/
					%if "&fromSN"="Y" %then %do;
						data workflow_log;
							set vzwflday.validate_log;
							if intnx('month', procdate, 0, 'beginning') = intnx('month', input(substr("&procdatew",1,7),monyy7.), 0, 'beginning');
							if status_priority = 0;
						run;

						proc sort data = workflow_log;
							by procdate;
						run;

						data _null_;
							set workflow_log end=last;
							if last then call symput('procmmdd', put(procdate, mmddyy4.));
						run;
					%end;

					data tickets;
						set vzwflday.workflow&procmmdd;
						if sla_ticket = 'Y';
						if (responded = 0 or responded_ontime = 0) or (resolved = 0 and due_date < datetime()) or (resolved = 1 and resolved_ontime = 0);
						if urldecode("&Priority") ne 'All' then do;
							if priority = input(substr("&Priority", 1, 1), 8.);
						end;
					run;

					data reportdata1(keep=ticket_number status2 request_type priority due_date completion_date2);
						retain ticket_number status2 request_type priority due_date completion_date2;
						set tickets;
						length completion_date2 $100. status2 $100.;
						if (responded = 0) or (responded_ontime = 0) then status2 = 'Responded Late';
						if resolved = 0 and due_date < datetime() then status2 = '<i>Pending (Late)</i>';
						if resolved = 1 and resolved_ontime = 0 then status2 = 'Resolved Late';
						if completion_date = . then completion_date2 = '';
						else completion_date2 = put(completion_date, mdyampm.);
						format due_date mdyampm.;
						label ticket_number = 'Ticket Number' status2 = 'Status' request_type = 'Request Type' priority = 'Priority' due_date = 'Due Date' completion_date2 = 'Completion Date';
					run;

					proc sort data = reportdata1;
						by ticket_number;
					run;

				%end;
				%else %do;
					data reportdata1;
					run;
				%end;
				data _null_;
					call symput('totaldata', 'N');
				run;
			%end;
		%end;

		/**************************************************/
		/** This is SLA Snapshot Report final Processing **/
		/**************************************************/
		%if "&reportname"="SLA Snapshot" %then %do;

			data reportdata1(keep=sla_name sla_met2);
				retain sla_name sla_met2;
				set snapshot;
				if sla_name ne '';
				length reportname $1000.;
				if index(sla_name, 'Metric 5:') > 0 then reportname = trim(scan(sla_name, 1, '-'));
				else reportname = trim(sla_name);
				/** Allow drill down to level 2 of the corrosponding SLA Report if SLA_MET=N **/
				if sla_met2 ne 'Y' then do;
					sla_met2 = trim(tranwrd(sla_met2, 'Internal Reports/SLA Snapshot', cats('Custom Reports/SLA Reports/', reportname)));
					sla_met2 = trim(tranwrd(sla_met2, 'title="&internal_link_title"', ''));
				end;
				sla_name = cats('<span style="width: 350px; text-align: left;">', sla_name, '</span>');
				if system ne '' then do;
					if sla_met ne 'Y' then do;
						sla_met2 = tranwrd(sla_met2, cats('::System=', "&system"), cats('::System=', system));
					end;
				end;
				label sla_name = 'SLA Name' sla_met2 = 'SLA Met';
			run;

			data reportdata1(keep=text);
				length text $5000.;
				set reportdata1 end=last;
				if _n_ = 1 then do;
					text = cats('<div class="web-part-container">',
								'<div class="web-part-title">Verizon SLA Snapshot</div>',
								'<div class="web-part-filter-text">September 2013 Month-to-date</div>',
								'<div class="web-part-content">',
								'<table class="content-table">',
								'<tr><th>SLA Name</th><th>SLA Met</th></tr>',
								'<tr><td>', sla_name, '</td><td style="text-align: center;">', sla_met2, '</td></tr>');
				end;
				else if not last then do;
					text = cats('<tr><td>', sla_name, '</td><td style="text-align: center;">', sla_met2, '</td></tr>');
				end;
				else if last then do;
					text = cats('<tr><td>', sla_name, '</td><td style="text-align: center;">', sla_met2, '</td></tr>',
								'</table>',
								'</div>',
								'</div>');
				end;
			run;

			data _null_;
				call symput('num_tables', 1);
			run;

			data _null_;
				call symput('selections', 'N');
			run;

			data _null_;
				call symput('totaldata', 'N');
			run;

			data _null_;
				call symput('warnlevel', "N");
			run;

			data _null_;
				call symput('linkheaders', 'Y');
			run;

			data addheader1;
				addlink = trim(catx(' ', put(input(substr("&procdatew",1,7),monyy7.), monname.), put(input(substr("&procdatew",1,7),monyy7.), year4.), 'Month-to-Date'));
			run;

		%end;

		/** Create a standard data set for output **/
		data web_part(keep=text);
			length text $5000.;
			set reportdata1;
		run;

	%end;

%exit: %mend dashboard_web_parts;
%dashboard_web_parts;