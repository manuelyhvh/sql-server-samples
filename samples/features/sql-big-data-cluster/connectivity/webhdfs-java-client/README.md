# Building this example in Linux

## Prepare dependencies jar into work dir

bash ./prepare.sh
## Building jars

bash ./build.sh

# Running this sample

The App.java has hardcoded values in it mentioned in the sections below. Those should be pointed to the right values.

On Windows, before running this application, kinit needs to be run to get a kerberos token. `kinit` is shipped with the JRE for Windows Java distributions.

`<JRE_INSTALL_ROOT>\bin\kinit.exe <user>@<REALM>`

e.g. 

`<JRE_INSTALL_ROOT>\bin\kinit.exe admin@ARIS.LOCAL`

On Linux, kinit can be used. If `kinit` is not installed, then it would need to be installed to get a kerberos token.

e.g.

 kinit admin@ARIS.LOCAL

# Sample login.conf. There is an existing login.conf that is being checked in as well.

For more details about login.conf refer https://docs.oracle.com/javase/7/docs/technotes/guides/security/jgss/tutorials/LoginConfigFile.html

```
com.sun.security.jgss.login {
    com.sun.security.auth.module.Krb5LoginModule required client=TRUE useTicketCache=true debug=true;
 };
 
 com.sun.security.jgss.initiate {
    com.sun.security.auth.module.Krb5LoginModule required client=TRUE useTicketCache=true debug=true;
 };
 
 com.sun.security.jgss.accept {
    com.sun.security.auth.module.Krb5LoginModule required client=TRUE useTicketCache=true debug=true;
 };

 ```

 In App.java the following properties need to be configured or parameterized using command line.

 ```
    private static String GW_ENDPOINT = "https://knox.tdeupgrade.aris.local:30443/gateway/default/webhdfs/v1";
	
	private static String KDC = "ARIS-WIN2016-DC.aris.local";
	
	private static String DOMAIN_REALM = "ARIS.LOCAL";
	
	private static String LOGIN_CONF_PATH = "login.conf";


```
# Upload file example

```
java -cp "./running_work_dir/*" com.microsoft.mssql.App ./source /tmp/destination
```
