******************************************************************************************************************************;
** Program: DashboardCompiler.sas																							**;
** Purpose: To compile the web parts used in dashboards and deliver the markup back to the dashboard web part via AJAX		**;
**																															**;
** Date: 01/01/2014																											**;
** Developer: John Sandoval																									**;
** Application Version: 2.0																									**;
**																															**;
** Data sources: Defined in Metadata																						**;
**																															**;
** Includes (pay attention to UNC vs. Relative pathing):																	**;
**  \\lmv08-metdb02\imd\web_server\admin\&app_version\programs\DashboardWebParts.sas										**;
**																															**;
** Notes:																													**;
** History:																													**;
**		01/01/2014 John Sandoval - Initial Release																			**;
**																															**;
******************************************************************************************************************************;

%macro compile_dashboard;

	/** Define some dashboard-specific flags **/
	%if not %symexist(customize) %then %do;
		%let customize = N;
	%end;
	%if not %symexist(layout_save) %then %do;
		%let layout_save = N;
	%end;

	%if "&layout_save" = "N" %then %do;
		%let standard_display = Y;
	%end;
	%else %do;
		%let standard_display = N;
	%end;

	%if "&standard_display" = "Y" %then %do;
		/** Get dashboard web parts list for user **/
		data dashboard_web_parts;
			set &admlib..dashboard_web_parts;
			if user_id = "&_METAPERSON";
		run;

		/** Determine the number of Web Parts for the Report **/
		%global num_dashboard_web_parts;
		%let num_dashboard_web_parts = 0;
		data _null_;
			set dashboard_web_parts end=last;
			if last then call symputx('num_dashboard_web_parts', compress(_n_));
		run;

		/** Loop through Web Parts to compile output data sets **/
		%if %eval(&num_dashboard_web_parts) > 0 %then %do;

			%do dashboard_web_part_counter = 1 %to %eval(&num_dashboard_web_parts);

				data _null_;
					set dashboard_web_parts (firstobs = &dashboard_web_part_counter obs = &dashboard_web_part_counter);
					call symputx('web_part_id', web_part_id);
					call symputx('level', level);
					call symputx('top', top);
					call symputx('left', left);
				run;

				/** Call Web Parts Program **/
				%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\DashboardWebParts.sas";

				/** Compile Web Parts **/
				data web_part(keep=text);
					length text $5000.;
					set web_part end=last;
					if _n_ = 1 then do;
						text = cats('<div id="web-part-', "&web_part_id",
									'" class="draggable" style="display: inline-block;',
																'position: absolute;',
																'top:', "&top", 'px;',
																'left:', "&left", 'px;">',
									text);
					end;
					if last then do;
						text = cats(text,
									'</div>');
					end;
				run;

				%if %sysfunc(exist(work.dashboard)) = 0 %then %do;
					data dashboard(keep=text);
						length text $5000.;
						set web_part;
					run;
				%end;
				%else %do;
					data dashboard(keep=text);
						set dashboard web_part;
					run;
				%end;

			%end;

		%end;
		%else %do;
			%if "&customize" = "Y" %then %do;
			/** If no dashboard web parts then alert the user to add web parts **/
				data dashboard(keep=text);
					length text $5000.;
					text = cats('<div style="width: 100%; text-align: center;"><img src="/SAS/images/', "&app_version", '/Titles/Add_Web_Part_Text.png" alt="AddWebPart" style="margin-top: 140px;" /></div>'); output;
				run;
				

			%end;
			%else %do;
			/** If no dashboard web parts then display a default web part (ID=0) **/
				
				%let web_part_id = 0;

				%inc "\\lmv08-metdb02\imd\web_server\admin\&app_version.\programs\DashboardWebParts.sas";

				data dashboard(keep=text);
					length text $5000.;
					set web_part;
				run;

			%end;
		%end;

		/** Create containers for dashboard web parts and available web parts **/
		data dashboard(keep=text);
			set dashboard end=last;
			if _n_ = 1 then do;
				text = cats('<div id="dashboard-wrapper">',
							text);
			end;
			if last then do;
				text = cats(text,
							'</div>');
			end;
		run;


		/** Use custom permissions to build the user a list of dashboard web parts **/


		/** Build the dashboard web parts into a carousel UI **/
		%if "&customize" = "Y" %then %do;
			data available_web_parts(keep=text);
				length text $5000.;
				text = '<div id="web-part-browser" class="sky-carousel" style="display: none; width: 98%;">'; output;
				text = '<div class="sky-carousel-wrapper">'; output;
				text = '<ul class="sky-carousel-container">'; output;

				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Sample1.png" alt="" /><div class="sc-content"><h2>TN Billing Graph</h2><p>Verizon<br /><br />('); output;
				text = cats('<a class="fancybox" href="', "&uri_prefix", '&ajax_request=Y&web_part_id=3&selected_web_part=1">Add</a>'); output;
				text = ')</p></div></li>'; output;

				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 2</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 3</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 4</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 5</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 6</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 7</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Sample2.png" alt="" /><div class="sc-content"><h2>SLA Snapshot</h2><p>Verizon<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 9</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 10</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 11</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 12</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 13</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 14</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;
				text = cats('<li><img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Placeholder.jpg" alt="" /><div class="sc-content"><h2>Report Name 15</h2><p>Report Description<br /><br />(<a href="#">Add</a>)</p></div></li>'); output;

				text = '</ul>'; output;
				text = '</div>'; output;
				text = '</div>'; output;
			run;

			data dashboard(keep=text);
				set dashboard available_web_parts;
			run;
		%end;

		/** If web part requested via AJAX then output the text immediately to the web page **/
		%if "&ajax_request" = "Y" %then %do;
			data _null_;
				file _webout lrecl=5000;
				set dashboard;
				put text;
			run;
		%end;
	%end;
	%else %if "&layout_save" = "Y" %then %do;
		/** Save user's custom layout **/
		data web_part_layout_top(keep=user_id web_part_id level top)
			 web_part_layout_left(keep=user_id web_part_id level left);
			set sashelp.vmacro;
			length user_id $100. web_part_id level 8. top left $50.;
			if index(name, 'WEB_PART') > 0;
			user_id = "&_METAPERSON";
			web_part_id = input(scan(name, -1, '_'), 8.);
			level = 1;
			if index(name, 'TOP') > 0 then do;
				top = compress(value);
				output web_part_layout_top;
			end;
			if index(name, 'LEFT') > 0 then do;
				left = compress(value);
				output web_part_layout_left;
			end;
		run;

		proc sort data = web_part_layout_top;
			by user_id web_part_id;
		run;

		proc sort data = web_part_layout_left;
			by user_id web_part_id;
		run;

		data dashboard_layout;
			merge web_part_layout_top(in=a) web_part_layout_left(in=b);
			by user_id web_part_id;
		run;

		%macro trylock(member=, timeout=3, retry=0.1);
			%local starttime;
			%let starttime = %sysfunc(datetime());
			%do %until(&syslckrc <= 0 or %sysevalf(%sysfunc(datetime()) > (&starttime + &timeout)));
				data _null_;
					dsid = 0;
					do until (dsid > 0 or datetime() > (&starttime + &timeout));
						dsid = open("&member");
						if (dsid = 0) then rc = sleep(&retry);
					end;
					if (dsid > 0) then rc = close(dsid);
				run;

				lock &member;
			%end;
		%mend trylock;

		%trylock(member=&admlib..dashboard_web_parts)
		data &admlib..dashboard_web_parts;
			set &admlib..dashboard_web_parts;
			if user_id = "&_METAPERSON" then delete;
		run;

		data &admlib..dashboard_web_parts (compress=yes);
			set &admlib..dashboard_web_parts dashboard_layout;
		run;

		lock &admlib..dashboard_web_parts clear;

		/** Since this was server-side request the instructional variable must be reset **/
		%let layout_save = N;
	%end;

%mend compile_dashboard;
%compile_dashboard;