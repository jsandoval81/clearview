******************************************************************************************************************************;
** Program: DefaultWebPartVariables.sas																						**;
** Purpose: To set the default values of the web part configuration variables												**;
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

/***************************************/
/** Create default web part variables **/
/***************************************/
data _null_;
	/**************************************************/
	/** Default restrictions (restricted)			 **/
	/**************************************************/
	%global restrictions;
	call symputx('restrictions', 'if 1 = 2');
	/**************************************************/
	/** Default date format/report frequency 		 **/
	/**************************************************/
	call symputx('date_format', 		'Monthly');
	/**************************************************/
	/** Default validate log 						**/
	/**************************************************/
	call symputx('validate_log', 		'');
	/**************************************************/
	/** Default data warehouse						**/
	/**************************************************/
	call symputx('data_warehouse', 		'');
	/**************************************************/
	/** Default inclusion of date type selection 	**/
	/**************************************************/
	call symputx('date_type_selection', 'N');
	/**************************************************/
	/** Default inclusion of day selection 			**/
	/**************************************************/
	call symputx('day_selection', 		'N');
	/**************************************************/
	/** Default inclusion of week selection 		**/
	/**************************************************/
	call symputx('week_selection', 		'N');
	/**************************************************/
	/** Default inclusion of month selection 		**/
	/**************************************************/
	call symputx('month_selection', 	'N');
	/**************************************************/
	/** Default inclusion of quarter selection 		**/
	/**************************************************/
	call symputx('quarter_selection', 	'N');
	/**************************************************/
	/** Default inclusion of year selection 		**/
	/**************************************************/
	call symputx('year_selection', 		'N');
	/**************************************************/
	/** Default usage of stacked drop-down labels	 **/
	/**************************************************/
	call symputx('stack_select_labels',	'N');
	/**************************************************/
	/** Default inclusion of a totals row			 **/
	/**************************************************/
	call symputx('totals_row',			'N');
	/**************************************************/
	/** Default usage of submit button for selections**/
	/**************************************************/
	%global refresh_on_select;
	call symputx('refresh_on_select', 	'N');
run;