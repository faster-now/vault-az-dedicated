server                      = true
retry_join                  = ["consul-a:7301","consul-b:8301","consul-c:9301"] #Seems like its only required for initial deployment/creation (Once it joins successfully to a member in a list of members it will never attempt to join again. Agents will then solely maintain their membership via gossip)
#performance {              #low performance VM host means must choose a low peformance value (default is 5 which is the lowest)
#    raft_multiplier         = 1
#}

addresses {
    http                    = "0.0.0.0"
    https                   = "0.0.0.0"
    dns                     = "0.0.0.0"
}

ports {
    dns                     = 8600
    http                    = 8500 #Vault storage backend is configured with HTTP port
    https                   = 8501
    serf_lan                = 8301 #Gossip protocol, required by all agents
    serf_wan                = 8302
    server                  = 8300 #This is used by servers to handle incoming requests from other agents.
}

bootstrap_expect            = 2
ui                          = true

datacenter                  = "dc1"
primary_ datacenter         = "dc1"

tls_cipher_suites           = "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"