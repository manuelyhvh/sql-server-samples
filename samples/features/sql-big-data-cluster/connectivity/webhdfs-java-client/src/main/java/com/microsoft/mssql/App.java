/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */
package com.microsoft.mssql;

import java.io.File;
import java.security.Principal;

import org.apache.http.HttpEntity;
import org.apache.http.auth.AuthSchemeProvider;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.Credentials;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.client.config.AuthSchemes;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.client.methods.RequestBuilder;
import org.apache.http.config.Registry;
import org.apache.http.config.RegistryBuilder;
import org.apache.http.entity.mime.MultipartEntityBuilder;
import org.apache.http.impl.auth.BasicSchemeFactory;
import org.apache.http.impl.auth.DigestSchemeFactory;
import org.apache.http.impl.auth.KerberosSchemeFactory;
import org.apache.http.impl.auth.NTLMSchemeFactory;
import org.apache.http.impl.auth.SPNegoSchemeFactory;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

/**
 * Sample app for Encryption Zone interactions with WebHdfs.
 */
public class App {
	
	// Properties to be configured before running the application.
	private static String GW_ENDPOINT = "https://knox.test.azdata.local:30443/gateway/default/webhdfs/v1";
	
	private static String KDC = "winad.azdata.local";
	
	private static String DOMAIN_REALM = "AZDATA.LOCAL";
	
	// The existing login.conf along with this project can be modified instead of providing a new path.
	private static String LOGIN_CONF_PATH = "login.conf";
	// End of properties to be configured.

	static Credentials emptyCredentials = new Credentials() {
		public String getPassword() {
			return null;
		}
		public Principal getUserPrincipal() {
			return null;
		}
	};
	
	static CredentialsProvider provider = new CredentialsProvider() {
		@Override
		public void setCredentials(AuthScope authscope, Credentials credentials) {
			// No op
		}

		@Override
		public Credentials getCredentials(AuthScope authscope) {
			//TODO: this can be enhanced to pass user name and password in case the AuthScope authscheme is basic.
			return emptyCredentials;
		}

		@Override
		public void clear() {
			// No op. Nothing to clean up.
		}
	};
	
	private static void uploadResource(String inputFilePath, String outputFilePath){
		System.out.println("Entering create resource");
		
		// Create a custom auth scheme registry to prevent reverse DNS lookup on the Http Endpoints
		// For BDC, the same IP address can be associated with multiple service endpoints. Hence control.aris.local and knox.aris.local
		// can resolve to the same IP during reverse lookup. As a result of this kerberos auth may fail.
		// To fix the problem, we should prevent reverse lookup by turning off Hostname Canonicalization in HTTP client and 
		// recommend that the user use the FQDN of knox endpoint to connect to knox.
		Registry<AuthSchemeProvider> authSchemeRegistryCopy = RegistryBuilder.<AuthSchemeProvider>create()
                .register(AuthSchemes.BASIC, new BasicSchemeFactory())
                .register(AuthSchemes.DIGEST, new DigestSchemeFactory())
                .register(AuthSchemes.NTLM, new NTLMSchemeFactory())
                .register(AuthSchemes.SPNEGO, new SPNegoSchemeFactory(true, false))
                .register(AuthSchemes.KERBEROS, new KerberosSchemeFactory(true, false))
                .build();
		
		// Construct Knox endpoint
		String createOperationEndpoint = GW_ENDPOINT + outputFilePath + "?op=CREATE&overwrite=true"; 
		try (CloseableHttpClient client2 = HttpClients.custom().setDefaultCredentialsProvider(provider).setDefaultAuthSchemeRegistry(authSchemeRegistryCopy).build()) {
			HttpUriRequest request = new HttpPut(createOperationEndpoint);
			// First request to get the location in data nodes
			try (CloseableHttpResponse response = client2.execute(request)) { 
				System.out.println("===============");
				String newlocation = response.getFirstHeader("Location").getValue();
				HttpEntity entity = response.getEntity();
				System.out.println("----------------------------------------");
				System.out.println(response.getStatusLine());
				System.out.println("----------------------------------------");
				if (entity != null) {
						System.out.println(EntityUtils.toString(entity));
				}
				System.out.println("----------------------------------------");
				EntityUtils.consume(entity);
				// Second request to put the content to that location
				File testUploadFile = new File(inputFilePath);
				HttpEntity putData = MultipartEntityBuilder.create().addBinaryBody("upfile", testUploadFile).build();
				HttpUriRequest putRequest = RequestBuilder.put(newlocation).setEntity(putData).build();
				System.out.println("Executing request " + putRequest.getRequestLine());
				CloseableHttpResponse response2 = client2.execute(putRequest);
				HttpEntity entity2 = response2.getEntity();
				System.out.println("----------------------------------------");
				System.out.println(response2.getStatusLine());
				System.out.println("----------------------------------------");
				if (entity2 != null) {
						System.out.println(EntityUtils.toString(entity2));
				}
				System.out.println("----------------------------------------");
			}
		} catch (Exception e) {
			System.out.println(e);
		}
	}
 
	public static void main(String[] args) throws Exception {
		// These properties can be specified using command line as well by using 
		// -Djava.security.auth.login.conf=login.conf -Djava.security.krb5.realm=MYDOMAIN.LOCAL
		// In case command line is used to pass these arguments, then code below setting system properties should not be used..
		System.setProperty("java.security.auth.login.config", LOGIN_CONF_PATH); // The login conf for Java GSS to use. See readme for a sample.
		System.setProperty("java.security.krb5.realm", DOMAIN_REALM); 	// The domain name.
		System.setProperty("java.security.krb5.kdc", KDC); // Provide the KDC name here
		System.setProperty("sun.security.krb5.debug", "true"); // This can be set to true to print debug information about Kerberos login.
		System.setProperty("javax.security.auth.useSubjectCredsOnly", "false");
	        
                for(int i = 0; i < args.length; i++) { 
                    System.out.println(args[i]);
                }
		uploadResource(args[0], args[1]);	
	}
}
