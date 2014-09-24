******************************************************************************************************************************;
** Program: MasterAccountSettings.sas																						**;
** Purpose: To handle any account-specific global settings																	**;
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

/***************************************************/
/** Set Master Account values based on Supergroup **/
/***************************************************/
data _null_;
	/** Wireline Group **/
	if "&supergroup" = "Alaska" then do;
		call symputx('ma', 						'ak');
		call symputx('state_list', 				'AK');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "ATT Midwest" then do;
		call symputx('ma', 						'mw');
		call symputx('state_list', 				'');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "ATT Southeast" then do;
		call symputx('ma', 						'se');
		call symputx('state_list', 				'');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "ATT Southwest East" then do;
		call symputx('ma', 						'sw');
		call symputx('state_list', 				'');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "CenturyLink" then do;
		call symputx('ma', 						'cl');
		call symputx('state_list', 				'');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "CLEC" then do;
		call symputx('ma', 						'ch');
		call symputx('state_list', 				'');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "Fairpoint" then do;
		call symputx('ma', 						'fp');
		call symputx('state_list', 				'');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "Frontier" then do;
		call symputx('ma', 						'fc');
		call symputx('state_list', 				'');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "Hawaii" then do;
		call symputx('ma', 						'hi');
		call symputx('state_list', 				'HI');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "National ALI" then do;
		call symputx('ma', 						'na');
		call symputx('state_list',				'');
		call symputx('account_specific_var', 	'cust_designator');
	end;
	if "&supergroup" = "Texas" then do;
		call symputx('ma', 						'tx');
		call symputx('state_list', 				'TX');
		call symputx('account_specific_var', 	'aa');
	end;
	if "&supergroup" = "Verizon" then do;
		call symputx('ma', 						'vz');
		call symputx('state_list', 				'');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "Vermont" then do;
		call symputx('ma', 						'vt');
		call symputx('state_list', 				'VT');
		call symputx('account_specific_var', 	'');
	end;
	if "&supergroup" = "Virginia Beach" then do;
		call symputx('ma', 						'vb');
		call symputx('state_list', 				'VA');
		call symputx('account_specific_var', 	'');
	end;
	/** IEN Group **/
	if "&supergroup" = "IEN Voice" then do;
		call symputx('ma', 'iv');
	end;
	/** Mobility Group **/
	if "&supergroup" = "Converged" then do;
		call symputx('ma', 'cn');
	end;
	if "&supergroup" = "Sprint" then do;
		call symputx('ma', 'sp');
	end;
	if "&supergroup" = "Telematics" then do;
		call symputx('ma', 'tm');
	end;
	if "&supergroup" = "VoIP" then do;
		call symputx('ma', 'vp');
	end;
	if "&supergroup" = "VUI" then do;
		call symputx('ma', 'vui');
	end;
	if "&supergroup" = "Wireless" then do;
		call symputx('ma', 'wr');
	end;

	/** General **/
	call symputx('account_specific_uri', 			'');
	call symputx('account_specific_uri_unencoded', 	'');
run;

/*******************************/
/** Master Account Auto-flags **/
/*******************************/
%macro auto_account_flags;
	data _null_;
		/** Automatically determine if the master account is a 1-state account **/
		%if %symexist(state_list) %then %do;
			%global single_state_account;
			if "&state_list" ne '' and countw("&state_list", ',', 's') = 1 then do;
				call symputx('single_state_account', 'Y');
			end;
			else do;
				call symputx('single_state_account', 'N');
			end;
		%end;
	run;

%mend;
%auto_account_flags;

/*********************************************************************/
/** %ACCOUNT_SPECIFIC_SELECTIONS will modify the common 			**/
/**	level-specific report processing variables to include the		**/
/** account-specific variables. It will also generate a drop-down	**/
/** selection for the account-specific variable. This account-		**/
/** specfic variable refactoing is all dependent on the name of the	**/
/** variable in our SAS data sets.									**/
/**																	**/
/** %ACCOUNT_SPECIFIC_SELECTIONS accepts the following arguments:	**/
/**		- account_specific_var										**/
/**																	**/
/*********************************************************************/
%macro account_specific_selections(account_specific_var);

	/** Update the Group By variables **/
	%if %symexist(group_by_vars) %then %do;
		data _null_;
			call symputx('group_by_vars', catx(' ', "&account_specific_var", "&group_by_vars"));
		run;
	%end;

	/** Update the Filter Clause **/
	%if %symexist(&account_specific_var._select) %then %do;
		%if "&&&account_specific_var._select" ne "ALL" %then %do;
			data _null_;
				call symput('filter_clause', catx(' ', symget("filter_clause"), '; where also', "&account_specific_var", cats("='", trim(urldecode(trim("&&&account_specific_var._select"))), "'")));
			run;
		%end;
	%end;
	%else %do;
		%let &account_specific_var._select = ALL;
	%end;

	/** Create additional URI variables **/
	data _null_;
		call symputx('account_specific_uri', cats('&amp;', "&account_specific_var",'_select=', trim(urlencode(trim("&&&account_specific_var._select")))));
		call symputx('account_specific_uri_unencoded', cats('%nrstr(&)', "&account_specific_var",'_select=', trim(urlencode(trim("&&&account_specific_var._select")))));
	run;

	/** Create the Customer drop down **/
	%&account_specific_var._menu( ,2);

%mend;