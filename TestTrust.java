import javax.net.ssl.*;
import java.security.cert.X509Certificate;

// To use:
// 1. Compile with: javac TestTrust.java
// 2. Execute: java TestTrust example.com 443

public class TestTrust {

    // ANSI color codes
    private static final String RESET = "\u001B[0m";
    private static final String GREEN = "\u001B[32m";
    private static final String RED   = "\u001B[31m";

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.out.println("Usage: java TestTrust <host> [port]");
            System.exit(1);
        }
        String host = args[0];
        int port = args.length > 1 ? Integer.parseInt(args[1]) : 443;

        System.out.println("JVM: " + System.getProperty("java.vendor") + " "
                + System.getProperty("java.version")
                + " (java.home=" + System.getProperty("java.home") + ")");
        System.out.println("Truststore: " + System.getProperty("javax.net.ssl.trustStore",
                System.getProperty("java.home") + "/lib/security/cacerts (default)"));
        System.out.println();

        SSLSocketFactory factory = (SSLSocketFactory) SSLSocketFactory.getDefault();
        try (SSLSocket socket = (SSLSocket) factory.createSocket(host, port)) {
            socket.startHandshake();
            System.out.println(GREEN + "Handshake successful - certificate is trusted." + RESET);

            SSLSession session = socket.getSession();
            X509Certificate cert = (X509Certificate) session.getPeerCertificates()[0];
            System.out.println("Subject:    " + cert.getSubjectX500Principal());
            System.out.println("Issuer:     " + cert.getIssuerX500Principal());
            System.out.println("Valid until: " + cert.getNotAfter());
        } catch (javax.net.ssl.SSLHandshakeException e) {
            System.out.println(RED + "Handshake failed - certificate is NOT trusted." + RESET);
            System.out.println(RED + "Error: " + e.getMessage() + RESET);
            System.exit(2);
        }
    }
}
