******************************************************************************************************************************;
** Program: GlobalContainer.sas																								**;
** Purpose: To handle global processing and global web page elements for all stored process calls							**;
**																															**;
** Date: 01/01/2014																											**;
** Developer: John Sandoval																									**;
** Application Version: 2.0																									**;
**																															**;
** Data sources: Defined in Metadata																						**;
**																															**;
** Includes (pay attention to UNC vs. Relative pathing):																	**;
**  \\lmv08-metdb02\imd\web_server\admin\&app_version\programs\DashboardCompiler.sas										**;
**  \\lmv08-metdb02\imd\web_server\admin\&app_version\programs\WebPartsCompiler.sas											**;
**  E:\imd\web_server\admin\&app_version\programs\WebParts.sas																**;
**																															**;
** Notes:																													**;
** History:																													**;
**		01/01/2014 John Sandoval - Initial Release																			**;
**																															**;
******************************************************************************************************************************;

options mprint minoperator;

%macro global_container;

	libname admprod '\\lmv08-metdb02\imd\web_server\admin\2.0\data';

	/*************************************************************************************************************************/
	/** Begin: Instantiate Global Variables	and Formats																		**/
	/*************************************************************************************************************************/
	data _null_;
		/*********************************************************************/
		/** Application Version: Files (folder names)						**/
		/*********************************************************************/
		%global app_version;
		call symputx('app_version', '2.0');
		/*********************************************************************/
		/** Application Version: Data (admin data library)					**/
		/*********************************************************************/
		%global admlib;
		call symputx('admlib', 'admprod');
		/*********************************************************************/
		/** Flag that tells the container to bypass normal page setup and	**/
		/** proceed straight to web part processing							**/
		/*********************************************************************/
		%if not %symexist(ajax_request) %then %do;
			call symputx('ajax_request', 'N');
		%end;
		/*********************************************************************/
		/** Flag that tells the AJAX bypass to call the dashboard compiler	**/
		/*********************************************************************/
		%if not %symexist(dashboard) %then %do;
			call symputx('dashboard', 'N');
		%end;
		/*********************************************************************/
		/** Flag that tells the AJAX bypass to call the report help			**/
		/*********************************************************************/
		%if not %symexist(report_help) %then %do;
			call symputx('report_help', 'N');
		%end;
		/*********************************************************************/
		/** Maximum number of HTML table rows before export is required		**/
		/*********************************************************************/
		%global table_row_limit;
		call symputx('table_row_limit', 500);
		/*********************************************************************/
		/** Optional JQuery code that can be added by Web Part Processing	**/
		/*********************************************************************/
		call symputx('add_jquery', ';');
		/*********************************************************************/
		/** Optional JQuery code that can be added by Web Part Processing 	**/
		/** and executed on the document.ready event						**/
		/*********************************************************************/
		call symputx('onload_jquery', ';');
		/*********************************************************************/
		/** Optional JQuery code that can be added by Web Part Processing 	**/
		/** and handled by the global click event delegation				**/
		/*********************************************************************/
		call symputx('click_delegate_jquery', ';');
		/*********************************************************************/
		/** Flag that tells container that report is enabled to toggle		**/
		/** between table and chart views									**/
		/*********************************************************************/
		call symputx('chart_enabled', 'N');
		/*********************************************************************/
		/** Flag that tells container to display the chart version of a  	**/
		/** table - requires data set named CHART_PLUGIN					**/
		/*********************************************************************/
		%if not %symexist(chart_plugin) %then %do;
			call symputx('chart_plugin', 'N');
		%end;
		/*********************************************************************/
		/** HTTP header for calling IE Edge document mode. This keeps pages	**/
		/** from displaying in compatibility view. It's declared here		**/
		/** because including it as an HTML META tag throws an error in the	**/
		/** HTML validator (as of HTML5 experimental @ W3).					**/
		/*********************************************************************/
		rc = stpsrv_header('X-UA-Compatible', 'IE=edge');
		/*********************************************************************/
		/** Default logical record length for _webout statement 			**/
		/*********************************************************************/
		call symputx('lrecl', 5000);
		/*********************************************************************/
		/** Application alert display. Automatically switched to Y when		**/
		/** valid alert is detected in the alerts data set					**/
		/*********************************************************************/
		call symputx('application_alert', 'N');
		/*********************************************************************/
		/** Default application alert message. In case the alert gets 		**/
		/** activated but no alert text is set								**/
		/*********************************************************************/
		call symputx('application_alert_message', 'System Alerts: None');
		/*********************************************************************/
		/** Page alert display. Can be changed to Y by web part code		**/
		/** Do NOT use page alerts as report help or to explain a poorly	**/
		/** constructed report. Create a better report or use the report	**/
		/** help feature.													**/
		/*********************************************************************/
		call symputx('page_alert', 'N');
		/*********************************************************************/
		/** Default page alert message. In case the alert gets activated	**/
		/** but no alert text is set										**/
		/*********************************************************************/
		call symputx('page_alert_message', 'Page Alerts: None');
		/*********************************************************************/
		/** Default report title when no title has been set		 			**/
		/*********************************************************************/
		call symputx('default_report_title', '(No Title)');
		/*********************************************************************/
		/** Default visibility of selected values in breadcrumb links		**/
		/*********************************************************************/
		%if not %symexist(show_breadcrumb_values) %then %do;
			call symputx('show_breadcrumb_values', 'Y');
		%end;
	run;

	proc format;
		/*********************************************************************/
		/** Datetime: mm/dd/yy hh:mm:ss										**/
		/*********************************************************************/
		picture mmddyytime other='%0m/%0d/%0Y %0H:%0M:%0S' (datatype=datetime);
		/*********************************************************************/
		/** Datetime: mm/dd/yy hh:mm AM/PM									**/
		/*********************************************************************/
		picture mmddyyampm other='%0m/%0d/%Y %0I:%0M %p' (datatype=datetime);
	run;
	/*************************************************************************************************************************/
	/** End: Instantiate Global Variables and Formats																		**/
	/*************************************************************************************************************************/

	/*************************************************************************************************************************/
	/** Begin: SAS Session Processing																						**/
	/*************************************************************************************************************************/
	%if not %symexist(SAVE_SESSION_DATA_CREATED) %then %do;

		/*******************************/
		/** Retreive Stored Processes **/
		/*******************************/
		/** Import stored processes from metadata **/
		%let mpw={sas002}9F5227373E1E70E031ED5B253ABF14E33817B7A9;
		options metauser="sasadm@saspw" metapass="&mpw";
		
		%mdsecds(outdata=access, identitynames="&_METAPERSON", identitytypes="Person", membertypes="StoredProcess", perms="ReadMetadata");

		/** Format stored process data for use throughout the session **/
		data report_access(keep=objId master_account sub_group_1 sub_group_2 sub_group_3 objName Location
								master_account_sort sub_group_1_sort sub_group_2_sort sub_group_3_sort
								stored_process_server);
			retain 				objId master_account sub_group_1 sub_group_2 sub_group_3 objName Location
								master_account_sort sub_group_1_sort sub_group_2_sort sub_group_3_sort
								stored_process_server;
			set access_join;
			length master_account sub_group_1 sub_group_2 sub_group_3 stpsrv stored_process_server $256.;
			length master_account_sort sub_group_1_sort sub_group_2_sort sub_group_3_sort 8.;
			/** Constrain to just stored processes that are granted to the user **/
			if PublicType = 'StoredProcess';
			if index(ReadMetadata, 'Granted') > 0;
			/** Define the master account and sub groups **/
			if trim(scan(location, 1, '/')) = 'Reporting Tools' then do;
				master_account = trim(scan(location, 2, '/'));
				master_account_sort = 1;
				sub_group_1 = trim(scan(location, 3, '/'));
				sub_group_2 = trim(scan(location, 4, '/'));
				sub_group_3 = trim(scan(location, 5, '/'));
			end;
			else if trim(scan(location, 1, '/')) in ('Top Menu', 'Administrative Tools') then do;
				master_account = trim(scan(location, 1, '/'));
				master_account_sort = 2;
				sub_group_1 = trim(scan(location, 2, '/'));
				sub_group_2 = trim(scan(location, 3, '/'));
				sub_group_3 = trim(scan(location, 4, '/'));
			end;
			else do;
				delete;
			end;
			/** Define the sorting that will flow through to the Reports Menu **/
			if sub_group_1 = '' then sub_group_1_sort = 0;
			else if sub_group_1 in ('Standard Reports', 'Standard Suite of Reports') then sub_group_1_sort = 1;
			else if sub_group_1 in ('Graphs') then sub_group_1_sort = 2;
			else if sub_group_1 in ('Queries') then sub_group_1_sort = 3;
			else if sub_group_1 in ('Custom Reports') then sub_group_1_sort = 4;
			else if sub_group_1 in ('Internal Reports') then sub_group_1_sort = 5;
			else if sub_group_1 in ('Flat Files') then sub_group_1_sort = 6;
			else if sub_group_1 in ('Development') then sub_group_1_sort = 99;
			else sub_group_1_sort = 7;
			/** Define the logical server for each stored process **/
			rc = metadata_getnasn(ObjUri, "ComputeLocations", 1, stpsrv);
			rc = metadata_getattr(stpsrv, "Name" , stored_process_server);
			stored_process_server = compress(scan(stored_process_server, 1));
		run;

		/** Save stored process data for the session **/
		proc sort data = report_access out = save.report_access;
			by master_account_sort master_account sub_group_1_sort sub_group_2_sort sub_group_3_sort objName;
		run;

		/********************************************************/
		/** Retrieve and summarize historical hits information **/
		/********************************************************/
		/** Combined with recent hits, this data can be used for the Most Frequent Favorites option **/

		/****************************************/
		/** Retreive Metadata Group Membership **/
		/****************************************/
		/** This can be used to control access to summary-only web parts for the dashboard. **/
		/** The summary web parts can have a web-part-to-group data set that's maintained **/
		data save.group_access(keep=group_uri_val group_name_val);
			length person_uri group_uri group_name group_uri_val group_name_val $500.;

			/** Determine the user metadata URI **/
			rc1 = metadata_getnobj(cats("omsobj:Person?@Name='", "&_METAPERSON", "'"), 1, person_uri);

			group_counter = 0;
			do until(rc2 < 0);
				group_counter = group_counter + 1;
				/** Determine the user metadata group URIs **/
				rc2 = metadata_getnasn(person_uri, "IdentityGroups", group_counter, group_uri);
				if rc2 > 0 then do;
					/** Determine the user metadata group names **/
					rc3 = metadata_getattr(group_uri, "Name", group_name);
					group_uri_val = group_uri; group_name_val = group_name; output;
				end;
			end;
		run;

		/*************************************************/
		/** Determine if the user has Review privileges **/
		/*************************************************/
		/** Extract the user's 1st email address stored in metadata **/
		data _null_;
			length emailuri email $256.;
			rc1 = METADATA_GETNASN(cats("omsobj:Person?@Name='", "&_METAPERSON", "'"), 'EmailAddresses', 1, emailuri);
			rc2 = METADATA_GETATTR(emailuri, "Address", email);
			call symputx('email_domain', lowcase(scan(email, -1, '@')));
		run;
		    
		/** If the user's email is intrado.com then allow review privileges **/
		%global SAVE_REVIEW;
		%if %index(&email_domain, intrado.com) > 0 %then %do;
			%let SAVE_REVIEW = Y;
			/** Test further for SAVE_METRICS here **/
		%end;
		%else %do;
			%let SAVE_REVIEW = N;
		%end;

		/** Set a macro var that flags this section not to run again for the session **/
		%global SAVE_SESSION_DATA_CREATED;
		%let SAVE_SESSION_DATA_CREATED = Y;

	%end;
	/*************************************************************************************************************************/
	/** End: SAS Session Processing																							**/
	/*************************************************************************************************************************/

	/*************************************************************************************************************************/
	/** Begin: Stored Process Settings																						**/
	/*************************************************************************************************************************/
	/** Offer session ID values **/
	%global wrlnsession mobsession verizsession;
	data _null_;
		set save.sessions;
		call symputx('wrlnsession', wrlnsession);
		call symputx('mobsession', mobsession);
		call symputx('verizsession', verizsession);
	run;

	/** Create a variable that includes many of the commomly passed items in a SAS BI URI **/
	data _null_;
		call symputx('uri_prefix', '/SASStoredProcess/do?%nrstr(&)amp;_sessionid=%superq(_SESSIONID)%nrstr(&)amp;_program=%superq(_PROGRAM)');
		call symputx('uri_prefix_unencoded', '/SASStoredProcess/do?%nrstr(&)_sessionid=%superq(_SESSIONID)%nrstr(&)_program=%superq(_PROGRAM)');
	run;

	data _null_;
		call symputx('uri_prefix', tranwrd("&uri_prefix", ' ', '%20'));
	run;

	/** Parse the _PROGRAM value **/
	data _null_;
		call symputx('toplevel', 	scan("&_program", 1, "/"));
		call symputx('supergroup',	scan("&_program", 2, "/"));
		call symputx('subgroup', 	scan("&_program", 4, "/"));
		call symputx('reportname', 	scan("&_program", -1, "/"));
	run;

	/** Set a default report level **/
	%if not %symexist(level) %then %do;
		%let level = 1;
	%end;

	/** Set a default HTTP content type **/
	%if not %symexist(exportto) %then %do;
		%let exportto = html;
	%end;
	/*************************************************************************************************************************/
	/** End: Stored Process Settings																						**/
	/*************************************************************************************************************************/

	/*************************************************************************************************************************/
	/** Begin: AJAX Bypass																									**/
	/*************************************************************************************************************************/
	/** If request was sent as AJAX then divert processing and ignore the rest of the global container **/
	%if "&ajax_request" = "Y" %then %do;
		/** Dashboard AJAX bypass **/
		%if "&dashboard" = "Y" %then %do;
			%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\DashboardCompiler.sas";
		%end;
		/** Report Help AJAX bypass **/
		%else %if "&report_help" = "Y" %then %do;
			%let web_part_id = 400;
			%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\GlobalWebParts.sas";
		%end;
		/** Standard AJAX bypass **/
		%else %do;
			%inc "E:\imd\web_server\admin\&app_version.\programs\WebParts.sas";
		%end;
		%goto exit;
	%end;
	/*************************************************************************************************************************/
	/** End: AJAX Bypass																									**/
	/*************************************************************************************************************************/

	/*************************************************************************************************************************/
	/** Begin: Favorites Menu Processing																					**/
	/*************************************************************************************************************************/
	/** Get user favorites and create individual UL elements (to achieve border-collapse effect) **/
	data user_favorites(keep=text);
		length text $5000.;
		set &admlib..favorites;
		if user_id = "&_METAPERSON";
		text = cats('<ul><li><a href=""#"">', master_account, ':', objName, '</a></li></ul>'); output;
	run;

	/** Create the Manage Favorites link **/
	data manage_favorites(keep=text);
		length text $5000.;
		text = cats('<ul><li id=""manage-favorites-item""><a href=""#"">Manage Favorites</a></li></ul>'); output;
	run;

	/** Compile the Favorites menu element **/
	data user_favorites;
		set user_favorites manage_favorites end=last;
		if _n_ = 1 then do;
			text = cats('<div id=""favorites-menu"" class=""top-drop-menu"">',
						text);
		end;
		if last then do;
			text = cats(text,
						'</div>');
		end;
	run;

	/** Store the menu as a text macro string for easy use later **/
	data _null_;
		set user_favorites end=last;
		retain temp;
		length temp $25000.;
		temp = cats(temp, '0D'x, trim(text));
		if last then call symputx('favorites_menu', trim(temp));
	run;
	/*************************************************************************************************************************/
	/** End: Favorites Menu Processing																						**/
	/*************************************************************************************************************************/

	/*************************************************************************************************************************/
	/** Begin: Export Menu Processing																						**/
	/*************************************************************************************************************************/
	/** Define the Export menu options as individual UL elements (to achieve border-collapse effect) **/
	data export_menu(keep=text);
		length text $5000.;
		text = cats('<div id=""export-menu"" class=""top-drop-menu"">'); output;

		text = cats('<ul><li><a href=""#"">Export Excel 2007+</a></li></ul>'); output;
		text = cats('<ul><li><a href=""#"">Export Excel 2003</a></li></ul>'); output;
		text = cats('<ul><li><a href=""#"">Export CSV</a></li></ul>'); output;
		text = cats('<ul><li><a href=""#"">Export PDF</a></li></ul>'); output;

		text = cats('</div>'); output;
	run;

	/** Store the menu as a text macro string for easy use later - ~32K character limit **/
	data _null_;
		set export_menu end=last;
		retain temp;
		length temp $25000.;
		temp = cats(temp, '0D'x, trim(text));
		if last then call symputx('export_menu', trim(temp));
	run;
	/*************************************************************************************************************************/
	/** End: Export Menu Processing																							**/
	/*************************************************************************************************************************/

	/*************************************************************************************************************************/
	/** Begin: Application Alert Processing																					**/
	/*************************************************************************************************************************/
	/** Determine if there are any alerts **/
	%let application_alert = N;
	
	/** Set the application alert message **/
	data _null_;
		call symputx('application_alert_message', cats('The system will be unavailable on 11/18/2013 from 4:00 PM to 5:00 PM Mountain time'
														/*
														,'A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text.'
														,'A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text.'
														,'A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text.'
														,'A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text. A lot more text.'
														*/
														));
	run;

	/*************************************************************************************************************************/
	/** End: Application Alert Processing																					**/
	/*************************************************************************************************************************/

	/*************************************************************************************************************************/
	/** Begin: Web Page	Output																								**/
	/*************************************************************************************************************************/
	data _null_;
		file _webout lrecl=&lrecl;

		/*******************************/
		/** Document Type Declaration **/
		/*******************************/
		put '<!doctype html>';

		/**********************************/
		/** Begin: HTML Document Section **/
		/**********************************/
		put '<html lang="en-US">';

		/********************************/
		/** Begin: HTML <HEAD> Section **/
		/********************************/
		put '<head>';
		/** Title **/
		put "<title>Intrado ClearView &app_version.</title>";
		/** Default Character Set **/
		put '<meta charset="UTF-8">';
		/** External Style Sheets **/
		put '<link rel="stylesheet" type="text/css" href="/SAS/stylesheet/' "&app_version" '/GlobalContainer.css">';
		put '<link rel="stylesheet" type="text/css" href="/SAS/stylesheet/' "&app_version" '/GlobalContainer_Mobile.css">';
		put '<link rel="stylesheet" type="text/css" href="/SAS/stylesheet/' "&app_version" '/jquery-ui-1.10.3.css">';
		put '<link rel="stylesheet" type="text/css" href="/SAS/stylesheet/' "&app_version" '/jquery.fancybox.css">';
		put '<link rel="stylesheet" type="text/css" href="/SAS/stylesheet/' "&app_version" '/carousel_skin_variation.css">';
		/** Scripting Libraries **/
		put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-1.10.2.min.js"></script>';
		put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-ui-1.10.3.min.js"></script>';
		put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-ui-touch-punch.min.js"></script>';
		put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-tablesorter.min.js"></script>';
		put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-tablesorter-widgets.min.js"></script>';
		put '<script src="/SAS/JavaScript/' "&app_version" '/jquery-cycle-all.js"></script>';
		put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-fancybox.min.js"></script>';
		put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-sky-carousel-1.0.2.min.js"></script>';

		put '<script src="/SAS/JavaScript/' "&app_version" '/jquery-highcharts.js"></script>';
		put '<script src="/SAS/JavaScript/' "&app_version" '/jquery-highcharts-data.js"></script>';
		put '<script src="/SAS/JavaScript/' "&app_version" '/jquery-highcharts-exporting.js"></script>';

		/** This snippet is for IE 6-9 that have console object inconsistencies **/
		/*put '<script type="text/javascript"> if (!window.console) console = {log: function() {}}; </script>';*/
		put '</head>';
		/******************************/
		/** End: HTML <HEAD> Section **/
		/******************************/

		/********************************/
		/** Begin: HTML <BODY> Section **/
		/********************************/
		put '<body id="body">';

		/*******************************/
		/** Begin: Viewport Container **/
		/*******************************/
		put '<div id="viewport">';

		/********************/
		/** Begin: Top Bar **/
		/********************/
		put '<div id="top-bar">';
		/** Top Bar Images **/
		put '<span id="top-bar-left-image"><img src="/SAS/images/' "&app_version" '/Logos/Intrado_logo.png" alt="Intrado" /></span>';
		put '<span id="top-bar-right-image"><img src="/SAS/images/' "&app_version" '/Logos/ClearView_Logo.png" alt="ClearView" /></span>';

		/*************************/
		/** Begin: Top Bar Menu **/
		/*************************/
		put '<div id="top-menu">';

	run;

	/** Retreive Top Menu Stored Processes **/
	data top_menu;
		set save.report_access;
		if master_account = 'Top Menu';
		/** Set the display order of the Top Menu items **/
		if objName = 'Home' then display_order = 1;
		else if objName = 'Reports' then display_order = 2;
		else if objName = 'Favorites' then display_order = 3;
		else if objName = 'Export' then display_order = 4;
		else if objName = 'Help' then display_order = 5;
		else display_order = 6;
	run;

	proc sort data = top_menu;
		by display_order objName;
	run;

	/** Create Top Menu buttons **/
	data top_menu(keep=text);
		length text $5000. div_def $100. a_def $500.;
		set top_menu;
		/** If the current stored process matches the menu button then format the button as selected **/
		if cats(Location, objName) = trim(urldecode(trim("&_program"))) then do;
			div_def = cats('<div id="top-menu-', compress(lowcase(objName)), '" class="top-menu-item-selected">');
			a_def = cats('<a href="#">');
		end;
		/** Otherwise apply standard button formatting **/
		else do;
			/** Certain buttons will only display hidden content **/
			div_def = cats('<div id="top-menu-', compress(lowcase(objName)), '" class="top-menu-item">');
			if objName in ('Favorites', 'Export') then do;
				a_def = cats('<a href="#" onclick="return false;">');
			end;
			else if objName = 'Help' then do;
				a_def = cats('<a href="#" onclick="reportHelp(); return false;">');
			end;
			/** Other buttons will actually make an HTTP request **/
			else do;
				a_def = cats('<a href="/SASStoredProcess/do?&amp;_sessionid=', "&wrlnsession", '&amp;_program=', trim(urlencode(trim(cats(Location, objName)))), '">');
			end;
		end;
		text = cats(div_def, a_def, objName, '</a></div>');
	run;

	/** Output the Top Menu source **/
	data _null_;
		file _webout lrecl=&lrecl;
		set top_menu;
		put text;
	run;

	data _null_;
		file _webout lrecl=32000;
		/** (This logical record length was larger - 32K - because of potentially large macro string variables) **/

		put '</div>';
		/***********************/
		/** End: Top Bar Menu **/
		/***********************/

		put '</div>';
		/******************/
		/** End: Top Bar **/
		/******************/

		/** Relative positioned placeholder element for Top Bar **/
		/** This is also the perfect place to store hidden elements (Top Menu drop down menus, loading animations, etc.) **/
		put '<div id="top-bar-placeholder">';

			/** Output the hidden global LOADING notification **/
			put '<div id="hidden-loading-container">';

				put '<div id="loading-img">';
				put '<img src="/SAS/images/' "&app_version" '/Icons/Loading_Transparency_Small.gif" alt="Loading" />';
				put '</div>';

			put '</div>';

			/** Output the global form submit notification **/
			put '<div id="hidden-selections-message">';

				put '<div id="filter-update-message">Click the Filter button when complete to see your updated selections</div>';

			put '</div>';

			/** Output the hidden Favorites drop down menu **/
			put "&favorites_menu";

			/** Output the hidden Export drop down menu **/
			put "&export_menu";

		put '</div>';

	run;

	/*************************************/
	/** Call Web Parts Compiler Program **/
	/*************************************/
	%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\WebPartsCompiler.sas";

	data _null_;
		file _webout lrecl=&lrecl;

		/*******************************/
		/** Begin: User Messages Area **/
		/*******************************/
		put '<div id="user-messages">';

	run;

		%macro generate_alert(alert_type);
			/** Alert Container **/
			put '<div class="user-alert">';
			/** Alert Show and Hide Icons **/
			put "<div class=""alert-icon &alert_type.-alert"">";
			put '<div class="alert-icon-x">x</div>';
			put '<div class="alert-icon-img"><img src="/SAS/images/' "&app_version" '/Icons/Info_Orange.png" alt="Alert" /></div>';
			put '</div>';
			/** Alert Text Container **/
			put '<div class="alert-message">';
			/** Alert Text **/
			put "<div class=""alert-message-text &alert_type.-alert"">";
			put "&&&alert_type._alert_message";
			put '</div>';
			/** Close Alert Text Container **/
			put '</div>';
			/** Close Alert Container **/
			put '</div>';
		%mend generate_alert;

	data _null_;
		file _webout lrecl=&lrecl;

		/** Application Alerts **/
		%if "&application_alert" = "Y" %then %do;
			%generate_alert(application);
		%end;
		/** Page Alerts **/
		%if "&page_alert" = "Y" %then %do;
			%generate_alert(page);
		%end;

		put '</div>';
		/** Relative positioned placeholder element for user messages **/
		put '<div id="user-messages-placeholder"></div>';
		/*****************************/
		/** End: User Messages Area **/
		/*****************************/

		/********************************/
		/** Begin: Content Header Area **/
		/********************************/
		put '<div id="content-header">';

		/***********************************/
		/** Begin: Content Header Top Row **/
		/***********************************/
		put '<div id="content-header-top-row">';

		/************************/
		/** Begin: Breadcrumbs **/
		/************************/
		put '<div id="breadcrumbs">';
	run;

	%if %eval(&level) > 1 %then %do;
		%if %sysfunc(exist(work.breadcrumbs)) > 0 %then %do;
			%do bc_counter = 1 %to %eval(&level - 1);

				data _null_;
					file _webout lrecl=&lrecl;
					set breadcrumbs;
					if level = &bc_counter;
					length text $5000. display_value $1500.;
					%if "&show_breadcrumb_values" = "Y" %then %do;
						display_value = cats('&nbsp;(', value, ')');
					%end;
					%else %do;
						display_value = '';
					%end;
					text = cats('&nbsp;&gt;&nbsp;<span>', link, display_value, '</span>');
					put text;
				run;

			%end;
		%end;
	%end;

	data _null_;
		file _webout lrecl=&lrecl;
		put '</div>';
		/**********************/
		/** End: Breadcrumbs **/
		/**********************/

		/** Welcome Row **/
		put '<div id="user-welcome">Welcome ' "&save_username" '</div>';

		put '</div>';
		/*********************************/
		/** End: Content Header Top Row **/
		/*********************************/

		/**************************/
		/** Begin: Content Title **/
		/**************************/
		put '<div id="content-title">';

	run;

	/** If Content Title dynamic output exists then output it here **/
	%if %sysfunc(exist(work.content_title)) > 0 %then %do;

		data _null_;
			file _webout lrecl=&lrecl;
			set content_title;
			put text;
		run;	

	%end;
	/** Otherwise output a standard text title **/
	%else %do;

		/** Set the report title as a custom-passed title or default to the stored process name **/
		%if %symexist(report_title) %then %do;
			%if "&report_title" ne "" %then %let report_title_text = &report_title;
			%else %let report_title_text = &reportname;
		%end;
		%else %do;
			%let report_title_text = &reportname;
		%end;

		/** Catch-all if the report title is still blank **/
		%if "&report_title_text" = "" %then %let report_title_text = &default_report_title;

		/** Output standard report title **/
		data _null_;
			file _webout lrecl=&lrecl;
			put "<span>&supergroup.: &report_title_text.</span>";
			/** Output table-chart toggle link if report is chart enabled **/
			%if "&chart_enabled" = "Y" %then %do;
				%if "&chart_plugin" = "N" %then %do;
					put '<div id="content-customize"><a href="#">Show as Chart</a></div>';
					put '<div id="content-customize-wait" style="display: none;"><a href="#">Show as Chart</a></div>';
				%end;
				%else %if "&chart_plugin" = "Y" %then %do;
					put '<div id="content-customize"><a href="#">Show as Table</a></div>';
					put '<div id="content-customize-wait" style="display: none;"><a href="#">Show as Table</a></div>';
				%end;
			%end;
		run;

	%end;

	data _null_;
		file _webout lrecl=&lrecl;

		put '</div>';
		/************************/
		/** End: Content Title **/
		/************************/

		/** Content Header Underline **/
		put '<div id="content-header-underline" class="horizontal-gradient-bar"></div>';

		/****************************/
		/** Begin: Content Filters **/
		/****************************/
		put '<div id="content-filters">';

		/** Define the form element that will hold the filter objects **/
		put '<form id="report-filter-form" name="report-filter-form" method="get" action="/SASStoredProcess/do?">';
		
		put '<input type="hidden" name="_program" value="' "&_PROGRAM" '">';
		put '<input type="hidden" name="_sessionid" value="' "&_SESSIONID" '">';
		put '<input type="hidden" name="level" value="1">';
		put '<input type="hidden" id="refreshed" value="no">';

	run;

	/** If Content Filter output exists then output it here **/
	%if %sysfunc(exist(work.content_filter)) > 0 %then %do;

		data _null_;
			file _webout lrecl=&lrecl;
			set content_filter;
			put text;
		run;	

	%end;

	data _null_;
		file _webout lrecl=&lrecl;

		%if %sysfunc(exist(work.content_filter)) > 0 %then %do;
			%if "&refresh_on_select" ne "Y" %then %do;
				/** Create the submit button **/
				put '<span id="filter-submit" class="submit-button-1" style="width: 70px; line-height: 20px;" onClick="form_submit(''report-filter-form'');">Filter</span>';
			%end;
		%end;

		/** Create hidden elements that can be linked to content objects **/

		/** Close the form **/
		put '</form>';

		put '</div>';
		/**************************/
		/** End: Content Filters **/
		/**************************/
		
		put '</div>';
		/******************************/
		/** End: Content Header Area **/
		/******************************/

		/** Relative positioned placeholder element for content header **/
		put '<div id="content-header-placeholder"></div>';

		/********************/
		/** Begin: Content **/
		/********************/
		put '<div id="content">';
		
	run;

	/** If Content output exists then output it here **/
	%if %sysfunc(exist(work.content)) > 0 %then %do;

		/** Begin: Web Part Content **/

		data _null_;
			file _webout lrecl=&lrecl;
			set content;
			put text;
		run;	

	%end;
	/** If no Content output exists then output a notification **/
	%else %do;

		data _null_;
			file _webout lrecl=&lrecl;
			put '<div id="no-content"><img src="/SAS/images/' "&app_version" '/Titles/No_Content.png" alt="No Content" /></div>';
		run;

	%end;
		
	data _null_;
		file _webout lrecl=&lrecl;

		put '</div>';
		/******************/
		/** End: Content **/
		/******************/

	run;

	data _null_;
		file _webout lrecl=&lrecl;

		/** Relative positioned placeholder element for Bottom Bar **/
		put '<div id="bottom-bar-placeholder"></div>';

		/***********************/
		/** Begin: Bottom Bar **/
		/***********************/
		put '<div id="bottom-bar">';

		/** Copyright **/
		copyright_year = put(today(), year4.);
		put '<div id="bottom-bar-copyright">&copy; ' copyright_year ' Intrado Inc. All rights reserved.</div>';
		
		put '</div>';
		/*********************/
		/** End: Bottom Bar **/
		/*********************/

		put '</div>';
		/*****************************/
		/** End: Viewport Container **/
		/*****************************/

		/*********************************************************************************************************************/
		/** Begin: Scripting Section 																						**/
		/*********************************************************************************************************************/
		put '<script>';
		/** Establish a dedicated JQuery variable **/
		put 'var $jload = jQuery.noConflict();';
		/***********************************/
		/** Begin: Document Ready Scripts **/
		/***********************************/
		put '$jload(document).ready(function(){';

			/************************************/
			/** TEMPORARY drop-down value sync **/
			/************************************/
			put 'var reload_state = document.getElementById("refreshed");';
			/** After initial DOM load set the refreshed value to yes **/
			/** This will leave the value as NO in the DOM cache and YES in memory **/
			/** This way we can tell when a page was loaded from the cache (browser back button) **/
			put 'if (reload_state.value == "no") {';
				put 'reload_state.value = "yes";';
			put '}';
			/** If the page was loaded from the cache then re-submit the page so that URI variables are processed and the form elements update **/
			/** Re-submitting the page is not ideal because long-running reports will actually be seen loading twice by the user **/
			/** A solution to this could be to NOT use forms to handle filtering or to manipulate the hash **/
			put 'else {';
				put 'reload_state.value = "no";';
				put 'location.reload();';
			put '}';

			/****************************************/
			/** Determine Initial Alert Visibility **/
			/****************************************/
			/*************************************************************************/
			/** If the user has selected to hide an	alert message this section 		**/
			/** reads the HTML5 session storage and puts the alert in a hidden 		**/
			/** state immediately after the DOM has loaded							**/
			/*************************************************************************/
			/** Currently, page alerts visibility is NOT stored because page alerts	**/
			/** could change from screen to screen and applying the user-stored 	**/
			/** hidden setting could prevent them from ever seeing a new page alert	**/
			/*************************************************************************/
			%if "&application_alert" = "Y" %then %do;
				/** Determine if browser allows HTML5 session storage **/
				put 'if(typeof(Storage)!== "undefined") {';
					/** Determine if an application alert state exists **/
  					put 'if (sessionStorage.applicationAlert) {';
						/** If the alert status exists and is "closed" then hide alert after DOM load **/
  						put 'if (sessionStorage.applicationAlert == "closed") {';
							put '$jload(".user-alert .alert-message-text.application-alert").hide(0);';
							put '$jload(".user-alert .alert-icon.application-alert .alert-icon-x").hide(0);';
							put '$jload(".user-alert .alert-icon.application-alert .alert-icon-img").show(0);';
						put '}';
					put '}';
  				put '}';
			%end;

			/*********************************/
			/** Relative Placeholder Sizing **/
			/*********************************/
			/*************************************************************************/
			/** This section makes sure that the position of relative placeholders 	**/
			/**	is correct based on the height of the fixed elements.	 			**/
			/*************************************************************************/
			/** Determine height of top-bar element **/
			put 'var top_bar_height = $jload("#top-bar").height();';
			put 'var total_fixed_height = top_bar_height;';
			/** Ensure correct height of top-bar relative placeholder and correct starting point of messages element **/
			put 'if ($jload("#top-bar-placeholder").height() != top_bar_height) { ';	
				put '$jload("#top-bar-placeholder").css(''height'', top_bar_height);';
				put '$jload("#user-messages").css(''top'', top_bar_height);';
			put '}';

			/** Determine height of user-messages element **/
			put 'var messages_height = $jload("#user-messages").height();';
			put 'var total_fixed_height = top_bar_height + messages_height;';
			/** Ensure correct height of user-messages relative placeholder and correct starting point of content header **/
			put 'if ($jload("#user-messages-placeholder").height() != messages_height) { ';
				put '$jload("#user-messages-placeholder").css(''height'', messages_height);';
				put '$jload("#content-header").css(''top'', total_fixed_height);';
			put '}';

			/** Determine height of content-header element **/
			put 'var content_header_height = $jload("#content-header").height();';
			put 'var total_fixed_height = top_bar_height + messages_height + content_header_height;';
			/** Ensure correct height of content-header relative placeholder **/
			put 'if ($jload("#content-header-placeholder").height() != content_header_height) { ';
				put '$jload("#content-header-placeholder").css(''height'', content_header_height);';
			put '}';

			/******************************************/
			/** Initialize Form Element Enhancements **/
			/******************************************/
			put '$jload("input:text, textarea").bind("focus blur", function() {';
    			put '$jload(this).toggleClass("input-active");';
				/*put '$jload(this).css("background-color", "#000000");';*/
			put '});';

			/******************************************/
			/** Initialize Tablesorter functionality **/
			/******************************************/
			%if "&dashboard" ne "Y" %then %do;
				put 'enhanceTable();';
			%end;

			/************************************/
			/** Initialize Modal functionality **/
			/************************************/
			put '$jload(".fancybox").fancybox();';

			/***************************************/
			/** Insert dynamically created JQuery **/
			/***************************************/
			put "&onload_jquery";

		put '});';
		/*********************************/
		/** End: Document Ready Scripts **/
		/*********************************/

		/****************************/
		/** Click event delegation **/
		/****************************/
		/*****************************************************************************/
		/** This section fires on any click within the DOM, disables event			**/
		/** propagation, and uses event delegation to:								**/
		/** 	1) Toggle the top level menus.										**/
		/**		2) Add/remove dashboard web parts for AJAX-loaded source			**/
		/**		3) Delete help entries for AJAX-loaded source (lightbox)			**/
		/*****************************************************************************/
		put '$jload(document).on(''click touchstart'', ''*'', function(event) {';
    		put 'event.stopPropagation();';
			/** Toggle Favorites Menu **/
    		put 'if ($jload(this).closest("div").attr("id") == "top-menu-favorites") {';
				put '$jload("#favorites-menu").siblings(".top-drop-menu").hide(0, function() {';
					put '$jload("#favorites-menu").toggle("slide", { direction: "up" }, 500);';
				put '});';
			/** Toggle Export Menu **/
			put '} else if ($jload(this).closest("div").attr("id") == "top-menu-export") {';
				put '$jload("#export-menu").siblings(".top-drop-menu").hide(0, function() {';
					put '$jload("#export-menu").toggle("slide", { direction: "up" }, 500).siblings(".top-drop-menu").hide(0);';
				put '});';
			/** If click was anywhere else on page close the top menus **/
    		put '} else {';
				put 'if ($jload(".top-drop-menu").is(":visible")) {';
	        		put '$jload(".top-drop-menu").hide("slide", { direction: "up" }, 500);';
				put '}';
			put '}';
			/*******************************************************************************/
			/** ALL OF THE BELOW JQUERY CAN BE ADDED REPORT SPECIFICALLY WITH A MACRO VAR **/
			/*******************************************************************************/
			/** If click was to remove a web part from the dashboard **/
			put 'if ($jload(this).parents(".draggable-remove").length == 1) {';
				put 'var webPartId = $jload(this).parents(".draggable-remove").attr("id").split("-").pop();';
				put 'alert("Web Part ID: " + webPartId + " will be removed");';
				/** Think about a confirmation box then an .AJAX call (like Save Layout) that refreshes back to the customize state **/
			put '}';
			/** If click was to add a web part to the dashboard **/
			put 'if ($jload(this).attr("class") == "submit-button-1 add-web-part-commit") {';
				put 'var webPartId = $jload(this).attr("id").split("-").pop();';
				put 'alert("Web Part ID: " + webPartId + " will be added");';
				/** Think about a confirmation box then an .AJAX call (like Save Layout) that refreshes back to the customize state **/
			put '}';

			put "&click_delegate_jquery";

		put '});';

		/*******************/
		/** Toggle Alerts **/
		/*******************/
		/*************************************************************************/
		/** This section does two things:										**/
		/** 	1) Toggles alert text as the user clicks the X and Info icons	**/
		/**		2) If the alert text wraps to more than 1 line then the rest of	**/
		/**			the page content is animated to move up/down to adjust to	**/
		/**			the showing/hiding of the multi-line alert.					**/
		/*************************************************************************/
		%if ("&application_alert" = "Y") or ("&page_alert" = "Y") %then %do;
			put '$jload(".user-alert .alert-icon").on(''click touchend'', function() {';
				/** Determine the alert type **/
				put 'if ($jload(this).is(".application-alert")) {var alert_type = "application-alert"}';
				put 'if ($jload(this).is(".page-alert")) {var alert_type = "page-alert"}';
				/** Hide alert **/
				put 'if ($jload(".user-alert .alert-message-text." + alert_type).is(":visible")) {';
					put 'var old_messages_height = $jload("#user-messages").height()';
					put '$jload(".user-alert .alert-message-text." + alert_type).hide("slide", { direction: "up" }, 500, function() {';
						/** Determine if the height of the messages element changes (got smaller) **/
						put 'var new_messages_height = $jload("#user-messages").height()';
						put 'if (old_messages_height != new_messages_height) {';
							/** Adjust size of messages placeholder **/
							put '$jload("#user-messages-placeholder").animate( { height: new_messages_height }, 500);';
							/** Adjust top value of content-header **/
							put 'var new_content_header_top = $jload("#content-header").offset().top - (old_messages_height - new_messages_height);';
							put '$jload("#content-header").animate( { top: new_content_header_top }, 500, function() {';
								put 'enhanceTable();';
							put '});';
						put '}';
					put '});';
					/** Replace X with icon **/
					put '$jload(".user-alert .alert-icon." + alert_type + " .alert-icon-x").hide(0);';
					put '$jload(".user-alert .alert-icon." + alert_type + " .alert-icon-img").show("slide", { direction: "left" }, 500)';
					/** Store current state (closed or open) in session storage **/
					put 'if(typeof(Storage)!== "undefined") {';

						put 'sessionStorage.applicationAlert="closed";';

					put '}';
				put '} else {';
					/** Show alert **/
					put 'var old_messages_height = $jload("#user-messages").height()';
					put '$jload(".user-alert .alert-message-text." + alert_type).show("slide", { direction: "up" }, 500, function() {';
						/** Determine if the height of the messages element changes (got larger) **/
						put 'var new_messages_height = $jload("#user-messages").height()';
						put 'if (old_messages_height != new_messages_height) {';
							/** Adjust size of messages placeholder **/
							put '$jload("#user-messages-placeholder").animate( { height: new_messages_height }, 500);';
							/** Adjust top value of content-header **/
							put 'var new_content_header_top = $jload("#content-header").offset().top + (new_messages_height - old_messages_height);';
							put '$jload("#content-header").animate( { top: new_content_header_top }, 500, function() {';
								put 'enhanceTable();';
							put '});';
						put '}';
					put '});';
					/** Replace icon with X **/
					put '$jload(".user-alert .alert-icon." + alert_type + " .alert-icon-img").hide(0);';
					put '$jload(".user-alert .alert-icon." + alert_type + " .alert-icon-x").show("slide", { direction: "left" }, 500)';
					/** Store current state (closed or open) in session storage **/
					put 'if(typeof(Storage)!== "undefined") {';

						put 'sessionStorage.applicationAlert="open";';

					put '}';
				put '}';
			put '});';
		%end;

		/******************/
		/** Chart Toggle **/
		/******************/
		%if "&chart_enabled" = "Y" %then %do;
			put '$jload("#content-customize").on("click", function() {';
				put '$jload("#content").html($jload("#hidden-loading-container").html());';
				put '$jload("#content-customize").hide(0);';
				put '$jload("#content-customize-wait").show(0);';
				put 'var queryString = location.search.substring(1);';
				%if "&chart_plugin" = "Y" %then %do;
					put 'var chartToggle = "N";';
				%end;
				%else %do;
					put 'var chartToggle = "Y";';
				%end;
				put 'if (queryString.indexOf("&chart_plugin=") >= 0) {';
					put 'var newQueryString = queryString.replace("&chart_plugin=' "&chart_plugin" '", "&chart_plugin=" + chartToggle);';
				put '} else {';
					put 'newQueryString = queryString + "&chart_plugin=" + chartToggle;';
				put '}';

				put 'location.search = newQueryString;';
				/*put '$jload("#content-customize").text(newQueryString);';*/
			put '});';
		%end;

		/***********************************/
		/** Report Filter Form Submission **/
		/***********************************/
		put 'function form_submit(theform) {';
			/** The following actions can be set up as callbacks if browser oddities arise **/
			put '$jload("#content").animate({ opacity: 1 });';
			put '$jload("#content").html($jload("#hidden-loading-container").html());';
			put 'document.forms[theform].submit();';
		put '}';

		put 'function selection_filter() {';
			put '$jload("#content").animate({ opacity: 0.3 });';
			/*put '$jload("#content").html($jload("#hidden-selections-message").html());';*/
		put '}';

		/******************************/
		/** Report Help Popup Window **/
		/******************************/
		put 'var reportHelpWindow;';
		put 'function reportHelp(option1) {';
			/** If the help window already exists then close it to avoid confusion **/
			put 'if (typeof reportHelpWindow != "undefined") {';
				put 'reportHelpWindow.close();';
			put '}';
			put 'if (typeof option1 != "undefined") {';
				put 'var opt1 = "&" + option1 + "=Y";';
			put '} else {';
				put 'var opt1 = "";';
			put '}';
			/** Open the help in a new controlled window **/
			put "reportHelpWindow=window.open('&uri_prefix_unencoded" '&ajax_request=Y&report_help=Y&_debug=0'' + opt1,''reportHelp'','@;
			put "'directories=0,titlebar=0,toolbar=0,location=0,status=0,menubar=0,scrollbars=yes,resizable=no,width=550,height=650,top=150,left=850');";
		put '}';

		/******************************/
		/** Apply Tablesorter Plugin **/
		/******************************/
		put 'function enhanceTable() {';
			put '$jload(".content-table").tablesorter({';
				put 'cssInfoBlock : "no-sort",';
				put 'sortReset : true,';
				put 'widgets: [ ''stickyHeaders'' ],';
				/*put 'widgetOptions : { stickyHeaders_offset : total_fixed_height }';*/
				put 'widgetOptions : { stickyHeaders_offset : $jload("#content").offset().top }';
			put '});';
		put '}';

	run;

	/*****************************************************************/
	/** Output the Highcharts API call if chart toggling is enabled **/
	/*****************************************************************/
	%if ("&chart_enabled" = "Y") and ("&chart_plugin" = "Y") %then %do;
		data _null_;
			file _webout lrecl=&lrecl;
			set chart_plugin;
			put text;
		run;
	%end;

	data _null_;
		file _webout lrecl=&lrecl;

		/***************************************/
		/** Insert dynamically created JQuery **/
		/***************************************/
		put "&add_jquery";

		put '</script>';
		/*********************************************************************************************************************/
		/** End: Scripting Section 																							**/
		/*********************************************************************************************************************/

		put '</body>';
		/******************************/
		/** End: HTML <BODY> Section **/
		/******************************/

		put '</html>';
		/********************************/
		/** End: HTML Document Section **/
		/********************************/

	run;
	/*************************************************************************************************************************/
	/** End: Web Page Output																								**/
	/*************************************************************************************************************************/

%exit: %mend global_container;
%global_container;
