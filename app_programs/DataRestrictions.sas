******************************************************************************************************************************;
** Program: DataRestrictions.sas																							**;
** Purpose: To set the row-level data restrictions on data sets used in ClearView reporting									**;
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
**	None																													**;
**																															**;
** History:																													**;
**		01/01/2014 John Sandoval - Initial Release																			**;
**																															**;
******************************************************************************************************************************;

%macro data_restrictions;

	/** Eventually this library will need to be moved into the 2.0 folders and use the admprod library **/
	libname restrict '\\lmv08-metdb02\imd\web_server\user\data';

	/** Retrieve data restrictions for user, master account, and data type **/
	data restrictions(keep=restriction_setting);
		set restrict.user_restrictions;
		if (metaperson = "&_METAPERSON") and (mastact = "&supergroup") and (data_type in &data_type);
		length restriction_setting $5000.;
		restriction_setting = catx(' ', data_type, 'in', list);
	run;

	/** Add restriction for Vermont External Customers **/
	%if ("&supergroup" = "Vermont") and ("&SAVE_REVIEW" ne "Y") %then %do;
		data vt_restrictions(keep=restriction_setting);
			length restriction_setting $5000.;
			if 'PSAPID' in &data_type then do;
				restriction_setting = "PSAPID in ('VT DIRECT MULTI PSAP 01')";
			end;
		run;

		data restrictions;
			set restrictions vt_restrictions;
		run;

		/** Remove the temporary Vermont data set **/
		proc datasets nolist;
			delete vt_restrictions;
		run;
	%end;
	
	/** Determine the number of restrictions retrieved **/
	%let num_restrictions = 0;
	data _null_;
		set restrictions end=last;
		if last then call symputx('num_restrictions', compress(_n_));
	run;

	/** Compile the restrictions settings into the &RESTRICTIONS macro variable **/
	%if %eval(&num_restrictions) > 0 %then %do;
		data _null_;
			set restrictions end=last;
			length restrictions $25000. operator $10.;
			retain restrictions;
			if _n_ = 1 then operator = 'if';
			else operator = 'and';
			restrictions = catx(' ', restrictions, operator, restriction_setting);
			if last then call symputx('restrictions', restrictions);
		run;
	%end;
	%else %do;
		data _null_;
			call symputx('restrictions', '');
		run;
	%end;

	/** Remove restrictions data set now that value is stored in the macro catalog **/
	proc datasets nolist;
		delete restrictions;
	run;

%mend data_restrictions;