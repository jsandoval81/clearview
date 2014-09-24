/*****************************************************************************************************************************/
/** This code contains the builds of the web-based data sets for ClearView 2.0.												**/
/** The builds in this program can be used to add/remove fields and modify data within the existing data sets.				**/
/**	(with tested Development code and after a Production backup, of course)													**/
/**																															**/
/**	- WEB_PART_CATALOG																										**/
/**		Added: Initial Build																								**/
/**		Added By: John Sandoval																								**/
/**		Description: This is the master catalog for all ClearView web parts													**/
/**	- DASHBOARD_WEB_PARTS																									**/
/**		Added: Initial Build																								**/
/**		Added By: John Sandoval																								**/
/**		Description: This maintains the user's dashboard web parts and their placement on the screen						**/
/**	- FAVORITES																												**/
/**		Added: Initial Build																								**/
/**		Added By: John Sandoval																								**/
/**		Description: This maintains the user's favorites menu																**/
/**	- HELP_ENTRY_CATALOG																									**/
/**		Added: Initial Build																								**/
/**		Added By: John Sandoval																								**/
/**		Description: This is the master catalog for ClearView help entries													**/
/**	- HELP_ENTRY_REPORT_ASSOC																								**/
/**		Added: Initial Build																								**/
/**		Added By: John Sandoval																								**/
/**		Description: This maintains the association of help entries to reports. Normalization increases performance here.	**/
/**																															**/
/*****************************************************************************************************************************/

/**********************/
/** WEB_PART_CATALOG **/
/**********************/
data admindev.web_part_catalog;
	length  web_part_id 			8.
			web_part_type			$256.
			web_part_name 			$1500.
			description 			$5000.
			report_web_part 		$1.
			dashboard_web_part		$1.
			entry_added_dt			8.
			entry_added_by			$256.
			entry_last_modified_dt	8.
			entry_last_modified_by	$256.
			entry_removed_dt		8.
			entry_removed_by		$256.
			deleted_ind 			$1.
			;
	retain 	web_part_id
			web_part_type
			web_part_name
			description
			report_web_part
			dashboard_web_part
			entry_added_dt
			entry_added_by
			entry_last_modified_dt
			entry_last_modified_by
			entry_removed_dt
			entry_removed_by
			deleted_ind
			;
	format entry_added_dt entry_last_modified_dt entry_removed_dt datetime19.;
	set admindev.web_part_catalog;
run;

/*************************/
/** DASHBOARD_WEB_PARTS **/
/*************************/
data admindev.dashboard_web_parts;
	length  user_id 		$100.
			web_part_id 	8.
			level			8.
			top				$50.
			left 			$50.
			;
	retain  user_id
			web_part_id
			level
			top
			left
			;
	set admindev.dashboard_web_parts;
run;

/***************/
/** FAVORITES **/
/***************/
data admindev.favorites;
	length  user_id 			$100.
			objId				$17.
			master_account		$256.	
			Location			$1024.
			objName				$60.			
			level				8.
			params				$1500.
			favorites_add_dt	8.
			last_run_dt			8.
			;
	retain  user_id
			objId
			master_account
			Location
			objName
			level
			params
			favorites_add_dt
			last_run_dt
			;
	format favorites_add_dt last_run_dt datetime19.;
	set admindev.favorites;
run;

/************************/
/** HELP_ENTRY_CATALOG **/
/************************/
data admindev.help_entry_catalog;
	length  entry_id 			8.
			entry_title			$500.
			entry_text 			$5000.
			sort_order 			8.
			last_updated_dt		8.
			last_updated_by		$500.
			revision_num		8.
			;
	retain 	entry_id
			entry_title
			entry_text
			sort_order
			last_updated_dt
			last_updated_by
			revision_num
			;
	format last_updated_dt datetime19.;
	set admindev.help_entry_catalog;
run;

/*****************************/
/** HELP_ENTRY_REPORT_ASSOC **/
/*****************************/
data admindev.help_entry_report_assoc;
	length  ObjId			$17.
			entry_id 		8.
			;
	retain 	ObjId
			entry_id
			;
	set admindev.help_entry_report_assoc;
run;