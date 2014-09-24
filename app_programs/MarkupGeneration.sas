******************************************************************************************************************************;
** Program: MarkupGeneration.sas																							**;
** Purpose: To automatically generate the markup associated with common outputs and formats									**;
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
**		- %standard_table_header_html																						**;
**		- %standard_table_body_html																							**;
**		- %standard_table_footer_html																						**;
**																															**;
** History:																													**;
**		01/01/2014 John Sandoval - Initial Release																			**;
**																															**;
******************************************************************************************************************************;

/*****************************************************************/
/** Translate data set into standard HTML <TABLE> header markup **/
/*****************************************************************/
%macro standard_table_header_html(dataset, id, css_classes, table_title);

	/** Count the records in the header data **/
	%let header_count = 0;
	data _null_;
		set &dataset end=last;
		if last then call symputx('header_count', compress(_n_));
	run;

	%if %eval(&header_count) > 0 %then %do;
		/** Create CSS styles for column data types **/
		data column_properties(keep=column_align css_prop);
			length css_prop $1000.;
			set &dataset;
			if lowcase(column_align) in ('left', 'l') then do;
				css_prop = "'text-align', 'left'";
			end;
			else if lowcase(column_align) in ('center', 'c') then do;
				css_prop = "'text-align', 'center'";
			end;
			else if lowcase(column_align) in ('right', 'r') then do;
				css_prop = "'text-align', 'right'";
			end;
			else do;
				css_prop = "'text-align', 'left'";
			end;
		run;
		
		/** Markup the table and table header elements **/
		data &dataset(keep=text);
			length text $5000. header_markup $300.;
			set &dataset end=last;
			%if "&table_title" ne "" %then %do;
				table_title = cats('<div class="', catx(' ', 'content-table-title', "&css_classes"), '">', "&table_title", '</div>');
			%end;
			%else %do;
				table_title = '';
			%end;
			header_markup = cats('<th>', header_value, '</th>');
			header_spacer = cats('<tbody class="table-head-bottom-margin no-sort"><tr><td colspan=', "&header_count", '>&nbsp;</td></tr></tbody>');
			if _n_ = 1 then do;	
				table_start = cats('<table id="table-', "&id", '" class="', catx(' ', 'content-table', "&css_classes"), '"><thead><tr>');
				if not last then do;
					text = cats(table_title, table_start, header_markup);
				end;
				else do;
					text = cats(table_title, table_start, header_markup, '</thead>', header_spacer);
				end;
			end;
			else if not last then do;
				text = cats(header_markup);
			end;
			else if last then do;
				text = cats(header_markup, '</tr></thead>', header_spacer);
			end;
		run;

		/** JavaScript to align columns based on data type **/
		data jquery(keep=text);
			length text $1500.;
			set column_properties;
			text = cats('$jload(''.content-table tbody.table-content td:nth-child(', _n_, ')'').css(', css_prop, ');');
		run;

		data _null_;
			set jquery end=last;
			retain temp;
			length temp $25000.;
			temp = cats(temp, '0D'x, trim(text));
			if last then call symputx('onload_jquery', cats("&onload_jquery", '0D'x, trim(temp)));
		run;

	%end;
	/** If no records then produce a formatted blank data set **/
	%else %do;
		data &dataset(keep=text);
			length text $5000.;
			set &dataset;
			if _n_ = 0;
		run;
	%end;

%mend standard_table_header_html;

/***************************************************************/
/** Translate data set into standard HTML <TABLE> body markup **/
/***************************************************************/
%macro standard_table_body_html(dataset);

	/** Count the records in the body data **/
	%let body_count = 0;
	data _null_;
		set &dataset end=last;
		if last then call symputx('body_count', compress(_n_));
	run;

	/** If table body records count is greater than &table_row_limit then resize and flag **/
	%let table_row_limit_exceeded = N;
	%if (%eval(&body_count) > %eval(&table_row_limit)) and ("&exportto" = "html") %then %do;
		data &dataset;
			set &dataset (firstobs = 1 obs = &table_row_limit);
		run;

		data _null_;
			call symputx('table_row_limit_exceeded', 'Y');
			call symputx('table_row_limit_message', catx(' ', 'Showing', put(&table_row_limit, comma12.), 'of', put(&body_count, comma12.), 'records. Please use Export to see all records.'));
			call symputx('page_alert', 'Y');
			call symputx('page_alert_message', catx(' ', 'Showing', put(&table_row_limit, comma12.), 'of', put(&body_count, comma12.), 'records. Please use Export to see all records'));
		run;
	%end;

	/** Determine the variables **/
	proc contents data = &dataset out=ds_vars(keep=name varnum) noprint;
	run;
	
	%let var_count = 0;
	data _null_;
		set ds_vars end=last;
		if last then call symputx('var_count', compress(_n_));
	run;

	/** Build the row string to place each variable to a table cell **/
	%if %eval(&var_count) > 0 %then %do;
	proc sort data = ds_vars;
		by varnum;
	run;

	data _null_;
		length ds_var_list_187 $5000.;
		retain ds_var_list_187;
		set ds_vars end=last;
		ds_var_list_187 = cats(ds_var_list_187, "'<td>',", name, ",'</td>',");
		if last then do;
			call symputx('row_def', cats("'<tr>',", ds_var_list_187, "'</tr>'"));
		end;
	run;
	%end;
	%else %do;
		data _null_;
			call symputx('row_def', '');
		run;
	%end;

	/** Markup the full table body and row elements **/
	%if %eval(&body_count) > 0 and %eval(&var_count) > 0 %then %do;
		data &dataset(keep=text);
			length text $5000.;
			set &dataset end=last;
			if _n_ = 1 then do;
				body_start = cats('<tbody class="table-content">');
				if not last then do;
					text = cats(body_start, &row_def);
				end;
				else do;
					text = cats(body_start, &row_def,
								/** If table row limit reached display a message in the last row **/
								ifc("&table_row_limit_exceeded"="Y", cats('<tr><td class="row-limit-message" colspan=', "&var_count", '>', "&table_row_limit_message", '</td></tr>'), ''),
								'</tbody>');
				end;
			end;
			else if not last then do;
				text = cats(&row_def);
			end;
			else if last then do;
				text = cats(&row_def,
							/** If table row limit reached display a message in the last row **/
							ifc("&table_row_limit_exceeded"="Y", cats('<tr><td class="row-limit-message" colspan=', "&var_count", '>', "&table_row_limit_message", '</td></tr>'), ''),
							'</tbody>');
			end;
		run;
	%end;
	/** If no records then produce a formatted blank data set **/
	%else %do;
		data &dataset(keep=text);
			length text $5000.;
			set &dataset;
			if _n_ = 0;
		run;
	%end;

%mend standard_table_body_html;

/*****************************************************************/
/** Translate data set into standard HTML <TABLE> footer markup **/
/*****************************************************************/
%macro standard_table_footer_html(dataset);

	/** Count the records in the footer data **/
	%let footer_count = 0;
	data _null_;
		set &dataset end=last;
		if last then call symputx('footer_count', compress(_n_));
	run;

	/** Determine the variables **/
	proc contents data = &dataset out=ds_vars(keep=name varnum) noprint;
	run;
	
	%let var_count = 0;
	data _null_;
		set ds_vars end=last;
		if last then call symputx('var_count', compress(_n_));
	run;

	/** Build the row string to place each variable to a table cell **/
	%if %eval(&var_count) > 0 %then %do;
	proc sort data = ds_vars;
		by varnum;
	run;

	data _null_;
		length ds_var_list_187 $5000.;
		retain ds_var_list_187;
		set ds_vars end=last;
		ds_var_list_187 = cats(ds_var_list_187, "'<td>',", name, ",'</td>',");
		if last then do;
			call symputx('row_def', cats("'<tr>',", ds_var_list_187, "'</tr>'"));
		end;
	run;
	%end;
	%else %do;
		data _null_;
			call symputx('row_def', '');
		run;
	%end;

	/** Markup the full table footer spacer and row elements **/
	%if %eval(&footer_count) > 0 and %eval(&var_count) > 0 %then %do;
		data &dataset(keep=text);
			length text $5000.;
			set &dataset (firstobs = 1 obs = 1) end=last;
			footer_start = cats('<tbody class="table-body-bottom-margin no-sort"><tr><td colspan=', "&var_count", '>&nbsp;</td></tr></tbody><tfoot>');
			text = cats(footer_start, &row_def, '</tfoot></table>');
		run;
	%end;
	/** If no records then produce a formatted blank data set **/
	%else %do;
		data &dataset(keep=text);
			length text $5000.;
			set &dataset;
			text = '</table>';
		run;
	%end;

%mend standard_table_footer_html;