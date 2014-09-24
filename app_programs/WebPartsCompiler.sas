******************************************************************************************************************************;
** Program: WebPartsCompiler.sas																							**;
** Purpose: To compile the web parts for a stored process and deliver the data sets back to the Global Container			**;
**																															**;
** Date: 01/01/2014																											**;
** Developer: John Sandoval																									**;
** Application Version: 2.0																									**;
**																															**;
** Data sources: Defined in Metadata																						**;
**																															**;
** Includes (pay attention to UNC vs. Relative pathing):																	**;
**	\\lmv08-metdb02\imd\web_server\admin\&app_version\programs\MasterAccountSettings.sas									**;
**	\\lmv08-metdb02\imd\web_server\admin\&app_version\programs\DataRestrictions.sas											**;
**	\\lmv08-metdb02\imd\web_server\admin\&app_version\programs\DateBasedSelectionProcessing.sas								**;
**	\\lmv08-metdb02\imd\web_server\admin\&app_version\programs\DefaultWebPartVariables.sas									**;
**  E:\imd\web_server\admin\&app_version\programs\WebParts.sas																**;
**																															**;
** Notes: Macros used:																										**;
**			- %compile_web_parts																							**;
**			- %set_procdate																									**;
**																															**;
** History:																													**;
**		01/01/2014 John Sandoval - Initial Release																			**;
**																															**;
******************************************************************************************************************************;

%macro compile_web_parts;

	/**************************************/
	/** Call the Master Account Settings **/
	/**************************************/
	%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\MasterAccountSettings.sas"; 

	/**************************************/
	/** Call the Restrictions Processing **/
	/**************************************/
	%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\DataRestrictions.sas";

	/************************************/
	/** Call the Selections Processing **/
	/************************************/
	%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\SelectionsProcessing.sas";

	/*******************************/
	/** Call the Markup Generator **/
	/*******************************/
	%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\MarkupGeneration.sas";

	/*********************************************************************/
	/** %SET_PROCDATE should be called by all web parts that have		**/
	/**	detected the absence of the &PROCDATEV macro variable.			**/
	/**																	**/
	/** This macro will use the &date_format to detect the presence of	**/
	/** an appropriate form-element macro variable (&month_select, etc).**/
	/** If none exist then the most recent valid procdate from the  	**/
	/** validate log will be used.										**/
	/*********************************************************************/
	%macro set_procdate(date_format);
		
		%global procdatev;

		/** Create PROCDATEV in Monthly format **/
		%if "&date_format" = "Monthly" %then %do;
			
			/** Check to see if the form on the previous page sent any dates **/
			%if %symexist(month_select) %then %do;
				data _null_;
					call symputx('procdatev', "&month_select");
				run;
			%end;
			/** If the previous page did not send any dates then use the most recnt valid date in the validate log **/
			%else %do;
				proc sql noprint;
					select cats(put(max(procdate), monyy7.), 'N') into: procdatev
					from &validate_log
					/** All status options that could result in data display **/
					where status in ('RELEASED','DATA APPROVED','REVISED');
				quit;
			%end;
		%end;

	%mend set_procdate;

	/**********************************************************************************************************/
	/** Determine the number of web parts for the report - this reads the metadata stored process parameters **/
	/**********************************************************************************************************/
	%if %symexist(WebPartIDs_Count) %then %do;
		data _null_;
			call symputx('num_web_parts', "&WEBPARTIDS_COUNT");
		run;
	%end;
	%else %do;
		data _null_;
			call symputx('num_web_parts', 0);
		run;
	%end;
	
	/********************************************************/
	/** Loop through Web Parts to compile output data sets **/
	/********************************************************/
	%if %eval(&num_web_parts) > 0 %then %do;

		%do web_part_counter = 1 %to %eval(&num_web_parts);

			/**********************************************/
			/** Set the default web part variable values **/
			/**********************************************/
			%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\DefaultWebPartVariables.sas";

			/** Determine the Web Part ID from the macro catalog **/
			%if %eval(&num_web_parts) = 1 %then %do;
				proc sql noprint;
					select compress(value) into: web_part_id
					from sashelp.vmacro
					where name = "WEBPARTIDS";
				quit;
			%end;
			%else %do;
				proc sql noprint;
					select compress(value) into: web_part_id
					from sashelp.vmacro
					where name = "WEBPARTIDS&web_part_counter";
				quit;
			%end;

			/** Determine the Web Part Type from the web part catalog - default is CONTENT **/
			%let web_part_type = Content;
			%if %sysfunc(exist(&admlib..web_part_catalog)) > 0 %then %do;
				data _null_;
					set &admlib..web_part_catalog;
					where web_part_id = input(compress("&web_part_id"), 8.);
					call symputx('web_part_type', web_part_type);
				run;
			%end;

			/** Call Web Parts Program **/
			%inc "E:\imd\web_server\admin\&app_version.\programs\WebParts.sas";

			/** Create the date-based drop-down selecctions **/
			%if "&month_selection" = "Y" %then %do;
				%month_drop_down_menu(&stack_select_labels);
			%end;

			/** Compile Content Title(s) **/
			%if "&web_part_type" = "Content Title" %then %do;
				data content_title(keep=text);
					length text $5000.;
					set web_part;
				run;
			%end;
			/** Compile Content Filter(s) **/
			%else %if "&web_part_type" = "Content Filter" %then %do;
				data content_filter(keep=text);
					length text $5000.;
					set web_part;
				run;
			%end;
			/** Compile Content(s) **/
			%else %if "&web_part_type" = "Content" %then %do;
	
				%if %sysfunc(exist(work.web_part)) > 0 %then %do;

					%if %sysfunc(exist(work.content)) = 0 %then %do;
						data content(keep=text);
							length text $5000.;
							set web_part;
						run;
					%end;
					%else %do;
						data content(keep=text);
						length text $5000.;
						set content web_part;
					run;
					%end;

				%end;

			%end;

		%end;

	%end;

	/*********************************************/
	/** Create container for compiled web parts **/
	/*********************************************/
	%if %sysfunc(exist(work.content)) > 0 %then %do;
		data content(keep=text);
			set content end=last;
			if _n_ = 1 then do;
				text = cats('<div class="web-part-content">',
							text);
			end;
			if last then do;
				text = cats(text,
							'</div>');
			end;
		run;
	%end;

	/********************************************************************************************************************/
	/** Compile all SELECTOPTIONS data sets into a CONTENT_FILTER data set that will be output by the global container **/
	/********************************************************************************************************************/
	%if %symexist(num_selection_filters) %then %do;
		%if %eval(&num_selection_filters) > 0 %then %do;

			%do selections_counter = 1 %to %eval(&num_selection_filters);

				data _null_;
					set selections_order (firstobs = &selections_counter obs = &selections_counter);
					call symputx('select_data', order_num);
				run;

				%if %sysfunc(exist(work.content_filter)) = 0 %then %do;
					data content_filter(keep=text);
						length text $5000.;
						set selectoptions&select_data;
					run;
				%end;
				%else %do;
					data content_filter(keep=text);
						set content_filter selectoptions&select_data;
					run;
				%end;

			%end;

		%end;
	%end;

%exit: %mend compile_web_parts;
%compile_web_parts;

