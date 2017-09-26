<%@page import="org.bitcoinj.core.Wallet.ExceededMaxTransactionSize"%>
<%@page import="org.bitcoinj.core.Sha256Hash"%>
<%@page import="org.apache.commons.codec.binary.Hex"%>
<%@page import="io.blocko.yp.YPWallet"%>
<%@page import="io.blocko.coinstack.ECDSA"%>
<%@page import="io.blocko.coinstack.exception.CoinStackException"%>
<%@page import="io.blocko.coinstack.Math"%>
<%@page import="io.blocko.coinstack.model.Transaction"%>
<%@page import="io.blocko.coinstack.TransactionBuilder"%>
<%@page import="java.util.Properties"%>
<%@page import="java.io.InputStream"%>
<%@page import="io.blocko.coinstack.ECKey"%>
<%@page import="io.blocko.coinstack.Endpoint"%>
<%@page import="io.blocko.coinstack.model.CredentialsProvider"%>
<%@page import="io.blocko.coinstack.CoinStackClient"%>
<%@page import="io.blocko.coinstack.model.BlockchainStatus"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Coin Transfer</title>
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

	String coinStr = request.getParameter("c");
	long coin = 0;
	if (coinStr != null && coinStr.length() != 0)
		coin = Long.parseLong(coinStr);

	String feeStr = request.getParameter("f");
	long fee = YPWallet.BLOCKCHAIN_TX_FEE;
	if (feeStr != null && feeStr.length() != 0)
		fee = Long.parseLong(feeStr);

	String step = request.getParameter("s");
	if (step == null || step.length() == 0) {
		step = "1";
	}
%>
<body>
	<a href="transfer.jsp?e=<%=endpoint%>&p=<%=privateKey%>&a=<%=address%>&c=<%=coin%>&f=<%=fee%>">RESTART</a><br>
	<a href="transfer.jsp">RESET</a><br>
<%
	// input
	if (step.equals("1")) {
%>
		<form action="transfer.jsp?s=2" method="post" id="form1">
			<h3>Node URL</h3>
			<input type="text" name="e" value="<%=endpoint%>">
			<h3>보내는 사람 (private key)</h3>
			<input type="text" name="p" value="<%=privateKey%>">
			<h3>받는 사람 (address)</h3>
			<input type="text" name="a" value="<%=address%>">
			<h3>이체 금액 (satoshi)</h3>
			<input type="text" name="c" value="<%=coin%>">
			<h3>수수료 (satoshi)</h3>
			<input type="text" name="f" value="<%=fee%>">
			<p>fee is <%=YPWallet.BLOCKCHAIN_TX_FEE%> satoshi.</p>
			<p>fee is <%=Math.convertToSatoshi("0.001")%> satoshi.</p>
			<input type="submit" value="Transfer" >
		</form>
<%
	}
	// transfer
	else if (step.equals("2")) {
		YPWallet sender = null;
		long balance = 0;

		try {
			sender = new YPWallet(endpoint, privateKey);
			balance = sender.getBalance();
		} catch (Exception e) {
			e.printStackTrace();
		}

		if (balance < coin) {
			out.println("<h1>Sender balance(" + balance + 
					") is less than request(" + coin + ")</h1>");
		} else {
			try {
				TransactionBuilder tb = new TransactionBuilder();
				tb.shuffleOutputs(false);
				tb.allowDustyOutput(false);
				tb.setFee(fee);
				tb.addOutput(address, coin - fee);
				String rawtx = sender.getCoinstackClient()
						.createSignedTransaction(tb, sender.getPrivateKey());
				sender.getCoinstackClient().sendTransaction(rawtx);

				byte[] rawHex = Hex.decodeHex(rawtx.toCharArray());
				byte[] txIdBytes = Sha256Hash.createDouble(rawHex).getBytes();
				String txId = Hex.encodeHexString(txIdBytes);
				txId = CoinStackClient.convertEndianness(txId);

				session.setAttribute("tx", rawtx);
				session.setAttribute("txid", txId);
				session.setAttribute("sender", sender);
				response.sendRedirect("transfer.jsp?s=3&e=" + endpoint
						+ "&p=" + privateKey
						+ "&a=" + address
						+ "&c=" + coin
						+ "&f=" + fee);
			} catch (CoinStackException cse) {
				out.println("<br>Error Code: " + cse.getErrorCode());
				out.println("<br>Error Type: " + cse.getErrorType());
				out.println("<br>Status Code: " + cse.getStatusCode());
				out.println("<br>Message: " + cse.getMessage());
				out.println("<br>Detailed Message: " + cse.getDetailedMessage());
				cse.printStackTrace();
			} catch (Exception e) {
				out.println(e.toString());
				e.printStackTrace();
			}
		}
	}
	// show result
	else if (step.equals("3")) {
		String lastTx = (String) session.getAttribute("tx");
		String txId = (String) session.getAttribute("txid");
		YPWallet sender = (YPWallet) session.getAttribute("sender");
	
		Transaction tx = null;
		try {
			tx = sender.getCoinstackClient().getTransaction(txId);
		} catch (Exception e) {
			e.printStackTrace();
		}
%>
		<h1>Sender</h1>
		<ul>
			<li>Private Key</li>
			<li>
				<ul>
					<li><%=sender.getPrivateKey()%></li>
				</ul>
			</li>
			<li>Address</li>
			<li>
				<ul>
					<li><%=address%></li>
				</ul>
			</li>
			<li>Balance</li>
			<li>
				<ul>
					<li><%=sender.getBalance()%></li>
				</ul>
			</li>
		</ul>
		<h1>Receiver</h1>
		<ul>
			<li>Address</li>
			<li>
				<ul>
					<li><%=address%></li>
				</ul>
			</li>
			<li>Balance</li>
			<li>
				<ul>
					<li><%=sender.getBalance(address)%></li>
				</ul>
			</li>
		</ul>
		<h1>Last TX</h1>
		<ul>
			<li>TX ID</li>
			<li>
				<ul>
					<li><%=txId%></li>
				</ul>
			</li>
			<li>Raw TX</li>
			<li>
				<ul>
					<li><%=lastTx%></li>
				</ul>
			</li>
		<%	if (tx != null) { %>
				<li>Confirmation Time</li>
				<li>
					<ul>
						<li><%=tx.getConfirmationTime()%></li>
					</ul>
				</li>
		<%	} %>
		</ul>
		<%	if (tx != null) { %>
			<table>
				<tr>
					<th>TX ID</th>
					<th>Outputs (Address/Value/Data/IsSpent)</th>
				</tr>
				<tr>
					<td><%=tx.getId()%></td>
					<td><%=tx.getOutputs().length%>
				<%
					for (int j = 0; j < tx.getOutputs().length; j++) {
						out.print("<br>* " + tx.getOutputs()[j].getAddress());
						out.print(":" + tx.getOutputs()[j].getValue());
						byte[] data = tx.getOutputs()[j].getData();
						String dataStr = "";
						if (data != null) {
							dataStr = new String(data);
						}
						out.print(":" + dataStr);
						out.print(":" + tx.getOutputs()[j].isSpent());
					}
				%>
					</td>
				</tr>
			</table>
<%
		}
	}
%>
</body>
</html>