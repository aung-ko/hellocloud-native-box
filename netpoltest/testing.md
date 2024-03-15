while true; do curl http://{your service IP}:{your service port}/health; sleep 1; done

# eg:
while true; do curl http://10.123.115.18:9080/health; sleep 1; done