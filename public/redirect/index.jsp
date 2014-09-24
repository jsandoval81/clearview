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
            document.write("<input type=hidden name=_username value=");

            <logic:present header="Safeword-User">
            <bean:header id="theheader" name="Safeword-User"/>
            document.write("<bean:write name="theheader"/>@saspw");
            </logic:present>

            <logic:notPresent header="Safeword-User">
            <bean:header id="theheader" name="User"/>
            document.write("<bean:write name="theheader"/>@saspw");
            </logic:notPresent>

            document.write(">");
            document.write("<input type=hidden name=_password value=>"); // SAS internal user PW here
            document.write("<input type=hidden name=save_emulate value=0>");
        
            window.document.theform.submit();
        </script>

    </body>
</html>