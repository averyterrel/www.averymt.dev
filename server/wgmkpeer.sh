umask 077
nextip() {
        IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' $(echo $1 | sed -e 's/\./ /g'))
        NEXT_IP_HEX=$(printf %.8X $(echo $(( 0x$IP_HEX + 1 ))))
        NEXT_IP=$(printf '%d.%d.%d.%d\n' $(echo $NEXT_IP_HEX | sed 's/\(..\)/0x\1 /g'))
        echo "$NEXT_IP"
}
TEMP=$(mktemp -dp.)
NEXT_IP=$(nextip $(grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' wg0.conf | tail -n1))/32 >> wg0.conf
printf 'Enter peer name> '; read NAME &> /dev/null
wg genkey | tee "$TEMP/secret.key" | wg pubkey > "$TEMP/public.key"
wg genpsk > "$TEMP/preshared.key"
printf '
# %s
[Peer]
PersistentKeepalive = 25
PublicKey = %s
PresharedKey = %s
AllowedIPs = %s
' \
        "$NAME" \
        $(grep . "$TEMP/public.key") \
        $(grep . "$TEMP/preshared.key") \
        $NEXT_IP >> wg0.conf
printf '[Interface]
PrivateKey = %s
ListenPort = 51820
Address = %s
[Peer]
PublicKey = %s
PreSharedKey = %s
AllowedIPs = 10.0.0.0/24
Endpoint = %s:%s
' \
        $(grep . "$TEMP/secret.key") \
        $NEXT_IP \
        $(sed '/^#PublicKey/s/[^=]*= //p;d' wg0.conf | head -n1) \
        $(grep . "$TEMP/preshared.key") \
        $(sed '/^#ListenAddress/s/[^=]*= //p;d' wg0.conf) \
        $(sed '/^ListenPort/s/[^=]*= //p;d' wg0.conf) \
        > client.conf
rm -rf "$TEMP"
