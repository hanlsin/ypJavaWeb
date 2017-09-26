/**
 *  Blocko Inc.
 * __________________
 * 
 *  (C) 2017 Blocko Inc. 
 *  All Rights Reserved.
 * 
 * NOTICE:  All information contained herein is, and remains
 * the property of Blocko Inc. and its suppliers, if any.
 * The intellectual and technical concepts contained herein are
 * proprietary to Blocko Inc. and its suppliers
 * and may be covered by South Korea and Foreign Patents, 
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Blocko Inc.
 */
package io.blocko.yp;

import java.io.IOException;
import java.security.PublicKey;

import org.apache.commons.codec.DecoderException;
import org.apache.commons.codec.binary.Hex;
import org.bitcoinj.core.Sha256Hash;

import io.blocko.coinstack.AbstractEndpoint;
import io.blocko.coinstack.CoinStackClient;
import io.blocko.coinstack.ECKey;
import io.blocko.coinstack.Math;
import io.blocko.coinstack.exception.CoinStackException;
import io.blocko.coinstack.exception.MalformedInputException;
import io.blocko.coinstack.model.CredentialsProvider;

/**
 * @author Yun Park <hanlsin@blocko.io>
 *
 */
public class YPWallet {
	public static final long BLOCKCHAIN_TX_FEE = Math
			.convertToSatoshi("0.001");
	public static final long BLOCKCHAIN_MIN_TX_FEE = Math
			.convertToSatoshi("0.0001");
	public static final long BLOCKCHAIN_MIN_OP_COIN = Math
			.convertToSatoshi("0.000006");
	public static final long BLOCKCHAIN_OP_COIN = Math
			.convertToSatoshi("0.000006");

	public static final String DEFAULT_ENDPOINT = "http://localhost:8080";
	public static final String DEFAULT_PV_KEY = "L56cqmuPsUmUeSxann2t7xsvL8q3D5QqmSdSuru45roinygZNTbS";

	private String endpoint;
	private String privateKey;
	private String address;

	private CoinStackClient csc;

	class SimpleCredentialProvider extends CredentialsProvider {
		String accessKey = "";
		String secretKey = "";

		public SimpleCredentialProvider(String address, String privKey) {
			super();

			accessKey = address;
			secretKey = privKey;
		}

		/* (non-Javadoc)
		 * @see io.blocko.coinstack.model.CredentialsProvider#getAccessKey()
		 */
		@Override
		public String getAccessKey() {
			return accessKey;
		}

		/* (non-Javadoc)
		 * @see io.blocko.coinstack.model.CredentialsProvider#getSecretKey()
		 */
		@Override
		public String getSecretKey() {
			return secretKey;
		}
	}

	class SimpleEndpoint implements AbstractEndpoint {
		String endpoint = "";

		public SimpleEndpoint(String endpoint) {
			this.endpoint = endpoint;
		}

		/* (non-Javadoc)
		 * @see io.blocko.coinstack.AbstractEndpoint#endpoint()
		 */
		@Override
		public String endpoint() {
			return endpoint;
		}

		/* (non-Javadoc)
		 * @see io.blocko.coinstack.AbstractEndpoint#mainnet()
		 */
		@Override
		public boolean mainnet() {
			return true;
		}

		/* (non-Javadoc)
		 * @see io.blocko.coinstack.AbstractEndpoint#getPublicKey()
		 */
		@Override
		public PublicKey getPublicKey() {
			return null;
		}
	}

	public YPWallet() throws MalformedInputException {
		this.endpoint = DEFAULT_ENDPOINT;
		this.privateKey = DEFAULT_PV_KEY;
		this.address = getAddress(this.privateKey);
	}

	public YPWallet(String endpoint, String privateKey)
			throws MalformedInputException {
		this.endpoint = endpoint;
		if (privateKey == null) {
			this.privateKey = DEFAULT_PV_KEY;
		} else {
			this.privateKey = privateKey;
		}
		this.address = getAddress(this.privateKey);
	}

	public YPWallet(String endpoint, String privateKey, boolean isRandom)
			throws MalformedInputException {
		this.endpoint = endpoint;
		this.privateKey = ECKey.createNewPrivateKey();
		this.address = getAddress(this.privateKey);
	}

	public CoinStackClient getCoinstackClient() {
		return getCoinstackClient(endpoint, false, false, 0);
	}

	public CoinStackClient getCoinstackClient(String endpoint,
			boolean isRefresh, boolean useUtxoCache, int utxoCacheSize) {
		if (isRefresh || csc == null) {
			if (useUtxoCache) {
				if (utxoCacheSize < 1) {
					utxoCacheSize = 1000;
				}

				// use UtxoCache after merging 'UtxoCache'
				csc = new CoinStackClient(
						new SimpleCredentialProvider(privateKey, address),
						new SimpleEndpoint(endpoint), utxoCacheSize);
			} else {
				csc = new CoinStackClient(
						new SimpleCredentialProvider(privateKey, address),
						new SimpleEndpoint(endpoint));
			}
		}
		return csc;
	}

	public long getBalance(String address)
			throws IOException, CoinStackException {
		return getCoinstackClient().getBalance(address);
	}

	public long getBalance() throws IOException, CoinStackException {
		return getBalance(this.address);
	}

	/**
	 * @return the endpointURL
	 */
	public String getEndpointURL() {
		return endpoint;
	}

	/**
	 * @param endpointURL
	 *            the endpointURL to set
	 */
	public void setEndpointURL(String endpointURL) {
		this.endpoint = endpointURL;
	}

	/**
	 * @return the privateKey
	 */
	public String getPrivateKey() {
		return privateKey;
	}

	/**
	 * @param privateKey
	 *            the privateKey to set
	 */
	public void setPrivateKey(String privateKey) {
		this.privateKey = privateKey;
	}

	/**
	 * @return the address
	 */
	public String getAddress() {
		return address;
	}

	public static String getAddress(String privateKey)
			throws MalformedInputException {
		return ECKey.deriveAddress(privateKey);
	}

	public static String getIDFromRawTx(String rawTx) {
		byte[] bytes;
		try {
			bytes = Hex.decodeHex(rawTx.toCharArray());
		} catch (DecoderException e) {
			e.printStackTrace();
			return null;
		}
		bytes = Sha256Hash.createDouble(bytes).getBytes();
		return CoinStackClient.convertEndianness(Hex.encodeHexString(bytes));
	}
}
