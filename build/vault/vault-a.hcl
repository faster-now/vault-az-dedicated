listener "tcp" {
    address                     = "0.0.0.0:8200"
    tls_disable                 = "true"
    tls_cipher_suites           = "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
}

storage "consul" {
    address                     = "127.0.0.1:7500"
    token                       = ""
    path                        = "vault/"
    scheme                      = "http"
}

ui                              = true
#cluster_addr                   = loadbalancerFQDN:443
cluster_addr                    = "http://vault-a:8200"
#api_addr                       = external ip of this host:8201
api_addr                        = "http://vault-a:8201"