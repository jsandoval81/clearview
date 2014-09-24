<%@ page language="java" %>
<%@ taglib uri="/WEB-INF/struts-bean.tld" prefix="bean" %>
<%@ taglib uri="/WEB-INF/struts-logic.tld" prefix="logic" %>

<html>
    <head>
        <title>Intrado Metrics</title>
    </head>
    <body>

        <script>
            document.write("<form name=theform method=post action=/SASStoredProcess/do?&_program=/Products/SAS%20Intelligence%20Platform/Samples/Wireline_Session>");
            document.write("<input type=hidden name=_password value=>"); // SAS internal user PW here
            document.write("<input type=hidden name=safewordfobuserid value=");
            document.write(">");
            document.write("<input type=hidden name=save_emulate value=1>");
            document.write("<textarea rows=1 cols=75 name=_username></textarea>");
            document.write("<input type=submit value=Enter>");
        </script>

    </body>
</html>