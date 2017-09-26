<%@page import="java.util.Arrays"%>
<%@page import="java.util.HashMap"%>
<%@page import="org.apache.commons.codec.binary.Hex"%>
<%@page import="io.blocko.coinstack.model.Input"%>
<%@page import="io.blocko.coinstack.model.Transaction"%>
<%@page import="java.util.ArrayList"%>
<%@page import="io.blocko.coinstack.model.Output"%>
<%@page import="io.blocko.yp.YPWallet"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Blockchain Status</title>
<style>
table, th, td {
	border: 1px solid black;
}
</style>
</head>
<%
	String endpoint = request.getParameter("e");
	if (endpoint == null || endpoint.length() == 0) {
		endpoint = YPWallet.DEFAULT_ENDPOINT;
	}

	String privateKey = request.getParameter("p");
	if (privateKey == null || privateKey.length() == 0) {
		privateKey = YPWallet.DEFAULT_PV_KEY;
	}

	String txID = request.getParameter("t");

	String step = request.getParameter("s");
	if (step == null || step.length() == 0) {
		step = "1";
	}
%>
<body>
	<a href="tx.jsp?e=<%=endpoint%>&p=<%=privateKey%>&t=<%=txID%>">RESTART</a><br>
	<a href="tx.jsp">RESET</a><br>
	<%	if (step.equals("1")) { %>
			<form action="tx.jsp?s=2" method="post" id="form1">
				<h3>Node URL</h3>
				<input type="text" name="e" value="<%=endpoint%>">
				<h3>private key</h3>
				<input type="text" name="p" value="<%=privateKey%>">
				<h3>TX ID</h3>
				<input type="text" name="t" value="<%=txID%>">
				<input type="submit" value="Search">
			</form>
	<%
		} else {
			YPWallet fw = new YPWallet(endpoint, privateKey);
			Transaction tx = fw.getCoinstackClient().getTransaction(txID);
	%>
			<h1>CONFIG VALUES</h1>
			<span>Endpoint URL: <%=endpoint%></span>
			<h1>Blockchain Status</h1>
			<ul>
				<li>Best Block Hash</li>
				<li>
					<ul>
						<li><%=fw.getCoinstackClient().getBlockchainStatus().getBestBlockHash()%></li>
					</ul>
				</li>
				<li>Best Block Height</li>
				<li>
					<ul>
						<li><%=fw.getCoinstackClient().getBlockchainStatus().getBestHeight()%></li>
					</ul>
				</li>
			</ul>
			<h1>Inputs</h1>
			<table>
				<tr>
					<th>Index</th>
					<th>Address</th>
					<th>UTXO ID</th>
					<th>Value</th>
				</tr>
			<%
				Input[] ins = tx.getInputs();
				for (int i = 0; i < ins.length; i++) {
					out.println("<tr>");
					out.println("<td>" + ins[i].getOutputIndex() + "</td>");
					out.println("<td>" + ins[i].getOutputAddress() + "</td>");
					out.println("<td>" + ins[i].getOutputTransactionId() + "</td>");
					out.println("<td>" + ins[i].getValue() + "</td>");
					out.println("</tr>");
				}
			%>
			</table>
			<h1>Outputs</h1>
			<table>
				<tr>
					<th>Index</th>
					<th>Address</th>
					<th>TX ID</th>
					<th>Value</th>
				</tr>
			<%
				Output[] outs = tx.getOutputs();
				for (int i = 0; i < outs.length; i++) {
					out.println("<tr>");
					out.println("<td>" + outs[i].getIndex() + "</td>");
					out.println("<td>" + outs[i].getAddress() + "</td>");
					out.println("<td>" + outs[i].getTransactionId() + "</td>");
					out.println("<td>" + outs[i].getValue() + "</td>");
					out.println("</tr>");
				}
			%>
			</table>
	<%	} %>
</body>
</html>