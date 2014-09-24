******************************************************************************************************************************;
** Program: GlobalWebParts.sas																								**;
** Purpose: All web parts used by global components of ClearView (Reports page, Dashboard, Favorites, Help, etc).			**;
**			It could also grow to include global reporting web parts.														**;
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

%macro global_web_parts;

/*****************************************************************************************************************************/
/** Home Page Dashboard Title Web Part 																						**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 1 %then %do;

		data web_part(keep=text);
			length text $5000.;
			/** Dashboard Title Image **/
			text = cats('<img src="/SAS/images/', "&app_version", '/Titles/Dashboard_Text.png" width="252" height="38" alt="Dashboard" />'); output;
			/** Customize Link **/
			text = '<div id="content-customize" style="display: none;"><a href="#">customize</a></div>'; output;
			text = '<div id="content-customize-wait" style="display: none;"><a href="#">customize</a></div>'; output;
			/** Customize Menu **/
			text = '<div id="dashboard-customize-menu" style="display: none;">'; output;
			text = '<span id="dashboard-customize-add" class="dashboard-customize-menu"><a href="#">Add a Web Part</a></span>'; output;
			text = '<span id="dashboard-customize-remove" class="dashboard-customize-menu"><a href="#">Remove a Web Part</a></span>'; output;
			text = '<span id="dashboard-customize-save" class="dashboard-customize-menu"><a href="#">Save Layout</a></span>'; output;
			text = '<span id="dashboard-customize-home" class="dashboard-customize-menu"><a href="#">Return Home</a></span>'; output;
			text = '</div>'; output;
		run;

		/** Get dashboard web parts list for user **/
		data dashboard_web_parts;
			set &admlib..dashboard_web_parts;
			if user_id = "&_METAPERSON";
		run;

		/** Determine the number of Web Parts for the Report **/
		%let num_dashboard_web_parts = 0;
		data _null_;
			set dashboard_web_parts end=last;
			if last then call symputx('num_dashboard_web_parts', compress(_n_));
		run;

		/************************************************************************/
		/** Begin: Javascript that will handle the customize menu click events **/
		/************************************************************************/
		/********************/
		/** Customize link **/
		/********************/
		data customize(keep=text);
			length text $5000.;
			text = '$jload(''#content-customize'').on(''click'', function() {'; output;

			/** Swap out the customize link so that it can't be clicked more than once **/
			text = '$jload(''#content-customize'').hide(0);'; output;
			text = '$jload(''#content-customize-wait'').show(0);'; output;

			/** Display the loading animation **/
			text = cats('$jload(''#dashboard-container'').html($jload(''#hidden-loading-container'').html());'); output;
			/** Make the AJAX call **/
			text = cats('$jload(''#dashboard-container'').load(''/SASStoredProcess/do'', {',
						'_program:', "'&_program',",
						'_sessionid:', "'&_sessionid',",
						'dashboard:', "'Y',",
						'customize:', "'Y',",
						/*'_debug:', "'131',",*/
						'ajax_request:', "'Y'",
						'}, function() {',

						/** Set the container height to the cumulative heights of the web parts (plus some extra wiggle room) **/
						'var wrapperHeight = 0;',
     					'$jload.each($jload(''#dashboard-wrapper'').children(), function(){',
            			'	wrapperHeight += $jload(this).height();',
     					'});',
     					'$jload(''#dashboard-wrapper'').height(wrapperHeight + 50);',

						/** Activate the Web Part Browser (still hidden) **/
						'$jload(''.sky-carousel'').carousel( {',

						'itemWidth: 170,',
						'itemHeight: 240,',
						'distance: 15,',
						'startIndex: 0,',
						'selectedItemDistance: 50,',
						'selectedItemZoomFactor: 1,',
						'unselectedItemZoomFactor: 0.67,',
						'unselectedItemAlpha: 0.6,',
						'motionStartDistance: 170,',
						'topMargin: 119,',
						'gradientStartPoint: 0.35,',
						'gradientOverlayColor: ''#f5f5f5'',',
						'gradientOverlaySize: 190,',
						/*'reflectionDistance: 1,',
						'reflectionAlpha: 0.35,',
						'reflectionVisible: true,',
						'reflectionSize: 70,',*/
						'selectByClick: true',

						'});',

						/** Activate FancyBox on Add web part links **/
						'$jload(''.fancybox'').fancybox({',
							'type : ''ajax'',',
							'ajax : { cache: false }', /** This can be set to TRUE in production if performance is an issue **/
						'});',

						/** Highlight the Add Web Part link **/
						%if %eval(&num_dashboard_web_parts) = 0 %then %do;
						'$jload(''#dashboard-customize-add'').addClass(''content-customize-highlight'');',
						'$jload(''#dashboard-customize-add'').effect(''pulsate'', {times: 3}, 4000);',
						%end;

						/** Display the customize menu **/
						'$jload(''#content-customize-wait'').hide(''slide'', { direction: ''right'' }, 300, function() {',
							'$jload(''#dashboard-customize-menu'').show(''slide'', { direction: ''right'' }, 300);',
						'});',

						/** Add CSS styling to draggable web parts **/
						'$jload(''.draggable'').addClass(''draggable-ready'');',

						/** Enable draggable web parts **/
						'$jload(''.draggable'').draggable({ containment: ''#dashboard-wrapper'', scroll: false, grid: [ 20,20 ] });',
						'});'); output;
			text = '});'; output;
		run;

		data jquery(keep=text);
			length text $5000.;
			set customize;
		run;

		/*************************/
		/** Add a Web Part link **/
		/*************************/
		data add_web_part(keep=text);
			length text $5000.;
			text = '$jload(''#dashboard-customize-add'').on(''click'', function() {'; output;
				/** If the dashboard container is on screen then hide it and show the web part selector **/
				text = 'if ($jload(''#dashboard-wrapper'').is('':visible'')) {'; output;
					text = '$jload(''#dashboard-wrapper'').hide(''slide'', { direction: ''up'' }, 1000, function() {'; output;
						text = '$jload(''#web-part-browser'').show(''slide'', { direction: ''left'' }, 1000);'; output;
						text = '$jload(''#dashboard-customize-remove, #dashboard-customize-save'').hide(0);'; output;
						text = '$jload(''#dashboard-customize-add a'').html(''Back'');'; output;
						%if %eval(&num_dashboard_web_parts) = 0 %then %do;
						text = '$jload(''#dashboard-customize-add'').removeClass(''content-customize-highlight'');'; output;
						%end;
					text = '});'; output;
				/** If the web part selector is on screen then hide it and show the dashboard container **/
				text = '} else {'; output;
					text = '$jload(''#web-part-browser'').hide(''slide'', { direction: ''left'' }, 1000, function() {'; output;
						text = '$jload(''#dashboard-wrapper'').show(''slide'', { direction: ''up'' }, 1000);'; output;
						text = '$jload(''#dashboard-customize-add a'').html(''Add a Web Part'');'; output;
						text = '$jload(''#dashboard-customize-remove, #dashboard-customize-save'').show(0);'; output;
						%if %eval(&num_dashboard_web_parts) = 0 %then %do;
						text = '$jload(''#dashboard-customize-add'').addClass(''content-customize-highlight'');'; output;
						%end;
					text = '});'; output;
				text = '};'; output;
			text = '});'; output;
		run;

		data jquery(keep=text);
			length text $5000.;
			set jquery add_web_part;
		run;

		/****************************/
		/** Remove a Web Part link **/
		/****************************/
		data remove_web_part(keep=text);
			length text $5000.;
			text = '$jload(''#dashboard-customize-remove'').on(''click'', function() {'; output;
				text = 'if ($jload(''.draggable'').hasClass(''draggable-remove'')) {'; output;
					text = '$jload(''.draggable'').removeClass(''draggable-remove'');'; output;
					text = '$jload(''#dashboard-customize-add, #dashboard-customize-save'').show(0);'; output;
					text = '$jload(''#dashboard-customize-remove a'').html(''Remove a Web Part'');'; output;
				text = '} else {'; output;
					text = '$jload(''.draggable'').addClass(''draggable-remove'');'; output;
					text = '$jload(''#dashboard-customize-remove a'').html(''Back'');'; output;
					text = '$jload(''#dashboard-customize-add, #dashboard-customize-save'').hide(0);'; output;
				text = '}'; output;
			text = '});'; output;

			/** Script to handle the click event of .draggable-remove is in GlobalContainer.sas (event delegation) **/
		run;

		data jquery(keep=text);
			length text $5000.;
			set jquery remove_web_part;
		run;

		/**********************/
		/** Save Layout link **/
		/**********************/
		data save_layout_1(keep=text);
			length text $5000.;
			set dashboard_web_parts end=last;
			text = cats('var position_', web_part_id, '= $jload(''#web-part-', web_part_id, ''').position();');
			if _n_ = 1 then do;
				text = cats('$jload(''#dashboard-customize-save'').on(''click'', function() {',
							text); 
			end;
		run;

		data save_layout_2(keep=text);
			length text $5000.;
			set dashboard_web_parts end=last;
			text = cats('web_part_top_', web_part_id, ': position_', web_part_id, '.top,', '0D'x,
						'web_part_left_', web_part_id, ': position_', web_part_id, '.left,');
			if _n_ = 1 then do;
				text = cats('$jload.ajax({',
							'type: ''GET'',',
							'url: ''/SASStoredProcess/do?%nrstr(&)_sessionid=', "&_sessionid", '%nrstr(&)_program=', "&_program", ''',',
							'data: {',
							text);
			end;
			if last then do;
				text = cats(text,
							'dashboard: ''Y'',',
							'layout_save: ''Y'',',
							/*'_debug:', "'131',",*/
							'ajax_request: ''Y''',
							'}',
							'})',
							'.done(function() {',
							/*'alert(''Save Layout attempt has finished'');',*/
							'window.location.href = ''/SASStoredProcess/do?%nrstr(&)_sessionid=', "&_sessionid", '%nrstr(&)_program=', "&_program", '''',
							'})',
							'})');
			end;
		run;

		data jquery(keep=text);
			length text $5000.;
			set jquery save_layout_1 save_layout_2;
		run;

		/**********************/
		/** Return Home link **/
		/**********************/
		data return_home(keep=text);
			length text $5000.;
			text = '$jload(''#dashboard-customize-home'').on(''click'', function() {'; output;
			text = 'location.reload();'; output;
			text = '})'; output;
		run;

		data jquery(keep=text);
			length text $5000.;
			set jquery return_home;
		run;

		/** Build JQuery string to send to global container **/
		data _null_;
			set jquery end=last;
			retain temp;
			length temp $25000.;
			temp = cats(temp, '0D'x, trim(text));
			if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
		run;
		/**********************************************************************/
		/** End: Javascript that will handle the customize menu click events **/
		/**********************************************************************/

	%end;

/*****************************************************************************************************************************/
/** Home Page Dashboard Web Part																							**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 2 %then %do;

		/** Create the dashboard container element **/
		data web_part(keep=text);
			length text $5000.;
			text = '<div id="dashboard-container">'; output;
			text = '</div>'; output;
		run;

		/** Get dashboard web parts list for user **/
		data dashboard_web_parts;
			set &admlib..dashboard_web_parts;
			if user_id = "&_METAPERSON";
		run;

		/** Determine the number of Web Parts for the Report **/
		%let num_dashboard_web_parts = 0;
		data _null_;
			set dashboard_web_parts end=last;
			if last then call symputx('num_dashboard_web_parts', compress(_n_));
		run;

		/************************************************************************/
		/** Javascript to make AJAX onload call to compile dashboard web parts **/
		/************************************************************************/
		data jquery(keep=text);
			length text $5000.;
			/** Display the loading animation **/
			text = cats('$jload(''#dashboard-container'').html($jload(''#hidden-loading-container'').html());'); output;
			/** Make the AJAX call **/
			text = cats('$jload(''#dashboard-container'').load(''/SASStoredProcess/do'', {',
						'_program:', "'&_program',",
						'_sessionid:', "'&_sessionid',",
						'dashboard:', "'Y',",
						/*'_debug:', "'131',",*/
						'ajax_request:', "'Y'",
						'}, function() {',
						
							/** Set the container height based on the top-most and bottom-most web part positions **/
							'var minTop = 500;',
							'var maxBottom = 0;',
							'var wrapperHeight = 0;',
	     					'$jload.each($jload(''#dashboard-wrapper'').children(), function(){',
								/** For absolute or fixed elements evaluate the TOP and HEIGHT attributes **/
								'if ($jload(this).css(''top'') != ''auto'') {',
									'if (parseInt($jload(this).css(''top''), 10) < minTop) {',
										'minTop = parseInt($jload(this).css(''top''), 10);',
									'}',
									'if (parseInt($jload(this).css(''top''), 10) + $jload(this).height() > maxBottom) {',
										'maxBottom = parseInt($jload(this).css(''top''), 10) + $jload(this).height();',
									'}',
								'}',
								/* 'alert(minTop + ''  '' + maxBottom);', */
	     					'});',
							'$jload(''#dashboard-wrapper'').height(maxBottom - minTop);',

							/** Show the customize link **/
							'$jload(''#content-customize'').show(''slide'', { direction: ''right'' }, 500);',
							%if %eval(&num_dashboard_web_parts) = 0 %then %do;
								/** Enable Dashboard Slideshow web part **/
								'$jload(''#dashboard-slideshow'').cycle({',
									'fx: ''fade'',',
									'pause: ''true''',
								'});', '0D'x,
								/** Hide the REMOVE and SAVE dashboard customization links **/
								'$jload(''#dashboard-customize-remove, #dashboard-customize-save'').hide(0);',
							%end;

						'});'); output;
		run;

		data _null_;
			set jquery end=last;
			retain temp;
			length temp $25000.;
			temp = cats(temp, '0D'x, trim(text));
			if last then call symputx('onload_jquery', cats("&onload_jquery", '0D'x, trim(temp)));
		run;

	%end;

/*****************************************************************************************************************************/
/** Dashboard Web Part Setup (Lightbox)																						**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 3 %then %do;

		data web_part_setup(keep=text);
			length text $5000.;
			/** Dashboard Web Part Setup container **/
			text = '<div class="web-part-setup">'; output;
				/** Photo DIV **/
				text = cats('<div class="web-part-setup-image">',
								'<div class="web-part-image-helper">',
									'<img src="/SAS/images/', "&app_version", '/Dashboard_Thumbs/Sample1_Large.png" alt="WebPartImage" onError="this.onerror=null;this.src=''/SAS/images/', "&app_version", '/Dashboard_Thumbs/No_Image.png'';" />',
								'</div>',
							'</div>'); output;
				/** Filter DIV **/
				text = cats('<div class="web-part-setup-filter" style="font: 20px bold Calibri,Tahoma;">Filters</div>'); output;
				/** Button DIV **/
				text = cats('<div class="web-part-setup-button">'); output;
					/** Button **/
					text = cats('<div id="add-web-part-', "&selected_web_part", '" class="submit-button-1 add-web-part-commit" style="width: 350px; font-size: 20px;">Add to My Dashboard</div>'); output;

				text = '</div>'; output;
			text = '</div>'; output;
		run;

		/** Create a standard data set for output **/
		data web_part;
			set web_part_setup;
		run;
	
		/** If web part requested via AJAX then output the text immediately to the web page **/
		%if "&ajax_request" = "Y" %then %do;
			data _null_;
				file _webout lrecl=5000;
				set web_part;
				put text;
			run;
		%end;

	%end;

/*****************************************************************************************************************************/
/** Report Navigation Page Title Web Part																					**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 100 %then %do;

		data web_part(keep=text);
			length text $5000.;
			/** Dashboard Title Image - requires an container with a bottom margin because of the lower-case P **/
			text = cats('<div style="position: relative; width: 172px; height: 38px; margin-bottom: 13px; overflow-y: visible;">',
						'<img src="/SAS/images/', "&app_version", '/Titles/Reports_Text.png" width="172" height="50" alt="Reports" />',
						'</div>'); output;
		run;

	%end;

/*****************************************************************************************************************************/
/** Report Navigation Page Initial Container Web Part																		**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 101 %then %do;

		/** Get a list of master accounts that the user can see **/
		proc sort data = save.report_access out = master_accounts(keep=master_account master_account_sort);
			by master_account_sort master_account;
		run;

		data master_accounts;
			set master_accounts;
			by master_account_sort master_account;
			if last.master_account;
			if master_account = 'Top Menu' then delete;
		run;

		/** Determine the number of master accounts **/
		%let num_master_accounts = 0;
		data _null_;
			set master_accounts end=last;
			if _n_ = 1 then call symputx('first_account', master_account);
			if last then call symputx('num_master_accounts', compress(_n_));
		run;

		/** Output Master Account links into the navigation container **/	
		data master_accounts;
			set master_accounts end=last;
			length text $5000.;
			/** If first and last account **/
			if _n_ = 1 and last then do;
				text = cats('<div id="reports-navigation">',
							'<div id="reports-account-list">',

							'<div class="reports-master-account" onclick="reportFilter(''', master_account, ''', this);">',
							master_account,
							'</div>',

							'</div>',
							'<div id="reports-list"></div>',
							'</div>');
			end;
			/** If just first account **/
			else if _n_ = 1 then do;
				text = cats('<div id="reports-navigation">',
							'<div id="reports-account-list">',
							'<div class="reports-master-account" onclick="reportFilter(''', master_account, ''', this);">',
							master_account,
							'</div>');
			end;
			/** If just a middle account **/
			else if not last then do;
				text = cats('<div class="reports-master-account" onclick="reportFilter(''', master_account, ''', this);">',
							master_account,
							'</div>');
			end;
			/** If just the last account **/
			else if last then do;
				text = cats('<div class="reports-master-account" onclick="reportFilter(''', master_account, ''', this);">',
							master_account,
							'</div>',

							'</div>', /** End reports-account-list **/
							'<div id="reports-list"></div>',
							'</div>');/** End reports-navigation **/
			end;

		run;

		/** Create a standard data set for output **/
		data web_part(keep=text);
			length text $5000.;
			set master_accounts;
		run;

		/** Javascript to make AJAX call to display the selected master account **/
		data jquery(keep=text);
			length text $5000.;
			text = 'function reportFilter(masterAccount, element) {'; output;
			text = '$jload(''.reports-master-account'').removeClass(''reports-master-account-selected'');'; output;
			text = '$jload(element).addClass(''reports-master-account-selected'');'; output;
			/** This line gets the current reports list height to keep the screen from jumping if both before and after lists have vertical scrolling **/
			text = 'var listHeight = $jload(''#reports-list-content'').height();'; output;
			/** Show the loading notification **/
			text = '$jload(''#reports-list'').html(''<div style=""""height: '' + listHeight + ''px;"""">'' + $jload(''#hidden-loading-container'').html() + ''</div>'');'; output;
			/** Call the web part that processes and output the reports list **/
			text = cats('$jload(''#reports-list'').load(''/SASStoredProcess/do'', {',
						'_program:', "'&_program',",
						'_sessionid:', "'&_sessionid',",
						'web_part_id:', "'102',",
						'master_account:', 'masterAccount,',
						'_debug:', "'0',",
						'ajax_request:', "'Y'",
						'}, function() {',
										/** Update the Hash with the master account to differentiate AJAX content for back button **/
										'window.location.hash = ''#'' + masterAccount;',
										'});'); output;
			text = '}'; output;
		run;

		data _null_;
			set jquery end=last;
			retain temp;
			length temp $25000.;
			temp = cats(temp, '0D'x, trim(text));
			if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
		run;

		/** Function to detect hash changes and allow AJAX content to be navigated with back buttons **/
			data jquery(keep=text);
				length text $1500.;
				/** Detect changes to the Hash - can include browser capability check if anyone has issues **/
				/** Hash is used because HTML 5 pushState() is only available for IE in v10+ **/
				text = 'window.onhashchange = function() {'; output;
					/** If Hash exists compare it to the select value of the drop down **/
					text = 'if (window.location.hash.length > 1) {'; output;
						/** If the current hash does not equal the current selected value then update the selected value **/
						text = 'var masterAccount = $jload(''.reports-master-account-selected'').text();'; output;
						text = cats('if (window.location.hash.substring(1) != masterAccount) {',
										/** Pass the correct master account value and also the div element that holds that value **/
										'reportFilter(window.location.hash.substring(1),',
													  '$jload(''.reports-master-account'').filter(function() {',
																							'return $jload(this).text() === window.location.hash.substring(1);',
																							'})',
													 ');',
									'}'); output;
					/** If Hash does not exist then page is on top level - refresh **/
					text = '} else {'; output;
						text = 'window.location.reload();'; output;
					text = '}'; output;
				text = '}'; output;
			run;

			data _null_;
				set jquery end=last;
				retain temp;
				length temp $25000.;
				temp = cats(temp, '0D'x, trim(text));
				if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
			run;

		/** JavaScript to autocall the reportFilter() method if the user only has 1 master account **/
		%if %eval(&num_master_accounts) = 1 %then %do;
			data jquery(keep=text);
				length text $1500.;
				text = cats('reportFilter(''', "&first_account", ''', $jload(''.reports-master-account''));'); output;
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
/** Report Navigation Page Report List Web Part																				**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 102 %then %do;

		/** Capture server sessions **/
		data _null_;
			set save.sessions;
			call symputx('wrlnsession', wrlnsession);
			call symputx('mobsession', mobsession);
			call symputx('verizsession', verizsession);
		run;

		/** Constrain reports by selected master account **/
		data reports_list;
			set save.report_access;
			if master_account = "&master_account";
		run;

		proc sort data = reports_list;
			by sub_group_1_sort sub_group_1 sub_group_2_sort sub_group_2 sub_group_3_sort sub_group_3 objName;
		run;

		/** Create reports list **/
		data reports_list(keep=text);
			set reports_list end=final;
			by sub_group_1_sort sub_group_1 sub_group_2_sort sub_group_2 sub_group_3_sort sub_group_3 objName;
			if sub_group_1 in ('', 'Standard Suite of Reports') then sub_group_1 = 'Standard Reports';
			length text $5000. session $250. uri $1000.;
			/** Set the session based on the stored process server **/
			if stored_process_server = 'MOBILITY' then session = "&mobsession";
			else if stored_process_server = 'WIRELINE' then session = "&wrlnsession";
			esle if stored_process_server = 'VERIZON' then session = "&verizsession";
			/** Create the URI for each stored process **/
			uri = cats('/SASStoredProcess/do?&amp;_sessionid=', session, '&amp;_program=', tranwrd(trim(location), ' ', '%20'), tranwrd(trim(objName), ' ', '%20'));
			/** Create the markup for each container scenario **/
			if _n_ = 1 and last.sub_group_1 then do;
				if first.sub_group_2 then do;
					text = cats('<div id="reports-list-content">',
								'<div class="vertical-gradient-bar"></div>',
								'<div class="report-group">',
								'<div class="report-group-title">', sub_group_1, '</div>',
								'<div class="horizontal-gradient-bar"></div>',
								'<div class="report-sub-group">',
								'<div class="report-sub-group-title">', sub_group_2, '</div>',
								'<div><a href="', uri, '">', objName, '</a></div>',
								'</div>',
								'</div>'); output;
				end;
				else do;
					text = cats('<div id="reports-list-content">',
								'<div class="vertical-gradient-bar"></div>',
								'<div class="report-group">',
								'<div class="report-group-title">', sub_group_1, '</div>',
								'<div class="horizontal-gradient-bar"></div>',
								'<div><a href="', uri, '">', objName, '</a></div>',
								'</div>'); output;
				end;
			end;
			else if _n_ = 1 then do;
				if first.sub_group_2 then do;
					if last.sub_group_2 then do;
						text = cats('<div id="reports-list-content">',
									'<div class="vertical-gradient-bar"></div>',
									'<div class="report-group">',
									'<div class="report-group-title">', sub_group_1, '</div>',
									'<div class="horizontal-gradient-bar"></div>',
									'<div class="report-sub-group">',
									'<div class="report-sub-group-title">', sub_group_2, '</div>',
									'<div><a href="', uri, '">', objName, '</a></div>',
									'</div>'); output;
					end;
					else do;
						text = cats('<div id="reports-list-content">',
									'<div class="vertical-gradient-bar"></div>',
									'<div class="report-group">',
									'<div class="report-group-title">', sub_group_1, '</div>',
									'<div class="horizontal-gradient-bar"></div>',
									'<div class="report-sub-group">',
									'<div class="report-sub-group-title">', sub_group_2, '</div>',
									'<div><a href="', uri, '">', objName, '</a></div>'); output;
					end;
				end;
				else do;
					text = cats('<div id="reports-list-content">',
								'<div class="vertical-gradient-bar"></div>',
								'<div class="report-group">',
								'<div class="report-group-title">', sub_group_1, '</div>',
								'<div class="horizontal-gradient-bar"></div>',
								'<div><a href="', uri, '">', objName, '</a></div>'); output;
				end;
			end;
			else if first.sub_group_1 and last.sub_group_1 then do;
				if first.sub_group_2 then do;
					text = cats('<div class="report-group">',
								'<div class="report-group-title">', sub_group_1, '</div>',
								'<div class="horizontal-gradient-bar"></div>',
								'<div class="report-sub-group">',
								'<div class="report-sub-group-title">', sub_group_2, '</div>',
								'<div><a href="', uri, '">', objName, '</a></div>',
								'</div>',
								'</div>'); output;
				end;
				else do;
					text = cats('<div class="report-group">',
								'<div class="report-group-title">', sub_group_1, '</div>',
								'<div class="horizontal-gradient-bar"></div>',
								'<div><a href="', uri, '">', objName, '</a></div>',
								'</div>'); output;
				end;
			end;
			else if first.sub_group_1 then do;
				if first.sub_group_2 then do;
					if last.sub_group_2 then do;
						text = cats('<div class="report-group">',
									'<div class="report-group-title">', sub_group_1, '</div>',
									'<div class="horizontal-gradient-bar"></div>',
									'<div class="report-sub-group">',
									'<div class="report-sub-group-title">', sub_group_2, '</div>',
									'<div><a href="', uri, '">', objName, '</a></div>',
									'</div>'); output;
					end;
					else do;
						text = cats('<div class="report-group">',
									'<div class="report-group-title">', sub_group_1, '</div>',
									'<div class="horizontal-gradient-bar"></div>',
									'<div class="report-sub-group">',
									'<div class="report-sub-group-title">', sub_group_2, '</div>',
									'<div><a href="', uri, '">', objName, '</a></div>'); output;
					end;
				end;
				else do;
					text = cats('<div class="report-group">',
								'<div class="report-group-title">', sub_group_1, '</div>',
								'<div class="horizontal-gradient-bar"></div>',
								'<div><a href="', uri, '">', objName, '</a></div>'); output;
				end;
			end;
			else if last.sub_group_1 and not final then do;
				if last.sub_group_2 then do;
					text = cats('<div><a href="', uri, '">', objName, '</a></div>',
								'</div>',
								'</div>'); output;
				end;
				else do;
					text = cats('<div><a href="', uri, '">', objName, '</a></div>',
								'</div>'); output;
				end;
			end;
			else if not final then do;
				if first.sub_group_2 then do;
					if last.sub_group_2 then do;
						text = cats('<div class="report-sub-group">',
									'<div class="report-sub-group-title">', sub_group_2, '</div>',
									'<div><a href="', uri, '">', objName, '</a></div>',
									'</div>'); output;
					end;
					else do;
						text = cats('<div class="report-sub-group">',
									'<div class="report-sub-group-title">', sub_group_2, '</div>',
									'<div><a href="', uri, '">', objName, '</a></div>'); output;
					end;
				end;
				else if last.sub_group_2 then do;
					text = cats('<div><a href="', uri, '">', objName, '</a></div>',
								'</div>'); output;
				end;
				else do;
					text = cats('<div><a href="', uri, '">', objName, '</a></div>'); output;
				end;
			end;
			else if final then do;
				if last.sub_group_2 then do;
					text = cats('<div><a href="', uri, '">', objName, '</a></div>',
								'</div>',
								'</div>',
								'</div>'); output;
				end;
				else do;
					text = cats('<div><a href="', uri, '">', objName, '</a></div>',
							'</div>',
							'</div>'); output;
				end;
			end;
		run;

		/** Create a standard data set for output **/
		data web_part;
			set reports_list;
		run;
	
		/** If web part requested via AJAX then output the text immediately to the web page **/
		%if "&ajax_request" = "Y" %then %do;
			data _null_;
				file _webout lrecl=5000;
				set web_part;
				put text;
			run;
		%end;

	%end;

/*****************************************************************************************************************************/
/** Report Help - Display Report Help Entries web part																		**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 400 %then %do;

		/** Determine which report called the Help **/
		%let sp_ObjId=;
		%let report_title=;
		data _null_;
			set save.report_access;
			if "&_PROGRAM" = cats(Location, ObjName) then do;
				call symputx('sp_ObjId', ObjId);
				call symputx('report_title', catx(' ', cats(master_account, ':'), ObjName));
			end;
		run;

		/** Begin web page output **/
		data _null_;
			file _webout lrecl=&lrecl;
			put '<!doctype html>';
			put '<html lang="en-US">';
			/** Head **/
			put '<head>';
			put "<title>Intrado ClearView &app_version - Help</title>";
			put '<meta charset="UTF-8">';
			put '<link rel="stylesheet" type="text/css" href="/SAS/stylesheet/' "&app_version" '/GlobalContainer.css">';
			put '<link rel="stylesheet" type="text/css" href="/SAS/stylesheet/' "&app_version" '/GlobalContainer_Mobile.css">';
			put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-1.10.2.min.js"></script>';
			put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-ui-1.10.3.min.js"></script>';
			put '<script src="/SAS/JavaScript/' "&app_version" '/Minified/jquery-ui-touch-punch.min.js"></script>';
			put '</head>';
			/** Body **/
			put '<body id="body" class="help">';
			put '<div id="viewport">';
			/** Top Bar **/
			put '<div id="top-bar" class="help">';
				put '<span id="top-bar-left-image" class="help"><img src="/SAS/images/' "&app_version" '/Logos/Help_Logo.png" alt="Help" /></span>';
				put '<span id="top-bar-right-image" class="help"><img src="/SAS/images/' "&app_version" '/Logos/ClearView_Logo.png" alt="ClearView" /></span>';
			put '</div>';
			put '<div id="top-bar-placeholder" class="help"></div>';
			/** Content Header **/
			put '<div id="content-header" class="help">';
				put '<div id="content-title" class="help">';
					put "<span>&report_title.</span>";
				put '</div>';
				put '<div id="content-header-underline" class="horizontal-gradient-bar help"></div>';
			put '</div>';
			put '<div id="content-header-placeholder" class="help"></div>';
			/** Content **/
			put '<div id="content" class="help">';

		run;

		/** If Help Administrator Preview was requested then read that data directly **/
		%if "&preview" = "Y" %then %do;
			data help_entries;
				length entry_title $500. entry_text $5000.;
				set save.help_entry_preview;
			run;
		%end;
		/** Otherwise read the help entry data set for the current stored process **/
		%else %do;
			data entry_ids;
				set &admlib..help_entry_report_assoc;
				if ObjId = "&sp_ObjId";
			run;

			data help_entries;
				if _n_ = 1 then do;
					declare hash h1(dataset: 'entry_ids');
					h1.defineKey('entry_id');
					h1.defineDone();
				end;
				set &admlib..help_entry_catalog;
				if h1.find() = 0 then output;
			run;

		proc sort data = help_entries;
			by sort_order;
		run;
		%end;

		/** Set the display markup for each help entry **/
		data help_entries(keep=text);
			set help_entries;
			/** Memory size is an extreme exception here to handle help entry text **/
			length text $5000.;
			if entry_title = '' then entry_title = '(No Title)';
			if entry_text = '' then entry_text = '(No Text)';
			%if "&preview" ne "Y" %then %do;
			if (entry_title = '(No Title)' and entry_text = '(No Text)') then delete;
			%end;
			text = cats('<div class="help-entry">',
						'<div class="help-title">', entry_title, '</div>',
						'<div class="help-text">', entry_text, '</div>',
						'</div>');
		run;

		/** Determine the number of help entries retrieved **/
		%let num_entries = 0;
		data _null_;
			set help_entries end=last;
			if last then call symputx('num_entries', compress(_n_));
		run;

		/** If no valid help entries the display default message **/
		%if %eval(&num_entries) = 0 %then %do;
			data _null_;
				file _webout;
				put '<div id="no-help-entries">No Help Entries</div>';
			run;
		%end;
		/** Create the help entry output **/
		%else %do;
			data _null_;
				/** Memory size is an extreme exception here to handle help entry text **/
				file _webout lrecl = 25000;
				set help_entries;
				put text;
			run;
		%end;

		/** Finish web page output **/
		data _null_;
			file _webout lrecl=&lrecl;

			put '</div>';
			/** Bottom Bar **/
			put '<div id="bottom-bar-placeholder"></div>';
			put '<div id="bottom-bar">';
				copyright_year = put(today(), year4.);
				put '<div id="bottom-bar-copyright">&copy; ' copyright_year ' Intrado Inc. All rights reserved.</div>';
			put '</div>';

			put '</div>';
			/** Javascript **/
			put '<script>';
			put 'var $jload = jQuery.noConflict();';
			/** OnLoad **/
				put '$jload(document).ready(function(){';
					/** Adjust relative placeholders to content size **/
					put 'var top_bar_height = $jload("#top-bar").height();';
					put 'var total_fixed_height = top_bar_height;';
					put 'if ($jload("#top-bar-placeholder").height() != top_bar_height) { ';	
						put '$jload("#top-bar-placeholder").css(''height'', top_bar_height);';
					put '}';
					put 'var content_header_height = $jload("#content-header").height();';
					put 'var total_fixed_height = top_bar_height + content_header_height;';
					put 'if ($jload("#content-header-placeholder").height() != content_header_height) { ';
						put '$jload("#content-header-placeholder").css(''height'', content_header_height);';
					put '}';
				put '});';
			put '</script>';
			/** End Page **/
			put '</body>';
			put '</html>';
		run;
		
	%end;

/*****************************************************************************************************************************/
/** Report Help Admin - Edit Help Entries (display) web part																**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 401 %then %do;

		/** Help entry character limit **/
		%let entry_character_limit = 2500;

		/** Set the default selection values **/
		%if not %symexist(master_accounts_select) %then %do;
			%let master_accounts_select = ALL;
		%end;

		%if not %symexist(action_type_select) %then %do;
			%let action_type_select = EDIT;
		%end;
	
		/** Retrieve the master account list for the drop-down menu **/
		proc sort data = save.report_access out = master_accounts(keep=master_account master_account_sort);
			by master_account_sort master_account;
		run;

		data master_accounts;
			set master_accounts;
			by master_account_sort master_account;
			if last.master_account;
			if master_account = 'Top Menu' then delete;
		run;

		%let num_master_accounts = 0;
		data _null_;
			set master_accounts end=last;
			if last then call symputx('num_master_accounts', compress(_n_));
		run;
		
		%if %eval(&num_master_accounts) > 0 %then %do;
			/** Create the Master Account drop-down menu **/
			proc sort data = master_accounts;
				by master_account_sort master_account;
			run;

			data master_accounts(keep=value display);
				set master_accounts end=last;
				length value display $500.;
				value = master_account;
				display = master_account;
				if last then call symputx('master_account_title', 'Master Account');
			run;
			%create_drop_down_menu(master_accounts, &master_account_title, &master_accounts_select, Y, , 1);

			/** Create the Action Type drop down **/
			data action_type(keep=value display);
				length value display $50.;
				value = 'CREATE'; 	display = 'Create Help Entry';	output;
				value = 'EDIT'; 	display = 'Edit Help Entry';	output;
				value = 'DELETE'; 	display = 'Delete Help Entry'; 	output;
				call symputx('action_type_title', 'Action');
			run;
			%create_drop_down_menu(action_type, &action_type_title, &action_type_select, N, , 2);

			/** Determine the available reports for the selected accounts **/
			data available_reports(keep=ObjId text master_account ObjName);
				length ObjName $500.;
				set save.report_access;
				if index(location, "Flat Files") then ObjName = catx(' ', ObjName, '(Flat File)');
				if index(location, "Development") then ObjName = catx(' ', ObjName, '(Development)');
				%if "&master_accounts_select" ne "ALL" %then %do;
					if master_account = trim(urldecode(trim("&master_accounts_select")));
				%end;
				text = cats('<option value="', ObjId, '">', master_account, ':', ObjName, '</option>');
			run;

			proc sort data = available_reports;
				by ObjId;
			run;

			%let entry_title =;
			%let entry_text =;
			%let sort_order = 1;
			%let updated_by = N/A;
			/** Determine the Entry Title, Entry Text, Selected Reports, Sort Order, and Last Updated By for existing entries **/
			%if (("&action_type_select" = "EDIT") or ("&action_type_select" = "DELETE")) and (%symexist(entry_id)) %then %do;
				data help_entry;
					set &admlib..help_entry_catalog;
					if entry_id = input("&entry_id", 8.);
				run;

				data _null_;
					set help_entry;
					call symputx('entry_title2', entry_title);
					call symputx('entry_text2', entry_text);
					call symputx('sort_order', sort_order);
					call symputx('userid', last_updated_by);
				run;

				/** Entry Title and Entry Text **/
				%let entry_title = %nrbquote(&entry_title2);
				%let entry_text = %nrbquote(&entry_text2);

				/** Last Updated By **/
				proc sql noprint;
					select display_name into: updated_by
					from srcgen.person_info
					where user_id = "&userid";
				quit;

				/** Selected Reports **/
				data selected_reports(keep=ObjId);
					set &admlib..help_entry_report_assoc;
					if entry_id = input("&entry_id", 8.);
				run;

				proc sort data = selected_reports;
					by ObjId;
				run;

				data available_reports selected_reports;
					merge available_reports(in=a) selected_reports(in=b);
					by ObjId;
					if b then output selected_reports;
					else output available_reports;
				run;
			%end;
			%else %do;
				/** If no entry exists then create a blank Selected list **/
				data selected_reports;
					set available_reports;
					stop;
				run;
			%end;

			/***************************************/
			/** Create the help entry update form **/
			/***************************************/
			%if ("&action_type_select" = "CREATE") or ("&action_type_select" = "EDIT" and %symexist(entry_id)) %then %do;
				/** Sort the Available and Selected lists by human-readable factors **/
				proc sort data = available_reports out = available_reports(keep=text);
					by master_account ObjName;
				run;

				proc sort data = selected_reports out = selected_reports(keep=text);
					by master_account ObjName;
				run;

				/** Sort Order **/
				data sort_values(keep=text);
					length text $5000. select_status $50.;
					do i = 1 to 50;
						if i = input("&sort_order", 8.) then select_status = 'selected';
						else select_status = '';
						text = cats(catx(' ', '<option', select_status, 'value="'), i, '">', i, '</option>'); output;
					end;
				run;

				/** Report Help Admin Form **/
				data form_header(keep=text);
					length text $5000.;
					/** Container **/
					text = '<div id="help-admin-form-container" class="admin-form-container" style="width: 1000px;">'; output;
					/** Form definition **/
					text = '<form id="help-entry-form" name="help-entry-form" method="get" action="/SASStoredProcess/do?">'; output;
					text = cats('<input type="hidden" name="_program" value="', "&_PROGRAM", '">'); output;
					text = cats('<input type="hidden" name="_sessionid" value="', "&_SESSIONID", '">'); output;
					text = cats('<input type="hidden" name="ajax_request" value="Y">'); output;
					text = cats('<input type="hidden" name="web_part_id" value="402">'); output;
					text = cats('<input type="hidden" name="_debug" value="0">'); output;
					text = cats('<input type="hidden" name="action_type_select" value="', "&action_type_select", '">'); output;
					%if ("&action_type_select" = "EDIT") and (%symexist(entry_id)) %then %do;
						text = cats('<input type="hidden" name="entry_id" value="', "&entry_id", '">'); output;
					%end;
					/** Form Title/Action **/
					text = cats('<div class="admin-form-bar border-radius">',
								catx(' ', propcase("&action_type_select"), 'Help Entry'),
								'</div>'); output;
					/** Help Entry Title Input **/
					text = '<div class="left-container">'; output;
					text = cats('<div id="help-admin-title-container">',
								'<label class="select-label" for="entry_title">Entry Title:&nbsp;</label>',
								'<input type="text" id="entry_title" name="entry_title" value="', "&entry_title", '" class="border-radius" />',
								'</div>'); output;
					/** Available Reports Selections **/
					text = cats('<div id="help-admin-available-container">',
								'<label class="select-label" for="available">Available Reports</label>',
								'<select id="available" name="available" multiple="multiple" size="8" class="border-radius">'); output;
				run;

				data form_selections(keep=text);
					length text $5000.;
					text = cats('</select>',
								'</div>'); output;
					/** Selected Reports **/
					text = cats('<div id="help-admin-selected-container">',
								'<label class="select-label" for="selected">Selected Reports</label>',
								'<select id="selected" name="selected" multiple="multiple" size="8" class="border-radius">'); output;
				run;

				data form_sort(keep=text);
					length text $5000.;
					text = cats('</select>',
								'</div>'); output;
					/** Sort Selection **/
					text = cats('<div id="updated-container">',
								'<span id="sort-container">',
								'<label class="select-label" for="sort">Sort Order:&nbsp;</label>',
								'<select id="sort" name="sort">'); output;
				run;

				data form_footer(keep=text);
					length text $5000.;
					text = cats('</select>',
								'</span>',
								/** Last Updated By **/
								'<span class="select-label">Last Updated By:&nbsp;</span>',
								'<span>', "&updated_by", '</span>',
								'</div>'); output;
					text = '</div>'; output;
					/** Help Entry Text Input **/
					text = '<div class="right-container">'; output;
					text = cats('<div id="text-container">',

								'<label class="select-label" for="entry_text">Entry Text:&nbsp;</label><br />',
								'<textarea id="entry_text" name="entry_text" class="border-radius">', "&entry_text", '</textarea>',
								'<div id="preview-container">',
								'<span id="entry-character-limit">', catx(' ', "&entry_character_limit.</span>", 'characters remaining'),
								'<span id="preview" class="link" style="text-decoration: none;">Preview</span>',
								'</div>',

								'</div>'); output;
					text = '</div>'; output;
					/** Form Footer/Submit Button **/
					text = '</form>'; output;
					text = cats('<div class="admin-form-bar border-radius" style="background-color: #FFFFFF;">',
								cats('<input id="help-admin-submit" type="button" class="submit-button-1" style="width: 120px; padding: 8px; margin-right: 100px;" value="', catx(' ', propcase("&action_type_select"), ' Entry'), '" disabled="disabled" />'),
								cats('<div class="submit-button-1" style="padding: 8px;" onClick="location.reload(true);">Reset Form</div>'),
								'</div>'); output;
				run;

				data web_part(keep=text);
					set form_header available_reports form_selections selected_reports form_sort sort_values form_footer;
				run;

				/**********************************************************/
				/** Additional JavaScript for the help entry update form **/
				/**********************************************************/
				/** Function to move reports between Available and Selected boxes **/
				data jquery(keep=text);
					length text $1500.;
					text = '$jload(''#selected'').click(function() {'; output;
	  					text = '$jload(''#selected option:selected'').remove().appendTo(''#available'');'; output;
						text = 'sortMultiSelects(''available'');'; output;
						text = 'helpFormContentChanged();'; output;
	 				text = '});'; output;
	 				text = '$jload(''#available'').click(function() {'; output;
	  					text = '$jload(''#available option:selected'').remove().appendTo(''#selected'');'; output;
						text = 'sortMultiSelects(''selected'');'; output;
						text = 'helpFormContentChanged();'; output;
	 				text = '});'; output;
					/** Function to sort Available and Selected boxes after each move **/
					text = 'function sortMultiSelects(select_id) {'; output;
						text = 'var selectOptions = $jload(''#'' + select_id + '' option'');'; output;
						text = 'selectOptions.sort(function(a, b) {'; output;
							text = 'if (a.text > b.text) {'; output;
								text = 'return 1;'; output;
							text = '}'; output;
							text = 'else if (a.text < b.text) {'; output;
								text = 'return -1;'; output;
							text = '}'; output;
							text = 'else {'; output;
								text = 'return 0;'; output;
							text = '}'; output;
						text = '});'; output;
						text = '$jload(''#'' + select_id).empty().append(selectOptions);'; output;
						text = '$jload(''#available, #selected'').find(''option:selected'').removeAttr(''selected'');'; output;
						text = '$jload(''#available, #selected'').trigger(''change'');'; output;
					text = '}'; output;
				run;

				data _null_;
					set jquery end=last;
					retain temp;
					length temp $25000.;
					temp = cats(temp, '0D'x, trim(text));
					if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
				run;

				/** Function to monitor character count of entry text **/
				data jquery(keep=text);
					length text $1500.;
					/** Function to count and restrict characters in Entry Text box **/
					text = 'function countCharacters() {'; output;
						text = catx(' ', 'var maxCharacters =', "&entry_character_limit"); output;
						text = 'if ($jload(''#entry_text'').val().length >= maxCharacters) {'; output;
							text = '$jload(''#entry_text'').val($jload(this).val().substr(0, maxCharacters));'; output;
							text = '$jload(''#entry-character-limit'').text(''No'');'; output;
						text = '} else {;'; output;
							text = '$jload(''#entry-character-limit'').text(maxCharacters - $jload(''#entry_text'').val().length);'; output;
						text = '}'; output;
					text = '}'; output;
					/** Function to call validation methods after typing strokes **/
					text = '$jload(''#entry_text'').keyup(function() {'; output;
						text = 'countCharacters();'; output;
						text = 'helpFormContentChanged();'; output;
					text = '});'; output;
				run;

				data _null_;
					set jquery end=last;
					retain temp;
					length temp $25000.;
					temp = cats(temp, '0D'x, trim(text));
					if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
				run;

				/** Function to monitor form fields and enable submit button based on form completeness **/
				data jquery(keep=text);
					length text $1500.;
					/** Monitor the Entry Title field **/
					text = '$jload(''#entry_title'').keyup(function() {'; output;
						text = 'helpFormContentChanged();'; output;
					text = '});'; output;
					/** Monitor Available, Selected, and Sort fields **/
					text = '$jload(''#available, #selected, #sort'').on(''change'', function() {'; output;
						text = 'helpFormContentChanged();'; output;
					text = '});'; output;
					/** Control the form submit button based on form completeness **/
					text = 'function helpFormContentChanged() {'; output;
						/** Check for title **/
						text = 'if ($jload(''#entry_title'').val() == '''') { $jload(''#help-admin-submit'').attr(''disabled'', ''disabled''); }'; output;
						/** Check for selected reports **/
						text = 'else if ($jload(''#selected option'').length == 0) { $jload(''#help-admin-submit'').attr(''disabled'', ''disabled''); }'; output;
						/** check for entry text **/
						text = 'else if ($jload(''#entry_text'').val() == '''') { $jload(''#help-admin-submit'').attr(''disabled'', ''disabled''); }'; output;
						text = 'else { $jload(''#help-admin-submit'').removeAttr(''disabled''); }'; output;
					text = '}'; output;
				run;

				data _null_;
					set jquery end=last;
					retain temp;
					length temp $25000.;
					temp = cats(temp, '0D'x, trim(text));
					if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
				run;

				/** Function to perform entry text character count on page load **/
				data jquery(keep=text);
					length text $1500.;
					text = 'countCharacters();'; output;
				run;

				data _null_;
					set jquery end=last;
					retain temp;
					length temp $25000.;
					temp = cats(temp, '0D'x, trim(text));
					if last then call symputx('onload_jquery', cats("&onload_jquery", '0D'x, trim(temp)));
				run;

				/** Function to preview the entry in the help window **/
				data jquery(keep=text);
					length text $1500.;
					text = '$jload(''#preview'').click(function() {'; output;
						/** Send the title and text to a web part that will create a save data set **/
						text = cats('$jload.ajax({',
									'type: ''POST'',',
									'url: ''/SASStoredProcess/do?'',',
									'data: {',
										'_program: ''', "&_PROGRAM", ''',',
										'_sessionid: ''', "&_SESSIONID", ''',',
										'ajax_request: ''Y'',',
										'web_part_id: ''405'',',
										'entry_title: $jload(''#entry_title'').val(),',
										'entry_text: $jload(''#entry_text'').val(),',
										'_debug: ''0''',
										'}',
									'})',
									/** When AJAX call is complete call the report help with the preview option **/
									'.done(function(data) {',
										'reportHelp(''preview'');',
									'})'); output;
					text = '});'; output;
				run;

				data _null_;
					set jquery end=last;
					retain temp;
					length temp $25000.;
					temp = cats(temp, '0D'x, trim(text));
					if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
				run;

				/** Funciton to submit the help entry form (AJAX) **/
				data jquery(keep=text);
					length text $1500.;
					text = '$jload(''#help-admin-submit'').on(''click'', function() {'; output;
						text = '$jload(''#selected'').children().each(function() {'; output;
							text = '$jload(this).prop(''selected'', true);'; output;
						text = '});'; output;
						text = cats('$jload.ajax({',
									/** Call the loading animation - serialize() introduces issues with the standard way of doing this **/
									'beforeSend: function() { $jload(''#help-admin-form-container'').html($jload(''#hidden-loading-container'').html()); },',
									/** Proceed with the AJAX call to process the help entry form **/
									'type: ''POST'',',
									'url: ''/SASStoredProcess/do?'',',
									'data: $jload(''#help-entry-form'').serialize()',
									'})',
									/** When AJAX call is complete load the results into the container **/
									'.done(function(data) {',
										'$jload(''#help-admin-form-container'').html(data);',
									'})'); output;
					text = '});'; output;
				run;

				data _null_;
					set jquery end=last;
					retain temp;
					length temp $25000.;
					temp = cats(temp, '0D'x, trim(text));
					if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
				run;
			%end; /** End - Output Form **/

			/***********************************/
			/** Create the help entry browser **/
			/***********************************/
			/** Set the default value of the report filter selection **/
			%if not %symexist(report_filter) %then %do;
				%let report_filter = ALL;
			%end;	

			/** Build drop-down options out of the master account report list **/
			data available_reports(keep=text master_account ObjName);
				length text $1500. ObjName $500.;
				set save.report_access;
				if master_account ne 'Top Menu';
				if index(location, "Flat Files") then ObjName = catx(' ', ObjName, '(Flat File)');
				if index(location, "Development") then ObjName = catx(' ', ObjName, '(Development)');
				%if "&master_accounts_select" ne "ALL" %then %do;
					if master_account = trim(urldecode(trim("&master_accounts_select")));
				%end;
				text = cats('<option value="', ObjId, '">', master_account, ':', ObjName, '</option>');
			run;

			proc sort data = available_reports;
				by master_account ObjName;
			run;

			data available_reports(keep=text);
				set available_reports;
				if _n_ = 1 then text = cats('<option value="">Select a Report</option>', text);
			run;
				
			/** Create the Entry Browser navigation select **/
			data entry_browser_container(keep=text);
				length text $1500.;
				/** Entry Browser Title **/
				text = cats('<div class="admin-form-bar border-radius">',
							catx(' ', 'Browse Help Entries for', trim(urldecode(trim("&master_accounts_select")))),
							'</div>'); output;
				/** Report Filter drop-down menu **/
				text = cats('<div id="entry-browser-filter">',
							'<select id="report_filter" name="report_filter">'); output;
			run;

			data entry_browser_table(keep=text);
				length text $1500.;
				/** Close Filter drop-down **/
				text = '</select>'; output;
				text = '</div>'; output;
				/** Create the container for the entry table **/
				text = cats('<div id="entry-browser-table">',
								'<div id="entry-browser-mask" style="display: none;"></div>',
								'<table id="existing-entry-table" class="content-table" style="display: none;">',
									'<thead>',
										'<tr>',
											'<th>Sort<br />Order</th>',
											'<th style="min-width: 550px;">Help Entry</th>',
											'<th>Report<br />Count</th>',
											'<th>Update</th>',
										'</tr>',
									'</thead>',
									'<tbody id="entry-records">',
									'</tbody>',
								'</table>',
							'</div>'); output;
			run;

			/** If the update form was already created then append the entry browser **/
			%if %sysfunc(exist(work.web_part)) > 0 %then %do;
				data web_part(keep=text);
					set web_part entry_browser_container available_reports entry_browser_table end=last;
					/** Terminate the help-admin-form-container element **/
					if last then text = cats(text, '</div>');
				run;
			%end;
			/** If the update form was not created then establish the container element **/
			%else %do;
				data web_part(keep=text);
					set entry_browser_container available_reports entry_browser_table end=last;
					if _n_ = 1 then text = cats('<div id="help-admin-form-container" class="admin-form-container" style="width: 1000px;">', text);
					if last then text = cats(text, '</div>');
				run;
			%end;

			/**************************************************/
			/** Additional JavaScript for help entry browser **/
			/**************************************************/
			/** Function to load the mask element with the standard loading animation **/
			data jquery(keep=text);
				length text $1500.;
				text = '$jload(''#entry-browser-mask'').html($jload(''#hidden-loading-container'').html());'; output;
			run;

			data _null_;
				set jquery end=last;
				retain temp;
				length temp $25000.;
				temp = cats(temp, '0D'x, trim(text));
				if last then call symputx('onload_jquery', cats("&onload_jquery", '0D'x, trim(temp)));
			run;

			/** Function to request help entries for selected report from server **/
			data jquery(keep=text);
				length text $1500.;
				text = '$jload(''#report_filter'').on(''change'', function() {'; output;
					text = '$jload(''#existing-entry-table'').hide(0);'; output;
					text = '$jload(''#entry-browser-mask'').show(0);'; output;
					text = 'var reportFilter = encodeURIComponent($jload(this).val());'; output;
  					text = cats('$jload(''#entry-records'').load(''/SASStoredProcess/do'', {',
								'_program:', "'&_program',",
								'_sessionid:', "'&_sessionid',",
								'web_part_id:', "'403',",
								'report_filter:', 'reportFilter,',
								'master_accounts_select:', "'&master_accounts_select',",
								'action_type_select:', "'&action_type_select',",
								'_debug:', "'0',",
								'ajax_request:', "'Y'",
								'}, function() { ',
												/** Update the Hash with the report ID to differentiate AJAX content for back button **/
												'window.location.hash = ''#'' + reportFilter;',
												/** Flag tableSorter to handle new content **/
												'$jload(''#existing-entry-table'').trigger(''update'');',
												/** Apply FancyBox to any DELETE links **/
												'$jload(''.fancybox'').fancybox({',
													'type : ''ajax'',',
													'ajax : { cache: false }', /** This can be set to TRUE in production if performance is an issue **/
												'});',
												/** Show the help entry table **/
												'$jload(''#existing-entry-table'').show(0);',
												'$jload(''#entry-browser-mask'').hide(0);',
												/** Scroll the user to the part of the page they want **/
												'$jload(''html, body'').animate({ scrollTop: $jload(''#entry-browser-table'').offset().top }, 2000);',
												/*'$jload(''html, body'').animate({ scrollTop: 100 }, 1000);',*/
												'});'); output;
				text = '});'; output;
			run;

			data _null_;
				set jquery end=last;
				retain temp;
				length temp $25000.;
				temp = cats(temp, '0D'x, trim(text));
				if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
			run;

			/** Function to detect hash changes and allow AJAX content to be navigated with back buttons **/
			data jquery(keep=text);
				length text $1500.;
				/** Detect changes to the Hash - can include browser capability check if anyone has issues **/
				/** Hash is used because HTML 5 pushState() is only available for IE in v10+ **/
				text = 'window.onhashchange = function() {'; output;
					/** If Hash exists compare it to the select value of the drop down **/
					text = 'if (window.location.hash.length > 1) {'; output;
						/*text = 'alert(''Hash: '' + window.location.hash + ''    Report: '' + $jload(''#report_filter'').val())'; output;*/
						/** If the current hash does not equal the current selected value then update the selected value **/
						text = 'var reportID = $jload(''#report_filter'').val();'; output;
						text = 'if (window.location.hash.substring(1) != reportID) { $jload(''#report_filter'').val(window.location.hash.substring(1)) }'; output;
						text = '$jload(''#report_filter'').trigger(''change'');'; output;
					/** If Hash does not exist then page is on top level - refresh **/
					text = '} else {'; output;
						text = 'window.location.reload();'; output;
					text = '}'; output;
				text = '}'; output;
			run;

			data _null_;
				set jquery end=last;
				retain temp;
				length temp $25000.;
				temp = cats(temp, '0D'x, trim(text));
				if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
			run;

			/** Function to expand and collapse help entries in the browser table **/
			data jquery(keep=text);
				length text $1500.;
				/** Delegate on original DOM element is used to accommodate AJAX-loaded content **/
				text = '$jload(''#existing-entry-table'').delegate(''.entry-title'', ''click'', function() {'; output;
					/** If clicked entry is the expanded entry then collapse it **/
					text = 'if ($jload(this).siblings(''.entry-text'').is('':visible'')) {'; output;
						text = '$jload(this).siblings(''.entry-text'').hide(500);'; output;
					/** Otherwise hide any expanded entries and show the selected entry **/
					text = '} else {'; output;
						text = '$jload(''.entry-text'').hide(200);'; output;
						text = '$jload(this).siblings(''.entry-text'').show(500);'; output;
					text = '}'; output;
				text = '});'; output;
			run;

			data _null_;
				set jquery end=last;
				retain temp;
				length temp $25000.;
				temp = cats(temp, '0D'x, trim(text));
				if last then call symputx('add_jquery', cats("&add_jquery", '0D'x, trim(temp)));
			run;

			/** Function to handle click delegation for delete button in lightbox **/
			data jquery(keep=text);
				length text $1500.;
				/** If click was to remove a help entry **/
				text = 'if ($jload(this).attr(''class'') == ''submit-button-1 delete-help-entry'') {'; output;
					text = 'var entryId = $jload(this).attr(''id'').split(''-'').pop();'; output;
					/** Loading notification **/
					text = '$jload(''.web-part-setup-button'').html(''Deleting...'');'; output;
					/** AJAX Call to delete help entry from data sets **/
					text = '$jload.ajax({'; output;
						text = 'type: ''POST'','; output;
						text = 'url: ''/SASStoredProcess/do?'','; output;
						text = 'data: {'; output;
							text = '_program: ''&_PROGRAM'','; output;
							text = '_sessionid: ''&_SESSIONID'','; output;
							text = 'web_part_id: ''402'','; output;
							text = 'action_type_select: ''DELETE'','; output;
							text = 'entry_id: entryId,'; output;
							text = 'ajax_request: ''Y'''; output;
						text = '}'; output;
					text = '})'; output;
					/** Call backs **/
					text = '.done(function(data) {'; output;
						/** Close the lightbox and refresh the help entry list for the selected report **/
						text = '$jload.fancybox.close();'; output;
						text = '$jload(''#report_filter'').trigger(''change'');'; output;
					text = '});'; output;
				text = '}'; output;
			run;

			data _null_;
				set jquery end=last;
				retain temp;
				length temp $25000.;
				temp = cats(temp, '0D'x, trim(text));
				if last then call symputx('click_delegate_jquery', cats("&click_delegate_jquery", '0D'x, trim(temp)));
			run;

		%end;
		
	%end;

/*****************************************************************************************************************************/
/** Report Help Admin - Edit Help Entries (logic) web part																	**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 402 %then %do;

		/** A compiled macro to test the lock state of production data sets at various points in this web part **/
		/** Macro is built locally to avoid collision with other web parts running the same function **/
		%macro trylock(member=, timeout=5, retry=0.1);
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

		/** If a new entry then set the entry id and revision values **/
		%if "&action_type_select" = "CREATE" %then %do;
			%let numrec=0;
			data _null_;
				set &admlib..help_entry_catalog end=last;
				if last then call symputx('numrec', _n_);
			run;

			%if %eval(&numrec) > 0 %then %do;
				proc sql;
					select max(entry_id) + 1 into: entry_id
				  	from &admlib..help_entry_catalog;
				quit;			
			%end;
			%else %do;
				%let entry_id = 1;
			%end;
			%let revision_num = 1;
		%end;
		/** If existing entry then set the new revision value **/
		%else %if "&action_type_select" = "EDIT" %then %do;
			data _null_;
				set &admlib..help_entry_catalog;
				if entry_id = input("&entry_id", 8.);
				call symputx('revision_num', compress(revision_num + 1));
			run;
		%end;

		%if (("&action_type_select" = "CREATE") or ("&action_type_select" = "EDIT")) %then %do;
			/** Build an update record for the help entry catalog **/
			data update_record (keep=entry_id entry_title entry_text sort_order last_updated_dt last_updated_by revision_num);
				length entry_id 8. entry_title $500. entry_text $5000. sort_order 8. last_updated_dt 8. last_updated_by $500. revision_num 8.;
				entry_id = input("&entry_id", 8.);
				entry_title = trim("&entry_title");
				entry_text = trim("&entry_text");
				sort_order = input("&sort", 8.);
				last_updated_dt = datetime();
				last_updated_by = "&_metaperson";
				revision_num = input("&revision_num", 8.);
			run;

			/** Update a WORK copy of the help entry catalog **/
			proc sort data = &admlib..help_entry_catalog out = help_entry_catalog;
				by entry_id;
			run;

			data help_entry_catalog;
				merge help_entry_catalog(in=a) update_record(in=b);
				by entry_id;
			run;

			/** Commit the updates to the production help entry catalog **/
			%trylock(member=&admlib..help_entry_catalog)
			data &admlib..help_entry_catalog (compress=yes);
				set work.help_entry_catalog;
			run;

			lock &admlib..help_entry_catalog clear;

			
			/** If selected reports count not large enough to create macro array then set values **/
			%if not %symexist(selected_count) and %symexist(selected) %then %do;
				%let selected_count = 1;
				%let selected1 = &selected;
			%end;

			/** Determine which stored processes were selected **/
			%if %symexist(selected_count) %then %do;
				%if %eval(&selected_count) > 0 %then %do;

					/** Build an update record for the help entry report assoc **/
					data update_record (keep=entry_id ObjId);
						length entry_id 8. ObjId $17.;
						%do selected_counter = 1 %to %eval(&selected_count);
							ObjId = trim("&&selected&selected_counter"); entry_id = input("&entry_id", 8.); output;
						%end;
					run;

					/** Update a WORK copy of the help entry report assoc **/
					data work.help_entry_report_assoc;
						set &admlib..help_entry_report_assoc;
						if entry_id = input("&entry_id", 8.) then delete;
					run;

					data work.help_entry_report_assoc;
						set work.help_entry_report_assoc update_record;
					run;

					proc sort data =  work.help_entry_report_assoc;
						by ObjId entry_id;
					run;

					/** Commit the updates to the production help entry report assoc **/
					%trylock(member=&admlib..help_entry_report_assoc)
					data &admlib..help_entry_report_assoc (compress=yes);
						set work.help_entry_report_assoc;
					run;

					lock &admlib..help_entry_report_assoc clear;

				%end;
			%end;

		%end;
		%else %if "&action_type_select" = "DELETE" %then %do;

			/** Remove entry_id from entry catalog **/
			%trylock(member=&admlib..help_entry_catalog)
			data &admlib..help_entry_catalog (compress=yes);
				set &admlib..help_entry_catalog;
				if entry_id = input("&entry_id", 8.) then delete;
			run;

			lock &admlib..help_entry_catalog clear;
			
			/** Remove entry_id from report assoc table **/
			%trylock(member=&admlib..help_entry_report_assoc)
			data &admlib..help_entry_report_assoc (compress=yes);
				set &admlib..help_entry_report_assoc;
				if entry_id = input("&entry_id", 8.) then delete;
			run;

			lock &admlib..help_entry_report_assoc clear;

		%end;

		/** Confirmation output for Create and Edit. Delete just refreshes the help entry list **/
		%if "&ajax_request" = "Y" %then %do;
			%if "&action_type_select" ne "DELETE" %then %do;
				data help_entry_confirmation(keep=text);
					length text $1500.;
					text = cats('<div class="entry-confirmation">',
								'<span>The help entry catalog has been successfully updated.</span><br />',
								'<span>To make additional updates use the filters above.</span>',
								'</div>'); output;
				run;

				data _null_;
					file _webout;
					set help_entry_confirmation;
					put text;
				run;
			%end;
		%end;
		
	%end;

/*****************************************************************************************************************************/
/** Report Help Admin - Return Help Entries for Selected Report (ajax) web part												**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 403 %then %do;

		/** Retrieve help entries for the selected report **/
		data entry_ids;
			set &admlib..help_entry_report_assoc;
			if ObjId = trim(urldecode(trim("&report_filter")));
		run;

		data help_entries;
			if _n_ = 1 then do;
				declare hash h1(dataset: 'entry_ids');
				h1.defineKey('entry_id');
				h1.defineDone();
			end;
			set &admlib..help_entry_catalog;
			if h1.find() = 0 then output;
		run;

		/** Determine the number of reports using each help entry **/
		proc sort data = help_entries;
			by entry_id;
		run;

		data report_count;
			if _n_ = 1 then do;
				declare hash h1(dataset: 'help_entries');
				h1.defineKey('entry_id');
				h1.defineDone();
			end;
			set &admlib..help_entry_report_assoc;
			if h1.find() = 0 then output;
		run;

		proc sort data = report_count;
			by entry_id;
		run;

		data report_count(keep=entry_id num_reports);
			set report_count;
			by entry_id;
			length num_reports 8.;
			retain num_reports;
			if first.entry_id then num_reports = 1;
			else num_reports = num_reports + 1;
			if last.entry_id then output;
		run;

		proc sort data = report_count;
			by entry_id;
		run;

		data help_entries;
			merge help_entries(in=a) report_count(in=b);
			by entry_id;
			if a;
		run;

		proc sort data = help_entries;
			by sort_order;
		run;

		/** Determine the number of help entries **/
		%let num_help_entries = 0;
		data _null_;
			set help_entries end=last;
			if last then call symputx('num_help_entries', compress(_n_));
		run;

		%if %eval(&num_help_entries) > 0 %then %do;
			/** Output the table rows **/
			data web_part(keep=text);
				/** Memory size is an extreme exception here to handle help entry text **/
				length text $25000.;
				set help_entries;
				text = cats('<tr>',
							'<td  style="text-align: center;">', sort_order, '</td>',
							/** Help Entry Content **/
							'<td>',
								'<div class="entry-title">', entry_title, '</div>',
								'<div class="entry-text">', entry_text, '</div>',
							'</td>',
							/** Help Entry Flags **/
							'<td style="text-align: center;">', num_reports, '</td>',
							/** Help Entry Action Link **/
							'<td style="text-align: center;">',
								/** Open EDITs in a new help form screen **/
								%if "&action_type_select" in "CREATE" "EDIT" %then %do;
								'<a href="', "&uri_prefix",
											'&amp;master_accounts_select=', "&master_accounts_select",
											'&amp;action_type_select=EDIT',
											'&amp;entry_id=', entry_id, '">Edit</a></td>',
								%end;
								/** Open DELETEs in a confirmation lightbox **/
								%else %if "&action_type_select" = "DELETE" %then %do;
								'<a class="fancybox" href="', "&uri_prefix",
											'&amp;master_accounts_select=', "&master_accounts_select",
											'&amp;action_type_select=', "&action_type_select",
											'&amp;entry_id=', entry_id,
											'&amp;ajax_request=Y',
											'&amp;_debug=0',
											'&amp;web_part_id=404">Delete</a></td>',
								%end;
							'</tr>'); output;
			run;
		%end;
		%else %do;
			data web_part(keep=text);
				length text $1500.;
				text = cats('<tr>',
							'<td colspan="4" style="text-align: center;">No Help Entries for this Report</td>',
							'</tr>'); output;
			run;
		%end;

		/** Output the entry browser table asynchronously **/
		data _null_;
			/** Memory size is an extreme exception here to handle help entry text **/
			file _webout lrecl = 25000;
			set web_part;
			put text;
		run;
		
	%end;

/*****************************************************************************************************************************/
/** Report Help Admin - Delete Help Entry (Lightbox)																		**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 404 %then %do;

		/** Retrieve the help entry record **/
		data help_entry;
			set &admlib..help_entry_catalog;
			if entry_id = trim(urldecode(trim("&entry_id")));			
		run;

		data help_entry(keep=text);
			length text $5000.;
			set help_entry;
			text = cats('<div class="help-entry" style="text-align: left;">',
						'<div class="help-title" style="color: #FFFFFF;">', entry_title, '</div>',
						'<div class="help-text" style="color: #FFFFFF;">', entry_text, '</div>',
						'</div>');
		run;

		/** Retrieve the associated reports **/
		data assoc_reports;
			set &admlib..help_entry_report_assoc;
			where entry_id = input("&entry_id", 8.);
		run;

		%if %sysfunc(exist(work.assoc_reports)) > 0 %then %do;
			proc sort data = assoc_reports;
				by ObjId;
			run;

			proc sort data = save.report_access out = report_access(keep=ObjId location master_account ObjName);
				by ObjId;
			run;

			data assoc_reports;
				merge assoc_reports(in=a) report_access(in=b);
				by ObjId;
				if a;
			run;

			proc sort data = assoc_reports;
				by master_account ObjName;
			run;

			data assoc_reports(keep=text);
				length text $1500. ObjName $500.;
				set assoc_reports;
				if index(location, "Flat Files") then ObjName = catx(' ', ObjName, '(Flat File)');
				if index(location, "Development") then ObjName = catx(' ', ObjName, '(Development)');
				text = cats('<div style="text-align: left; padding: 0 5px 0 5px;">', master_account, ':', ObjName, '</div>');
			run;
				
		%end;
		%else %do;
			data assoc_reports(keep=text);
				length text $1500.;
				text = cats('<div>No Reports Assigned</div>'); output;
			run;
		%end;

		data section_start(keep=text);
			length text $5000.;
			/** Delete Help Entry Container **/
			text = '<div id="delete-help-entry">'; output;
			/** Reports List **/
			text = cats('<div class="web-part-setup-image" style="color: #FFFFFF;">',
						'<div style="font-size: 20px; font-weight: bold;">Reports:</div>'); output;
		run;

		data section_middle(keep=text);
			length text $1500.;
			/** Close Reports List **/
			text = cats('</div>'); output;
			/** Entry Display **/
			text = cats('<div class="web-part-setup-filter">'); output;
		run;

		data section_end(keep=text);
			length text $1500.;
			/** Close Entry Display **/
			text = cats('</div>'); output;
			/** Button Container **/
			text = cats('<div class="web-part-setup-button" style="width: 350px; font-size: 20px; text-align: center;">'); output;
				/** Button **/
				text = cats('<div class="submit-button-1 delete-help-entry" id="delete-entry-', "&entry_id", '" style="width: 350px;">Delete Help Entry</div>'); output;
			/*** Close Button Container **/
			text = '</div>'; output;
			/** Close Delete Help Entry Container **/
			text = '</div>'; output;
		run;

		/** Compile the data sets into the full markup **/
		data web_part(keep=text);
			length text $5000.;
			set section_start assoc_reports section_middle help_entry section_end;
		run;
	
		/** If web part requested via AJAX then output the text immediately to the web page **/
		%if "&ajax_request" = "Y" %then %do;
			data _null_;
				file _webout lrecl=5000;
				set web_part;
				put text;
			run;
		%end;

	%end;

/*****************************************************************************************************************************/
/** Report Help Admin - Add Preview to SAVE data set (ajax)																	**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 405 %then %do;

		data save.help_entry_preview;
			entry_title = trim(urldecode(trim("&entry_title")));
			entry_text = trim(urldecode(trim("&entry_text")));
		run;

	%end;

/*****************************************************************************************************************************/
/** Web Part Administration (display) web part																				**/
/*****************************************************************************************************************************/
	%if %eval(&web_part_id) = 1000 %then %do;

		/** Web part description character limit **/
		%let entry_character_limit = 500;

		/** Set default action type if none selected **/
		%if not %symexist(action_type_select) %then %do;
			%let action_type_select = EDIT;
		%end;

		/** Create the Action Type drop down **/
		data action_type(keep=value display);
			length value display $50.;
			value = 'CREATE'; 	display = 'Create Help Entry';	output;
			value = 'EDIT'; 	display = 'Edit Help Entry';	output;
			value = 'DELETE'; 	display = 'Delete Help Entry'; 	output;
			call symputx('action_type_title', 'Action');
		run;
		%create_drop_down_menu(action_type, &action_type_title, &action_type_select, N, , 1);

		/** Web Part Admin form **/
		data form_header(keep=text);
			length text $1500.;
			text = ''; output;
		
	
		

	%end;

%exit: %mend global_web_parts;
%global_web_parts;