umask 077
TEMP=$(mktemp -dp.)
wg genkey | tee "$TEMP/secret.key" | wg pubkey > "$TEMP/public.key"
printf '[Interface]
#PublicKey = %s
#ListenAddress = 127.127.127.127 # server ip goes here
#Address = 10.0.0.1
PrivateKey = %s
ListenPort = 51820
' \
        $(grep . "$TEMP/public.key") \
        $(grep . "$TEMP/secret.key") > wg0.conf
rm -rf "$TEMP"
