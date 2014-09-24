******************************************************************************************************************************;
** Program: SelectionsProcessing.sas																						**;
** Purpose: To handle the creation of the report filter selections															**;
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
** Notes: Macros used:																										**;
**			- %create_drop_down_menu																						**;
**			- %day_drop_down_menu																							**;
**			- %week_drop_down_menu																							**;
**			- %month_drop_down_menu																							**;
**			- %quarter_drop_down_menu																						**;
**			- %year_drop_down_menu																							**;
**																															**;
** History:																													**;
**		01/01/2014 John Sandoval - Initial Release																			**;
**																															**;
******************************************************************************************************************************;

/*********************************************************************/
/** %CREATE_DROP_DOWN_MENU will take a data set and turn it into an	**/
/** HTML <SELECT> element that will render as a drop down menu.		**/
/**																	**/
/** It can be called multiple times per report and will generate as	**/
/** many drop downs as the report requires.							**/
/**																	**/
/** %CREATE_DROP_DOWN_MENU requires a data set that includes:		**/
/** 	- A data set name sufficient to be an HTML element name		**/
/**		- A variable VALUE that will be passed via HTTP				**/
/**		- A variable DISPLAY that will appear in the drop down		**/
/**																	**/
/** %CREATE_DROP_DOWN_MENU accepts the following arguments:			**/
/**		- selectoptions: the data set containing the value/display	**/
/**		- selectlabel: the screen label of the drop down menu		**/
/**		- current_value: the current selected value from the menu	**/
/**		- all_option: Y/N whether to include an "All" select option	**/
/**		- stack_label: Y/N whether to put label on top of menu		**/
/*********************************************************************/
%macro create_drop_down_menu(selectoptions, selectlabel, current_value, all_option, stack_label, order);

	/** Keep track of the number of drop-down menus requested **/
	%if not %symexist(num_selection_filters) %then %do;
		%global num_selection_filters;
		%let num_selection_filters = 1;
	%end;
	%else %do;
		%let num_selection_filters = %eval(&num_selection_filters + 1);
	%end;

	/** Keep track of menu order **/
	%if %sysfunc(exist(work.selections_order)) = 0 %then %do;
		%if "&order" = "" %then %do;
			data selections_order;
				order_num = 1;
			run;
		%end;
		%else %do;
			data selections_order;
				order_num = &order;
			run;
		%end;
	%end;

	/** If no order was passed then find the lowest-sequence position **/
	%if "&order" = "" %then %do;
		proc sql noprint;
			select compress(tranwrd(cats(min(monotonic)), '.', "&num_selection_filters")) into: order
			from (select monotonic() as monotonic, order_num
		  		  from selections_order) as torder
			where monotonic ne order_num;
		quit;
	%end;
	/** If an order was passed but conflicts with an existing order then the older selection menu will be overwritten **/
	%else %do;
		data selections_order;
			set selections_order;
			if "&order" = order_num then delete;
		run;
	%end;

	/** Update the selections order data set **/
	data temp_order;
		order_num = &order;
	run;

	data selections_order;
		set selections_order temp_order;
	run;

	proc sort data = selections_order;
		by order_num;
	run;

	/** If no selectlabel was given then use the data set name **/
	%if "&selectlabel" = "" %then %let selectlabel = %sysfunc(propcase(&selectoptions));

	data selectoptions&order(keep=text);
		set &selectoptions end=last;
		length text $5000.;
		if trim(urldecode(trim("&current_value"))) = value then selected = 'selected';
		else selected = '';
		/** In the first observation set the container DIV, LABEL, and SELECT elements **/
		if _n_ = 1 then do;
			text = cats('<div class="drop-down-filter">', '0D'x,
						'<label class="select-label" for="', "&selectoptions", '_select">', "&selectlabel", ':&nbsp;</label>', '0D'x,
						%if "&stack_label" = "Y" %then %do;
							'<br />',
						%end;
						'<select id="', "&selectoptions", '_select" name="', "&selectoptions", '_select" class="combobox" onChange="',
						%if "&refresh_on_select" = "Y" %then %do;
							'form_submit(''report-filter-form'');',
						%end;
						%else %do;
							'selection_filter();',
						%end;
						'">', '0D'x,
						%if "&all_option" = "Y" %then %do;
							%if "&current_value" = "ALL" %then %do;
								'<option selected value="ALL">All</option>', '0D'x,
							%end;
							%else %do;
								'<option value="ALL">All</option>',
							%end;
						%end;
						'<', catx(' ', 'option', selected, 'value="'), trim(urlencode(trim(value))), '">', display, '</option>');
		end;
		else do;
			text = cats('<', catx(' ', 'option', selected, 'value="'), trim(urlencode(trim(value))), '">', display, '</option>');
		end;
		/** In the last observation close the SELECT and DIV elements **/
		if last then do;
			text = cats(text, '0D'x,
						'</select>', '0D'x,
						'</div>');
		end;
	run;

	/** SELECTOPTIONS&order data sets will be compiled into CONTENT_FILTER further down after web parts compilation **/

%mend create_drop_down_menu;

/*********************************************************************/
/** %MONTH_DROP_DOWN_MENU will take the validate log specified in	**/
/** the web part and create a standard Month data set that will		**/
/** get passed to %create_drop_down_menu							**/
/**																	**/
/** %MONTH_DROP_DOWN_MENU accepts the following arguments:			**/
/**		- stack_select_label										**/
/**																	**/
/*********************************************************************/
%macro month_drop_down_menu(stack_select_labels);

	/** Retrieve the validate log **/
	proc sort data = &validate_log out = month;
		by descending procdate create_dt validate_dt;
	run;

	data month(keep=value display);
		length value display $500.;
		set month;
		by descending procdate create_dt validate_dt;
		/** Restrict the month drop-down menu to the most recent 13 months **/
		if last.procdate and procdate >= intnx('month', today(), -13);
		/** If it's the first day of the month and before a set time then remove previous month **/
		if (day(today()) = 1) and (time() < hms(17, 0, 0)) then do;
			if intnx('month', procdate, 0, 'beginning') = intnx('month', today(), -1, 'beginning') then delete;
		end;
		/** Add indicators for non-standard status states **/
		if status = "RELEASED" then do;
			display = catx(' ', put(procdate, monname.), put(procdate, year4.));
			value = cats(put(procdate, monyy7.), 'N');
		end;
		else if status = "DATA APPROVED" and "&SAVE_REVIEW" = "Y" then do;
			display = catx(' ', put(procdate, monname.), put(procdate, year4.), '- DRAFT');
			value = cats(put(procdate, monyy7.), 'D');
		end;
		else if status = "REVISED" then do;
			display = catx(' ', put(procdate, monname.), put(procdate, year4.), '- REVISED');
			value = cats(put(procdate, monyy7.), 'R');
		end;
		else do;
			display = catx(' ', put(procdate, monname.), put(procdate, year4.), '- N/A');
			value = cats(put(procdate, monyy7.), 'U');
		end;
	run;

	/** Set parameters that will be passed to the %create_drop_down_menu macro **/
	data _null_;
		set month;
		if _n_ = 1;
		call symput('selectoptions', 'month');
		call symputx('drop_down_label', 'Select a Month');
		%if not %symexist(procdatev) %then %do;
		call symputx('procdatev', value);
		%end;
	run;

	/** Turn the monthly date selections into a drop-down menu **/
	%create_drop_down_menu(&selectoptions, &drop_down_label, &procdatev, N, &stack_select_labels);
		
%mend month_drop_down_menu;

/*********************************************************************/
/** %CUST_DESIGNATOR_MENU will take customer table from the 		**/
/** specified account and create a  data set that will	get passed	**/
/** to %create_drop_down_menu										**/
/**																	**/
/** %CUST_DESIGNATOR_MENU accepts the following arguments:			**/
/**		- stack_select_label										**/
/**		- order														**/
/**																	**/
/*********************************************************************/
%macro cust_designator_menu(stack_select_labels, order);

	/** Retrieve the NALI customer designator table **/
	data cust_designator;
		set natables.nali_customertable;
		if active = 'Y';
		&restrictions;
	run;

	proc sort data = cust_designator;
		by cust_name;
	run;

	data cust_designator (keep=value display);
		length value display $500.;
		set cust_designator;
		by cust_name;
		value = cust_designator;
		display = cust_name;
	run;

	/** Set parameters that will be passed to the %create_drop_down_menu macro **/
	data _null_;
		set cust_designator;
		if _n_ = 1;
		call symput('selectoptions', 'cust_designator');
		call symputx('drop_down_label', 'Select a Customer');
		%if not %symexist(cust_designator_select) %then %do;
		call symputx('cust_designator_select', value);
		%end;
	run;

	/** Turn the monthly date selections into a drop-down menu **/
	%create_drop_down_menu(&selectoptions, &drop_down_label, &cust_designator_select, Y, &stack_select_labels, &order);

%mend;

/*********************************************************************/
/** %AA_MENU will take affiliated agencies table from the specified	**/
/** account and create a data set that will get	passed to			**/
/** %create_drop_down_menu											**/
/**																	**/
/** %AA_MENU accepts the following arguments:						**/
/**		- stack_select_label										**/
/**		- order														**/
/**																	**/
/*********************************************************************/
%macro aa_menu(stack_select_labels, order);

	/** Retrieve the NALI customer designator table **/
	data aa;
		set txsrc.txaffiliatedagencies;
		&restrictions;
	run;

	proc sort data = aa;
		by aaname;
	run;

	data aa (keep=value display);
		length value display $500.;
		set aa;
		by aaname;
		value = aa;
		display = aaname;
	run;

	/** Set parameters that will be passed to the %create_drop_down_menu macro **/
	data _null_;
		set aa;
		if _n_ = 1;
		call symput('selectoptions', 'aa');
		call symputx('drop_down_label', 'Select an Agency');
		%if not %symexist(aa_select) %then %do;
		call symputx('aa_select', value);
		%end;
	run;

	/** Turn the monthly date selections into a drop-down menu **/
	%create_drop_down_menu(&selectoptions, &drop_down_label, &aa_select, Y, &stack_select_labels, &order);

%mend;

