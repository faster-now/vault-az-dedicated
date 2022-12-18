docker stop vault-a
sleep 1
docker stop vault-b
sleep 1
docker rm vault-a
sleep 1
docker rm vault-b
sleep 1
docker rmi my-vault:v1

ansible-playbook ~/vault-build/build-vault-servers.yml