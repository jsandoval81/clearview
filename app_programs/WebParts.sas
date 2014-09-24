******************************************************************************************************************************;
** Program: DB02 - WebParts.sas																								**;
** Purpose: A compilation of all web parts used by this application server. Web Part IDs should still be unique across		**;
**			all application servers.																						**;
**																															**;
** Date: 01/01/2014																											**;
** Developer: John Sandoval																									**;
** Application Version: 2.0																									**;
**																															**;
** Data sources: Defined in Metadata																						**;
**																															**;
** Includes (pay attention to UNC vs. Relative pathing):																	**;
**  \\lmv08-metdb02\imd\web_server\admin\&app_version\programs\GlobalWebParts.sas											**;
**																															**;
** Notes:																													**;
** History:																													**;
**		01/01/2014 John Sandoval - Initial Release																			**;
**																															**;
******************************************************************************************************************************;

%macro web_parts;

	%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\GlobalWebParts.sas";

/*****************************************************************************************************************************/
/** ANI Failure Report web part																								**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 1050 %then %do;

		/********************************************/
		/** Define the attributes of this web part **/
		/********************************************/
		/** Level-independent attributes **/
		data _null_;
			call symputx('chart_enabled', 		'N');
			call symputx('date_format', 		'Monthly');
			call symputx('validate_log', 		'&ma.alimth.validate_log');
			call symputx('data_warehouse', 		'&ma.alimth.anifail&procmmyy');
			call symputx('where_clause', 		"where manual = 'N'");
			call symputx('page_alert', 			'N');
			call symputx('month_selection', 	'Y');
			call symputx('stack_select_labels',	'N');
			call symputx('refresh_on_select', 	'Y');
			call symputx('account_specific_uri','');
		run;

		/** Skip State level if single-state account **/
		%if "&single_state_account" = "Y" and %eval(&level) = 1 %then %let level = 2;

		/** Level-specific attributes **/
		data _null_;
			%if %eval(&level) = 1 %then %do;
				call symputx('report_type', 		'Summary');
				call symputx('group_by_vars', 		'state');
				call symputx('stat_vars', 			'esco seiz');
				call symputx('filter_clause', 		'');
				call symputx('sort_vars',			'state_sort');
				call symputx('totals_row', 			'Y');
			%end;
			%else %if %eval(&level) = 2 %then %do;
				call symputx('report_type', 		'Summary');
				call symputx('group_by_vars', 		'state essid');
				call symputx('stat_vars', 			'esco seiz');
				call symputx('filter_clause', 		'where state_val = trim(urldecode(trim("&state")))');
				call symputx('sort_vars',			'essid_sort');
				call symputx('totals_row', 			'Y');
			%end;
			%else %if %eval(&level) = 3 %then %do;
				call symputx('report_type', 		'Summary');
				call symputx('group_by_vars', 		'state essid psapid');
				call symputx('stat_vars', 			'esco seiz');
				call symputx('filter_clause', 		'where state_val = trim(urldecode(trim("&state"))) and essid_val = trim(urldecode(trim("&essid")))');
				call symputx('sort_vars',			'psapid_sort');
				call symputx('totals_row', 			'Y');
			%end;
			%else %if %eval(&level) = 4 %then %do;
				call symputx('report_type', 		'Record-Level');
				call symputx('group_by_vars', 		'state essid psapid npa nxx line biddt');
				call symputx('where_clause', 		"where manual = 'N' and &anifail = 1");
				call symputx('filter_clause', 		'where state_val = trim(urldecode(trim("&state"))) and essid_val = trim(urldecode(trim("&essid"))) and psapid_val = trim(urldecode(trim("&psapid")))');
				call symputx('sort_vars',			'biddate_sort');
				call symputx('totals_row', 			'N');
			%end;
		run;

		/*************************************/
		/** Set row-level data restrictions **/
		/*************************************/
		%let data_type = ('STATE', 'PSAPID');
		%data_restrictions;

		/*********************************************************/
		/** Set the selection variables if they don't yet exist **/
		/*********************************************************/
		/** PROCDATEV **/
		%if not %symexist(procdatev) %then %do;
			%set_procdate(&date_format);
		%end;

		/*************************************/
		/** Account specific configurations **/
		/*************************************/
		%if %symexist(account_specific_var) %then %do;
			%if "&account_specific_var" ne "" %then %do;

				/** Re-factor level-specific attributes and add an account-specific selection drop-down **/
				%account_specific_selections(&account_specific_var);

			%end;
		%end;

		/** Set state selection value for single-state accounts **/
		%if "&single_state_account" = "Y" %then %let state = &state_list;

		/********************************************************/
		/** Define dynamic date suffixes used to retrieve data **/
		/********************************************************/
		%let procdate = %substr(&procdatev, 1, 7);
		data _null_;
			call symputx('procmmyy', put(input("&procdate", monyy7.), mmyyn4.));
		run;

		/***************************************************************************/
		/** Generate and process the master data set for selections and filtering **/
		/***************************************************************************/
		%if "&report_type" = "Summary" %then %do;
			proc means data = &data_warehouse sum nway missing noprint;
				class &group_by_vars;
				var &stat_vars;
				&where_clause;
				output out = anifail (drop=_type_ _freq_) sum=;
			run;
		%end;
		%else %if "&report_type" = "Record-Level" %then %do;
			data anifail(keep=&group_by_vars);
				set &data_warehouse;
				&where_clause;
			run;
		%end;

		data anifail;
			set anifail;
			/** Level-specific data preparation **/
			%if %eval(&level) in 1 2 3 4 %then %do;
				length state_val state_name state_sort $50.;
				if stnamel(state) = '' then do;
					state_val = '';
					state_name = 'Default Report Group';
					state_sort = 'zzzzz';
				end;
				else do;
					state_val = state;
					state_name = stnamel(state);
					state_sort = state_name;
				end;
				call symputx('final_group_by', 'state_val state_name state_sort');
			%end;
			%if %eval(&level) in 2 3 4 %then %do;
				length essid_val essid_name essid_sort $50.;
				if compress(essid) = '' then do;
					essid_val = '';
					essid_name = 'Default Report Group';
					essid_sort = 'zzzzz';
				end;
				else do;
					essid_val = put(essid, $50.);
					essid_name = essid;
					essid_sort = essid;
				end;
				call symputx('final_group_by', 'essid_val essid_name essid_sort');
			%end;
			%if %eval(&level) in 3 4 %then %do;
				length psapid_val psapid_name psapid_sort $500.;
				if compress(psapid) = '' then do;
					psapid_val = '';
					psapid_name = 'Default Report Group';
					psapid_sort = 'zzzzz';
				end;
				else do;
					psapid_val = psapid;
					psapid_name = psapid;
					psapid_sort = psapid;
				end;
				call symputx('final_group_by', 'psapid_val psapid_name psapid_sort');
			%end;
			%if %eval(&level) = 4 %then %do;
				length biddate_val biddate_name biddate_sort $500.;
				if biddt = . then do;
					biddate_val = '';
					biddate_name = 'Blank';
					biddate_sort = 'zzzzz';
				end;
				else do;
					biddate_val = compress(biddt);
					biddate_name = put(biddt, mmddyytime.);
					biddate_sort = put(biddt, mmddyytime.);
				end;
				call symputx('final_group_by', 'biddate_val biddate_name biddate_sort');
			%end;
			&restrictions;
		run;
		
		/******************************/
		/** Generate drop-down menus **/
		/******************************/
		
		
		/*********************************************/
		/** Final data set filtering and processing **/
		/*********************************************/
		%if "&report_type" = "Summary" %then %do;
			proc means data = anifail sum nway missing noprint;
				class &final_group_by;
				var &stat_vars;
				&filter_clause;
				output out = anifail (drop=_type_ _freq_) sum=;
			run;
		%end;
		%else %do;
			data anifail;
				set anifail;
				&filter_clause;
			run;
		%end;

		/** Level-independent data sort **/
		proc sort data = anifail;
			by &sort_vars;
		run;

		/** Determine row count **/
		%let web_part_rows = 0;
		data _null_;
			set anifail end=last;
			if last then call symputx('web_part_rows', compress(_n_));
		run;

		/*************************************/
		/** Create the output source markup **/
		/*************************************/
		%if %eval(&web_part_rows) > 0 %then %do;
			/******************************/
			/** HTML Table Header values **/
			/******************************/
			data anifail_header(keep=header_value column_align);
				length header_value $100. column_align $10.;
				%if %eval(&level) in 1 2 3 %then %do;
					call symputx('table_title', '');
					%if %eval(&level) = 1 %then %do;
						header_value = 'State'; column_align = 'Left';		output;
					%end;
					%else %if %eval(&level) = 2 %then %do;
						header_value = 'ESSID';	column_align = 'Left';		output;
					%end;
					%else %if %eval(&level) = 3 %then %do;
						header_value = 'PSAP'; 	column_align = 'Left';		output;
					%end;
					header_value = 'ESCO'; 		column_align = 'Center';	output;
					header_value = 'Seizure'; 	column_align = 'Center';	output;
				%end;
				%else %do;
					if "&anifail" = "esco" then call symputx('table_title', 'ESCOs');
					else if "&anifail" = "seiz" then call symputx('table_title', 'Seizures');
					header_value = 'Bid Date'; 	column_align = 'Left';		output;
					header_value = 'NPA'; 		column_align = 'Center';	output;
					header_value = 'NXX'; 		column_align = 'Center';	output;
					header_value = 'Line'; 		column_align = 'Center';	output;
				%end;
			run;
			%standard_table_header_html(anifail_header, 1, centered, &table_title);

			/****************************/
			/** HTML Table Body values **/
			/****************************/
			%if %eval(&level) in 1 2 3 %then %do;
				data anifail_body(keep=group_var_1 esco_str seiz_str);
					retain group_var_1 esco_str seiz_str;
					set anifail;
					length group_var_1 esco_str seiz_str $1500.;
					%if %eval(&level) = 1 %then %do;
						group_var_1 = cats('<a href="', "&uri_prefix", '&amp;procdatev=', "&procdatev", '&amp;level=2&amp;state=', trim(urlencode(trim(state_val))), "&account_specific_uri", '">', state_name, '</a>');
					%end;
					%else %if %eval(&level) = 2 %then %do;
						group_var_1 = cats('<a href="', "&uri_prefix", '&amp;procdatev=', "&procdatev", '&amp;level=3&amp;state=', "&state", '&amp;essid=', trim(urlencode(trim(essid_val))), "&account_specific_uri", '">', essid_name, '</a>');
					%end;
					%else %if %eval(&level) = 3 %then %do;
						group_var_1 = psapid_val;
					%end;
					%if %eval(&level) in 1 2 %then %do;
						esco_str = put(esco, comma12.);
						seiz_str = put(seiz, comma12.);
					%end;
					%else %do;
						esco_str = cats(ifc(esco > 0,
											cats('<a href="', "&uri_prefix", '&amp;procdatev=', "&procdatev", '&amp;level=4&amp;state=', "&state", 
												 '&amp;essid=', "&essid", '&amp;psapid=', trim(urlencode(trim(psapid_val))), "&account_specific_uri", '&amp;anifail=esco">'),
											''),
										put(esco, comma12.),
										ifc(esco > 0,
											'</a>',
											'')
									);
						seiz_str = cats(ifc(seiz > 0,
										cats('<a href="', "&uri_prefix", '&amp;procdatev=', "&procdatev", '&amp;level=4&amp;state=', "&state",
											 '&amp;essid=', "&essid", '&amp;psapid=', trim(urlencode(trim(psapid_val))), "&account_specific_uri", '&amp;anifail=seiz">'),
										''),
										put(seiz, comma12.),
										ifc(seiz > 0,
											'</a>',
											'')
									);						
					%end;
				run;
			%end;
			%else %do;
				data anifail_body(keep=biddate_name npa nxx line);
					retain biddate_name npa nxx line;
					set anifail;
				run;
			%end;
			%standard_table_body_html(anifail_body);

			/******************************/
			/** HTML Table Footer values **/
			/******************************/
			%if "&totals_row" = "Y" %then %do;
				/** Create the totals data **/
				proc means data = anifail sum nway missing noprint;
					var &stat_vars;
					output out = anifail_footer (drop=_type_ _freq_) sum=;
				run;

				data anifail_footer(keep=total esco_str seiz_str);
					retain total esco_str seiz_str;
					set anifail_footer;
					total = 'Total';
					esco_str = put(esco, comma12.);
					seiz_str = put(seiz, comma12.);
				run;
				%standard_table_footer_html(anifail_footer);
			%end;
			%else %do;
				data anifail_footer(keep=text);
					length text $5000.;
					text = cats('</table>');
				run;
			%end;
		
			/** Create final Web Part data set **/
			data web_part;
				set anifail_header anifail_body anifail_footer;
			run;
		%end;

		/*************************************************************************************/
		/** If web part requested via AJAX then output the text immediately to the web page **/
		/*************************************************************************************/
		%if "&ajax_request" = "Y" %then %do;
			data _null_;
				file _webout lrecl = &lrecl;
				%if %eval(&web_part_rows) > 0 %then %do;
					set web_part;
					put text;
				%end;
				%else %do;
					put 'No web part content was generated';
				%end;
			run;
		%end;
		/*******************************************************************************/
		/** If web part was NOT requested via AJAX then finish adding page formatting **/
		/*******************************************************************************/
		%else %do;
			/*****************/
			/** Breadcrumbs **/
			/*****************/
			data breadcrumbs(keep=level link value);
				length link value $1500.;
				/** Breadcrumb link to Level 1 **/
				%if "&single_state_account" = "N" %then %do;
					level = 1;
					link = cats('<a href="', "&uri_prefix", '&amp;level=1&amp;procdatev=', "&procdatev", "&account_specific_uri", '">State</a>');
					value = trim(urldecode(trim("&state")));
					output;
				%end;
				/** Breadcrumb link to Level 2 **/
				level = 2;
				link = cats('<a href="', "&uri_prefix", '&amp;level=2&amp;procdatev=', "&procdatev", '&amp;state=', "&state", "&account_specific_uri", '">ESSID</a>');
				value = trim(urldecode(trim("&essid")));
				output;
				/** Breadcrumb link to Level 3 **/
				level = 3;
				link = cats('<a href="', "&uri_prefix", '&amp;level=3&amp;procdatev=', "&procdatev", '&amp;state=', "&state", '&amp;essid=', "&essid", "&account_specific_uri", '">PSAP</a>');
				value = trim(urldecode(trim("&psapid")));
				output;
			run;

			/***************************/
			/** Additional Javascript **/
			/***************************/
			/** SAMPLE JQUERY **/
			data jquery(keep=text);
				length text $1500.;
				text = '$jload(''#bottom-bar'').click(function(){'; output;
					text = 'alert(''SAMPLE: The bottom bar was clicked'');'; output;
				text = '});'; output;
			run;

			data _null_;
				set jquery end=last;
				retain temp;
				length temp $25000.;
				temp = cats(temp, '0D'x, trim(text));
				if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
			run;

			/** SAMPLE ONLOAD JQUERY **/
			data jquery(keep=text);
				length text $1500.;
				text = 'var sample = ''This is a global variable created on (document).ready'';'; output;
				/*text = 'alert(sample);'; output;*/
			run;

			data _null_;
				set jquery end=last;
				retain temp;
				length temp $25000.;
				temp = cats(temp, '0D'x, trim(text));
				if last then call symputx('onload_jquery', cats("&onload_jquery", '0D'x, trim(temp)));
			run;

		%end;

		
	%end;

/*****************************************************************************************************************************/
/** ANI Failure Report Chart container web part																			**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 1051 %then %do;
		
		/********************************************/
		/** Define the attributes of this web part **/
		/********************************************/
		/** Level-independent attributes **/
		data _null_;
			call symputx('chart_enabled', 		'Y');
			call symputx('date_format', 		'Monthly');
			call symputx('validate_log', 		'&ma.alimth.validate_log');
			call symputx('where_clause', 		"where manual = 'N'");
			call symputx('refresh_on_select', 	'Y');
		run;

		/** Level-specific attributes **/
		data _null_;
			%if %eval(&level) = 1 %then %do;
				call symputx('report_type', 		'Summary');
				call symputx('stat_vars', 			'esco seiz total_failures');
				call symputx('filter_clause', 		'');
				call symputx('totals_row', 			'Y');
			%end;
			%else %if %eval(&level) = 2 %then %do;
				call symputx('report_type', 		'Summary');
				call symputx('stat_vars', 			'esco seiz total_failures');
				call symputx('filter_clause', 		'');
				call symputx('totals_row', 			'Y');
			%end;
			%else %if %eval(&level) = 3 %then %do;
				call symputx('report_type', 		'Summary');
				call symputx('stat_vars', 			'esco seiz total_failures');
				call symputx('filter_clause', 		'if state = trim(urldecode(trim("&state")))');
				call symputx('totals_row', 			'Y');
			%end;
			%else %if %eval(&level) = 4 %then %do;
				call symputx('chart_enabled',		'N');
				call symputx('report_type', 		'Record-Level');
				call symputx('where_clause', 		"where manual = 'N'");
				call symputx('filter_clause', 		'if state = trim(urldecode(trim("&state"))) and psapid = trim(urldecode(trim("&psapid")))');
				call symputx('sort_vars',			'biddate_sort');
				call symputx('totals_row', 			'N');
			%end;
		run;

		/*************************************/
		/** Set row-level data restrictions **/
		/*************************************/
		%let data_type = ('STATE', 'PSAPID');
		%data_restrictions;

		/*********************************************************/
		/** Set the selection variables if they don't yet exist **/
		/*********************************************************/
		/** PROCDATEV **/
		%if not %symexist(procdatev) %then %do;
			%set_procdate(&date_format);
		%end;

		/*************************************/
		/** Account specific configurations **/
		/*************************************/
		%if %symexist(account_specific_var) %then %do;
			%if "&account_specific_var" ne "" %then %do;

				/** Re-factor level-specific attributes and add an account-specific selection drop-down **/
				%account_specific_selections(&account_specific_var);

			%end;
		%end;
		
		/********************************************************/
		/** Define dynamic date suffixes used to retrieve data **/
		/********************************************************/
		%let procdate = %substr(&procdatev, 1, 7);
		data _null_;
			call symputx('procmmyy', put(input("&procdate", monyy7.), mmyyn4.));
		run;

		/*************************************/
		/** Level-specific data preparation **/
		/*************************************/
		/** Level 1 - Month level **/
		%if %eval(&level) = 1 %then %do;

			%do loop_month = -11 %to 0;
	
				data _null_;
					call symputx('loopmmyy', put(intnx('month', input("&procdate", monyy7.), &loop_month), mmyyn4.));
				run;

				data anifail_temp(keep=esco seiz total_failures);
					set &ma.alimth.anifail&loopmmyy;
					&restrictions;
					&where_clause;
					&filter_clause;
					total_failures = (esco + seiz);
				run;

				%let num_anifail_recs = 0;
				data _null_;
					set anifail_temp end=last;
					if last then call symputx('num_anifail_recs', compress(_n_));
				run;

				%if %eval(&num_anifail_recs) > 0 %then %do;
					proc means data = anifail_temp sum nway missing noprint;
						var &stat_vars;
						output out = anifail_temp (drop=_type_ _freq_) sum=;
					run;

					data anifail_temp;
						set anifail_temp;
						length month $25. year $4. procdatev $7.;
						procdatev = put(intnx('month', input("&procdate", monyy7.), &loop_month), monyy7.);
						month = compress(put(intnx('month', input("&procdate", monyy7.), &loop_month), monname.));
						year = put(intnx('month', input("&procdate", monyy7.), &loop_month), year4.);
						/** Temp data adjust for Verizon Graph for Demo **/
						%if ("&ma" = "vz") and ("&loopmmyy" = "0613") %then %do;
							seiz = seiz - 200000;
							total_failures = total_failures - 200000;
						%end;
					run;
				%end;
				%else %do;
					data anifail_temp;
						procdatev = put(intnx('month', input("&procdate", monyy7.), &loop_month), monyy7.);
						month = compress(put(intnx('month', input("&procdate", monyy7.), &loop_month), monname.));
						year = put(intnx('month', input("&procdate", monyy7.), &loop_month), year4.);
						esco = 0;
						seiz = 0;
						total_failures = 0;
					run;
				%end;

				%if %eval(&loop_month) = -11 %then %do;
					data anifail;
						set anifail_temp;
					run;
				%end;
				%else %do;
					data anifail;
						set anifail anifail_temp;
					run;
				%end;

			%end;

		%end;
		/** Level 2 - State level **/
		%else %if %eval(&level) = 2 %then %do;

			/** Retreive the ANI Failure data **/
			data anifail;
				set &ma.alimth.anifail&procmmyy;
				&restrictions;
				&where_clause;
				length state_name $50.;
				if stnamel(state) = '' then do;
					state = '99';
					state_name = 'zzzzz';
				end;
				else do;
					state_name = stnamel(state);
				end;
				total_failures = (esco + seiz);
				&filter_clause;
			run;

			/** Summarize the ANI Failures by State **/
			proc means data = anifail sum nway missing noprint;
				class state_name state;
				var &stat_vars;
				output out = anifail (drop=_type_ _freq_) sum=;
			run;

			/** Assign custom values **/
			data anifail;
				set anifail;
				if state_name = 'zzzzz' then state_name = 'Default Report Group';
				%if ("&ma" = "vz") and ("&procmmyy" = "0613") %then %do;
					if state = 'CA' then do;
						seiz = seiz - 200000;
						total_failures = total_failures - 200000;
					end;
				%end;
			run;

		%end;
		/** Level 3 - PSAP level **/
		%if %eval(&level) = 3 %then %do;
			
			/** Retreive the ANI Failure data **/
			data anifail;
				set &ma.alimth.anifail&procmmyy;
				&restrictions;
				&where_clause;
				if stnamel(state) = '' then state = '99';
				if psapid = '' then psapid = 'zzzzz';
				total_failures = (esco + seiz);
				&filter_clause;
			run;

			/** Summarize the ANI Failures by PSAP **/
			proc means data = anifail sum nway missing noprint;
				class psapid;
				var &stat_vars;
				output out = anifail (drop=_type_ _freq_) sum=;
			run;

			/** Assign custom values **/
			data anifail;
				set anifail;
				if psapid = 'zzzzz' then psapid = 'Default Report Group';
				%if ("&ma" = "vz") and ("&procmmyy" = "0613") %then %do;
					if psapid = 'CA-WALNUT SO                 81040' then do;
						seiz = seiz - 200000;
						total_failures = total_failures - 200000;
					end;
				%end;
			run;

		%end;
		/** Level 4 - Record Level **/
		%if %eval(&level) = 4 %then %do;

			/** Retreive the ANI Failure data **/
			data anifail;
				set &ma.alimth.anifail&procmmyy;
				&restrictions;
				&where_clause;
				if stnamel(state) = '' then state = '99';
				if compress(psapid) = '' then psapid = 'zzzzz';
				length anifail_type $10.;
				if esco = 1 then anifail_type = 'ESCO';
				else if seiz = 1 then anifail_type = 'Seizure';
				else anifail_type = 'Other';
				&filter_clause;
			run;

		%end;

		/*****************/
		/** JSON Markup **/
		/*****************/
		%if ("&chart_enabled" = "Y") and ("&chart_plugin" = "Y") %then %do;

			/** Determine the total ESCO and Seizures for the series **/
			proc means data = anifail sum nway missing noprint;
				var esco seiz total_failures;
				output out = anifail_total (drop=_type_ _freq_) sum=;
			run;

			data _null_;
				set anifail_total;
				call symputx('total_esco', esco);
				call symputx('total_seiz', seiz);
				call symputx('total_anifail', total_failures);
			run;

			/** Construct a JSON series for Month, ESCO, and Seizure **/
			data anifail(keep=text);
				set anifail end=last;
				length text $5000.;
				length xaxis_label $100. total_failures 8.;
				length cat_series esco_series seiz_series tot_series $5000.;
				retain cat_series esco_series seiz_series tot_series;
				%if %eval(&level) = 1 %then %do;
					xaxis_label = cats(procdatev, catx(' ', substr(month, 1, 3),  substr(year, 3, 2)));
				%end;
				%else %if %eval(&level) = 2 %then %do;
					xaxis_label = cats(state, state_name);
				%end;
				%else %if %eval(&level) = 3 %then %do;
					xaxis_label = psapid;
				%end;
				/** Begin JSON markup **/
				if _n_ = 1 then do;
					if not last then do;
						cat_series = cats('"category": ["', xaxis_label, '"');
						esco_series = cats('"esco": [', esco);
						seiz_series = cats('"seiz": [', seiz);
						tot_series = cats('"total": [', total_failures);
					end;
					else do;
						cat_series = cats('"category": ["', xaxis_label, '"],');
						esco_series = cats('"esco": [', esco, '],');
						seiz_series = cats('"seiz": [', seiz, '],');
						tot_series = cats('"total": [', total_failures, '],');
					end;
				end;
				else if not last then do;
					cat_series = cats(cat_series, ',"', xaxis_label, '"');
					esco_series = cats(esco_series, ',', esco);
					seiz_series = cats(seiz_series, ',', seiz);
					tot_series = cats(tot_series, ',', total_failures);
				end;
				else if last then do;
					cat_series = cats(cat_series, ',"', xaxis_label, '"],');
					esco_series = cats(esco_series, ',', esco, '],');
					seiz_series = cats(seiz_series, ',', seiz, '],' );
					tot_series = cats(tot_series, ',', total_failures, '],' );
					
				end;
				if last then do;
					/** Compile markup into one statement that can be dropped into chart options **/
					text = cats('var jsonData = {',
								cat_series,
								esco_series,
								seiz_series,
								%if %eval(&level) in 1 2 %then %do;
									tot_series,
								%end;
								'"pie_total": [',
									'{"name": "ESCO", "y":', "&total_esco", '},',
									'{"name": "Seizure", "y":', "&total_seiz", '}',
								']',
							'}');
				output;
				end;
			run;

			/** Create the container web part for the chart plugin **/
			data web_part(keep=text);
				length text $5000.;
				text = '<div id="chart-container"></div>'; output;
				/** This div is for testing JSON output. In AJAX, disable datatype json and enable chart-container2 text **/
				text = '<div id="chart-container-json"></div>'; output;
			run;

		%end;
		/*****************/
		/** HTML Markup **/
		/*****************/
		%else %do;

			/** Determine row count **/
			%let web_part_rows = 0;
			data _null_;
				set anifail end=last;
				if last then call symputx('web_part_rows', compress(_n_));
			run;

			/** Create the output table markup **/			
			%if %eval(&web_part_rows) > 0 %then %do;
				/******************************/
				/** HTML Table Header values **/
				/******************************/
				data anifail_header(keep=header_value column_align);
					length header_value $100. column_align $10.;
					call symputx('table_title', '');
					%if %eval(&level) in 1 2 3 %then %do;
						%if %eval(&level) = 1 %then %do;
							header_value = 'Month'; column_align = 'Left';		output;
						%end;
						%else %if %eval(&level) = 2 %then %do;
							header_value = 'State';	column_align = 'Left';		output;
						%end;
						%else %if %eval(&level) = 3 %then %do;
							header_value = 'PSAP'; 	column_align = 'Left';		output;
						%end;
						header_value = 'ESCO'; 		column_align = 'Center';	output;
						header_value = 'Seizure'; 	column_align = 'Center';	output;
						header_value = 'Total'; 	column_align = 'Center';	output;
					%end;
					%else %do;
						header_value = 'Bid Date'; 	column_align = 'Left';		output;
						header_value = 'Type'; 		column_align = 'Center';	output;
						header_value = 'NPA'; 		column_align = 'Center';	output;
						header_value = 'NXX'; 		column_align = 'Center';	output;
						header_value = 'Line'; 		column_align = 'Center';	output;
					%end;
				run;
				%standard_table_header_html(anifail_header, 1, centered, &table_title);

				/****************************/
				/** HTML Table Body values **/
				/****************************/
				%if %eval(&level) in 1 2 3 %then %do;
					data anifail_body(keep=group_var_1 esco_str seiz_str total_str);
						retain group_var_1 esco_str seiz_str total_str;
						set anifail;
						length group_var_1 esco_str seiz_str total_str $1500.;
						%if %eval(&level) = 1 %then %do;
							group_var_1 = cats('<a href="', "&uri_prefix", '&amp;procdatev=', procdatev, '&amp;level=2', "&account_specific_uri", '">', catx(' ', month, year), '</a>');
						%end;
						%else %if %eval(&level) = 2 %then %do;
							group_var_1 = cats('<a href="', "&uri_prefix", '&amp;procdatev=', "&procdatev", '&amp;level=3&amp;state=', state, "&account_specific_uri", '">', state_name, '</a>');
						%end;
						%else %if %eval(&level) = 3 %then %do;
							group_var_1 = cats('<a href="', "&uri_prefix", '&amp;procdatev=', "&procdatev", '&amp;level=4&amp;state=', "&state", '&amp;psapid=', psapid, "&account_specific_uri", '">', psapid, '</a>');
						%end;
						esco_str = put(esco, comma12.);
						seiz_str = put(seiz, comma12.);
						total_str = put(total_failures, comma12.);
					run;
				%end;
				%else %do;
					data anifail_body(keep=biddate_name anifail_type npa nxx line);
						retain biddate_name anifail_type npa nxx line;
						set anifail;
						biddate_name = put(biddt, mmddyytime.);
					run;
				%end;
				%standard_table_body_html(anifail_body);

				/******************************/
				/** HTML Table Footer values **/
				/******************************/
				%if "&totals_row" = "Y" %then %do;
					/** Create the totals data **/
					proc means data = anifail sum nway missing noprint;
						var &stat_vars;
						output out = anifail_footer (drop=_type_ _freq_) sum=;
					run;

					data anifail_footer(keep=total esco_str seiz_str total_str);
						retain total esco_str seiz_str total_str;
						set anifail_footer;
						total = 'Total';
						esco_str = put(esco, comma12.);
						seiz_str = put(seiz, comma12.);
						total_str = put(total_failures, comma12.);
					run;
					%standard_table_footer_html(anifail_footer);
				%end;
				%else %do;
					data anifail_footer(keep=text);
						length text $5000.;
						text = cats('</table>');
					run;
				%end;

				/** Compile the table sections to a web part **/
				data web_part;
					set anifail_header anifail_body anifail_footer;
				run;
				
			%end;

		%end;

		/***************************/
		/** Additional Javascript **/
		/***************************/
		%if ("&chart_enabled" = "Y") and ("&chart_plugin" = "Y") %then %do;
			data chart_plugin_1;
				length text $5000.;
				text = 'function ANIFailChart() {'; output;
			run;

			data chart_plugin_2;
				length text $5000.;
				/** Begin defining the chart options **/
				text = cats(
				'var options = {',
					/** Chart Type **/
					'chart: {',
						'renderTo: "chart-container"',
					'},',
					/** Chart Title **/
					'title: {',
						'text: "",',
						'style: {',
							'color: "#A4A8AE",',
							'font: "bold 16px Calibri, Tahoma, sans-serif"',
						'}',
					'},',
					/** Chart Colors **/
					'colors: ["#58BFED","#1F81AD", "#0B4763", "#05212D"],',
					/** Tooltip **/
					'tooltip: {',
						'formatter: function() {',
							%if %eval(&level) = 1 %then %do;
							'var series_tip = ''<b>''+ this.x.substring(7) +''</b>'';',
							%end;
							%else %if %eval(&level) = 2 %then %do;
							'var series_tip = ''<b>''+ this.x.substring(2) +''</b>'';',
							%end;
							%else %if %eval(&level) = 3 %then %do;
							'var series_tip = ''<b>''+ this.x +''</b>'';',
							%end;
							'$jload.each(this.points, function(i, point) {',
								'if (i == 2) { color = "#808080"; }',
								'else { color = point.series.color; }', 
								'series_tip += ''<br/><span style="color:''+color+''">''+',
										'point.series.name +": "+',
										'point.y.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")+',
										'''</span>'';',
							'});',
							'return series_tip;',
						'},',
						'shared: true',
					'},',
					/** X-Axis Definition **/
					'xAxis: {',
						'categories: [],',
						'labels: {',
							'formatter: function() {',
								%if %eval(&level) = 1 %then %do;
								'return this.value.substring(7);',
								%end;
								%else %if %eval(&level) = 2 %then %do;
								'return this.value.substring(2);',
								%end;
								%else %if %eval(&level) = 3 %then %do;
								'return this.value;',
								%end;
							'},',
							%if %eval(&level) = 3 %then %do;
							'rotation: -55',
							%end;
							%else %do;
							'rotation: 0',
							%end;
						'}',
					'},',
					/** Y-Axis Definition **/
					'yAxis: {',
						'min: 0,',
						%if %eval(&total_anifail) = 0 %then %do;
							'max: 1,',
						%end;
						'title: {',
							'text: "Count"',
						'}',
					'},',
					/** Plot Options **/
					'plotOptions: {',
						'column: {',
							'cursor: "pointer",',
							'point: {',
								'events: {',
									'click: function() {',
										%if %eval(&level) = 1 %then %do;
										'location.href = "',
														"&uri_prefix_unencoded", '&level=2',
														'&procdatev="+', 'this.category.substring(0,7) +"',
														"&account_specific_uri_unencoded",
														'&chart_plugin=', "&chart_plugin",
														'";',
										%end;
										%else %if %eval(&level) = 2 %then %do;
										'location.href = "',
														"&uri_prefix_unencoded", '&level=3',
														'&procdatev=', "&procdatev",
														'&state="+', 'this.category.substring(0,2) +"',
														"&account_specific_uri_unencoded",
														'&chart_plugin=', "&chart_plugin",
														'";',
										%end;
										%else %if %eval(&level) = 3 %then %do;
										'location.href = "',
														"&uri_prefix_unencoded", '&level=4',
														'&procdatev=', "&procdatev",
														'&state=', "&state",
														'&psapid="+', 'this.category +"',
														"&account_specific_uri_unencoded",
														'&chart_plugin=', "&chart_plugin",
														'";',
										%end;
									'}',
								'}',
							'}',
						'}',
					'},',
					/** Labels **/
					'labels: {',
						'items: [',
							%if %eval(&total_anifail) > 0 %then %do;
							'{',
								'html: "Ratio",',
								'style: {',
									'left: "45px",',
									'top: "-10px",',
									'color: "black"',
								'}',
							'}',
							%end;
						']',
					'},',
					/** Series Definition **/
					'series: [{',
						'type: "column",',
						'name: "ESCO",',
						'data: []',
					'},{',
						'type: "column",',
						'name: "Seizure",',
						'data: []',
					'},{',
						'type: "pie",',
						'name: "Total",',
						'data: [],',
						'center: [40, 35],',
						'size: 100,',
						'dataLabels: {',
							'enabled: false',
						'}',
					'},{',
						'type: "spline",',
						'name: "Total ANI Failures",',
						'data: [],',
						'color: "#E4EAF2",',
						'marker: {',
							'lineWidth: 4,',
							'lineColor: "#89A7C9",',
							'fillColor: "white"',
						'}',
					'}]',

				/** END options var **/
				'}'); output;

				/*text = '$jload("#chart-container-json").text(JSON.stringify(jsonData));'; output;*/
				text = 'options.xAxis.categories = jsonData["category"];'; output;
				text = 'options.series[0].data = jsonData["esco"];'; output;
				text = 'options.series[1].data = jsonData["seiz"];'; output;
				text = 'options.series[2].data = jsonData["pie_total"];'; output;
				text = 'options.series[3].data = jsonData["total"];'; output;
				text = 'var chart = new Highcharts.Chart(options);'; output;

				/** END ANIFailure() method **/
				text = '}'; output;
			run;

			/** Compile data sets to an CHART_PLUGIN data set **/
			data chart_plugin(keep=text);
				length text $5000.;
				set chart_plugin_1 anifail chart_plugin_2;
			run;

			/** Set loading animation and chart method to run on page load **/
			data jquery(keep=text);
				length text $1500.;
				text = cats('$jload(''#chart-container'').html($jload(''#hidden-loading-container'').html());'); output;
				text = 'ANIFailChart();'; output;
			run;

			data _null_;
				set jquery end=last;
				retain temp;
				length temp $25000.;
				temp = cats(temp, '0D'x, trim(text));
				if last then call symputx('onload_jquery', cats("&onload_jquery", '0D'x, trim(temp)));
			run;
		%end;

		/*****************/
		/** Breadcrumbs **/
		/*****************/
		data breadcrumbs(keep=level link value);
			length link value $1500.;
			/** Breadcrumb link to Level 1 **/
			level = 1;
			link = cats('<a href="', "&uri_prefix", '&amp;level=1', "&account_specific_uri", '&chart_plugin=', "&chart_plugin", '">Month</a>');
				length month $25. year $4.;
				month = compress(put(intnx('month', input("&procdatev", monyy7.), 0), monname.));
				year = put(intnx('month', input("&procdatev", monyy7.), 0), year4.);
			value = catx(' ', substr(month, 1, 3), substr(year, 3, 2));
			output;
			/** Breadcrumb link to Level 2 **/
			level = 2;
			link = cats('<a href="', "&uri_prefix", '&amp;level=2&amp;procdatev=', "&procdatev", "&account_specific_uri", '&chart_plugin=', "&chart_plugin", '">State</a>');
				length state_name $50.;
				if trim(urldecode(trim("&state"))) ne '99' then state_name = stnamel(trim(urldecode(trim("&state"))));
				else state_name = 'Default Report Group';
			value = state_name;
			output;
			/** Breadcrumb link to Level 3 **/
			level = 3;
			link = cats('<a href="', "&uri_prefix", '&amp;level=3&amp;procdatev=', "&procdatev", '&amp;state=', "&state", "&account_specific_uri", '&chart_plugin=', "&chart_plugin", '">PSAP</a>');
			value = trim(urldecode(trim("&psapid")));
			output;
				
		run;

	%end;


%exit: %mend web_parts;
%web_parts;