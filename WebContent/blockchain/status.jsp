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

	String address = request.getParameter("a");
	if (address == null || address.length() == 0) {
		address = YPWallet.getAddress(privateKey);
	}

	String step = request.getParameter("s");
	if (step == null || step.length() == 0) {
		step = "1";
	}
%>
<body>
	<a href="status.jsp?e=<%=endpoint%>&p=<%=privateKey%>&a=<%=address%>">RESTART</a><br>
	<a href="status.jsp">RESET</a><br>
	<%	if (step.equals("1")) { %>
			<form action="status.jsp?s=3" method="post" id="form1">
				<h3>Node URL</h3>
				<input type="text" name="e" value="<%=endpoint%>">
				<h3>private key</h3>
				<input type="text" name="p" value="<%=privateKey%>"> <input
					type="submit" value="Search">
			</form>
			<hr />
			<form action="status.jsp?s=4" method="post" id="form1">
				<h3>Node URL</h3>
				<input type="text" name="e" value="<%=endpoint%>">
				<h3>address</h3>
				<input type="text" name="a" value="<%=address%>"> <input
					type="submit" value="Search">
			</form>
	<%
		} else {
			YPWallet fw = null;
			if (step.equals("3")) {
				fw = new YPWallet(endpoint, privateKey);
				address = fw.getAddress();
			} else if (step.equals("4")) {
				fw = new YPWallet(endpoint, null);

				out.println("<br>using");
				out.println("<br>- Address     : " + fw.getAddress());
				out.println("<br>- Private Key : " + fw.getPrivateKey());
			} else {
				response.sendRedirect("status.jsp");
			}
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
			<h1>User Info</h1>
			<ul>
			<%	if (step.equals("3")) { %>
					<li>Private Key</li>
					<li>
						<ul>
							<li><%=fw.getPrivateKey()%></li>
						</ul>
					</li>
			<%	} %>
				<li>Address</li>
				<li>
					<ul>
						<li><%=address%></li>
					</ul>
				</li>
				<li>Balance</li>
				<li>
					<ul>
						<li><%=fw.getBalance(address)%></li>
					</ul>
				</li>
			</ul>
			<h1>Unspent Outputs</h1>
			<table>
				<tr>
					<th>Index</th>
					<th>Value</th>
					<th>TX ID</th>
				</tr>
			<%
				Output[] utxos = fw.getCoinstackClient().getUnspentOutputs(address);
				// sort by value (desc)
				if (utxos.length > 0) {
					for (int i = 0; i < utxos.length; i++) {
						boolean changed = false;
						for (int j = i; j < utxos.length; j++) {
							if (utxos[i].getValue() < utxos[j].getValue()) {
								// switch
								Output tmp = utxos[i];
								utxos[i] = utxos[j];
								utxos[j] = tmp;
		
								// restart comparing
								changed = true;
								break;
							}
						}
	
						if (changed) {
							i--;
						}
					}
				}

				String txId = null;
				if (utxos.length > 0) {
					txId = utxos[0].getTransactionId();
					out.println("<br>Total unspent outputs = " + utxos.length + "<br>");
				}

				for (int i = 0; i < utxos.length; i++) {
					out.println("<tr>");
					out.println("<td>" + utxos[i].getIndex() + "</td>");
					out.println("<td>" + utxos[i].getValue() + "</td>");
					out.println("<td>" + utxos[i].getTransactionId() + "</td>");
					out.println("</tr>");
				}
			%>
			</table>
			<h1>Related TXs</h1>
			<table>
				<tr>
					<th>Confirm Time</th>
					<th>TX ID</th>
					<th>Output TX ID</th>
					<th>Output Address</th>
					<th>Value</th>
					<th>Data</th>
					<th>Is Spent</th>
				</tr>
			<%
				int maxRowCnt = 5;
				String[] txIds = fw.getCoinstackClient().getTransactions(address);
				for (String id : txIds) {
					if (maxRowCnt == 0) break;
					maxRowCnt--;

					Transaction tx = fw.getCoinstackClient().getTransaction(id);
					Input[] txIs = tx.getInputs();
					//System.out.println(txIs[0].getOutputAddress());
					Output[] txOs = tx.getOutputs();
				%>
					<tr>
						<td rowspan="<%=txOs.length%>"><%=tx.getConfirmationTime()%></td>
						<td rowspan="<%=txOs.length%>"><%=tx.getId()%></td>
				<%
					String oTxId = txOs[0].getTransactionId();
					String oAddr = txOs[0].getAddress();
					byte[] oData = txOs[0].getData();
					String oDataStr = "";
					String oDataHex = "";
					if (oData != null) {
						oDataStr = new String(oData);
						oDataHex = Hex.encodeHexString(oData);
					}
				%>
						<td><%=oTxId%></td>
				<%	if (fw.getAddress().equals(oAddr)) { %>
							<td style="color: #ff0000"><%=oAddr%></td>
				<%	} else { %>
							<td><%=oAddr%></td>
				<%	} %>
						<td><%=txOs[0].getValue()%></td>
						<td><%=oDataStr%></td>
						<td><%=txOs[0].isSpent()%></td>
					</tr>
				<%
					for (int j = 1; j < txOs.length; j++) {
						oTxId = txOs[j].getTransactionId();
						oAddr = txOs[j].getAddress();
						oData = txOs[j].getData();
						oDataStr = "";
						oDataHex = "";
						if (oData != null) {
							oDataStr = new String(oData);
							oDataHex = Hex.encodeHexString(oData);
						}
					%>
						<tr>
							<td><%=oTxId%></td>
					<%	if (fw.getAddress().equals(oAddr)) { %>
							<td style="color: #ff0000"><%=oAddr%></td>
					<%	} else { %>
							<td><%=oAddr%></td>
					<%	} %>
							<td><%=txOs[j].getValue()%></td>
							<td><%=oDataStr%><br><%=oDataHex%></td>
							<td><%=txOs[j].isSpent()%></td>
						</tr>
				<%
					}
				}
			%>
			</table>
	<%	} %>
</body>
</html>