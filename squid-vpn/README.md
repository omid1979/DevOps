# docker-openvpn-proxy
Docker OpenVPN Client and Squid Proxy Server

## Run container from Docker registry
To run the container use this command:

```
$ docker run --privileged  -d \
              -e "OPENVPN_PROVIDER=LOCALA" \
              -e "OPENVPN_CONFIG=Netherlands" \
              -e "OPENVPN_USERNAME=user" \
              -e "OPENVPN_PASSWORD=pass" \
              -p 1022:22 \
              -p 3128:3128 \
              dceschmidt/openvpn-proxy
```

Now you can connect your application to a proxy `localhost:3128`.
