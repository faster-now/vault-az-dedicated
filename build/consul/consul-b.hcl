#Generic file that can be used by all 3 Consul server instances. This configures all instances to use the same ports and thus requires use of a docker bridge network so each instance has a different IP

server                      = true
data_dir                    = "/opt/consul-storage"
retry_join                  = ["consul-a","consul-b","consul-c"] #Seems like its only required for initial deployment/creation (Once it joins successfully to a member in a list of members it will never attempt to join again. Agents will then solely maintain their membership via gossip)
#performance {              #low performance VM host means must choose a low peformance value (default is 5 which is the lowest)
#    raft_multiplier         = 1
#}

addresses {
    http                    = "0.0.0.0"
    https                   = "0.0.0.0"
    dns                     = "0.0.0.0"
}

ports {
    dns                     = 7600
    http                    = 7500 #Vault storage backend is configured with HTTP port
    https                   = 7501
    serf_lan                = 7301 #Gossip protocol, required by all agents
    serf_wan                = 7302
    server                  = 7300 #This is used by servers to handle incoming requests from other agents.
}

bootstrap_expect            = 3
ui                          = true

datacenter                  = "dc1"

tls_cipher_suites           = "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"